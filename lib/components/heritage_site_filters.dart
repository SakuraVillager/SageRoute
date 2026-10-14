import 'package:flutter/material.dart';
import '../models/heritage_grade.dart';

class HeritageSiteFilters extends StatelessWidget {
  const HeritageSiteFilters({
    super.key,
    required this.grade,
    required this.theme,
    required this.onGradeChanged,
    required this.onThemeChanged,
    required this.onQueryChanged,
  });
  final HeritageGrade? grade;
  final String? theme;
  final ValueChanged<HeritageGrade?> onGradeChanged;
  final ValueChanged<String?> onThemeChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        onChanged: onQueryChanged,
        decoration: const InputDecoration(
          labelText: '搜索景点、事件或诗文',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      const Text('遗存等级'),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ChoiceChip(
            label: const Text('全部'),
            selected: grade == null,
            onSelected: (_) => onGradeChanged(null),
          ),
          ...HeritageGrade.values.map(
            (value) => ChoiceChip(
              avatar: Icon(Icons.circle, size: 10, color: value.color),
              label: Text(value.label),
              selected: grade == value,
              onSelected: (_) => onGradeChanged(value),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text('专题'),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ChoiceChip(
            label: const Text('全部专题'),
            selected: theme == null,
            onSelected: (_) => onThemeChanged(null),
          ),
          ...dongpoThemes.map(
            (value) => ChoiceChip(
              label: Text(value),
              selected: theme == value,
              onSelected: (_) => onThemeChanged(value),
            ),
          ),
        ],
      ),
    ],
  );
}
