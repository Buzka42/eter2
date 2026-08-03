import 'package:flutter/material.dart';

import '../../core/controls.dart';
import '../../core/i18n/strings.dart';
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
  Rect? _spotlight() {
    final key = widget.steps[_index].target;
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    if (!origin.dx.isFinite || !origin.dy.isFinite) return null;
    return (origin & box.size).inflate(8);
  }

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    final text = Theme.of(context).textTheme;
    final step = widget.steps[_index];
    final hole = _spotlight();
    final size = MediaQuery.sizeOf(context);
    final last = _index == widget.steps.length - 1;

    // The caption goes on whichever side of the hole has more room, so it
    // never lands on the thing it is describing.
    final below = hole == null || hole.center.dy < size.height / 2;

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
                painter: _ScrimPainter(hole: hole),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            left: EterSpace.gutter,
            right: EterSpace.gutter,
            top: below ? null : EterSpace.s48,
            bottom: below ? EterSpace.s48 : null,
            child: IgnorePointer(
              ignoring: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.eyebrow,
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

/// Fills the screen and punches one rounded hole in it.
class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({required this.hole});

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xE60B1020);
    final full = Offset.zero & size;
    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    final rounded = RRect.fromRectAndRadius(
      hole!,
      const Radius.circular(EterSpace.rChip),
    );
    // Even-odd so the hole is genuinely transparent: a second draw in blend
    // mode clear would need a saveLayer and would fight the sky behind it.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(full),
        Path()..addRRect(rounded),
      ),
      scrim,
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..color = const Color(0x66D8C79A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}
