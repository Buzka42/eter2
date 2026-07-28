import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/health/health_hub.dart';
import '../../core/health/platform_health_gateway.dart';
import '../../core/privacy/local_data_export.dart';
import '../../core/register.dart';
import '../../core/tokens.dart';
import '../../main.dart';

/// The Sanctum is the shell's quiet settings layer, not another destination
/// page. It is deliberately plain in both registers and leaves the Journal and
/// Dashboard mounted beneath it.
class SanctumOverlay extends ConsumerWidget {
  const SanctumOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final night = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);

    return SurfaceIntentScope(
      intent: SurfaceIntent.plain,
      child: ColoredBox(
        color: night ? EterColors.night900 : EterColors.mist50,
        child: SafeArea(
          child: StreamBuilder<ProfileRow?>(
            stream: db.watchProfile(),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: EterSpace.gutter,
                  vertical: EterSpace.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SanctumHeader(
                      onClose: onClose,
                      style: text.labelLarge?.copyWith(letterSpacing: 2.4),
                    ),
                    const SizedBox(height: EterSpace.s48),
                    Text(
                      'How Eter meets you',
                      style: text.displaySmall?.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: EterSpace.s8),
                    Text(
                      profile?.cloudSyncConsentAt == null
                          ? 'Your history stays on this device. Cloud sync is '
                              'off.'
                          : 'Cloud continuity is allowed. You can revoke it '
                              'below.',
                      style: text.bodyMedium?.copyWith(color: ink.labelMuted),
                    ),
                    const SizedBox(height: EterSpace.s32),
                    _ChoiceGroup(
                      heading: 'OPENING PAGE',
                      value: profile?.startSurface ?? 'dashboard',
                      choices: const {
                        'journal': 'Journal',
                        'dashboard': 'Dashboard',
                      },
                      onChanged: (value) => db.updateProfilePreferences(
                        startSurface: value,
                      ),
                    ),
                    const SizedBox(height: EterSpace.s32),
                    _ChoiceGroup(
                      heading: 'GUIDANCE REGISTER',
                      value: profile?.guidanceMode ?? 'balanced',
                      choices: const {
                        'grounded': 'Grounded',
                        'balanced': 'Balanced',
                        'immersive': 'Immersive',
                      },
                      descriptions: const {
                        'grounded': 'Daylight clarity at every hour.',
                        'balanced': 'Changes with sunrise and sunset.',
                        'immersive': 'The deeper night register.',
                      },
                      onChanged: (value) => db.updateProfilePreferences(
                        guidanceMode: value,
                      ),
                    ),
                    const SizedBox(height: EterSpace.s32),
                    Container(height: 1, color: ink.line),
                    const SizedBox(height: EterSpace.s24),
                    Text('YOUR DATA', style: text.labelSmall),
                    const SizedBox(height: EterSpace.s12),
                    Text(
                      'Each permission is independent and can be revoked. '
                      'Revoking AI also turns off journal-aware guidance.',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: EterSpace.s16),
                    _ChoiceGroup(
                      heading: 'AI GUIDANCE',
                      value: profile?.aiConsentAt == null ? 'off' : 'allowed',
                      choices: const {
                        'off': 'Off',
                        'allowed': 'Allowed',
                      },
                      descriptions: const {
                        'off': 'No health context leaves this device for AI.',
                        'allowed':
                            'Selected context may be sent to compose guidance.',
                      },
                      onChanged: profile == null
                          ? null
                          : (value) => db.updateProfileConsents(
                                aiAllowed: value == 'allowed',
                              ),
                    ),
                    const SizedBox(height: EterSpace.s24),
                    _ChoiceGroup(
                      heading: 'JOURNAL-AWARE GUIDANCE',
                      value: profile?.journalAiConsentAt == null
                          ? 'off'
                          : 'allowed',
                      choices: const {
                        'off': 'Off',
                        'allowed': 'Allowed',
                      },
                      descriptions: const {
                        'off': 'Journal prose is never sent.',
                        'allowed': 'Only entries not marked Keep local may be '
                            'included.',
                      },
                      onChanged: profile == null
                          ? null
                          : (value) => db.updateProfileConsents(
                                journalAiAllowed: value == 'allowed',
                              ),
                    ),
                    const SizedBox(height: EterSpace.s24),
                    _ChoiceGroup(
                      heading: 'CLOUD CONTINUITY',
                      value: profile?.cloudSyncConsentAt == null
                          ? 'off'
                          : 'allowed',
                      choices: const {
                        'off': 'Local only',
                        'allowed': 'Allowed',
                      },
                      descriptions: const {
                        'off': 'No account copy is created.',
                        'allowed': 'Eligible documents may mirror to your '
                            'account when sync is connected.',
                      },
                      onChanged: profile == null
                          ? null
                          : (value) => db.updateProfileConsents(
                                cloudSyncAllowed: value == 'allowed',
                              ),
                    ),
                    const SizedBox(height: EterSpace.s32),
                    _HealthConnection(database: db),
                    const SizedBox(height: EterSpace.s32),
                    _LocalExport(database: db),
                    const SizedBox(height: EterSpace.s64),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HealthConnection extends StatefulWidget {
  const _HealthConnection({required this.database});

  final AppDatabase database;

  @override
  State<_HealthConnection> createState() => _HealthConnectionState();
}

class _HealthConnectionState extends State<_HealthConnection> {
  late final Stream<List<IntegrationRow>> _integrations =
      widget.database.watchIntegrations();
  bool _busy = false;
  String? _message;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final now = DateTime.now();
      final result = await HealthHubSyncService(
        database: widget.database,
        gateway: PlatformHealthGateway(),
      ).sync(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );
      if (!mounted) return;
      setState(() {
        _message = result.authorized
            ? '${result.records} health records read. Eter kept one source per minute.'
            : 'Access was not granted. No health values were imported.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _message =
              'Health data could not be read. Existing history is unchanged.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = Platform.isAndroid || Platform.isIOS;
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<IntegrationRow>>(
      stream: _integrations,
      builder: (context, snapshot) {
        final connected = snapshot.data?.any(
              (row) =>
                  (row.vendor == 'healthConnect' ||
                      row.vendor == 'appleHealth') &&
                  row.status == 'connected',
            ) ??
            false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HEALTH HISTORY', style: text.labelSmall),
            const SizedBox(height: EterSpace.s8),
            Text(
              connected
                  ? 'Connected. Reconnect to read the latest 30 days; source overlap is resolved per minute.'
                  : supported
                      ? 'Read selected movement, sleep, and recovery signals from your phone’s health store.'
                      : 'Health connection is available on iPhone and Android.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: EterSpace.s8),
            EterAction(
              label: connected ? 'Refresh' : 'Connect',
              busy: _busy,
              onPressed: supported && !_busy ? _connect : null,
            ),
            if (_message != null)
              Semantics(
                liveRegion: true,
                child: Text(_message!, style: text.bodySmall),
              ),
          ],
        );
      },
    );
  }
}

class _LocalExport extends StatefulWidget {
  const _LocalExport({required this.database});

  final AppDatabase database;

  @override
  State<_LocalExport> createState() => _LocalExportState();
}

class _LocalExportState extends State<_LocalExport> {
  bool _busy = false;
  String? _message;
  String? _path;

  Future<void> _prepare() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bundle = await LocalDataExporter(widget.database).export();
      if (!mounted) return;
      setState(() {
        _path = bundle.directory.path;
        _message = 'Local JSON and CSV files are ready on this device. '
            'Cloud account data is not included.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'The local export could not be prepared right now.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyPath() async {
    final path = _path;
    if (path == null) return;
    await Clipboard.setData(ClipboardData(text: path));
    if (mounted) {
      setState(() => _message = 'Export folder location copied.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LOCAL EXPORT', style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(
          'Prepare a complete JSON snapshot and spreadsheet-friendly movement '
          'and session files. Nothing is uploaded.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: EterSpace.s8),
        EterAction(
          label: 'Export',
          busy: _busy,
          onPressed: _busy ? null : _prepare,
        ),
        if (_path != null)
          EterAction(
            label: 'Copy path',
            emphasis: EterActionEmphasis.quiet,
            onPressed: _copyPath,
          ),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
      ],
    );
  }
}

class _SanctumHeader extends StatelessWidget {
  const _SanctumHeader({required this.onClose, required this.style});

  final VoidCallback onClose;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final close = EterAction(
      label: 'Close',
      emphasis: EterActionEmphasis.quiet,
      onPressed: onClose,
    );
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('SANCTUM', maxLines: 1, style: style),
              ),
            ),
          ),
          Align(alignment: Alignment.centerRight, child: close),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: Text('SANCTUM', maxLines: 1, style: style)),
        close,
      ],
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.heading,
    required this.value,
    required this.choices,
    required this.onChanged,
    this.descriptions = const {},
  });

  final String heading;
  final String value;
  final Map<String, String> choices;
  final Map<String, String> descriptions;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        for (final choice in choices.entries)
          Semantics(
            button: true,
            selected: choice.key == value,
            label: choice.value,
            child: GestureDetector(
              key: ValueKey('$heading-${choice.key}'),
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null ? null : () => onChanged!(choice.key),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: EterSpace.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              choice.value,
                              style: text.titleMedium?.copyWith(
                                color: choice.key == value
                                    ? ink.label
                                    : ink.labelMuted,
                                fontWeight: choice.key == value
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            if (descriptions[choice.key] case final note?) ...[
                              const SizedBox(height: EterSpace.s4),
                              Text(
                                note,
                                style: text.bodySmall?.copyWith(
                                  color: ink.labelMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: EterSpace.s16),
                      AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : EterMotion.durStandard,
                        width: choice.key == value ? 32 : 12,
                        height: 1,
                        margin: const EdgeInsets.only(top: 13),
                        color: choice.key == value ? ink.lineStrong : ink.line,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
