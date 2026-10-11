import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/services/credential_storage.dart';

void main() {
  late Map<String, String> store;
  late DateTime now;
  late CredentialStorage storage;

  CredentialStorage buildStorage() => CredentialStorage(
    read: (key) async => store[key],
    write: (key, value) async => store[key] = value,
    delete: (key) async => store.remove(key),
    now: () => now,
  );

  setUp(() {
    store = {};
    now = DateTime(2026, 1, 10, 12);
    storage = buildStorage();
  });

  group('CredentialStorage', () {
    test('save and load round-trips within the validity window', () async {
      await storage.save(email: 'user@example.com', password: 'secret123');

      final loaded = await storage.load();

      expect(loaded, isNotNull);
      expect(loaded!.email, 'user@example.com');
      expect(loaded.password, 'secret123');
      expect(loaded.savedAt, now);
    });

    test('load returns null when nothing was saved', () async {
      expect(await storage.load(), isNull);
      // 空数据不应触发清理或写入。
      expect(store, isEmpty);
    });

    test('save overwrites a previously remembered account', () async {
      await storage.save(email: 'a@example.com', password: 'password-a');
      await storage.save(email: 'b@example.com', password: 'password-b');

      final loaded = await storage.load();

      expect(loaded!.email, 'b@example.com');
      expect(loaded.password, 'password-b');
    });

    test('each save refreshes the timestamp', () async {
      await storage.save(email: 'user@example.com', password: 'secret123');
      now = now.add(const Duration(days: 5));
      await storage.save(email: 'user@example.com', password: 'secret123');

      final loaded = await storage.load();

      expect(loaded, isNotNull);
      expect(loaded!.savedAt, now);
    });

    test('credentials exactly at the 7 day boundary still load', () async {
      await storage.save(email: 'user@example.com', password: 'secret123');
      now = now.add(CredentialStorage.validity);

      expect(await storage.load(), isNotNull);
    });

    test(
      'credentials older than 7 days are cleared and not returned',
      () async {
        await storage.save(email: 'user@example.com', password: 'secret123');
        now = now.add(CredentialStorage.validity + const Duration(seconds: 1));

        expect(await storage.load(), isNull);
        expect(store, isEmpty);
      },
    );

    test('a timestamp from the future is treated as corrupt', () async {
      await storage.save(email: 'user@example.com', password: 'secret123');
      now = now.subtract(const Duration(days: 1));

      expect(await storage.load(), isNull);
      expect(store, isEmpty);
    });

    test('a corrupt password entry is cleared', () async {
      await storage.save(email: 'user@example.com', password: 'secret123');
      store[CredentialStorage.passwordKey] = 'not-base64-###';

      expect(await storage.load(), isNull);
      expect(store, isEmpty);
    });

    test('a corrupt timestamp entry is cleared', () async {
      await storage.save(email: 'user@example.com', password: 'secret123');
      store[CredentialStorage.timestampKey] = 'not-a-number';

      expect(await storage.load(), isNull);
      expect(store, isEmpty);
    });

    test('clear removes every stored key', () async {
      await storage.save(email: 'user@example.com', password: 'secret123');

      await storage.clear();

      expect(store, isEmpty);
      expect(await storage.load(), isNull);
    });

    group('replacePassword', () {
      test('updates the stored password when the email matches', () async {
        await storage.save(email: 'user@example.com', password: 'old-password');

        await storage.replacePassword(
          email: 'user@example.com',
          newPassword: 'new-password',
        );

        final loaded = await storage.load();
        expect(loaded!.email, 'user@example.com');
        expect(loaded.password, 'new-password');
      });

      test(
        'keeps the original timestamp when replacing the password',
        () async {
          await storage.save(
            email: 'user@example.com',
            password: 'old-password',
          );
          final savedAtBefore = (await storage.load())!.savedAt;
          now = now.add(const Duration(days: 3));

          await storage.replacePassword(
            email: 'user@example.com',
            newPassword: 'new-password',
          );

          final loaded = await storage.load();
          expect(loaded, isNotNull);
          expect(loaded!.savedAt, savedAtBefore);
        },
      );

      test('does nothing when the email does not match', () async {
        await storage.save(email: 'user@example.com', password: 'old-password');

        await storage.replacePassword(
          email: 'other@example.com',
          newPassword: 'new-password',
        );

        final loaded = await storage.load();
        expect(loaded!.password, 'old-password');
      });

      test('does nothing when nothing was saved', () async {
        await storage.replacePassword(
          email: 'user@example.com',
          newPassword: 'new-password',
        );

        expect(store, isEmpty);
        expect(await storage.load(), isNull);
      });
    });
  });
}
