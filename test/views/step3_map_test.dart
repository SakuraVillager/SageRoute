import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/route_planning/models/route_place.dart';
import 'package:sageroute/views/create_route_wizard/steps/step3_map.dart';

void main() {
  const channel = MethodChannel('com.sageroute/route_planning');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final args = call.arguments as Map;
          return {
            'distance': 1200,
            'duration': 600,
            'polyline': [
              [args['originLat'], args['originLon']],
              [args['destLat'], args['destLon']],
            ],
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'preview tracks only selected stops and their route order',
    (tester) async {
      tester.view.physicalSize = const Size(430, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> showPlaces(List<RoutePlace> places) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Step3Map(
                selectedPlaces: places,
                onLocationsChanged: (_) {},
                onPreviewStatusChanged: (_) {},
                onSaveRequested: () async {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
      }

      AMapWidget map() => tester.widget<AMapWidget>(find.byType(AMapWidget));

      // No Supabase initialization: preview must not load the candidate catalog.
      await showPlaces([_place(2), _place(1)]);
      expect(map().markers.map((m) => m.infoWindow.title), [
        '1. 地点2',
        '2. 地点1',
      ]);
      expect(calls, hasLength(1));
      expect(calls.single.arguments['originLat'], _place(2).latitude);
      expect(calls.single.arguments['destLat'], _place(1).latitude);
      expect(calls.single.arguments['preferenceKey'], 'shortest');
      expect(map().polylines, hasLength(1));

      await showPlaces([_place(1), _place(3), _place(2)]);
      expect(map().markers.map((m) => m.infoWindow.title), [
        '1. 地点1',
        '2. 地点3',
        '3. 地点2',
      ]);
      expect(calls, hasLength(3));

      await showPlaces([_place(3)]);
      expect(map().markers.map((m) => m.infoWindow.title), ['1. 地点3']);
      expect(map().polylines, isEmpty);

      await showPlaces([]);
      expect(map().markers, isEmpty);
      expect(map().polylines, isEmpty);
      expect(calls, hasLength(3));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

RoutePlace _place(int id) => RoutePlace(
  id: id,
  name: '地点$id',
  latitude: 30 + id / 100,
  longitude: 120 + id / 100,
  averageVisitDurationMin: 30,
  topic: null,
  categories: null,
);
