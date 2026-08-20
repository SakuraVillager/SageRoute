import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all application colors belong to the approved brand palette', () {
    const allowedRgb = <String>{
      '000000',
      '1C1700',
      '382F00',
      '534600',
      '6F5E00',
      '8B7500',
      'A89840',
      'C5BA80',
      'DCD6B3',
      'EEEAD9',
      'F8F7F0',
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

    expect(violations, isEmpty, reason: '发现未使用黑、白、#8B7500 或其明暗衍生色的颜色');
  });
}
