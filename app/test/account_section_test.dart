import 'dart:async';

import 'package:eter/core/account/account.dart';
import 'package:eter/core/controls.dart';
import 'package:eter/core/theme.dart';
import 'package:eter/features/sanctum/account_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the Sanctum says about accounts, in each of the four states it can be
/// in. The copy is the feature here: an account is offered as recovery and
/// nothing else, and every state has to keep saying that the local record is
/// safe.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    AccountService? service,
    EterAccount? account,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: EterTheme.day(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: AccountSection(service: service, account: account),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('a build with no account system says so without alarm',
      (tester) async {
    await pump(tester);

    expect(find.textContaining('no account system'), findsOneWidget);
    expect(find.textContaining('Everything works'), findsOneWidget);
    expect(find.text('SIGN IN'), findsNothing);
  });

  testWidgets('signed out, it offers recovery rather than selling a feature',
      (tester) async {
    await pump(tester, service: _FakeAccountService());

    expect(find.textContaining('needs no account'), findsOneWidget);
    expect(find.textContaining('when you change phone'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
  });

  testWidgets('a typo is refused before any network call', (tester) async {
    final service = _FakeAccountService();
    await pump(tester, service: service);

    await tester.enterText(find.byType(TextField).first, 'not-an-address');
    await tester.enterText(find.byType(TextField).last, 'longenough');
    await tester.tap(find.text('SIGN IN'));
    await tester.pump();

    expect(find.textContaining('does not look like an email'), findsOneWidget);
    expect(service.signInAttempts, 0);
  });

  testWidgets('registering tells the person to go and confirm', (tester) async {
    final service = _FakeAccountService();
    await pump(tester, service: service);

    await tester.tap(find.text('CREATE ONE'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'someone@example.com');
    await tester.enterText(find.byType(TextField).last, 'longenough');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.textContaining('confirmation link'), findsOneWidget);
    // The reassurance matters more than the instruction.
    expect(find.textContaining('stays here'), findsOneWidget);
  });

  testWidgets('a short password never reaches the provider', (tester) async {
    final service = _FakeAccountService();
    await pump(tester, service: service);

    await tester.tap(find.text('CREATE ONE'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'someone@example.com');
    await tester.enterText(find.byType(TextField).last, 'short');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.textContaining('at least eight'), findsOneWidget);
    expect(service.registerAttempts, 0);
  });

  testWidgets('an unconfirmed account is told what is and is not happening',
      (tester) async {
    await pump(
      tester,
      service: _FakeAccountService(),
      account: const EterAccount(
        id: 'uid',
        email: 'someone@example.com',
        emailVerified: false,
        provider: 'password',
      ),
    );

    expect(find.text('someone@example.com'), findsOneWidget);
    expect(find.textContaining('nothing leaves this device'), findsOneWidget);
    expect(find.text('RESEND LINK'), findsOneWidget);
    expect(find.text('I HAVE CONFIRMED'), findsOneWidget);
  });

  testWidgets('a confirmed account is not nagged', (tester) async {
    await pump(
      tester,
      service: _FakeAccountService(),
      account: const EterAccount(
        id: 'uid',
        email: 'someone@example.com',
        emailVerified: true,
        provider: 'password',
      ),
    );

    expect(find.textContaining('restored on a new phone'), findsOneWidget);
    expect(find.text('RESEND LINK'), findsNothing);
    expect(find.text('SIGN OUT'), findsOneWidget);
  });

  testWidgets('a Google account is never asked to confirm anything',
      (tester) async {
    await pump(
      tester,
      service: _FakeAccountService(),
      account: const EterAccount(
        id: 'uid',
        email: 'someone@gmail.com',
        emailVerified: true,
        provider: 'google',
      ),
    );

    expect(find.text('RESEND LINK'), findsNothing);
  });

  testWidgets('signing out says plainly that it is not deletion',
      (tester) async {
    await pump(
      tester,
      service: _FakeAccountService(),
      account: const EterAccount(
        id: 'uid',
        email: 'someone@example.com',
        emailVerified: true,
        provider: 'password',
      ),
    );

    await tester.tap(find.text('SIGN OUT'));
    await tester.pump();

    expect(find.textContaining('still here'), findsOneWidget);
  });

  testWidgets('a forgotten-password reply reveals nothing about the address',
      (tester) async {
    await pump(tester, service: _FakeAccountService());

    await tester.enterText(find.byType(TextField).first, 'someone@example.com');
    await tester.tap(find.text('FORGOTTEN PASSWORD'));
    await tester.pump();

    // "If that address has an account" — the same answer either way.
    expect(find.textContaining('If that address'), findsOneWidget);
  });

  testWidgets('a provider failure is shown in plain words', (tester) async {
    await pump(tester, service: _FakeAccountService(failWith: AccountFailure.network));

    await tester.enterText(find.byType(TextField).first, 'someone@example.com');
    await tester.enterText(find.byType(TextField).last, 'longenough');
    await tester.tap(find.text('SIGN IN'));
    await tester.pump();

    expect(find.textContaining('Eter works offline'), findsOneWidget);
  });

  /// Deletion. Both stores require this to exist in-app, and for a long while
  /// it did not: `deleteAccount()` was implemented and called from nowhere.
  group('deleting the account', () {
    const signedIn = EterAccount(
      id: 'uid',
      email: 'someone@example.com',
      emailVerified: true,
      provider: 'password',
    );

    testWidgets('is offered to anyone signed in', (tester) async {
      await pump(tester, service: _FakeAccountService(), account: signedIn);

      expect(find.text('DELETE ACCOUNT'), findsWidgets);
      expect(find.textContaining('Remove the account'), findsOneWidget);
    });

    testWidgets('is never offered to someone signed out', (tester) async {
      await pump(tester, service: _FakeAccountService());

      expect(find.text('DELETE ACCOUNT'), findsNothing);
    });

    testWidgets('reveals the consequence before it will act', (tester) async {
      final service = _FakeAccountService();
      await pump(tester, service: service, account: signedIn);

      await tester.tap(find.widgetWithText(EterAction, 'DELETE ACCOUNT'));
      await tester.pump();

      // The first tap only speaks. What it says is the part that matters: the
      // local record survives, so a person deleting an account is not also
      // silently deleting their journal.
      expect(service.deleteAttempts, 0);
      expect(find.textContaining('Everything on this device stays'),
          findsOneWidget);
      expect(find.text('DELETE NOW'), findsOneWidget);
    });

    testWidgets('acts on the second tap and says what survived',
        (tester) async {
      final service = _FakeAccountService();
      await pump(tester, service: service, account: signedIn);

      await tester.tap(find.widgetWithText(EterAction, 'DELETE ACCOUNT'));
      await tester.pump();
      await tester.tap(find.text('DELETE NOW'));
      await tester.pump();

      expect(service.deleteAttempts, 1);
      expect(find.textContaining('still on this device'), findsOneWidget);
    });

    testWidgets('a stale session is told to sign in again, not that it failed',
        (tester) async {
      final service =
          _FakeAccountService(failWith: AccountFailure.requiresRecentLogin);
      await pump(tester, service: service, account: signedIn);

      await tester.tap(find.widgetWithText(EterAction, 'DELETE ACCOUNT'));
      await tester.pump();
      await tester.tap(find.text('DELETE NOW'));
      await tester.pump();

      // The provider refuses to delete on an old session, which is the ordinary
      // outcome rather than an edge case. "Something went wrong" would leave a
      // person believing the account is gone when it is not.
      expect(find.textContaining('Sign in again'), findsOneWidget);
      expect(find.textContaining('Nothing was deleted'), findsOneWidget);
    });
  });
}

class _FakeAccountService implements AccountService {
  _FakeAccountService({this.failWith});

  final AccountFailure? failWith;
  int signInAttempts = 0;
  int registerAttempts = 0;
  int deleteAttempts = 0;

  @override
  EterAccount? current;

  @override
  Stream<EterAccount?> changes() => const Stream.empty();

  void _maybeFail() {
    if (failWith != null) throw AccountException(failWith!);
  }

  @override
  Future<EterAccount> registerWithEmail({
    required String email,
    required String password,
  }) async {
    AccountRules.check(email: email, password: password);
    registerAttempts += 1;
    _maybeFail();
    return EterAccount(
      id: 'uid',
      email: email,
      emailVerified: false,
      provider: 'password',
    );
  }

  @override
  Future<EterAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AccountRules.check(email: email);
    signInAttempts += 1;
    _maybeFail();
    return EterAccount(
      id: 'uid',
      email: email,
      emailVerified: true,
      provider: 'password',
    );
  }

  @override
  Future<EterAccount> signInWithGoogle() async {
    _maybeFail();
    return const EterAccount(
      id: 'uid',
      email: 'someone@gmail.com',
      emailVerified: true,
      provider: 'google',
    );
  }

  @override
  Future<void> resendVerification() async => _maybeFail();

  @override
  Future<EterAccount?> refresh() async => current;

  @override
  Future<void> sendPasswordReset(String email) async {
    AccountRules.check(email: email);
    _maybeFail();
  }

  @override
  Future<void> signOut() async => _maybeFail();

  @override
  Future<void> deleteAccount() async {
    _maybeFail();
    deleteAttempts += 1;
  }
}
