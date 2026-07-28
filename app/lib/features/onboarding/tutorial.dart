import 'package:flutter/material.dart';

import '../../core/arrival.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/register.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import 'onboarding_flow.dart' show EterMotto;

/// The first minute, once.
///
/// Eter's interface is deliberately sparse, and sparse interfaces are the ones
/// most often misread: a person who does not know that the Journal is where
/// everything is recorded will look for a plus button, not find one, and
/// conclude the app does nothing. This is four short passages that say where
/// things are, in the product's own voice, and never appear again.
///
/// What it is not: a feature tour, a carousel of screenshots, a coach-mark
/// overlay pointing at controls, or a checklist. It is read once and dismissed
/// — `SKIP` is present on every passage because a tutorial that cannot be left
/// is a wall.
class EterTutorial extends StatefulWidget {
  const EterTutorial({
    super.key,
    required this.database,
    required this.onFinished,
  });

  final AppDatabase database;
  final VoidCallback onFinished;

  /// Recorded in the same intake table onboarding uses, so a completed
  /// tutorial survives a restart and never shows twice.
  static const answerKey = 'tutorial_complete';

  @override
  State<EterTutorial> createState() => _EterTutorialState();
}

class _TutorialPassage {
  const _TutorialPassage({
    required this.eyebrow,
    required this.lines,
  });

  final String eyebrow;
  final List<String> lines;
}

const _passages = <_TutorialPassage>[
  _TutorialPassage(
    eyebrow: 'ETER',
    lines: [
      'Eter reads your days and tells you what it notices.',
      'It keeps everything on this device unless you say otherwise, and it '
          'never scores you.',
    ],
  ),
  _TutorialPassage(
    eyebrow: 'THE JOURNAL',
    lines: [
      'Everything you record, you write or speak here.',
      'There are no forms elsewhere: meals, movement and how a day felt all '
          'come from what you wrote. Each page can be interpreted when you ask '
          'for it, and any page can be kept from Aether entirely.',
    ],
  ),
  _TutorialPassage(
    eyebrow: 'THE DASHBOARD',
    lines: [
      'The other side of the same space reads back what it found.',
      'Guidance arrives on its own each day. Look deeper for the body, or for '
          'the Vessel — your chart, your Life Path, and where today’s sky '
          'stands against them.',
    ],
  ),
  _TutorialPassage(
    eyebrow: 'THE SANCTUM',
    lines: [
      'Tap the ETER signature at the top to open it.',
      'Settings, your birth details, the health connection, and every '
          'permission — each one independent, each one revocable, and a way to '
          'take all of it back out again.',
    ],
  ),
];

class _EterTutorialState extends State<EterTutorial> {
  int _index = 0;

  Future<void> _finish() async {
    await widget.database.saveIntakeAnswer(
      key: EterTutorial.answerKey,
      value: 'true',
      tier: 'essential',
    );
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final passage = _passages[_index];
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final last = _index == _passages.length - 1;

    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: SurfaceIntentScope(
            intent: SurfaceIntent.ritual,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 44, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(passage.eyebrow, style: text.labelSmall),
                      const Spacer(),
                      Text(
                        '${_index + 1} / ${_passages.length}',
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: EterSpace.s48),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The same reveal that carries guidance carries this:
                          // the first sentences a person reads should behave
                          // the way every sentence after them will.
                          EterArrival(
                            key: ValueKey('tutorial-$_index'),
                            passages: [
                              ArrivalPassage(
                                passage.lines.first,
                                style: text.displaySmall?.copyWith(height: 1.3),
                              ),
                              for (final line in passage.lines.skip(1))
                                ArrivalPassage(
                                  line,
                                  style: text.bodyLarge?.copyWith(
                                    color: ink.labelMuted,
                                    height: 1.6,
                                  ),
                                ),
                            ],
                          ),
                          if (_index == 0) ...[
                            const SizedBox(height: EterSpace.s32),
                            const EterMotto(textAlign: TextAlign.start),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (!last)
                        EterAction(
                          label: 'Skip',
                          emphasis: EterActionEmphasis.quiet,
                          onPressed: _finish,
                        ),
                      const Spacer(),
                      EterAction(
                        label: last ? 'Begin' : 'Next',
                        emphasis: last
                            ? EterActionEmphasis.primary
                            : EterActionEmphasis.secondary,
                        onPressed: last
                            ? _finish
                            : () => setState(() => _index += 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
