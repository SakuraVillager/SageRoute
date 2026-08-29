import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../components/content_carousel.dart';
import '../components/filterable_directory_section.dart';
import '../data/article_repository.dart';
import '../data/article_image_repository.dart';
import '../data/celebrity_repository.dart';
import '../data/topic_repository.dart';
import '../models/article_record.dart';
import '../models/article_image_record.dart';
import '../models/article_media.dart';
import '../models/celebrity_profile.dart';
import '../models/figure.dart';
import '../models/topic_record.dart';
import '../theme/color_schemes.dart';
import '../utils/slide_route.dart';
import 'article_detail_page.dart';
import 'figure_detail_page.dart';

const _directorySurface = AppColors.neutralDirectory;
const _pageInset = EdgeInsets.symmetric(horizontal: 15);

/// Reading-first entry point for article, topic, and historical figure content.
class FiguresListPage extends StatefulWidget {
  const FiguresListPage({
    super.key,
    this.articleRepository,
    this.articleImageRepository,
    this.celebrityRepository,
    this.topicRepository,
  });

  final ArticleRepository? articleRepository;
  final ArticleImageRepository? articleImageRepository;
  final CelebrityRepository? celebrityRepository;
  final TopicRepository? topicRepository;

  @override
  State<FiguresListPage> createState() => _FiguresListPageState();
}

class _FiguresListPageState extends State<FiguresListPage> {
  late final ArticleRepository _articleRepository =
      widget.articleRepository ?? const ArticleRepository();
  late final CelebrityRepository _celebrityRepository =
      widget.celebrityRepository ?? const CelebrityRepository();
  late final TopicRepository _topicRepository =
      widget.topicRepository ?? const TopicRepository();
  late final ArticleImageRepository _articleImageRepository =
      widget.articleImageRepository ?? const ArticleImageRepository();
  late Future<_FiguresPageData> _pageFuture;

  String _selectedTopic = _allFilter;
  String _selectedDynasty = _allFilter;
  bool _showAllArticles = false;
  bool _showAllFigures = false;

  static const _allFilter = '全部';

  @override
  void initState() {
    super.initState();
    _pageFuture = _loadPage();
  }

  Future<_FiguresPageData> _loadPage() async {
    final data = await Future.wait<Object>([
      _articleRepository.fetchArticles(),
      _celebrityRepository.fetchCelebrities(),
      _topicRepository.fetchTopics(),
    ]);
    final images = await _loadArticleImages();
    return _FiguresPageData(
      articles: data[0] as List<ArticleRecord>,
      images: images,
      celebrities: data[1] as List<CelebrityProfile>,
      topics: data[2] as List<TopicRecord>,
    );
  }

  Future<List<ArticleImageRecord>> _loadArticleImages() async {
    try {
      return await _articleImageRepository.fetchArticleImages();
    } catch (_) {
      return const <ArticleImageRecord>[];
    }
  }

  void _retry() => setState(() => _pageFuture = _loadPage());

  void _openArticle(ArticleRecord article) {
    Navigator.of(
      context,
    ).push(slideFromRightRoute(ArticleDetailPage(article: article)));
  }

  Future<void> _openFeaturedArticle(ArticleRecord article) => Navigator.of(
    context,
  ).push(slideFromRightRoute(ArticleDetailPage(article: article)));

  void _openFigure(CelebrityProfile celebrity) {
    Navigator.of(context).push(
      slideFromRightRoute(
        FigureDetailPage(
          figure: Figure(
            id: celebrity.id.toString(),
            name: celebrity.name,
            dynasty: celebrity.dynasty,
            shortDesc: celebrity.bioShort,
            description: celebrity.bioFull,
            imageUrl: celebrity.avatarUrl,
          ),
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _SearchPage(
          articleRepository: _articleRepository,
          celebrityRepository: _celebrityRepository,
          topicRepository: _topicRepository,
          onOpenArticle: _openArticle,
          onOpenFigure: _openFigure,
          onSelectTopic: (topic) {
            setState(() {
              _selectedTopic = topic;
              _showAllArticles = false;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_FiguresPageData>(
    future: _pageFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const _PageStatus(label: '正在加载人物内容', loading: true);
      }
      if (snapshot.hasError) {
        return _PageStatus(
          label: '人物内容暂时无法加载',
          actionLabel: '重试',
          onAction: _retry,
        );
      }
      return _FiguresContent(
        data: snapshot.data!,
        selectedTopic: _selectedTopic,
        selectedDynasty: _selectedDynasty,
        showAllArticles: _showAllArticles,
        showAllFigures: _showAllFigures,
        onOpenSearch: _openSearch,
        onOpenArticle: _openArticle,
        onOpenFeaturedArticle: _openFeaturedArticle,
        onOpenFigure: _openFigure,
        onTopicChanged: (topic) => setState(() {
          _selectedTopic = topic;
          _showAllArticles = false;
        }),
        onDynastyChanged: (dynasty) => setState(() {
          _selectedDynasty = dynasty;
          _showAllFigures = false;
        }),
        onArticleExpansionChanged: () =>
            setState(() => _showAllArticles = !_showAllArticles),
        onFigureExpansionChanged: () =>
            setState(() => _showAllFigures = !_showAllFigures),
      );
    },
  );
}

class _FiguresPageData {
  const _FiguresPageData({
    required this.articles,
    required this.images,
    required this.celebrities,
    required this.topics,
  });

  final List<ArticleRecord> articles;
  final List<ArticleImageRecord> images;
  final List<CelebrityProfile> celebrities;
  final List<TopicRecord> topics;
}

class _PageStatus extends StatelessWidget {
  const _PageStatus({
    required this.label,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: SafeArea(
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) const CircularProgressIndicator(),
              if (loading) const SizedBox(height: 16),
              Text(label, style: const TextStyle(color: AppColors.brandInk)),
              if (onAction != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _FiguresContent extends StatelessWidget {
  const _FiguresContent({
    required this.data,
    required this.selectedTopic,
    required this.selectedDynasty,
    required this.showAllArticles,
    required this.showAllFigures,
    required this.onOpenSearch,
    required this.onOpenArticle,
    required this.onOpenFeaturedArticle,
    required this.onOpenFigure,
    required this.onTopicChanged,
    required this.onDynastyChanged,
    required this.onArticleExpansionChanged,
    required this.onFigureExpansionChanged,
  });

  final _FiguresPageData data;
  final String selectedTopic;
  final String selectedDynasty;
  final bool showAllArticles;
  final bool showAllFigures;
  final VoidCallback onOpenSearch;
  final ValueChanged<ArticleRecord> onOpenArticle;
  final Future<void> Function(ArticleRecord) onOpenFeaturedArticle;
  final ValueChanged<CelebrityProfile> onOpenFigure;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<String> onDynastyChanged;
  final VoidCallback onArticleExpansionChanged;
  final VoidCallback onFigureExpansionChanged;

  @override
  Widget build(BuildContext context) {
    final topicNames = _unique(<String>[
      ...data.topics.map((topic) => topic.name),
      ...data.articles.map((article) => article.topic),
    ]);
    final dynasties = _unique(data.celebrities.map((figure) => figure.dynasty));
    final articles = selectedTopic == _FiguresListPageState._allFilter
        ? data.articles
        : data.articles
              .where((article) => article.topic == selectedTopic)
              .toList(growable: false);
    final figures = selectedDynasty == _FiguresListPageState._allFilter
        ? data.celebrities
        : data.celebrities
              .where((figure) => figure.dynasty == selectedDynasty)
              .toList(growable: false);
    final visibleArticles = _visibleItems(articles, showAllArticles);
    final visibleFigures = _visibleItems(figures, showAllFigures);
    final articleMedia = <int, ArticleMedia>{
      for (final article in data.articles)
        article.id: ArticleMedia(
          article: article,
          images: data.images
              .where((image) => image.articleId == article.id)
              .toList(growable: false),
        ),
    };
    final featured = data.articles
        .map((article) => articleMedia[article.id]!)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: CustomScrollView(
          key: const Key('figures-scroll'),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '人物',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontFamily: 'serif',
                              color: AppColors.brandInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Semantics(
                        button: true,
                        label: '搜索人物、文章、主题',
                        child: ExcludeSemantics(
                          child: IconButton(
                            tooltip: '搜索人物、文章、主题',
                            onPressed: onOpenSearch,
                            icon: const Icon(Icons.search_outlined),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (featured.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 6, 15, 10),
                      child: Text(
                        '精选文章',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.brandInk,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _FeaturedArticle(
                      articles: featured,
                      onTap: onOpenFeaturedArticle,
                    ),
                  ],
                ),
              ),
            const SliverToBoxAdapter(
              child: _SectionDivider(key: Key('section-divider')),
            ),
            SliverToBoxAdapter(
              child: FilterableDirectorySection<ArticleRecord>(
                title: '主题目录',
                filterLabel: '主题',
                options: topicNames,
                selectedOption: selectedTopic,
                emptyLabel: '这个主题下还没有推送文章',
                items: visibleArticles,
                totalCount: articles.length,
                expanded: showAllArticles,
                onOptionChanged: onTopicChanged,
                onExpansionChanged: onArticleExpansionChanged,
                filterKeyPrefix: 'topic',
                itemId: (article) => 'article-${article.id}',
                itemBuilder: (article) => _ArticleRow(
                  media: articleMedia[article.id]!,
                  onTap: () => onOpenArticle(article),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _RecommendedTopics(
                topics: data.topics,
                articles: featured,
                onOpenArticle: onOpenArticle,
              ),
            ),
            SliverToBoxAdapter(
              child: FilterableDirectorySection<CelebrityProfile>(
                title: '人物目录',
                filterLabel: '朝代',
                options: dynasties,
                selectedOption: selectedDynasty,
                emptyLabel: '这个朝代下还没有人物',
                items: visibleFigures,
                totalCount: figures.length,
                expanded: showAllFigures,
                onOptionChanged: onDynastyChanged,
                onExpansionChanged: onFigureExpansionChanged,
                filterKeyPrefix: 'dynasty',
                itemId: (figure) => 'figure-${figure.id}',
                itemBuilder: (figure) => _FigureRow(
                  figure: figure,
                  onTap: () => onOpenFigure(figure),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 98)),
          ],
        ),
      ),
    );
  }
}

class _FeaturedArticle extends StatefulWidget {
  const _FeaturedArticle({required this.articles, required this.onTap});

  final List<ArticleMedia> articles;
  final Future<void> Function(ArticleRecord) onTap;

  @override
  State<_FeaturedArticle> createState() => _FeaturedArticleState();
}

class _FeaturedArticleState extends State<_FeaturedArticle> {
  late final PageController _controller;
  Timer? _autoAdvanceTimer;
  var _currentPage = 0;
  var _physicalPage = 0;
  var _isAutoAdvancing = false;
  var _isHoldingArticle = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant _FeaturedArticle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.articles.length != widget.articles.length) {
      _currentPage = widget.articles.isEmpty
          ? 0
          : _currentPage.clamp(0, widget.articles.length - 1).toInt();
      _scheduleAutoAdvance();
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (widget.articles.length < 2 || _isHoldingArticle) return;
    _autoAdvanceTimer = Timer(const Duration(seconds: 5), _advance);
  }

  Future<void> _advance() async {
    if (!mounted ||
        !_controller.hasClients ||
        widget.articles.length < 2 ||
        _isHoldingArticle) {
      return;
    }
    _isAutoAdvancing = true;
    await _controller.animateToPage(
      _physicalPage + 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    _isAutoAdvancing = false;
    if (mounted) _scheduleAutoAdvance();
  }

  void _onPageChanged(int page) {
    _physicalPage = page;
    setState(() => _currentPage = page % widget.articles.length);
    if (!_isAutoAdvancing) _scheduleAutoAdvance();
  }

  void _onHoldStart(LongPressStartDetails _) {
    _isHoldingArticle = true;
    _autoAdvanceTimer?.cancel();
  }

  void _onHoldEnd(LongPressEndDetails _) {
    _isHoldingArticle = false;
    _scheduleAutoAdvance();
  }

  void _onHoldCancel() {
    if (!_isHoldingArticle) return;
    _isHoldingArticle = false;
    _scheduleAutoAdvance();
  }

  Future<void> _openArticle(ArticleRecord article) async {
    _autoAdvanceTimer?.cancel();
    await widget.onTap(article);
    if (mounted) _scheduleAutoAdvance();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: '精选文章，第 ${_currentPage + 1} 篇，共 ${widget.articles.length} 篇',
    child: Column(
      children: [
        SizedBox(
          key: const Key('featured-page-view'),
          height: 380,
          child: GestureDetector(
            onLongPressStart: _onHoldStart,
            onLongPressEnd: _onHoldEnd,
            onLongPressCancel: _onHoldCancel,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final media = widget.articles[index % widget.articles.length];
                return _FeaturedArticleCard(
                  key: Key('featured-virtual-page-$index'),
                  media: media,
                  onTap: () => _openArticle(media.article),
                );
              },
            ),
          ),
        ),
        SizedBox(
          key: const Key('featured-article-pager'),
          height: 30,
          child: Center(
            child: _ArticlePager(
              count: widget.articles.length,
              currentIndex: _currentPage,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FeaturedArticleCard extends StatelessWidget {
  const _FeaturedArticleCard({
    super.key,
    required this.media,
    required this.onTap,
  });

  final ArticleMedia media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: '打开精选文章 ${media.article.title}',
    child: ExcludeSemantics(
      child: Material(
        color: AppColors.brandNearBlack,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 380,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ArticleImage(
                  key: Key('featured-image-${media.article.id}'),
                  article: media.article,
                  imageUrl: media.urlFor(ArticleImageRole.featured),
                  altText: media.altTextFor(ArticleImageRole.featured),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xD92D1D1B)],
                      stops: [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 18,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _CoverMark(
                        key: Key('featured-poster-${media.article.id}'),
                        media: media,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              media.article.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              media.article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'serif',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArticlePager extends StatelessWidget {
  const _ArticlePager({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List<Widget>.generate(count, (index) {
      final active = index == currentIndex;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: active
            ? Container(
                width: 25,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(3),
                ),
              )
            : const _PagerDot(),
      );
    }),
  );
}

class _PagerDot extends StatelessWidget {
  const _PagerDot();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 5,
    height: 5,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sageMuted,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 25, thickness: 6, color: _directorySurface);
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.media, required this.onTap});

  final ArticleMedia media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('article-row-${media.article.id}'),
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 16,
    leading: _ArticleThumbnail(media: media),
    title: Text(
      media.article.title,
      style: const TextStyle(
        color: AppColors.brandInk,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      media.article.summary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({required this.figure, required this.onTap});

  final CelebrityProfile figure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('figure-row-${figure.id}'),
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 16,
    leading: _InitialAvatar(
      key: Key('figure-thumb-${figure.id}'),
      name: figure.name,
      imageUrl: figure.avatarUrl,
    ),
    title: Text(
      figure.name,
      style: const TextStyle(
        color: AppColors.brandInk,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text('${figure.dynasty} · ${figure.bioShort}'),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _RecommendedTopics extends StatelessWidget {
  const _RecommendedTopics({
    required this.topics,
    required this.articles,
    required this.onOpenArticle,
  });

  final List<TopicRecord> topics;
  final List<ArticleMedia> articles;
  final ValueChanged<ArticleRecord> onOpenArticle;

  @override
  Widget build(BuildContext context) => ContentCarousel<TopicRecord>(
    title: '推荐主题',
    items: topics,
    pageViewKey: const Key('recommended-page-view'),
    showPositionIndicator: true,
    positionIndicatorKey: const Key('recommended-topic-pager'),
    inactiveIndicatorColor: AppColors.white,
    itemBuilder: (context, topic, distance) {
      final scale = 1 - (distance * 0.17);
      final article = _mediaForTopic(articles, topic.name);
      return Center(
        child: Transform.scale(
          scale: scale,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: distance * 2.8,
              sigmaY: distance * 2.8,
            ),
            child: _TopicCard(
              key: article == null
                  ? Key('recommended-topic-${topic.id}')
                  : Key('recommended-article-${article.article.id}'),
              topic: topic,
              article: article,
              onTap: article == null
                  ? null
                  : () => onOpenArticle(article.article),
            ),
          ),
        ),
      );
    },
  );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    super.key,
    required this.topic,
    required this.article,
    required this.onTap,
  });

  final TopicRecord topic;
  final ArticleMedia? article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    enabled: onTap != null,
    label: onTap == null
        ? '推荐主题 ${topic.name}，暂无相关文章'
        : '打开推荐文章 ${article!.article.title}',
    child: Material(
      color: AppColors.neutralDirectory,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: AppColors.neutralDirectory,
                  alignment: Alignment.center,
                  child: SizedBox.expand(
                    key: article == null
                        ? null
                        : Key('recommended-image-frame-${article!.article.id}'),
                    child: article == null
                        ? Center(
                            child: Text(
                              topic.name,
                              style: const TextStyle(
                                color: AppColors.brandDark,
                              ),
                            ),
                          )
                        : _ArticleImage(
                            article: article!.article,
                            imageUrl: article!.urlFor(
                              ArticleImageRole.featured,
                            ),
                            altText: article!.altTextFor(
                              ArticleImageRole.featured,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                article?.article.title ?? topic.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.brandInk,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                article?.article.summary ?? topic.description ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.sageMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

ArticleMedia? _mediaForTopic(List<ArticleMedia> articles, String topicName) {
  for (final article in articles) {
    if (article.article.topic == topicName) return article;
  }
  return null;
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({super.key, required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 64,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        image: imageUrl.isEmpty
            ? null
            : DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: imageUrl.isEmpty
          ? Center(
              child: Text(
                name.isEmpty ? '?' : name.characters.first,
                style: const TextStyle(color: AppColors.brandDark),
              ),
            )
          : null,
    ),
  );
}

class _ArticleThumbnail extends StatelessWidget {
  const _ArticleThumbnail({required this.media});

  final ArticleMedia media;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: Key('article-thumb-${media.article.id}'),
    width: 82,
    height: 82,
    child: _ArticleImage(
      article: media.article,
      imageUrl: media.urlFor(ArticleImageRole.cover),
      altText: media.altTextFor(ArticleImageRole.cover),
    ),
  );
}

class _CoverMark extends StatelessWidget {
  const _CoverMark({super.key, required this.media});

  final ArticleMedia media;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 70,
    child: ClipRect(
      child: _ArticleImage(
        article: media.article,
        imageUrl: media.urlFor(ArticleImageRole.poster),
        altText: media.altTextFor(ArticleImageRole.poster),
      ),
    ),
  );
}

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({
    super.key,
    required this.article,
    required this.imageUrl,
    this.altText,
  });

  final ArticleRecord article;
  final String imageUrl;
  final String? altText;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: AppColors.brandDark,
        alignment: Alignment.center,
        child: Text(
          article.topic,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
    return Image.network(
      imageUrl,
      semanticLabel: altText,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(color: AppColors.brandDark),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage({
    required this.articleRepository,
    required this.celebrityRepository,
    required this.topicRepository,
    required this.onOpenArticle,
    required this.onOpenFigure,
    required this.onSelectTopic,
  });

  final ArticleRepository articleRepository;
  final CelebrityRepository celebrityRepository;
  final TopicRepository topicRepository;
  final ValueChanged<ArticleRecord> onOpenArticle;
  final ValueChanged<CelebrityProfile> onOpenFigure;
  final ValueChanged<String> onSelectTopic;

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _controller = TextEditingController();
  Future<_SearchResults>? _searchFuture;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searchFuture =
          Future.wait<Object>([
            widget.celebrityRepository.searchByName(query),
            widget.articleRepository.searchByTitle(query),
            widget.topicRepository.searchByName(query),
          ]).then(
            (data) => _SearchResults(
              celebrities: data[0] as List<CelebrityProfile>,
              articles: data[1] as List<ArticleRecord>,
              topics: data[2] as List<TopicRecord>,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    appBar: AppBar(
      backgroundColor: AppColors.white,
      title: const Text('搜索'),
      leading: IconButton(
        tooltip: '关闭搜索',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: _pageInset,
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '搜索人物、文章、主题',
                suffixIcon: IconButton(
                  tooltip: '执行搜索',
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _SearchResultsView(future: _searchFuture, widget: widget),
          ),
        ],
      ),
    ),
  );
}

class _SearchResults {
  const _SearchResults({
    required this.celebrities,
    required this.articles,
    required this.topics,
  });

  final List<CelebrityProfile> celebrities;
  final List<ArticleRecord> articles;
  final List<TopicRecord> topics;

  bool get isEmpty => celebrities.isEmpty && articles.isEmpty && topics.isEmpty;
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({required this.future, required this.widget});

  final Future<_SearchResults>? future;
  final _SearchPage widget;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const Center(child: Text('输入关键词开始搜索'));
    }
    return FutureBuilder<_SearchResults>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('搜索失败，请重试'));
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(child: Text('未找到匹配结果'));
        }
        return ListView(
          children: [
            for (final article in results.articles)
              ListTile(
                key: Key('search-result-article-${article.id}'),
                title: Text(article.title),
                subtitle: const Text('文章'),
                onTap: () => widget.onOpenArticle(article),
              ),
            for (final celebrity in results.celebrities)
              ListTile(
                key: Key('search-result-figure-${celebrity.id}'),
                title: Text(celebrity.name),
                subtitle: const Text('人物'),
                onTap: () => widget.onOpenFigure(celebrity),
              ),
            for (final topic in results.topics)
              ListTile(
                key: Key('search-result-topic-${topic.id}'),
                title: Text(topic.name),
                subtitle: const Text('主题'),
                onTap: () {
                  widget.onSelectTopic(topic.name);
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }
}

List<String> _unique(Iterable<String> values) {
  final seen = <String>{};
  return <String>[
    _FiguresListPageState._allFilter,
    ...values.where((value) => value.isNotEmpty && seen.add(value)),
  ];
}

List<T> _visibleItems<T>(List<T> items, bool expanded) =>
    expanded || items.length <= 7
    ? items
    : items.take(7).toList(growable: false);
