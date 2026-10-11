import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/services/credential_storage.dart';

void main() {
  test(
    'Web policy deletes legacy password and remembers only the email',
    () async {
      final values = <String, String>{CredentialStorage.passwordKey: 'legacy'};
      final reads = <String>[];
      final storage = CredentialStorage(
        persistPassword: false,
        read: (key) async {
          reads.add(key);
          return values[key];
        },
        write: (key, value) async {
          values[key] = value;
        },
        delete: (key) async {
          values.remove(key);
        },
      );
      await storage.save(
        email: 'traveler@example.com',
        password: 'must-not-persist',
      );
      expect(values.containsKey(CredentialStorage.passwordKey), isFalse);
      values[CredentialStorage.passwordKey] = 'old-password';
      final saved = await storage.load();
      expect(saved?.email, 'traveler@example.com');
      expect(saved?.password, isEmpty);
      expect(reads, isNot(contains(CredentialStorage.passwordKey)));
      expect(values.containsKey(CredentialStorage.passwordKey), isFalse);
      await storage.replacePassword(
        email: 'traveler@example.com',
        newPassword: 'new-password',
      );
      expect(values.containsKey(CredentialStorage.passwordKey), isFalse);
    },
  );
}
