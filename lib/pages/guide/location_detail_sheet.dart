part of 'guide_page.dart';

class _LocationDetailSheet extends StatelessWidget {
  const _LocationDetailSheet({required this.location});
  final LocationRecord location;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    minChildSize: 0.35,
    initialChildSize: 0.75,
    maxChildSize: 0.95,
    builder: (context, controller) => Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('景点资料')),
                IconButton(
                  tooltip: '关闭详情',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            HeritageSiteDetails(site: location),
          ],
        ),
      ),
    ),
  );
}
