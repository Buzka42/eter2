import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/profile/birth_offset.dart';
import '../../core/profile/birth_time.dart';
import '../../core/diagnostics/crash_reporter.dart';
import '../../core/health/health_hub.dart';
import '../../core/health/platform_health_gateway.dart';
import '../../core/i18n/language.dart';
import '../../core/i18n/strings.dart';
import '../../core/privacy/local_data_export.dart';
import '../../core/patterns/local_pattern_discovery.dart';
import '../../core/profile/birth_context.dart';
import '../../core/register.dart';
import '../../core/retrospectives/local_weekly_retrospective.dart';
import '../../core/tokens.dart';
import '../../main.dart';
import 'account_section.dart';

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
    final strings = EterStrings.of(context);

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
                      strings.howEterMeetsYou,
                      style: text.displaySmall?.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: EterSpace.s8),
                    Text(
                      profile?.cloudSyncConsentAt == null
                          ? strings.historyStaysOnThisDevice
                          : strings.cloudContinuityAllowed,
                      style: text.bodyMedium?.copyWith(color: ink.labelMuted),
                    ),
                    const SizedBox(height: EterSpace.s32),
                    _ChoiceGroup(
                      id: 'opening-page',
                      heading: strings.headingOpeningPage,
                      value: profile?.startSurface ?? 'dashboard',
                      choices: {
                        'journal': strings.choiceJournal,
                        'dashboard': strings.choiceDashboard,
                      },
                      onChanged: (value) => db.updateProfilePreferences(
                        startSurface: value,
                      ),
                    ),
                    const SizedBox(height: EterSpace.s32),
                    // Above the register and the consents, because it governs
                    // both of their wording: reading them in a language you do
                    // not speak in order to find the language setting is the
                    // one ordering that cannot work.
                    _LanguageChoice(database: db, profile: profile),
                    const SizedBox(height: EterSpace.s32),
                    _ChoiceGroup(
                      id: 'guidance-register',
                      heading: strings.headingGuidanceRegister,
                      value: profile?.guidanceMode ?? 'balanced',
                      choices: {
                        'grounded': strings.registerGrounded,
                        'balanced': strings.registerBalanced,
                        'immersive': strings.registerImmersive,
                      },
                      descriptions: {
                        'grounded': strings.registerGroundedDetail,
                        'balanced': strings.registerBalancedDetail,
                        'immersive': strings.registerImmersiveDetail,
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
                    Text(strings.headingYourData, style: text.labelSmall),
                    const SizedBox(height: EterSpace.s12),
                    Text(
                      strings.permissionsAreIndependent,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: EterSpace.s16),
                    _ChoiceGroup(
                      id: 'ai-guidance',
                      heading: strings.headingAiGuidance,
                      value: profile?.aiConsentAt == null ? 'off' : 'allowed',
                      choices: {
                        'off': strings.off,
                        'allowed': strings.allowed,
                      },
                      descriptions: {
                        'off': strings.aiGuidanceOffDetail,
                        'allowed': strings.aiGuidanceAllowedDetail,
                      },
                      onChanged: profile == null
                          ? null
                          : (value) => db.updateProfileConsents(
                                aiAllowed: value == 'allowed',
                              ),
                    ),
                    const SizedBox(height: EterSpace.s24),
                    _ChoiceGroup(
                      id: 'journal-aware-guidance',
                      heading: strings.headingJournalAwareGuidance,
                      value: profile?.journalAiConsentAt == null
                          ? 'off'
                          : 'allowed',
                      choices: {
                        'off': strings.off,
                        'allowed': strings.allowed,
                      },
                      descriptions: {
                        'off': strings.journalAwareOffDetail,
                        'allowed': strings.journalAwareAllowedDetail,
                      },
                      onChanged: profile == null
                          ? null
                          : (value) => db.updateProfileConsents(
                                journalAiAllowed: value == 'allowed',
                              ),
                    ),
                    const SizedBox(height: EterSpace.s24),
                    _ChoiceGroup(
                      id: 'cloud-continuity',
                      heading: strings.headingCloudContinuity,
                      value: profile?.cloudSyncConsentAt == null
                          ? 'off'
                          : 'allowed',
                      choices: {
                        'off': strings.localOnly,
                        'allowed': strings.allowed,
                      },
                      descriptions: {
                        'off': strings.cloudOffDetail,
                        'allowed': strings.cloudAllowedDetail,
                      },
                      onChanged: profile == null
                          ? null
                          : (value) => db.updateProfileConsents(
                                cloudSyncAllowed: value == 'allowed',
                              ),
                    ),
                    const SizedBox(height: EterSpace.s24),
                    // Separate from the mirror above for the same reason
                    // journal-aware guidance is separate from AI guidance:
                    // agreeing to keep a copy of your weights is not agreeing
                    // to keep a copy of what you wrote at 2am.
                    _ChoiceGroup(
                      id: 'journal-in-the-mirror',
                      heading: strings.headingJournalInTheMirror,
                      value: profile?.journalCloudSyncConsentAt == null
                          ? 'off'
                          : 'allowed',
                      choices: {
                        'off': strings.staysHere,
                        'allowed': strings.allowed,
                      },
                      descriptions: {
                        'off': strings.journalMirrorOffDetail,
                        'allowed': strings.journalMirrorAllowedDetail,
                      },
                      onChanged: profile == null
                          ? null
                          : (value) => db.updateProfileConsents(
                                journalCloudSyncAllowed: value == 'allowed',
                              ),
                    ),
                    const SizedBox(height: EterSpace.s24),
                    _ChoiceGroup(
                      id: 'crash-reports',
                      heading: strings.headingCrashReports,
                      value: profile?.crashReportConsentAt == null
                          ? 'off'
                          : 'allowed',
                      choices: {
                        'off': strings.off,
                        'allowed': strings.allowed,
                      },
                      descriptions: {
                        'off': strings.crashReportsOffDetail,
                        'allowed': strings.crashReportsAllowedDetail,
                      },
                      onChanged: profile == null
                          ? null
                          : (value) async {
                              await db.updateProfileConsents(
                                crashReportsAllowed: value == 'allowed',
                              );
                              // Applied immediately rather than at next
                              // launch: revoking should stop collection now.
                              await CrashConsent(ref.read(crashReporterProvider))
                                  .apply(
                                consentedAt: value == 'allowed'
                                    ? DateTime.now().toUtc()
                                    : null,
                              );
                            },
                    ),
                    const SizedBox(height: EterSpace.s32),
                    AccountSection(
                      service: ref.watch(accountServiceProvider),
                      account: ref.watch(accountProvider).value,
                      sync: ref.watch(syncServiceProvider),
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
                      // A copy exists only when an account could actually hold
                      // one: signed in, confirmed, and cloud continuity on.
                      // Any of the three missing and the plain warning is the
                      // accurate one.
                      copyRemains:
                          (ref.watch(accountProvider).value?.canSync ??
                                  false) &&
                              profile?.cloudSyncConsentAt != null,
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

/// Choosing the language, and saying what choosing it costs.
///
/// The choice is not just a relabelling: composed passages are discarded, and a
/// person who has been reading Eter for a month should be told that before the
/// paragraph they were reading disappears. The note under the group says it up
/// front and the live message afterwards says what actually happened, in the
/// language they just switched *to* — which is also the first sentence of the new
/// language they will read, and so has to be worth reading.
class _LanguageChoice extends StatefulWidget {
  const _LanguageChoice({required this.database, required this.profile});

  final AppDatabase database;
  final ProfileRow? profile;

  @override
  State<_LanguageChoice> createState() => _LanguageChoiceState();
}

class _LanguageChoiceState extends State<_LanguageChoice> {
  int? _cleared;

  Future<void> _choose(String code) async {
    final cleared = await widget.database.chooseLanguage(code);
    // Only when something was actually discarded. Switching to the language
    // already in force clears nothing and should say nothing.
    if (mounted && cleared > 0) setState(() => _cleared = cleared);
  }

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    // An unchosen language shows whatever the phone resolved to, so the group
    // marks what the person is actually reading rather than nothing at all.
    final active = widget.profile?.language ?? strings.language.code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChoiceGroup(
          id: 'language',
          heading: strings.headingLanguage,
          value: active,
          // Each language names itself in itself — see `AppLanguage.endonym`.
          choices: {
            for (final language in AppLanguage.values)
              language.code: language.endonym,
          },
          onChanged: widget.profile == null ? null : _choose,
        ),
        Text(
          strings.languageDetail,
          style: text.bodySmall?.copyWith(color: ink.labelMuted),
        ),
        if (_cleared case final cleared?)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: EterSpace.s4),
              child: Text(
                strings.languageChanged(cleared),
                style: text.bodySmall,
              ),
            ),
          ),
      ],
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
  BirthTimePrecision _precision = BirthTimePrecision.unknown;
  BirthTimePeriod? _period;
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
    _precision = BirthTimePrecision.fromName(profile?.birthTimePrecision);
    _period = BirthTimePeriod.forMinutes(profile?.birthTimeMinutes);
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

  /// Fills the offset field with the one that was in force on the birth date,
  /// if the person has not written one themselves.
  ///
  /// A suggestion, and labelled as one: see `core/profile/birth_offset.dart`
  /// for why the zone is the device's rather than the birthplace's.
  void _suggestOffset() {
    if (_offset.text.trim().isNotEmpty) return;
    final dob = widget.profile?.dob;
    if (dob == null) return;
    final minutes = BirthOffset.suggestMinutes(dob);
    if (minutes == null || !mounted || _offset.text.trim().isNotEmpty) return;
    setState(() {
      _offset.text = BirthOffset.format(minutes);
      _message = EterStrings.of(context).offsetSuggestedFromPhone;
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    final strings = EterStrings.of(context);
    setState(() {
      _busy = true;
      _message = strings.locatingBirthContext;
    });
    try {
      await BirthContextService(
        database: widget.database,
        resolver: widget.resolver,
      ).save(
        time: _time.text,
        utcOffset: _offset.text,
        place: _place.text,
        precision: _precision,
        period: _period,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _editing = false;
        _message = strings.birthContextSaved;
      });
    } on BirthContextException catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = strings.birthContextError(failure.error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    final profile = widget.profile;
    final exact = profile?.birthTimeMinutes != null &&
        profile?.birthUtcOffsetMinutes != null &&
        profile?.birthLatitude != null &&
        profile?.birthLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.headingBirthContext, style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(
          exact
              ? strings.birthContextSummary(
                  place: profile!.birthPlace ?? strings.locatedPlace,
                  time: _formatTime(profile.birthTimeMinutes!),
                  utcOffset: _formatOffset(profile.birthUtcOffsetMinutes!),
                )
              : strings.birthContextProvisional,
          style: text.bodyMedium?.copyWith(
            color: exact ? null : ink.labelMuted,
          ),
        ),
        if (_editing) ...[
          const SizedBox(height: EterSpace.s12),
          // Almost nobody knows the minute, and almost everybody knows the
          // part of the day. Offering only "exact or nothing" turned real
          // knowledge into either a false certainty or a shrug.
          _ChoiceGroup(
            id: 'time-precision',
            heading: strings.headingHowWellIsTimeKnown,
            value: _precision.name,
            choices: {
              'exact': strings.precisionExact,
              'approximate': strings.precisionApproximate,
              'unknown': strings.precisionUnknown,
            },
            descriptions: {
              'exact': strings.precisionExactDetail,
              'approximate': strings.precisionApproximateDetail,
              'unknown': strings.precisionUnknownDetail,
            },
            onChanged: _busy
                ? null
                : (value) => setState(
                      () => _precision = BirthTimePrecision.fromName(value),
                    ),
          ),
          if (_precision == BirthTimePrecision.exact) ...[
            const SizedBox(height: EterSpace.s12),
            TextField(
              key: const ValueKey('birth-context-time'),
              controller: _time,
              enabled: !_busy,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: strings.fieldLocalBirthTime,
              ),
            ),
          ],
          if (_precision == BirthTimePrecision.approximate) ...[
            const SizedBox(height: EterSpace.s12),
            _ChoiceGroup(
              id: 'birth-period',
              heading: strings.headingWhichPartOfDay,
              value: (_period ?? BirthTimePeriod.morning).name,
              choices: {
                for (final period in BirthTimePeriod.values)
                  period.name: strings.birthPeriodLabel(period),
              },
              descriptions: {
                for (final period in BirthTimePeriod.values)
                  period.name: strings.birthPeriodDetail(period),
              },
              onChanged: _busy
                  ? null
                  : (value) => setState(
                        () => _period = BirthTimePeriod.values
                            .firstWhere((item) => item.name == value),
                      ),
            ),
          ],
          const SizedBox(height: EterSpace.s12),
          TextField(
            key: const ValueKey('birth-context-offset'),
            controller: _offset,
            enabled: !_busy,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: strings.fieldUtcOffsetAtBirth,
            ),
          ),
          const SizedBox(height: EterSpace.s12),
          TextField(
            key: const ValueKey('birth-context-place'),
            controller: _place,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: strings.fieldBirthCityAndCountry,
            ),
          ),
          const SizedBox(height: EterSpace.s8),
          Text(
            strings.placeLookupNote,
            style: text.bodySmall?.copyWith(color: ink.labelMuted),
          ),
        ],
        const SizedBox(height: EterSpace.s8),
        Wrap(
          spacing: EterSpace.s8,
          children: [
            EterAction(
              key: const ValueKey('birth-context-primary-action'),
              label: _editing ? strings.save : strings.edit,
              emphasis: EterActionEmphasis.quiet,
              busy: _busy,
              onPressed: widget.profile == null || _busy
                  ? null
                  : (_editing
                      ? _save
                      : () {
                          setState(() => _editing = true);
                          _suggestOffset();
                        }),
            ),
            if (_editing)
              EterAction(
                label: strings.cancel,
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
  bool _confirmPrune = false;
  bool _busy = false;
  String? _message;

  Future<void> _review() async {
    if (_busy) return;
    final strings = EterStrings.of(context);
    setState(() {
      _busy = true;
      _message = strings.reviewing;
    });
    final result = await LocalPatternDiscovery(widget.database).review(
      now: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _patterns = widget.database.loadActivePatterns();
      _message = result.activePatterns == 0
          ? strings.notEnoughConsistentEvidence
          : strings.patternsRefreshed(
              patterns: result.activePatterns,
              observations: result.observations,
            );
    });
  }

  Future<void> _prepareWeek() async {
    if (_busy) return;
    final strings = EterStrings.of(context);
    setState(() {
      _busy = true;
      _message = strings.preparingSevenDayView;
    });
    final result = await LocalWeeklyRetrospective(widget.database).prepare(
      now: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _retrospectives = widget.database.loadRetrospectives(limit: 1);
      _message = result == null
          ? strings.notEnoughHistoryForWeekly
          : strings.sevenDayViewPrepared;
    });
  }

  Future<void> _dismiss(String key) async {
    final strings = EterStrings.of(context);
    await widget.database.dismissPattern(key);
    if (mounted) {
      setState(() {
        _patterns = widget.database.loadActivePatterns();
        _message = strings.patternDismissed;
      });
    }
  }

  /// Clears the prose of every page older than a year, keeping what those
  /// pages produced.
  ///
  /// The retention control that existed in the database and nowhere else. What
  /// a person wrote two years ago is the most personal thing this app holds
  /// and the least likely to be read again; what they ate that day is a fact
  /// about their history and stays.
  Future<void> _pruneProse() async {
    final strings = EterStrings.of(context);
    if (!_confirmPrune) {
      setState(() {
        _confirmPrune = true;
        _message = strings.pruneProseWarning;
      });
      return;
    }
    setState(() => _busy = true);
    final cleared = await widget.database.pruneJournalProse(
      DateTime.now().toUtc().subtract(const Duration(days: 365)),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _confirmPrune = false;
      _message = cleared == 0
          ? strings.noPagesOlderThanAYear
          : strings.clearedPageText(cleared);
    });
  }

  Future<void> _reset() async {
    final strings = EterStrings.of(context);
    if (!_confirmReset) {
      setState(() {
        _confirmReset = true;
        _message = strings.resetPersonalizationWarning;
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
          ? strings.aetherMemoryAlreadyEmpty
          : strings.aetherMemoryCleared;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.headingAetherMemory, style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(strings.onlyStructuredPatternsRetained, style: text.bodyMedium),
        const SizedBox(height: EterSpace.s16),
        Text(strings.headingWeekInView, style: text.labelSmall),
        FutureBuilder<List<RetrospectiveRow>>(
          future: _retrospectives,
          builder: (context, snapshot) {
            final rows = snapshot.data;
            if (rows == null) return const SizedBox.shrink();
            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: EterSpace.s8),
                child: Text(
                  strings.noWeeklyViewPrepared,
                  style: text.bodySmall?.copyWith(color: ink.labelMuted),
                ),
              );
            }
            final review = _RetrospectiveView.tryParse(rows.first, strings);
            if (review == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: EterSpace.s8),
              child: Semantics(
                container: true,
                label: review.semanticLabel(strings),
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
          label: strings.prepare,
          emphasis: EterActionEmphasis.quiet,
          busy: _busy,
          onPressed: _busy ? null : _prepareWeek,
        ),
        const SizedBox(height: EterSpace.s16),
        Text(strings.headingLocalPatterns, style: text.labelSmall),
        FutureBuilder<List<PatternCandidateRow>>(
          future: _patterns,
          builder: (context, snapshot) {
            final patterns = snapshot.data;
            if (patterns == null) return const SizedBox.shrink();
            if (patterns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: EterSpace.s8),
                child: Text(
                  strings.noActivePatterns,
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
                          label: _patternSemantics(pattern, strings),
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _patternSummary(pattern, strings),
                                  style: text.titleMedium,
                                ),
                                const SizedBox(height: EterSpace.s4),
                                Text(
                                  _patternReceipt(pattern, strings),
                                  style: text.bodySmall?.copyWith(
                                    color: ink.labelMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        EterAction(
                          label: strings.dismiss,
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
          label: strings.review,
          emphasis: EterActionEmphasis.quiet,
          busy: _busy,
          onPressed: _busy ? null : _review,
        ),
        EterAction(
          label: _confirmReset ? strings.clearNow : strings.reset,
          busy: _busy,
          onPressed: _busy ? null : _reset,
        ),
        const SizedBox(height: EterSpace.s16),
        Text(strings.headingOldPages, style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(strings.oldPagesNote, style: text.bodyMedium),
        EterAction(
          // Two words at most: the section heading above already says which
          // pages, and a longer label overflows at 320 dp with text doubled.
          label: _confirmPrune ? strings.clearNow : strings.clear,
          emphasis: EterActionEmphasis.quiet,
          busy: _busy,
          onPressed: _busy ? null : _pruneProse,
        ),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Text(_message!, style: text.bodySmall),
          ),
      ],
    );
  }

  static Map<String, dynamic> _evidence(PatternCandidateRow pattern) {
    try {
      final decoded = jsonDecode(pattern.evidenceJson);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // A pattern stays inspectable even if legacy evidence is malformed.
    }
    return const {};
  }

  /// The finding, worded now rather than read back as a stored sentence.
  ///
  /// `PatternCandidates.summary` still holds the English sentence discovery
  /// wrote, and it is still the fallback — but a pattern found last month must
  /// read in the language chosen today, and the structured evidence beside it
  /// says everything the sentence does. Discovery finds; this speaks.
  String _patternSummary(PatternCandidateRow pattern, EterStrings strings) {
    final evidence = _evidence(pattern);
    if (pattern.key == LocalPatternDiscovery.sleepAfterLateActivityKey) {
      if (evidence['coefficient'] case final num coefficient) {
        return strings.patternSleepAfterLateActivity(shorter: coefficient < 0);
      }
    }
    // The correlation sweep names its findings `sweep:<from><>|~><to>`, which
    // carries both series and whether the pair was lagged. Everything else the
    // sentence needs is in the evidence beside it, so nothing has to be parsed
    // out of the stored English prose.
    if (_sweepPairing(pattern.key) case final pairing?) {
      if (evidence['explainsPercent'] case final num percent) {
        if (evidence['days'] case final num days) {
          return strings.patternSweepSummary(
            fromKey: pairing.from,
            toKey: pairing.to,
            lagged: pairing.lagged,
            positive: evidence['positive'] == true,
            percent: percent.round(),
            days: days.round(),
          );
        }
      }
    }
    // A finding from a build before the evidence carried its own numbers. Its
    // English sentence is all there is, and showing it beats showing nothing.
    return pattern.summary;
  }

  /// Reads a sweep key back into the two series it compared.
  ///
  /// Null for any key that is not a sweep finding — the local discovery pattern,
  /// or anything a future sweep names differently.
  static ({String from, String to, bool lagged})? _sweepPairing(String key) {
    if (!key.startsWith('sweep:')) return null;
    final body = key.substring('sweep:'.length);
    for (final (separator, lagged) in const [('>', true), ('~', false)]) {
      final at = body.indexOf(separator);
      if (at <= 0 || at == body.length - 1) continue;
      return (
        from: body.substring(0, at),
        to: body.substring(at + 1),
        lagged: lagged,
      );
    }
    return null;
  }

  String _patternReceipt(PatternCandidateRow pattern, EterStrings strings) {
    final evidence = _evidence(pattern);
    return strings.patternReceipt(
      confidencePercent: (pattern.confidence * 100).round(),
      observations: evidence['n'] is num ? evidence['n'] : null,
      window: evidence['window'] is String
          ? evidence['window'] as String
          : null,
      coefficientMinutes:
          evidence['coefficient'] is num ? evidence['coefficient'] as num : null,
    );
  }

  String _patternSemantics(PatternCandidateRow pattern, EterStrings strings) =>
      strings.patternSemantic(
        summary: _patternSummary(pattern, strings),
        receipt: _patternReceipt(pattern, strings),
      );
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

  String semanticLabel(EterStrings strings) => strings.retrospectiveSemantic(
        headline: headline,
        passages: passages.join(' '),
        caveat: caveat,
        window: window,
      );

  static _RetrospectiveView? tryParse(
    RetrospectiveRow row,
    EterStrings strings,
  ) {
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
        window: strings.retrospectiveWindow(
          from: row.periodStart,
          to: row.periodEnd,
        ),
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
    required this.copyRemains,
  });

  final AppDatabase database;
  final VoidCallback onDeleted;

  /// True when an account holds a copy that this action will not touch.
  ///
  /// The warning has to say so. Wiping the device while a full copy sits in the
  /// mirror — restorable by a button a few centimetres up the same screen — is
  /// not the permanent deletion the old single sentence promised.
  final bool copyRemains;

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
    final strings = EterStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.headingDeleteFromThisDevice, style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(
          switch ((_confirming, widget.copyRemains)) {
            (false, _) => strings.deleteLocalIntro,
            (true, true) => strings.deleteLocalWarningCopyRemains,
            (true, false) => strings.deleteLocalWarning,
          },
          style: text.bodyMedium,
        ),
        const SizedBox(height: EterSpace.s8),
        EterAction(
          label: _confirming ? strings.deleteNow : strings.delete,
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
    final strings = EterStrings.of(context);
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
            ? strings.healthRecordsRead(result.records)
            : strings.healthAccessNotGranted;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = strings.healthCouldNotBeRead);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = Platform.isAndroid || Platform.isIOS;
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
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
            Text(strings.headingHealthHistory, style: text.labelSmall),
            const SizedBox(height: EterSpace.s8),
            Text(
              connected
                  ? strings.healthConnectedReconnect
                  : supported
                      ? strings.healthOffer
                      : strings.healthUnsupportedPlatform,
              style: text.bodyMedium,
            ),
            const SizedBox(height: EterSpace.s8),
            EterAction(
              label: connected ? strings.refresh : strings.connect,
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
    final strings = EterStrings.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bundle = await LocalDataExporter(widget.database).export();
      if (!mounted) return;
      setState(() {
        _path = bundle.directory.path;
        _message = strings.localExportReady;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = strings.localExportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyPath() async {
    final path = _path;
    if (path == null) return;
    final strings = EterStrings.of(context);
    await Clipboard.setData(ClipboardData(text: path));
    if (mounted) {
      setState(() => _message = strings.exportFolderCopied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.headingLocalExport, style: text.labelSmall),
        const SizedBox(height: EterSpace.s8),
        Text(strings.localExportNote, style: text.bodyMedium),
        const SizedBox(height: EterSpace.s8),
        EterAction(
          label: strings.export,
          busy: _busy,
          onPressed: _busy ? null : _prepare,
        ),
        if (_path != null)
          EterAction(
            label: strings.copyPath,
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
    final strings = EterStrings.of(context);
    final close = EterAction(
      label: strings.close,
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
                child: Text(
                  strings.headingSanctum,
                  maxLines: 1,
                  style: style,
                ),
              ),
            ),
          ),
          Align(alignment: Alignment.centerRight, child: close),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(strings.headingSanctum, maxLines: 1, style: style),
        ),
        close,
      ],
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.id,
    required this.heading,
    required this.value,
    required this.choices,
    required this.onChanged,
    this.descriptions = const {},
  });

  /// A stable slug, never shown and never translated.
  ///
  /// The widget keys used to be built from [heading] — `ValueKey('$heading-$k')`
  /// — which made a caps-locked English sentence the identity of every setting
  /// row. Translating the heading would have renamed every key in the Sanctum,
  /// so a test tapping a permission would silently find nothing, and a
  /// `GlobalKey` collision was one duplicated heading away. The id is what
  /// identifies the row; the heading is what it says.
  final String id;

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
              key: ValueKey('$id-${choice.key}'),
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
