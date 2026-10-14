import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/heritage_photo_gallery.dart';

class DongpoPhotosPage extends StatefulWidget {
  const DongpoPhotosPage({super.key});

  @override
  State<DongpoPhotosPage> createState() => _DongpoPhotosPageState();
}

class _DongpoPhotosPageState extends State<DongpoPhotosPage> {
  late final Future<List<dynamic>> _photos = _load();

  Future<List<dynamic>> _load() async =>
      jsonDecode(
            await rootBundle.loadString('assets/data/dongpo_photo_assets.json'),
          )
          as List<dynamic>;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('东坡景点影像 · 37 张')),
    body: FutureBuilder<List<dynamic>>(
      future: _photos,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('影像资料加载失败'));
        final rows = snapshot.data;
        if (rows == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index] as Map;
            final photo = Map<String, String>.from(row['photo'] as Map);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['site_label'] as String,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (row['site_id'] == null)
                      const Text('补充调研点位（原 37 条景点清单未收录）'),
                    const SizedBox(height: 12),
                    HeritagePhotoGallery(photos: [photo]),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
