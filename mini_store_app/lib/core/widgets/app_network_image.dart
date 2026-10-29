import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Network image with disk caching, a static skeleton while loading, and a
/// compact broken-image fallback.
///
/// The short fade-out keeps the skeleton from lingering after the image has
/// already decoded, which is the main reason the storefront felt slow.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.fallbackIcon = Icons.image_outlined,
    this.memCacheWidth,
  });

  final String imageUrl;
  final BoxFit fit;
  final String? semanticLabel;
  final IconData fallbackIcon;

  /// Decode width in physical pixels. Keeping the height unset preserves the
  /// image aspect ratio (an exact width and height would distort it).
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _Fallback(icon: fallbackIcon);
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        memCacheWidth: memCacheWidth,
        fadeInDuration: const Duration(milliseconds: 160),
        fadeOutDuration: const Duration(milliseconds: 60),
        placeholder: (context, url) => const _Skeleton(),
        errorWidget: (context, url, error) {
          debugPrint('Image failed: $url ($error)');
          return _Fallback(icon: fallbackIcon);
        },
      ),
    );
  }
}

/// Image provider matching [AppNetworkImage]'s cache key so prefetching warms
/// the same entry the widget reads.
ImageProvider<Object> appNetworkImageProvider(
  String imageUrl, {
  int? memCacheWidth,
}) {
  return ResizeImage.resizeIfNeeded(
    memCacheWidth,
    null,
    CachedNetworkImageProvider(imageUrl),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.imageBackground,
      child: Center(
        child: Icon(
          Icons.photo_size_select_actual_outlined,
          size: 22,
          color: context.palette.textSecondary.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        icon,
        size: 32,
        color: context.palette.textSecondary.withValues(alpha: 0.55),
      ),
    );
  }
}
