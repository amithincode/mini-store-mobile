import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/domain/entities/product.dart';
import '../../../products/domain/failures/product_failure.dart';
import '../../domain/repositories/product_detail_repository.dart';
import '../../domain/usecases/get_product_detail_use_case.dart';
import 'product_detail_state.dart';

/// Cache-first product details with a non-blocking background refresh.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit({
    required GetProductDetailUseCase getDetail,
    required ProductDetailRepository repository,
  }) : _getDetail = getDetail,
       _repository = repository,
       super(const ProductDetailInitial());

  final GetProductDetailUseCase _getDetail;
  final ProductDetailRepository _repository;

  int? _id;
  int _generation = 0;
  bool _inFlight = false;

  /// Shows cached details immediately, then refreshes them from the API.
  Future<void> load(int id) async {
    if (_id == id && _inFlight) {
      return;
    }

    _id = id;
    final generation = ++_generation;
    _inFlight = true;

    Product? cached;
    try {
      cached = await _repository.readCached(id);
    } catch (_) {
      // A broken cache read is treated like a cache miss.
    }

    if (!_isCurrent(generation)) {
      return;
    }

    if (cached != null) {
      emit(ProductDetailLoaded(cached, isRefreshing: true));
    } else {
      emit(const ProductDetailLoading());
    }

    await _refresh(id, generation, cached);
  }

  /// Retries a first-visit failure or a failed background refresh.
  Future<void> retry() async {
    final id = _id;
    if (id == null || _inFlight) {
      return;
    }
    await load(id);
  }

  Future<void> _refresh(int id, int generation, Product? cached) async {
    try {
      final product = await _getDetail(id);
      if (!_isCurrent(generation)) {
        return;
      }
      emit(ProductDetailLoaded(product));
    } on ProductFailure catch (failure) {
      if (!_isCurrent(generation)) {
        return;
      }
      _emitFailure(failure, cached);
    } catch (_) {
      if (!_isCurrent(generation)) {
        return;
      }
      _emitFailure(const ProductUnexpectedFailure(), cached);
    } finally {
      if (_isCurrent(generation)) {
        _inFlight = false;
      }
    }
  }

  void _emitFailure(ProductFailure failure, Product? cached) {
    if (cached != null) {
      emit(ProductDetailLoaded(cached, refreshFailure: failure));
      return;
    }

    if (failure.isOffline) {
      emit(const ProductDetailOffline());
      return;
    }

    emit(
      ProductDetailFailure(
        failure,
        canRetry: !failure.requiresReauthentication,
      ),
    );
  }

  bool _isCurrent(int generation) => generation == _generation && !isClosed;
}
