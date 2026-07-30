import 'dart:async';

import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/i18n/strings.dart';
import 'package:eter/core/i18n/strings_en.dart';
import 'package:eter/core/i18n/strings_pl.dart';
import 'package:eter/core/account/account.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules an account has to hold, tested against the interface rather than
/// against Firebase — which is the point of there being an interface. Nothing
/// here needs a network, a platform channel or a project.
void main() {
  group('email plausibility', () {
    test('accepts ordinary addresses, including the awkward legal ones', () {
      for (final email in [
        'ar4wnn@gmail.com',
        'a@b.co',
        'first.last+tag@sub.domain.example',
        "o'brien@example.ie",
        'UPPER@EXAMPLE.COM',
      ]) {
        expect(AccountRules.isPlausibleEmail(email), isTrue, reason: email);
      }
    });

    test('refuses what cannot be an address', () {
      for (final email in [
        '',
        'nope',
        '@example.com',
        'someone@',
        'someone@example',
        'someone@.com',
        'someone@example.',
        'two@at@example.com',
        'has space@example.com',
        'a@b.c${'x' * 400}',
      ]) {
        expect(AccountRules.isPlausibleEmail(email), isFalse, reason: email);
      }
    });
  });

  group('passwords', () {
    test('eight characters is the whole rule', () {
      expect(AccountRules.isAcceptablePassword('1234567'), isFalse);
      expect(AccountRules.isAcceptablePassword('12345678'), isTrue);
      // No composition requirement: a long passphrase is a good password and
      // rules that forbid it produce worse ones.
      expect(
        AccountRules.isAcceptablePassword('correct horse battery staple'),
        isTrue,
      );
    });

    test('a typo costs no network call', () {
      expect(
        () => AccountRules.check(email: 'nope', password: 'longenough'),
        throwsA(isA<AccountException>().having(
          (error) => error.failure,
          'failure',
          AccountFailure.invalidEmail,
        )),
      );
      expect(
        () => AccountRules.check(email: 'a@b.co', password: 'short'),
        throwsA(isA<AccountException>().having(
          (error) => error.failure,
          'failure',
          AccountFailure.weakPassword,
        )),
      );
      expect(() => AccountRules.check(email: 'a@b.co'), returnsNormally);
    });
  });

  group('what the person is told', () {
    // Every language, not just the one the copy was written in. The sentences
    // moved out of `AccountException` and into the string tables, so these
    // invariants have to hold for each table — a Polish reader who mistypes a
    // password must get a sentence, not a provider code, and must not be able
    // to learn which addresses are registered either.
    for (final language in AppLanguage.values) {
      final strings = EterStrings.forLanguage(language);

      test('${language.code}: every failure has a sentence, not a code', () {
        for (final failure in AccountFailure.values) {
          final message = strings.accountFailure(failure);
          expect(message, isNotEmpty, reason: failure.name);
          expect(message, isNot(contains('auth/')), reason: failure.name);
          expect(message, isNot(contains('_')), reason: failure.name);
          expect(message.endsWith('.'), isTrue, reason: failure.name);
        }
      });

      test('${language.code}: a wrong password reveals nothing about the '
          'account', () {
        // Account enumeration: if these differed, an attacker could learn which
        // addresses are registered by trying them.
        expect(
          strings.accountFailure(AccountFailure.wrongPassword),
          strings.accountFailure(AccountFailure.noSuchAccount),
        );
      });
    }

    test('offline says the app still works, in both languages', () {
      expect(
        const EterStringsEn().accountFailure(AccountFailure.network),
        contains('offline'),
      );
      expect(
        const EterStringsPl().accountFailure(AccountFailure.network),
        contains('bez sieci'),
      );
    });
  });

  group('syncing', () {
    EterAccount account({
      required String provider,
      bool emailVerified = false,
    }) =>
        EterAccount(
          id: 'uid',
          email: 'someone@example.com',
          emailVerified: emailVerified,
          provider: provider,
        );

    test('an unconfirmed email account may not mirror anything', () {
      expect(account(provider: 'password').canSync, isFalse);
      expect(
        account(provider: 'password', emailVerified: true).canSync,
        isTrue,
      );
    });

    test('a provider that vouches for the address needs no confirmation', () {
      expect(account(provider: 'google').canSync, isTrue);
      expect(account(provider: 'apple').canSync, isTrue);
    });
  });

  group('the interface holds without a network', () {
    test('a fake service satisfies it, which is what the app depends on',
        () async {
      final service = _FakeAccountService();
      expect(service.current, isNull);

      final registered = await service.registerWithEmail(
        email: 'someone@example.com',
        password: 'longenough',
      );
      expect(registered.emailVerified, isFalse);
      expect(registered.canSync, isFalse);
      expect(service.verificationsSent, 1);

      await service.resendVerification();
      expect(service.verificationsSent, 2);

      service.confirmEmail();
      final refreshed = await service.refresh();
      expect(refreshed!.canSync, isTrue);

      await service.signOut();
      expect(service.current, isNull);
    });

    test('registering the same address twice is refused', () async {
      final service = _FakeAccountService();
      await service.registerWithEmail(
        email: 'someone@example.com',
        password: 'longenough',
      );
      await service.signOut();

      await expectLater(
        service.registerWithEmail(
          email: 'someone@example.com',
          password: 'longenough',
        ),
        throwsA(isA<AccountException>().having(
          (error) => error.failure,
          'failure',
          AccountFailure.emailInUse,
        )),
      );
    });

    test('changes() reports sign-in and sign-out', () async {
      final service = _FakeAccountService();
      final seen = <EterAccount?>[];
      final subscription = service.changes().listen(seen.add);

      await service.registerWithEmail(
        email: 'someone@example.com',
        password: 'longenough',
      );
      await service.signOut();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen, hasLength(2));
      expect(seen.first, isNotNull);
      expect(seen.last, isNull);
    });
  });
}

/// A complete in-memory account system. Its existence is the proof that
/// nothing above [AccountService] depends on Firebase.
class _FakeAccountService implements AccountService {
  final _controller = StreamController<EterAccount?>.broadcast();
  final _registered = <String, String>{};

  EterAccount? _current;
  int verificationsSent = 0;

  @override
  EterAccount? get current => _current;

  @override
  Stream<EterAccount?> changes() => _controller.stream;

  void _emit(EterAccount? account) {
    _current = account;
    _controller.add(account);
  }

  void confirmEmail() {
    final account = _current;
    if (account == null) return;
    _current = EterAccount(
      id: account.id,
      email: account.email,
      emailVerified: true,
      provider: account.provider,
    );
  }

  @override
  Future<EterAccount> registerWithEmail({
    required String email,
    required String password,
  }) async {
    AccountRules.check(email: email, password: password);
    if (_registered.containsKey(email)) {
      throw const AccountException(AccountFailure.emailInUse);
    }
    _registered[email] = password;
    verificationsSent += 1;
    final account = EterAccount(
      id: 'uid-${_registered.length}',
      email: email,
      emailVerified: false,
      provider: 'password',
    );
    _emit(account);
    return account;
  }

  @override
  Future<EterAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AccountRules.check(email: email);
    if (_registered[email] != password) {
      throw const AccountException(AccountFailure.wrongPassword);
    }
    final account = EterAccount(
      id: 'uid-1',
      email: email,
      emailVerified: true,
      provider: 'password',
    );
    _emit(account);
    return account;
  }

  @override
  Future<EterAccount> signInWithGoogle() async {
    const account = EterAccount(
      id: 'uid-google',
      email: 'someone@gmail.com',
      emailVerified: true,
      provider: 'google',
    );
    _emit(account);
    return account;
  }

  @override
  Future<void> resendVerification() async => verificationsSent += 1;

  @override
  Future<EterAccount?> refresh() async => _current;

  @override
  Future<void> sendPasswordReset(String email) async =>
      AccountRules.check(email: email);

  @override
  Future<void> signOut() async => _emit(null);

  @override
  Future<void> deleteAccount() async {
    _registered.remove(_current?.email);
    _emit(null);
  }
}
