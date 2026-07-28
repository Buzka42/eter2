import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/controls.dart';
import '../../core/db/app_database.dart';
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
  });

  final AppDatabase database;
  final ProfileRow? profile;
  final VoidCallback onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _name = TextEditingController();
  final _intention = TextEditingController();
  final _birthPlace = TextEditingController();
  final _dob = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  var _step = 0;
  var _sex = 'other';
  var _ai = false;
  var _journalAi = false;
  var _cloud = false;
  var _saving = false;
  String? _birthError;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name.text = profile?.firstName ?? '';
    _birthPlace.text = profile?.birthPlace ?? '';
    _sex = profile?.sex ?? 'other';
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
    _birthPlace.dispose();
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
            units: 'metric',
            firstName:
                Value(_name.text.trim().isEmpty ? null : _name.text.trim()),
            birthPlace: Value(_birthPlace.text.trim().isEmpty
                ? null
                : _birthPlace.text.trim()),
            aiConsentAt: Value(_ai ? now : null),
            journalAiConsentAt: Value(_ai && _journalAi ? now : null),
            cloudSyncConsentAt: Value(_cloud ? now : null),
          )
        : existing.toCompanion(true).copyWith(
              dob: Value(dob),
              sex: Value(_sex),
              weightKg: Value(weight),
              heightCm: Value(height),
              firstName:
                  Value(_name.text.trim().isEmpty ? null : _name.text.trim()),
              birthPlace: Value(_birthPlace.text.trim().isEmpty
                  ? null
                  : _birthPlace.text.trim()),
              aiConsentAt: Value(_ai ? now : null),
              journalAiConsentAt: Value(_ai && _journalAi ? now : null),
              cloudSyncConsentAt: Value(_cloud ? now : null),
            );
    await widget.database.saveProfile(profile);
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

  bool _validateBirth() {
    final dob = DateTime.tryParse(_dob.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    final height = double.tryParse(_height.text.trim());
    String? error;
    if (dob == null || dob.isAfter(DateTime.now())) {
      error = 'Enter a valid birth date as YYYY-MM-DD.';
    } else {
      final today = DateTime.now();
      var age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      if (age < 16) {
        error = 'Eter is currently available to people aged 16 and over.';
      }
    }
    if (error == null && (weight == null || weight < 20 || weight > 500)) {
      error = 'Enter your current weight between 20 and 500 kg.';
    }
    if (error == null && (height == null || height < 100 || height > 250)) {
      error = 'Enter your current height between 100 and 250 cm.';
    }
    setState(() => _birthError = error);
    return error == null;
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: EterSpace.s32),
                      Semantics(
                        label: 'Onboarding step ${_step + 1} of 3',
                        child: Text(
                          '${_step + 1} / 3',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(height: EterSpace.s12),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : EterMotion.durStandard,
                        child: switch (_step) {
                          0 => _WelcomeStep(
                              key: const ValueKey(0),
                              name: _name,
                              intention: _intention,
                            ),
                          1 => _BirthStep(
                              key: const ValueKey(1),
                              dob: _dob,
                              weight: _weight,
                              height: _height,
                              sex: _sex,
                              onSex: (value) => setState(() => _sex = value),
                              place: _birthPlace,
                              error: _birthError,
                            ),
                          _ => _ConsentStep(
                              key: const ValueKey(2),
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
                              label: 'Back',
                              emphasis: EterActionEmphasis.quiet,
                              onPressed: () => setState(() => _step--),
                            )
                          else
                            const SizedBox(width: 64),
                          EterAction(
                            label: _step == 2 ? 'Enter Eter' : 'Continue',
                            emphasis: EterActionEmphasis.primary,
                            busy: _saving,
                            onPressed: _saving
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    if (_step < 2) {
                                      if (_step == 1 && !_validateBirth()) {
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
                'ETER',
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

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.name, required this.intention});
  final TextEditingController name;
  final TextEditingController intention;

  @override
  Widget build(BuildContext context) => _StepBody(
        title: 'Begin with what matters',
        intro:
            'A few words are enough. You can change or remove any of this later.',
        children: [
          _LineField(controller: name, label: 'What should Eter call you?'),
          const SizedBox(height: EterSpace.s24),
          _LineField(
            controller: intention,
            label: 'What would you like more of?',
            hint: 'Steadier energy, deeper sleep, a clearer mind…',
            lines: 3,
          ),
        ],
      );
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
  });
  final TextEditingController dob;
  final TextEditingController weight;
  final TextEditingController height;
  final String sex;
  final ValueChanged<String> onSex;
  final TextEditingController place;
  final String? error;

  @override
  Widget build(BuildContext context) => _StepBody(
        title: 'Your point of origin',
        intro:
            'Date supports health context and symbolic calculations. Place and exact time are optional; without them, Eter labels the chart provisional.',
        children: [
          _LineField(
            controller: dob,
            label: 'Birth date',
            hint: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
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
            label: 'Current weight in kilograms',
            hint: '70',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: EterSpace.s24),
          _LineField(
            controller: height,
            label: 'Current height in centimetres',
            hint: '170',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: EterSpace.s24),
          Text('BODY CONTEXT', style: Theme.of(context).textTheme.labelSmall),
          Wrap(
            spacing: EterSpace.s16,
            children: [
              for (final option in const {
                'female': 'Female',
                'male': 'Male',
                'other': 'Another / prefer not to say',
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
            label: 'Birth place — optional',
            hint: 'City or region',
          ),
          const SizedBox(height: EterSpace.s16),
          Text(
            'Exact birth time can be added later in the Sanctum.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
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
  });
  final bool ai;
  final bool journalAi;
  final bool cloud;
  final ValueChanged<bool> onAi;
  final ValueChanged<bool> onJournalAi;
  final ValueChanged<bool> onCloud;

  @override
  Widget build(BuildContext context) => _StepBody(
        title: 'Choose what may leave this device',
        intro:
            'All three choices are optional. Core journaling and local calculations still work if you decline.',
        children: [
          _PlainChoice(
            title: 'AI guidance',
            detail: 'Send selected health context to compose guidance.',
            value: ai,
            onChanged: onAi,
          ),
          _PlainChoice(
            title: 'Journal-aware guidance',
            detail: 'Allow included journal prose to be sent for reflection.',
            value: journalAi,
            enabled: ai,
            onChanged: onJournalAi,
          ),
          _PlainChoice(
            title: 'Cloud continuity',
            detail: 'Keep an encrypted account copy for a future phone.',
            value: cloud,
            onChanged: onCloud,
          ),
        ],
      );
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.title,
    required this.intro,
    required this.children,
  });
  final String title;
  final String intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        key: ValueKey(title),
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
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int lines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: keyboardType,
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
          // Left-aligned, like every field above it. Centred labels inside a
          // left-aligned form read as three captions rather than a choice.
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? ink.label : ink.labelMuted,
                    decoration: selected
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
            ),
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
    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      label: '$title, ${value ? 'allowed' : 'kept off'}',
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
                  value ? 'ALLOW' : 'OFF',
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
