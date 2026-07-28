import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/health/health_hub.dart';
import '../../core/health/platform_health_gateway.dart';
import '../../core/privacy/local_data_export.dart';
import '../../core/patterns/local_pattern_discovery.dart';
import '../../core/profile/birth_context.dart';
import '../../core/register.dart';
import '../../core/retrospectives/local_weekly_retrospective.dart';
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
                    _BirthContext(
                      database: db,
                      profile: profile,
                      resolver: ref.watch(birthplaceResolverProvider),
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
                    _PersonalizationControls(database: db),
                    const SizedBox(height: EterSpace.s32),
                    _LocalExport(database: db),
                    const SizedBox(height: EterSpace.s32),
                    _LocalDeletion(
                      database: db,
                      onDeleted: onClose,
                    ),
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

class _BirthContext extends StatefulWidget {
  const _BirthContext({
    required this.database,
    required this.profile,
    required this.resolver,
  });

  final AppDatabase database;
  final ProfileRow? profile;
  final BirthplaceResolver resolver;

  @override
  State<_BirthContext> createState() => _BirthContextState();
}

class _BirthContextState extends State<_BirthContext> {
  final _time = TextEditingController();
  final _offset = TextEditingController();
  final _place = TextEditingController();
  bool _editing = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _syncFields();
  }

  @override
  void didUpdateWidget(_BirthContext oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.profile != widget.profile) _syncFields();
  }

  @override
  void dispose() {
    _time.dispose();
    _offset.dispose();
    _place.dispose();
    super.dispose();
  }

  void _syncFields() {
    final profile = widget.profile;
    final minutes = profile?.birthTimeMinutes;
    _time.text = minutes == null
        ? ''
        : '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
            '${(minutes % 60).toString().padLeft(2, '0')}';
    final offset = profile?.birthUtcOffsetMinutes;
    if (offset == null) {
      _offset.text = '';
    } else {
      final sign = offset < 0 ? '-' : '+';
      final absolute = offset.abs();
      _offset.text = '$sign${(absolute ~/ 60).toString().padLeft(2, '0')}:'
          '${(absolute % 60).toString().padLeft(2, '0')}';
    }
    _place.text = profile?.birthPlace ?? '';
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = 'Locating this birth context…';
    });
    try {
      await BirthContextService(
        database: widget.database,
        resolver: widget.resolver,
      ).save(
        time: _time.text,
        utcOffset: _offset.text,
        place: _place.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _editing = false;
        _message = 'Birth context saved on this device.';
      });
    } on BirthContextException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final profile = widget.profile;
    final exact = profile?.birthTimeMinutes != null &&
        profile?.birthUtcOffsetMinutes != null &&
        profile?.birthLatitude != null &&
        profile?.birthLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BIRTH CONTEXT', style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(
          exact
              ? '${profile!.birthPlace ?? 'Located place'} · '
                  '${_formatTime(profile.birthTimeMinutes!)} · '
                  'UTC${_formatOffset(profile.birthUtcOffsetMinutes!)}'
              : 'Provisional. Add exact local time, its UTC offset, and a '
                  'place to improve chart reliability.',
          style: text.bodyMedium?.copyWith(
            color: exact ? null : ink.labelMuted,
          ),
        ),
        if (_editing) ...[
          const SizedBox(height: EterSpace.s12),
          TextField(
            key: const ValueKey('birth-context-time'),
            controller: _time,
            enabled: !_busy,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Local birth time · HH:MM',
            ),
          ),
          const SizedBox(height: EterSpace.s12),
          TextField(
            key: const ValueKey('birth-context-offset'),
            controller: _offset,
            enabled: !_busy,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'UTC offset at birth · for example +01:00',
            ),
          ),
          const SizedBox(height: EterSpace.s12),
          TextField(
            key: const ValueKey('birth-context-place'),
            controller: _place,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Birth city and country',
            ),
          ),
          const SizedBox(height: EterSpace.s8),
          Text(
            'Place lookup uses the device geocoder. The label and coordinates '
            'are stored locally.',
            style: text.bodySmall?.copyWith(color: ink.labelMuted),
          ),
        ],
        const SizedBox(height: EterSpace.s8),
        Wrap(
          spacing: EterSpace.s8,
          children: [
            EterAction(
              key: const ValueKey('birth-context-primary-action'),
              label: _editing ? 'Save' : 'Edit',
              emphasis: EterActionEmphasis.quiet,
              busy: _busy,
              onPressed: widget.profile == null || _busy
                  ? null
                  : (_editing ? _save : () => setState(() => _editing = true)),
            ),
            if (_editing)
              EterAction(
                label: 'Cancel',
                emphasis: EterActionEmphasis.quiet,
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _editing = false;
                          _message = null;
                          _syncFields();
                        }),
              ),
          ],
        ),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
      ],
    );
  }

  static String _formatTime(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  static String _formatOffset(int minutes) {
    final sign = minutes < 0 ? '−' : '+';
    final absolute = minutes.abs();
    return '$sign${(absolute ~/ 60).toString().padLeft(2, '0')}:'
        '${(absolute % 60).toString().padLeft(2, '0')}';
  }
}

class _PersonalizationControls extends StatefulWidget {
  const _PersonalizationControls({required this.database});

  final AppDatabase database;

  @override
  State<_PersonalizationControls> createState() =>
      _PersonalizationControlsState();
}

class _PersonalizationControlsState extends State<_PersonalizationControls> {
  late Future<List<PatternCandidateRow>> _patterns =
      widget.database.loadActivePatterns();
  late Future<List<RetrospectiveRow>> _retrospectives =
      widget.database.loadRetrospectives(limit: 1);
  bool _confirmReset = false;
  bool _busy = false;
  String? _message;

  Future<void> _review() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = 'Reviewing recent local signals…';
    });
    final result = await LocalPatternDiscovery(widget.database).review(
      now: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _patterns = widget.database.loadActivePatterns();
      _message = result.activePatterns == 0
          ? 'Not enough consistent local evidence yet.'
          : '${result.activePatterns} local pattern refreshed from '
              '${result.observations} observations.';
    });
  }

  Future<void> _prepareWeek() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = 'Preparing a factual seven-day view…';
    });
    final result = await LocalWeeklyRetrospective(widget.database).prepare(
      now: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _retrospectives = widget.database.loadRetrospectives(limit: 1);
      _message = result == null
          ? 'There is not enough local history for a weekly view yet.'
          : 'Seven-day view prepared on this device.';
    });
  }

  Future<void> _dismiss(String key) async {
    await widget.database.dismissPattern(key);
    if (mounted) {
      setState(() {
        _patterns = widget.database.loadActivePatterns();
        _message = 'Pattern dismissed. Aether will not use it.';
      });
    }
  }

  Future<void> _reset() async {
    if (!_confirmReset) {
      setState(() {
        _confirmReset = true;
        _message = 'This removes composed guidance, learned patterns, and '
            'retrospectives. Your journal and health history stay.';
      });
      return;
    }
    setState(() => _busy = true);
    final result = await widget.database.resetPersonalization();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _confirmReset = false;
      _patterns = widget.database.loadActivePatterns();
      _retrospectives = widget.database.loadRetrospectives(limit: 1);
      _message = result.total == 0
          ? 'Aether memory was already empty.'
          : 'Aether memory cleared from this device.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AETHER MEMORY', style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(
          'Only structured patterns are retained. Local correlations are not '
          'treated as causes.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: EterSpace.s16),
        Text('WEEK IN VIEW', style: text.labelSmall),
        FutureBuilder<List<RetrospectiveRow>>(
          future: _retrospectives,
          builder: (context, snapshot) {
            final rows = snapshot.data;
            if (rows == null) return const SizedBox.shrink();
            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: EterSpace.s8),
                child: Text(
                  'No weekly view has been prepared.',
                  style: text.bodySmall?.copyWith(color: ink.labelMuted),
                ),
              );
            }
            final review = _RetrospectiveView.tryParse(rows.first);
            if (review == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: EterSpace.s8),
              child: Semantics(
                container: true,
                label: review.semanticLabel,
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.headline, style: text.titleMedium),
                      const SizedBox(height: EterSpace.s4),
                      for (final passage in review.passages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: EterSpace.s4),
                          child: Text(passage, style: text.bodySmall),
                        ),
                      Text(
                        review.caveat,
                        style: text.bodySmall?.copyWith(color: ink.labelMuted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        EterAction(
          label: 'Prepare',
          emphasis: EterActionEmphasis.quiet,
          busy: _busy,
          onPressed: _busy ? null : _prepareWeek,
        ),
        const SizedBox(height: EterSpace.s16),
        Text('LOCAL PATTERNS', style: text.labelSmall),
        FutureBuilder<List<PatternCandidateRow>>(
          future: _patterns,
          builder: (context, snapshot) {
            final patterns = snapshot.data;
            if (patterns == null) return const SizedBox.shrink();
            if (patterns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: EterSpace.s8),
                child: Text(
                  'No active patterns.',
                  style: text.bodySmall?.copyWith(color: ink.labelMuted),
                ),
              );
            }
            return Column(
              children: [
                for (final pattern in patterns)
                  Padding(
                    padding: const EdgeInsets.only(top: EterSpace.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          container: true,
                          label: _patternSemantics(pattern),
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pattern.summary, style: text.titleMedium),
                                const SizedBox(height: EterSpace.s4),
                                Text(
                                  _patternReceipt(pattern),
                                  style: text.bodySmall?.copyWith(
                                    color: ink.labelMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        EterAction(
                          label: 'Dismiss',
                          emphasis: EterActionEmphasis.quiet,
                          onPressed: () => _dismiss(pattern.key),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: EterSpace.s8),
        EterAction(
          label: 'Review',
          emphasis: EterActionEmphasis.quiet,
          busy: _busy,
          onPressed: _busy ? null : _review,
        ),
        EterAction(
          label: _confirmReset ? 'Clear now' : 'Reset',
          busy: _busy,
          onPressed: _busy ? null : _reset,
        ),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
      ],
    );
  }

  String _patternReceipt(PatternCandidateRow pattern) {
    final parts = <String>[
      '${(pattern.confidence * 100).round()}% confidence',
    ];
    try {
      final evidence = jsonDecode(pattern.evidenceJson);
      if (evidence is Map<String, dynamic>) {
        if (evidence['n'] case final num count) {
          parts.add('$count observations');
        }
        if (evidence['window'] case final String window) {
          parts.add(window);
        }
        if (evidence['coefficient'] case final num coefficient) {
          final sign = coefficient > 0 ? '+' : '';
          parts.add('$sign${coefficient.round()} min difference');
        }
      }
    } on FormatException {
      // The summary remains inspectable even if legacy evidence is malformed.
    }
    return '${parts.join(' · ')} · correlation, not cause';
  }

  String _patternSemantics(PatternCandidateRow pattern) =>
      '${pattern.summary}. ${_patternReceipt(pattern)}.';
}

class _RetrospectiveView {
  const _RetrospectiveView({
    required this.headline,
    required this.passages,
    required this.caveat,
    required this.window,
  });

  final String headline;
  final List<String> passages;
  final String caveat;
  final String window;

  String get semanticLabel =>
      '$headline. ${passages.join(' ')} $caveat Window $window.';

  static _RetrospectiveView? tryParse(RetrospectiveRow row) {
    try {
      final content = jsonDecode(row.contentJson);
      if (content is! Map<String, dynamic>) return null;
      final headline = content['headline'];
      final rawPassages = content['passages'];
      final caveat = content['caveat'];
      if (headline is! String || rawPassages is! List || caveat is! String) {
        return null;
      }
      final passages = rawPassages.whereType<String>().toList();
      if (passages.isEmpty) return null;
      return _RetrospectiveView(
        headline: headline,
        passages: passages,
        caveat: caveat,
        window: '${row.periodStart} to ${row.periodEnd}',
      );
    } on FormatException {
      return null;
    }
  }
}

class _LocalDeletion extends StatefulWidget {
  const _LocalDeletion({
    required this.database,
    required this.onDeleted,
  });

  final AppDatabase database;
  final VoidCallback onDeleted;

  @override
  State<_LocalDeletion> createState() => _LocalDeletionState();
}

class _LocalDeletionState extends State<_LocalDeletion> {
  bool _confirming = false;
  bool _busy = false;

  Future<void> _delete() async {
    if (!_confirming) {
      setState(() => _confirming = true);
      return;
    }
    setState(() => _busy = true);
    await widget.database.deleteAllLocalData();
    if (mounted) widget.onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DELETE FROM THIS DEVICE', style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(
          _confirming
              ? 'This permanently removes the local profile, journal, health '
                  'history, and derived readings. It does not claim to delete '
                  'a future cloud account copy.'
              : 'Remove every local Eter record and return to onboarding.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: EterSpace.s8),
        EterAction(
          label: _confirming ? 'Delete now' : 'Delete',
          busy: _busy,
          onPressed: _busy ? null : _delete,
        ),
      ],
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
