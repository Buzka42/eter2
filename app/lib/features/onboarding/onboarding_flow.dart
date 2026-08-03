import 'dart:io' show Platform;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/health/health_hub.dart';
import '../../core/health/platform_health_gateway.dart';
import '../../core/i18n/language.dart';
import '../../core/i18n/strings.dart';
import '../../core/profile/birth_context.dart';
import '../../core/profile/birth_offset.dart';
import '../../core/profile/birth_time.dart';
import '../../core/profile/body_fat.dart';
import '../../core/profile/date_input.dart';
import '../../core/profile/place_suggestions.dart';
import '../../core/register.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.database,
    required this.profile,
    required this.onComplete,
    this.resolver = const PlatformBirthplaceResolver(),
  });

  final AppDatabase database;
  final ProfileRow? profile;
  final VoidCallback onComplete;

  /// Turns a typed birth place into coordinates.
  ///
  /// Defaulted rather than required so a widget test that only cares about the
  /// steps does not have to know about geocoding — the platform one throws a
  /// `MissingPluginException` under a test binding, which the save already
  /// treats as "the place stays as typed".
  final BirthplaceResolver resolver;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _name = TextEditingController();
  final _intention = TextEditingController();
  final _birthPlace = TextEditingController();
  final _birthTime = TextEditingController();
  BirthTimePrecision _precision = BirthTimePrecision.unknown;
  BirthTimePeriod? _period;
  final _dob = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  var _step = 0;
  var _sex = 'other';
  double? _bodyFat;
  var _ai = false;
  var _journalAi = false;
  var _cloud = false;
  var _register = 'balanced';
  var _saving = false;
  String? _birthError;

  /// Suggestions as the birth place is typed. Null when the resolver cannot
  /// suggest — a test fake, or any resolver that only knows how to save —
  /// in which case the field stays the plain field it always was.
  PlaceSuggestionController? _placeSuggestions;

  /// Chosen on the first step, and pre-filled from the phone.
  ///
  /// Held in local state and written with the profile at the end, like every
  /// other answer here — but applied to the *interface* immediately, because a
  /// language choice that does not take effect until you finish setup is a
  /// language choice made in a language you may not read.
  AppLanguage? _language;

  /// The number of steps, in one place. Adding the language step made this a
  /// literal `4` in four unrelated expressions, one of which was the
  /// `AnimatedSwitcher` default branch.
  static const _steps = 5;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _language = AppLanguage.forProfile(profile?.language);
    _name.text = profile?.firstName ?? '';
    _birthPlace.text = profile?.birthPlace ?? '';
    if (widget.resolver case final PlaceSuggester suggester) {
      final suggestions = PlaceSuggestionController(suggester: suggester);
      _placeSuggestions = suggestions;
      _birthPlace.addListener(
        () => suggestions.onQueryChanged(_birthPlace.text),
      );
    }
    _sex = profile?.sex ?? 'other';
    _register = profile?.guidanceMode ?? 'balanced';
    _bodyFat = EterBodyFat.normalize(profile?.bodyFatPercent);
    if (profile != null) {
      _dob.text = '${profile.dob.year.toString().padLeft(4, '0')}-'
          '${profile.dob.month.toString().padLeft(2, '0')}-'
          '${profile.dob.day.toString().padLeft(2, '0')}';
      _weight.text = profile.weightKg.toStringAsFixed(1);
      if (profile.heightCm != null) {
        _height.text = profile.heightCm!.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _intention.dispose();
    _placeSuggestions?.dispose();
    _birthPlace.dispose();
    _birthTime.dispose();
    _dob.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final dob = DateTime.parse(_dob.text.trim());
    final weight = double.parse(_weight.text.trim());
    final height = double.parse(_height.text.trim());
    final existing = widget.profile;
    final profile = existing == null
        ? ProfilesCompanion.insert(
            dob: dob,
            sex: _sex,
            weightKg: weight,
            heightCm: Value(height),
            bodyFatPercent: Value(_bodyFat),
            units: 'metric',
            firstName:
                Value(_name.text.trim().isEmpty ? null : _name.text.trim()),
            birthPlace: Value(_birthPlace.text.trim().isEmpty
                ? null
                : _birthPlace.text.trim()),
            aiConsentAt: Value(_ai ? now : null),
            journalAiConsentAt: Value(_ai && _journalAi ? now : null),
            cloudSyncConsentAt: Value(_cloud ? now : null),
            guidanceMode: Value(_register),
            language: Value(_language?.code),
          )
        : existing.toCompanion(true).copyWith(
              dob: Value(dob),
              sex: Value(_sex),
              weightKg: Value(weight),
              heightCm: Value(height),
              bodyFatPercent: Value(_bodyFat),
              firstName:
                  Value(_name.text.trim().isEmpty ? null : _name.text.trim()),
              birthPlace: Value(_birthPlace.text.trim().isEmpty
                  ? null
                  : _birthPlace.text.trim()),
              aiConsentAt: Value(_ai ? now : null),
              journalAiConsentAt: Value(_ai && _journalAi ? now : null),
              cloudSyncConsentAt: Value(_cloud ? now : null),
              guidanceMode: Value(_register),
              language: Value(_language?.code),
            );
    await widget.database.saveProfile(profile);

    // The birth context, through the same service the Sanctum uses.
    //
    // Onboarding used to write `birthPlace` as a bare string and stop there —
    // no coordinates, ever. That is why a real profile carried
    // `birth_place = 'Warsaw'` with a null latitude, and why the register and
    // the evening invitation both fell back to a clock hour for somebody who
    // had told Eter exactly where they were born. Resolving here is what makes
    // the answer worth asking for.
    //
    // Best-effort: a geocoder that cannot reach the network, or a place it does
    // not recognise, must not strand somebody on the last step of onboarding
    // with everything else already saved. The Sanctum can still resolve it
    // later, and says so.
    try {
      await BirthContextService(
        database: widget.database,
        resolver: widget.resolver,
      )
          .save(
            time: _birthTime.text,
            utcOffset: _suggestedOffset(dob),
            place: _birthPlace.text,
            precision: _precision,
            period: _period,
          )
          // Bounded, because this is the last step of onboarding and the
          // geocoder is a network call. A fast lookup is worth waiting for —
          // the chart is cast the moment the shell opens and is better with
          // coordinates — but nobody stands on the doorstep while a lookup
          // times out. The Sanctum can resolve it later and says so.
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Timed out, offline, or a place the geocoder does not know. The typed
      // place is already on the profile row above; only the coordinates are
      // missing, which is the state the whole birth-context UI is built for.
    }

    await widget.database.saveIntakeAnswer(
      key: 'primary_intention',
      value: _intention.text.trim(),
      tier: 'essential',
    );
    await widget.database.saveIntakeAnswer(
      key: 'onboarding_complete',
      value: 'true',
      tier: 'essential',
    );
    if (mounted) widget.onComplete();
  }

  /// The offset this phone implies for that date, formatted the way
  /// `parseUtcOffsetMinutes` reads it.
  ///
  /// Not asked for. Onboarding is not the place to explain UTC offsets, and
  /// the overwhelmingly common case is somebody born where their phone thinks
  /// it is. The Sanctum exposes the field for the case it is wrong, and its
  /// note already says to correct it if the birth place was elsewhere.
  String _suggestedOffset(DateTime dob) {
    final minutes = BirthOffset.suggestMinutes(dob);
    return minutes == null ? '' : BirthOffset.format(minutes);
  }

  bool _validateBirth(EterStrings strings) {
    final weight = double.tryParse(_weight.text.trim());
    final height = double.tryParse(_height.text.trim());
    String? error;
    // One validator, shared with the Sanctum. `DateTime.tryParse` was doing
    // this job and it rolls over rather than refusing: 31 February came back
    // as 3 March, so onboarding accepted a birthday nobody has and cast the
    // chart for it.
    switch (birthDateProblem(_dob.text, now: DateTime.now())) {
      case BirthDateProblem.malformed:
      case BirthDateProblem.outOfRange:
        error = strings.errorEnterValidBirthDate;
      case BirthDateProblem.tooYoung:
        error = strings.errorMinimumAge;
      case null:
        break;
    }
    if (error == null && (weight == null || weight < 20 || weight > 500)) {
      error = strings.errorEnterWeightRange;
    }
    if (error == null && (height == null || height < 100 || height > 250)) {
      error = strings.errorEnterHeightRange;
    }
    setState(() => _birthError = error);
    return error == null;
  }

  @override
  Widget build(BuildContext context) {
    // The chosen language, not the ambient one: the rest of the tree is still
    // under the root scope, which reads the profile — and the profile has no
    // language until this flow finishes. Re-scoping here is what makes the
    // choice on step one visible on step one.
    final strings = EterStrings.forLanguage(
      _language ?? AppLanguage.resolveFromPlatform(),
    );
    return EterStringsScope(
      strings: strings,
      child: _build(context, strings),
    );
  }

  Widget _build(BuildContext context, EterStrings strings) {
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 44, 28, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SurfaceIntentScope(
                  intent: SurfaceIntent.ritual,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _OnboardingMark(),
                      const SizedBox(height: EterSpace.s12),
                      const EterMotto(),
                      const SizedBox(height: EterSpace.s32),
                      Semantics(
                        label: strings.onboardingStepSemantic(
                          step: _step + 1,
                          total: _steps,
                        ),
                        child: Text(
                          strings.onboardingStepMark(
                            step: _step + 1,
                            total: _steps,
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(height: EterSpace.s12),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : EterMotion.durStandard,
                        child: switch (_step) {
                          // First, because it decides what every step after it
                          // is written in.
                          0 => _LanguageStep(
                              key: const ValueKey(0),
                              value: _language ??
                                  AppLanguage.resolveFromPlatform(),
                              onChanged: (value) =>
                                  setState(() => _language = value),
                            ),
                          1 => _WelcomeStep(
                              key: const ValueKey(1),
                              name: _name,
                              intention: _intention,
                            ),
                          2 => _BirthStep(
                              key: const ValueKey(2),
                              dob: _dob,
                              weight: _weight,
                              height: _height,
                              bodyFat: _bodyFat,
                              onBodyFat: (value) =>
                                  setState(() => _bodyFat = value),
                              sex: _sex,
                              onSex: (value) => setState(() => _sex = value),
                              place: _birthPlace,
                              birthTime: _birthTime,
                              precision: _precision,
                              onPrecision: (value) =>
                                  setState(() => _precision = value),
                              period: _period,
                              onPeriod: (value) =>
                                  setState(() => _period = value),
                              error: _birthError,
                              suggestions: _placeSuggestions,
                            ),
                          3 => _RegisterStep(
                              key: const ValueKey(3),
                              value: _register,
                              onChanged: (value) =>
                                  setState(() => _register = value),
                            ),
                          _ => _ConsentStep(
                              key: const ValueKey(4),
                              database: widget.database,
                              ai: _ai,
                              journalAi: _journalAi,
                              cloud: _cloud,
                              onAi: (value) => setState(() {
                                _ai = value;
                                if (!value) _journalAi = false;
                              }),
                              onJournalAi: (value) =>
                                  setState(() => _journalAi = value),
                              onCloud: (value) =>
                                  setState(() => _cloud = value),
                            ),
                        },
                      ),
                      const SizedBox(height: EterSpace.s32),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: EterSpace.s12,
                        children: [
                          if (_step > 0)
                            EterAction(
                              label: strings.back,
                              emphasis: EterActionEmphasis.quiet,
                              onPressed: () => setState(() => _step--),
                            )
                          else
                            const SizedBox(width: 64),
                          EterAction(
                            label: _step == _steps - 1
                                ? strings.enterEter
                                : strings.continueLabel,
                            emphasis: EterActionEmphasis.primary,
                            busy: _saving,
                            onPressed: _saving
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    if (_step < _steps - 1) {
                                      if (_step == 2 &&
                                          !_validateBirth(strings)) {
                                        return;
                                      }
                                      setState(() => _step++);
                                    } else {
                                      _finish();
                                    }
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingMark extends StatelessWidget {
  const _OnboardingMark();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const StarOrnament(size: 18),
          const SizedBox(width: EterSpace.s12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              // The shell's wordmark lockup, not a heading: `headlineMedium`
              // is the one TextTheme slot EterTheme does not define, so this
              // was silently rendering in the platform's default face instead
              // of Cormorant. Onboarding is where the name is met first; it
              // has to be the same name.
              child: Text(
                EterStrings.of(context).wordmark,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 8,
                    ),
              ),
            ),
          ),
          const SizedBox(width: EterSpace.s12),
          const StarOrnament(size: 18),
        ],
      );
}

/// The line the whole product is an argument for. It appears once, under the
/// name, at the moment someone meets Eter for the first time — and again on
/// the first card of the tutorial. Nowhere else: a motto repeated is a slogan.
///
/// `anima` rather than Juvenal's `mens`: soul rather than mind, which is the
/// triad this product actually reads — health, mind, spirit.
class EterMotto extends StatelessWidget {
  const EterMotto({super.key, this.textAlign = TextAlign.center});

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => Text(
        EterStrings.of(context).motto,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Cormorant Garamond',
              fontSize: 16,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.6,
              color: EterInk.of(context).labelMuted,
            ),
      );
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.name, required this.intention});
  final TextEditingController name;
  final TextEditingController intention;

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    return _StepBody(
      id: 'welcome',
      title: strings.welcomeTitle,
      intro: strings.welcomeIntro,
      children: [
        _LineField(
          controller: name,
          label: strings.fieldWhatShouldEterCallYou,
        ),
        const SizedBox(height: EterSpace.s24),
        _LineField(
          controller: intention,
          label: strings.fieldWhatWouldYouLikeMoreOf,
          hint: strings.hintWhatWouldYouLikeMoreOf,
          lines: 3,
        ),
      ],
    );
  }
}

class _BirthStep extends StatelessWidget {
  const _BirthStep({
    super.key,
    required this.dob,
    required this.weight,
    required this.height,
    required this.sex,
    required this.onSex,
    required this.place,
    required this.error,
    required this.bodyFat,
    required this.onBodyFat,
    required this.birthTime,
    required this.precision,
    required this.onPrecision,
    required this.period,
    required this.onPeriod,
    required this.suggestions,
  });
  final TextEditingController dob;
  final TextEditingController weight;
  final TextEditingController height;
  final double? bodyFat;
  final ValueChanged<double?> onBodyFat;
  final String sex;
  final ValueChanged<String> onSex;
  final TextEditingController place;
  final TextEditingController birthTime;
  final BirthTimePrecision precision;
  final ValueChanged<BirthTimePrecision> onPrecision;
  final BirthTimePeriod? period;
  final ValueChanged<BirthTimePeriod> onPeriod;
  final String? error;
  final PlaceSuggestionController? suggestions;

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    return _StepBody(
      id: 'birth',
      title: strings.birthStepTitle,
      intro: strings.birthStepIntro,
      children: [
        _LineField(
          controller: dob,
          label: strings.fieldBirthDate,
          hint: strings.hintBirthDateFormat,
          keyboardType: TextInputType.number,
          // The hyphens type themselves. Asking somebody to punctuate their own
          // birthday to satisfy `DateTime.parse` is the parser's problem.
          formatters: const [BirthDateInputFormatter()],
        ),
        // The message belongs under the field that raised it. It used to sit
        // at the foot of the step, below the optional birth place, several
        // fields away from the input it was about.
        if (error != null) ...[
          const SizedBox(height: EterSpace.s8),
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: EterSpace.s24),
        _LineField(
          controller: weight,
          label: strings.fieldCurrentWeightKg,
          hint: '70',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: EterSpace.s24),
        _LineField(
          controller: height,
          label: strings.fieldCurrentHeightCm,
          hint: '170',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: EterSpace.s8),
        BodyFatField(value: bodyFat, onChanged: onBodyFat),
        const SizedBox(height: EterSpace.s16),
        Text(
          strings.headingBodyContext,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Wrap(
          spacing: EterSpace.s16,
          children: [
            for (final option in {
              'female': strings.sexFemale,
              'male': strings.sexMale,
              'other': strings.sexOther,
            }.entries)
              _TextChoice(
                label: option.value,
                selected: sex == option.key,
                onTap: () => onSex(option.key),
              ),
          ],
        ),
        const SizedBox(height: EterSpace.s16),
        _LineField(
          controller: place,
          label: strings.fieldBirthPlaceOptional,
          hint: strings.hintCityOrRegion,
        ),
        if (suggestions != null)
          PlaceSuggestionList(
            controller: suggestions!,
            onChosen: (candidate) {
              // Setting the text re-triggers the listener, so the dismissal
              // has to come second to cancel the lookup it just scheduled.
              place.text = candidate.label;
              suggestions!.dismiss();
            },
          ),

        // The birth time, asked here rather than deferred to the Sanctum.
        //
        // It used to say "Exact birth time can be added later" and almost
        // nobody did, which left every chart cast for noon with a hedge on
        // every angle — the ascendant crosses a sign about every two hours, so
        // a chart without a time is a chart missing the fastest thing in it.
        // Asking once, here, while somebody is already looking up where they
        // were born, is the only moment it is cheap to ask.
        const SizedBox(height: EterSpace.s24),
        Text(
          strings.headingHowWellIsTimeKnown,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Wrap(
          spacing: EterSpace.s16,
          children: [
            for (final option in {
              BirthTimePrecision.exact: strings.precisionExact,
              BirthTimePrecision.approximate: strings.precisionApproximate,
              BirthTimePrecision.unknown: strings.precisionUnknown,
            }.entries)
              _TextChoice(
                label: option.value,
                selected: precision == option.key,
                onTap: () => onPrecision(option.key),
              ),
          ],
        ),
        if (precision == BirthTimePrecision.exact) ...[
          const SizedBox(height: EterSpace.s12),
          _LineField(
            controller: birthTime,
            label: strings.fieldLocalBirthTime,
            hint: '07:42',
            keyboardType: TextInputType.number,
            formatters: const [ClockInputFormatter()],
          ),
        ],
        if (precision == BirthTimePrecision.approximate) ...[
          const SizedBox(height: EterSpace.s12),
          Text(
            strings.headingWhichPartOfDay,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Wrap(
            spacing: EterSpace.s16,
            children: [
              for (final option in BirthTimePeriod.values)
                _TextChoice(
                  label: strings.birthPeriodLabel(option),
                  selected: period == option,
                  onTap: () => onPeriod(option),
                ),
            ],
          ),
        ],
        if (precision != BirthTimePrecision.unknown) ...[
          const SizedBox(height: EterSpace.s4),
          Text(
            strings.offsetSuggestedFromPhone,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({
    super.key,
    required this.ai,
    required this.journalAi,
    required this.cloud,
    required this.onAi,
    required this.onJournalAi,
    required this.onCloud,
    required this.database,
  });
  final bool ai;
  final bool journalAi;
  final bool cloud;
  final ValueChanged<bool> onAi;
  final ValueChanged<bool> onJournalAi;
  final ValueChanged<bool> onCloud;
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    return _StepBody(
      id: 'consent',
      title: strings.consentStepTitle,
      intro: strings.consentStepIntro,
      children: [
        _HealthConnectStep(database: database),
        const SizedBox(height: EterSpace.s24),
        _PlainChoice(
          title: strings.consentAiTitle,
          detail: strings.consentAiDetail,
          value: ai,
          onChanged: onAi,
        ),
        _PlainChoice(
          title: strings.consentJournalAiTitle,
          detail: strings.consentJournalAiDetail,
          value: journalAi,
          enabled: ai,
          onChanged: onJournalAi,
        ),
        _PlainChoice(
          title: strings.consentCloudTitle,
          detail: strings.consentCloudDetail,
          value: cloud,
          onChanged: onCloud,
        ),
      ],
    );
  }
}

/// The first thing anyone is asked, and the only one that has to be readable
/// before it is answered.
///
/// Pre-selected from the phone, so the overwhelming majority of people see their
/// own language already chosen and simply continue. Each option names itself in
/// itself — a row reading "Polish" is no use to somebody who needs it.
class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    return _StepBody(
      id: 'language',
      title: strings.languageStepTitle,
      intro: strings.languageStepIntro,
      children: [
        for (final language in AppLanguage.values)
          _TextChoice(
            key: ValueKey('onboarding-language-${language.code}'),
            label: language.endonym,
            selected: language == value,
            onTap: () => onChanged(language),
          ),
      ],
    );
  }
}

/// Choosing the register at the start, rather than discovering it later.
///
/// It defaulted to `balanced` and lived only in the Sanctum, which meant the
/// one choice that most changes how Eter sounds was the one thing nobody was
/// asked. It is a preference, not a permission, so it sits before the consents
/// rather than among them.
class _RegisterStep extends StatelessWidget {
  const _RegisterStep({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final choices = {
      'grounded': (
        strings.registerGrounded,
        strings.registerGroundedOnboardingDetail,
      ),
      'balanced': (
        strings.registerBalanced,
        strings.registerBalancedOnboardingDetail,
      ),
      'immersive': (
        strings.registerImmersive,
        strings.registerImmersiveOnboardingDetail,
      ),
    };
    return _StepBody(
      id: 'register',
      title: strings.registerStepTitle,
      intro: strings.registerStepIntro,
      children: [
        for (final entry in choices.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: EterSpace.s12),
            child: Semantics(
              selected: value == entry.key,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(entry.key),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      // The selected register is marked, not boxed.
                      child: StarOrnament(
                        size: 12,
                        color: value == entry.key
                            ? EterColors.aura500
                            : EterInk.of(context).labelMuted,
                      ),
                    ),
                    const SizedBox(width: EterSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.$1,
                            style: value == entry.key
                                ? text.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)
                                : text.bodyLarge,
                          ),
                          Text(entry.value.$2, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Connecting the phone's health store during onboarding.
///
/// It was only ever offered in the Sanctum, so a new person finished setup
/// with an empty body log and no indication that Eter could fill it.
class _HealthConnectStep extends StatefulWidget {
  const _HealthConnectStep({required this.database});

  final AppDatabase database;

  @override
  State<_HealthConnectStep> createState() => _HealthConnectStepState();
}

class _HealthConnectStepState extends State<_HealthConnectStep> {
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
      ).sync(start: now.subtract(const Duration(days: 30)), end: now);
      if (!mounted) return;
      setState(() {
        _message = result.authorized
            ? strings.healthRecordsRead(result.records)
            : strings.healthAccessNotGrantedOnboarding;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = strings.healthCouldNotBeReadOnboarding);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final supported = Platform.isAndroid || Platform.isIOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.healthHistoryTitle, style: text.bodyLarge),
        const SizedBox(height: EterSpace.s4),
        Text(
          supported
              ? strings.healthOnboardingOffer
              : strings.healthUnsupportedPlatform,
          style: text.bodySmall,
        ),
        const SizedBox(height: EterSpace.s8),
        EterAction(
          label: strings.connect,
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
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.id,
    required this.title,
    required this.children,
    required this.intro,
  });

  /// Identity for the switcher's transition, and untranslated: keying on
  /// [title] meant changing language mid-flow read as a step change.
  final String id;

  final String title;
  final String intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        key: ValueKey(id),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: EterSpace.s12),
          Text(intro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: EterSpace.s32),
          ...children,
        ],
      );
}

class _LineField extends StatelessWidget {
  const _LineField({
    required this.controller,
    required this.label,
    this.hint,
    this.lines = 1,
    this.keyboardType,
    this.formatters,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int lines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: false,
        border: UnderlineInputBorder(borderSide: BorderSide(color: ink.line)),
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: ink.line)),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: ink.lineStrong)),
      ),
    );
  }
}

class _TextChoice extends StatelessWidget {
  const _TextChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          // Left-aligned, like every field above it — centred labels inside a
          // left-aligned form read as three captions rather than a choice —
          // and marked the way the Sanctum marks a choice: a travelling rule
          // at the end of the row. An underline alone was too quiet to read
          // as selection, and it is also how the app draws a pressed action.
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected ? ink.label : ink.labelMuted,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
              const SizedBox(width: EterSpace.s16),
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : EterMotion.durStandard,
                width: selected ? 32 : 12,
                height: 1,
                color: selected ? ink.lineStrong : ink.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlainChoice extends StatelessWidget {
  const _PlainChoice({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String title;
  final String detail;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      label: strings.consentSemantic(title: title, allowed: value),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: EterSpace.s12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: EterSpace.s4),
                      Text(detail,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: EterSpace.s16),
                Text(
                  value ? strings.allowMark : strings.offMark,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: enabled ? ink.lineStrong : ink.labelMuted,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
