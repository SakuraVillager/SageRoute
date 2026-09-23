import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// 精选文章卡片的占比策略。
///
/// 卡片不使用固定高度，而是按「当前屏幕可用高度」换算：
///
/// 1. 可用高度 = 屏幕高度 − 顶部安全区（状态栏 / 刘海）− 底部安全区（手势条）
///    − 首屏固定头部 [chromeHeight]；
/// 2. 基准高度 = 可用高度 × [baseHeightFactor]，再夹在 [baseMinHeight] /
///    [baseMaxHeight] 之间（横屏走横屏区间）；
/// 3. 卡片高度 = 基准高度 × [heightScale]。
///
/// 于是同一份布局在任意机型上的观感一致：320×568 的小屏不会一张图顶满首屏，
/// 430×932 的大屏也不会显得单薄；封面小图、内边距同样随卡片高度插值，
/// 避免"图变小了字还那么大"的比例失衡。
///
/// 调比例只需要改本文件的常量，不必翻 UI 代码：
///
/// * 整体变高 / 变矮（各机型一起变）→ 只改 [heightScale]；
/// * 改"卡片占可用高度的多少" → 改 [baseHeightFactor]；
/// * 改小屏下限 / 大屏上限 → 改 [baseMinHeight] / [baseMaxHeight]。
///
/// 注意：这里刻意不依赖父级约束，因为精选卡片位于 `SliverToBoxAdapter` 中，
/// 它拿到的纵向约束是无界的（`constraints.biggest.height == infinity`）。
@immutable
class FeaturedCardMetrics {
  const FeaturedCardMetrics({
    required this.availableHeight,
    required this.cardHeight,
    required this.horizontalInset,
    required this.bottomInset,
    required this.posterWidth,
    required this.posterHeight,
    required this.titleFontSize,
    required this.summaryFontSize,
    required this.posterGap,
    required this.titleGap,
  });

  /// 首屏固定占用：标题行（上 18 + 行高 48 + 下 8）+
  /// 「精选文章」标题块（上 6 + 文本约 34 + 下 10）。
  static const chromeHeight = 124.0;

  /// 高度整体缩放系数。
  ///
  /// 卡片高度、封面小图与内边距一起乘以这个系数，用来一次性把精选区调高 /
  /// 调矮，且所有机型同步变化：`1.0` 是初版设计，当前的 `1.25` 表示
  /// 「比初版再高 25%」。字号不跟着放大，免得大屏上标题喧宾夺主。
  static const heightScale = 1.25;

  /// 卡片高度占可用高度的比例。
  static const baseHeightFactor = 0.44;

  /// 竖屏卡片高度夹取范围（逻辑像素）：下限保证小屏封面可读，上限避免大屏过于霸道。
  static const baseMinHeight = 310.0;
  static const baseMaxHeight = 390.0;

  /// 横屏（或宽扁窗口）下的夹取范围。
  static const baseMinLandscapeHeight = 248.0;
  static const baseMaxLandscapeHeight = 300.0;

  /// 缩放后的实际夹取范围，即卡片在各机型上能达到的最小 / 最大高度。
  static const minHeight = baseMinHeight * heightScale;
  static const maxHeight = baseMaxHeight * heightScale;
  static const minLandscapeHeight = baseMinLandscapeHeight * heightScale;
  static const maxLandscapeHeight = baseMaxLandscapeHeight * heightScale;

  /// 横向留白随宽度插值的范围（设计稿基准 15）。
  static const minHorizontalInset = 12.0;
  static const maxHorizontalInset = 15.0;

  /// 可用区域宽高比达到该值即按横屏 / 宽扁窗口处理。
  static const wideLayoutAspectRatio = 1.2;

  /// 屏幕高度扣除安全区与首屏固定 chrome 后的可用高度。
  final double availableHeight;
  final double cardHeight;
  final double horizontalInset;
  final double bottomInset;
  final double posterWidth;
  final double posterHeight;
  final double titleFontSize;
  final double summaryFontSize;
  final double posterGap;
  final double titleGap;

  /// 按整机屏幕尺寸与安全区推导一组尺寸。
  ///
  /// [width] 为屏幕宽度（用于横向留白）；[padding] 传 `MediaQuery.paddingOf`，
  /// 且必须在 Scaffold 之外读取（Scaffold 会把 body 的顶部 padding 清零）。
  factory FeaturedCardMetrics.fromScreen({
    required double width,
    required double height,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final availableHeight =
        (height - padding.top - padding.bottom - chromeHeight).clamp(
          80.0,
          double.infinity,
        );
    return FeaturedCardMetrics.fromAvailableHeight(
      availableHeight: availableHeight,
      width: width,
    );
  }

  /// 供测试与特殊布局直接指定可用高度。
  factory FeaturedCardMetrics.fromAvailableHeight({
    required double availableHeight,
    required double width,
  }) {
    final portrait = (width / availableHeight) < wideLayoutAspectRatio;
    final baseHeight = portrait
        ? (availableHeight * baseHeightFactor).clamp(
            baseMinHeight,
            baseMaxHeight,
          )
        : (availableHeight * baseHeightFactor).clamp(
            baseMinLandscapeHeight,
            baseMaxLandscapeHeight,
          );
    // 内部元素按「基准高度在基准区间里的位置」插值，再单独缩放尺寸，
    // 这样调高卡片不会连带把字号也放大。
    final progress =
        ((baseHeight - baseMinHeight) / (baseMaxHeight - baseMinHeight)).clamp(
          0.0,
          1.0,
        );
    final inset = (width * 0.04).clamp(minHorizontalInset, maxHorizontalInset);
    final posterHeight = lerpDouble(60, 68, progress)! * heightScale;

    return FeaturedCardMetrics(
      availableHeight: availableHeight,
      cardHeight: baseHeight * heightScale,
      horizontalInset: inset,
      bottomInset: lerpDouble(14, 18, progress)! * heightScale,
      posterWidth: posterHeight * (48 / 70),
      posterHeight: posterHeight,
      titleFontSize: lerpDouble(20, 22, progress)!,
      summaryFontSize: lerpDouble(12, 13, progress)!,
      posterGap: lerpDouble(10, 12, progress)! * heightScale,
      titleGap: lerpDouble(4, 5, progress)! * heightScale,
    );
  }
}
