import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/auth/auth_gate.dart';
import 'package:sageroute/auth/reset_password_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('shows reset password page for a password recovery callback', (
    tester,
  ) async {
    final controller = StreamController<AuthState>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authenticatedBuilder: (_) => const Text('主页'),
          authStateChanges: controller.stream,
        ),
      ),
    );
    controller.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
    await tester.pump();

    expect(find.byType(ResetPasswordPage), findsOneWidget);
    expect(find.text('主页'), findsNothing);
  });
}
