import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/auth/login_page.dart';
import 'package:sageroute/services/auth_service.dart';
import 'package:sageroute/services/credential_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _testUser = User(
  id: 'test-user',
  appMetadata: {},
  userMetadata: null,
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

Session _testSession() => Session(
  accessToken: 'test-access-token',
  tokenType: 'bearer',
  user: _testUser,
);

void main() {
  late Map<String, String> store;
  late DateTime now;

  CredentialStorage buildStorage() => CredentialStorage(
    read: (key) async => store[key],
    write: (key, value) async => store[key] = value,
    delete: (key) async => store.remove(key),
    now: () => now,
  );

  Future<void> pumpLoginPage(
    WidgetTester tester, {
    required CredentialStorage storage,
    AuthService? authService,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {'/main': (context) => const Text('主界面')},
        home: LoginPage(authService: authService, credentialStorage: storage),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 读取页面中邮箱 / 密码输入框当前的文本。
  (String, String) readFieldTexts(WidgetTester tester) {
    final fields = find.byType(TextField);
    final email = tester.widget<TextField>(fields.at(0)).controller!.text;
    final password = tester.widget<TextField>(fields.at(1)).controller!.text;
    return (email, password);
  }

  setUp(() {
    store = {};
    now = DateTime(2026, 1, 10, 12);
  });

  group('LoginPage remembered credentials', () {
    testWidgets('prefills email and password within 7 days', (tester) async {
      final storage = buildStorage();
      await storage.save(email: 'user@example.com', password: 'secret123');
      now = now.add(const Duration(days: 6));

      await pumpLoginPage(tester, storage: storage);

      final (email, password) = readFieldTexts(tester);
      expect(email, 'user@example.com');
      expect(password, 'secret123');
    });

    testWidgets('does not prefill after 7 days and clears storage', (
      tester,
    ) async {
      final storage = buildStorage();
      await storage.save(email: 'user@example.com', password: 'secret123');
      now = now.add(const Duration(days: 7, seconds: 1));

      await pumpLoginPage(tester, storage: storage);

      final (email, password) = readFieldTexts(tester);
      expect(email, isEmpty);
      expect(password, isEmpty);
      expect(store, isEmpty);
    });

    testWidgets('saves credentials after a successful sign-in', (tester) async {
      final storage = buildStorage();
      final authService = AuthService(
        passwordSignIn: ({required email, required password}) async =>
            AuthResponse(session: _testSession(), user: _testUser),
      );

      await pumpLoginPage(tester, storage: storage, authService: authService);

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      expect(find.text('主界面'), findsOneWidget);
      final saved = await storage.load();
      expect(saved, isNotNull);
      expect(saved!.email, 'user@example.com');
      expect(saved.password, 'secret123');
    });

    testWidgets('saves the trimmed password that was actually submitted', (
      tester,
    ) async {
      final storage = buildStorage();
      final authService = AuthService(
        passwordSignIn: ({required email, required password}) async =>
            AuthResponse(session: _testSession(), user: _testUser),
      );

      await pumpLoginPage(tester, storage: storage, authService: authService);

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), ' secret123 ');
      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      final saved = await storage.load();
      expect(saved, isNotNull);
      expect(saved!.password, 'secret123');
    });

    testWidgets('does not save credentials when sign-in fails', (tester) async {
      final storage = buildStorage();
      final authService = AuthService(
        passwordSignIn: ({required email, required password}) async {
          throw const AuthException('Invalid login credentials');
        },
      );

      await pumpLoginPage(tester, storage: storage, authService: authService);

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      expect(store, isEmpty);
      expect(find.text('邮箱或密码错误，请重试'), findsOneWidget);
    });
  });
}
