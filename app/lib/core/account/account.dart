/// Accounts, and what having one does and does not change.
///
/// Eter opens, works and keeps every record with no account, no network and no
/// model. That is the product, and signing in does not alter it: the local
/// database stays canonical, every surface reads from it, and nothing waits on
/// a server. An account adds exactly one thing — the ability to get your
/// history back on a new phone.
///
/// So this is deliberately a small interface rather than a Firebase type
/// spread through the app. Two reasons. The surfaces should be unable to tell
/// which provider signed someone in, and the tests should never need a network
/// or a platform channel to prove the rules hold.
library;

/// Who is signed in, if anyone.
class EterAccount {
  const EterAccount({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.provider,
  });

  /// The stable identifier the mirror is keyed on. Never shown.
  final String id;

  /// Null for providers that do not release one.
  final String? email;

  /// False until a confirmation link has been followed.
  ///
  /// Nothing is mirrored for an unverified email account. An address someone
  /// has not proved they own is not an address their records should be
  /// recoverable through.
  final bool emailVerified;

  /// `password` | `google` | `apple`.
  final String provider;

  /// Whether this account may hold a mirror of the record.
  bool get canSync => provider != 'password' || emailVerified;
}

/// Every way signing in can fail, in terms the interface can speak about.
///
/// Deliberately not the provider's own codes: a surface should say "that
/// address is already registered", not surface `auth/email-already-in-use`.
enum AccountFailure {
  invalidEmail,
  weakPassword,
  emailInUse,
  wrongPassword,
  noSuchAccount,
  cancelled,
  network,
  tooManyAttempts,
  notVerified,
  unknown,
}

class AccountException implements Exception {
  const AccountException(this.failure, [this.detail]);

  final AccountFailure failure;
  final String? detail;

  /// What the person is told. One sentence, no jargon, and never a hint about
  /// whether an address exists — that is an account-enumeration leak.
  String get message => switch (failure) {
        AccountFailure.invalidEmail => 'That does not look like an email '
            'address.',
        AccountFailure.weakPassword =>
          'Choose a password of at least eight characters.',
        AccountFailure.emailInUse => 'That address is already registered. '
            'Sign in instead, or reset the password.',
        AccountFailure.wrongPassword ||
        AccountFailure.noSuchAccount =>
          'That email and password do not match.',
        AccountFailure.cancelled => 'Sign-in was cancelled.',
        AccountFailure.network =>
          'No connection. Eter works offline; sync will wait.',
        AccountFailure.tooManyAttempts =>
          'Too many attempts. Try again in a few minutes.',
        AccountFailure.notVerified =>
          'Confirm your email first — check for the link we sent.',
        AccountFailure.unknown => 'Sign-in failed. Nothing was changed.',
      };

  @override
  String toString() => 'AccountException(${failure.name}${
      detail == null ? '' : ': $detail'})';
}

/// What the app is allowed to ask of an account system.
abstract interface class AccountService {
  /// The current account, and every change to it. Emits null when signed out.
  Stream<EterAccount?> changes();

  /// The account signed in right now, without waiting.
  EterAccount? get current;

  /// Registers an address and sends a confirmation link.
  ///
  /// The account exists immediately but cannot sync until the link is
  /// followed; see [EterAccount.canSync].
  Future<EterAccount> registerWithEmail({
    required String email,
    required String password,
  });

  Future<EterAccount> signInWithEmail({
    required String email,
    required String password,
  });

  Future<EterAccount> signInWithGoogle();

  /// Sends the confirmation link again, for the common case of a lost email.
  Future<void> resendVerification();

  /// Re-reads the account from the provider, which is how a verification that
  /// happened in a mail client on another device becomes visible here.
  Future<EterAccount?> refresh();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// Deletes the account and everything mirrored under it.
  ///
  /// The local database is untouched: deleting an account is withdrawing from
  /// the mirror, not asking Eter to forget you. Erasing the local record is a
  /// separate, equally explicit action in the Sanctum.
  Future<void> deleteAccount();
}

/// The rules that hold whoever is signing in.
///
/// Kept out of the provider implementation so they are testable without one,
/// and so the same words are used everywhere they are enforced.
abstract final class AccountRules {
  /// Deliberately permissive. Address validation beyond this is a fool's
  /// errand — the confirmation email is the real check, and a rejected
  /// legitimate address is worse than an accepted typo.
  static bool isPlausibleEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.length < 3 || trimmed.length > 320) return false;
    if (trimmed.contains(' ')) return false;
    final at = trimmed.indexOf('@');
    if (at <= 0 || at != trimmed.lastIndexOf('@')) return false;
    final domain = trimmed.substring(at + 1);
    return domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.');
  }

  /// Eight characters, and no other rule.
  ///
  /// Composition requirements — a digit, a symbol, a capital — measurably
  /// produce worse passwords and are no longer recommended by anyone who has
  /// studied it. Length is the property that matters.
  static const minimumPasswordLength = 8;

  static bool isAcceptablePassword(String password) =>
      password.length >= minimumPasswordLength;

  /// Throws before a network call is made, so a typo costs nothing.
  static void check({required String email, String? password}) {
    if (!isPlausibleEmail(email)) {
      throw const AccountException(AccountFailure.invalidEmail);
    }
    if (password != null && !isAcceptablePassword(password)) {
      throw const AccountException(AccountFailure.weakPassword);
    }
  }
}
