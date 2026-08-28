import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/services/auth_service.dart';

void main() {
  group('AuthService password reset', () {
    test('requests a reset email using the app callback URL', () async {
      String? sentEmail;
      String? capturedRedirectTo;
      final service = AuthService(
        passwordResetSender: ({required email, required redirectTo}) async {
          sentEmail = email;
          capturedRedirectTo = redirectTo;
        },
      );

      await service.requestPasswordReset('  traveler@example.com  ');

      expect(sentEmail, 'traveler@example.com');
      expect(capturedRedirectTo, 'sageroute://login-callback/');
    });

    test('updates the password through the active recovery session', () async {
      String? updatedPassword;
      final service = AuthService(
        passwordUpdater: (password) async {
          updatedPassword = password;
        },
      );

      await service.updatePassword('new-secure-password');

      expect(updatedPassword, 'new-secure-password');
    });
  });
}
