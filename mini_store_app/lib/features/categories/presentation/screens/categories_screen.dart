import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/bottom_bar_auto_hide.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../products/domain/failures/product_failure.dart';
import '../../domain/entities/product_category.dart';
import '../cubit/categories_cubit.dart';
import '../cubit/categories_state.dart';
import '../utils/category_icon.dart';

/// The Categories bottom-navigation tab.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
    super.key,
    required this.createCubit,
    required this.onCategorySelected,
    this.bottomBar,
  });

  final CategoriesCubit Function() createCubit;
  final ValueChanged<ProductCategory> onCategorySelected;

  /// Drives the shell's bottom navigation while this tab scrolls.
  final BottomBarVisibilityController? bottomBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoriesCubit>(
      create: (_) => createCubit()..load(),
      child: _CategoriesView(
        onCategorySelected: onCategorySelected,
        bottomBar: bottomBar,
      ),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView({required this.onCategorySelected, this.bottomBar});

  final ValueChanged<ProductCategory> onCategorySelected;
  final BottomBarVisibilityController? bottomBar;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CategoriesCubit>();

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Categories',
        subtitle: 'Browse by department',
      ),
      body: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) => BottomBarAutoHide(
          controller: bottomBar,
          child: RefreshIndicator(
            onRefresh: cubit.load,
            child: CustomScrollView(
              key: const ValueKey('categories-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  sliver: SliverToBoxAdapter(child: _Intro()),
                ),
                ..._contentSlivers(context, cubit, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    CategoriesCubit cubit,
    CategoriesState state,
  ) {
    return switch (state) {
      CategoriesInitial() || CategoriesLoading() => const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoadingView(message: 'Loading categories…'),
        ),
      ],
      CategoriesEmpty() => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyView(
            title: 'No categories yet',
            message: 'Pull down to refresh and try again.',
            icon: Icons.grid_view_rounded,
            actionLabel: 'Retry',
            onAction: cubit.retry,
          ),
        ),
      ],
      CategoriesOffline() => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            title: "You're offline",
            message:
                'Categories have not been saved on this device yet. '
                'Check your connection and try again.',
            retryLabel: 'Retry',
            onRetry: cubit.retry,
          ),
        ),
      ],
      CategoriesFailure() => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            title: "Couldn't load categories",
            message: state.failure.message,
            onRetry: state.canRetry ? cubit.retry : null,
            icon: state.failure.requiresReauthentication
                ? Icons.lock_clock_rounded
                : Icons.cloud_off_rounded,
          ),
        ),
      ],
      CategoriesLoaded() => <Widget>[
        if (state.refreshFailure != null)
          SliverPadding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: _RefreshNotice(
                failure: state.refreshFailure!,
                onRetry: cubit.load,
              ),
            ),
          ),
        if (state.isRefreshing)
          const SliverPadding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: _cardHeight(context),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = state.categories[index];
              return _CategoryCard(
                category: category,
                onTap: () => onCategorySelected(category),
              );
            }, childCount: state.categories.length),
          ),
        ),
      ],
    };
  }

  /// Cards grow with the user's text scale so two-line names always fit and
  /// every tile in a row stays aligned.
  double _cardHeight(BuildContext context) {
    final scaledName = MediaQuery.textScalerOf(context).scale(15);
    final extra = (scaledName - 15).clamp(0.0, 30.0) * 2.4;
    return 142 + extra;
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop by category', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Pick a department to see its latest products.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = category.imageUrl.trim().isNotEmpty;
    final accent = _accentFor(category.slug);

    return Semantics(
      button: true,
      label: 'Browse ${category.name}',
      child: Container(
        key: ValueKey('category-card-${category.slug}'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CategoryBackdrop(accent: accent, hasImage: hasImage),
              if (hasImage)
                AppNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 480,
                  semanticLabel: category.name,
                  fallbackIcon: categoryIcon(category.slug),
                ),
              if (hasImage)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x14000000), Color(0xCC000000)],
                      stops: [0.25, 1],
                    ),
                  ),
                ),
              Positioned(
                top: AppSpacing.xs + 2,
                left: AppSpacing.xs + 2,
                child: _CategoryIconPill(
                  icon: categoryIcon(category.slug),
                  color: accent,
                ),
              ),
              const Positioned(
                top: AppSpacing.xs + 2,
                right: AppSpacing.xs + 2,
                child: _CategoryArrowPill(),
              ),
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBackdrop extends StatelessWidget {
  const _CategoryBackdrop({required this.accent, required this.hasImage});

  final Color accent;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasImage
              ? [accent, _deepen(accent)]
              : [accent, Color.lerp(accent, Colors.black, 0.55)!],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.8, 0.4),
        child: Icon(
          Icons.category_rounded,
          size: 96,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _CategoryIconPill extends StatelessWidget {
  const _CategoryIconPill({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 18, color: _darkenForText(color)),
    );
  }
}

class _CategoryArrowPill extends StatelessWidget {
  const _CategoryArrowPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: const Icon(
        Icons.arrow_outward_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

const List<Color> _categoryAccents = <Color>[
  AppColors.primary,
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
];

Color _accentFor(String slug) {
  if (slug.isEmpty) {
    return _categoryAccents.first;
  }
  final hash = slug.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return _categoryAccents[hash % _categoryAccents.length];
}

Color _darkenForText(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
}

Color _deepen(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0)).toColor();
}

class _RefreshNotice extends StatelessWidget {
  const _RefreshNotice({required this.failure, required this.onRetry});

  final ProductFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isSession = failure.requiresReauthentication;
    final background = isSession
        ? AppColors.error.withValues(alpha: 0.08)
        : context.palette.accentContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            failure.isOffline
                ? Icons.cloud_off_rounded
                : Icons.sync_problem_rounded,
            size: 18,
            color: isSession ? AppColors.error : context.palette.textPrimary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              failure.isOffline
                  ? "You're offline. Showing saved categories."
                  : isSession
                  ? failure.message
                  : "Couldn't update categories. Showing saved data.",
              style: AppTypography.bodySmall,
            ),
          ),
          if (!isSession)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: isSession
                    ? AppColors.error
                    : context.palette.onAccentContainer,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
