import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../dashboard/dashboard_page.dart';
import '../journal/journal_page.dart';
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
  const EterShell({super.key, this.startSurface = 'dashboard'});

  /// `journal` | `dashboard` — from `Profile.startSurface`.
  final String startSurface;

  @override
  State<EterShell> createState() => _EterShellState();
}

class _EterShellState extends State<EterShell> {
  late final PageController _controller;
  late int _active;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SkyBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: EterSpace.s8),
              const EterShellHeader(),
              DestinationSwitch(activeIndex: _active, onSelect: _goTo),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _active = page),
                  // One continuous space: the adjacent page is always built,
                  // so the first crossing is instant and both surfaces stay
                  // live.
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
