import 'package:flutter/material.dart';

import '../models/location_record.dart';
import 'heritage_photo_gallery.dart';
import 'place_metadata_tags.dart';

class HeritageSiteDetails extends StatelessWidget {
  const HeritageSiteDetails({super.key, required this.site});
  final LocationRecord site;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(site.nameModern, style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        PlaceMetadataTags(
          categories: site.categories,
          grade: site.heritageGrade,
          themes: [...site.themes, if (site.isCoreSite) '核心景点'],
        ),
        for (final entry in <String, String?>{
          '古地名': site.nameAncient,
          '今地': site.address,
          '时期': site.period,
          '历史事件': site.historicalEvent ?? site.description,
          '相关诗文': site.relatedLiterature,
          '文献出处': site.literatureSource,
          '考订说明': site.researchNotes,
          '地图定位': site.hasValidCoordinates
              ? '${site.longitude!.toStringAsFixed(6)}, ${site.latitude!.toStringAsFixed(6)}（GCJ-02）\n${site.coordinateNote ?? ''}'
              : site.coordinateNote ?? '位置待核实，暂不显示地图标记。',
        }.entries) ...[
          const SizedBox(height: 20),
          Text(entry.key, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          SelectableText(
            entry.value?.trim().isNotEmpty == true ? entry.value! : '待补充',
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
        const SizedBox(height: 24),
        Text('景点影像', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        if (site.photos.isEmpty) const Text('尚未提供对应现场照片。'),
        HeritagePhotoGallery(photos: site.photos),
      ],
    );
  }
}
