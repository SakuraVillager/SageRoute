import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/utils/featured_card_metrics.dart';

void main() {
  /// 可用高度 = 屏高 − 状态栏 − 手势条 − 首屏固定头部。
  double availableHeight(double height, {double topInset = 34}) =>
      height - topInset;

  double cardHeight(double width, double height, {double topInset = 34}) =>
      FeaturedCardMetrics.fromAvailableHeight(
        availableHeight: availableHeight(height, topInset: topInset),
        width: width,
      ).cardHeight;

  group('height stays proportional across devices', () {
    test('narrow small phones fall back to the readable lower bound', () {
      expect(cardHeight(320, 568, topInset: 24), FeaturedCardMetrics.minHeight);
    });

    test('the height policy is scaled up from the base design', () {
      // 当前需求：精选区整体比初版再高 25%。
      expect(FeaturedCardMetrics.heightScale, 1.25);
      expect(FeaturedCardMetrics.minHeight, 310 * 1.25);
      expect(FeaturedCardMetrics.maxHeight, 390 * 1.25);

      for (final available in <double>[420, 700, 900]) {
        final base = (available * FeaturedCardMetrics.baseHeightFactor).clamp(
          FeaturedCardMetrics.baseMinHeight,
          FeaturedCardMetrics.baseMaxHeight,
        );

        expect(
          FeaturedCardMetrics.fromAvailableHeight(
            availableHeight: available,
            width: 390,
          ).cardHeight,
          closeTo(base * FeaturedCardMetrics.heightScale, 1e-9),
          reason: '$available',
        );
      }
    });

    test('common and large phones keep 50%~66% of the available area', () {
      for (final size in <Size>[
        const Size(360, 640),
        const Size(360, 800),
        const Size(393, 852),
        const Size(430, 932),
      ]) {
        final available = availableHeight(size.height);
        final ratio = cardHeight(size.width, size.height) / available;

        // 无夹取时正好是 0.44 × 1.25 = 0.55；被下限托住的小屏会更高一些。
        expect(ratio, greaterThanOrEqualTo(0.5), reason: '${size.height}');
        expect(ratio, lessThanOrEqualTo(0.66), reason: '${size.height}');
      }
    });

    test('tablets and very tall windows stop at the upper bound', () {
      expect(
        cardHeight(834, 1194, topInset: 24),
        FeaturedCardMetrics.maxHeight,
      );
      expect(cardHeight(430, 1100), FeaturedCardMetrics.maxHeight);
    });

    test('bigger available area means a taller card until the cap', () {
      final heights = <double>[
        for (final available in <double>[500, 620, 700, 800, 900])
          FeaturedCardMetrics.fromAvailableHeight(
            availableHeight: available,
            width: 390,
          ).cardHeight,
      ];

      for (var i = 1; i < heights.length; i++) {
        expect(heights[i], greaterThanOrEqualTo(heights[i - 1]));
      }
      expect(heights.first, FeaturedCardMetrics.minHeight);
      expect(heights.last, FeaturedCardMetrics.maxHeight);
    });

    test('landscape and wide windows switch to the compact height', () {
      // 844×390 手机横屏：可用高度 = 390 − 24 − 124 = 242，宽扁窗口改用横屏高度。
      final metrics = FeaturedCardMetrics.fromScreen(
        width: 844,
        height: 390,
        padding: const EdgeInsets.only(top: 24),
      );

      expect(metrics.availableHeight, 242);
      expect(metrics.cardHeight, FeaturedCardMetrics.minLandscapeHeight);
    });

    test('landscape stays capped even with plenty of vertical space', () {
      final metrics = FeaturedCardMetrics.fromAvailableHeight(
        availableHeight: 900,
        width: 1200,
      );

      expect(metrics.cardHeight, FeaturedCardMetrics.maxLandscapeHeight);
    });

    test('tiny windows keep a usable card instead of collapsing', () {
      final metrics = FeaturedCardMetrics.fromScreen(width: 640, height: 296);

      expect(metrics.availableHeight, 172);
      expect(metrics.cardHeight, FeaturedCardMetrics.minLandscapeHeight);
    });

    test('fromScreen subtracts both safe areas', () {
      final metrics = FeaturedCardMetrics.fromScreen(
        width: 430,
        height: 932,
        padding: const EdgeInsets.only(top: 59, bottom: 34),
      );

      expect(metrics.availableHeight, 932 - 59 - 34 - 124);
      // 可用高度 715 × 0.44 = 314.6，再按 1.25 放大。
      expect(metrics.cardHeight, 314.6 * 1.25);
    });
  });

  group('card internals scale with the card height', () {
    test(
      'poster and typography grow from the smallest card to the largest',
      () {
        final small = FeaturedCardMetrics.fromAvailableHeight(
          availableHeight: 705,
          width: 390,
        );
        final large = FeaturedCardMetrics.fromAvailableHeight(
          availableHeight: 900,
          width: 390,
        );

        expect(small.cardHeight, closeTo(FeaturedCardMetrics.minHeight, 0.5));
        expect(large.cardHeight, FeaturedCardMetrics.maxHeight);
        expect(small.posterHeight, lessThan(large.posterHeight));
        expect(small.posterWidth, lessThan(large.posterWidth));
        expect(small.titleFontSize, lessThan(large.titleFontSize));
        expect(small.summaryFontSize, lessThan(large.summaryFontSize));
        expect(small.posterGap, lessThanOrEqualTo(large.posterGap));
        expect(small.titleGap, lessThanOrEqualTo(large.titleGap));
      },
    );

    test('poster keeps its 48:70 design ratio', () {
      for (final width in <double>[320, 390, 430, 834]) {
        final metrics = FeaturedCardMetrics.fromAvailableHeight(
          availableHeight: 700,
          width: width,
        );
        expect(
          metrics.posterWidth / metrics.posterHeight,
          closeTo(48 / 70, 1e-9),
        );
      }
    });

    test(
      'poster stays a small part of the card so copy keeps breathing room',
      () {
        for (final width in <double>[320, 360, 393, 430, 834]) {
          final metrics = FeaturedCardMetrics.fromAvailableHeight(
            availableHeight: 700,
            width: width,
          );
          expect(metrics.posterHeight, lessThan(metrics.cardHeight / 3));
        }
      },
    );

    test('horizontal inset stays inside the design range', () {
      for (final width in <double>[320, 360, 393, 430, 834]) {
        final metrics = FeaturedCardMetrics.fromAvailableHeight(
          availableHeight: 700,
          width: width,
        );
        expect(
          metrics.horizontalInset,
          inInclusiveRange(
            FeaturedCardMetrics.minHorizontalInset,
            FeaturedCardMetrics.maxHorizontalInset,
          ),
        );
      }
    });
  });
}
