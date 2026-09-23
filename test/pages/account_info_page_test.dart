import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/pages/account_info_page.dart';
import 'package:sageroute/services/auth_service.dart';
import 'package:sageroute/services/profile_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/page_test_harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpAccountInfo(
    WidgetTester tester, {
    AuthService? authService,
    String email = 'traveler@example.com',
  }) async {
    useLargeSurface(tester);
    await pumpPushedPage(
      tester,
      AccountInfoPage(
        email: email,
        initialNickname: '旅行者',
        authService: authService,
      ),
    );
  }

  testWidgets('shows bound email and prefills the account nickname', (
    tester,
  ) async {
    await pumpAccountInfo(tester);

    expect(find.text('traveler@example.com'), findsOneWidget);

    final nicknameField = tester.widget<TextField>(
      find.byKey(const Key('account-nickname-field')),
    );
    expect(nicknameField.controller?.text, '旅行者');
  });

  testWidgets('saves nickname and bio locally then pops', (tester) async {
    await pumpAccountInfo(tester);

    await tester.enterText(
      find.byKey(const Key('account-nickname-field')),
      '东坡粉',
    );
    await tester.enterText(find.byKey(const Key('account-bio-field')), '一路向南');
    await tester.tap(find.byKey(const Key('account-save-button')));
    await tester.pumpAndSettle();

    expect(find.byType(AccountInfoPage), findsNothing);

    final state = await ProfilePreferences().load();
    expect(state.nickname, '东坡粉');
    expect(state.bio, '一路向南');
  });

  testWidgets('rejects an empty nickname', (tester) async {
    await pumpAccountInfo(tester);

    await tester.enterText(find.byKey(const Key('account-nickname-field')), '');
    await tester.tap(find.byKey(const Key('account-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('昵称不能为空'), findsOneWidget);
    expect(find.byType(AccountInfoPage), findsOneWidget);
  });

  testWidgets('change password sends a reset email to the bound address', (
    tester,
  ) async {
    String? sentEmail;
    final auth = AuthService(
      passwordResetSender: ({required email, required redirectTo}) async {
        sentEmail = email;
      },
    );
    await pumpAccountInfo(tester, authService: auth);

    await tester.tap(find.byKey(const Key('account-change-password')));
    await tester.pumpAndSettle();

    expect(find.textContaining('traveler@example.com'), findsWidgets);

    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();

    expect(sentEmail, 'traveler@example.com');
    expect(find.text('重置邮件已发送，请查收'), findsOneWidget);
  });
}
