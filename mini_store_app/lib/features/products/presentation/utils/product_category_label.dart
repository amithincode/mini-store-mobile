const Map<String, String> _categoryLabels = <String, String>{
  'home-decoration': 'Home Decor',
  'kitchen-accessories': 'Kitchen',
  'mens-shirts': 'Mens Shirts',
  'mens-shoes': 'Mens Shoes',
  'mens-watches': 'Mens Watches',
  'mobile-accessories': 'Mobile',
  'skin-care': 'Skin Care',
  'sports-accessories': 'Sports',
  'womens-bags': 'Bags',
  'womens-dresses': 'Dresses',
  'womens-jewellery': 'Jewellery',
  'womens-shoes': 'Womens Shoes',
  'womens-watches': 'Womens Watches',
};

/// Converts an API-style category slug into a short display label.
String productCategoryLabel(String category) {
  final mapped = _categoryLabels[category];
  if (mapped != null) {
    return mapped;
  }

  return category
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
