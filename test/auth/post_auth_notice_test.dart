import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/state/auth_controller.dart';

void main() {
  group('postAuthNotice', () {
    test('Log in with no existing account -> "set one up" notice', () {
      expect(
        postAuthNotice(
          intendedSignup: false,
          isNewUser: true,
          onboardingCompleted: false,
        ),
        "You don't have an account yet — let's set one up.",
      );
    });

    test('Get started with a finished account -> "welcome back" notice', () {
      expect(
        postAuthNotice(
          intendedSignup: true,
          isNewUser: false,
          onboardingCompleted: true,
        ),
        'You already have an account — welcome back.',
      );
    });

    test('Get started, brand-new account -> no notice (expected path)', () {
      expect(
        postAuthNotice(
          intendedSignup: true,
          isNewUser: true,
          onboardingCompleted: false,
        ),
        isNull,
      );
    });

    test('Log in, existing finished account -> no notice (expected path)', () {
      expect(
        postAuthNotice(
          intendedSignup: false,
          isNewUser: false,
          onboardingCompleted: true,
        ),
        isNull,
      );
    });

    test('Log in, existing account mid-onboarding -> no notice', () {
      // Account exists (not new) but hasn't finished onboarding — just resume,
      // no need to explain anything.
      expect(
        postAuthNotice(
          intendedSignup: false,
          isNewUser: false,
          onboardingCompleted: false,
        ),
        isNull,
      );
    });
  });
}
