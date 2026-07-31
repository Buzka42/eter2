import 'package:eter/core/invitation/evening_invitation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one time Eter speaks first.
///
/// The rule is small and the ways to get it wrong are not: inviting somebody
/// who already wrote, inviting at a sunset that has passed, inviting at all
/// without consent, or falling silent for six months above the Arctic Circle.
void main() {
  // Warsaw. Far enough north that the sunset moves a lot across the year,
  // which is the point of using the real one.
  const warsaw = (latitude: 52.23, longitude: 21.01);

  group('consent', () {
    test('off by default means nothing is scheduled', () {
      final decision = EveningInvitation.nextAt(
        now: DateTime(2026, 7, 31, 9),
        consented: false,
        wroteToday: false,
        latitude: warsaw.latitude,
        longitude: warsaw.longitude,
      );
      expect(decision.isScheduled, isFalse);
      expect(decision.refusal, InvitationRefusal.notConsented);
    });
  });

  group('when it lands', () {
    test('after today’s sunset, on today’s date', () {
      final decision = EveningInvitation.nextAt(
        now: DateTime(2026, 7, 31, 9),
        consented: true,
        wroteToday: false,
        latitude: warsaw.latitude,
        longitude: warsaw.longitude,
      );
      final at = decision.at!;
      expect(at.year, 2026);
      expect(at.month, 7);
      expect(at.day, 31);
      // Late July in Warsaw: sunset is around 20:30 local, so the invitation
      // is in the evening rather than the afternoon or the small hours.
      expect(at.hour, inInclusiveRange(18, 23));
    });

    test('the hour moves with the season, which is the whole point', () {
      DateTime evening(DateTime day) => EveningInvitation.nextAt(
            now: day,
            consented: true,
            wroteToday: false,
            latitude: warsaw.latitude,
            longitude: warsaw.longitude,
          ).at!;

      final summer = evening(DateTime(2026, 6, 21, 9));
      final winter = evening(DateTime(2026, 12, 21, 9));
      // A clock time would have made these identical. They must not be.
      expect(summer.hour, greaterThan(winter.hour + 2));
    });

    test('a sunset already past schedules tomorrow, not the past', () {
      final decision = EveningInvitation.nextAt(
        // Late at night, well after the invitation would have fired.
        now: DateTime(2026, 7, 31, 23, 30),
        consented: true,
        wroteToday: false,
        latitude: warsaw.latitude,
        longitude: warsaw.longitude,
      );
      expect(decision.at!.day, 1);
      expect(decision.at!.month, 8);
      expect(decision.at!.isAfter(DateTime(2026, 7, 31, 23, 30)), isTrue);
    });
  });

  test('somebody who already wrote is not asked again today', () {
    final decision = EveningInvitation.nextAt(
      now: DateTime(2026, 7, 31, 9),
      consented: true,
      wroteToday: true,
      latitude: warsaw.latitude,
      longitude: warsaw.longitude,
    );
    // An invitation, not a reminder: it moves to tomorrow rather than firing
    // at somebody who has already done the thing it invites.
    expect(decision.at!.day, 1);
    expect(decision.at!.month, 8);
  });

  group('where there is no horizon to read', () {
    test('the common case is no coordinates, not a polar night', () {
      // A real profile carried `birth_place = 'Warsaw'` and no latitude, so
      // this branch is the ordinary one rather than the exotic one.
      final decision = EveningInvitation.nextAt(
        now: DateTime(2026, 7, 31, 9),
        consented: true,
        wroteToday: false,
        latitude: null,
        longitude: 21.01,
      );
      expect(decision.at!.hour, EveningInvitation.fallbackHour);
    });

    test('no coordinates falls back to a clock hour rather than silence', () {
      final decision = EveningInvitation.nextAt(
        now: DateTime(2026, 7, 31, 9),
        consented: true,
        wroteToday: false,
      );
      expect(decision.at, DateTime(2026, 7, 31, EveningInvitation.fallbackHour));
    });

    test('a polar summer still gets an invitation', () {
      // Longyearbyen in June: the sun does not set at all, so `SolarDay` has
      // no sunset to offer. Falling silent for a season would be a worse
      // answer than the dull one the register already gives.
      final decision = EveningInvitation.nextAt(
        now: DateTime(2026, 6, 21, 9),
        consented: true,
        wroteToday: false,
        latitude: 78.22,
        longitude: 15.63,
      );
      expect(decision.isScheduled, isTrue);
      expect(decision.at!.hour, EveningInvitation.fallbackHour);
    });
  });
}
