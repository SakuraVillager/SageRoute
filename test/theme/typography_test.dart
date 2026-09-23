import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/theme/app_theme.dart';

void main() {
  test('light and dark themes use the bundled application font', () {
    expect(
      AppTheme.lightTheme.textTheme.bodyLarge?.fontFamily,
      'SageRouteSans',
    );
    expect(AppTheme.darkTheme.textTheme.bodyLarge?.fontFamily, 'SageRouteSans');
  });
}
