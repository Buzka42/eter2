import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/arrival.dart';
import '../../core/clock.dart';
import '../../core/db/app_database.dart';
import '../../core/register.dart';
import '../../core/tokens.dart';
import '../../main.dart';
import '../prototype/fixtures.dart';
import 'body_section.dart';

/// The Dashboard, collapsed: the day's guidance and one quiet disclosure.
///
/// The density budget is deliberate — one primary passage, one supporting
/// passage, and nothing else in the resting viewport. Metrics, charts and
/// symbols wait behind the single `Body` disclosure; the guidance owns the
/// first glance.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _bodyExpanded = false;
  final _scrollController = ScrollController();
  Stream<List<GuidanceHistoryRow>>? _guidanceStream;
  String? _streamedDay;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Cached so rebuilds (the arrival animates; frames rebuild) never
  /// resubscribe the StreamBuilder.
  Stream<List<GuidanceHistoryRow>> _guidanceFor(
      AppDatabase db, String today) {
    if (_guidanceStream == null || _streamedDay != today) {
      _streamedDay = today;
      _guidanceStream = db.watchGuidanceForDate(today);
    }
    return _guidanceStream!;
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final now = ref.watch(nowProvider)();
    final today = eterIsoDate(now);
    final text = Theme.of(context).textTheme;
    // Display scale responds to width: the concept plates' large type is a
    // mood cue, not a fixed size.
    final displayStyle =
        MediaQuery.sizeOf(context).width < 360 ? text.displaySmall : text.displayMedium;
    final supportingStyle = text.headlineSmall?.copyWith(
      fontSize: 19,
      height: 28 / 19,
      fontWeight: FontWeight.w400,
    );

    return SurfaceIntentScope(
      intent: SurfaceIntent.ritual,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: EterSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: EterSpace.s48),
            StreamBuilder<List<GuidanceHistoryRow>>(
              stream: _guidanceFor(db, today),
              builder: (context, snapshot) {
                final synthesis = snapshot.data
                    ?.where((row) => row.dimension == 'synthesis')
                    .firstOrNull;
                if (synthesis == null) {
                  // An uncomposed reading is content, not a spinner. The
                  // pipeline has simply not been asked yet.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    'Today’s guidance has not been composed yet.',
                    style: supportingStyle,
                  );
                }
                final content = _GuidanceContent.parse(synthesis.contentJson);
                return EterArrival(
                  key: ValueKey('guidance-${synthesis.id}'),
                  passages: [
                    ArrivalPassage(content.passage, style: displayStyle),
                    if (content.supporting != null)
                      ArrivalPassage(content.supporting!, style: supportingStyle),
                  ],
                );
              },
            ),
            const SizedBox(height: EterSpace.s48),
            SurfaceIntentScope(
              intent: SurfaceIntent.plain,
              child: BodySection(
                expanded: _bodyExpanded,
                onToggle: (expanded) =>
                    setState(() => _bodyExpanded = expanded),
              ),
            ),
            const SizedBox(height: EterSpace.s48),
          ],
        ),
      ),
    );
  }
}

/// The synthesis content contract: a primary passage and an optional
/// supporting one. The pipeline is unbuilt, so parse defensively — a bare
/// string is treated as the passage.
class _GuidanceContent {
  const _GuidanceContent(this.passage, this.supporting);

  final String passage;
  final String? supporting;

  static _GuidanceContent parse(String contentJson) {
    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is Map) {
        final passage = decoded['passage'];
        final supporting = decoded['supporting'];
        if (passage is String && passage.trim().isNotEmpty) {
          return _GuidanceContent(
            passage,
            supporting is String && supporting.trim().isNotEmpty
                ? supporting
                : null,
          );
        }
      }
    } on FormatException {
      // Fall through to the bare-string treatment.
    }
    return _GuidanceContent(contentJson, null);
  }
}
