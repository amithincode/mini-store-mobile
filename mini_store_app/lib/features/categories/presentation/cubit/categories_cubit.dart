import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/failures/product_failure.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/usecases/fetch_category_image_use_case.dart';
import '../../domain/usecases/get_cached_categories_use_case.dart';
import '../../domain/usecases/get_cached_category_images_use_case.dart';
import '../../domain/usecases/get_categories_use_case.dart';
import '../../domain/usecases/save_category_images_use_case.dart';
import 'categories_state.dart';

/// Cache-first category list with a background refresh.
///
/// Once the list is visible, the cubit resolves a preview image for each
/// category from its first product. Preview URLs are persisted locally and the
/// images themselves are disk-cached by the network image widget, so cold
/// starts usually paint the grid without extra requests.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit({
    required GetCategoriesUseCase getCategories,
    required GetCachedCategoriesUseCase getCachedCategories,
    required GetCachedCategoryImagesUseCase getCachedImages,
    required FetchCategoryImageUseCase fetchImage,
    required SaveCategoryImagesUseCase saveImages,
  }) : _getCategories = getCategories,
       _getCachedCategories = getCachedCategories,
       _getCachedImages = getCachedImages,
       _fetchImage = fetchImage,
       _saveImages = saveImages,
       super(const CategoriesInitial());

  static const int _previewConcurrency = 4;

  final GetCategoriesUseCase _getCategories;
  final GetCachedCategoriesUseCase _getCachedCategories;
  final GetCachedCategoryImagesUseCase _getCachedImages;
  final FetchCategoryImageUseCase _fetchImage;
  final SaveCategoryImagesUseCase _saveImages;

  final Map<String, String> _previewImages = <String, String>{};

  bool _inFlight = false;
  bool _previewSyncing = false;
  int _generation = 0;

  /// Loads saved categories first, then refreshes from the API.
  Future<void> load() async {
    if (_inFlight) {
      return;
    }

    final generation = ++_generation;
    _inFlight = true;
    _previewSyncing = false;

    var cached = const <ProductCategory>[];
    try {
      cached = await _getCachedCategories();
    } catch (_) {
      // A cache read failure is treated like an empty cache.
    }

    if (!_isCurrent(generation)) {
      return;
    }

    _previewImages.clear();
    try {
      _previewImages.addAll(await _getCachedImages());
    } catch (_) {
      // Missing preview cache simply means every card starts on its fallback.
    }
    for (final category in cached) {
      if (category.imageUrl.isNotEmpty) {
        _previewImages.putIfAbsent(category.slug, () => category.imageUrl);
      }
    }

    if (!_isCurrent(generation)) {
      return;
    }

    final cachedWithImages = _attachImages(cached);
    if (cached.isNotEmpty) {
      emit(CategoriesLoaded(cachedWithImages, isRefreshing: true));
      _startPreviewSync(cachedWithImages, generation);
    } else {
      emit(const CategoriesLoading());
    }

    try {
      final fresh = await _getCategories();
      if (!_isCurrent(generation)) {
        return;
      }

      if (fresh.isNotEmpty) {
        final withImages = _attachImages(fresh);
        emit(CategoriesLoaded(withImages));
        _startPreviewSync(withImages, generation);
      } else if (cached.isNotEmpty) {
        emit(CategoriesLoaded(cachedWithImages));
      } else {
        emit(const CategoriesEmpty());
      }
    } on ProductFailure catch (failure) {
      if (!_isCurrent(generation)) {
        return;
      }
      _emitFailure(failure, cachedWithImages);
    } catch (_) {
      if (!_isCurrent(generation)) {
        return;
      }
      _emitFailure(const ProductUnexpectedFailure(), cachedWithImages);
    } finally {
      if (_isCurrent(generation)) {
        _inFlight = false;
      }
    }
  }

  Future<void> retry() => load();

  void _emitFailure(ProductFailure failure, List<ProductCategory> cached) {
    if (cached.isNotEmpty) {
      emit(CategoriesLoaded(_attachImages(cached), refreshFailure: failure));
      _startPreviewSync(cached, _generation);
      return;
    }

    if (failure.isOffline) {
      emit(CategoriesOffline(failure));
      return;
    }

    emit(
      CategoriesFailure(failure, canRetry: !failure.requiresReauthentication),
    );
  }

  List<ProductCategory> _attachImages(List<ProductCategory> categories) {
    if (categories.isEmpty || _previewImages.isEmpty) {
      return categories;
    }

    var changed = false;
    final result = <ProductCategory>[];
    for (final category in categories) {
      final imageUrl = category.imageUrl.isNotEmpty
          ? category.imageUrl
          : (_previewImages[category.slug] ?? '');
      if (imageUrl != category.imageUrl) {
        changed = true;
        result.add(category.copyWith(imageUrl: imageUrl));
      } else {
        result.add(category);
      }
    }

    return changed ? List<ProductCategory>.unmodifiable(result) : categories;
  }

  void _startPreviewSync(List<ProductCategory> categories, int generation) {
    if (_previewSyncing || categories.isEmpty) {
      return;
    }

    final missing = <String>[];
    final seen = <String>{};
    for (final category in categories) {
      if (category.imageUrl.isNotEmpty ||
          (_previewImages[category.slug]?.isNotEmpty ?? false)) {
        continue;
      }
      if (seen.add(category.slug)) {
        missing.add(category.slug);
      }
    }

    if (missing.isEmpty) {
      return;
    }

    _previewSyncing = true;
    unawaited(_syncPreviews(missing, generation));
  }

  Future<void> _syncPreviews(List<String> slugs, int generation) async {
    try {
      var next = 0;

      Future<void> worker() async {
        while (true) {
          if (!_isCurrent(generation)) {
            return;
          }
          final index = next++;
          if (index >= slugs.length) {
            return;
          }

          final slug = slugs[index];
          String? image;
          try {
            image = await _fetchImage(slug);
          } catch (_) {
            image = null;
          }

          if (image == null || image.isEmpty || !_isCurrent(generation)) {
            continue;
          }

          _previewImages[slug] = image;
          _emitPreviews(generation);
        }
      }

      await Future.wait(
        List<Future<void>>.generate(
          math.min(_previewConcurrency, slugs.length),
          (_) => worker(),
        ),
      );

      if (_isCurrent(generation) && _previewImages.isNotEmpty) {
        await _saveImages(Map<String, String>.unmodifiable(_previewImages));
      }
    } catch (_) {
      // Preview resolution is best-effort and never blocks the list.
    } finally {
      _previewSyncing = false;
    }
  }

  void _emitPreviews(int generation) {
    if (!_isCurrent(generation)) {
      return;
    }
    final current = state;
    if (current is! CategoriesLoaded) {
      return;
    }

    final updated = _attachImages(current.categories);
    if (identical(updated, current.categories)) {
      return;
    }

    emit(
      CategoriesLoaded(
        updated,
        isRefreshing: current.isRefreshing,
        refreshFailure: current.refreshFailure,
      ),
    );
  }

  bool _isCurrent(int generation) => generation == _generation && !isClosed;
}
