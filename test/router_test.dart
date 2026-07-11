import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/router.dart';

void main() {
  test('auth routes are recognised', () {
    expect(isAuthRoute('/login'), isTrue);
    expect(isAuthRoute('/signup'), isTrue);
    expect(isAuthRoute('/forgot-password'), isTrue);
  });

  test('protected routes are not auth routes', () {
    expect(isAuthRoute('/'), isFalse);
    expect(isAuthRoute('/entry/123'), isFalse);
  });
}
