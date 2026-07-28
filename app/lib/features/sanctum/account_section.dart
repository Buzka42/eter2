import 'package:flutter/material.dart';

import '../../core/account/account.dart';
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
  });

  /// Null when this build has no account system at all, which is a supported
  /// configuration and not an error worth explaining at length.
  final AccountService? service;
  final EterAccount? account;

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
      setState(() => _message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Something went wrong. Nothing was changed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() {
    final service = widget.service!;
    final email = _email.text;
    final password = _password.text;
    return _run(() async {
      if (_mode == _Mode.register) {
        final account = await service.registerWithEmail(
          email: email,
          password: password,
        );
        _password.clear();
        return 'Check ${account.email} for a confirmation link. '
            'Your history stays here until you follow it.';
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
    final service = widget.service;
    final account = widget.account;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACCOUNT', style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        if (service == null)
          Text(
            'This build has no account system. Everything works; nothing is '
            'backed up.',
            style: text.bodyMedium?.copyWith(color: ink.labelMuted),
          )
        else if (account == null)
          ..._signedOut(text, ink, service)
        else
          ..._signedIn(text, ink, service, account),
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
    AccountService service,
  ) {
    final registering = _mode == _Mode.register;
    return [
      Text(
        'Your history is on this device and needs no account. Sign in only if '
        'you want it back when you change phone.',
        style: text.bodyMedium,
      ),
      const SizedBox(height: EterSpace.s16),
      _field(
        controller: _email,
        label: 'Email',
        ink: ink,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: EterSpace.s12),
      _field(
        controller: _password,
        label: registering ? 'New password' : 'Password',
        ink: ink,
        obscure: true,
      ),
      if (registering) ...[
        const SizedBox(height: EterSpace.s4),
        Text(
          'At least ${AccountRules.minimumPasswordLength} characters. '
          'A phrase you will remember beats a short tangle you will not.',
          style: text.bodySmall?.copyWith(color: ink.labelMuted),
        ),
      ],
      const SizedBox(height: EterSpace.s16),
      Row(
        children: [
          EterAction(
            label: registering ? 'Create account' : 'Sign in',
            busy: _busy,
            onPressed: _busy ? null : _submit,
          ),
          const SizedBox(width: EterSpace.s12),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _mode = registering ? _Mode.signIn : _Mode.register;
                      _message = null;
                    }),
            child: Text(
              registering ? 'I have an account' : 'Create one',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: EterSpace.s12),
      EterAction(
        label: 'Continue with Google',
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
        TextButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await service.sendPasswordReset(_email.text);
                    // Deliberately says nothing about whether the address is
                    // registered — the same sentence either way.
                    return 'If that address has an account, a reset link is '
                        'on its way.';
                  }),
          child: Text('Forgotten password', style: text.bodySmall),
        ),
      ],
    ];
  }

  List<Widget> _signedIn(
    TextTheme text,
    EterInk ink,
    AccountService service,
    EterAccount account,
  ) =>
      [
        Text(
          account.email ?? 'Signed in',
          style: text.bodyMedium,
        ),
        const SizedBox(height: EterSpace.s4),
        Text(
          account.canSync
              ? 'Your history can be restored on a new phone.'
              : 'Confirm your email to enable that. Until you do, nothing '
                  'leaves this device.',
          style: text.bodySmall?.copyWith(color: ink.labelMuted),
        ),
        const SizedBox(height: EterSpace.s16),
        if (!account.canSync) ...[
          Row(
            children: [
              EterAction(
                label: 'Resend link',
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          await service.resendVerification();
                          return 'Sent. It can take a minute to arrive.';
                        }),
              ),
              const SizedBox(width: EterSpace.s12),
              EterAction(
                label: 'I have confirmed',
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          final refreshed = await service.refresh();
                          return refreshed?.canSync ?? false
                              ? null
                              : 'Not confirmed yet. Follow the link in the '
                                  'email, then try again.';
                        }),
              ),
            ],
          ),
          const SizedBox(height: EterSpace.s12),
        ],
        EterAction(
          label: 'Sign out',
          busy: _busy,
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await service.signOut();
                    // Worth saying plainly: signing out is not deletion, and
                    // people reasonably fear it might be.
                    return 'Signed out. Everything on this device is still '
                        'here.';
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
