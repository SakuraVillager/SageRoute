import '../models/heritage_grade.dart';
import '../models/location_record.dart';

List<LocationRecord> filterSites(
  Iterable<LocationRecord> sites, {
  HeritageGrade? grade,
  String? theme,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  return sites
      .where((site) {
        if (grade != null && site.heritageGrade != grade) return false;
        if (theme != null && !site.themes.contains(theme)) return false;
        return needle.isEmpty ||
            [
              site.nameModern,
              site.nameAncient ?? '',
              site.address ?? '',
              site.historicalEvent ?? '',
              site.relatedLiterature ?? '',
            ].join(' ').toLowerCase().contains(needle);
      })
      .toList(growable: false);
}
