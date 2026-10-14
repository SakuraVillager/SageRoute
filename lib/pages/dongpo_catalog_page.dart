import 'package:flutter/material.dart';
import 'guide/guide_page.dart';
import 'dongpo_photos_page.dart';

class DongpoCatalogPage extends StatelessWidget {
  const DongpoCatalogPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('东坡杭州行迹'),
      actions: [
        IconButton(
          tooltip: '景点影像 · 37 张',
          icon: const Icon(Icons.photo_library_outlined),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const DongpoPhotosPage()),
          ),
        ),
      ],
    ),
    body: const SafeArea(child: GuidePage()),
  );
}
