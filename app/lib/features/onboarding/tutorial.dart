import 'package:flutter/material.dart';

import '../../core/arrival.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/i18n/strings.dart';
import '../../core/icons.dart';
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

  /// The second half — the walkthrough over the running shell. Recorded
  /// separately so somebody who has read the written half on an older build is
  /// not made to read it again to reach the new one.
  static const walkthroughKey = 'walkthrough_complete';

  @override
  State<EterTutorial> createState() => _EterTutorialState();
}

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
    final strings = EterStrings.of(context);
    final passages = strings.tutorialPassages;
    final passage = passages[_index];
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final last = _index == passages.length - 1;

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
                        strings.onboardingStepMark(
                          step: _index + 1,
                          total: passages.length,
                        ),
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
                          if (passage.showsSanctumMark) ...[
                            const SizedBox(height: EterSpace.s32),
                            // Shown, not described. It is the only symbol in the
                            // product somebody has to recognise before they can
                            // use it, and a sentence about "a ringed mark" is a
                            // riddle where the mark itself is an answer.
                            ExcludeSemantics(
                              child: EterSanctumMark(
                                size: 26,
                                glow: true,
                                color: ink.lineStrong,
                              ),
                            ),
                          ],
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
                          label: strings.skip,
                          emphasis: EterActionEmphasis.quiet,
                          onPressed: _finish,
                        ),
                      const Spacer(),
                      EterAction(
                        label: last ? strings.begin : strings.next,
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
