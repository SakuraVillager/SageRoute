import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/data/location_repository.dart';
import 'package:sageroute/data/poi_celebrity_relation_repository.dart';
import 'package:sageroute/data/topic_repository.dart';
import 'package:sageroute/models/celebrity_profile.dart';
import 'package:sageroute/models/location_record.dart';
import 'package:sageroute/models/poi_celebrity_relation_record.dart';
import 'package:sageroute/views/create_route_wizard/steps/add_place_page.dart';

void main() {
  const figure = CelebrityProfile(
    id: 1,
    name: '苏轼',
    dynasty: '北宋',
    bioShort: '',
    bioFull: '',
    avatarUrl: '',
    topic: [],
  );
  final locations = <LocationRecord>[
    _location(1, '杭州西湖景区'),
    _location(2, '杭州凤凰山景区'),
    _location(3, '白居易纪念馆'),
  ];
  final locationRepository = LocationRepository(fetcher: () async => locations);
  final relationRepository = PoiCelebrityRelationRepository(
    fetcher: () async => const [
      PoiCelebrityRelationRecord(
        id: 1,
        createdAt: null,
        locationName: '杭州西湖景区',
        celebrityName: '苏轼',
        relationType: null,
        weight: null,
      ),
      PoiCelebrityRelationRecord(
        id: 2,
        createdAt: null,
        locationName: '杭州凤凰山景区',
        celebrityName: '苏轼',
        relationType: null,
        weight: null,
      ),
      PoiCelebrityRelationRecord(
        id: 3,
        createdAt: null,
        locationName: '白居易纪念馆',
        celebrityName: '白居易',
        relationType: null,
        weight: null,
      ),
    ],
  );
  final topicRepository = TopicRepository(fetcher: () async => []);

  testWidgets('selected celebrity limits places before search', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddPlacePage(
            figure: figure,
            currentSelectedPlaces: const [],
            locationRepository: locationRepository,
            relationRepository: relationRepository,
            topicRepository: topicRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('仅显示苏轼相关景点'), findsOneWidget);
    expect(find.text('杭州西湖景区'), findsOneWidget);
    expect(find.text('杭州凤凰山景区'), findsOneWidget);
    expect(find.text('白居易纪念馆'), findsNothing);

    await tester.enterText(find.byType(TextField), '凤凰山');
    await tester.pumpAndSettle();
    expect(find.text('杭州凤凰山景区'), findsOneWidget);
    expect(find.text('杭州西湖景区'), findsNothing);
  });

  testWidgets('without a celebrity all valid places remain available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddPlacePage(
            figure: null,
            currentSelectedPlaces: const [],
            locationRepository: locationRepository,
            relationRepository: relationRepository,
            topicRepository: topicRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('杭州西湖景区'), findsOneWidget);
    expect(find.text('白居易纪念馆'), findsOneWidget);
  });
}

LocationRecord _location(int id, String name) => LocationRecord(
  id: id,
  nameModern: name,
  nameAncient: null,
  description: null,
  averageVisitDurationMin: null,
  address: null,
  openTime: null,
  closeTime: null,
  isArEnabled: false,
  topic: null,
  categories: const [],
  coordinates: const [120.0, 30.0],
);
