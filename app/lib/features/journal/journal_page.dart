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
import '../../core/journal/day_story.dart';
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
  final _storyKey = GlobalKey<_DayStoryState>();
  Stream<List<JournalEntryRow>>? _entriesStream;
  String? _streamedDay;
  DateTime? _selectedDay;

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
      // The day now reads differently, so its story is stale.
      unawaited(_storyKey.currentState?.refresh() ?? Future<void>.value());
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
  Stream<List<JournalEntryRow>> _entriesFor(AppDatabase db, DateTime day) {
    final date = eterIsoDate(day);
    if (_entriesStream == null || _streamedDay != date) {
      _streamedDay = date;
      final (dayStart, dayEnd) = eterDayBounds(day);
      _entriesStream = db.watchJournalForRange(dayStart, dayEnd);
    }
    return _entriesStream!;
  }

  Future<void> _moveDay(int delta, DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final current = _selectedDay ?? today;
    final target = current.add(Duration(days: delta));
    if (target.isAfter(today)) return;

    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
    }
    if (_selectedDay == null && _composer.text.trim().isNotEmpty) {
      await _save();
    }
    if (!mounted) return;
    setState(() {
      _selectedDay = target == today ? null : target;
      _arrivingIds.clear();
      _dictationNote = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final now = ref.watch(nowProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = _selectedDay ?? today;
    final isToday = _selectedDay == null;
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
            onTap: isToday ? _focusNode.requestFocus : null,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: EterSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: EterSpace.s24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE')
                                  .format(selectedDay)
                                  .toUpperCase(),
                              style: text.labelSmall,
                            ),
                            const SizedBox(height: EterSpace.s4),
                            Text(
                              DateFormat('d MMMM').format(selectedDay),
                              style: text.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      _DayTurn(
                        direction: _DayTurnDirection.earlier,
                        semanticLabel: 'Previous journal day',
                        onTap: () => _moveDay(-1, now),
                      ),
                      _DayTurn(
                        direction: _DayTurnDirection.later,
                        semanticLabel: isToday
                            ? 'Next journal day unavailable'
                            : 'Next journal day',
                        onTap: isToday ? null : () => _moveDay(1, now),
                      ),
                    ],
                  ),
                  const SizedBox(height: EterSpace.s16),
                  _DayStory(
                    key: _storyKey,
                    day: selectedDay,
                    isToday: isToday,
                    proseStyle: proseStyle,
                  ),
                  if (isToday) ...[
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
                    // Under the field it belongs to, at the end of the line —
                    // where a hand already is after writing, and out of the
                    // reading path. Compact: the word only, with its 48 dp
                    // target invisible around it.
                    Row(
                      children: [
                        if (_listening)
                          Text('Listening…', style: text.bodySmall)
                        else if (_dictationNote != null)
                          Expanded(
                            child: Text(_dictationNote!, style: text.bodySmall),
                          ),
                        const Spacer(),
                        _GlyphAction(
                          label: _listening ? 'Stop' : 'Dictate',
                          semanticLabel:
                              _listening ? 'Stop dictation' : 'Dictate',
                          color: _listening ? ink.lineStrong : ink.labelMuted,
                          onTap: _toggleDictation,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: EterSpace.s24),
                  StreamBuilder<List<JournalEntryRow>>(
                    stream: _entriesFor(db, selectedDay),
                    builder: (context, snapshot) {
                      final entries =
                          snapshot.data ?? const <JournalEntryRow>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isToday && entries.isEmpty)
                            Text(
                              'Nothing was written on this page.',
                              style: proseStyle?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: ink.labelMuted,
                              ),
                            ),
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

/// The day, read back — the first thing on the Journal page and always there.
///
/// It is not a header and not a card: a short passage in the page's own prose,
/// set apart by a hairline beneath rather than a box around. It arrives through
/// the shared reveal the first time it appears, like everything else Aether
/// writes.
///
/// Refreshed when the Journal opens and again after each entry saves. Both are
/// cheap: the composer fingerprints the day's prose and returns the stored row
/// untouched when nothing has changed.
class _DayStory extends ConsumerStatefulWidget {
  const _DayStory({
    super.key,
    required this.day,
    required this.isToday,
    required this.proseStyle,
  });

  final DateTime day;
  final bool isToday;
  final TextStyle? proseStyle;

  @override
  ConsumerState<_DayStory> createState() => _DayStoryState();
}

class _DayStoryState extends ConsumerState<_DayStory> {
  Stream<JournalDayStoryRow?>? _stream;
  String? _streamedDay;
  String? _lastRefreshedFingerprint;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The story for the page being opened, not for whatever was open before.
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  @override
  void didUpdateWidget(covariant _DayStory old) {
    super.didUpdateWidget(old);
    if (eterIsoDate(old.day) != eterIsoDate(widget.day)) refresh();
  }

  /// Recomposes the day if its prose has changed. Silent throughout: a story
  /// is something the page has, not a task the reader is waiting on.
  Future<void> refresh() async {
    if (_busy || !mounted) return;
    final provider = ref.read(journalDayStoryProvider);
    if (provider == null) return;
    _busy = true;
    try {
      await JournalDayStoryComposer(
        database: ref.read(databaseProvider),
        provider: provider,
      ).refresh(day: widget.day, now: ref.read(nowProvider)());
    } catch (_) {
      // A story that cannot be written changes nothing about the page. The
      // previous one, if any, stays.
    } finally {
      _busy = false;
    }
  }

  Stream<JournalDayStoryRow?> _storyFor(AppDatabase db) {
    final date = eterIsoDate(widget.day);
    if (_stream == null || _streamedDay != date) {
      _streamedDay = date;
      _stream = db.watchDayStory(date);
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;

    return StreamBuilder<JournalDayStoryRow?>(
      stream: _storyFor(db),
      builder: (context, snapshot) {
        final row = snapshot.data;
        if (row == null || row.story.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        final arriving = _lastRefreshedFingerprint != null &&
            _lastRefreshedFingerprint != row.sourceFingerprint;
        _lastRefreshedFingerprint = row.sourceFingerprint;
        return Padding(
          padding: const EdgeInsets.only(bottom: EterSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Everything Aether writes is attributed. Unlabelled italic
              // prose above someone's own journal reads as their own writing,
              // which is the one thing it must never be mistaken for.
              Text('THE DAY SO FAR', style: text.labelSmall),
              const SizedBox(height: EterSpace.s8),
              EterArrival.single(
                row.story,
                key: ValueKey('story-${row.sourceFingerprint}'),
                style: widget.proseStyle?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: ink.label,
                ),
                playArrival: arriving,
              ),
              const SizedBox(height: EterSpace.s12),
              Container(height: 1, width: 64, color: ink.line),
            ],
          ),
        );
      },
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
    this.compact = false,
  });

  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  /// Sizes to the word instead of reserving a fixed column, while keeping the
  /// 48 dp target. Used where the action sits at the end of a line rather than
  /// at the head of one.
  final bool compact;

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
          width: compact ? null : 112,
          height: 48,
          child: Align(
            alignment:
                compact ? Alignment.centerRight : Alignment.centerLeft,
            widthFactor: compact ? 1 : null,
            child: Padding(
              padding: compact
                  ? const EdgeInsets.symmetric(horizontal: EterSpace.s8)
                  : EdgeInsets.zero,
              child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _DayTurnDirection { earlier, later }

/// A journal page-turn mark: one bead and a short engraved thread. It keeps
/// older dates discoverable without introducing calendar chrome.
class _DayTurn extends StatelessWidget {
  const _DayTurn({
    required this.direction,
    required this.semanticLabel,
    required this.onTap,
  });

  final _DayTurnDirection direction;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = EterInk.of(context).labelMuted.withValues(
          alpha: onTap == null ? 0.28 : 1,
        );
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: CustomPaint(
            painter: _DayTurnPainter(
              color: color,
              direction: direction,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayTurnPainter extends CustomPainter {
  const _DayTurnPainter({
    required this.color,
    required this.direction,
  });

  final Color color;
  final _DayTurnDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final y = size.height / 2;
    final pointsEarlier = <Offset>[
      Offset(29, y - 5),
      Offset(23, y),
      Offset(29, y + 5),
    ];
    final points = direction == _DayTurnDirection.earlier
        ? pointsEarlier
        : pointsEarlier.map((point) => Offset(size.width - point.dx, point.dy));
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
    final beadX = direction == _DayTurnDirection.earlier ? 34.0 : 14.0;
    canvas.drawLine(
      Offset(direction == _DayTurnDirection.earlier ? 23 : 25, y),
      Offset(beadX - (direction == _DayTurnDirection.earlier ? 3 : -3), y),
      paint,
    );
    canvas.drawCircle(Offset(beadX, y), 1.5, paint);
  }

  @override
  bool shouldRepaint(_DayTurnPainter old) =>
      old.color != color || old.direction != direction;
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
