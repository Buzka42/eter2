import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../tokens.dart';
import '../theme.dart';
import 'loop_budget.dart';

// `AnimatedArcanaCard` was here: a flip-reveal card, 100 lines, with no call
// sites. `EterArcanaPlate` in the Vessel supersedes it and reaches the same 22
// night loops through `ArcanaCardMedia` below, which is the half of this file
// that was ever used.

/// Static card art with an optional motion loop composited over it.
///
/// The still image always renders; the loop is additive and any decode failure
/// silently leaves the still in place (DEVELOPMENT.md: static fallback is
/// mandatory, animation must never be the only rendering).
///
/// A loop is only started while the plate is **on or near the screen**, and
/// only while [arcanaLoopBudget] has a slot for it. Both conditions exist for
/// the same reason: the Vessel can put eighteen plates in one column and a
/// phone has nowhere near eighteen video decoders. Scrolling a plate away
/// hands its decoder back, so the plate you are looking at is the one that
/// moves — which is what "every position animates" has to mean on a device
/// that cannot animate all of them at once.
class ArcanaCardMedia extends StatefulWidget {
  const ArcanaCardMedia({
    super.key,
    required this.path,
    required this.videoPath,
    required this.lightOverlay,
    required this.width,
    required this.height,
  });

  final String path;
  final String? videoPath;
  final bool lightOverlay;
  final double width;
  final double height;

  @override
  State<ArcanaCardMedia> createState() => _ArcanaCardMediaState();
}

class _ArcanaCardMediaState extends State<ArcanaCardMedia> {
  VideoPlayerController? _controller;
  bool _holdsSlot = false;
  bool _onScreen = false;
  bool _checkScheduled = false;
  ScrollPosition? _scrollPosition;

  /// How far outside the viewport a plate still counts as on screen.
  ///
  /// Roughly one card tall, so a loop has begun decoding by the time the plate
  /// is actually looked at rather than starting still and catching up.
  static const _margin = 240.0;

  @override
  void initState() {
    super.initState();
    _scheduleVisibilityCheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The plate can be rebuilt into a different scrollable — the Vessel is
    // inside the Dashboard's scroll view, which is itself inside the shell's
    // pager — so the subscription is re-made rather than assumed.
    final position = Scrollable.maybeOf(context)?.position;
    if (identical(position, _scrollPosition)) return;
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _scrollPosition = position;
    _scrollPosition?.addListener(_scheduleVisibilityCheck);
    _scheduleVisibilityCheck();
  }

  @override
  void didUpdateWidget(covariant ArcanaCardMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _releaseLoop();
      _scheduleVisibilityCheck();
    }
  }

  /// Coalesces the scroll listener's many calls into one check per frame.
  void _scheduleVisibilityCheck() {
    if (_checkScheduled || !mounted) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (mounted) _applyVisibility();
    });
  }

  void _applyVisibility() {
    final visible = _computeOnScreen();
    if (visible == _onScreen) return;
    _onScreen = visible;
    if (visible) {
      _loadVideo();
    } else {
      _releaseLoop();
      if (mounted) setState(() {});
    }
  }

  bool _computeOnScreen() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return false;
    final origin = box.localToGlobal(Offset.zero);
    if (!origin.dx.isFinite || !origin.dy.isFinite) return false;
    final plate = origin & box.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    return plate.overlaps(screen.inflate(_margin));
  }

  /// Disposes the loop and hands the slot back. Safe to call twice.
  void _releaseLoop() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    if (_holdsSlot) {
      _holdsSlot = false;
      arcanaLoopBudget.release();
    }
  }

  Future<void> _loadVideo() async {
    _releaseLoop();
    if (eterRunningTests()) {
      if (mounted) setState(() {});
      return;
    }
    final path = widget.videoPath;
    if (path == null) {
      if (mounted) setState(() {});
      return;
    }
    // Over budget the plate simply stays still. The still art is already
    // drawn, so there is nothing to fall back to and nothing to report.
    if (!arcanaLoopBudget.request()) {
      if (mounted) setState(() {});
      return;
    }
    _holdsSlot = true;
    final controller = VideoPlayerController.asset(path);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted || !identical(_controller, controller)) {
        // Scrolled away, or replaced, while the decoder was starting.
        return;
      }
      setState(() {});
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) {
        _controller = null;
        if (_holdsSlot) {
          _holdsSlot = false;
          arcanaLoopBudget.release();
        }
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_scheduleVisibilityCheck);
    _releaseLoop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Every build is a chance the plate has moved: an expanding section above
    // it shifts it without any scrolling at all.
    _scheduleVisibilityCheck();
    return ClipRRect(
      borderRadius: BorderRadius.circular(EterSpace.rChip),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.path,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            if (_controller?.value.isInitialized ?? false)
              RepaintBoundary(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
