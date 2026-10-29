import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_system_ui.dart';
import 'app_typography.dart';
import 'side_slide_page_transitions_builder.dart';

/// Central Material 3 theme. Feature screens should not define their own
/// colors, text styles, or component shapes.
abstract final class AppTheme {
  static const double _fieldRadius = 14;
  static const double _cardRadius = 16;

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: palette.primaryContainer,
          onPrimaryContainer: palette.onPrimaryContainer,
          secondary: AppColors.accent,
          onSecondary: isDark ? AppColors.darkBackground : palette.textPrimary,
          secondaryContainer: palette.accentContainer,
          onSecondaryContainer: palette.onAccentContainer,
          surface: palette.surface,
          onSurface: palette.textPrimary,
          onSurfaceVariant: palette.textSecondary,
          surfaceContainerLowest: palette.background,
          surfaceContainerLow: palette.surface,
          surfaceContainer: palette.surface,
          surfaceContainerHigh: palette.surfaceElevated,
          surfaceContainerHighest: palette.imageBackground,
          outline: palette.border,
          outlineVariant: palette.border,
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: isDark
              ? const Color(0xFF7F1D1D)
              : const Color(0xFFFEE2E2),
          onErrorContainer: isDark
              ? const Color(0xFFFECACA)
              : const Color(0xFF991B1B),
          surfaceTint: Colors.transparent,
          scrim: const Color(0xFF000000),
        );

    final textTheme = AppTypography.textTheme
        .apply(
          bodyColor: palette.textPrimary,
          displayColor: palette.textPrimary,
        )
        .copyWith(
          bodySmall: AppTypography.bodySmall.copyWith(
            color: palette.textSecondary,
          ),
          labelMedium: AppTypography.labelMedium.copyWith(
            color: palette.textSecondary,
          ),
          labelSmall: AppTypography.labelSmall.copyWith(
            color: palette.textSecondary,
          ),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[palette],
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      dividerColor: palette.border,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: SideSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: SideSlidePageTransitionsBuilder(),
          TargetPlatform.linux: SideSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: SideSlidePageTransitionsBuilder(),
          TargetPlatform.windows: SideSlidePageTransitionsBuilder(),
          TargetPlatform.fuchsia: SideSlidePageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(color: palette.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        systemOverlayStyle: isDark ? AppSystemUi.dark : AppSystemUi.light,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: BorderSide(color: palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? palette.surfaceElevated : palette.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: palette.textSecondary,
        ),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        border: _roundedFieldBorder(palette.border),
        enabledBorder: _roundedFieldBorder(palette.border),
        focusedBorder: _roundedFieldBorder(AppColors.primary, width: 1.6),
        errorBorder: _roundedFieldBorder(AppColors.error),
        focusedErrorBorder: _roundedFieldBorder(AppColors.error, width: 1.6),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.16),
        selectionHandleColor: AppColors.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? palette.surfaceElevated : palette.surface,
        selectedColor: palette.primaryContainer,
        disabledColor: palette.background,
        checkmarkColor: palette.onPrimaryContainer,
        showCheckmark: false,
        labelStyle: AppTypography.labelLarge.copyWith(
          color: palette.textPrimary,
        ),
        secondaryLabelStyle: AppTypography.labelLarge.copyWith(
          color: palette.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        side: BorderSide(color: palette.border),
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: palette.border),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? palette.surfaceElevated : palette.surface,
          foregroundColor: AppColors.primary,
          elevation: 0,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: palette.border,
        circularTrackColor: palette.border,
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: palette.textSecondary,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surface,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? palette.surfaceElevated : palette.textPrimary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? palette.textPrimary : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static OutlineInputBorder _roundedFieldBorder(
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
