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
import '../../core/health/record_error.dart';
import '../../core/i18n/dictation.dart';
import '../../core/i18n/language.dart';
import '../../core/i18n/strings.dart';
import '../../core/icons.dart';
import '../../core/journal/classification_contract.dart';
import '../../core/journal/auto_interpret.dart';
import '../../core/journal/classifier.dart';
import '../../core/aether/letter.dart';
import '../../core/journal/day_story.dart';
import '../../core/instruments.dart';
import '../../core/longview/long_view.dart';
import '../../core/longview/long_view_source.dart';
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

  /// A finger is currently on the dictation mark. See [_holdDictation].
  bool _holding = false;
  String? _dictationNote;
  String _dictationBase = '';
  final _storyKey = GlobalKey<_DayStoryState>();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // Anything written before interpretation was automatic — or while the
    // endpoint was unreachable — is read when the Journal next opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_autoInterpret());
      // The app's own comings and goings are the only clock the invitation
      // has. Cheap and idempotent: it reads consent, and with none it cancels
      // and returns.
      if (mounted) {
        unawaited(
          ref
                  .read(eveningInvitationSchedulerProvider)
                  ?.sync(now: ref.read(nowProvider)()) ??
              Future<void>.value(),
        );
      }
    });
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
    // Not while dictating.
    //
    // Every recognised word came through here, so a 900 ms pause for breath
    // was indistinguishable from a pause for thought: the page saved the
    // half-spoken sentence and cleared itself, and the words appeared to
    // vanish as they were spoken. They were never lost — they were filed
    // mid-thought, which is worse than either.
    //
    // Speech has its own end, and `_finishDictation` is where it is handled.
    if (_listening) return;
    _autosave = Timer(const Duration(milliseconds: 900), _save);
  }

  /// Dictation has stopped. Now the page may keep what was said.
  ///
  /// [immediately] is push-to-talk releasing its hold. A held button says
  /// exactly when someone finished — there is no ambiguity left for a debounce to
  /// resolve — so the page is kept on release rather than 900 ms later. That
  /// difference is the whole point of holding: speak, let go, put the phone in a
  /// pocket, and the page is already filed.
  ///
  /// The timer still governs the tap path, where "stopped speaking" and
  /// "finished" are not the same event.
  void _finishDictation({bool immediately = false}) {
    if (!mounted) return;
    setState(() => _listening = false);
    _dictationBase = '';
    if (_composer.text.trim().isEmpty) return;
    _autosave?.cancel();
    if (immediately) {
      unawaited(_save());
      return;
    }
    _autosave = Timer(const Duration(milliseconds: 900), _save);
  }

  /// Push-to-talk. Held, so releasing is the commit.
  ///
  /// Deliberately *additive*: tapping still toggles, because a press-and-hold is
  /// a gesture, and non-negotiable 7 forbids putting anything essential behind
  /// one alone. Someone who cannot hold a button steady — or who never discovers
  /// that they can — loses nothing.
  ///
  /// [_holding] exists for one race, and it is not a rare one. Starting
  /// dictation is asynchronous — initialise, permission, enumerate locales — and
  /// a quick hold can be released before any of that finishes. Without the flag,
  /// the release finds `_listening` still false, returns, and the recogniser then
  /// comes up listening with nobody holding it: the microphone left open by the
  /// gesture meant to be the safe one.
  Future<void> _holdDictation() async {
    if (_listening) return;
    _holding = true;
    await _toggleDictation();
    if (!_holding && _listening) await _releaseDictation();
  }

  Future<void> _releaseDictation() async {
    _holding = false;
    if (!_listening) return;
    await _speech.stop();
    _finishDictation(immediately: true);
  }

  Future<void> _save() async {
    _autosave?.cancel();
    final text = _composer.text.trim();
    if (text.isEmpty || _saving) return;
    _saving = true;
    // Taken out of the composer *before* the first await, not after the insert
    // returns. Dictation ends through several doors — the plugin reports both
    // `notListening` and `done`, push-to-talk saves on release, and opening
    // History saves on the way out — and any two of them landing either side
    // of an await used to file the same words twice. The draft is claimed
    // here, so a second caller finds an empty page and returns.
    final spoken = _spokenUsed;
    _composer.clear();
    _spokenUsed = false;
    try {
      final db = ref.read(databaseProvider);
      final now = ref.read(nowProvider)();
      final id = await db.addJournalEntry(
        JournalEntriesCompanion.insert(
          entryText: text,
          createdAt: now,
          source: Value(spoken ? 'spoken' : 'typed'),
        ),
      );
      if (!mounted) return;
      setState(() {
        _arrivingIds.add(id);
      });
      // Haptics confirm the save but must never hold the page in its composing
      // state when a platform channel is slow or unavailable.
      unawaited(EterHaptics.light());
      // The day now reads differently, so its story is stale.
      unawaited(_storyKey.currentState?.refresh() ?? Future<void>.value());
      // And the page that was just kept is read, without being asked about.
      unawaited(_autoInterpret());
      // Somebody who has now written does not need inviting tonight. There is
      // no background job in this product, so a save is one of the few moments
      // the pending invitation can be brought up to date.
      unawaited(
        ref.read(eveningInvitationSchedulerProvider)?.sync(now: now) ??
            Future<void>.value(),
      );
    } catch (error) {
      // The words were taken out of the page to claim them; if nothing was
      // filed they have to go back, or claiming them would be how they are
      // lost.
      debugPrint('Eter journal: entry not saved: $error');
      if (mounted) {
        _composer.text = text;
        _spokenUsed = spoken;
      }
    } finally {
      _saving = false;
    }
  }

  /// Reads whatever is pending on the day in view.
  ///
  /// Unawaited by every caller: interpretation is something Eter does with a
  /// page, not something the page waits for.
  Future<void> _autoInterpret() async {
    final now = ref.read(nowProvider)();
    final day = _selectedDay ?? now;
    final (start, end) = eterDayBounds(day);
    await JournalAutoInterpreter(
      database: ref.read(databaseProvider),
      provider: ref.read(journalClassificationProvider),
    ).run(start: start.toUtc(), end: end.toUtc());
  }

  /// Which locale the recogniser should listen in, or null when it has nothing
  /// for Eter's language.
  ///
  /// The decision itself is [DictationLocale.resolve], which is pure and tested.
  /// This is only the part that has to talk to the plugin.
  Future<String?> _dictationLocaleId(AppLanguage language) async {
    final available = await _speech.locales();
    return DictationLocale.resolve(
      language: language,
      available: [for (final locale in available) locale.localeId],
    );
  }

  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stop();
      _finishDictation();
      return;
    }
    final strings = EterStrings.of(context);
    try {
      // Logged because the on-screen sentence has to stay short, and the
      // reason dictation failed is exactly what a short sentence loses.
      final available = await _speech.initialize(
        debugLogging: true,
        onStatus: (status) {
          debugPrint('Eter dictation: status $status');
          if ((status == 'done' || status == 'notListening') && mounted) {
            _finishDictation();
          }
        },
        onError: (error) {
          debugPrint(
            'Eter dictation: error ${error.errorMsg} '
            '(permanent: ${error.permanent})',
          );
          if (!mounted) return;
          setState(() {
            _listening = false;
            // The recogniser's codes are useless to a person and differ by
            // platform, so `DictationFailure` names the outcome and the string
            // table words it. Both halves are tested; a `switch` inlined here
            // was not.
            _dictationNote = strings.dictationFailure(
              DictationFailure.fromRecogniserCode(error.errorMsg),
            );
          });
          // Words spoken before the failure are still words. Ending this way
          // must keep them exactly as ending normally does.
          _finishDictation();
        },
      );
      debugPrint('Eter dictation: initialize returned $available');
      if (!available) {
        if (mounted) {
          setState(() => _dictationNote = strings.dictationNoRecogniser);
        }
        return;
      }
      final permitted = await _speech.hasPermission;
      debugPrint('Eter dictation: hasPermission $permitted');
      if (!permitted) {
        if (mounted) {
          setState(() => _dictationNote = strings.dictationNeedsMicrophone);
        }
        return;
      }
      final localeId = await _dictationLocaleId(strings.language);
      debugPrint('Eter dictation: locale $localeId');
      if (localeId == null) {
        if (mounted) {
          setState(() => _dictationNote = strings.dictationLanguageUnavailable(
                strings.language.endonym,
              ));
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _listening = true;
        _dictationNote = null;
        _dictationBase = _composer.text;
      });
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
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
    } catch (error) {
      debugPrint('Eter dictation: threw $error');
      if (mounted) {
        setState(() {
          _listening = false;
          _dictationNote = strings.dictationUnavailable;
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
    final strings = EterStrings.of(context);
    final locale = strings.language.code;

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
                              DateFormat('EEEE', locale)
                                  .format(selectedDay)
                                  .toUpperCase(),
                              style: text.labelSmall,
                            ),
                            const SizedBox(height: EterSpace.s4),
                            Text(
                              DateFormat('d MMMM', locale)
                                  .format(selectedDay),
                              style: text.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      _GlyphAction(
                        label: strings.journalHistory,
                        semanticLabel: strings.openJournalHistorySemantic,
                        color: ink.labelMuted,
                        onTap: () => _openHistory(selectedDay, now),
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: EterSpace.s16),
                  // A letter takes the page for the day it arrives. It is not a
                  // banner above the day story and not a sheet over it: it
                  // stands where Aether's prose always stands, and the writing
                  // field below is how it is answered — which is the whole
                  // reason it arrives here rather than as a notification.
                  Expanded(
                    child: _LetterArrival(
                      day: selectedDay,
                      isToday: isToday,
                      proseStyle: proseStyle,
                      otherwise: _DayStory(
                        key: _storyKey,
                        day: selectedDay,
                        isToday: isToday,
                        proseStyle: proseStyle,
                      ),
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
                            hintText: strings.writingFieldHint,
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
                          Text(strings.listening, style: text.bodySmall)
                        else if (_dictationNote != null)
                          Expanded(
                            child: Text(_dictationNote!, style: text.bodySmall),
                          ),
                        const Spacer(),
                        _GlyphAction(
                          label: _listening ? strings.stop : strings.dictate,
                          semanticLabel: _listening
                              ? strings.stopDictationSemantic
                              : strings.dictateSemantic,
                          color: _listening ? ink.lineStrong : ink.labelMuted,
                          onTap: _toggleDictation,
                          // Hold to speak, release to keep. The fastest path
                          // from wanting to say something to it being filed.
                          onHoldStart: () => unawaited(_holdDictation()),
                          onHoldEnd: () => unawaited(_releaseDictation()),
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
                        strings.thisPageIsClosed,
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
        var scrolls = false;
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
            // Below the floor the prose stops shrinking, so on a short box it
            // simply ran past the bottom — which is what the keyboard does to
            // this page: the story keeps its height budget, the field takes
            // the rest, and a long day overflowed by about thirty pixels. It
            // scrolls inside its own box instead. Nothing is cut, and the page
            // still does not scroll.
            scrolls = !fits(minimumFontSize);
          }
        }
        final prose = EterArrival.single(
          text,
          key: arrivalKey,
          style: base.copyWith(fontSize: size),
          playArrival: playArrival,
        );
        if (scrolls) {
          return SingleChildScrollView(
            child: Align(alignment: Alignment.topLeft, child: prose),
          );
        }
        return Align(alignment: Alignment.topLeft, child: prose);
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

  /// Read once when the sheet opens. A date of birth does not change while
  /// somebody is turning pages, and re-reading it on every tap would put a
  /// query behind a bead.
  DateTime? _dateOfBirth;
  Stream<List<JournalEntryRow>>? _entries;
  String? _streamedDay;

  /// A 24-hour clock in both languages: Polish never uses am/pm, and English
  /// Eter already showed 24-hour time everywhere else. Left as an explicit
  /// pattern rather than `DateFormat.jm(locale)`, which would put an English
  /// reader on a 12-hour clock and disagree with the sleep summary two screens
  /// away.
  static final _marginal = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.db.loadProfile().then((profile) {
        if (mounted) setState(() => _dateOfBirth = profile?.dob);
      }),
    );
  }

  Stream<List<JournalEntryRow>> _entriesFor(DateTime day) {
    final date = eterIsoDate(day);
    if (_entries == null || _streamedDay != date) {
      _streamedDay = date;
      final (start, end) = eterDayBounds(day);
      _entries = widget.db.watchJournalForRange(start, end);
    }
    return _entries!;
  }

  /// How far back the axis has been turned, and therefore what scale it is on.
  ///
  /// This is the whole of the Long View's navigation: there is no control for
  /// it. Keep turning back and the day widens — a fortnight out it is a week, a
  /// couple of months out a month, a year out a year. `DECISIONS.md` chose
  /// extension over a menu, and a menu is what a "zoom" button would have been.
  ///
  /// The thresholds themselves are [longViewSpanFor], which is domain rather
  /// than interface and is tested there.
  LongViewSpan? get _span => longViewSpanFor(
        DateTime(widget.today.year, widget.today.month, widget.today.day)
            .difference(DateTime(_day.year, _day.month, _day.day))
            .inDays,
      );

  /// One step along the axis, at whatever scale the axis is currently on. The
  /// beads travel further per tap the further out you are, which is what stops
  /// reaching last spring from being ninety taps.
  void _move(int delta) {
    final span = _span;
    DateTime target;
    if (span == null) {
      target = _day.add(Duration(days: delta));
    } else {
      final window = LongViewWindow.of(span, _day);
      target = delta < 0 ? window.earlier(span) : window.later(span);
    }
    // The axis stops at the day the person was born. Travel accelerates once
    // the span widens — a tap is a whole year in year mode — so without a floor
    // the beads walk off into decades that are not anybody's time.
    target = clampToFloor(target, longViewFloor(_dateOfBirth));
    if (target.isAfter(widget.today)) {
      // Stepping forward out of a wide span lands past today; the axis narrows
      // back to today rather than refusing to move.
      if (span != null) setState(() => _day = widget.today);
      return;
    }
    setState(() => _day = target);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
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
                      child: Text(strings.headingHistory,
                          style: text.labelSmall),
                    ),
                    _GlyphAction(
                      label: strings.close,
                      semanticLabel: strings.closeHistorySemantic,
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
                        _axisTitle(strings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineSmall,
                      ),
                    ),
                    _DayTurn(
                      direction: _DayTurnDirection.earlier,
                      semanticLabel: strings.previousJournalDay,
                      onTap: () => _move(-1),
                    ),
                    _DayTurn(
                      direction: _DayTurnDirection.later,
                      semanticLabel: isToday
                          ? strings.nextJournalDayUnavailable
                          : strings.nextJournalDay,
                      onTap: isToday ? null : () => _move(1),
                    ),
                  ],
                ),
                const SizedBox(height: EterSpace.s8),
                if (_span case final span?)
                  Expanded(
                    child: _LongViewPanel(
                      key: ValueKey('long-view-$span-${eterIsoDate(_day)}'),
                      db: widget.db,
                      span: span,
                      anchor: _day,
                    ),
                  )
                else
                  Expanded(
                    child: StreamBuilder<List<JournalEntryRow>>(
                    stream: _entriesFor(_day),
                    builder: (context, snapshot) {
                      final entries =
                          snapshot.data ?? const <JournalEntryRow>[];
                      if (entries.isEmpty) {
                        return Text(
                          strings.nothingWrittenOnThisPage,
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

  /// A day names itself; a wider span names its scale and its window, because
  /// "24–30 July" alone does not say whether you are looking at a week or the
  /// last seven days of a month.
  String _axisTitle(EterStrings strings) {
    final span = _span;
    if (span == null) {
      return DateFormat('EEEE d MMMM', strings.language.code).format(_day);
    }
    final window = LongViewWindow.of(span, _day);
    final locale = strings.language.code;
    final name = strings.longViewSpanName(switch (span) {
      LongViewSpan.week => LongViewSpanName.week,
      LongViewSpan.month => LongViewSpanName.month,
      LongViewSpan.year => LongViewSpanName.year,
    });
    // Abbreviated months on the year span. `MMMM yyyy` on both ends gives
    // "Year · August 1992 – July 1993", which is thirty characters and
    // ellipsised on a 1080px phone before the second year is readable — the
    // one thing the title exists to tell you.
    final pattern = span == LongViewSpan.year ? 'MMM yyyy' : 'd MMM';
    final from = DateFormat(pattern, locale).format(window.from);
    final to = DateFormat(pattern, locale).format(window.to);
    return span == LongViewSpan.month
        ? '$name · ${DateFormat('MMMM yyyy', locale).format(window.from)}'
        : '$name · $from – $to';
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
              Text(EterStrings.of(context).headingTheDaySoFar,
                  style: text.labelSmall),
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
    final strings = EterStrings.of(context);
    final provider = ref.read(journalClassificationProvider);
    if (provider == null) {
      setState(() {
        _message = strings.journalInterpretationNotConnected;
      });
      return;
    }
    final answer = _question == null ? null : _clarification.text.trim();
    if (_question != null && (answer == null || answer.isEmpty)) {
      setState(() => _message = strings.addMoreDetailFirst);
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
        _message = _outcomeMessage(outcome, strings);
      });
    } on JournalClassificationConsentException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = strings.enableAiBeforeSendingEntry;
      });
    } on JournalClassificationException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = strings.entryNotInterpretedSafely;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = strings.interpretationUnavailable;
      });
    }
  }

  /// Says what actually happened, in the order the person cares about: what
  /// still needs them, then what was written, then what could not be.
  String _outcomeMessage(
    JournalClassificationOutcome outcome,
    EterStrings strings,
  ) {
    final result = outcome.classification;
    if (result.status == 'needsDetail') return strings.aetherNeedsOneDetail;

    final written = <String>[];
    final body = outcome.body;
    if (body != null) {
      if (body.weights > 0) written.add(strings.derivedWeight);
      if (body.activities > 0) {
        written.add(body.activities == 1
            ? strings.derivedActivity
            : strings.derivedActivities);
      }
      if (body.workouts > 0) written.add(strings.derivedWorkout);
    }
    if (result.food.isNotEmpty) {
      written.add(strings.derivedFoodAwaitingReview);
    }

    final sentence = written.isEmpty
        ? (result.lifestyle.isEmpty
            ? strings.entryWasInterpreted
            : strings.entryWasInterpretedAndLogged)
        : strings.recordedItems(written);

    // The commit layer reports which bound was exceeded; the sentence is made
    // here, where the language is known.
    final failures = body?.failures ?? const <BodyRecordError>[];
    return failures.isEmpty
        ? sentence
        : '$sentence ${strings.bodyRecordError(failures.first)}';
  }

  /// Deleting asks once, because it removes prose nobody else has a copy of.
  Future<void> _confirmDelete() async {
    if (_busy) return;
    final strings = EterStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteEntryTitle),
        content: Text(strings.deleteEntryBody),
        actions: [
          EterAction(
            label: strings.keep,
            emphasis: EterActionEmphasis.quiet,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          EterAction(
            label: strings.delete,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    // The derived rows go first: an orphaned meal estimate outliving the
    // sentence it came from is exactly the kind of record nobody can explain.
    await widget.db.revertJournalEntryRows(widget.entry.id);
    await widget.db.discardJournalEntry(widget.entry.id);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _undo() async {
    if (_busy) return;
    final strings = EterStrings.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    await widget.db.revertJournalEntryRows(widget.entry.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = strings.interpretationAndDerivedRemoved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    final interpreted = widget.entry.status == 'classified';
    final question = _question;
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.time +
                (widget.entry.excludedFromAi
                    ? '  ·  ${strings.keptFromAether}'
                    : ''),
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
                label: widget.entry.excludedFromAi
                    ? strings.allowAether
                    : strings.keepLocal,
                semanticLabel: widget.entry.excludedFromAi
                    ? strings.allowAetherSemantic
                    : strings.keepLocalSemantic,
                color: ink.labelMuted,
                onTap: () => widget.db.setJournalExcludedFromAi(
                  widget.entry.id,
                  !widget.entry.excludedFromAi,
                ),
              ),
              // Interpretation is no longer asked for; it happens to every
              // page that is kept. What is left here is the way back out of
              // it, and the way to remove the page entirely.
              if (interpreted)
                _GlyphAction(
                  label: strings.undoInterpretation,
                  semanticLabel: strings.undoInterpretationSemantic,
                  color: ink.labelMuted,
                  onTap: _undo,
                ),
              _GlyphAction(
                label: strings.delete,
                semanticLabel: strings.deleteEntrySemantic,
                color: ink.labelMuted,
                onTap: _confirmDelete,
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
              decoration: InputDecoration(
                labelText: strings.fieldAddMissingDetail,
              ),
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
    this.onHoldStart,
    this.onHoldEnd,
    this.compact = false,
    this.mark = false,
    this.markActive = false,
  });

  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  /// Push-to-talk, when this action supports it. Additive to [onTap] — holding
  /// is a shortcut for people who find it, never the only way in.
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;

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
        // `onLongPress` fires once the hold is recognised; the end callbacks
        // cover every way a finger can leave, including sliding off the target,
        // so a hold can never be left listening forever.
        onLongPress: onHoldStart,
        onLongPressEnd: onHoldEnd == null ? null : (_) => onHoldEnd!(),
        onLongPressCancel: onHoldEnd,
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

/// The axis, pulled back — what the History sheet shows once the day has
/// widened. Not a destination and not a route: the same sheet, the same beads,
/// a different scale.
///
/// Everything here is arithmetic over rows already on the device. No model call,
/// so it works offline, instantly, and after a trial has ended — which is the
/// reason `long_view.dart` exists at all.
class _LongViewPanel extends StatefulWidget {
  const _LongViewPanel({
    super.key,
    required this.db,
    required this.span,
    required this.anchor,
  });

  final AppDatabase db;
  final LongViewSpan span;
  final DateTime anchor;

  @override
  State<_LongViewPanel> createState() => _LongViewPanelState();
}

class _LongViewPanelState extends State<_LongViewPanel> {
  late Future<LongView> _view = _load();

  Future<LongView> _load() async {
    // Consent is re-read here rather than passed down, because every path in
    // Eter re-reads it and a cached flag would outlive a revocation.
    final profile = await widget.db.loadProfile();
    return LongViewSource.load(
      widget.db,
      span: widget.span,
      anchor: widget.anchor,
      journalAllowed: profile?.journalAiConsentAt != null,
    );
  }

  @override
  void didUpdateWidget(_LongViewPanel old) {
    super.didUpdateWidget(old);
    if (old.span != widget.span || old.anchor != widget.anchor) {
      setState(() => _view = _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;

    return FutureBuilder<LongView>(
      future: _view,
      builder: (context, snapshot) {
        final view = snapshot.data;
        if (view == null) return const SizedBox.shrink();

        final labels = [
          for (final cell in view.cells) _cellLabel(cell, strings.language.code),
        ];

        return ListView(
          padding: const EdgeInsets.only(bottom: EterSpace.s32),
          children: [
            Text(
              strings.longViewRecorded(
                recorded: view.recordedCells,
                total: view.cells.length,
              ),
              style: text.labelSmall,
            ),
            const SizedBox(height: EterSpace.s16),
            if (view.isEmpty)
              Text(
                strings.longViewNothingRecorded,
                style: text.bodyMedium?.copyWith(color: ink.labelMuted),
              )
            else ...[
              for (final (measure, values, format) in _series(view))
                if (values.any((value) => value != null)) ...[
                  EngravedLongView(
                    measure: measure,
                    values: values,
                    labels: labels,
                    format: format,
                  ),
                  const SizedBox(height: EterSpace.s24),
                ],
              ..._marginalia(view, text, ink),
            ],
          ],
        );
      },
    );
  }

  /// The four measures, each with the units it is said in. Pages is a count and
  /// its zero is real; the other three are means over recorded days only, and a
  /// period that recorded none of them is null all the way through.
  List<(LongViewMeasure, List<double?>, String Function(double))> _series(
    LongView view,
  ) =>
      [
        (
          LongViewMeasure.sleep,
          [for (final cell in view.cells) cell.sleepHours],
          (double value) => '${value.toStringAsFixed(1)} h',
        ),
        (
          LongViewMeasure.mood,
          [for (final cell in view.cells) cell.mood],
          (double value) => value.toStringAsFixed(1),
        ),
        (
          LongViewMeasure.steps,
          [for (final cell in view.cells) cell.steps],
          (double value) => '${value.round()}',
        ),
        (
          LongViewMeasure.pages,
          [
            for (final cell in view.cells)
              // Zero pages is a fact, not an absence — Eter knows for certain
              // that nothing was written. It is drawn as a bar of no height
              // rather than an absent tick.
              cell.journalEntries.toDouble(),
          ],
          (double value) => '${value.round()}',
        ),
      ];

  /// Aether's own notes, in the margin.
  ///
  /// Only on a week. A month is thirty day cells and thirty notes is a wall of
  /// text, not marginalia — the same reason `LongViewComposer` returns none for
  /// a month cell rather than picking one and implying it summarised the month.
  List<Widget> _marginalia(LongView view, TextTheme text, EterInk ink) {
    if (view.span != LongViewSpan.week) return const [];
    final notes = [
      for (final cell in view.cells)
        if (cell.note case final note?) (cell.key, note),
    ];
    if (notes.isEmpty) return const [];
    return [
      for (final (key, note) in notes)
        Padding(
          padding: const EdgeInsets.only(bottom: EterSpace.s8),
          child: Text(
            '$key · $note',
            style: text.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: ink.labelMuted,
            ),
          ),
        ),
    ];
  }

  /// A day cell is a day number; a month cell is a short month name. The
  /// composer carries the canonical key and leaves the wording here, which is
  /// the half that knows the language.
  static String _cellLabel(LongViewCell cell, String locale) {
    final parts = cell.key.split('-');
    if (parts.length == 2) {
      return DateFormat('MMM', locale)
          .format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
    }
    return parts.last.replaceFirst(RegExp(r'^0'), '');
  }
}

/// The monthly letter, on the page it arrives on.
///
/// Shows last month's letter in the place Aether's prose always occupies, and
/// only until it has been read — a letter arrives once. Every other day, and
/// every day that is not today, this is transparent and [otherwise] renders.
///
/// Composition is attempted here rather than on a schedule because the Journal
/// opening is the only moment Eter reliably has: there is no background poll in
/// this product, and `AI_FLOW.md` says so. The attempt is cheap after the first
/// of the month, since the month is the cache key and `LetterComposer` returns
/// the stored row without a request.
class _LetterArrival extends ConsumerStatefulWidget {
  const _LetterArrival({
    required this.day,
    required this.isToday,
    required this.proseStyle,
    required this.otherwise,
  });

  final DateTime day;
  final bool isToday;
  final TextStyle? proseStyle;
  final Widget otherwise;

  @override
  ConsumerState<_LetterArrival> createState() => _LetterArrivalState();
}

class _LetterArrivalState extends ConsumerState<_LetterArrival> {
  bool _asked = false;

  /// The month a letter would be about: the one before the day in view.
  String get _month {
    final previous = DateTime(widget.day.year, widget.day.month - 1);
    return '${previous.year.toString().padLeft(4, '0')}-'
        '${previous.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_compose());
    });
  }

  /// Best-effort, exactly like auto-interpretation. Nothing was asked for, so a
  /// month that cannot be written is not an error on anybody's screen — the
  /// page simply carries the day story instead.
  Future<void> _compose() async {
    if (_asked || !widget.isToday) return;
    _asked = true;
    final provider = ref.read(letterProvider);
    if (provider == null) return;
    try {
      await LetterComposer(
        database: ref.read(databaseProvider),
        provider: provider,
      ).compose(month: _month, now: ref.read(nowProvider)());
    } catch (_) {
      // A letter that cannot be composed changes nothing about the page.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isToday) return widget.otherwise;
    final db = ref.watch(databaseProvider);
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);

    return StreamBuilder<LetterRow?>(
      stream: db.watchLetter(_month),
      builder: (context, snapshot) {
        final row = snapshot.data;
        if (row == null || row.readAt || row.body.trim().isEmpty) {
          return widget.otherwise;
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: EterSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.headingLetter, style: text.labelSmall),
              const SizedBox(height: EterSpace.s4),
              Text(
                strings.letterMonth(row.month),
                style: text.labelSmall?.copyWith(color: ink.labelMuted),
              ),
              const SizedBox(height: EterSpace.s8),
              Expanded(
                child: SingleChildScrollView(
                  // A letter is longer than a day story and must not be shrunk
                  // to fit — `_FittedProse` would take a full month's page down
                  // to fine print. It scrolls instead.
                  child: EterArrival.single(
                    row.body,
                    key: ValueKey('letter-${row.month}'),
                    style: widget.proseStyle?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: ink.label,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: EterSpace.s12),
              // Read once it has been seen. The writing field below is the
              // reply, so there is no "dismiss": answering it, or simply
              // having read it, is what closes it.
              EterAction(
                label: strings.close,
                emphasis: EterActionEmphasis.quiet,
                onPressed: () => unawaited(db.markLetterRead(row.month)),
              ),
              Container(height: 1, width: 64, color: ink.line),
            ],
          ),
        );
      },
    );
  }
}
