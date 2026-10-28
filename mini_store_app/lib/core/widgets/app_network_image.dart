// import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
 
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _Fallback(icon: fallbackIcon);
    }

    return Semantics(
      image: true,
      label: semanticLabel,
      child: Image.network(
        imageUrl,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image error: $error');
          return const Icon(Icons.broken_image, size: 40);
        },
      ),

      // CachedNetworkImage(
      //   imageUrl: imageUrl,
      //   fit: fit,
      //   memCacheWidth: memCacheWidth,
      //   fadeInDuration: const Duration(milliseconds: 150),
      //   placeholder: (context, url) => const Center(
      //     child: SizedBox(
      //       width: 20,
      //       height: 20,
      //       child: CircularProgressIndicator(strokeWidth: 2),
      //     ),
      //   ),
      //   errorWidget: (context, url, error) {
      //     debugPrint('Image failed: $url');
      //     debugPrint('Error: $error');
      //     return _Fallback(icon: fallbackIcon);
      //   },
      // ),
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
        color: AppColors.textSecondary.withValues(alpha: 0.55),
      ),
    );
  }
}
