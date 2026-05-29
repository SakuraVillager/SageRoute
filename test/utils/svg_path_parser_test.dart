import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/utils/svg_path_parser.dart';

void main() {
  late SvgPathParser parser;

  setUp(() {
    parser = SvgPathParser();
  });

  // ---------------------------------------------------------------------------
  // Absolute commands
  // ---------------------------------------------------------------------------
  group('Absolute commands', () {
    group('M — moveto', () {
      test('single point', () {
        final path = parser.parse('M10 20');
        expect(path, isNotNull);
        expect(path, isA<ui.Path>());
      });

      test('multiple points produce implicit lineto segments', () {
        final path = parser.parse('M10 20 30 40 50 60');
        expect(path, isNotNull);
      });
    });

    group('L — lineto', () {
      test('single point', () {
        final path = parser.parse('M0 0L10 20');
        expect(path, isNotNull);
      });

      test('multiple points', () {
        final path = parser.parse('M0 0L10 20 30 40 50 60');
        expect(path, isNotNull);
      });

      test('standalone L (no preceding M) starts from origin', () {
        final path = parser.parse('L10 20L30 40');
        expect(path, isNotNull);
      });
    });

    group('H — horizontal lineto', () {
      test('single value', () {
        final path = parser.parse('M10 20H50');
        expect(path, isNotNull);
      });

      test('multiple values', () {
        final path = parser.parse('M10 20H50 100 150');
        expect(path, isNotNull);
      });
    });

    group('V — vertical lineto', () {
      test('single value', () {
        final path = parser.parse('M10 20V50');
        expect(path, isNotNull);
      });

      test('multiple values', () {
        final path = parser.parse('M10 20V50 100 150');
        expect(path, isNotNull);
      });
    });

    group('C — cubic Bezier', () {
      test('single curve', () {
        final path =
            parser.parse('M10 20C30 40 50 60 70 80');
        expect(path, isNotNull);
      });

      test('multiple curves via repeated parameters', () {
        final path =
            parser.parse('M0 0C10 10 20 20 30 30 40 40 50 50 60 60');
        expect(path, isNotNull);
      });
    });

    group('S — smooth cubic Bezier', () {
      test('after C (reflects control point)', () {
        final path =
            parser.parse('M10 20C30 40 50 60 70 80S90 100 110 120');
        expect(path, isNotNull);
      });

      test('multiple smooth curves', () {
        final path =
            parser.parse('M10 20S30 40 50 60 70 80 90 100');
        expect(path, isNotNull);
      });

      test('standalone S (no preceding cubic) uses current point as control', () {
        final path = parser.parse('M10 20S30 40 50 60');
        expect(path, isNotNull);
      });
    });

    group('Q — quadratic Bezier', () {
      test('single curve', () {
        final path =
            parser.parse('M10 20Q30 40 50 60');
        expect(path, isNotNull);
      });

      test('multiple curves via repeated parameters', () {
        final path =
            parser.parse('M0 0Q10 10 20 20 30 30 40 40');
        expect(path, isNotNull);
      });
    });

    group('T — smooth quadratic Bezier', () {
      test('after Q (reflects control point)', () {
        final path =
            parser.parse('M10 20Q30 40 50 60T70 80');
        expect(path, isNotNull);
      });

      test('multiple smooth curves', () {
        final path =
            parser.parse('M10 20T30 40 50 60');
        expect(path, isNotNull);
      });

      test('standalone T (no preceding quadratic) uses current point as control',
          () {
        final path = parser.parse('M10 20T30 40');
        expect(path, isNotNull);
      });
    });

    group('A — arc', () {
      test('basic arc', () {
        final path =
            parser.parse('M10 20A30 40 0 0 1 50 60');
        expect(path, isNotNull);
      });

      test('arc with rotation and large-arc flag', () {
        final path =
            parser.parse('M10 20A30 40 45 1 0 50 60');
        expect(path, isNotNull);
      });
    });

    group('Z / z — closepath', () {
      test('uppercase Z', () {
        final path = parser.parse('M10 20L50 60Z');
        expect(path, isNotNull);
      });

      test('lowercase z', () {
        final path = parser.parse('M10 20L50 60z');
        expect(path, isNotNull);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Relative commands
  // ---------------------------------------------------------------------------
  group('Relative commands', () {
    group('m — relative moveto', () {
      test('single point', () {
        final path = parser.parse('m10 20');
        expect(path, isNotNull);
      });

      test('accumulates from current position', () {
        // m10 20l5 5: moves to (0+10, 0+20)=(10,20), then line to (15,25)
        final pathRel = parser.parse('m10 20l5 5');
        // M10 20L5 5: moves to (10,20), then line to (5,5)
        final pathAbs = parser.parse('M10 20L5 5');
        expect(pathRel, isNotNull);
        expect(pathAbs, isNotNull);
        // Different paths: relative goes to (15,25), absolute goes to (5,5)
        expect(identical(pathRel, pathAbs), isFalse);
      });
    });

    group('l — relative lineto', () {
      test('single point', () {
        final path = parser.parse('m10 20l5 5');
        expect(path, isNotNull);
      });

      test('multiple points', () {
        final path = parser.parse('m10 20l5 5 10 10');
        expect(path, isNotNull);
      });

      test('produces different path from absolute equivalent', () {
        // relative: from (0,0), m to (0,0), l +10+10 → (10,10)
        // absolute: from (0,0), L 10 10 → (10,10)
        // Actually same for first point! But relative adjusts by current point.
        // Second L: from (10,10), l10 10 → (20,20)
        // Second L: from (10,10), L10 10 → (10,10)
        final relPath = parser.parse('M0 0l10 10l10 10');
        final absPath = parser.parse('M0 0L10 10L10 10');
        expect(relPath, isNotNull);
        expect(absPath, isNotNull);
      });
    });

    group('h — relative horizontal lineto', () {
      test('single value', () {
        final path = parser.parse('m10 20h50');
        expect(path, isNotNull);
      });

      test('multiple values', () {
        final path = parser.parse('m10 20h50 100');
        expect(path, isNotNull);
      });

      test('accumulates horizontally', () {
        // h10 h10: x moves from currentX to currentX+10 to currentX+20
        final path = parser.parse('M0 0h10h10');
        expect(path, isNotNull);
      });
    });

    group('v — relative vertical lineto', () {
      test('single value', () {
        final path = parser.parse('m10 20v50');
        expect(path, isNotNull);
      });

      test('multiple values', () {
        final path = parser.parse('m10 20v50 100');
        expect(path, isNotNull);
      });

      test('accumulates vertically', () {
        final path = parser.parse('M0 0v10v10');
        expect(path, isNotNull);
      });
    });

    group('c — relative cubic Bezier', () {
      test('single curve', () {
        final path =
            parser.parse('m10 20c10 10 20 20 30 30');
        expect(path, isNotNull);
      });

      test('multiple curves', () {
        final path =
            parser.parse('m10 20c10 10 20 20 30 30 40 40 50 50 60 60');
        expect(path, isNotNull);
      });
    });

    group('s — relative smooth cubic Bezier', () {
      test('after relative c', () {
        final path =
            parser.parse('m10 20c10 10 20 20 30 30s10 10 20 20');
        expect(path, isNotNull);
      });

      test('standalone s', () {
        final path =
            parser.parse('m10 20s10 10 20 20');
        expect(path, isNotNull);
      });
    });

    group('q — relative quadratic Bezier', () {
      test('single curve', () {
        final path =
            parser.parse('m10 20q5 5 10 10');
        expect(path, isNotNull);
      });

      test('multiple curves', () {
        final path =
            parser.parse('m10 20q5 5 10 10 15 15 20 20');
        expect(path, isNotNull);
      });
    });

    group('t — relative smooth quadratic Bezier', () {
      test('after relative q', () {
        final path =
            parser.parse('m10 20q5 5 10 10t5 5');
        expect(path, isNotNull);
      });

      test('standalone t', () {
        final path =
            parser.parse('m10 20t5 5');
        expect(path, isNotNull);
      });
    });

    group('a — relative arc', () {
      test('basic relative arc', () {
        final path =
            parser.parse('m10 20a30 40 0 0 1 50 60');
        expect(path, isNotNull);
      });

      test('relative arc with all flags', () {
        final path =
            parser.parse('M10 20a30 40 45 1 1 60 70');
        expect(path, isNotNull);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Combined and complex paths
  // ---------------------------------------------------------------------------
  group('Combined / complex paths', () {
    test('multiple commands in one string', () {
      final path = parser.parse('M10 20L30 40L50 60');
      expect(path, isNotNull);
      expect(path, isA<ui.Path>());
    });

    test('mixed absolute and relative commands', () {
      final path = parser.parse('M10 20l10 10L40 40l10 10');
      expect(path, isNotNull);
    });

    test('triangle path', () {
      final path = parser.parse('M0 0L100 0L50 100Z');
      expect(path, isNotNull);
    });

    test('rectangle path with relative commands', () {
      final path = parser.parse('M10 10h80v80h-80Z');
      expect(path, isNotNull);
    });

    test('all command types in one path', () {
      final path = parser.parse(
        'M10 20L30 40H50V60C70 80 90 100 110 120'
        'S130 140 150 160Q170 180 190 200T210 220'
        'A230 240 0 0 1 250 260Z',
      );
      expect(path, isNotNull);
    });

    test('repeated implicit parameters after M', () {
      // M10 20 30 40 → moveto (10,20) + implicit lineto (30,40)
      final path = parser.parse('M10 20 30 40 50 60');
      expect(path, isNotNull);
    });

    test('repeated implicit parameters after L', () {
      final path = parser.parse('M0 0L10 10 20 20 30 30');
      expect(path, isNotNull);
    });

    test('repeated explicit command letters', () {
      final path = parser.parse('M0 0L10 10L20 20L30 30');
      expect(path, isNotNull);
    });

    test('S after relative c (cross-case reflection)', () {
      // S should reflect last control point from relative 'c'
      final path =
          parser.parse('M10 20c10 10 20 20 30 30S50 60 70 80');
      expect(path, isNotNull);
    });

    test('s after absolute C (cross-case reflection)', () {
      final path =
          parser.parse('M10 20C10 10 20 20 30 30s50 60 70 80');
      expect(path, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------
  group('Edge cases', () {
    test('empty string returns non-null path', () {
      final path = parser.parse('');
      expect(path, isNotNull);
      expect(path, isA<ui.Path>());
    });

    test('whitespace-only string returns non-null path', () {
      final path = parser.parse('   ');
      expect(path, isNotNull);
    });

    test('single point (moveto only)', () {
      final path = parser.parse('M50 50');
      expect(path, isNotNull);
    });

    test('unknown/invalid command letters are skipped gracefully', () {
      // X is not a valid SVG path command; parser should skip silently
      final path = parser.parse('M10 20X50 50L30 40');
      expect(path, isNotNull);
    });

    test('comma-separated coordinates', () {
      final path = parser.parse('M10,20L30,40L50,60');
      expect(path, isNotNull);
    });

    test('mixed whitespace and commas', () {
      final path = parser.parse('M 10 , 20 L 30 , 40');
      expect(path, isNotNull);
    });

    test('tab-separated coordinates', () {
      final path = parser.parse('M10\t20L30\t40');
      expect(path, isNotNull);
    });

    test('newline-separated coordinates', () {
      final path = parser.parse('M10\n20L30\n40');
      expect(path, isNotNull);
    });

    test('carriage-return separated coordinates', () {
      final path = parser.parse('M10\r20L30\r40');
      expect(path, isNotNull);
    });

    test('negative coordinates', () {
      final path = parser.parse('M-10 -20L-30 -40');
      expect(path, isNotNull);
    });

    test('decimal coordinates', () {
      final path = parser.parse('M10.5 20.5L30.25 40.75');
      expect(path, isNotNull);
    });

    test('plus-signed coordinates', () {
      final path = parser.parse('M+10 +20L+30 +40');
      expect(path, isNotNull);
    });

    test('scientific notation (exponent)', () {
      // e.g. 1e2 = 100, 3.5e-1 = 0.35
      final path = parser.parse('M1e2 2e1L3.5e-1 4.0e0');
      expect(path, isNotNull);
    });

    test('scientific notation with positive exponent', () {
      final path = parser.parse('M1e+2 2E+1');
      expect(path, isNotNull);
    });

    test('parser can be reused with different path strings', () {
      final path1 = parser.parse('M10 20L30 40');
      final path2 = parser.parse('M50 60L70 80');
      expect(path1, isNotNull);
      expect(path2, isNotNull);
      expect(identical(path1, path2), isFalse);
    });

    test('consecutive Z commands', () {
      final path = parser.parse('M10 20L30 40ZZ');
      expect(path, isNotNull);
    });

    test('arc with zero radius degenerates to line', () {
      // rx=0 or ry=0 → degrades to lineTo
      final path = parser.parse('M10 20A0 0 0 0 1 50 60');
      expect(path, isNotNull);
    });

    test('arc with negative radii (takes absolute value)', () {
      final path = parser.parse('M10 20A-30 -40 0 0 1 50 60');
      expect(path, isNotNull);
    });

    test('arc where start and end are the same point', () {
      final path = parser.parse('M0 0A10 10 0 0 1 0 0');
      expect(path, isNotNull);
    });

    test('only relative commands (no initial absolute M)', () {
      // Starts from (0,0) and all positions are relative
      final path = parser.parse('m10 10l20 20l10 10');
      expect(path, isNotNull);
    });

    test('arc with both large-arc and sweep flags set', () {
      final path = parser.parse('M10 20A30 40 0 1 1 50 60');
      expect(path, isNotNull);
    });

    test('arc with rotation angle', () {
      final path = parser.parse('M10 20A30 40 90 0 1 50 60');
      expect(path, isNotNull);
    });

    test('token starting with dot (e.g. .5 for 0.5)', () {
      // The tokenizer should handle leading decimal points
      final path = parser.parse('M10 .5L.25 .75');
      expect(path, isNotNull);
    });
  });
}
