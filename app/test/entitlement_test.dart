import 'package:eter/core/entitlement/entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one rule that decides whether Aether may compose.
///
/// It is a pure function precisely so it can be pinned like this. Getting it wrong
/// in the generous direction gives the product away; getting it wrong in the mean
/// direction tells somebody who has paid that they have not.
void main() {
  final launch = DateTime.utc(2026, 7, 1, 9);

  EterEntitlement at(
    Duration since, {
    bool hasEndpoint = true,
    DateTime? startedAt,
    EterSubscription? subscription,
  }) =>
      EterEntitlement.resolve(
        hasEndpoint: hasEndpoint,
        now: launch.add(since),
        trialStartedAt: startedAt ?? launch,
        subscription: subscription,
      );

  group('the trial', () {
    test('is thirty days, because 21 is when a pattern can first exist', () {
      // Not a round number chosen by feel. `statistics.dart` will not return a
      // pattern before 21 paired days, so a trial has to outlast that or it ends
      // before the product becomes what it is sold as.
      expect(EterEntitlement.trialDays, 30);
      expect(EterEntitlement.trialDays, greaterThan(21));
    });

    test('composes on the first day and the twenty-ninth', () {
      expect(at(Duration.zero).composes, isTrue);
      expect(at(const Duration(days: 29)).composes, isTrue);
    });

    test('counts down in whole days', () {
      expect(at(Duration.zero).trialDaysLeft, 30);
      expect(at(const Duration(days: 1)).trialDaysLeft, 29);
      // Part-way through a day is still that day; the copy says "ends today"
      // rather than counting to one.
      expect(at(const Duration(days: 29, hours: 20)).trialDaysLeft, 1);
    });

    test('lapses once the thirtieth day is behind it', () {
      final lapsed = at(const Duration(days: 30));
      expect(lapsed.access, AetherAccess.lapsed);
      expect(lapsed.composes, isFalse);
      expect(at(const Duration(days: 400)).access, AetherAccess.lapsed);
    });

    test('an unknown start is a full trial, not an expired one', () {
      // Null happens before `main` has read the mark, and on a store that would
      // not answer. Reading it as a lapse would refuse somebody for a failure
      // that was ours.
      final unknown = EterEntitlement.resolve(
        hasEndpoint: true,
        now: launch,
        trialStartedAt: null,
      );
      expect(unknown.access, AetherAccess.trial);
      expect(unknown.trialDaysLeft, EterEntitlement.trialDays);
    });
  });

  group('a subscription', () {
    test('outranks a lapsed trial', () {
      final subscribed = at(
        const Duration(days: 90),
        subscription: const EterSubscription(active: true),
      );
      expect(subscribed.access, AetherAccess.subscribed);
      expect(subscribed.composes, isTrue);
    });

    test('an inactive one does not rescue a lapsed trial', () {
      expect(
        at(
          const Duration(days: 90),
          subscription: const EterSubscription(active: false),
        ).access,
        AetherAccess.lapsed,
      );
    });

    test('an inactive one does not shorten a running trial either', () {
      // Cancelled-but-still-in-trial is an ordinary state and must not read as a
      // lapse.
      expect(
        at(
          const Duration(days: 3),
          subscription: const EterSubscription(active: false),
        ).access,
        AetherAccess.trial,
      );
    });
  });

  group('no endpoint', () {
    test('outranks everything, including a paid subscription', () {
      // A build compiled without an endpoint cannot compose whatever anybody has
      // paid. Reporting that as a lapse would blame the person for a build, and
      // reporting it as subscribed would promise something that cannot happen.
      final unconfigured = at(
        Duration.zero,
        hasEndpoint: false,
        subscription: const EterSubscription(active: true),
      );
      expect(unconfigured.access, AetherAccess.unconfigured);
      expect(unconfigured.composes, isFalse);
    });

    test('is not a lapse even long after the trial would have ended', () {
      expect(
        at(const Duration(days: 400), hasEndpoint: false).access,
        AetherAccess.unconfigured,
      );
    });
  });
}
