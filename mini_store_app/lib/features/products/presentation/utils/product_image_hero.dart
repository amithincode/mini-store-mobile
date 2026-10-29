/// Shared Hero tag for a product thumbnail.
///
/// Only one widget per route may use a tag, so the detail gallery applies it
/// to the first image page only.
String productImageHeroTag(int productId) => 'product-image-$productId';
