import 'package:flutter/material.dart';

import 'tokens.dart';

// The cadence, tuned against the 1200 ms per-sentence budget.
const _groupDuration = Duration(milliseconds: 520);
const _groupDurationMs = 520.0;
const _maxGroupStagger = 140.0; // ms between overlapping group starts
const _interSentencePause = 280.0; // ms
const _interPassagePause = 520.0; // ms — a breath between paragraphs
const _maxBlurSigma = 2.4;
const _maxDisplacement = 4.0; // dp, per the direction document

/// One passage of an [EterArrival]: text plus the style it resolves into.
/// A dashboard reading is usually two — the primary direction and the
/// supporting line; a journal entry is one.
class ArrivalPassage {
  const ArrivalPassage(this.text, {this.style});

  final String text;
  final TextStyle? style;
}

/// The signature arrival — guidance and journal entries do not appear, they
/// arrive, as if the sentences were being written into the air.
///
/// The grammar, from `docs/UI_DIRECTION.md`:
///
/// * A sentence begins slightly displaced (never more than 4 dp), softly
///   blurred and low-contrast.
/// * Words resolve in short overlapping groups — never character by
///   character, never with a cursor.
/// * Contrast, blur and displacement settle together on [EterMotion.easeAir].
/// * Pauses fall between sentences, not between words; one sentence never
///   takes longer than [EterMotion.durSentence].
/// * A tap anywhere in the region resolves the whole passage immediately.
/// * Under reduced motion the final state renders on the first frame.
///
/// This widget is the only implementation. It serves the Dashboard guidance
/// and the Journal alike; the product's defining interaction must not exist
/// twice. Deliberately shader-free: per-span opacity and blur with a
/// block-level translation, which is the prototype the direction document
/// asks to see profiled before anything fancier is attempted.
class EterArrival extends StatefulWidget {
  EterArrival({
    super.key,
    required List<ArrivalPassage> passages,
    this.playArrival = true,
    this.onSettled,
  }) : passages = List.unmodifiable(passages);

  /// A single styled passage — the common case for journal entries.
  EterArrival.single(
    String text, {
    super.key,
    TextStyle? style,
    this.playArrival = true,
    this.onSettled,
  }) : passages = List.unmodifiable([ArrivalPassage(text, style: style)]);

  final List<ArrivalPassage> passages;

  /// False renders the settled state immediately — pre-existing journal
  /// entries are already on the page; only newly saved ones arrive.
  final bool playArrival;

  /// Fires once, when the passage has fully resolved.
  final VoidCallback? onSettled;

  @override
  State<EterArrival> createState() => _EterArrivalState();
}

class _EterArrivalState extends State<EterArrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_PassageTimeline> _timeline;
  late Duration _total;
  bool _notifiedSettled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _notifySettled();
      });
    _parse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyMotionPolicy();
  }

  @override
  void didUpdateWidget(EterArrival oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldText = oldWidget.passages.map((p) => p.text).join();
    final newText = widget.passages.map((p) => p.text).join();
    if (oldText != newText || oldWidget.playArrival != widget.playArrival) {
      _parse();
      _applyMotionPolicy();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _reducedMotion =>
      MediaQuery.disableAnimationsOf(context) || !widget.playArrival;

  void _applyMotionPolicy() {
    if (_reducedMotion) {
      // Reduced motion: the final state on the first frame, and no ticker.
      _controller.stop();
      _controller.value = 1;
      _notifySettled();
    } else if (!_controller.isAnimating && _controller.value < 1) {
      _notifiedSettled = false;
      _controller.forward(from: 0);
    }
  }

  void _notifySettled() {
    if (_notifiedSettled) return;
    _notifiedSettled = true;
    final callback = widget.onSettled;
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) callback();
      });
    }
  }

  /// Splits passages into sentences and sentences into overlapping word
  /// groups, then lays the whole reading out on one timeline.
  void _parse() {
    final timeline = <_PassageTimeline>[];
    var cursor = 0.0; // ms
    for (var p = 0; p < widget.passages.length; p++) {
      if (p > 0) cursor += _interPassagePause;
      final passageStart = cursor;
      final groups = <_GroupTimeline>[];
      final sentences = _splitSentences(widget.passages[p].text);
      for (var s = 0; s < sentences.length; s++) {
        if (s > 0) cursor += _interSentencePause;
        final words = sentences[s].split(' ');
        final chunk = words.length <= 7 ? 2 : 3;
        final chunks = <List<String>>[
          for (var i = 0; i < words.length; i += chunk)
            words.sublist(i, i + chunk > words.length ? words.length : i + chunk),
        ];
        // The sentence must land inside durSentence: shrink the stagger until
        // the final group settles within budget.
        final stagger = chunks.length > 1
            ? ((EterMotion.durSentence.inMilliseconds -
                        _groupDuration.inMilliseconds) /
                    (chunks.length - 1))
                .clamp(0.0, _maxGroupStagger)
            : 0.0;
        for (var g = 0; g < chunks.length; g++) {
          final isLastOfSentence = g == chunks.length - 1;
          final isLastSentence = s == sentences.length - 1;
          // Every group but the passage's last carries its trailing space;
          // sentence breaks hang theirs on the sentence's final group.
          final trailingSpace = !(isLastOfSentence && isLastSentence);
          groups.add(
            _GroupTimeline(
              text: chunks[g].join(' ') + (trailingSpace ? ' ' : ''),
              startMs: cursor + g * stagger,
            ),
          );
        }
        cursor += (chunks.length - 1) * stagger + _groupDuration.inMilliseconds;
      }
      timeline.add(_PassageTimeline(startMs: passageStart, groups: groups));
    }
    _timeline = timeline;
    _total = Duration(milliseconds: cursor.ceil());
    _controller.duration = _total;
  }

  static final _sentenceBreak = RegExp(r'(?<=[.!?…])\s+');

  static List<String> _splitSentences(String text) =>
      text.trim().split(_sentenceBreak).where((s) => s.isNotEmpty).toList();

  void _complete() {
    if (_controller.value < 1) {
      _controller.value = 1;
      _notifySettled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullText =
        widget.passages.map((p) => p.text.trim()).join('\n\n');
    return Semantics(
      container: true,
      liveRegion: true,
      label: fullText,
      hint: _controller.value < 1 ? 'Tap to reveal immediately' : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _complete,
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final elapsed = _controller.value * _total.inMilliseconds;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _timeline.length; i++) ...[
                    if (i > 0) const SizedBox(height: EterSpace.s16),
                    _PassageView(
                      timeline: _timeline[i],
                      style: widget.passages[i].style ??
                          DefaultTextStyle.of(context).style,
                      elapsedMs: elapsed,
                      maxBlur: _maxBlurSigma,
                      maxDisplacement: _maxDisplacement,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GroupTimeline {
  const _GroupTimeline({required this.text, required this.startMs});

  final String text;
  final double startMs;
}

class _PassageTimeline {
  const _PassageTimeline({required this.startMs, required this.groups});

  final double startMs;
  final List<_GroupTimeline> groups;
}

/// One paragraph of the arrival: flowing prose (a journal entry must read as
/// continuous dated prose, not verse), resolving group by group.
class _PassageView extends StatelessWidget {
  const _PassageView({
    required this.timeline,
    required this.style,
    required this.elapsedMs,
    required this.maxBlur,
    required this.maxDisplacement,
  });

  final _PassageTimeline timeline;
  final TextStyle style;
  final double elapsedMs;
  final double maxBlur;
  final double maxDisplacement;

  @override
  Widget build(BuildContext context) {
    const groupDurMs = _groupDurationMs;
    final spans = <TextSpan>[];
    // Displacement tracks the group currently resolving, so each sentence
    // begins fractionally low and settles — the block re-dips by at most
    // 4 dp, which is the "focus arriving" beat, not a jitter.
    var displacement = 0.0;
    var latestStarted = -1;
    for (var g = 0; g < timeline.groups.length; g++) {
      final group = timeline.groups[g];
      final raw = ((elapsedMs - group.startMs) / groupDurMs).clamp(0.0, 1.0);
      if (raw >= 1) {
        // Settled spans render with the plain style: crisp, no foreground
        // paint, no residual blur.
        spans.add(TextSpan(text: group.text, style: style));
      } else {
        final eased = EterMotion.easeAir.transform(raw);
        if (elapsedMs >= group.startMs) latestStarted = g;
        final color = style.color ?? const Color(0xFF000000);
        spans.add(
          TextSpan(
            text: group.text,
            style: TextStyle(
              fontFamily: style.fontFamily,
              fontSize: style.fontSize,
              height: style.height,
              fontWeight: style.fontWeight,
              fontStyle: style.fontStyle,
              letterSpacing: style.letterSpacing,
              fontFeatures: style.fontFeatures,
              foreground: Paint()
                ..color = color.withValues(alpha: eased)
                ..maskFilter =
                    MaskFilter.blur(BlurStyle.normal, (1 - eased) * maxBlur),
            ),
          ),
        );
      }
    }
    if (latestStarted >= 0) {
      final group = timeline.groups[latestStarted];
      final raw = ((elapsedMs - group.startMs) / groupDurMs).clamp(0.0, 1.0);
      displacement = (1 - EterMotion.easeAir.transform(raw)) * maxDisplacement;
    }
    return Transform.translate(
      offset: Offset(0, displacement),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}
