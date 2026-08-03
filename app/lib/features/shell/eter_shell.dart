import 'package:flutter/material.dart';

import '../../core/controls.dart';
import '../../core/i18n/strings.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../dashboard/dashboard_page.dart';
import '../journal/journal_page.dart';
import '../onboarding/walkthrough.dart';
import '../sanctum/sanctum_overlay.dart';
import 'shell_header.dart';

/// The shell: one continuous space with two front doors.
///
/// ```
///    ← Journal ═══════════════ Dashboard →     horizontal pager, one space
/// ```
///
/// A single [SkyBackground] holds the environment while the two surfaces
/// slide over it; the shared celestial header and the persistent destination
/// switch sit above both, identical on either side. Both pages stay alive
/// across page changes — scroll position, an expanded section and a
/// half-written entry all survive the crossing.
class EterShell extends StatefulWidget {
  const EterShell({
    super.key,
    this.startSurface = 'dashboard',
    this.walkthrough = false,
    this.onWalkthroughFinished,
  });

  /// `journal` | `dashboard` — from `Profile.startSurface`.
  final String startSurface;

  /// Whether the second half of the first minute runs over this shell.
  ///
  /// It lives here rather than beside the written half because it points at
  /// the real rail, the real writing field and the real Sanctum mark — and
  /// because only the shell can bring the right page forward before lighting
  /// something on it.
  final bool walkthrough;
  final VoidCallback? onWalkthroughFinished;

  @override
  State<EterShell> createState() => _EterShellState();
}

class _EterShellState extends State<EterShell> {
  late final PageController _controller;
  late int _active;
  bool _sanctumOpen = false;

  // What the walkthrough lights, one at a time. Real widgets, so the sentences
  // stay true when anything moves.
  final _railKey = GlobalKey();
  final _sanctumKey = GlobalKey();
  final _pageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _active = widget.startSurface == 'journal' ? 0 : 1;
    _controller = PageController(initialPage: _active);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page == _active || !_controller.hasClients) return;
    // The explicit words are deterministic navigation; the optional swipe is
    // where the continuous horizontal motion lives. This also gives keyboard
    // and assistive-technology users an immediate, reliable destination.
    _controller.jumpToPage(page);
  }

  void _openSanctum() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _sanctumOpen = true);
  }

  void _closeSanctum() => setState(() => _sanctumOpen = false);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sanctumOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _sanctumOpen) _closeSanctum();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SkyBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: EterSpace.s8),
                    EterShellHeader(onOpenSanctum: _openSanctum),
                    // The way into the Sanctum: the mark alone, dead centre on
                    // the destination row, on the same vertical axis as the arc,
                    // the wordmark and the plumb above it.
                    //
                    // Chosen over four alternatives, on rendered pixels in both
                    // languages. A *word* here needs about 90 dp and has to take
                    // it from the rail, which pushes the destinations off the
                    // wordmark's axis. It was `SANKTUARIUM` — eleven letterspaced
                    // caps against `SANCTUM`'s seven — that decided it; the
                    // lexicon has since shortened that to `ZACISZE`, which does
                    // not reopen the question, because 90 dp is still 90 dp. A
                    // glyph fits in the roughly 70 dp the two labels already
                    // leave between them, so nothing moves and no row is added.
                    //
                    // The travelling hairline still belongs only to the active
                    // destination, which is what keeps this from reading as a
                    // third page. What keeps it from being an *unexplained*
                    // symbol — which non-negotiable 7 forbids — is that the
                    // tutorial draws it on the first run.
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        DestinationSwitch(
                          key: _railKey,
                          activeIndex: _active,
                          onSelect: _goTo,
                        ),
                        Semantics(
                          button: true,
                          label: EterStrings.of(context).openSanctumSemantic,
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _openSanctum,
                            child: SizedBox(
                              key: _sanctumKey,
                              width: 48,
                              height: 48,
                              child: Center(
                                child: EterSanctumMark(
                                  size: 18,
                                  glow: true,
                                  color: EterInk.of(context).lineStrong,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      key: _pageKey,
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (page) => setState(() => _active = page),
                        // One continuous space: the adjacent page is always
                        // built, so the first crossing is instant and both
                        // surfaces stay live.
                        allowImplicitScrolling: true,
                        children: const [
                          _KeepAlivePage(child: JournalPage()),
                          _KeepAlivePage(child: DashboardPage()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_sanctumOpen)
              Positioned.fill(
                child: SanctumOverlay(onClose: _closeSanctum),
              ),
            if (widget.walkthrough && !_sanctumOpen)
              Positioned.fill(
                child: EterWalkthrough(
                  onFinished: widget.onWalkthroughFinished ?? () {},
                  steps: [
                    WalkthroughStep(
                      target: _pageKey,
                      eyebrow: EterStrings.of(context).destinationJournal,
                      line: EterStrings.of(context).walkthroughJournal,
                      onEnter: () => _goTo(0),
                    ),
                    WalkthroughStep(
                      target: _pageKey,
                      eyebrow: EterStrings.of(context).destinationDashboard,
                      line: EterStrings.of(context).walkthroughGuidance,
                      onEnter: () => _goTo(1),
                    ),
                    WalkthroughStep(
                      target: _pageKey,
                      eyebrow: EterStrings.of(context).lookDeeper,
                      line: EterStrings.of(context).walkthroughDepths,
                    ),
                    WalkthroughStep(
                      target: _railKey,
                      eyebrow: EterStrings.of(context).walkthroughTwoDoors,
                      line: EterStrings.of(context).walkthroughRail,
                    ),
                    WalkthroughStep(
                      target: _sanctumKey,
                      eyebrow: EterStrings.of(context).sanctum,
                      line: EterStrings.of(context).walkthroughSanctum,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keeps a pager page's state alive while it is off-screen: the arrival's
/// settle state, an expanded instrument and a half-written journal entry are
/// all part of the continuous space and must survive the crossing.
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
