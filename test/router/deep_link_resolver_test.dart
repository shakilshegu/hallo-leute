import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/router/deep_link_resolver.dart';
import 'package:poppylo/router/routes.dart';

void main() {
  group('resolveDeepLink', () {
    test('someone matched with you', () {
      expect(
        resolveDeepLink(Uri.parse('https://coffeemeet.app/match/m1')),
        AppRoutes.matchPath('m1'),
      );
    });

    test('they accepted', () {
      expect(
        resolveDeepLink(Uri.parse('coffeemeet://match/m1/confirmed')),
        AppRoutes.matchConfirmedPath('m1'),
      );
    });

    test('cafe suggested', () {
      expect(
        resolveDeepLink(
            Uri.parse('https://www.coffeemeet.app/match/m1/cafes/proposed')),
        AppRoutes.cafeProposedPath('m1'),
      );
    });

    test('meeting confirmed', () {
      expect(
        resolveDeepLink(Uri.parse('coffeemeet://meeting/g1/confirmed')),
        AppRoutes.meetingConfirmedPath('g1'),
      );
    });

    test('starting in 1 hour', () {
      expect(
        resolveDeepLink(Uri.parse('https://coffeemeet.app/meeting/g1')),
        AppRoutes.meetingPath('g1'),
      );
    });

    test('how was your coffee', () {
      expect(
        resolveDeepLink(Uri.parse('coffeemeet://meeting/g1/feedback')),
        AppRoutes.feedbackPath('g1'),
      );
    });

    test('new message', () {
      expect(
        resolveDeepLink(Uri.parse('coffeemeet://meeting/g1/chat')),
        AppRoutes.chatPath('g1'),
      );
    });

    test('unrecognized host is ignored', () {
      expect(
        resolveDeepLink(Uri.parse('https://example.com/match/m1')),
        isNull,
      );
    });

    test('unrecognized scheme is ignored', () {
      expect(
        resolveDeepLink(Uri.parse('mailto:hi@coffeemeet.app')),
        isNull,
      );
    });
  });
}
