import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/location_record.dart';
import 'package:sageroute/models/heritage_grade.dart';
import 'package:sageroute/data/site_filter.dart';

void main() {
  test('appendix preserves all 37 records and historical fields', () {
    final rows =
        jsonDecode(File('assets/data/dongpo_sites.json').readAsStringSync())
            as List;
    final sites = rows
        .map(
          (row) =>
              LocationRecord.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    expect(sites.length, 37);
    expect(sites.map((site) => site.id).toSet().length, 37);
    expect(
      sites
          .where((site) => site.heritageGrade == HeritageGrade.confirmed)
          .length,
      30,
    );
    expect(
      sites
          .where((site) => site.heritageGrade == HeritageGrade.suspected)
          .length,
      2,
    );
    expect(
      sites.where((site) => site.heritageGrade == HeritageGrade.lost).length,
      5,
    );
    for (final site in sites) {
      expect(site.period, isNotEmpty);
      expect(site.historicalEvent, isNotEmpty);
      expect(site.relatedLiterature, isNotEmpty);
      expect(site.literatureSource, isNotEmpty);
      expect(site.researchNotes, isNotEmpty);
      expect(site.themes, isNotEmpty);
      expect(site.themes.every(dongpoThemes.contains), isTrue);
      expect(LocationRecord.fromMap(site.toMap()), site);
    }
    expect(sites[26].coordinates, isEmpty);
    expect(sites[27].coordinates, isEmpty);
  });

  test('legacy records are ungraded rather than confirmed', () {
    expect(LocationRecord.fromMap({'id': 1}).heritageGrade, isNull);
  });

  test(
    'grade, theme and historical text search combine without hiding unlocated sites',
    () {
      final sites = [
        LocationRecord.fromMap({
          'id': 1,
          'name_modern': '钱塘六井',
          'heritage_grade': '确证',
          'themes': ['水利治绩', '民生善政'],
          'historical_event': '修浚六井',
        }),
        LocationRecord.fromMap({
          'id': 2,
          'name_modern': '安乐坊',
          'heritage_grade': '疑似',
          'themes': ['民生善政'],
          'historical_event': '捐金设病坊',
        }),
      ];
      expect(
        filterSites(
          sites,
          grade: HeritageGrade.suspected,
          theme: '民生善政',
          query: '病坊',
        ).map((site) => site.id),
        [2],
      );
      expect(
        filterSites(
          sites,
          grade: HeritageGrade.confirmed,
          theme: '民生善政',
        ).map((site) => site.id),
        [1],
      );
      expect(filterSites(sites, theme: '自然山水'), isEmpty);
    },
  );
}
