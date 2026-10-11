import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/auth/forgot_password_page.dart';
import 'package:sageroute/auth/reset_password_page.dart';
import 'package:sageroute/services/auth_service.dart';

void main() {
  testWidgets('forgot password page submits the entered email', (tester) async {
    String? submittedEmail;
    final authService = AuthService(
      passwordResetSender: ({required email, required redirectTo}) async {
        submittedEmail = email;
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordPage(authService: authService)),
    );

    await tester.enterText(find.byType(TextField), 'traveler@example.com');
    await tester.tap(find.text('发送重置邮件'));
    await tester.pumpAndSettle();

    expect(submittedEmail, 'traveler@example.com');
    expect(find.text('重置邮件已发送'), findsOneWidget);
  });

  testWidgets('reset password page updates matching passwords', (tester) async {
    String? updatedPassword;
    final authService = AuthService(
      passwordUpdater: (password) async {
        updatedPassword = password;
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: ResetPasswordPage(authService: authService)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'new-password');
    await tester.enterText(find.byType(TextField).at(1), 'new-password');
    await tester.tap(find.text('更新密码'));
    await tester.pumpAndSettle();

    expect(updatedPassword, 'new-password');
    expect(find.text('密码已更新'), findsOneWidget);
  });
}
