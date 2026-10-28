import 'dart:math' as math;

/// Device classes used to adapt spacing, not to change the feature set.
enum AppDeviceType { mobile, tablet, desktop }

/// Layout decisions derived from the available width.
///
/// Prefer [ResponsiveMetrics.fromWidth] with a `LayoutBuilder` constraint when
/// the layout depends on the space allocated to a widget. Use the app window
/// width only for page-level choices such as the number of grid columns.
class ResponsiveMetrics {
  const ResponsiveMetrics({required this.width, required this.deviceType});

  factory ResponsiveMetrics.fromWidth(double width) {
    final deviceType = width >= tabletBreakpoint
        ? AppDeviceType.desktop
        : width >= mobileBreakpoint
        ? AppDeviceType.tablet
        : AppDeviceType.mobile;

    return ResponsiveMetrics(width: width, deviceType: deviceType);
  }

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double wideDesktopBreakpoint = 1100;

  final double width;
  final AppDeviceType deviceType;

  bool get isMobile => deviceType == AppDeviceType.mobile;
  bool get isTablet => deviceType == AppDeviceType.tablet;
  bool get isDesktop => deviceType == AppDeviceType.desktop;

  /// Page gutter: 16 on mobile, 24 on tablet, 32 on desktop.
  double get horizontalPadding => switch (deviceType) {
    AppDeviceType.mobile => 16,
    AppDeviceType.tablet => 24,
    AppDeviceType.desktop => 32,
  };

  /// Product grid columns: 2 / 3 / 4 / 5.
  int get productColumns {
    if (width >= wideDesktopBreakpoint) {
      return 5;
    }
    if (width >= tabletBreakpoint) {
      return 4;
    }
    if (width >= mobileBreakpoint) {
      return 3;
    }
    return 2;
  }

  double get gridSpacing => switch (deviceType) {
    AppDeviceType.mobile => 12,
    AppDeviceType.tablet => 16,
    AppDeviceType.desktop => 20,
  };

  /// Banner height leaves room for two title lines on narrow screens.
  double get bannerHeight => switch (deviceType) {
    AppDeviceType.mobile => 216,
    AppDeviceType.tablet => 220,
    AppDeviceType.desktop => 232,
  };

  /// Search fields stop growing once they are comfortable to read.
  double get searchMaxWidth =>
      isMobile ? double.infinity : math.min(width, 560);
}
