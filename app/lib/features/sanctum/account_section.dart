import 'package:flutter/material.dart';

import '../../core/account/account.dart';
import '../../core/i18n/strings.dart';
import '../../core/sync/cloud_mirror.dart';
import '../../core/sync/sync_service.dart';
import '../../core/controls.dart';
import '../../core/tokens.dart';

/// Signing in, and what it is honestly for.
///
/// This section says the same thing whether or not anyone is signed in: your
/// history is on this device and it works. An account is offered as recovery,
/// not as a requirement and not as a feature — the copy deliberately does not
/// sell it, because a person who signs in expecting more than a backup has
/// been misled.
class AccountSection extends StatefulWidget {
  const AccountSection({
    super.key,
    required this.service,
    required this.account,
    this.sync,
  });

  /// Null when this build has no account system at all, which is a supported
  /// configuration and not an error worth explaining at length.
  final AccountService? service;
  final EterAccount? account;

  /// Null when this build has no mirror to push to.
  final SyncService? sync;

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

enum _Mode { signIn, register }

class _AccountSectionState extends State<AccountSection> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  _Mode _mode = _Mode.signIn;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Every action funnels through here so that a failure can never leave the
  /// section spinning, and so the message a person sees is always the
  /// interface's own sentence rather than a provider code.
  Future<void> _run(Future<String?> Function() action) async {
    final strings = EterStrings.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final said = await action();
      if (!mounted) return;
      setState(() => _message = said);
    } on AccountException catch (error) {
      if (!mounted) return;
      setState(() => _message = strings.accountFailure(error.failure));
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = strings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() {
    final service = widget.service!;
    final strings = EterStrings.of(context);
    final email = _email.text;
    final password = _password.text;
    return _run(() async {
      if (_mode == _Mode.register) {
        final account = await service.registerWithEmail(
          email: email,
          password: password,
        );
        _password.clear();
        return strings.confirmationLinkSent(account.email ?? email);
      }
      await service.signInWithEmail(email: email, password: password);
      _password.clear();
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    final service = widget.service;
    final account = widget.account;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.headingAccount, style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        if (service == null)
          Text(
            strings.buildHasNoAccountSystem,
            style: text.bodyMedium?.copyWith(color: ink.labelMuted),
          )
        else if (account == null)
          ..._signedOut(text, ink, strings, service)
        else
          ..._signedIn(text, ink, strings, service, account),
        if (_message != null) ...[
          const SizedBox(height: EterSpace.s8),
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
        ],
      ],
    );
  }

  List<Widget> _signedOut(
    TextTheme text,
    EterInk ink,
    EterStrings strings,
    AccountService service,
  ) {
    final registering = _mode == _Mode.register;
    return [
      Text(strings.historyNeedsNoAccount, style: text.bodyMedium),
      const SizedBox(height: EterSpace.s16),
      _field(
        controller: _email,
        label: strings.fieldEmail,
        ink: ink,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: EterSpace.s12),
      _field(
        controller: _password,
        label: registering ? strings.fieldNewPassword : strings.fieldPassword,
        ink: ink,
        obscure: true,
      ),
      if (registering) ...[
        const SizedBox(height: EterSpace.s4),
        Text(
          strings.passwordMinimum(AccountRules.minimumPasswordLength),
          style: text.bodySmall?.copyWith(color: ink.labelMuted),
        ),
      ],
      const SizedBox(height: EterSpace.s16),
      Row(
        children: [
          EterAction(
            label: registering ? strings.createAccount : strings.signIn,
            busy: _busy,
            onPressed: _busy ? null : _submit,
          ),
          const SizedBox(width: EterSpace.s12),
          EterAction(
            label: registering ? strings.iHaveAnAccount : strings.createOne,
            emphasis: EterActionEmphasis.quiet,
            onPressed: _busy
                ? null
                : () => setState(() {
                      _mode = registering ? _Mode.signIn : _Mode.register;
                      _message = null;
                    }),
          ),
        ],
      ),
      const SizedBox(height: EterSpace.s12),
      EterAction(
        label: strings.continueWithGoogle,
        busy: _busy,
        onPressed: _busy
            ? null
            : () => _run(() async {
                  await service.signInWithGoogle();
                  return null;
                }),
      ),
      if (!registering) ...[
        const SizedBox(height: EterSpace.s8),
        EterAction(
          label: strings.forgottenPassword,
          emphasis: EterActionEmphasis.quiet,
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await service.sendPasswordReset(_email.text);
                    // Deliberately says nothing about whether the address is
                    // registered — the same sentence either way.
                    return strings.resetLinkOnItsWay;
                  }),
        ),
      ],
    ];
  }

  /// Sends whatever has not been sent, and says exactly what happened —
  /// including what deliberately stayed behind.
  /// Whatever stopped the attempt, said in the reader's language.
  ///
  /// A refusal is Eter's own precondition and has a translated sentence; a
  /// `failure` is whatever the mirror reported and is passed through untranslated
  /// — inventing Polish for an arbitrary backend error would be inventing a
  /// diagnosis. Null when nothing stopped it.
  String? _stopped(SyncOutcome outcome, EterStrings strings) =>
      outcome.refusal != null
          ? strings.syncRefusal(outcome.refusal!)
          : outcome.failure;

  Future<void> _sync(EterAccount account) {
    final strings = EterStrings.of(context);
    return _run(() async {
      final sync = widget.sync;
      if (sync == null) return strings.syncNotAvailableOnBuild;
      final outcome = await sync.push(account);
      if (_stopped(outcome, strings) case final stopped?) return stopped;
      final held = outcome.skipped['journalEntries'];
      final sent = outcome.uploaded == 0
          ? strings.everythingAlreadyCopied
          : strings.copiedRecords(outcome.uploaded);
      return held == null
          ? sent
          : '$sent ${strings.journalStayedOnThisDevice}';
    });
  }

  Future<void> _restore(EterAccount account) {
    final strings = EterStrings.of(context);
    return _run(() async {
      final sync = widget.sync;
      if (sync == null) return strings.syncNotAvailableOnBuild;
      final outcome = await sync.restore(account);
      if (_stopped(outcome, strings) case final stopped?) return stopped;
      return outcome.restored == 0
          ? strings.nothingInAccountToRestore
          : strings.restoredRecords(outcome.restored);
    });
  }

  List<Widget> _signedIn(
    TextTheme text,
    EterInk ink,
    EterStrings strings,
    AccountService service,
    EterAccount account,
  ) =>
      [
        Text(
          account.email ?? strings.signedIn,
          style: text.bodyMedium,
        ),
        const SizedBox(height: EterSpace.s4),
        Text(
          account.canSync
              ? strings.historyCanBeRestored
              : strings.confirmEmailToEnable,
          style: text.bodySmall?.copyWith(color: ink.labelMuted),
        ),
        const SizedBox(height: EterSpace.s16),
        if (!account.canSync) ...[
          Row(
            children: [
              EterAction(
                label: strings.resendLink,
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await service.resendVerification();
                          return strings.verificationSent;
                        }),
              ),
              const SizedBox(width: EterSpace.s12),
              EterAction(
                label: strings.iHaveConfirmed,
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          final refreshed = await service.refresh();
                          return refreshed?.canSync ?? false
                              ? null
                              : strings.notConfirmedYet;
                        }),
              ),
            ],
          ),
          const SizedBox(height: EterSpace.s12),
        ],
        if (account.canSync && widget.sync != null) ...[
          Row(
            children: [
              EterAction(
                label: strings.syncNow,
                busy: _busy,
                onPressed: _busy ? null : () => _sync(account),
              ),
              const SizedBox(width: EterSpace.s12),
              EterAction(
                label: strings.restore,
                busy: _busy,
                onPressed: _busy ? null : () => _restore(account),
              ),
            ],
          ),
          const SizedBox(height: EterSpace.s4),
          Text(
            strings.restoreOnlyFillsEmptyDevice,
            style: text.bodySmall?.copyWith(color: ink.labelMuted),
          ),
          const SizedBox(height: EterSpace.s12),
        ],
        EterAction(
          label: strings.signOut,
          busy: _busy,
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await service.signOut();
                    // Worth saying plainly: signing out is not deletion, and
                    // people reasonably fear it might be.
                    return strings.signedOutNothingRemoved;
                  }),
        ),
      ];

  Widget _field({
    required TextEditingController controller,
    required String label,
    required EterInk ink,
    bool obscure = false,
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: !obscure,
        decoration: InputDecoration(
          labelText: label,
          filled: false,
          border: UnderlineInputBorder(borderSide: BorderSide(color: ink.line)),
          enabledBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: ink.line)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: ink.lineStrong),
          ),
        ),
      );
}
