import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/arrival.dart';
import '../../core/clock.dart';
import '../../core/controls.dart';
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
  String? _expandedSection;
  bool _choosingSection = false;
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
  Stream<List<GuidanceHistoryRow>> _guidanceFor(AppDatabase db, String today) {
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
    final displayStyle = MediaQuery.sizeOf(context).width < 360
        ? text.displaySmall
        : text.displayMedium;
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
                      ArrivalPassage(content.supporting!,
                          style: supportingStyle),
                  ],
                );
              },
            ),
            const SizedBox(height: EterSpace.s48),
            if (_expandedSection == 'guidance')
              _ExpandedGuidance(
                rows: db.loadGuidanceForDate(today),
                onClose: () => setState(() => _expandedSection = null),
              )
            else if (_expandedSection == 'body')
              SurfaceIntentScope(
                intent: SurfaceIntent.plain,
                child: BodySection(
                  expanded: true,
                  onToggle: (_) => setState(() => _expandedSection = null),
                ),
              )
            else
              _SectionThreshold(
                choosing: _choosingSection,
                onOpen: () => setState(() => _choosingSection = true),
                onChoose: (section) => setState(() {
                  _expandedSection = section;
                  _choosingSection = false;
                }),
              ),
            const SizedBox(height: EterSpace.s48),
          ],
        ),
      ),
    );
  }
}

class _SectionThreshold extends StatelessWidget {
  const _SectionThreshold({
    required this.choosing,
    required this.onOpen,
    required this.onChoose,
  });

  final bool choosing;
  final VoidCallback onOpen;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: ink.line),
        if (!choosing)
          Semantics(
            button: true,
            label: 'Look deeper',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Text('LOOK DEEPER', style: text.labelSmall),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: ink.labelMuted),
                  ],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: EterSpace.s24,
            runSpacing: EterSpace.s4,
            children: [
              _ThresholdChoice(
                label: 'GUIDANCE',
                onTap: () => onChoose('guidance'),
              ),
              _ThresholdChoice(
                label: 'THE BODY',
                onTap: () => onChoose('body'),
              ),
            ],
          ),
      ],
    );
  }
}

class _ThresholdChoice extends StatelessWidget {
  const _ThresholdChoice({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label.toLowerCase(),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
        ),
      );
}

class _ExpandedGuidance extends StatelessWidget {
  const _ExpandedGuidance({
    required this.rows,
    required this.onClose,
  });

  final Future<List<GuidanceHistoryRow>> rows;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder<List<GuidanceHistoryRow>>(
      future: rows,
      builder: (context, snapshot) {
        final byDimension = {
          for (final row in snapshot.data ?? const <GuidanceHistoryRow>[])
            row.dimension: row,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: ink.line),
            Row(
              children: [
                Text('GUIDANCE', style: text.labelSmall),
                const Spacer(),
                EterAction(
                  label: 'Close',
                  emphasis: EterActionEmphasis.quiet,
                  onPressed: onClose,
                ),
              ],
            ),
            for (final dimension in const ['health', 'mind', 'spirit'])
              if (byDimension[dimension] case final row?)
                _GuidanceDimension(
                  name: dimension,
                  row: row,
                ),
          ],
        );
      },
    );
  }
}

class _GuidanceDimension extends StatelessWidget {
  const _GuidanceDimension({required this.name, required this.row});

  final String name;
  final GuidanceHistoryRow row;

  @override
  Widget build(BuildContext context) {
    final content = _GuidanceContent.parse(row.contentJson);
    final prose = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 19,
          height: 28 / 19,
          fontWeight: FontWeight.w400,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: EterSpace.s8),
          Text(content.passage, style: prose),
          if (row.evidenceJson != null)
            _EvidenceReceipt(raw: row.evidenceJson!, dimension: name),
        ],
      ),
    );
  }
}

class _EvidenceReceipt extends StatefulWidget {
  const _EvidenceReceipt({required this.raw, required this.dimension});

  final String raw;
  final String dimension;

  @override
  State<_EvidenceReceipt> createState() => _EvidenceReceiptState();
}

class _EvidenceReceiptState extends State<_EvidenceReceipt> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final evidence = _decodeEvidence(widget.raw);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label: 'Evidence for ${widget.dimension}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '¹',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: ink.lineStrong),
                ),
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: EterSpace.s8),
            child: Text(
              'n=${evidence['n']} · ${evidence['window']} · '
              'coefficient ${evidence['coefficient']}\n'
              '${evidence['note']} This is an association, not proof of cause.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  static Map<String, Object?> _decodeEvidence(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } on FormatException {
      // The receipt remains inspectable even if an old cached payload is bad.
    }
    return const {
      'n': 'unknown',
      'window': 'window unavailable',
      'coefficient': 'unavailable',
      'note': 'The cached evidence details could not be read.',
    };
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
