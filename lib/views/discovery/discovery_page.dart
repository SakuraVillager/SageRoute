import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../../components/account_action.dart';
import '../../components/community_post_card.dart';
import '../../data/community_repository.dart';
import '../../data/user_route_repository.dart';
import '../../data/social_gateway.dart';
import '../../models/community_post.dart';
import '../../services/share_links.dart';
import '../../theme/color_schemes.dart';
import 'community_compose_sheet.dart';
import 'community_post_page.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({
    super.key,
    this.repository = const CommunityRepository(),
    this.routes = const UserRouteRepository(),
    this.onRouteCreated,
  });
  final CommunityRepository repository;
  final UserRouteRepository routes;
  final Future<void> Function()? onRouteCreated;
  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  List<CommunityPost> _posts = const [];
  String? _kind;
  String? _error;
  bool _loading = true;
  bool _more = false;
  bool _hasMore = false;
  int _request = 0;
  final _busy = <String>{};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await widget.repository.feed(kind: _kind);
      if (mounted && request == _request) {
        setState(() {
          _posts = posts;
          _hasMore = posts.length == 20;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = socialErrorMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_more || _posts.isEmpty) return;
    final request = _request;
    setState(() => _more = true);
    try {
      final posts = await widget.repository.feed(
        kind: _kind,
        before: _posts.last.createdAt,
      );
      if (mounted && request == _request) {
        setState(() {
          _posts = [..._posts, ...posts];
          _hasMore = posts.length == 20;
        });
      }
    } catch (error) {
      if (mounted) _notify(socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _more = false);
    }
  }

  void _notify(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _compose() async {
    if (widget.repository.gateway.userId == null &&
        !await requireAccountForAction(context)) {
      return;
    }
    if (!mounted) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .88,
        child: CommunityComposeSheet(
          repository: widget.repository,
          routes: widget.routes,
        ),
      ),
    );
    if (id != null && mounted) await _load();
  }

  Future<void> _like(CommunityPost post) async {
    if (widget.repository.gateway.userId == null &&
        !await requireAccountForAction(context)) {
      return;
    }
    if (!mounted || _busy.contains(post.id)) return;
    setState(() => _busy.add(post.id));
    try {
      await widget.repository.like(post.id, !post.liked);
      final updated = await widget.repository.post(post.id);
      if (mounted && updated != null) {
        setState(
          () => _posts = _posts
              .map((p) => p.id == post.id ? updated : p)
              .toList(),
        );
      }
    } catch (error) {
      if (mounted) _notify(socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy.remove(post.id));
    }
  }

  Future<void> _share(CommunityPost post) async {
    await Clipboard.setData(
      ClipboardData(text: ShareLinks.post(post.id).toString()),
    );
    if (mounted) _notify('动态链接已复制');
  }

  Future<void> _delete(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这篇分享？'),
        content: const Text('分享和下方的讨论将一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.delete(post.id);
      if (mounted) await _load();
    } catch (error) {
      if (mounted) _notify(socialErrorMessage(error));
    }
  }

  Future<void> _open(CommunityPost post) async {
    if (kIsWeb) {
      await context.push<void>('/discover/posts/${post.id}');
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CommunityPostPage(
            postId: post.id,
            repository: widget.repository,
            initialPost: post,
            onRouteCreated: widget.onRouteCreated,
          ),
        ),
      );
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.sageBg,
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '发现',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _compose,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('发布'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '把路上的见闻，留给下一位同行者。',
                          style: TextStyle(
                            color: AppColors.sageMuted,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final filter in <String?, String>{
                              null: '全部',
                              'note': '随手记',
                              'route': '路线分享',
                            }.entries)
                              ChoiceChip(
                                label: Text(filter.value),
                                selected: _kind == filter.key,
                                onSelected: (_) {
                                  setState(() => _kind = filter.key);
                                  _load();
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 40),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新加载'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.explore_outlined,
                          size: 46,
                          color: AppColors.sageAccent,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          '这里还没有分享',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '写一段见闻，或分享一条走过的路线。',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          onPressed: _compose,
                          child: const Text('写下第一段故事'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CommunityPostCard(
                          post: post,
                          busy: _busy.contains(post.id),
                          onOpen: () => _open(post),
                          onLike: () => _like(post),
                          onShare: () => _share(post),
                          onDelete:
                              widget.repository.gateway.userId == post.authorId
                              ? () => _delete(post)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (!_loading && _hasMore)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton(
                    onPressed: _more ? null : _loadMore,
                    child: Text(_more ? '加载中…' : '查看更多'),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    ),
  );
}
