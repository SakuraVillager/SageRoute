import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sageroute/services/guest_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GuestSession.active.value = false;
  });
  tearDown(() => GuestSession.active.value = false);

  test('guest access persists across startup and is cleared on exit', () async {
    await GuestSession.enter();
    expect(GuestSession.isActive, isTrue);
    GuestSession.active.value = false;
    await GuestSession.restore();
    expect(GuestSession.isActive, isTrue);
    await GuestSession.leave();
    await GuestSession.restore();
    expect(GuestSession.isActive, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool('hasSeenOnboarding'),
      isTrue,
    );
  });

  test('account sign in clears the guest preference', () async {
    await GuestSession.enter();
    await GuestSession.completeSignIn('account-user');
    expect(GuestSession.isActive, isFalse);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        GuestSession.preferenceKey,
      ),
      isFalse,
    );
  });

  test(
    'guests browse public content and plan without opening private routes',
    () {
      for (final path in [
        '/home',
        '/figures',
        '/figures/4',
        '/locations/19',
        '/articles/3',
        '/routes/new',
        '/profile',
        '/saved',
      ]) {
        expect(guestCanVisit(path), isTrue, reason: path);
      }
      for (final path in [
        '/routes/123',
        '/routes/123/edit',
        '/settings/account',
        '/reset-password',
        '/unknown',
      ]) {
        expect(guestCanVisit(path), isFalse, reason: path);
      }
    },
  );
}
