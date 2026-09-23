import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/models/travel_preferences.dart';
import 'package:sageroute/pages/travel_preferences_page.dart';
import 'package:sageroute/services/profile_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/page_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('saves selected preferences locally', (tester) async {
    useLargeSurface(tester);
    await pumpPushedPage(
      tester,
      TravelPreferencesPage(preferences: ProfilePreferences()),
    );

    await tester.tap(find.byKey(const Key('travel-dynasty-唐')));
    await tester.tap(find.byKey(const Key('travel-theme-诗词')));
    await tester.tap(find.byKey(const Key('travel-pace-packed')));
    await tester.tap(find.byKey(const Key('travel-transport-walking')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('travel-save-button')));
    await tester.pumpAndSettle();

    expect(find.byType(TravelPreferencesPage), findsNothing);

    final state = await ProfilePreferences().load();
    expect(state.travelPreferences.dynasties, <String>{'唐'});
    expect(state.travelPreferences.themes, <String>{'诗词'});
    expect(state.travelPreferences.pace, TravelPace.packed);
    expect(state.travelPreferences.transport, TravelTransport.walking);
  });

  testWidgets('restores previously saved preferences', (tester) async {
    useLargeSurface(tester);
    await ProfilePreferences().saveTravelPreferences(
      const TravelPreferences(
        dynasties: <String>{'宋'},
        themes: <String>{'哲学'},
        pace: TravelPace.relaxed,
        transport: TravelTransport.walking,
      ),
    );

    await pumpPushedPage(
      tester,
      TravelPreferencesPage(preferences: ProfilePreferences()),
    );

    final dynastyChip = tester.widget<FilterChip>(
      find.byKey(const Key('travel-dynasty-宋')),
    );
    final paceChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('travel-pace-relaxed')),
    );
    expect(dynastyChip.selected, isTrue);
    expect(paceChip.selected, isTrue);
  });
}
