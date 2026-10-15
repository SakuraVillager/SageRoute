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
import '../../models/saved_route.dart';
import '../../route_planning/models/transport_type.dart';
import '../../services/share_links.dart';
import '../../theme/color_schemes.dart';
import '../create_route_wizard/steps/step3_map.dart';
import '../route_preview/route_preview_page.dart';

class CommunityPostPage extends StatefulWidget {
  const CommunityPostPage({
    super.key,
    required this.postId,
    this.initialPost,
    this.repository = const CommunityRepository(),
    this.onRouteCreated,
  });
  final String postId;
  final CommunityPost? initialPost;
  final CommunityRepository repository;
  final Future<void> Function()? onRouteCreated;
  @override
  State<CommunityPostPage> createState() => _CommunityPostPageState();
}

class _CommunityPostPageState extends State<CommunityPostPage> {
  final _comment = TextEditingController();
  final _commentFocus = FocusNode();
  CommunityPost? _post;
  List<CommunityComment> _comments = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        widget.repository.post(widget.postId),
        widget.repository.comments(widget.postId),
      ]);
      if (mounted) {
        setState(() {
          _post = results[0] as CommunityPost?;
          _comments = results[1] as List<CommunityComment>;
          _loading = false;
          _error = _post == null ? '这篇分享不存在或已被删除' : null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = socialErrorMessage(error);
        });
      }
    }
  }

  void _notify(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    if (widget.repository.gateway.userId == null &&
        !await requireAccountForAction(context)) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (error) {
      if (mounted) _notify(socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _mutate(() async {
    await widget.repository.comment(widget.postId, _comment.text);
    _comment.clear();
  });
  void _openRoute() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityRoutePage(
          post: _post!,
          onRouteCreated: widget.onRouteCreated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.sageBg,
    appBar: AppBar(title: const Text('路上的故事')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('重试')),
                ],
                if (_post != null) ...[
                  CommunityPostCard(
                    post: _post!,
                    busy: _busy,
                    onOpen: () {},
                    onOpenRoute: _openRoute,
                    onComment: _commentFocus.requestFocus,
                    onLike: () => _mutate(
                      () =>
                          widget.repository.like(widget.postId, !_post!.liked),
                    ),
                    onShare: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: ShareLinks.post(widget.postId).toString(),
                        ),
                      );
                      if (mounted) _notify('动态链接已复制');
                    },
                  ),
                  if (_post!.route != null)
                    OutlinedButton.icon(
                      onPressed: _openRoute,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('查看公开路线'),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    '讨论 · ${_post!.commentCount}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final comment in _comments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            comment.body,
                            style: const TextStyle(height: 1.7),
                          ),
                        ],
                      ),
                    ),
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '还没有讨论，来聊聊你的发现。',
                        style: TextStyle(color: AppColors.sageMuted),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _comment,
                    focusNode: _commentFocus,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '写下你的想法…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _send,
                    child: Text(_busy ? '正在发送…' : '发表评论'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CommunityRoutePage extends StatefulWidget {
  const CommunityRoutePage({
    super.key,
    required this.post,
    this.routes = const UserRouteRepository(),
    this.onRouteCreated,
  });
  final CommunityPost post;
  final UserRouteRepository routes;
  final Future<void> Function()? onRouteCreated;
  @override
  State<CommunityRoutePage> createState() => _CommunityRoutePageState();
}

class _CommunityRoutePageState extends State<CommunityRoutePage> {
  bool _saving = false;
  Future<void> _saveCopy() async {
    if (!await requireAccountForAction(context) || !mounted) return;
    setState(() => _saving = true);
    try {
      final source = widget.post.route!;
      final copy = SavedRoute(
        id: '',
        title: source.title,
        dateRange: '',
        duration: source.duration,
        distance: source.distance,
        waypoints: source.waypoints,
        figureId: source.figureId,
        figureName: source.figureName,
      );
      final id = await widget.routes.createRoute(copy);
      await widget.onRouteCreated?.call();
      if (!mounted) return;
      if (kIsWeb) {
        context.go('/routes/$id');
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RoutePreviewPage(routeId: id),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(socialErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.post.route!;
    return Scaffold(
      appBar: AppBar(title: Text(route.title)),
      body: Step3Map(
        mode: Step3Mode.preview,
        selectedPlaces: route.waypoints
            .map((point) => point.toRoutePlace())
            .toList(),
        onLocationsChanged: (_) {},
        onPreviewStatusChanged: (_) {},
        onSaveRequested: () async {},
        initialSegmentTransports: route.waypoints
            .take(route.waypoints.isEmpty ? 0 : route.waypoints.length - 1)
            .map((p) => p.transportToNext ?? TransportType.driving)
            .toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveCopy,
            icon: const Icon(Icons.add_road_outlined),
            label: Text(_saving ? '正在保存…' : '保存为我的行程'),
          ),
        ),
      ),
    );
  }
}
