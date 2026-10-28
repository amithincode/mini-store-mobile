import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Displays a remote product image with consistent loading and fallback states.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String imageUrl;
  final BoxFit fit;
  final String? semanticLabel;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      semanticLabel: semanticLabel,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }

        final totalBytes = progress.expectedTotalBytes;
        final value = totalBytes == null
            ? null
            : progress.cumulativeBytesLoaded / totalBytes;

        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, value: value),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            fallbackIcon,
            size: 32,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
          ),
        );
      },
    );
  }
}
