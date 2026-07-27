import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../tokens.dart';
import '../theme.dart';
import 'major_arcana.dart';
import 'zodiac.dart';

class AnimatedArcanaCard extends StatefulWidget {
  const AnimatedArcanaCard({
    super.key,
    required this.zodiac,
    this.revealed = false,
    this.onReveal,
    this.width = 220,
  });

  final Zodiac zodiac;
  final bool revealed;
  final VoidCallback? onReveal;
  final double width;

  @override
  State<AnimatedArcanaCard> createState() => _AnimatedArcanaCardState();
}

class _AnimatedArcanaCardState extends State<AnimatedArcanaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final brightness = Theme.of(context).brightness;
    final height = widget.width * 1.485;

    return Semantics(
      button: !widget.revealed,
      label: widget.revealed
          ? '${widget.zodiac.arcana}, ${widget.zodiac.numeral}'
          : 'Reveal Arcana card',
      child: GestureDetector(
        onTap: widget.revealed ? null : widget.onReveal,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.revealed ? math.pi : 0),
          duration: reduceMotion ? Duration.zero : EterMotion.durReveal,
          curve: EterMotion.easeAir,
          builder: (context, angle, _) {
            final front = angle > math.pi / 2;
            final card = ArcanaCardMedia(
              path: front
                  ? widget.zodiac.cardAssetFor(brightness)
                  : 'assets/art/card-back-v2-${brightness == Brightness.dark ? 'dark' : 'light'}.webp',
              // Stage 13.5: the back-face loop was regenerated from the v2
              // dark master, so Night Sky animates both faces again. Day Sky
              // still has no approved loops.
              videoPath: reduceMotion
                  ? null
                  : brightness == Brightness.light
                      ? null
                      : front
                          ? MajorArcana.forZodiac(widget.zodiac)
                              .nightLoopFor(brightness)
                          : 'assets/art/animations/card-back-dark.mp4',
              lightOverlay: brightness == Brightness.light,
              width: widget.width,
              height: height,
            );
            final facingCard = front
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: card,
                  )
                : card;
            return AnimatedBuilder(
              animation: _ambient,
              child: facingCard,
              builder: (context, child) {
                final drift =
                    reduceMotion ? 0.0 : math.sin(_ambient.value * math.pi) * 3;
                return Transform.translate(
                  offset: Offset(0, drift),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angle),
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Static card art with an optional motion loop composited over it.
///
/// The still image always renders; the loop is additive and any decode failure
/// silently leaves the still in place (DEVELOPMENT.md: static fallback is
/// mandatory, animation must never be the only rendering).
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

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant ArcanaCardMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) _loadVideo();
  }

  Future<void> _loadVideo() async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();
    if (eterRunningTests()) {
      if (mounted) setState(() {});
      return;
    }
    final path = widget.videoPath;
    if (path == null) {
      if (mounted) setState(() {});
      return;
    }
    final controller = VideoPlayerController.asset(path);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted && identical(_controller, controller)) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (identical(_controller, controller)) _controller = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
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
