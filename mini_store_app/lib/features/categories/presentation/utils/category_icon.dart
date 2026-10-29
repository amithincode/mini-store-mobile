import 'package:flutter/material.dart';

/// A friendly icon for a category slug.
IconData categoryIcon(String slug) {
  final value = slug.toLowerCase();
  if (value.contains('beauty') ||
      value.contains('skin') ||
      value.contains('fragrance')) {
    return Icons.spa_outlined;
  }
  if (value.contains('furniture') ||
      value.contains('home') ||
      value.contains('decoration')) {
    return Icons.chair_outlined;
  }
  if (value.contains('kitchen') || value.contains('grocer')) {
    return Icons.kitchen_outlined;
  }
  if (value.contains('laptop') ||
      value.contains('tablet') ||
      value.contains('mobile')) {
    return Icons.devices_outlined;
  }
  if (value.contains('shirt') ||
      value.contains('dress') ||
      value.contains('tops')) {
    return Icons.checkroom_outlined;
  }
  if (value.contains('shoe') || value.contains('sneaker')) {
    return Icons.directions_walk_rounded;
  }
  if (value.contains('watch')) {
    return Icons.watch_outlined;
  }
  if (value.contains('jewellery') || value.contains('jewelry')) {
    return Icons.diamond_outlined;
  }
  if (value.contains('bag')) {
    return Icons.shopping_bag_outlined;
  }
  if (value.contains('sport')) {
    return Icons.sports_basketball_outlined;
  }
  if (value.contains('motorcycle') || value.contains('vehicle')) {
    return Icons.two_wheeler_outlined;
  }
  if (value.contains('sunglass')) {
    return Icons.visibility_outlined;
  }
  return Icons.category_outlined;
}
