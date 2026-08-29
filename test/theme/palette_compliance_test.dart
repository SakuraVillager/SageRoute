import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all application colors belong to the approved brand palette', () {
    const allowedRgb = <String>{
      '000000',
      '202124',
      '2D1D1B',
      '3C2724',
      '5A3A36',
      '6F6D72',
      '784E48',
      '96615A',
      'AB817B',
      'C0A09C',
      'D3D3D3',
      'D5C0BD',
      'D8D8DC',
      'EADFDE',
      'F0F0F2',
      'F5EFEF',
      'F8F8F9',
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

    expect(violations, isEmpty, reason: '发现未使用 #F0F0F2 中性色板或 #96615A 品牌色板的颜色');
  });
}
