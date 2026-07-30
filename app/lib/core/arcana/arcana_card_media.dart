import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../tokens.dart';
import '../theme.dart';

// `AnimatedArcanaCard` was here: a flip-reveal card, 100 lines, with no call
// sites. `EterArcanaPlate` in the Vessel supersedes it and reaches the same 22
// night loops through `ArcanaCardMedia` below, which is the half of this file
// that was ever used.

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
