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
import '../../core/icons.dart';
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
  DateTime? _selectedDay;

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

  /// Everything already written, one day at a time.
  ///
  /// The page itself is for today; this is the archive, and archives belong
  /// behind a door. Day navigation lives here too, which is why the two
  /// page-turn marks left the header — turning pages *is* reading history.
  Future<void> _openHistory(DateTime day, DateTime now) async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
    }
    if (_composer.text.trim().isNotEmpty) await _save();
    if (!mounted) return;
    final today = DateTime(now.year, now.month, now.day);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JournalHistorySheet(
        db: ref.read(databaseProvider),
        initialDay: day,
        today: today,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: EterSpace.gutter,
              ),
              // One screen, and it does not scroll. The story takes whatever
              // height is left over and fits itself to it; the writing field
              // and its one action sit on the floor of the page, where a hand
              // already is. Everything already written is a tap away behind
              // HISTORY rather than a column below the fold — a journal you
              // scroll through is an archive, and this page is for today.
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
                      _GlyphAction(
                        label: 'History',
                        semanticLabel: 'Open journal history',
                        color: ink.labelMuted,
                        onTap: () => _openHistory(selectedDay, now),
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: EterSpace.s16),
                  Expanded(
                    child: _DayStory(
                      key: _storyKey,
                      day: selectedDay,
                      isToday: isToday,
                      proseStyle: proseStyle,
                    ),
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
                          minLines: 4,
                          maxLines: 6,
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
                    // reading path.
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
                          mark: true,
                          markActive: _listening,
                        ),
                      ],
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: EterSpace.s16),
                      child: Text(
                        'This page is closed. Today’s page is the one you can '
                        'write on.',
                        style: text.bodySmall,
                      ),
                    ),
                  const SizedBox(height: EterSpace.s16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prose that fits the height it is given.
///
/// The Journal is one screen that does not scroll, so the story has to hold
/// whatever it says inside whatever room is left after the date and the
/// writing field. Rather than truncating — a story cut mid-sentence is worse
/// than a small one — the type steps down until the whole passage fits, and
/// stops at a floor where it would stop being reading.
///
/// A binary search over point size, measured with the real [TextPainter], is
/// the only way to know: line breaking depends on the face, the width and the
/// user's own text scale, none of which can be estimated.
class _FittedProse extends StatelessWidget {
  const _FittedProse({
    required this.text,
    required this.style,
    required this.arrivalKey,
    required this.playArrival,
  });

  final String text;
  final TextStyle? style;
  final Key arrivalKey;
  final bool playArrival;

  /// Below this the passage stops being editorial prose and becomes fine
  /// print. A story this long is rare; the parser caps it at 700 characters.
  static const double minimumFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle();
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = base.fontSize ?? 19;
        if (constraints.maxHeight.isFinite) {
          var low = minimumFontSize;
          var high = size;
          bool fits(double candidate) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: base.copyWith(
                fontSize: scaler.scale(candidate),
              )),
              textDirection: Directionality.of(context),
            )..layout(maxWidth: constraints.maxWidth);
            return painter.height <= constraints.maxHeight;
          }

          if (!fits(high)) {
            // Eight halvings resolve a 6-point range to well under a tenth of
            // a point, which is finer than the eye or the layout can tell.
            for (var i = 0; i < 8; i++) {
              final mid = (low + high) / 2;
              if (fits(mid)) {
                low = mid;
              } else {
                high = mid;
              }
            }
            size = low;
          }
        }
        return Align(
          alignment: Alignment.topLeft,
          child: EterArrival.single(
            text,
            key: arrivalKey,
            style: base.copyWith(fontSize: size),
            playArrival: playArrival,
          ),
        );
      },
    );
  }
}

/// The archive: one day at a time, with its story and its pages.
///
/// A sheet rather than a route, because it is a drawer pulled out of the page
/// and pushed back in. `rSheet` is one of the two radii the system allows, and
/// this is what it is for.
class _JournalHistorySheet extends ConsumerStatefulWidget {
  const _JournalHistorySheet({
    required this.db,
    required this.initialDay,
    required this.today,
  });

  final AppDatabase db;
  final DateTime initialDay;
  final DateTime today;

  @override
  ConsumerState<_JournalHistorySheet> createState() =>
      _JournalHistorySheetState();
}

class _JournalHistorySheetState extends ConsumerState<_JournalHistorySheet> {
  late DateTime _day = widget.initialDay;
  Stream<List<JournalEntryRow>>? _entries;
  String? _streamedDay;

  static final _marginal = DateFormat('HH:mm');

  Stream<List<JournalEntryRow>> _entriesFor(DateTime day) {
    final date = eterIsoDate(day);
    if (_entries == null || _streamedDay != date) {
      _streamedDay = date;
      final (start, end) = eterDayBounds(day);
      _entries = widget.db.watchJournalForRange(start, end);
    }
    return _entries!;
  }

  void _move(int delta) {
    final target = _day.add(Duration(days: delta));
    if (target.isAfter(widget.today)) return;
    setState(() => _day = target);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final night = Theme.of(context).brightness == Brightness.dark;
    final proseStyle = text.headlineSmall?.copyWith(
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    final isToday = eterIsoDate(_day) == eterIsoDate(widget.today);

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: night
              ? EterColors.night900.withValues(alpha: 0.97)
              : EterColors.parchment,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(EterSpace.rSheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EterSpace.gutter,
              vertical: EterSpace.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('HISTORY', style: text.labelSmall),
                    ),
                    _GlyphAction(
                      label: 'Close',
                      semanticLabel: 'Close history',
                      color: ink.labelMuted,
                      onTap: () => Navigator.of(context).pop(),
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: EterSpace.s8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE d MMMM').format(_day),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineSmall,
                      ),
                    ),
                    _DayTurn(
                      direction: _DayTurnDirection.earlier,
                      semanticLabel: 'Previous journal day',
                      onTap: () => _move(-1),
                    ),
                    _DayTurn(
                      direction: _DayTurnDirection.later,
                      semanticLabel: isToday
                          ? 'Next journal day unavailable'
                          : 'Next journal day',
                      onTap: isToday ? null : () => _move(1),
                    ),
                  ],
                ),
                const SizedBox(height: EterSpace.s8),
                Expanded(
                  child: StreamBuilder<List<JournalEntryRow>>(
                    stream: _entriesFor(_day),
                    builder: (context, snapshot) {
                      final entries =
                          snapshot.data ?? const <JournalEntryRow>[];
                      if (entries.isEmpty) {
                        return Text(
                          'Nothing was written on this page.',
                          style: proseStyle?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: ink.labelMuted,
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: EterSpace.s32),
                        itemCount: entries.length,
                        itemBuilder: (context, index) => _JournalPassage(
                          key: ValueKey('history-${entries[index].id}'),
                          entry: entries[index],
                          db: widget.db,
                          time: _marginal.format(entries[index].createdAt),
                          proseStyle: proseStyle,
                          playArrival: false,
                        ),
                      );
                    },
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
          // The space stays the story's whether or not one exists yet, so the
          // writing field does not travel up the page and back down again
          // when the day's first story arrives.
          return const SizedBox.expand();
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
              Expanded(
                child: _FittedProse(
                  text: row.story,
                  style: widget.proseStyle?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: ink.label,
                  ),
                  arrivalKey: ValueKey('story-${row.sourceFingerprint}'),
                  playArrival: arriving,
                ),
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
      final outcome = await JournalClassifier(
        database: widget.db,
        provider: provider,
      ).classify(widget.entry.id, clarification: answer);
      if (!mounted) return;
      _clarification.clear();
      setState(() {
        _busy = false;
        _message = _outcomeMessage(outcome);
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

  /// Says what actually happened, in the order the person cares about: what
  /// still needs them, then what was written, then what could not be.
  String _outcomeMessage(JournalClassificationOutcome outcome) {
    final result = outcome.classification;
    if (result.status == 'needsDetail') {
      return 'Aether needs one detail before applying anything.';
    }

    final written = <String>[];
    final body = outcome.body;
    if (body != null) {
      if (body.weights > 0) written.add('a weight');
      if (body.activities > 0) {
        written.add(body.activities == 1 ? 'an activity' : 'activities');
      }
      if (body.workouts > 0) written.add('a workout');
    }
    if (result.food.isNotEmpty) written.add('food waiting for review in Body');

    final sentence = switch (written.length) {
      0 => result.lifestyle.isEmpty
          ? 'The entry was interpreted.'
          : 'The entry was interpreted and logged.',
      1 => 'Recorded ${written.first}.',
      _ =>
        'Recorded ${written.take(written.length - 1).join(', ')} and ${written.last}.',
    };

    final failures = body?.failures ?? const <String>[];
    return failures.isEmpty ? sentence : '$sentence ${failures.first}';
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
    this.mark = false,
    this.markActive = false,
  });

  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  /// Draws the dictation mark before the word. Only dictation carries a glyph:
  /// it is the one action here that names a device rather than an intention.
  final bool mark;
  final bool markActive;

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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mark) ...[
                    EterMicMark(size: 15, active: markActive, color: color),
                    const SizedBox(width: EterSpace.s8),
                  ],
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                          ),
                    ),
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
