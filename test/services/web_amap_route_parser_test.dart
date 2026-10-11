import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/services/web_amap_route_parser.dart';

void main() {
  test(
    'JS coordinates stay latitude-first and duplicated joins are removed',
    () {
      final route = parseWebAmapRoute({
        'distance': 1234.4,
        'duration': 100,
        'polyline': [
          [30.1, 120.2],
          [30.1, 120.2],
          [30.2, 120.3],
          [100, 120],
        ],
      });
      expect(route.distanceMeters, 1234);
      expect(route.travelDuration, const Duration(seconds: 100));
      expect(route.polyline, [
        [30.1, 120.2],
        [30.2, 120.3],
      ]);
    },
  );
  test(
    'missing paths and invalid metrics are failures, never synthetic routes',
    () {
      for (final data in [
        {'distance': 10, 'duration': 5, 'polyline': []},
        {
          'distance': -1,
          'duration': 5,
          'polyline': [
            [30, 120],
            [31, 121],
          ],
        },
        {
          'distance': 10,
          'polyline': [
            [30, 120],
            [31, 121],
          ],
        },
      ]) {
        expect(() => parseWebAmapRoute(data), throwsFormatException);
      }
    },
  );
}
