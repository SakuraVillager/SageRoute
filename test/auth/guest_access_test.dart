import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sageroute/auth/auth_gate.dart';
import 'package:sageroute/auth/login_page.dart';
import 'package:sageroute/auth/reset_password_page.dart';
import 'package:sageroute/services/auth_service.dart';
import 'package:sageroute/services/credential_storage.dart';
import 'package:sageroute/services/guest_session.dart';
import 'package:sageroute/views/saved_routes_page.dart';
import 'package:sageroute/data/community_repository.dart';
import 'package:sageroute/data/social_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GuestSession.active.value = false;
  });
  tearDown(() => GuestSession.active.value = false);

  testWidgets('guest entry bypasses password login and opens the main screen', (
    tester,
  ) async {
    var passwordCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        routes: {'/main': (_) => const Text('游客主页')},
        home: LoginPage(
          authService: AuthService(
            passwordSignIn: ({required email, required password}) async {
              passwordCalls++;
              throw StateError('No password request expected');
            },
          ),
          credentialStorage: CredentialStorage(
            read: (_) async => null,
            write: (_, _) async {},
            delete: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('游客进入'));
    await tester.tap(find.text('游客进入'));
    await tester.pumpAndSettle();
    expect(find.text('游客主页'), findsOneWidget);
    expect(GuestSession.isActive, isTrue);
    expect(passwordCalls, 0);
  });

  testWidgets('auth gate admits a guest but recovery still takes priority', (
    tester,
  ) async {
    await GuestSession.enter();
    final auth = StreamController<AuthState>();
    addTearDown(auth.close);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authenticatedBuilder: (_) => const Text('浏览内容'),
          authStateChanges: auth.stream,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('浏览内容'), findsOneWidget);
    auth.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
    await tester.pumpAndSettle();
    expect(find.byType(ResetPasswordPage), findsOneWidget);
  });

  testWidgets('guest can browse discovery without requiring account content', (
    tester,
  ) async {
    await GuestSession.enter();
    await tester.pumpWidget(
      MaterialApp(
        home: SavedRoutesPage(
          repository: CommunityRepository(
            gateway: SocialGateway(userId: () => null, rpc: (_, _) async => []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('发现'), findsOneWidget);
    expect(find.text('这里还没有分享'), findsOneWidget);
    expect(find.text('登录 / 注册'), findsNothing);
  });

  test(
    'failed login retains guest access; successful login replaces it',
    () async {
      await GuestSession.enter();
      final failure = AuthService(
        passwordSignIn: ({required email, required password}) async {
          throw const AuthException('Invalid credentials');
        },
      );
      await expectLater(
        failure.signIn(email: 'guest@example.com', password: 'invalid'),
        throwsA(isA<AuthException>()),
      );
      expect(GuestSession.isActive, isTrue);
      const user = User(
        id: 'account-id',
        appMetadata: {},
        userMetadata: null,
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
      final success = AuthService(
        passwordSignIn: ({required email, required password}) async =>
            AuthResponse(
              session: Session(
                accessToken: 'test-token',
                tokenType: 'bearer',
                user: user,
              ),
              user: user,
            ),
      );
      await success.signIn(email: 'guest@example.com', password: 'valid');
      expect(GuestSession.isActive, isFalse);
    },
  );
}
