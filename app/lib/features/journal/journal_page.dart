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
import '../../core/lifestyle/daily_check_in.dart';
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
                    Row(
                      children: [
                        _GlyphAction(
                          label: _listening ? 'Stop dictation' : 'Dictate',
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
                      ],
                    ),
                  ],
                  const SizedBox(height: EterSpace.s24),
                  // The day's self-report lives here, in the margin of the
                  // writing, and nowhere else (steering decision, 28 July
                  // 2026). Body reads these rows; it does not collect them.
                  _MarginCheckIns(
                    key: ValueKey('check-ins-${eterIsoDate(selectedDay)}'),
                    day: selectedDay,
                    editable: isToday,
                  ),
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

/// The day's self-report, written in the Journal's margin.
///
/// Deliberately not a check-in card: no panel, no heading, no completion
/// state, no streak. At rest it is one quiet line per prompt — the prompt word
/// and either the day's answer or a single em dash. Tapping a prompt opens its
/// rail in place; answering closes it again. A historical page shows the same
/// line, read-only, and says nothing at all when the day holds no answers.
class _MarginCheckIns extends ConsumerStatefulWidget {
  const _MarginCheckIns({
    super.key,
    required this.day,
    required this.editable,
  });

  final DateTime day;
  final bool editable;

  @override
  ConsumerState<_MarginCheckIns> createState() => _MarginCheckInsState();
}

class _MarginCheckInsState extends ConsumerState<_MarginCheckIns> {
  Stream<List<LifestyleEntryRow>>? _stream;
  String? _streamedDay;
  String? _openPrompt;
  final _minutes = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  /// Cached exactly like the entries stream: Drift hands back a fresh stream
  /// per call, and this widget rebuilds on every keystroke of the page above.
  Stream<List<LifestyleEntryRow>> _entries(AppDatabase db) {
    final date = eterIsoDate(widget.day);
    if (_stream == null || _streamedDay != date) {
      _streamedDay = date;
      final (start, end) = eterDayBounds(widget.day);
      _stream = db.watchLifestyleForRange(start, end);
    }
    return _stream!;
  }

  LifestyleCheckInService _service() =>
      LifestyleCheckInService(ref.read(databaseProvider));

  Future<void> _answer(LifestyleReading reading, int mark) async {
    final now = ref.read(nowProvider)();
    await _service().recordReading(
      reading: reading,
      value: mark,
      day: widget.day,
      recordedAt: now,
    );
    if (!mounted) return;
    setState(() {
      _openPrompt = null;
      _message = null;
    });
    unawaited(EterHaptics.light());
  }

  Future<void> _logPractice(LifestylePractice practice) async {
    final minutes = double.tryParse(_minutes.text.trim().replaceAll(',', '.'));
    if (minutes == null) {
      setState(() => _message = 'Give the sitting a length in minutes.');
      return;
    }
    try {
      await _service().recordPractice(
        practice: practice,
        minutes: minutes,
        recordedAt: ref.read(nowProvider)(),
      );
    } on LifestyleCheckInException catch (error) {
      if (mounted) setState(() => _message = error.message);
      return;
    }
    if (!mounted) return;
    _minutes.clear();
    setState(() {
      _openPrompt = null;
      _message = null;
    });
    unawaited(EterHaptics.light());
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);

    return StreamBuilder<List<LifestyleEntryRow>>(
      stream: _entries(db),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <LifestyleEntryRow>[];
        LifestyleEntryRow? readingRow(LifestyleReading reading) {
          for (final row in rows) {
            if (row.kind == reading.kind && row.value != null) return row;
          }
          return null;
        }

        double practiceMinutes(LifestylePractice practice) {
          var total = 0.0;
          for (final row in rows) {
            if (row.kind == practice.kind) total += row.durationMinutes ?? 0;
          }
          return total;
        }

        final answered = rows.isNotEmpty;
        if (!widget.editable && !answered) return const SizedBox.shrink();

        String? readingAnswer(LifestyleReading reading) {
          final row = readingRow(reading);
          if (row == null) return null;
          return LifestyleReading.marks[row.value!.round() - 1];
        }

        String? practiceAnswer(LifestylePractice practice) {
          final minutes = practiceMinutes(practice);
          return minutes <= 0 ? null : '${minutes.round()} min';
        }

        // Marginal, not listed: the prompts flow across the page rather than
        // stacking into a five-row questionnaire under the writing. Whatever
        // is open unfolds beneath them, at full width, one at a time.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                for (final reading in LifestyleReading.values)
                  _MarginPrompt(
                    label: reading.label,
                    answer: readingAnswer(reading),
                    open: _openPrompt == reading.kind,
                    editable: widget.editable,
                    onTap: () => setState(() {
                      _message = null;
                      _openPrompt =
                          _openPrompt == reading.kind ? null : reading.kind;
                    }),
                  ),
                for (final practice in LifestylePractice.values)
                  _MarginPrompt(
                    label: practice.label,
                    answer: practiceAnswer(practice),
                    open: _openPrompt == practice.kind,
                    editable: widget.editable,
                    onTap: () => setState(() {
                      _message = null;
                      _minutes.clear();
                      _openPrompt =
                          _openPrompt == practice.kind ? null : practice.kind;
                    }),
                  ),
              ],
            ),
            for (final reading in LifestyleReading.values)
              if (_openPrompt == reading.kind)
                _MarkRail(
                  selected: readingRow(reading)?.value?.round(),
                  onSelect: (mark) => _answer(reading, mark),
                  promptLabel: reading.label,
                ),
            for (final practice in LifestylePractice.values)
              if (_openPrompt == practice.kind)
                Row(
                  children: [
                    SizedBox(
                      width: 108,
                      child: TextField(
                        key: ValueKey('practice-minutes-${practice.kind}'),
                        controller: _minutes,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _logPractice(practice),
                        style: text.bodyMedium,
                        decoration: InputDecoration(
                          labelText: '${practice.label} minutes',
                        ),
                      ),
                    ),
                    const SizedBox(width: EterSpace.s8),
                    EterAction(
                      label: 'Keep',
                      emphasis: EterActionEmphasis.quiet,
                      onPressed: () => _logPractice(practice),
                    ),
                  ],
                ),
            if (_message != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: text.bodySmall?.copyWith(color: ink.labelMuted),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One marginal annotation: the prompt word above its answer, or above a
/// single em dash when the day has not answered it. On a historical page the
/// same annotation is inert.
class _MarginPrompt extends StatelessWidget {
  const _MarginPrompt({
    required this.label,
    required this.answer,
    required this.open,
    required this.editable,
    required this.onTap,
  });

  final String label;
  final String? answer;
  final bool open;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final annotation = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: text.labelSmall?.copyWith(
            color: open ? ink.label : null,
          ),
        ),
        Text(
          answer ?? '—',
          style: text.bodySmall?.copyWith(
            color: answer == null ? ink.labelMuted : ink.label,
          ),
        ),
      ],
    );
    if (!editable) {
      return SizedBox(
        width: 116,
        height: 48,
        child: annotation,
      );
    }
    return Semantics(
      button: true,
      expanded: open,
      label: answer == null
          ? '$label not recorded today'
          : '$label today: $answer',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(width: 116, height: 48, child: annotation),
      ),
    );
  }
}

/// Five engraved marks, low to high. Not a slider and not a row of chips: the
/// measure device the instruments already use, at reading size.
class _MarkRail extends StatelessWidget {
  const _MarkRail({
    required this.selected,
    required this.onSelect,
    required this.promptLabel,
  });

  final int? selected;
  final ValueChanged<int> onSelect;
  final String promptLabel;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return Row(
      children: [
        for (var mark = 1; mark <= LifestyleReading.marks.length; mark++)
          Semantics(
            button: true,
            selected: mark == selected,
            label: '$promptLabel ${LifestyleReading.marks[mark - 1]}',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(mark),
              child: SizedBox(
                width: 44,
                height: 48,
                child: CustomPaint(
                  painter: _MarkPainter(
                    filled: mark == selected,
                    height: 8.0 + mark * 3,
                    color: mark == selected ? ink.lineStrong : ink.line,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.filled,
    required this.height,
    required this.color,
  });

  final bool filled;
  final double height;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = filled ? 1.4 : 1
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    final baseline = size.height / 2 + 8;
    canvas.drawLine(Offset(x, baseline), Offset(x, baseline - height), paint);
    if (filled) {
      canvas.drawCircle(
        Offset(x, baseline - height - 4),
        2,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.filled != filled || old.height != height || old.color != color;
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
