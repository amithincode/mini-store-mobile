import 'package:flutter/foundation.dart';

/// Shared bottom-navigation selection.
///
/// Screens outside the shell (product details, order success) can select a tab
/// without pushing a duplicate shell route.
class MainTabController extends ChangeNotifier {
  static const int homeIndex = 0;
  static const int categoriesIndex = 1;
  static const int cartIndex = 2;
  static const int accountIndex = 3;

  int _index = homeIndex;

  int get index => _index;

  void select(int index) {
    if (index < 0 || index > accountIndex || index == _index) {
      return;
    }
    _index = index;
    notifyListeners();
  }

  void selectHome() => select(homeIndex);

  void selectCart() => select(cartIndex);
}
