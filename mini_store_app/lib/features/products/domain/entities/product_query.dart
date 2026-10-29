/// Normalizes a search query before it is used as a cache identity.
///
/// Queries that differ only by case or surrounding/repeated whitespace share
/// the same cache entry and are treated as the same active search.
String normalizeProductQuery(String query) {
  return query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
