import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Store search input with a clear affordance.
///
/// Search runs against the API through the product cubit; this widget only owns
/// the text field affordances and forwards changes, submissions, and clears.
class StoreSearchField extends StatelessWidget {
  const StoreSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.onSubmitted,
    this.maxWidth = double.infinity,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: maxWidth,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search products, brands…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  onPressed: onClear,
                  tooltip: 'Clear search',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
