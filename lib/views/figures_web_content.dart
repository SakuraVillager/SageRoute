part of 'figures_list_page.dart';

/// Browser presentation. Data, filters and navigation remain owned by the page.
class FiguresWebContent extends StatelessWidget {
  const FiguresWebContent({
    super.key,
    required this.articles,
    required this.figures,
    required this.topics,
    required this.selectedTopic,
    required this.selectedDynasty,
    required this.showAllArticles,
    required this.showAllFigures,
    required this.onTopicChanged,
    required this.onDynastyChanged,
    required this.onArticleExpansionChanged,
    required this.onFigureExpansionChanged,
    required this.onOpenArticle,
    required this.onOpenFigure,
    required this.onOpenSearch,
    required this.onHome,
  });

  final List<ArticleMedia> articles;
  final List<CelebrityProfile> figures;
  final List<TopicRecord> topics;
  final String selectedTopic;
  final String selectedDynasty;
  final bool showAllArticles;
  final bool showAllFigures;
  final ValueChanged<String> onTopicChanged;
  final ValueChanged<String> onDynastyChanged;
  final VoidCallback onArticleExpansionChanged;
  final VoidCallback onFigureExpansionChanged;
  final Future<void> Function(ArticleRecord) onOpenArticle;
  final ValueChanged<CelebrityProfile> onOpenFigure;
  final VoidCallback onOpenSearch;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final filteredArticles = articles
        .where(
          (item) =>
              selectedTopic == '全部' || item.article.topic == selectedTopic,
        )
        .toList();
    final filteredFigures = figures
        .where(
          (item) => selectedDynasty == '全部' || item.dynasty == selectedDynasty,
        )
        .toList();
    return Material(
      color: AppColors.white,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inset = constraints.maxWidth >= 1000 ? 40.0 : 20.0;
                return Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minHeight: 72),
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.sageBorder),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                key: const Key('figures-brand-home'),
                                onPressed: onHome,
                                child: const Text(
                                  'Sage — Route',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandInk,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '搜索人物、文章、主题',
                            onPressed: onOpenSearch,
                            icon: const Icon(Icons.search_outlined),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('figures-web-scroll'),
                        padding: EdgeInsets.fromLTRB(inset, 24, inset, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '人物与故事',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandInk,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (articles.isNotEmpty)
                              _WebFeaturedCarousel(
                                articles: articles,
                                onOpen: onOpenArticle,
                              ),
                            const _WebSectionBreak(),
                            _WebDirectory(
                              title: '探索文章',
                              prefix: 'topic',
                              options: _unique([
                                ...topics.map((item) => item.name),
                                ...articles.map((item) => item.article.topic),
                              ]),
                              selected: selectedTopic,
                              onChanged: onTopicChanged,
                              emptyLabel: '这个主题下还没有推送文章',
                              total: filteredArticles.length,
                              expanded: showAllArticles,
                              onExpand: onArticleExpansionChanged,
                              expandLabel: '查看全部文章',
                              children: [
                                for (final item
                                    in showAllArticles
                                        ? filteredArticles
                                        : filteredArticles.take(6))
                                  _WebArticleCard(
                                    key: Key('web-article-${item.article.id}'),
                                    media: item,
                                    onTap: () => onOpenArticle(item.article),
                                  ),
                              ],
                            ),
                            if (topics.isNotEmpty) ...[
                              const _WebSectionBreak(),
                              const _WebSectionTitle('推荐主题'),
                              const SizedBox(height: 24),
                              _WebContentGrid(
                                children: [
                                  for (final topic in topics)
                                    _WebTopicCard(
                                      topic: topic,
                                      media: _mediaForTopic(
                                        articles,
                                        topic.name,
                                      ),
                                      onOpen: onOpenArticle,
                                    ),
                                ],
                              ),
                            ],
                            const _WebSectionBreak(),
                            _WebDirectory(
                              title: '人物目录',
                              prefix: 'dynasty',
                              options: _unique(
                                figures.map((item) => item.dynasty),
                              ),
                              selected: selectedDynasty,
                              onChanged: onDynastyChanged,
                              emptyLabel: '这个朝代下还没有人物',
                              total: filteredFigures.length,
                              expanded: showAllFigures,
                              onExpand: onFigureExpansionChanged,
                              expandLabel: '查看全部人物',
                              children: [
                                for (final figure
                                    in showAllFigures
                                        ? filteredFigures
                                        : filteredFigures.take(6))
                                  _WebFigureCard(
                                    figure: figure,
                                    onTap: () => onOpenFigure(figure),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WebSectionTitle extends StatelessWidget {
  const _WebSectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: AppColors.brandInk,
    ),
  );
}

class _WebSectionBreak extends StatelessWidget {
  const _WebSectionBreak();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 28),
    child: Divider(height: 1, color: AppColors.sageBorder),
  );
}

/// Wrap measures each row from its tallest card; text scaling needs no fixed height.
class _WebContentGrid extends StatelessWidget {
  const _WebContentGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 960
          ? 3
          : constraints.maxWidth >= 600
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 24) / columns;
      return Wrap(
        spacing: 24,
        runSpacing: 40,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _WebDirectory extends StatelessWidget {
  const _WebDirectory({
    required this.title,
    required this.prefix,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.children,
    required this.emptyLabel,
    required this.total,
    required this.expanded,
    required this.onExpand,
    required this.expandLabel,
  });
  final String title;
  final String prefix;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final List<Widget> children;
  final String emptyLabel;
  final int total;
  final bool expanded;
  final VoidCallback onExpand;
  final String expandLabel;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _WebSectionTitle(title),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in [
            '全部',
            ...options.where((value) => value != '全部'),
          ])
            ChoiceChip(
              key: Key('web-$prefix-filter-$option'),
              label: Text(option),
              selected: selected == option,
              selectedColor: AppColors.brandWash,
              labelStyle: const TextStyle(color: AppColors.brandInk),
              checkmarkColor: AppColors.brandDark,
              onSelected: (_) => onChanged(option),
            ),
        ],
      ),
      const SizedBox(height: 24),
      if (children.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(emptyLabel),
        )
      else
        _WebContentGrid(children: children),
      if (total > 6)
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Center(
            child: TextButton(
              key: Key('web-$prefix-expand'),
              onPressed: onExpand,
              child: Text(expanded ? '收起' : expandLabel),
            ),
          ),
        ),
    ],
  );
}

class _WebArticleCard extends StatefulWidget {
  const _WebArticleCard({super.key, required this.media, required this.onTap});
  final ArticleMedia media;
  final VoidCallback onTap;
  @override
  State<_WebArticleCard> createState() => _WebArticleCardState();
}

class _WebArticleCardState extends State<_WebArticleCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: ClipRect(
                child: AnimatedScale(
                  scale: _hovered && !reduced ? 1.025 : 1,
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: _ArticleImage(
                    article: media.article,
                    imageUrl: media.urlFor(ArticleImageRole.cover),
                    altText: media.altTextFor(ArticleImageRole.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              media.article.topic,
              style: const TextStyle(fontSize: 13, color: AppColors.brand),
            ),
            const SizedBox(height: 8),
            Text(
              media.article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.brandInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              media.article.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.sageMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebTopicCard extends StatelessWidget {
  const _WebTopicCard({
    required this.topic,
    required this.media,
    required this.onOpen,
  });
  final TopicRecord topic;
  final ArticleMedia? media;
  final Future<void> Function(ArticleRecord) onOpen;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.brandWash,
    child: InkWell(
      key: Key('web-recommended-${topic.id}'),
      onTap: media == null ? null : () => onOpen(media!.article),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: media == null
                  ? ColoredBox(
                      color: AppColors.brandLight,
                      child: Center(
                        child: Text(
                          topic.name,
                          style: const TextStyle(color: AppColors.brandInk),
                        ),
                      ),
                    )
                  : _ArticleImage(
                      article: media!.article,
                      imageUrl: media!.urlFor(ArticleImageRole.featured),
                      altText: media!.altTextFor(ArticleImageRole.featured),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              topic.name,
              style: const TextStyle(fontSize: 13, color: AppColors.brand),
            ),
            const SizedBox(height: 8),
            Text(
              media?.article.title ?? topic.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.brandInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              media?.article.summary ?? topic.description ?? '暂无相关文章',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.sageMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WebFigureCard extends StatelessWidget {
  const _WebFigureCard({required this.figure, required this.onTap});
  final CelebrityProfile figure;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => ColoredBox(
      color: AppColors.brandLight,
      child: Center(
        child: Text(figure.name.isEmpty ? '?' : figure.name.characters.first),
      ),
    );
    return InkWell(
      key: Key('web-figure-${figure.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: figure.avatarUrl.isEmpty
                  ? fallback()
                  : Image.network(
                      figure.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback(),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    figure.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandInk,
                    ),
                  ),
                  Text(
                    figure.dynasty,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    figure.bioShort,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.sageMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebFeaturedCarousel extends StatefulWidget {
  const _WebFeaturedCarousel({required this.articles, required this.onOpen});
  final List<ArticleMedia> articles;
  final Future<void> Function(ArticleRecord) onOpen;
  @override
  State<_WebFeaturedCarousel> createState() => _WebFeaturedCarouselState();
}

class _WebFeaturedCarouselState extends State<_WebFeaturedCarousel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _pages;
  late final AnimationController _progress;
  int _index = 0;
  late int _physicalPage;
  bool _hovered = false;
  bool _focused = false;
  bool _paused = false;
  bool _opening = false;
  bool _moving = false;
  bool _reduced = false;
  bool _visible = true;
  bool _foreground = true;

  bool get _canPlay =>
      widget.articles.length > 1 &&
      !_hovered &&
      !_focused &&
      !_paused &&
      !_opening &&
      !_moving &&
      !_reduced &&
      _visible &&
      _foreground;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _physicalPage = widget.articles.length * 1000;
    _pages = PageController(initialPage: _physicalPage);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _progress =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _canPlay) _move(1);
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant _WebFeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      oldWidget.articles.map((item) => item.article.id).toList(),
      widget.articles.map((item) => item.article.id).toList(),
    )) {
      _index = 0;
      _physicalPage = widget.articles.length * 1000;
      _progress.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_pages.hasClients) _pages.jumpToPage(_physicalPage);
        _syncPlayback();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  void _syncPlayback() {
    if (_canPlay) {
      _progress.forward(from: _progress.isCompleted ? 0 : null);
    } else {
      _progress.stop();
    }
  }

  void _change(VoidCallback update) {
    setState(update);
    _syncPlayback();
  }

  Future<void> _move(int delta) async {
    if (_moving || !_pages.hasClients || widget.articles.length < 2) return;
    _moving = true;
    _progress.stop();
    if (_physicalPage == 0 && delta < 0) {
      _physicalPage = widget.articles.length * 1000;
      _pages.jumpToPage(_physicalPage);
    }
    final target = _physicalPage + delta;
    if (_reduced) {
      _pages.jumpToPage(target);
    } else {
      await _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
    if (!mounted) return;
    _moving = false;
    _progress.reset();
    _syncPlayback();
  }

  Future<void> _open(ArticleRecord article) async {
    _change(() => _opening = true);
    try {
      await widget.onOpen(article);
    } finally {
      if (mounted) _change(() => _opening = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _change(() => _hovered = true),
    onExit: (_) => _change(() => _hovered = false),
    child: Focus(
      onFocusChange: (value) => _change(() => _focused = value),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight)) {
          _move(event.logicalKey == LogicalKeyboardKey.arrowLeft ? -1 : 1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 600;
              final fontSize = narrow
                  ? 26.0
                  : constraints.maxWidth < 960
                  ? 32.0
                  : 40.0;
              final scale = MediaQuery.textScalerOf(context);
              // At large accessibility sizes grow the hero instead of clipping its text.
              final textHeight =
                  scale.scale(fontSize) * 2 * 1.25 +
                  scale.scale(16) * 4 * 1.5 +
                  scale.scale(13) * 2 +
                  120;
              final baseHeight = (MediaQuery.sizeOf(context).height * .52)
                  .clamp(360.0, 520.0);
              final height = textHeight > baseHeight ? textHeight : baseHeight;
              return SizedBox(
                key: const Key('web-featured-frame'),
                height: height,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _progress.stop();
                    } else if (notification is ScrollEndNotification) {
                      _progress.reset();
                      _syncPlayback();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pages,
                    physics: widget.articles.length == 1
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    onPageChanged: (page) {
                      setState(() {
                        _physicalPage = page;
                        _index = page % widget.articles.length;
                      });
                      _progress.reset();
                    },
                    itemBuilder: (context, page) {
                      final index = page % widget.articles.length;
                      final media = widget.articles[index];
                      return Semantics(
                        label: '打开精选文章 ${media.article.title}',
                        button: true,
                        child: InkWell(
                          key: Key('web-featured-${media.article.id}'),
                          onTap: () => _open(media.article),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _ArticleImage(
                                article: media.article,
                                imageUrl: media.urlFor(
                                  ArticleImageRole.featured,
                                ),
                                altText: media.altTextFor(
                                  ArticleImageRole.featured,
                                ),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x102D1D1B),
                                      Color(0xED2D1D1B),
                                    ],
                                    stops: [.2, 1],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: narrow ? 24 : 40,
                                right: narrow ? 24 : 40,
                                bottom: 32,
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: SizedBox(
                                    width: narrow || scale.scale(16) > 24
                                        ? constraints.maxWidth
                                        : constraints.maxWidth * .6,
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey(
                                        'featured-text-$index-${_index == index}',
                                      ),
                                      tween: Tween(
                                        begin: _reduced ? 1 : 0,
                                        end: 1,
                                      ),
                                      duration: _reduced
                                          ? Duration.zero
                                          : const Duration(milliseconds: 300),
                                      builder: (context, value, child) =>
                                          Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                (1 - value) * 12,
                                              ),
                                              child: child,
                                            ),
                                          ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${media.article.topic} · 精选',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            media.article.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              height: 1.25,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            media.article.summary,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              height: 1.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          const Text(
                                            '阅读全文 →',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (widget.articles.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final position = Semantics(
                    liveRegion: false,
                    child: Text(
                      '${(_index + 1).toString().padLeft(2, '0')} / ${widget.articles.length.toString().padLeft(2, '0')}',
                      key: const Key('web-featured-position'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.brandInk,
                      ),
                    ),
                  );
                  final progress = AnimatedBuilder(
                    animation: _progress,
                    builder: (_, _) => LinearProgressIndicator(
                      value: _progress.value,
                      minHeight: 2,
                      color: AppColors.brand,
                      backgroundColor: AppColors.brandWash,
                    ),
                  );
                  final controls = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _paused ? '继续自动播放' : '暂停自动播放',
                        onPressed: _reduced
                            ? null
                            : () => _change(() => _paused = !_paused),
                        icon: Icon(
                          _paused || _reduced ? Icons.play_arrow : Icons.pause,
                        ),
                      ),
                      IconButton(
                        tooltip: '上一篇精选',
                        onPressed: () => _move(-1),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      IconButton(
                        tooltip: '下一篇精选',
                        onPressed: () => _move(1),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  );
                  if (constraints.maxWidth < 480) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        progress,
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [position, controls],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      position,
                      const SizedBox(width: 16),
                      Expanded(child: progress),
                      const SizedBox(width: 8),
                      controls,
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}
