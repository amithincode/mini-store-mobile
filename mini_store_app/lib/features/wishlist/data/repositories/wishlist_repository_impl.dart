import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_local_data_source.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  const WishlistRepositoryImpl(this._local);

  final WishlistLocalDataSource _local;

  @override
  Future<List<WishlistItem>> loadWishlist() => _local.load();

  @override
  Future<void> saveWishlist(List<WishlistItem> items) => _local.save(items);
}
