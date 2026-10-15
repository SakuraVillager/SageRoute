import 'package:flutter/material.dart';

import '../models/heritage_grade.dart';
import '../theme/color_schemes.dart';

/// The same compact label treatment for category, evidence grade and themes.
class PlaceMetadataTags extends StatelessWidget {
  const PlaceMetadataTags({
    super.key,
    this.categories = const [],
    this.grade,
    this.themes = const [],
  });

  final List<String> categories;
  final HeritageGrade? grade;
  final List<String> themes;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (final category in categories) _tag(category, AppColors.sageMuted),
      if (grade != null) _tag(grade!.label, grade!.color),
      for (final theme in themes) _tag(theme, AppColors.sageAccent),
    ],
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, height: 1.2, color: color),
    ),
  );
}
