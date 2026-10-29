import 'dart:convert';

import 'package:mini_store_app/features/products/data/models/product_model.dart';

import '../../../../core/storage/app_storage.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../models/product_model.dart';

/// Cached product collection for one normalized query.
class CachedProductPage {
  const CachedProductPage({
    required this.products,
    required this.total,
    required this.limit,
    required this.updatedAt,
  });

  final List<Product> products;
  final int total;
  final int limit;
  final DateTime updatedAt;
}

/// Persistent product cache contract.
abstract interface class ProductLocalDataSource {
  /// Returns the cached collection for [query] in insertion order.
  Future<CachedProductPage?> read(String query);

  /// Writes [products] for [query]. When [replace] is true the previous
  /// collection for that query is discarded; otherwise the page is appended.
  Future<void> savePage({
    required String query,
    required List<Product> products,
    required int total,
    required int limit,
    required bool replace,
  });

  /// Removes the cached collection for [query].
  Future<void> clearQuery(String query);
}

/// Chunked SharedPreferences cache.
///
/// Each product is stored under its own key and every query only stores an
/// ordered id list plus metadata. This keeps individual values small instead
/// of serialising the whole catalogue into one oversized JSON blob.
class SharedPreferencesProductLocalDataSource
    implements ProductLocalDataSource {
  SharedPreferencesProductLocalDataSource(
    this._storage, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const int schemaVersion = 1;
  static const int maxCachedQueries = 10;
  static const String _allProductsKey = '__all__';
  static const String _prefix = 'mini_store.products.v1';
  static const String _schemaKey = '$_prefix.schema';
  static const String _indexKey = '$_prefix.index';
  static const String _metaPrefix = '$_prefix.meta.';
  static const String _itemPrefix = '$_prefix.item.';

  final AppStorage _storage;
  final DateTime Function() _now;

  @override
  Future<CachedProductPage?> read(String query) async {
    if (_storage.read<int>(_schemaKey) != schemaVersion) {
      return null;
    }

    final key = _cacheKey(query);
    final meta = _readJsonMap('$_metaPrefix$key');
    if (meta == null) {
      return null;
    }

    final ids = _readIds(meta['ids']);
    if (ids.isEmpty) {
      return null;
    }

    final products = <Product>[];
    final seenIds = <int>{};
    for (final id in ids) {
      if (!seenIds.add(id)) {
        continue;
      }

      final item = _readJsonMap('$_itemPrefix$id');
      if (item == null) {
        continue;
      }

      try {
        products.add(ProductModel.fromJson(item).toEntity());
      } on FormatException {
        // Skip corrupted individual entries instead of discarding the cache.
      }
    }

    if (products.isEmpty) {
      return null;
    }

    final total = _readInt(meta['total']) ?? products.length;
    final updatedAt = DateTime.tryParse(
      _readString(meta['updatedAt']) ?? '',
    )?.toLocal();

    return CachedProductPage(
      products: List<Product>.unmodifiable(products),
      total: total < products.length ? products.length : total,
      limit: _readInt(meta['limit']) ?? products.length,
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Future<void> savePage({
    required String query,
    required List<Product> products,
    required int total,
    required int limit,
    required bool replace,
  }) async {
    final key = _cacheKey(query);

    if (products.isEmpty && replace) {
      await clearQuery(query);
      return;
    }

    if (products.isEmpty) {
      return;
    }

    if (_storage.read<int>(_schemaKey) != schemaVersion) {
      await _storage.write<int>(_schemaKey, schemaVersion);
    }

    final existingMeta = _readJsonMap('$_metaPrefix$key');
    final ids = replace ? <int>[] : _readIds(existingMeta?['ids']);
    final seenIds = ids.toSet();

    for (final product in products) {
      await _storage.write<String>(
        '$_itemPrefix${product.id}',
        jsonEncode(ProductModel.fromEntity(product).toJson()),
      );
      if (seenIds.add(product.id)) {
        ids.add(product.id);
      }
    }

    final effectiveTotal = total < ids.length ? ids.length : total;
    await _storage.write<String>(
      '$_metaPrefix$key',
      jsonEncode(<String, dynamic>{
        'query': normalizeProductQuery(query),
        'total': effectiveTotal,
        'limit': limit,
        'updatedAt': _now().toUtc().toIso8601String(),
        'ids': ids,
      }),
    );

    await _touchIndex(key);

    if (replace) {
      // A fresh first page replaces the collection, so products that only
      // belonged to the previous collection should not linger in storage.
      await _pruneItems(_readIndex());
    }
  }

  @override
  Future<void> clearQuery(String query) async {
    final key = _cacheKey(query);
    await _storage.remove('$_metaPrefix$key');

    final index = _readIndex();
    final hadEntry = index.any((entry) => entry['key'] == key);
    if (hadEntry) {
      index.removeWhere((entry) => entry['key'] == key);
      await _storage.write<String>(_indexKey, jsonEncode(index));
      await _pruneItems(index);
    }
  }

  String _cacheKey(String query) {
    final normalized = normalizeProductQuery(query);
    if (normalized.isEmpty) {
      return _allProductsKey;
    }

    return base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
  }

  Future<void> _touchIndex(String key) async {
    final index = _readIndex()
      ..removeWhere((entry) => entry['key'] == key)
      ..insert(0, <String, dynamic>{
        'key': key,
        'updatedAt': _now().toUtc().toIso8601String(),
      });

    final kept = index.take(maxCachedQueries).toList(growable: false);
    final evicted = index.skip(maxCachedQueries).toList(growable: false);

    await _storage.write<String>(_indexKey, jsonEncode(kept));

    for (final entry in evicted) {
      final evictedKey = _readString(entry['key']);
      if (evictedKey != null) {
        await _storage.remove('$_metaPrefix$evictedKey');
      }
    }

    if (evicted.isNotEmpty) {
      await _pruneItems(kept);
    }
  }

  Future<void> _pruneItems(List<Map<String, dynamic>> index) async {
    final referencedIds = <int>{};

    for (final entry in index) {
      final key = _readString(entry['key']);
      if (key == null) {
        continue;
      }
      final meta = _readJsonMap('$_metaPrefix$key');
      if (meta != null) {
        referencedIds.addAll(_readIds(meta['ids']));
      }
    }

    for (final storageKey in _storage.keys.toList()) {
      if (!storageKey.startsWith(_itemPrefix)) {
        continue;
      }

      final id = int.tryParse(storageKey.substring(_itemPrefix.length));
      if (id != null && !referencedIds.contains(id)) {
        await _storage.remove(storageKey);
      }
    }
  }

  List<Map<String, dynamic>> _readIndex() {
    final raw = _storage.read<String>(_indexKey);
    if (raw == null) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } on FormatException {
      return <Map<String, dynamic>>[];
    }
  }

  Map<String, dynamic>? _readJsonMap(String key) {
    final raw = _storage.read<String>(key);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  static List<int> _readIds(Object? value) {
    if (value is! List) {
      return <int>[];
    }

    return value.map(_readInt).whereType<int>().where((id) => id > 0).toList();
  }

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
