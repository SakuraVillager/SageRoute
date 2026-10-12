import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/components/web/web_workspace.dart';
import 'package:sageroute/models/article_media.dart';
import 'package:sageroute/models/article_record.dart';
import 'package:sageroute/models/celebrity_profile.dart';
import 'package:sageroute/models/topic_record.dart';
import 'package:sageroute/theme/app_theme.dart';
import 'package:sageroute/theme/web_theme.dart';
import 'package:sageroute/views/figures_list_page.dart';

final _articles = List.generate(
  8,
  (index) => ArticleMedia(
    article: ArticleRecord(
      id: index + 1,
      createdAt: null,
      topic: index.isEven ? '山水' : '诗词',
      title: '文章 ${index + 1}：沿着历史的足迹出发',
      summary: '在山水之间认识一位人物，读懂一段故事，再规划属于自己的旅程。',
      content: '',
      coverImageUrl: '',
    ),
    images: const [],
  ),
);
final _figures = List.generate(
  8,
  (index) => CelebrityProfile(
    id: index + 1,
    name: '人物 ${index + 1}',
    dynasty: index.isEven ? '唐' : '宋',
    bioShort: '沿着诗人的足迹探索山水与历史。',
    bioFull: '',
    avatarUrl: '',
    topic: const [],
  ),
);
const _topics = [
  TopicRecord(
    id: 1,
    createdAt: null,
    celebrity: null,
    name: '山水',
    description: '山水之间',
  ),
  TopicRecord(
    id: 2,
    createdAt: null,
    celebrity: null,
    name: '诗词',
    description: '诗词之路',
  ),
  TopicRecord(
    id: 3,
    createdAt: null,
    celebrity: null,
    name: '无文章主题',
    description: '敬请期待',
  ),
];

class _Harness extends StatefulWidget {
  const _Harness({
    this.articles,
    this.reduced = true,
    this.scale = 1,
    this.sidebar = false,
    this.onHome,
    this.onSearch,
    this.onArticle,
    this.onFigure,
  });
  final List<ArticleMedia>? articles;
  final bool reduced;
  final double scale;
  final bool sidebar;
  final VoidCallback? onHome;
  final VoidCallback? onSearch;
  final Future<void> Function(ArticleRecord)? onArticle;
  final ValueChanged<CelebrityProfile>? onFigure;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String topic = '全部';
  String dynasty = '全部';
  bool expandedArticles = false;
  bool expandedFigures = false;
  bool visible = true;

  void setVisible(bool value) => setState(() => visible = value);

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: browserTheme(AppTheme.lightTheme),
    home: Builder(
      builder: (context) {
        final content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: widget.reduced,
            textScaler: TextScaler.linear(widget.scale),
          ),
          child: TickerMode(
            enabled: visible,
            child: FiguresWebContent(
              articles: widget.articles ?? _articles,
              figures: _figures,
              topics: _topics,
              selectedTopic: topic,
              selectedDynasty: dynasty,
              showAllArticles: expandedArticles,
              showAllFigures: expandedFigures,
              onTopicChanged: (value) => setState(() {
                topic = value;
                expandedArticles = false;
              }),
              onDynastyChanged: (value) => setState(() {
                dynasty = value;
                expandedFigures = false;
              }),
              onArticleExpansionChanged: () =>
                  setState(() => expandedArticles = !expandedArticles),
              onFigureExpansionChanged: () =>
                  setState(() => expandedFigures = !expandedFigures),
              onOpenArticle: widget.onArticle ?? (_) async {},
              onOpenFigure: widget.onFigure ?? (_) {},
              onOpenSearch: widget.onSearch ?? () {},
              onHome: widget.onHome ?? () {},
            ),
          ),
        );
        return widget.sidebar
            ? WebWorkspace(
                selectedIndex: 1,
                onSelected: (index) {
                  if (index == 0) widget.onHome?.call();
                },
                child: content,
              )
            : content;
      },
    ),
  );
}

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(1280, 800),
    const Size(1440, 900),
    const Size(1920, 1080),
  ]) {
    testWidgets('desktop ${size.width} has three aligned article columns', (
      tester,
    ) async {
      await _size(tester, size);
      await tester.pumpWidget(const _Harness(sidebar: true));
      await tester.pumpAndSettle();
      final rects = [
        for (var id = 1; id <= 4; id++)
          tester.getRect(find.byKey(Key('web-article-$id'))),
      ];
      expect(rects[0].top, rects[1].top);
      expect(rects[1].top, rects[2].top);
      expect(rects[2].left - rects[1].right, closeTo(24, .1));
      expect(rects[3].top, greaterThan(rects[0].bottom));
      expect(find.byKey(const Key('web-article-7')), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('web-featured-frame'))).height,
        closeTo((size.height * .52).clamp(360, 520), .1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in [(850.0, 2), (580.0, 1), (375.0, 1)]) {
    testWidgets(
      'content width ${entry.$1} uses ${entry.$2} columns at 200% text',
      (tester) async {
        await _size(tester, Size(entry.$1, 900));
        await tester.pumpWidget(const _Harness(scale: 2));
        await tester.pumpAndSettle();
        final first = tester.getRect(find.byKey(const Key('web-article-1')));
        final nextRow = tester.getRect(
          find.byKey(Key('web-article-${entry.$2 + 1}')),
        );
        expect(nextRow.top, greaterThan(first.bottom));
        await _show(tester, find.byKey(const Key('web-figure-1')));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'filters are independent and expansion resets without losing scroll',
    (tester) async {
      await _size(tester, const Size(1440, 900));
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();
      await _show(tester, find.byKey(const Key('web-topic-expand')));
      await tester.tap(find.byKey(const Key('web-topic-expand')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('web-article-8')), findsOneWidget);
      await _show(tester, find.byKey(const Key('web-topic-filter-山水')));
      await tester.tap(find.byKey(const Key('web-topic-filter-山水')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('web-article-2')), findsNothing);
      expect(find.byKey(const Key('web-article-7')), findsOneWidget);
      expect(find.byKey(const Key('web-figure-2')), findsOneWidget);
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const Key('figures-web-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scroll.position.pixels, greaterThan(0));
      await tester.tap(find.byKey(const Key('web-topic-filter-全部')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('web-article-7')), findsNothing);
      await _show(tester, find.byKey(const Key('web-dynasty-filter-宋')));
      await tester.tap(find.byKey(const Key('web-dynasty-filter-宋')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('web-figure-1')), findsNothing);
      expect(find.byKey(const Key('web-article-1')), findsOneWidget);
    },
  );

  testWidgets(
    'brand, search, articles, recommended topics and figures dispatch actions',
    (tester) async {
      await _size(tester, const Size(1440, 900));
      var home = 0;
      var searches = 0;
      int? article;
      int? figure;
      await tester.pumpWidget(
        _Harness(
          sidebar: true,
          onHome: () => home++,
          onSearch: () => searches++,
          onArticle: (value) async => article = value.id,
          onFigure: (value) => figure = value.id,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('figures-brand-home')));
      await tester.tap(find.byKey(const Key('web-brand-home')));
      await tester.tap(find.byTooltip('搜索人物、文章、主题'));
      expect(home, 2);
      expect(searches, 1);
      await tester.tap(find.byKey(const Key('web-featured-1')));
      expect(article, 1);
      await _show(tester, find.byKey(const Key('web-article-2')));
      await tester.tap(find.byKey(const Key('web-article-2')));
      expect(article, 2);
      await _show(tester, find.byKey(const Key('web-recommended-1')));
      await tester.tap(find.byKey(const Key('web-recommended-1')));
      expect(article, 1);
      await _show(tester, find.byKey(const Key('web-figure-2')));
      await tester.tap(find.byKey(const Key('web-figure-2')));
      expect(figure, 2);
    },
  );

  testWidgets(
    'reduced motion disables autoplay but supports looping and keyboard navigation',
    (tester) async {
      await _size(tester, const Size(1440, 900));
      await tester.pumpWidget(const _Harness());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('01 / 08'), findsOneWidget);
      await tester.tap(find.byTooltip('上一篇精选'));
      await tester.pumpAndSettle();
      expect(find.text('08 / 08'), findsOneWidget);
      await tester.tap(find.byTooltip('下一篇精选'));
      await tester.pumpAndSettle();
      expect(find.text('01 / 08'), findsOneWidget);
      Focus.of(tester.element(find.byTooltip('下一篇精选'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('02 / 08'), findsOneWidget);
    },
  );

  testWidgets('autoplay pauses on hover and resumes after leaving', (
    tester,
  ) async {
    await _size(tester, const Size(1440, 900));
    await tester.pumpWidget(const _Harness(reduced: false));
    await tester.pump(const Duration(milliseconds: 700));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: tester.getCenter(find.byKey(const Key('web-featured-frame'))),
    );
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('01 / 08'), findsOneWidget);
    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('02 / 08'), findsOneWidget);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('autoplay pauses while inactive, hidden, or opening an article', (
    tester,
  ) async {
    await _size(tester, const Size(1440, 900));
    final opened = Completer<void>();
    await tester.pumpWidget(
      _Harness(reduced: false, onArticle: (_) => opened.future),
    );
    await tester.pump(const Duration(milliseconds: 700));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('01 / 08'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.setVisible(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('01 / 08'), findsOneWidget);
    state.setVisible(true);
    await tester.pump();
    await tester.tap(find.byKey(const Key('web-featured-1')));
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('01 / 08'), findsOneWidget);
    opened.complete();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'empty and single article states omit unnecessary carousel controls',
    (tester) async {
      await _size(tester, const Size(1440, 900));
      await tester.pumpWidget(const _Harness(articles: []));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('web-featured-frame')), findsNothing);
      expect(find.text('这个主题下还没有推送文章'), findsOneWidget);
      await tester.pumpWidget(_Harness(articles: [_articles.first]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('web-featured-frame')), findsOneWidget);
      expect(find.byTooltip('下一篇精选'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
