import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/arrival.dart';
import '../../core/clock.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/haptics.dart';
import '../../core/register.dart';
import '../../core/tokens.dart';
import '../../main.dart';
import '../prototype/fixtures.dart';

/// The Journal — an open, date-led personal page, not a form.
///
/// The writing region is a warm parchment field resting on the same sky as
/// everything else: subtle grain, a soft page edge, no border, no card per
/// entry. The date leads; time is a marginal annotation. Capture is the whole
/// game — tapping the open page starts writing, dictation is one tap away,
/// and saving is something the page does, not something the user is asked
/// for. New entries do not appear; they arrive, through the same signature
/// reveal as the guidance.
class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final _composer = TextEditingController();
  final _focusNode = FocusNode();
  final _speech = stt.SpeechToText();
  final _arrivingIds = <int>{};

  Timer? _autosave;
  bool _saving = false;
  bool _excluded = false;
  bool _spokenUsed = false;
  bool _listening = false;
  String? _dictationNote;
  String _dictationBase = '';
  Stream<List<JournalEntryRow>>? _entriesStream;
  String? _streamedDay;

  static final _dateHeading = DateFormat('EEEE d MMMM');
  static final _marginalTime = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _composer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {}); // Done visibility follows the text.
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 900), _save);
  }

  Future<void> _save() async {
    _autosave?.cancel();
    final text = _composer.text.trim();
    if (text.isEmpty || _saving) return;
    _saving = true;
    try {
      final db = ref.read(databaseProvider);
      final now = ref.read(nowProvider)();
      final id = await db.addJournalEntry(
        JournalEntriesCompanion.insert(
          entryText: text,
          createdAt: now,
          source: Value(_spokenUsed ? 'spoken' : 'typed'),
          excludedFromAi: Value(_excluded),
        ),
      );
      await EterHaptics.light();
      if (!mounted) return;
      setState(() {
        _arrivingIds.add(id);
        _composer.clear();
        _spokenUsed = false;
        _excluded = false;
      });
    } finally {
      _saving = false;
    }
  }

  Future<void> _done() async {
    await _save();
    _focusNode.unfocus();
  }

  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() {
              _listening = false;
              _dictationNote = 'Dictation is unavailable right now.';
            });
          }
        },
      );
      if (!available) {
        if (mounted) {
          setState(
              () => _dictationNote = 'Dictation is unavailable on this device.');
        }
        return;
      }
      setState(() {
        _listening = true;
        _dictationNote = null;
        _dictationBase = _composer.text;
      });
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(minutes: 5),
          pauseFor: const Duration(seconds: 30),
        ),
        onResult: (result) {
          final words = result.recognizedWords;
          final needsSpace = _dictationBase.isNotEmpty &&
              !_dictationBase.endsWith(' ') &&
              words.isNotEmpty;
          _composer.value = TextEditingValue(
            text: _dictationBase + (needsSpace ? ' ' : '') + words,
            selection: TextSelection.collapsed(
              offset: _dictationBase.length +
                  (needsSpace ? 1 : 0) +
                  words.length,
            ),
          );
          _spokenUsed = true;
          _onChanged(_composer.text);
          if (result.finalResult) _dictationBase = _composer.text;
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _dictationNote = 'Dictation is unavailable right now.';
        });
      }
    }
  }

  /// Cached so rebuilds (every keystroke) never resubscribe the
  /// StreamBuilder.
  Stream<List<JournalEntryRow>> _entriesFor(
      AppDatabase db, DateTime now) {
    final today = eterIsoDate(now);
    if (_entriesStream == null || _streamedDay != today) {
      _streamedDay = today;
      final (dayStart, dayEnd) = eterDayBounds(now);
      _entriesStream = db.watchJournalForRange(dayStart, dayEnd);
    }
    return _entriesStream!;
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final now = ref.watch(nowProvider)();
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);

    final proseStyle = text.headlineSmall?.copyWith(
      fontSize: 19,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    final composing = _composer.text.isNotEmpty || _focusNode.hasFocus;

    return SurfaceIntentScope(
      intent: SurfaceIntent.plain,
      child: Stack(
        children: [
          const Positioned.fill(child: _ParchmentField()),
          // Tapping the open page starts writing. Child recognizers (the
          // field, the actions) win their own regions; the empty page belongs
          // to this one.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _focusNode.requestFocus,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: EterSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: EterSpace.s24),
                  Text(_dateHeading.format(now), style: text.headlineSmall),
                  const SizedBox(height: EterSpace.s16),
                  TextField(
                    controller: _composer,
                    focusNode: _focusNode,
                    onChanged: _onChanged,
                    style: proseStyle,
                    cursorColor: ink.lineStrong,
                    cursorWidth: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration.collapsed(
                      hintText: 'What is asking for your attention?',
                      hintStyle: proseStyle?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: ink.labelMuted.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: EterSpace.s8),
                  // Privacy inclusion is a marginal note beneath the entry,
                  // not a toggle row interrupting the writing.
                  Row(
                    children: [
                      _SquareSwitch(
                        value: !_excluded,
                        semanticLabel: 'Include this entry in Aether guidance',
                        onChanged: (include) =>
                            setState(() => _excluded = !include),
                      ),
                      Expanded(
                        child: Text(
                          _excluded
                              ? 'Kept from Aether'
                              : 'Included in Aether guidance',
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _GlyphAction(
                        icon: _listening ? Icons.mic : Icons.mic_none,
                        semanticLabel:
                            _listening ? 'Stop dictation' : 'Dictate',
                        color: _listening ? ink.lineStrong : ink.labelMuted,
                        onTap: _toggleDictation,
                      ),
                      if (_listening)
                        Text('Listening…', style: text.bodySmall),
                      if (_dictationNote != null)
                        Expanded(
                          child: Text(_dictationNote!, style: text.bodySmall),
                        ),
                      const Spacer(),
                      if (composing)
                        EterAction(
                          label: 'Done',
                          emphasis: EterActionEmphasis.quiet,
                          onPressed: _done,
                        ),
                    ],
                  ),
                  const SizedBox(height: EterSpace.s24),
                  StreamBuilder<List<JournalEntryRow>>(
                    stream: _entriesFor(db, now),
                    builder: (context, snapshot) {
                      final entries =
                          snapshot.data ?? const <JournalEntryRow>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in entries)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: EterSpace.s24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _marginalTime.format(entry.createdAt) +
                                        (entry.excludedFromAi
                                            ? '  ·  Kept from Aether'
                                            : ''),
                                    style: text.labelSmall,
                                  ),
                                  const SizedBox(height: EterSpace.s4),
                                  EterArrival.single(
                                    entry.entryText,
                                    key: ValueKey('entry-${entry.id}'),
                                    style: proseStyle,
                                    playArrival:
                                        _arrivingIds.contains(entry.id),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: EterSpace.s64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The writing region: a warm parchment field resting on the sky, with subtle
/// grain and a soft top edge — never a complete rectangular border. Night
/// keeps a dark paper field; no constellations beneath prose.
class _ParchmentField extends StatelessWidget {
  const _ParchmentField();

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final paper = night
        ? EterColors.night900.withValues(alpha: 0.55)
        : EterColors.parchment.withValues(alpha: 0.94);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.06, 1],
                colors: [
                  paper.withValues(alpha: 0),
                  paper,
                  paper,
                ],
              ),
            ),
          ),
          Opacity(
            opacity: night ? 0.04 : 0.06,
            child: Image.asset(
              'assets/art/grain-subtle.webp',
              repeat: ImageRepeat.repeat,
              filterQuality: FilterQuality.low,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small conventional glyph with a 48×48 dp hit region — the borderless
/// action form for dictation. The visible label lives in semantics.
class _GlyphAction extends StatelessWidget {
  const _GlyphAction({
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(icon, size: 22, color: color)),
        ),
      ),
    );
  }
}

/// A square, mechanical instrument switch — the house toggle form from
/// `docs/UI_DIRECTION.md`. Hairline square, a set square inside when on, and
/// an invisible 48 dp target.
class _SquareSwitch extends StatelessWidget {
  const _SquareSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return Semantics(
      button: true,
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: EterMotion.durMicro,
              curve: EterMotion.easeAir,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? ink.wash : Colors.transparent,
                border: Border.all(
                  color: value ? ink.lineStrong : ink.line,
                  width: 1.2,
                ),
              ),
              child: value
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        color: ink.lineStrong,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
