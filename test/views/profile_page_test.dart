import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/pages/account_info_page.dart';
import 'package:sageroute/pages/achievement_detail_page.dart';
import 'package:sageroute/services/auth_service.dart';
import 'package:sageroute/services/profile_preferences.dart';
import 'package:sageroute/views/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/page_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpProfile(WidgetTester tester, {ProfilePage? page}) async {
    useLargeSurface(tester);
    await tester.pumpWidget(MaterialApp(home: page ?? const ProfilePage()));
    await tester.pumpAndSettle();
  }

  Future<void> tapAfterScroll(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('renders identity, achievements and settings entries', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('旅行者'), findsOneWidget);
    expect(find.text('我的文史成就'), findsOneWidget);
    expect(find.text('偏好设置'), findsOneWidget);
    expect(find.text('账号信息'), findsOneWidget);
    expect(find.text('旅行偏好'), findsOneWidget);
    expect(find.text('语言设置'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);

    final achievementStat = tester.widget<Text>(
      find.byKey(const Key('profile-stat-achievements')),
    );
    expect(achievementStat.data, '2');
  });

  testWidgets('prefers locally saved nickname and bio', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ProfilePreferences.nicknameKey: '东坡粉',
      ProfilePreferences.bioKey: '一路向南',
    });

    await pumpProfile(tester);

    expect(find.text('东坡粉'), findsOneWidget);
    expect(find.text('一路向南'), findsOneWidget);
    expect(find.text('旅行者'), findsNothing);
  });

  testWidgets('settings gear uses the injected callback', (tester) async {
    var tapped = false;
    await pumpProfile(
      tester,
      page: ProfilePage(onSettingsTap: () => tapped = true),
    );

    await tester.tap(find.byKey(const Key('profile-settings-button')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('settings gear opens SettingsPage without a callback', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.byKey(const Key('profile-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('切换人物'), findsOneWidget);
  });

  testWidgets('preference rows report the tapped item', (tester) async {
    final tapped = <ProfileSettingItem>[];
    await pumpProfile(tester, page: ProfilePage(onSettingItemTap: tapped.add));

    await tapAfterScroll(
      tester,
      find.byKey(const Key('profile-setting-account')),
    );
    await tapAfterScroll(
      tester,
      find.byKey(const Key('profile-setting-travel')),
    );
    await tapAfterScroll(
      tester,
      find.byKey(const Key('profile-setting-language')),
    );

    expect(tapped, <ProfileSettingItem>[
      ProfileSettingItem.account,
      ProfileSettingItem.travelPreference,
      ProfileSettingItem.language,
    ]);
  });

  testWidgets('account row opens AccountInfoPage without a callback', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tapAfterScroll(
      tester,
      find.byKey(const Key('profile-setting-account')),
    );

    expect(find.byType(AccountInfoPage), findsOneWidget);
  });

  testWidgets('achievement cards report their ids including locked ones', (
    tester,
  ) async {
    final tapped = <String>[];
    await pumpProfile(tester, page: ProfilePage(onAchievementTap: tapped.add));

    await tester.tap(find.byKey(const Key('achievement-card-song-ci-tracker')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('achievement-card-tang-poetry-master')),
    );
    await tester.pump();

    expect(tapped, <String>['song-ci-tracker', 'tang-poetry-master']);
  });

  testWidgets('locked achievement opens its detail page', (tester) async {
    await pumpProfile(tester);

    await tester.tap(
      find.byKey(const Key('achievement-card-tang-poetry-master')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AchievementDetailPage), findsOneWidget);
    expect(find.text('获取方法'), findsOneWidget);
    expect(find.text('当前进度'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
  });

  testWidgets('unlocked achievement detail shows the unlock time', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.byKey(const Key('achievement-card-song-ci-tracker')));
    await tester.pumpAndSettle();

    expect(find.byType(AchievementDetailPage), findsOneWidget);
    expect(find.text('获得时间'), findsOneWidget);
    expect(find.textContaining('2026-05-12'), findsOneWidget);
  });

  testWidgets('logout asks for confirmation before calling the callback', (
    tester,
  ) async {
    var loggedOut = false;
    await pumpProfile(
      tester,
      page: ProfilePage(onLogout: () => loggedOut = true),
    );

    await tapAfterScroll(
      tester,
      find.byKey(const Key('profile-logout-button')),
    );
    expect(find.text('退出后需要重新登录才能继续同步行程，确定要退出吗？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(loggedOut, isFalse);

    await tester.tap(find.byKey(const Key('profile-logout-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出'));
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
  });

  testWidgets('logout calls AuthService.signOut without a callback', (
    tester,
  ) async {
    var signedOut = false;
    final auth = AuthService(
      signOutHandler: () async {
        signedOut = true;
      },
    );
    await pumpProfile(tester, page: ProfilePage(authService: auth));

    await tapAfterScroll(
      tester,
      find.byKey(const Key('profile-logout-button')),
    );
    await tester.tap(find.text('退出'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });

  testWidgets('debug entry only appears when a debug callback is provided', (
    tester,
  ) async {
    await pumpProfile(tester, page: ProfilePage(onDebugRouteTap: () {}));
    expect(find.text('Debug'), findsOneWidget);

    await pumpProfile(tester);
    expect(find.text('Debug'), findsNothing);
  });
}
