import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controls.dart';
import '../../core/db/app_database.dart';
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
                      'These choices stay on this device until cloud sync is '
                      'explicitly enabled.',
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
                      'Your journal and health history remain local. Account '
                      'sync, export and account deletion will appear here when '
                      'the cloud account layer is connected.',
                      style: text.bodyMedium,
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
