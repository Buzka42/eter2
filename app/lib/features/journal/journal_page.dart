import 'dart:async';
import 'dart:convert';

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
import '../../core/journal/classification_contract.dart';
import '../../core/journal/classifier.dart';
import '../../core/register.dart';
import '../../core/tokens.dart';
import '../../main.dart';

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
  bool _spokenUsed = false;
  bool _listening = false;
  String? _dictationNote;
  String _dictationBase = '';
  Stream<List<JournalEntryRow>>? _entriesStream;
  String? _streamedDay;

  static final _marginalTime = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _composer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {}); // Dictation and autosave feedback follow the draft.
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
        ),
      );
      if (!mounted) return;
      setState(() {
        _arrivingIds.add(id);
        _composer.clear();
        _spokenUsed = false;
      });
      // Haptics confirm the save but must never hold the page in its composing
      // state when a platform channel is slow or unavailable.
      unawaited(EterHaptics.light());
    } finally {
      _saving = false;
    }
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
          setState(() =>
              _dictationNote = 'Dictation is unavailable on this device.');
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
              offset:
                  _dictationBase.length + (needsSpace ? 1 : 0) + words.length,
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
  Stream<List<JournalEntryRow>> _entriesFor(AppDatabase db, DateTime now) {
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final writingLineHeight = 28.5 * textScale;

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
                  Text(
                    DateFormat('EEEE').format(now).toUpperCase(),
                    style: text.labelSmall,
                  ),
                  const SizedBox(height: EterSpace.s4),
                  Text(
                    DateFormat('d MMMM').format(now),
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: EterSpace.s16),
                  Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _WritingLinesPainter(
                              color: ink.line.withValues(alpha: 0.3),
                              spacing: writingLineHeight,
                            ),
                          ),
                        ),
                      ),
                      TextField(
                        controller: _composer,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        style: proseStyle,
                        cursorColor: ink.lineStrong,
                        cursorWidth: 1,
                        minLines: 6,
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
                    ],
                  ),
                  const SizedBox(height: EterSpace.s4),
                  Row(
                    children: [
                      _GlyphAction(
                        label: _listening ? 'Stop dictation' : 'Dictate',
                        semanticLabel:
                            _listening ? 'Stop dictation' : 'Dictate',
                        color: _listening ? ink.lineStrong : ink.labelMuted,
                        onTap: _toggleDictation,
                      ),
                      if (_listening) Text('Listening…', style: text.bodySmall),
                      if (_dictationNote != null)
                        Expanded(
                          child: Text(_dictationNote!, style: text.bodySmall),
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
                            _JournalPassage(
                              key: ValueKey('passage-${entry.id}'),
                              entry: entry,
                              db: db,
                              time: _marginalTime.format(entry.createdAt),
                              proseStyle: proseStyle,
                              playArrival: _arrivingIds.contains(entry.id),
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

class _JournalPassage extends ConsumerStatefulWidget {
  const _JournalPassage({
    super.key,
    required this.entry,
    required this.db,
    required this.time,
    required this.proseStyle,
    required this.playArrival,
  });

  final JournalEntryRow entry;
  final AppDatabase db;
  final String time;
  final TextStyle? proseStyle;
  final bool playArrival;

  @override
  ConsumerState<_JournalPassage> createState() => _JournalPassageState();
}

class _JournalPassageState extends ConsumerState<_JournalPassage> {
  final _clarification = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _clarification.dispose();
    super.dispose();
  }

  String? get _question {
    final raw = widget.entry.extractionJson;
    if (widget.entry.status != 'needsDetail' || raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      final question = decoded is Map<String, dynamic>
          ? decoded['clarifyingQuestion']
          : null;
      return question is String && question.trim().isNotEmpty
          ? question.trim()
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _interpret() async {
    if (_busy) return;
    final provider = ref.read(journalClassificationProvider);
    if (provider == null) {
      setState(() {
        _message = 'Journal interpretation is not connected on this build yet.';
      });
      return;
    }
    final answer = _question == null ? null : _clarification.text.trim();
    if (_question != null && (answer == null || answer.isEmpty)) {
      setState(() => _message = 'Add a little more detail first.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await JournalClassifier(
        database: widget.db,
        provider: provider,
      ).classify(widget.entry.id, clarification: answer);
      if (!mounted) return;
      _clarification.clear();
      setState(() {
        _busy = false;
        _message = result.status == 'needsDetail'
            ? 'Aether needs one detail before applying anything.'
            : result.food.isEmpty
                ? 'The entry was interpreted.'
                : 'Food estimates are waiting for review in Body.';
      });
    } on JournalClassificationConsentException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message =
            'Enable AI guidance in the Sanctum before sending this entry.';
      });
    } on JournalClassificationException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'This entry could not be interpreted safely. Try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Interpretation is unavailable right now. Nothing changed.';
      });
    }
  }

  Future<void> _undo() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    await widget.db.revertJournalEntryRows(widget.entry.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = 'The interpretation and its derived records were removed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final interpreted = widget.entry.status == 'classified';
    final question = _question;
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.time +
                (widget.entry.excludedFromAi ? '  ·  Kept from Aether' : ''),
            style: text.labelSmall,
          ),
          const SizedBox(height: EterSpace.s4),
          EterArrival.single(
            widget.entry.entryText,
            key: ValueKey('entry-${widget.entry.id}'),
            style: widget.proseStyle,
            playArrival: widget.playArrival,
          ),
          Wrap(
            spacing: EterSpace.s8,
            children: [
              _GlyphAction(
                label:
                    widget.entry.excludedFromAi ? 'Allow Aether' : 'Keep local',
                semanticLabel: widget.entry.excludedFromAi
                    ? 'Allow this journal entry in Aether guidance'
                    : 'Keep this journal entry out of Aether guidance',
                color: ink.labelMuted,
                onTap: () => widget.db.setJournalExcludedFromAi(
                  widget.entry.id,
                  !widget.entry.excludedFromAi,
                ),
              ),
              _GlyphAction(
                label: interpreted ? 'Undo interpretation' : 'Interpret',
                semanticLabel: interpreted
                    ? 'Remove interpretation and derived records'
                    : 'Interpret food and wellbeing details in this entry',
                color: ink.labelMuted,
                onTap: interpreted ? _undo : _interpret,
              ),
            ],
          ),
          if (question != null) ...[
            Text(question, style: text.bodyMedium),
            const SizedBox(height: EterSpace.s4),
            TextField(
              key: ValueKey('journal-clarification-${widget.entry.id}'),
              controller: _clarification,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _interpret(),
              decoration:
                  const InputDecoration(labelText: 'Add the missing detail'),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: EterSpace.s4),
            Semantics(
              liveRegion: true,
              child: Text(_message!, style: text.bodySmall),
            ),
          ],
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
                stops: const [0, 0.12, 1],
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
    required this.label,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 112,
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WritingLinesPainter extends CustomPainter {
  const _WritingLinesPainter({required this.color, required this.spacing});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 0.7;
    for (var y = spacing - 2; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_WritingLinesPainter old) =>
      old.color != color || old.spacing != spacing;
}
