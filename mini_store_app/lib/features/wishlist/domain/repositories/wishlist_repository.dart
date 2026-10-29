import '../entities/wishlist_item.dart';

abstract interface class WishlistRepository {
  Future<List<WishlistItem>> loadWishlist();
  Future<void> saveWishlist(List<WishlistItem> items);
}
