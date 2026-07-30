import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'account.dart';

/// The only file in the app that knows Firebase exists.
///
/// Everything above it talks to [AccountService], which is why the rules can
/// be tested without a network and why a second provider — Apple, when there
/// is a membership to sign it with — is a change here and nowhere else.
class FirebaseAccountService implements AccountService {
  FirebaseAccountService({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  @override
  Stream<EterAccount?> changes() => _auth.userChanges().map(_toAccount);

  @override
  EterAccount? get current => _toAccount(_auth.currentUser);

  @override
  Future<EterAccount> registerWithEmail({
    required String email,
    required String password,
  }) async {
    AccountRules.check(email: email, password: password);
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Sent before the account is handed back, so the person is never told
      // they are registered without also being told to check their mail.
      await credential.user?.sendEmailVerification();
      return _require(credential.user);
    });
  }

  @override
  Future<EterAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AccountRules.check(email: email);
    return _guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _require(credential.user);
    });
  }

  @override
  Future<EterAccount> signInWithGoogle() => _guard(() async {
        final account = await _google.signIn();
        if (account == null) {
          // The person closed the sheet. Not an error worth a red message.
          throw const AccountException(AccountFailure.cancelled);
        }
        final auth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken,
          accessToken: auth.accessToken,
        );
        final result = await _auth.signInWithCredential(credential);
        return _require(result.user);
      });

  @override
  Future<void> resendVerification() => _guard(() async {
        await _auth.currentUser?.sendEmailVerification();
      });

  @override
  Future<EterAccount?> refresh() => _guard(() async {
        await _auth.currentUser?.reload();
        return _toAccount(_auth.currentUser);
      });

  @override
  Future<void> sendPasswordReset(String email) {
    AccountRules.check(email: email);
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> signOut() => _guard(() async {
        // Google's own session is signed out too, or the next sign-in silently
        // reuses the last account and looks like a bug.
        await _google.signOut();
        await _auth.signOut();
      });

  @override
  Future<void> deleteAccount() => _guard(() async {
        await _auth.currentUser?.delete();
      });

  EterAccount? _toAccount(User? user) {
    if (user == null) return null;
    final provider = user.providerData.isEmpty
        ? 'password'
        : switch (user.providerData.first.providerId) {
            'google.com' => 'google',
            'apple.com' => 'apple',
            _ => 'password',
          };
    return EterAccount(
      id: user.uid,
      email: user.email,
      // A Google or Apple address is verified by the provider itself.
      emailVerified: user.emailVerified || provider != 'password',
      provider: provider,
    );
  }

  EterAccount _require(User? user) {
    final account = _toAccount(user);
    if (account == null) {
      throw const AccountException(AccountFailure.unknown, 'no user returned');
    }
    return account;
  }

  /// Turns provider codes into the failures the interface speaks in.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AccountException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AccountException(
        switch (error.code) {
          'invalid-email' => AccountFailure.invalidEmail,
          'weak-password' => AccountFailure.weakPassword,
          'email-already-in-use' => AccountFailure.emailInUse,
          // Firebase collapses these two when email enumeration protection is
          // on, which is the behaviour we want; both say the same thing.
          'wrong-password' ||
          'invalid-credential' =>
            AccountFailure.wrongPassword,
          'user-not-found' => AccountFailure.noSuchAccount,
          'network-request-failed' => AccountFailure.network,
          'too-many-requests' => AccountFailure.tooManyAttempts,
          'requires-recent-login' => AccountFailure.requiresRecentLogin,
          _ => AccountFailure.unknown,
        },
        error.code,
      );
    } catch (error) {
      throw AccountException(AccountFailure.unknown, '$error');
    }
  }
}
