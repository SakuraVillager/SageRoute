import 'package:flutter/material.dart';
import '../models/location_record.dart';

class HeritageGradeBadge extends StatelessWidget {
  const HeritageGradeBadge({super.key, required this.site});
  final LocationRecord site;

  @override
  Widget build(BuildContext context) {
    final color =
        site.heritageGrade?.color ?? Theme.of(context).colorScheme.outline;
    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(site.heritageGrade?.label ?? '未评级'),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}
