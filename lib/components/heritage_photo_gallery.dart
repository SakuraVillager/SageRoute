import 'package:flutter/material.dart';

class HeritagePhotoGallery extends StatelessWidget {
  const HeritagePhotoGallery({super.key, required this.photos});
  final List<Map<String, String>> photos;

  Widget _image(Map<String, String> photo) {
    final asset = photo['asset_path'];
    Widget failed(BuildContext context, Object error, StackTrace? trace) =>
        const SizedBox(height: 100, child: Center(child: Text('照片加载失败')));
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(asset, fit: BoxFit.contain, errorBuilder: failed);
    }
    return Image.network(
      photo['url'] ?? '',
      fit: BoxFit.contain,
      errorBuilder: failed,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final photo in photos) ...[
        Semantics(
          button: true,
          label: '放大照片：${photo['caption'] ?? '景点照片'}',
          child: InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: '关闭照片',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                    Expanded(child: InteractiveViewer(child: _image(photo))),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(photo['caption'] ?? '景点照片'),
                    ),
                  ],
                ),
              ),
            ),
            child: SizedBox(
              height: 240,
              width: double.infinity,
              child: _image(photo),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('${photo['kind'] ?? '景点图片'} · ${photo['caption'] ?? ''}'),
        Text('摄影：${photo['credit'] ?? '未提供'}'),
        SelectableText('来源：${photo['source'] ?? '未提供'}'),
        Text('授权：${photo['license'] ?? '未提供'}'),
        const SizedBox(height: 20),
      ],
    ],
  );
}
