import 'package:flutter/material.dart';
import '../../data/community_repository.dart';
import '../../data/user_route_repository.dart';
import '../../data/social_gateway.dart';
import '../../models/saved_route.dart';
import '../../theme/color_schemes.dart';

class CommunityComposeSheet extends StatefulWidget {
  const CommunityComposeSheet({
    super.key,
    required this.repository,
    required this.routes,
  });
  final CommunityRepository repository;
  final UserRouteRepository routes;
  @override
  State<CommunityComposeSheet> createState() => _CommunityComposeSheetState();
}

class _CommunityComposeSheetState extends State<CommunityComposeSheet> {
  final _body = TextEditingController();
  List<SavedRoute> _routes = const [];
  String _routeId = '';
  bool _sending = false;
  bool _loading = true;
  String? _error;
  String? _routeError;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await widget.routes.fetchUserRoutes();
      if (mounted) {
        setState(() {
          _routes = routes.where((route) => route.canManage).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _routeError = '暂时无法读取行程，你仍可发布随手记。';
        });
      }
    }
  }

  Future<void> _publish() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final id = await widget.repository.publish(
        _body.text,
        routeId: _routeId.isEmpty ? null : _routeId,
      );
      if (mounted) Navigator.pop(context, id);
    } catch (error) {
      if (mounted) setState(() => _error = socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.sageCard,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '分享一段见闻',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭发布',
                ),
              ],
            ),
            const Text(
              '一处风景，一段故事，或一条值得同行的路线。',
              style: TextStyle(color: AppColors.sageMuted, height: 1.7),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _body,
              maxLength: 2000,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: '写下你在路上的发现…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                initialValue: _routeId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '附带一条路线（可选）',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('不附带路线 · 发布随手记'),
                  ),
                  for (final route in _routes)
                    DropdownMenuItem(
                      value: route.id,
                      child: Text(
                        route.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _sending
                    ? null
                    : (value) => setState(() => _routeId = value ?? ''),
              ),
            if (_routeError != null)
              Text(
                _routeError!,
                style: const TextStyle(color: AppColors.sageMuted),
              ),
            const SizedBox(height: 12),
            const Text(
              '附带路线会公开当前地点快照，不包含私人出行日期和同行成员。之后的协作修改不会改变这篇分享。',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: AppColors.sageMuted,
              ),
            ),
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!)],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _publish,
                child: Text(_sending ? '正在发布…' : '发布到发现'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
