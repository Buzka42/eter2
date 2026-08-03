import 'package:flutter/material.dart';

import '../../core/controls.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';

/// One stop on the walkthrough: something to look at, and a sentence about it.
class WalkthroughStep {
  const WalkthroughStep({
    required this.target,
    required this.eyebrow,
    required this.line,
    this.onEnter,
  });

  /// The thing being pointed at. Null means the caption stands alone — a step
  /// about the surface as a whole rather than a control on it.
  final GlobalKey? target;

  final String eyebrow;
  final String line;

  /// Run before the step is shown: bring the right page forward, mostly.
  final VoidCallback? onEnter;
}

/// The second half of the first minute: the interface, on the interface.
///
/// The written half says what Eter is. This one says where things are, and it
/// says it *over the running app* rather than in a picture of it — the
/// destination rail, the writing field and the Sanctum mark are the real ones,
/// lit one at a time under a scrim.
///
/// Why not a carousel of screenshots: a screenshot goes stale the first time
/// anything moves, and it teaches the shape of an image rather than the shape
/// of the app. Why not arrows and tooltips: this product has no such idiom
/// anywhere else, and inventing one for four sentences would be the most
/// heavily designed thing in it.
///
/// `SKIP` is on every step. A tutorial that cannot be left is a wall.
class EterWalkthrough extends StatefulWidget {
  const EterWalkthrough({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  final List<WalkthroughStep> steps;
  final VoidCallback onFinished;

  @override
  State<EterWalkthrough> createState() => _EterWalkthroughState();
}

class _EterWalkthroughState extends State<EterWalkthrough> {
  int _index = 0;

  /// The caption's own box, so the scrim can be told to keep hold of the ground
  /// underneath it.
  final GlobalKey _captionKey = GlobalKey();
  Rect? _captionRect;

  @override
  void initState() {
    super.initState();
    // The first step may need a page brought forward before it can be lit.
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter(0));
  }

  void _enter(int index) {
    if (index >= widget.steps.length) return;
    widget.steps[index].onEnter?.call();
    // The rect is read after the frame the page change lands in, so the hole
    // is cut around where the target actually is rather than where it was.
    if (mounted) setState(() {});
  }

  void _advance() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() => _index++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter(_index));
  }

  /// Where the current step's target sits on screen, in global coordinates.
  Rect? _spotlight() => _globalRect(widget.steps[_index].target, 8);

  /// Where the caption sits, with a little air around it so the scrim it keeps
  /// does not stop exactly on the letters.
  Rect? _captionBox() => _globalRect(_captionKey, EterSpace.s8);

  static Rect? _globalRect(GlobalKey? key, double inflate) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    if (!origin.dx.isFinite || !origin.dy.isFinite) return null;
    return (origin & box.size).inflate(inflate);
  }

  /// Re-reads the caption's box after it has been laid out.
  ///
  /// The caption is measured rather than guessed because its height depends on
  /// the sentence, and the sentence is a translation: the Polish for a step is
  /// routinely two lines longer than the English, which is exactly the case
  /// where a guessed height would be wrong.
  void _rememberCaption() {
    if (!mounted) return;
    final measured = _captionBox();
    if (measured != _captionRect) {
      setState(() => _captionRect = measured);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    final text = Theme.of(context).textTheme;
    final step = widget.steps[_index];
    final hole = _spotlight();
    final size = MediaQuery.sizeOf(context);
    final last = _index == widget.steps.length - 1;

    WidgetsBinding.instance.addPostFrameCallback((_) => _rememberCaption());

    // The caption goes on whichever side of the hole has more room, so it
    // never lands on the thing it is describing.
    final below = WalkthroughScrim.captionBelow(hole, size);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Stack(
        children: [
          // The scrim, with the target cut out of it. It takes every tap that
          // is not on a control here: the app underneath is running, and a
          // stray press during the walkthrough would file a journal entry.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _advance,
              child: CustomPaint(
                painter: _ScrimPainter(hole: hole, caption: _captionRect),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            left: EterSpace.gutter,
            right: EterSpace.gutter,
            top: below ? null : EterSpace.s48,
            bottom: below ? EterSpace.s48 : null,
            // The caption is always night, whatever register the shell behind
            // it is in, because the scrim it is written on is always night.
            //
            // The eyebrow and the sentence say `Colors.white` themselves and so
            // were right by accident; the two actions take their ink from the
            // ambient theme, which during the day is the ink of the cream page
            // — dark letters on a dark scrim. It went unseen because the fault
            // above put those actions on the cream page, where dark letters
            // looked deliberate. Carving the scrim fixed the collision and
            // uncovered this underneath it.
            child: Theme(
              data: EterTheme.night(),
              child: Column(
                key: _captionKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    // Cased here rather than trusted from the string. The five
                    // eyebrows borrow labels that exist for other reasons, and
                    // four of them happen to be authored in caps while the
                    // Sanctum's is a proper name in title case — so on a phone
                    // the run read DZIENNIK, WGLAD, DWOJE DRZWI, then Zacisze.
                    step.eyebrow.toUpperCase(),
                    style: text.labelSmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: EterSpace.s8),
                  Text(
                    step.line,
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: EterSpace.s24),
                  Row(
                    children: [
                      EterAction(
                        key: const ValueKey('walkthrough-advance'),
                        label: last ? strings.begin : strings.next,
                        emphasis: EterActionEmphasis.primary,
                        onPressed: _advance,
                      ),
                      const Spacer(),
                      if (!last)
                        EterAction(
                          key: const ValueKey('walkthrough-skip'),
                          label: strings.skip,
                          emphasis: EterActionEmphasis.quiet,
                          onPressed: widget.onFinished,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the caption goes, and what the spotlight gives up to it.
///
/// Pure, and out of the painter, for the reason `NatalChartWheelLayout` is out
/// of the chart's: the fault here was geometric and was invisible in a reading
/// of the paint calls. It took a device to see it and it takes arithmetic to
/// keep it shut — writing the arithmetic down immediately disproved one of the
/// two causes first suspected, which is the argument for writing it down.
class WalkthroughScrim {
  const WalkthroughScrim._();

  /// Whether the caption sits below the hole rather than above it.
  ///
  /// Stated as the room each side actually has. This was written as "is the
  /// hole's centre in the top half", which is the *same predicate* — both
  /// reduce to `top + bottom < height` — so the rewording fixes nothing and is
  /// not claimed to. It is kept only because the question being asked is which
  /// gap is bigger, and it now says so.
  ///
  /// Worth knowing, because it is the trap here: **choosing the roomier side
  /// does not mean the caption fits.** When the target is large both gaps can
  /// be too small, and no choice between them helps. That is what [lit] is for.
  static bool captionBelow(Rect? hole, Size screen) =>
      hole == null || (screen.height - hole.bottom) >= hole.top;

  /// The lit shape: the hole, less the caption's box where the two meet.
  ///
  /// The caption is white text with nothing behind it, legible exactly as far
  /// as the scrim reaches, so the scrim under it is not negotiable and the
  /// spotlight's last corner is. A lit control with a corner scrimmed is still
  /// obviously the lit control; an unreadable instruction is not an
  /// instruction.
  static Path lit(Rect hole, Rect? caption) {
    final rounded = Path()
      ..addRRect(
        RRect.fromRectAndRadius(hole, const Radius.circular(EterSpace.rChip)),
      );
    if (caption == null || !caption.overlaps(hole)) return rounded;
    return Path.combine(
      PathOperation.difference,
      rounded,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            caption,
            const Radius.circular(EterSpace.rChip),
          ),
        ),
    );
  }
}

/// Fills the screen and punches one rounded hole in it, less whatever the
/// caption is standing on.
///
/// The caption is white text with nothing of its own behind it, so it is
/// legible exactly as far as the scrim reaches. That was left to chance: the
/// hole was punched wherever the target was and the caption was placed in what
/// remained, with nothing checking that what remained was big enough. On the
/// first walkthrough step it was not, and `DALEJ` and `POMIŃ` were drawn in
/// white over the cream journal page, on top of the date and the History
/// control — the first thing a new person sees.
///
/// So the caption keeps its ground and the spotlight gives it up. It is the
/// right way round: a lit control with a corner scrimmed is still obviously the
/// lit control, and an unreadable instruction is not an instruction. The outline
/// follows the carve rather than the original rectangle, so the notch is stated
/// rather than hidden behind a line that no longer bounds anything.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.hole, this.caption});

  final Rect? hole;
  final Rect? caption;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xE60B1020);
    final full = Offset.zero & size;
    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    final lit = WalkthroughScrim.lit(hole!, caption);
    // Even-odd so the hole is genuinely transparent: a second draw in blend
    // mode clear would need a saveLayer and would fight the sky behind it.
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(full), lit),
      scrim,
    );
    canvas.drawPath(
      lit,
      Paint()
        ..color = const Color(0x66D8C79A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.caption != caption;
}
