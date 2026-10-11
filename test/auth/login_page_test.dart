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

AuthService _successfulAuthService() => AuthService(
  passwordSignIn: ({required email, required password}) async =>
      AuthResponse(session: _testSession(), user: _testUser),
);

void main() {
  late Map<String, String> store;
  late DateTime now;

  CredentialStorage buildStorage({Duration? readDelay}) => CredentialStorage(
    read: (key) async {
      if (readDelay != null) await Future<void>.delayed(readDelay);
      return store[key];
    },
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

  bool rememberCheckboxValue(WidgetTester tester) =>
      tester.widget<Checkbox>(find.byType(Checkbox)).value!;

  Future<void> checkRememberBox(WidgetTester tester) async {
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
  }

  setUp(() {
    store = {};
    now = DateTime(2026, 1, 10, 12);
  });

  group('LoginPage remembered credentials', () {
    testWidgets('prefills fields and checks the box within 7 days', (
      tester,
    ) async {
      final storage = buildStorage();
      await storage.save(email: 'user@example.com', password: 'secret123');
      now = now.add(const Duration(days: 6));

      await pumpLoginPage(tester, storage: storage);

      final (email, password) = readFieldTexts(tester);
      expect(email, 'user@example.com');
      expect(password, 'secret123');
      expect(rememberCheckboxValue(tester), isTrue);
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
      expect(rememberCheckboxValue(tester), isFalse);
      expect(store, isEmpty);
    });

    testWidgets('restore does not clobber already entered input', (
      tester,
    ) async {
      final storage = buildStorage(readDelay: const Duration(milliseconds: 50));
      await storage.save(email: 'user@example.com', password: 'secret123');

      // 先渲染页面（异步恢复尚未完成），立刻手动输入内容。
      await tester.pumpWidget(
        MaterialApp(
          routes: {'/main': (context) => const Text('主界面')},
          home: LoginPage(credentialStorage: storage),
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), 'typed@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'typed-password');
      await tester.pumpAndSettle();

      final (email, password) = readFieldTexts(tester);
      expect(email, 'typed@example.com');
      expect(password, 'typed-password');
      expect(rememberCheckboxValue(tester), isFalse);
    });

    testWidgets('does not save credentials when the box is left unchecked', (
      tester,
    ) async {
      final storage = buildStorage();

      await pumpLoginPage(
        tester,
        storage: storage,
        authService: _successfulAuthService(),
      );
      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      expect(find.text('主界面'), findsOneWidget);
      expect(store, isEmpty);
    });

    testWidgets('saves credentials after a checked successful sign-in', (
      tester,
    ) async {
      final storage = buildStorage();

      await pumpLoginPage(
        tester,
        storage: storage,
        authService: _successfulAuthService(),
      );
      await checkRememberBox(tester);
      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      final saved = await storage.load();
      expect(saved, isNotNull);
      expect(saved!.email, 'user@example.com');
      expect(saved.password, 'secret123');
    });

    testWidgets('saves the trimmed password that was actually submitted', (
      tester,
    ) async {
      final storage = buildStorage();

      await pumpLoginPage(
        tester,
        storage: storage,
        authService: _successfulAuthService(),
      );
      await checkRememberBox(tester);
      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), ' secret123 ');
      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      final saved = await storage.load();
      expect(saved, isNotNull);
      expect(saved!.password, 'secret123');
    });

    testWidgets('clears saved credentials when unchecked at sign-in', (
      tester,
    ) async {
      final storage = buildStorage();
      await storage.save(email: 'user@example.com', password: 'secret123');

      // 已保存 -> 打开页面自动填充且勾选；取消勾选后登录 -> 清除。
      await pumpLoginPage(
        tester,
        storage: storage,
        authService: _successfulAuthService(),
      );
      expect(rememberCheckboxValue(tester), isTrue);

      await checkRememberBox(tester);
      expect(rememberCheckboxValue(tester), isFalse);

      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      expect(find.text('主界面'), findsOneWidget);
      expect(store, isEmpty);
      expect(await storage.load(), isNull);
    });

    testWidgets('does not save credentials when sign-in fails', (tester) async {
      final storage = buildStorage();
      final authService = AuthService(
        passwordSignIn: ({required email, required password}) async {
          throw const AuthException('Invalid login credentials');
        },
      );

      await pumpLoginPage(tester, storage: storage, authService: authService);
      await checkRememberBox(tester);

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.text('登 录'));
      await tester.pumpAndSettle();

      expect(store, isEmpty);
      expect(find.text('邮箱或密码错误，请重试'), findsOneWidget);
    });

    testWidgets('tapping the info icon explains the retention period', (
      tester,
    ) async {
      final storage = buildStorage();

      await pumpLoginPage(
        tester,
        storage: storage,
        authService: _successfulAuthService(),
      );

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('记住密码说明'), findsOneWidget);
      expect(find.textContaining('保留 7 天'), findsOneWidget);
      expect(find.text('知道了'), findsOneWidget);

      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
      expect(find.text('记住密码说明'), findsNothing);
    });

    testWidgets('tapping the remember label toggles the checkbox', (
      tester,
    ) async {
      final storage = buildStorage();

      await pumpLoginPage(
        tester,
        storage: storage,
        authService: _successfulAuthService(),
      );
      expect(rememberCheckboxValue(tester), isFalse);

      await tester.tap(find.text('记住密码'));
      await tester.pump();

      expect(rememberCheckboxValue(tester), isTrue);
    });
  });
}
