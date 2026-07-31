import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/arrival.dart';
import '../../core/aether/composer.dart';
import '../../core/aether/context_assembler.dart';
import '../../core/aether/guidance_contract.dart';
import '../../core/aether/request_contract.dart';
import '../../core/ai/transport.dart';
import '../../core/clock.dart';
import '../../core/correspondence/correspondence.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/i18n/strings.dart';
import '../../core/icons.dart';
import '../../core/register.dart';
import '../../core/tokens.dart';
import '../../main.dart';
import '../vessel/vessel_section.dart';
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
  bool _composing = false;
  String? _compositionMessage;

  /// The day this surface has already offered to compose for. Guidance is the
  /// day's first sentence; asking the user to press a button for it every
  /// morning made the product feel like it was waiting to be operated.
  String? _autoComposedDay;

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

  Future<void> _compose(AppDatabase db, DateTime now) async {
    if (_composing) return;
    // Captured before the first await: this is the only place in the file that
    // needs words outside `build`, and reading the scope after an await would
    // touch a possibly-unmounted context.
    final strings = EterStrings.of(context);
    final provider = ref.read(aetherTransportProvider);
    if (provider == null) {
      setState(() {
        _compositionMessage = strings.aetherNotConnected;
      });
      return;
    }
    setState(() {
      _composing = true;
      _compositionMessage = null;
    });
    try {
      final request =
          await AetherContextAssembler(database: db).assemble(now: now);
      final result = await AetherComposer(
        database: db,
        provider: provider,
      ).compose(request, now: now);
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = result.fromCache
            ? strings.guidanceAlreadyCurrent
            : strings.guidanceComposed;
      });
    } on AetherConsentException {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = strings.enableAiBeforeComposing;
      });
    } on AetherContractException {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = strings.responseNotAcceptedSafely;
      });
    } on EterTransportException catch (error) {
      // Named separately because "unavailable right now" is useless when the
      // real answer is that the endpoint is unreachable, and the person can
      // do something about that.
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = error.reason;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = strings.compositionUnavailable;
      });
    }
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
                  // Once per local day, and only once: the first look at the
                  // Dashboard composes on its own. `_autoComposedDay` is set
                  // before the attempt, so a failure does not retry on every
                  // rebuild — the explicit action below is the retry.
                  if (_autoComposedDay != today &&
                      ref.read(aetherTransportProvider) != null) {
                    _autoComposedDay = today;
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _compose(db, now),
                    );
                  }
                  return _UncomposedGuidance(
                    style: supportingStyle,
                    composing: _composing,
                    message: _compositionMessage,
                    onCompose: () => _compose(db, now),
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
            // One extra line beneath today's guidance, and that is the whole
            // surface of the Correspondence. Not a screen, not a feed, and
            // nothing when there is no correspondence or they have not written
            // today — see `DECISIONS.md` on extension over destinations.
            _CorrespondingLine(today: today, now: now),
            const SizedBox(height: EterSpace.s48),
            if (_expandedSection == 'guidance')
              _ExpandedGuidance(
                rows: db.loadGuidanceForDate(today),
                composing: _composing,
                message: _compositionMessage,
                onRefresh: () => _compose(db, now),
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
            else if (_expandedSection == 'vessel')
              VesselSection(
                db: db,
                now: now,
                onClose: () => setState(() => _expandedSection = null),
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

class _UncomposedGuidance extends StatelessWidget {
  const _UncomposedGuidance({
    required this.style,
    required this.composing,
    required this.message,
    required this.onCompose,
  });

  final TextStyle? style;
  final bool composing;
  final String? message;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            composing
                ? EterStrings.of(context).composingTodaysGuidance
                : EterStrings.of(context).guidanceNotComposedYet,
            style: style,
          ),
          // Composition is automatic on the day's first look, so this is a
          // retry rather than the way in. It is smaller and quieter than the
          // sentence above it, and it says nothing while it is working.
          if (!composing) ...[
            const SizedBox(height: EterSpace.s12),
            EterAction(
              label: EterStrings.of(context).composeNow,
              emphasis: EterActionEmphasis.quiet,
              onPressed: onCompose,
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: EterSpace.s8),
            Semantics(
              liveRegion: true,
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      );
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
    final strings = EterStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: ink.line),
        if (!choosing)
          Semantics(
            button: true,
            label: strings.lookDeeper.toLowerCase(),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(strings.lookDeeper, style: text.labelSmall),
                    ),
                    const SizedBox(width: EterSpace.s8),
                    const EterDisclosureMark(),
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
                label: strings.sectionGuidance,
                onTap: () => onChoose('guidance'),
              ),
              _ThresholdChoice(
                label: strings.sectionBody,
                onTap: () => onChoose('body'),
              ),
              _ThresholdChoice(
                label: strings.sectionVessel,
                onTap: () => onChoose('vessel'),
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
    required this.composing,
    required this.message,
    required this.onRefresh,
    required this.onClose,
  });

  final Future<List<GuidanceHistoryRow>> rows;
  final bool composing;
  final String? message;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    return FutureBuilder<List<GuidanceHistoryRow>>(
      future: rows,
      builder: (context, snapshot) {
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
        final byDimension = {
          for (final row in snapshot.data ?? const <GuidanceHistoryRow>[])
            row.dimension: row,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: ink.line),
            if (largeText) ...[
              Text(strings.sectionGuidance, style: text.labelSmall),
              _GuidanceHeaderActions(
                composing: composing,
                onRefresh: onRefresh,
                onClose: onClose,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.sectionGuidance, style: text.labelSmall),
                  const SizedBox(width: EterSpace.s12),
                  Expanded(
                    child: _GuidanceHeaderActions(
                      composing: composing,
                      onRefresh: onRefresh,
                      onClose: onClose,
                    ),
                  ),
                ],
              ),
            if (message != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: EterSpace.s12),
                  child: Text(message!, style: text.bodySmall),
                ),
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

class _GuidanceHeaderActions extends StatelessWidget {
  const _GuidanceHeaderActions({
    required this.composing,
    required this.onRefresh,
    required this.onClose,
  });

  final bool composing;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.end,
        spacing: EterSpace.s8,
        runSpacing: EterSpace.s4,
        children: [
          EterAction(
            label: composing
                ? EterStrings.of(context).composing
                : EterStrings.of(context).refresh,
            emphasis: EterActionEmphasis.quiet,
            busy: composing,
            onPressed: onRefresh,
          ),
          EterAction(
            label: EterStrings.of(context).close,
            emphasis: EterActionEmphasis.quiet,
            onPressed: onClose,
          ),
        ],
      );
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
          Text(EterStrings.of(context).guidanceDimension(name),
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
    final strings = EterStrings.of(context);
    final evidence = _decodeEvidence(widget.raw, strings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label: strings.evidenceFor(
            strings.guidanceDimension(widget.dimension).toLowerCase(),
          ),
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
              strings.evidenceReceipt(
                n: evidence['n'],
                window: evidence['window'],
                coefficient: evidence['coefficient'],
                note: evidence['note'],
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  static Map<String, Object?> _decodeEvidence(
    String raw,
    EterStrings strings,
  ) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } on FormatException {
      // The receipt remains inspectable even if an old cached payload is bad.
    }
    return {
      'n': strings.evidenceUnknownCount,
      'window': strings.evidenceWindowUnavailable,
      'coefficient': strings.evidenceCoefficientUnavailable,
      'note': strings.evidenceUnreadable,
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
        final sentences = decoded['sentences'];
        final primaryAction = decoded['primaryAction'];
        if (sentences is List &&
            sentences.isNotEmpty &&
            sentences.every((item) => item is String)) {
          final prose = sentences
              .cast<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .join(' ');
          if (prose.isNotEmpty) {
            return _GuidanceContent(
              prose,
              primaryAction is String && primaryAction.trim().isNotEmpty
                  ? primaryAction.trim()
                  : null,
            );
          }
        }
      }
    } on FormatException {
      // Fall through to the bare-string treatment.
    }
    return _GuidanceContent(contentJson, null);
  }
}

/// The other person's day, in one line.
///
/// Renders nothing at all unless there is a correspondence, they have written
/// today, and their sentence passes the policy on the way in. Every one of
/// those is an ordinary state rather than an error, so none of them produces a
/// message: an empty space is the correct rendering of "they have not written
/// yet", and a placeholder saying so would turn a quiet feature into a nag
/// about somebody else's habits.
class _CorrespondingLine extends ConsumerStatefulWidget {
  const _CorrespondingLine({required this.today, required this.now});

  final String today;
  final DateTime now;

  @override
  ConsumerState<_CorrespondingLine> createState() => _CorrespondingLineState();
}

class _CorrespondingLineState extends ConsumerState<_CorrespondingLine> {
  Future<CorrespondenceLine?>? _line;
  String? _exchangedDay;

  Future<CorrespondenceLine?> _exchange() async {
    final service = ref.read(correspondenceServiceProvider);
    if (service == null) return null;
    final db = ref.read(databaseProvider);
    // Ours goes out with theirs coming back, in one pass: the synthesis is
    // already on the device by the time this builds, and a second trip to
    // publish it would be a second failure to handle.
    final synthesis = (await db.loadGuidanceForDate(widget.today))
        .where((row) => row.dimension == 'synthesis')
        .firstOrNull;
    return service.exchange(
      now: widget.now,
      todaysSentence: synthesis == null
          ? null
          : _GuidanceContent.parse(synthesis.contentJson).passage,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exchangedDay != widget.today) {
      _exchangedDay = widget.today;
      _line = _exchange();
    }
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);

    return FutureBuilder<CorrespondenceLine?>(
      future: _line,
      builder: (context, snapshot) {
        final line = snapshot.data;
        if (line == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: EterSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attributed, like everything else on this page that somebody
              // else wrote. Unlabelled prose beneath your own guidance reads
              // as your own, and this sentence is about another person's day.
              Text(strings.correspondenceTheirDay, style: text.labelSmall),
              const SizedBox(height: EterSpace.s8),
              Text(
                line.sentence,
                style: text.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: ink.labelMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
