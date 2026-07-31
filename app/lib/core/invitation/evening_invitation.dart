/// Eter may speak first, once.
///
/// One quiet local notification in the evening, inviting a page. **Off by
/// default.** Nothing else: no morning reading, no streak nudge, no
/// re-engagement, no "you haven't opened Eter in a while". `DECISIONS.md`
/// closes that question, and this file is the whole of it.
///
/// It is scheduled on the **real sunset** the register already computes rather
/// than a clock time, so the invitation arrives with the night register instead
/// of arbitrarily. That is the difference between the product noticing the
/// evening and an alarm going off at eight.
///
/// Everything here is pure. The decision of *whether and when* is separable
/// from the platform call that delivers it, and only the platform half needs a
/// phone — which is why the rule is tested and the delivery is not.
library;

import '../symbolic/solar.dart';

/// Why no invitation is scheduled. Distinct cases because they are distinct
/// answers: "you turned it off" is not "there is nowhere to put it".
enum InvitationRefusal {
  /// Off by default, and still off.
  notConsented,

  /// A page was already written today. Eter has nothing to invite.
  alreadyWritten,

  /// No usable coordinates *and* no clock fallback wanted — see
  /// [EveningInvitation.nextAt] on why this is not reachable today.
  nowhereToPlaceIt,
}

class InvitationDecision {
  const InvitationDecision.scheduled(DateTime this.at) : refusal = null;
  const InvitationDecision.refused(InvitationRefusal this.refusal) : at = null;

  /// Local time the invitation should fire, or null.
  final DateTime? at;
  final InvitationRefusal? refusal;

  bool get isScheduled => at != null;
}

abstract final class EveningInvitation {
  /// How long after sunset the invitation arrives.
  ///
  /// Not at sunset itself. The register turns then, and a notification landing
  /// on the same minute reads as the app announcing its own theme change. Half
  /// an hour later the evening has actually started.
  static const after = Duration(minutes: 30);

  /// The hour used where the sun does not set.
  ///
  /// A polar summer would otherwise mean no invitation for months, and a polar
  /// winter would mean one at a sunset that never happens. The register already
  /// degrades to the clock when it has no horizon to read; this degrades the
  /// same way rather than inventing a second policy.
  static const polarFallbackHour = 20;

  /// When the next invitation should fire, in local time.
  ///
  /// [now] is local. [wroteToday] is the courtesy that makes this an invitation
  /// rather than a reminder: somebody who has already written does not need
  /// asking, and a notification that arrives anyway is a nag.
  ///
  /// Returns tomorrow's when today's has passed, so the caller can schedule one
  /// and only one pending notification at a time.
  static InvitationDecision nextAt({
    required DateTime now,
    required bool consented,
    required bool wroteToday,
    double? latitude,
    double? longitude,
  }) {
    if (!consented) {
      return const InvitationDecision.refused(InvitationRefusal.notConsented);
    }
    if (wroteToday) {
      // Only today's is suppressed. Tomorrow is scheduled when tomorrow's
      // Journal opens without a page in it.
      final tomorrow = _atOn(
        now.add(const Duration(days: 1)),
        latitude: latitude,
        longitude: longitude,
      );
      return InvitationDecision.scheduled(tomorrow);
    }

    final today = _atOn(now, latitude: latitude, longitude: longitude);
    if (today.isAfter(now)) return InvitationDecision.scheduled(today);
    return InvitationDecision.scheduled(
      _atOn(
        now.add(const Duration(days: 1)),
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  /// The invitation's local instant on [day]'s date.
  static DateTime _atOn(
    DateTime day, {
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      final solar = solarDayFor(
        instant: day,
        latitude: latitude,
        longitude: longitude,
      );
      if (solar.sunsetUtc case final sunset?) {
        final local = sunset.toLocal().add(after);
        // The sunset for a UTC calendar day can land on the neighbouring local
        // date near the date line. The invitation belongs to the day it was
        // asked about, so it is placed on that date at the computed clock time.
        return DateTime(
          day.year,
          day.month,
          day.day,
          local.hour,
          local.minute,
        );
      }
    }
    return DateTime(day.year, day.month, day.day, polarFallbackHour);
  }
}
