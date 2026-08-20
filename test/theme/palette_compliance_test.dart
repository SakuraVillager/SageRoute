import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all application colors belong to the approved brand palette', () {
    const allowedRgb = <String>{
      '000000',
      '332E24',
      '665B48',
      '99896D',
      'CCB691',
      'FFE4B5',
      'FFEBC8',
      'FFF2DA',
      'FFF8ED',
      'FFFCF6',
      'FFFFFF',
    };
    const allowedNamedColors = <String>{'black', 'white', 'transparent'};
    final violations = <String>[];
    final colorPattern = RegExp(r'Color\(0x[0-9A-Fa-f]{2}([0-9A-Fa-f]{6})\)');
    final namedPattern = RegExp(r'\bColors\.([A-Za-z]+)(?:\.shade\d+)?');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final match in colorPattern.allMatches(source)) {
        final rgb = match.group(1)!.toUpperCase();
        if (!allowedRgb.contains(rgb)) {
          violations.add('${entity.path}: ${match.group(0)}');
        }
      }
      for (final match in namedPattern.allMatches(source)) {
        final name = match.group(1)!;
        if (!allowedNamedColors.contains(name)) {
          violations.add('${entity.path}: ${match.group(0)}');
        }
      }
    }

    expect(violations, isEmpty, reason: '发现未使用黑、白、#FFE4B5 或其明暗衍生色的颜色');
  });
}
