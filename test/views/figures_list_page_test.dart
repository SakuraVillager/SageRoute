import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/article_repository.dart';
import 'package:sageroute/data/article_image_repository.dart';
import 'package:sageroute/data/celebrity_repository.dart';
import 'package:sageroute/data/topic_repository.dart';
import 'package:sageroute/models/article_record.dart';
import 'package:sageroute/models/article_image_record.dart';
import 'package:sageroute/models/celebrity_profile.dart';
import 'package:sageroute/models/topic_record.dart';
import 'package:sageroute/theme/color_schemes.dart';
import 'package:sageroute/views/figures_list_page.dart';

void main() {
  Widget buildPage() => MaterialApp(
    home: FiguresListPage(
      articleRepository: ArticleRepository(fetcher: () async => _articles),
      articleImageRepository: ArticleImageRepository(
        fetcher: () async => _articleImages,
      ),
      celebrityRepository: CelebrityRepository(
        fetcher: () async => _celebrities,
      ),
      topicRepository: TopicRepository(fetcher: () async => _topics),
    ),
  );

  testWidgets('presents featured reading and both independent directories', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('精选文章'), findsOneWidget);
    expect(find.text('主题目录'), findsOneWidget);
    expect(find.byKey(const Key('article-row-1')), findsOneWidget);
    await _scrollTo(tester, find.text('人物目录'));
    expect(find.text('人物目录'), findsOneWidget);
    expect(find.byKey(const Key('figure-row-1')), findsOneWidget);
  });

  testWidgets('topic selection does not filter the figure directory', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('topic-filter-江南')));
    await tester.tap(find.byKey(const Key('topic-filter-江南')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('article-row-1')), findsOneWidget);
    expect(find.byKey(const Key('article-row-2')), findsNothing);
    await _scrollTo(tester, find.byKey(const Key('figure-row-1')));
    expect(find.byKey(const Key('figure-row-1')), findsOneWidget);
    expect(find.byKey(const Key('figure-row-2')), findsOneWidget);
  });

  testWidgets('dynasty selection does not filter the topic article directory', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('dynasty-filter-唐')));
    await tester.tap(find.byKey(const Key('dynasty-filter-唐')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('figure-row-1')), findsOneWidget);
    expect(find.byKey(const Key('figure-row-2')), findsNothing);
    await _scrollToStart(tester);
    expect(find.byKey(const Key('article-row-1')), findsOneWidget);
    expect(find.byKey(const Key('article-row-2')), findsOneWidget);
  });

  testWidgets('shows additional figures only after explicit expansion', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.text('人物八'), findsNothing);
    await _scrollToFigures(tester);
    await tester.tap(find.byKey(const Key('dynasty-expand')));
    await tester.pumpAndSettle();

    expect(find.text('人物八'), findsOneWidget);
    expect(find.byKey(const Key('dynasty-expand')), findsOneWidget);
  });

  testWidgets('search presents results within the approved field scope', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('搜索人物、文章、主题'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '钱');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-result-article-1')), findsOneWidget);
    expect(find.text('文章'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '江');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-result-article-1')), findsNothing);
    expect(find.byKey(const Key('search-result-topic-1')), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
  });

  testWidgets('exposes labeled reading and search actions to assistive tech', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('打开精选文章 钱塘湖春行'), findsOneWidget);
    expect(find.bySemanticsLabel('搜索人物、文章、主题'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps primary entry points visible at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: FiguresListPage(
          articleRepository: ArticleRepository(fetcher: () async => _articles),
          articleImageRepository: ArticleImageRepository(
            fetcher: () async => _articleImages,
          ),
          celebrityRepository: CelebrityRepository(
            fetcher: () async => _celebrities,
          ),
          topicRepository: TopicRepository(fetcher: () async => _topics),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('人物'), findsOneWidget);
    expect(find.byTooltip('搜索人物、文章、主题'), findsOneWidget);
    expect(find.text('精选文章'), findsOneWidget);
  });

  testWidgets('shows a retry action when content loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FiguresListPage(
          articleRepository: ArticleRepository(
            fetcher: () async => throw StateError('offline'),
          ),
          celebrityRepository: CelebrityRepository(
            fetcher: () async => _celebrities,
          ),
          topicRepository: TopicRepository(fetcher: () async => _topics),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('人物内容暂时无法加载'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('keeps article discovery available when image media fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FiguresListPage(
          articleRepository: ArticleRepository(fetcher: () async => _articles),
          articleImageRepository: ArticleImageRepository(
            fetcher: () async => throw StateError('media unavailable'),
          ),
          celebrityRepository: CelebrityRepository(
            fetcher: () async => _celebrities,
          ),
          topicRepository: TopicRepository(fetcher: () async => _topics),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('精选文章'), findsOneWidget);
    expect(find.byKey(const Key('article-row-1')), findsOneWidget);
  });

  testWidgets('featured and recommended content use paged carousels', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('featured-page-view')), findsOneWidget);
    await _scrollTo(tester, find.byKey(const Key('recommended-page-view')));
    expect(find.byKey(const Key('recommended-page-view')), findsOneWidget);
  });

  testWidgets('featured articles auto-advance every five seconds and loop', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('精选文章，第 2 篇，共 2 篇'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('精选文章，第 1 篇，共 2 篇'), findsOneWidget);
  });

  testWidgets('featured carousel keeps a leftward transition while looping', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 160));

    final loopingFirst = find.byKey(const Key('featured-virtual-page-2'));
    expect(loopingFirst, findsOneWidget);
    expect(tester.getTopLeft(loopingFirst).dx, greaterThan(0));
  });

  testWidgets('holding a featured article pauses and resets auto-advance', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('featured-page-view'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 5));

    expect(find.bySemanticsLabel('精选文章，第 1 篇，共 2 篇'), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(seconds: 4));
    expect(find.bySemanticsLabel('精选文章，第 1 篇，共 2 篇'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('精选文章，第 2 篇，共 2 篇'), findsOneWidget);
  });

  testWidgets('featured cards use dedicated featured and poster media', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('featured-image-1')), findsOneWidget);
    expect(find.byKey(const Key('featured-poster-1')), findsOneWidget);
  });

  testWidgets('recommended topics expose a themed position indicator', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('recommended-page-view')));
    expect(find.byKey(const Key('recommended-topic-pager')), findsOneWidget);
    expect(find.bySemanticsLabel('推荐主题，第 1 项，共 2 项'), findsOneWidget);
  });

  testWidgets('places the featured pager in the gap before the divider', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('featured-article-pager')), findsOneWidget);
    expect(find.byKey(const Key('section-divider')), findsOneWidget);
    final pagerTop = tester.getTopLeft(
      find.byKey(const Key('featured-article-pager')),
    );
    final dividerTop = tester.getTopLeft(
      find.byKey(const Key('section-divider')),
    );
    expect(pagerTop.dy, lessThan(dividerTop.dy));
  });

  testWidgets('directory results use a leftward slide transition', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('topic-filter-江南')));
    await tester.tap(find.byKey(const Key('topic-filter-江南')));
    await tester.pump(const Duration(milliseconds: 100));

    final animated = find.byKey(const Key('topic-directory-animated'));
    expect(animated, findsOneWidget);
    expect(
      find.descendant(of: animated, matching: find.byType(AnimatedList)),
      findsOneWidget,
    );
    expect(find.byType(ImageFiltered), findsWidgets);
  });

  testWidgets('recommended topic cards open their matching articles', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('recommended-article-1')));
    await tester.tap(find.byKey(const Key('recommended-article-1')));
    await tester.pumpAndSettle();

    expect(find.text('钱塘湖春行'), findsOneWidget);
  });

  testWidgets(
    'recommended topic cards use a neutral surface and fill image frame',
    (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.byKey(const Key('recommended-article-1')));
      final card = find.byKey(const Key('recommended-article-1'));
      final material = tester.widget<Material>(
        find.descendant(of: card, matching: find.byType(Material)),
      );
      expect(material.color, AppColors.neutralDirectory);

      final imageFrame = tester.widget<SizedBox>(
        find.byKey(const Key('recommended-image-frame-1')),
      );
      expect(imageFrame.width, double.infinity);
      expect(imageFrame.height, double.infinity);
    },
  );

  testWidgets('filter labels stay fixed beside independently scrolling chips', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('topic-filter-label')), findsOneWidget);
    await _scrollTo(tester, find.byKey(const Key('dynasty-filter-label')));
    expect(find.byKey(const Key('dynasty-filter-label')), findsOneWidget);
  });

  testWidgets('article rows expose square thumbnail containers', (
    tester,
  ) async {
    await tester.pumpWidget(buildPage());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('article-thumb-1')), findsOneWidget);
    await _scrollTo(tester, find.byKey(const Key('figure-thumb-1')));
    expect(find.byKey(const Key('figure-thumb-1')), findsOneWidget);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final scrollView = find.byKey(const Key('figures-scroll'));
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      final box = tester.renderObject<RenderBox>(target);
      final center = box.localToGlobal(box.size.center(Offset.zero));
      if (center.dy >= 0 && center.dy <= 570) return;
      await tester.drag(scrollView, Offset(0, center.dy > 570 ? -260 : 260));
    } on StateError {
      await tester.drag(scrollView, const Offset(0, -260));
    }
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target);
}

Future<void> _scrollToFigures(WidgetTester tester) async {
  final scrollView = find.byKey(const Key('figures-scroll'));
  for (
    var attempt = 0;
    attempt < 8 && find.byKey(const Key('dynasty-expand')).evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(scrollView, const Offset(0, -320));
    await tester.pumpAndSettle();
  }
  expect(find.byKey(const Key('dynasty-expand')), findsOneWidget);
  await tester.ensureVisible(find.byKey(const Key('dynasty-expand')));
  await tester.pumpAndSettle();
}

Future<void> _scrollToStart(WidgetTester tester) async {
  final scrollView = find.byKey(const Key('figures-scroll'));
  for (
    var attempt = 0;
    attempt < 8 && find.byKey(const Key('article-row-1')).evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(scrollView, const Offset(0, 320));
    await tester.pumpAndSettle();
  }
}

const _articles = <ArticleRecord>[
  ArticleRecord(
    id: 1,
    createdAt: null,
    topic: '江南',
    title: '钱塘湖春行',
    summary: '从白居易笔下看西湖。',
    content: '正文一',
    coverImageUrl: '',
  ),
  ArticleRecord(
    id: 2,
    createdAt: null,
    topic: '赤壁',
    title: '赤壁夜游',
    summary: '沿着江风重读苏轼。',
    content: '正文二',
    coverImageUrl: '',
  ),
];

const _topics = <TopicRecord>[
  TopicRecord(
    id: 1,
    createdAt: null,
    celebrity: '白居易',
    name: '江南',
    description: '江南的诗与行旅。',
  ),
  TopicRecord(
    id: 2,
    createdAt: null,
    celebrity: '苏东坡',
    name: '赤壁',
    description: '山水与文脉。',
  ),
];

const _articleImages = <ArticleImageRecord>[
  ArticleImageRecord(
    id: 1,
    articleId: 1,
    role: ArticleImageRole.featured,
    url: 'https://images.unsplash.com/photo-featured',
    altText: '钱塘湖畔的春日',
    source: 'unsplash',
    photographerName: null,
    attributionUrl: null,
    sortOrder: 0,
    createdAt: null,
  ),
  ArticleImageRecord(
    id: 2,
    articleId: 1,
    role: ArticleImageRole.poster,
    url: 'https://images.unsplash.com/photo-poster',
    altText: '钱塘湖春行海报',
    source: 'unsplash',
    photographerName: null,
    attributionUrl: null,
    sortOrder: 0,
    createdAt: null,
  ),
];

const _celebrities = <CelebrityProfile>[
  CelebrityProfile(
    id: 1,
    name: '白居易',
    dynasty: '唐',
    bioShort: '诗人',
    bioFull: '白居易',
    avatarUrl: '',
    topic: <String>[],
  ),
  CelebrityProfile(
    id: 2,
    name: '苏东坡',
    dynasty: '宋',
    bioShort: '文学家',
    bioFull: '苏轼',
    avatarUrl: '',
    topic: <String>[],
  ),
  CelebrityProfile(
    id: 3,
    name: '人物三',
    dynasty: '唐',
    bioShort: '',
    bioFull: '',
    avatarUrl: '',
    topic: <String>[],
  ),
  CelebrityProfile(
    id: 4,
    name: '人物四',
    dynasty: '宋',
    bioShort: '',
    bioFull: '',
    avatarUrl: '',
    topic: <String>[],
  ),
  CelebrityProfile(
    id: 5,
    name: '人物五',
    dynasty: '唐',
    bioShort: '',
    bioFull: '',
    avatarUrl: '',
    topic: <String>[],
  ),
  CelebrityProfile(
    id: 6,
    name: '人物六',
    dynasty: '宋',
    bioShort: '',
    bioFull: '',
    avatarUrl: '',
    topic: <String>[],
  ),
  CelebrityProfile(
    id: 7,
    name: '人物七',
    dynasty: '唐',
    bioShort: '',
    bioFull: '',
    avatarUrl: '',
    topic: <String>[],
  ),
  CelebrityProfile(
    id: 8,
    name: '人物八',
    dynasty: '宋',
    bioShort: '',
    bioFull: '',
    avatarUrl: '',
    topic: <String>[],
  ),
];
