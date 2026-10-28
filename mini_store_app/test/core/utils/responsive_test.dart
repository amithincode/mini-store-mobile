import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store_app/core/utils/responsive.dart';

void main() {
  group('ResponsiveMetrics', () {
    test('classifies device types at the breakpoints', () {
      expect(ResponsiveMetrics.fromWidth(390).deviceType, AppDeviceType.mobile);
      expect(
        ResponsiveMetrics.fromWidth(599.9).deviceType,
        AppDeviceType.mobile,
      );
      expect(ResponsiveMetrics.fromWidth(600).deviceType, AppDeviceType.tablet);
      expect(
        ResponsiveMetrics.fromWidth(899.9).deviceType,
        AppDeviceType.tablet,
      );
      expect(
        ResponsiveMetrics.fromWidth(900).deviceType,
        AppDeviceType.desktop,
      );
    });

    test('uses responsive page gutters', () {
      expect(ResponsiveMetrics.fromWidth(390).horizontalPadding, 16);
      expect(ResponsiveMetrics.fromWidth(700).horizontalPadding, 24);
      expect(ResponsiveMetrics.fromWidth(1200).horizontalPadding, 32);
    });

    test('uses 2 to 5 product columns', () {
      expect(ResponsiveMetrics.fromWidth(390).productColumns, 2);
      expect(ResponsiveMetrics.fromWidth(600).productColumns, 3);
      expect(ResponsiveMetrics.fromWidth(899).productColumns, 3);
      expect(ResponsiveMetrics.fromWidth(900).productColumns, 4);
      expect(ResponsiveMetrics.fromWidth(1099).productColumns, 4);
      expect(ResponsiveMetrics.fromWidth(1100).productColumns, 5);
    });

    test('caps the search field width outside mobile', () {
      expect(ResponsiveMetrics.fromWidth(390).searchMaxWidth, double.infinity);
      expect(ResponsiveMetrics.fromWidth(700).searchMaxWidth, 560);
      expect(ResponsiveMetrics.fromWidth(1400).searchMaxWidth, 560);
    });

    test('provides positive grid spacing and banner heights', () {
      for (final width in <double>[390, 700, 1200]) {
        final metrics = ResponsiveMetrics.fromWidth(width);
        expect(metrics.gridSpacing, greaterThan(0));
        expect(metrics.bannerHeight, greaterThan(0));
      }
    });
  });
}
