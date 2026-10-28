import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import 'store_state.dart';

/// Presentation state for the storefront.
///
/// The catalogue is supplied by the caller. No repository or remote request
/// sits behind this cubit yet.
class StoreCubit extends Cubit<StoreState> {
  StoreCubit({List<Product> products = const <Product>[]})
    : super(StoreState(products: List<Product>.unmodifiable(products)));

  void search(String value) {
    if (value == state.query) {
      return;
    }
    emit(state.copyWith(query: value));
  }

  void selectCategory(String category) {
    if (category == state.selectedCategory) {
      return;
    }
    emit(state.copyWith(selectedCategory: category));
  }

  void clearFilters() {
    if (!state.hasActiveFilters) {
      return;
    }
    emit(state.copyWith(query: '', selectedCategory: StoreState.allCategory));
  }
}
