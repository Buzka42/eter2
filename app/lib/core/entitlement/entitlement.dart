/// Who may reach Aether, and why.
///
/// `STEERING_BRIEF.md` asks for one application with feature entitlements and
/// warns, twice, against coupling subscription checks to individual widgets. So
/// this file is the only place the rule lives: one pure resolver, one value, read
/// at section level. No surface asks "is this person subscribed" — surfaces ask
/// what access exists and choose their sentence from it.
///
/// The split follows the brief's own line. Free is the *record*: journal,
/// dictation, the local health log, the Body's charts, the deterministic Vessel —
/// chart, Life Path, keywords, the daily card — and export. All of it works with
/// no network and no model. Paid is the *intelligence*: the five model calls, and
/// what is composed from them.
///
/// Gating the record would be gating what someone already owns. For a product
/// whose pitch is that your history stays on your device, that is also how the
/// right to charge is earned.
library;

/// What a person may do with Aether right now.
enum AetherAccess {
  /// This build has no endpoint at all. Not a lapse and not a sale — the app is
  /// complete without a model and every surface already says so.
  unconfigured,

  /// Inside the trial. Carries [AetherEntitlement.trialDaysLeft].
  trial,

  /// Paid.
  subscribed,

  /// The trial ended and nothing replaced it. The record stays; the composing
  /// stops.
  lapsed,
}

/// A subscription as the app needs to understand it, which is barely at all.
///
/// Deliberately not a store receipt. The stores' own types differ, change, and
/// carry twenty fields nothing here reads; a surface only needs to know whether
/// this is currently good for access.
class EterSubscription {
  const EterSubscription({required this.active, this.expiresAt});

  /// True while the store says the entitlement is current — including inside a
  /// grace period, which is the store's judgement to make, not ours.
  final bool active;

  /// When it lapses, when that is known. Null is normal: several stores report
  /// only a boolean for an auto-renewing product.
  final DateTime? expiresAt;
}

/// Somewhere to buy and restore a subscription.
///
/// An interface with no implementation yet, exactly as `AccountService` was: null
/// is a shipped configuration, meaning this build has no billing. Every caller
/// must behave correctly when it is null, and the tests read it null by default so
/// that stays true.
abstract interface class SubscriptionService {
  /// The current subscription, and every change to it.
  Stream<EterSubscription?> changes();

  /// Begins a purchase. The store owns the entire interface for this; Eter shows
  /// nothing of its own beyond the sentence that leads here.
  Future<void> purchase(String productId);

  /// Re-reads entitlements the person already owns — a new phone, a reinstall,
  /// a family-sharing grant. Both stores require this to exist.
  Future<void> restorePurchases();
}

/// The one resolver.
class EterEntitlement {
  const EterEntitlement({required this.access, this.trialDaysLeft = 0});

  final AetherAccess access;

  /// Whole days remaining, floored, never negative. Zero on the last day, which
  /// is why the copy says "ends today" rather than counting to one.
  final int trialDaysLeft;

  /// True when the five model calls may be made.
  bool get composes =>
      access == AetherAccess.trial || access == AetherAccess.subscribed;

  /// The trial length, and it was chosen by the code rather than by feel.
  ///
  /// Eter's differentiator is a learned pattern about your own body, and
  /// `statistics.dart` will not return one before 21 paired days
  /// (`minimumPairs`). The recall window that lets guidance say "the third short
  /// night this week" only fills at 14. A 14-day trial therefore ended a week
  /// before the product became the thing it is sold as, and asked for money on a
  /// promise. Thirty crosses day 21, so the decision to pay is made by somebody
  /// who has read a true sentence about themselves.
  ///
  /// See `docs/DECISIONS.md`.
  static const trialDays = 30;

  /// Resolves access. Pure: every input is passed in.
  ///
  /// [hasEndpoint] comes first because it outranks everything. A build with no
  /// endpoint cannot compose whatever anyone has paid, and telling that person
  /// their trial has lapsed would be blaming them for a build.
  ///
  /// [trialStartedAt] is when this install first ran, not when onboarding
  /// finished — someone who opens Eter, looks around and comes back a week later
  /// has used a week of trial, and pretending otherwise would make the countdown
  /// disagree with the calendar. Null means the trial has not started, which
  /// resolves to [AetherAccess.trial] with a full allowance rather than to a
  /// lapse: an unknown start is not an expired one.
  static EterEntitlement resolve({
    required bool hasEndpoint,
    required DateTime now,
    DateTime? trialStartedAt,
    EterSubscription? subscription,
  }) {
    if (!hasEndpoint) {
      return const EterEntitlement(access: AetherAccess.unconfigured);
    }
    if (subscription?.active ?? false) {
      return const EterEntitlement(access: AetherAccess.subscribed);
    }
    if (trialStartedAt == null) {
      return const EterEntitlement(
        access: AetherAccess.trial,
        trialDaysLeft: trialDays,
      );
    }
    // Elapsed against the clock as it is now. Moving the device clock backwards
    // extends a trial, and that is a decision rather than an oversight: the
    // commoner hole is a reinstall, which resets a local start date entirely, and
    // both stores already enforce one-introductory-offer-per-account. Engineering
    // against clock-setting would buy nothing the store does not already give.
    final elapsed = now.difference(trialStartedAt).inDays;
    final remaining = trialDays - elapsed;
    return remaining > 0
        ? EterEntitlement(
            access: AetherAccess.trial,
            trialDaysLeft: remaining,
          )
        : const EterEntitlement(access: AetherAccess.lapsed);
  }
}
