import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aether/guidance_mode.dart';
import '../../core/arcana/arcana_card_media.dart';
import '../../core/arcana/major_arcana.dart';
import '../../core/arcana/matrix.dart';
import '../../core/arcana/symbol_content.dart';
import '../../core/arcana/zodiac.dart';
import '../../core/ai/transport.dart';
import '../../core/arrival.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/i18n/language.dart';
import '../../core/i18n/strings.dart';
import '../../core/profile/birth_time.dart';
import '../../core/symbolic/astro_glyphs.dart';
import '../../core/symbolic/chart_wheel.dart';
import '../../core/symbolic/transits.dart';
import '../../core/vessel/positions_composer.dart';
import '../../core/symbolic/natal_chart.dart';
import '../../core/symbolic/numerology.dart';
import '../../core/tokens.dart';
import '../../core/vessel/reading_composer.dart';
import '../../main.dart';

class VesselSection extends ConsumerStatefulWidget {
  const VesselSection({
    super.key,
    required this.db,
    required this.now,
    required this.onClose,
    this.showHeading = true,
  });

  final AppDatabase db;
  final DateTime now;
  final VoidCallback onClose;

  /// Whether to draw its own rule and name. False when something above
  /// already names this section — the Dashboard's threshold row does, and
  /// printing the name twice two lines apart reads as a mistake.
  final bool showHeading;

  @override
  ConsumerState<VesselSection> createState() => _VesselSectionState();
}

class _VesselSectionState extends ConsumerState<VesselSection> {
  late Future<_VesselData?> _data;
  StreamSubscription<ProfileRow?>? _profileSubscription;
  String? _profileFingerprint;
  bool _readingOpen = false;
  bool _chartOpen = false;
  bool _composing = false;
  String? _compositionMessage;

  @override
  void initState() {
    super.initState();
    _data = _load();
    _profileSubscription = widget.db.watchProfile().listen(_profileChanged);
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _profileChanged(ProfileRow? profile) {
    final fingerprint = profile == null
        ? 'none'
        : [
            profile.dob.toIso8601String(),
            profile.birthTimeMinutes,
            profile.birthUtcOffsetMinutes,
            profile.birthLatitude,
            profile.birthLongitude,
            profile.guidanceMode,
          ].join('|');
    if (_profileFingerprint == null) {
      _profileFingerprint = fingerprint;
      return;
    }
    if (_profileFingerprint == fingerprint || !mounted) return;
    _profileFingerprint = fingerprint;
    setState(() {
      _readingOpen = false;
      _chartOpen = false;
      _compositionMessage = null;
      _data = _load();
    });
  }

  Future<_VesselData?> _load() async {
    final profile = await widget.db.loadProfile();
    if (profile == null) return null;
    _profileFingerprint = [
      profile.dob.toIso8601String(),
      profile.birthTimeMinutes,
      profile.birthUtcOffsetMinutes,
      profile.birthLatitude,
      profile.birthLongitude,
      profile.guidanceMode,
    ].join('|');
    final content = await SymbolContent.load(
      language: AppLanguage.forProfile(profile.language),
    );
    final minutes = profile.birthTimeMinutes ?? 12 * 60;
    final input = NatalInput(
      localDateTime: DateTime(
        profile.dob.year,
        profile.dob.month,
        profile.dob.day,
        minutes ~/ 60,
        minutes % 60,
      ),
      utcOffsetMinutes: profile.birthUtcOffsetMinutes ?? 0,
      latitude: profile.birthLatitude ?? 0,
      longitude: profile.birthLongitude ?? 0,
    );
    final chart = NatalChartEngine().calculate(input);
    final lifePath = calculateLifePath(profile.dob);
    final hash = natalInputHash(
      dob: profile.dob,
      birthTimeMinutes: profile.birthTimeMinutes,
      birthTimePrecision: profile.birthTimePrecision,
      birthUtcOffsetMinutes: profile.birthUtcOffsetMinutes,
      birthLatitude: profile.birthLatitude,
      birthLongitude: profile.birthLongitude,
    );
    final readings = <String, VesselReadingRow?>{
      for (final key in [
        'lifePath',
        'sun',
        'moon',
        'ascendant',
        for (final position in MatrixPosition.values) position.key,
        for (final name in _VesselData.chartBodies) name.toLowerCase(),
      ])
        key: await widget.db.loadVesselReading(
          inputHash: hash,
          positionKey: key,
        ),
    };
    return _VesselData(
      content: content,
      chart: chart,
      lifePath: lifePath,
      readings: readings,
      dob: profile.dob,
      inputHash: hash,
      mode: switch (profile.guidanceMode) {
        'grounded' => GuidanceMode.grounded,
        'immersive' => GuidanceMode.immersive,
        _ => GuidanceMode.balanced,
      },
      // A remembered period is approximate even though a minute is stored:
      // the ascendant crosses a sign roughly every two hours, so a three-hour
      // window is most of a sign and must be hedged like an unknown time.
      usedApproximateTime: !BirthTimePrecision.fromName(
            profile.birthTimePrecision,
          ).supportsPreciseAngles ||
          profile.birthUtcOffsetMinutes == null,
      usedApproximatePlace:
          profile.birthLatitude == null || profile.birthLongitude == null,
    );
  }

  Future<void> _compose(
    _VesselData data,
    List<_VesselPosition> targets,
  ) async {
    if (_composing) return;
    final strings = EterStrings.of(context);
    final provider = ref.read(vesselReadingTransportProvider);
    if (provider == null) {
      setState(() {
        _compositionMessage = strings.personalReadingNotConnected;
      });
      return;
    }
    setState(() {
      _composing = true;
      _compositionMessage = null;
    });
    try {
      final result = await VesselReadingComposer(
        database: widget.db,
        provider: provider,
      ).compose(
        inputHash: data.inputHash,
        request: VesselReadingRequest(
          mode: data.mode,
          // Sent as the reader sees them, in the reader's language, because the
          // passage is an interpretation of the words on their screen. The
          // instruction that travels with this says which language to answer
          // in; see `core/ai/prompts.dart`.
          positions: [
            for (final position in targets)
              VesselReadingPosition(
                key: position.key,
                label: position.label(strings),
                card: strings.arcanaTitle(position.card.assetSlug),
                keywords: position.keywords,
                detail: position.detail(strings),
              ),
          ],
          approximateTime: data.usedApproximateTime,
          approximatePlace: data.usedApproximatePlace,
        ),
        now: widget.now,
      );
      if (!mounted) return;
      setState(() {
        _composing = false;
        data.readings.addAll(result.rows);
        _compositionMessage = result.fromCache
            ? strings.everyReadingAlreadyComposed
            : strings.missingReadingsComposed;
      });
    } on VesselReadingException catch (error) {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = error.reason == 'AI processing is not permitted'
            ? strings.enableAiBeforeComposing
            // Everything else here is the parser or the safety gate refusing
            // what came back, and saying which is more use than a single
            // sentence covering both. The reason itself stays English: it is a
            // contract value, not copy, and inventing a Polish rendering of
            // every parser failure would be translating a diagnostic.
            : strings.readingNotAccepted(error.reason);
      });
    } on EterTransportException catch (error) {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = error.reason;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = strings.compositionUnavailableCachedRemain;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    return FutureBuilder<_VesselData?>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeading) Container(height: 1, color: ink.line),
            Row(
              children: [
                // Expanded rather than a bare Text beside a Spacer: the heading
                // and the close action together are wider than 320 dp at 200%
                // text once either word grows, and a Spacer cannot give back
                // space a fixed child has already claimed. With no heading
                // there is nothing to push against, and the action sits left
                // like everything else in this column.
                if (widget.showHeading)
                  Expanded(
                    child: Text(strings.theVessel, style: text.labelSmall),
                  ),
                EterAction(
                  label: strings.close,
                  emphasis: EterActionEmphasis.quiet,
                  onPressed: widget.onClose,
                ),
              ],
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              Text(strings.readingChartOnDevice, style: text.bodyMedium)
            else if (data == null)
              Text(
                strings.birthDetailsNeededForVessel,
                style: text.bodyMedium,
              )
            else ...[
              // The chart itself, above everything written about it. Every
              // other symbolic surface here is prose about a chart nobody
              // could see.
              const SizedBox(height: EterSpace.s16),
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) => NatalChartWheel(
                    chart: data.chart,
                    size: constraints.maxWidth.clamp(240.0, 340.0),
                    ascendantReliable: !data.usedApproximateTime &&
                        !data.usedApproximatePlace,
                  ),
                ),
              ),
              const SizedBox(height: EterSpace.s24),
              _SunCard(data: data),
              if (data.usedApproximateTime || data.usedApproximatePlace) ...[
                const SizedBox(height: EterSpace.s16),
                Text(
                  _approximationNote(data, strings),
                  style: text.bodySmall?.copyWith(color: ink.labelMuted),
                ),
              ],
              const SizedBox(height: EterSpace.s16),
              // The written astrogram. The wheel above is the only surface in
              // the Vessel with no passage behind it; this is that passage,
              // one per remaining body, composed through the same composer
              // and cached under the same inputHash as every other reading —
              // a chart is paid for once (AI_FLOW.md is the authority).
              EterAction(
                label: _chartOpen ? strings.showLess : strings.chartGoDeeper,
                emphasis: EterActionEmphasis.secondary,
                onPressed: () => setState(() => _chartOpen = !_chartOpen),
              ),
              if (_chartOpen) ...[
                const SizedBox(height: EterSpace.s16),
                for (final position in data.chartPositions())
                  _ComposedReading(
                    position: position,
                    reading: data.readings[position.key],
                    fullWidth: Theme.of(context).brightness ==
                            Brightness.dark &&
                        data.mode != GuidanceMode.grounded,
                  ),
                if (data
                    .chartPositions()
                    .any((position) => data.readings[position.key] == null))
                  EterAction(
                    label: _composing
                        ? strings.composing
                        : strings.composeReadings,
                    emphasis: EterActionEmphasis.quiet,
                    busy: _composing,
                    onPressed: () =>
                        _compose(data, data.chartPositions()),
                  ),
                // Guarded so the same live message is never announced from
                // two places when both panels are open — the readings panel
                // below already carries it then.
                if (_compositionMessage != null && !_readingOpen) ...[
                  const SizedBox(height: EterSpace.s8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _compositionMessage!,
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: EterSpace.s24),
              // One list at two depths, never two lists. Read deeper used to
              // append a second copy of the same four positions underneath the
              // first, so the same headings appeared twice on one screen; it
              // now deepens the list in place.
              for (final position in data.positions(strings))
                if (_readingOpen)
                  _ComposedReading(
                    position: position,
                    reading: data.readings[position.key],
                    // The Sun card is already on screen at full width a few
                    // lines above; a position resolving to the same card does
                    // not print it twice.
                    showCard: position.key != 'sun',
                    // At night in the balanced and immersive registers the
                    // deck is the point, and every card takes the Sun card's
                    // measure. Grounded keeps them small in both skies — that
                    // register asked for less theatre — and day keeps them
                    // small because still art at full width four times over
                    // reads as a gallery, not a reading.
                    fullWidth: Theme.of(context).brightness ==
                            Brightness.dark &&
                        data.mode != GuidanceMode.grounded,
                  )
                else
                  _PositionLine(position: position),
              const SizedBox(height: EterSpace.s16),
              EterAction(
                label: _readingOpen ? strings.showLess : strings.readDeeper,
                emphasis: EterActionEmphasis.secondary,
                onPressed: () => setState(() => _readingOpen = !_readingOpen),
              ),
              if (_readingOpen) ...[
                const SizedBox(height: EterSpace.s16),
                if (data.readings.values.any((reading) => reading == null))
                  EterAction(
                    label: _composing
                        ? strings.composing
                        : strings.composeReadings,
                    emphasis: EterActionEmphasis.quiet,
                    busy: _composing,
                    onPressed: () => _compose(data, data.positions(strings)),
                  ),
                if (_compositionMessage != null) ...[
                  const SizedBox(height: EterSpace.s8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _compositionMessage!,
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: EterSpace.s24),
              _Positions(data: data, now: widget.now),
            ],
            const SizedBox(height: EterSpace.s32),
          ],
        );
      },
    );
  }

  static String _approximationNote(_VesselData data, EterStrings strings) {
    if (data.usedApproximateTime && data.usedApproximatePlace) {
      return strings.approximateTimeAndPlace;
    }
    if (data.usedApproximateTime) return strings.approximateTime;
    return strings.approximatePlace;
  }
}

/// The card a person is born under.
///
/// There was a "card of the day" here, and it was two failures wearing one
/// name: it was written only by the prototype fixtures, so no real user ever
/// saw one, and its selector was the personal *year*, which changes annually.
/// Rather than repair a daily card, the Vessel now leads with the one card
/// that is genuinely, permanently theirs — the Arcana of their Sun sign,
/// fixed at birth and identical every time they open it.
class _SunCard extends StatelessWidget {
  const _SunCard({required this.data});

  final _VesselData data;

  @override
  Widget build(BuildContext context) {
    final strings = EterStrings.of(context);
    final sun = data.positions(strings).firstWhere((p) => p.key == 'sun');
    final attributes = data.content.card(sun.card);
    final title = strings.arcanaTitle(sun.card.assetSlug);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: EterSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nearly the full measure. This is the most considered art in the
          // product and the one image the Vessel is about; at thumbnail size
          // it read as decoration beside the text.
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EterSpace.rChip),
              child: LayoutBuilder(
                builder: (context, constraints) => EterArcanaPlate(
                  card: sun.card,
                  width: constraints.maxWidth.clamp(200.0, 420.0),
                  semanticLabel: strings.sunCardSemantic(title),
                ),
              ),
            ),
          ),
          const SizedBox(height: EterSpace.s16),
          Text(strings.headingYourCard, style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          Text(title, style: text.headlineSmall),
          if (attributes != null) ...[
            const SizedBox(height: EterSpace.s4),
            Text(attributes.subtitle, style: text.bodySmall),
          ],
          const SizedBox(height: EterSpace.s8),
          // The canonical sign, not the printed degree line: the sentence needs
          // to decline the sign's name, which it cannot do to `12.4° Baran`.
          Text(strings.sunSitsIn(sun.signCanonical), style: text.bodySmall),
        ],
      ),
    );
  }
}

/// One Arcana card as the Vessel shows it: the shipped still, with the night
/// loop composited on top wherever the deck has one.
///
/// Day is still and night moves — the same register rule the shell follows —
/// and reduced motion is still everywhere. The static art is always drawn
/// underneath, so a missing or slow loop is invisible rather than a gap.
class EterArcanaPlate extends StatelessWidget {
  const EterArcanaPlate({
    super.key,
    required this.card,
    required this.width,
    this.semanticLabel,
  });

  final MajorArcana card;
  final double width;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      image: true,
      label: semanticLabel ?? EterStrings.of(context).arcanaTitle(card.assetSlug),
      excludeSemantics: true,
      child: ArcanaCardMedia(
        path: card.assetFor(brightness),
        videoPath: reduceMotion ? null : card.nightLoopFor(brightness),
        lightOverlay: brightness == Brightness.light,
        width: width,
        height: width * 1.485,
      ),
    );
  }
}

/// Today's Positions — the only part of the Vessel that changes daily.
///
/// The natal chart is fixed and its readings are written once. This is the sky
/// moving against it: contacts computed on the device, always present and
/// costing nothing, with a passage that is written once per day and cached.
///
/// The contacts are shown whether or not the prose exists, because they are
/// the actual finding. The prose is an interpretation of them.
class _Positions extends ConsumerStatefulWidget {
  const _Positions({required this.data, required this.now});

  final _VesselData data;
  final DateTime now;

  @override
  ConsumerState<_Positions> createState() => _PositionsState();
}

class _PositionsState extends ConsumerState<_Positions> {
  TransitReading? _reading;
  PositionsPassage? _passage;
  bool _busy = false;
  String? _message;

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not `initState`: the first load reads the string table for its failure
    // sentences, and an inherited widget may not be looked up before
    // `initState` has returned. Guarded, because this also runs whenever the
    // language or the register changes and the contacts are the same either way
    // — they are arithmetic, and re-fetching them would only re-request the
    // passage.
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load({bool compose = false}) async {
    if (_busy) return;
    final strings = EterStrings.of(context);
    setState(() {
      _busy = compose;
      if (compose) _message = null;
    });
    try {
      final profile = await ref.read(databaseProvider).loadProfile();
      if (profile == null) return;
      final reading = _reading ??
          TransitEngine().forDay(
            natal: widget.data.chart,
            at: widget.now,
            latitude: profile.birthLatitude ?? 0,
            longitude: profile.birthLongitude ?? 0,
          );
      final result = await PositionsComposer(
        database: ref.read(databaseProvider),
        provider: ref.read(positionsTransportProvider),
      ).forDay(
        reading: reading,
        inputHash: widget.data.inputHash,
        mode: widget.data.mode,
        ascendantReliable: !widget.data.usedApproximateTime &&
            !widget.data.usedApproximatePlace,
        now: widget.now,
        compose: compose,
      );
      if (!mounted) return;
      setState(() {
        _reading = result.reading;
        _passage = result.passage;
        _busy = false;
      });
    } on PositionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = error.reason == 'AI processing is not permitted'
            ? strings.enableAiBeforeReadingToday
            : strings.todaysReadingNotConnected;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = strings.todaysReadingCouldNotBeWritten;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);
    final reading = _reading;
    if (reading == null) return const SizedBox.shrink();

    final contacts = reading.contacts.take(4).toList();
    // `toJson` is the reading's own serialisation and carries canonical English
    // names, which is exactly what the localised lookups want.
    final json = reading.toJson();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ink.line)),
      ),
      padding: const EdgeInsets.only(top: EterSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.headingPositionsToday, style: text.labelSmall),
          const SizedBox(height: EterSpace.s8),
          Text(
            strings.positionsSummary(
              moonPhaseCanonical: reading.moonPhaseLabel,
              moonSignCanonical: '${json['moonSign']}',
              sunSignCanonical: '${json['sunSign']}',
            ),
            style: text.bodyMedium,
          ),
          const SizedBox(height: EterSpace.s12),
          if (contacts.isEmpty)
            Text(strings.nothingCloseInTheSky, style: text.bodySmall)
          else
            for (final contact in contacts)
              Padding(
                padding: const EdgeInsets.only(bottom: EterSpace.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        strings.contactLine(
                          transiting: strings.bodyName(contact.transiting),
                          aspect: strings.aspectName(contact.type),
                          natal: strings.bodyName(contact.natal),
                        ),
                        style: text.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: EterSpace.s8),
                    // Flexible, not a bare Text. A non-flex child beside an
                    // Expanded is laid out at its full intrinsic width first,
                    // so a long one overflows the row no matter how much the
                    // Expanded gives up: `zbliża się` is three times the width
                    // of `applying`, and at 320 dp with text doubled that ran
                    // ten pixels past the edge.
                    Flexible(
                      child: Text(
                        strings.contactOrb(
                          degrees: contact.orb.toStringAsFixed(1),
                          applying: contact.applying,
                        ),
                        textAlign: TextAlign.end,
                        style: text.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
          if (_passage != null) ...[
            const SizedBox(height: EterSpace.s16),
            EterArrival.single(
              _passage!.passage,
              key: ValueKey('positions-${reading.forDate}'),
              style: text.headlineSmall?.copyWith(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ] else ...[
            const SizedBox(height: EterSpace.s12),
            EterAction(
              label: _busy ? strings.readingToday : strings.readToday,
              emphasis: EterActionEmphasis.secondary,
              busy: _busy,
              onPressed: () => _load(compose: true),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: EterSpace.s8),
            Semantics(
              liveRegion: true,
              child: Text(_message!, style: text.bodySmall),
            ),
          ],
          const SizedBox(height: EterSpace.s16),
        ],
      ),
    );
  }
}

class _PositionLine extends StatelessWidget {
  const _PositionLine({required this.position});

  final _VesselPosition position;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final detail = position.detail(strings);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ink.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: EterSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Keyed on the canonical body, never on the printed label.
              if (position.bodyCanonical case final body?)
                if (AstroGlyph.forBody(body) case final glyph?) ...[
                  AstroGlyphMark(
                    glyph: glyph,
                    color: ink.labelMuted,
                    size: 14,
                  ),
                  const SizedBox(width: EterSpace.s8),
                ],
              // Expanded, so the label wraps rather than running off the row.
              // It held an unbounded `Text` for as long as every label was a
              // short English word; `ODZIEDZICZONE` and `MEDIUM COELI` at
              // 320 dp with text doubled overflow it by ten pixels, which the
              // Polish goldens caught at exactly that size.
              Expanded(
                child: Text(
                  position.label(strings).toUpperCase(),
                  style: text.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: EterSpace.s4),
          Text(
            '${strings.arcanaTitle(position.card.assetSlug)} · '
            '${position.keywords.join(', ')}',
            style: text.titleMedium,
          ),
          if (detail != null) ...[
            const SizedBox(height: EterSpace.s4),
            Row(
              children: [
                if (position.signCanonical case final sign?)
                  if (AstroGlyph.forSign(sign) case final glyph?) ...[
                    AstroGlyphMark(
                      glyph: glyph,
                      color: ink.labelMuted,
                      size: 12,
                    ),
                    const SizedBox(width: EterSpace.s4),
                  ],
                Expanded(child: Text(detail, style: text.bodySmall)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ComposedReading extends StatelessWidget {
  const _ComposedReading({
    required this.position,
    required this.reading,
    this.showCard = true,
    this.fullWidth = false,
  });

  final _VesselPosition position;
  final VesselReadingRow? reading;
  final bool showCard;

  /// Whether this card takes the Sun card's measure rather than the 132 dp
  /// thumbnail. Decided by the caller, who knows the sky and the register.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final title = strings.arcanaTitle(position.card.assetSlug);
    final passage = reading == null ? null : _passage(reading!.contentJson);
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Every reading is headed by its own card. Read deeper is where the
          // deck earns its place: the passage is about that card, so the card
          // sits above the passage rather than being named in it.
          if (showCard) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(EterSpace.rChip),
                child: LayoutBuilder(
                  builder: (context, constraints) => EterArcanaPlate(
                    card: position.card,
                    // The same clamp the Sun card uses, so "full" means equal
                    // rather than merely bigger.
                    width: fullWidth
                        ? constraints.maxWidth.clamp(200.0, 420.0)
                        : 132,
                    semanticLabel: strings.positionCardSemantic(
                      cardTitle: title,
                      positionLabel: position.label(strings),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: EterSpace.s12),
          ],
          Text(position.label(strings).toUpperCase(), style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          // The keywords stay visible at depth: the passage interprets them,
          // and losing them on opening made the deeper view feel like a
          // different subject rather than the same one, closer.
          Text(
            '$title · ${position.keywords.join(', ')}',
            style: text.titleMedium,
          ),
          const SizedBox(height: EterSpace.s8),
          Text(
            passage ?? strings.personalReadingNotComposedYet,
            style: text.headlineSmall?.copyWith(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  static String? _passage(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is Map && value['passage'] is String) {
        return value['passage'] as String;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

class _VesselData {
  _VesselData({
    required this.content,
    required this.chart,
    required this.lifePath,
    required this.readings,
    required this.dob,
    required this.inputHash,
    required this.mode,
    required this.usedApproximateTime,
    required this.usedApproximatePlace,
  });

  final SymbolContent content;
  final NatalChart chart;
  final int lifePath;
  final Map<String, VesselReadingRow?> readings;
  final DateTime dob;
  final String inputHash;
  final GuidanceMode mode;
  final bool usedApproximateTime;
  final bool usedApproximatePlace;

  /// The bodies the astrogram explanation covers, beyond the three the main
  /// list already reads. The engine's own English names; keys are these,
  /// lowercased.
  static const chartBodies = [
    'Mercury',
    'Venus',
    'Mars',
    'Jupiter',
    'Saturn',
    'Uranus',
    'Neptune',
  ];

  /// The rest of the chart, one position per planet, for "go deeper" under
  /// the wheel. Same shape as [positions] so the same composer, cache and
  /// row widget serve both — the whole point of not making this a new call.
  List<_VesselPosition> chartPositions() => [
        for (final name in chartBodies)
          for (final point in chart.positions.where((p) => p.name == name))
            _signPosition(name.toLowerCase(), name, point),
      ];

  _VesselPosition _signPosition(
    String key,
    String bodyCanonical,
    ZodiacPosition point,
  ) {
    // `point.sign` is the engine's English name, and `Zodiac.label` is the
    // English canon it is matched against. Neither is ever localised, which
    // is what keeps this lookup working in Polish.
    final sign =
        Zodiac.values.firstWhere((value) => value.label == point.sign);
    final card = MajorArcana.forZodiac(sign);
    final attributes = content.card(card)!;
    return _VesselPosition(
      key: key,
      bodyCanonical: bodyCanonical,
      card: card,
      keywords: attributes.keywords,
      signCanonical: point.sign,
      degrees: point.degreeInSign,
      retrograde: point.retrograde,
    );
  }

  List<_VesselPosition> positions(EterStrings strings) {
    final lifeCard = MajorArcana.forLifePath(lifePath);
    return [
      _VesselPosition(
        key: 'lifePath',
        displayLabel: strings.lifePathLabel(lifePath),
        card: lifeCard,
        keywords: content.lifePath(lifePath)!.keywords,
      ),
      _signPosition('sun', 'Sun', chart.sun),
      _signPosition('moon', 'Moon', chart.moon),
      _signPosition('ascendant', 'Ascendant', chart.ascendant),
      // The figure reads after the chart, because it explains where the Life
      // Path card at the top came from.
      for (final entry in buildArcanaMatrix(dob).inReadingOrder)
        _VesselPosition(
          key: entry.position.key,
          displayLabel: strings.matrixPositionLabel(entry.position),
          card: entry.card,
          keywords: content.card(entry.card)?.keywords ?? const [],
          // The row carries a short mark, as the sign positions do. The
          // position's sentence is context for the model, not a caption —
          // putting it here overflowed the line by 246 pixels, which is the
          // layout saying the same thing.
          numeral: entry.card.numeral,
        ),
    ];
  }
}

/// One place in the Vessel, kept as data rather than as rendered text.
///
/// It used to carry a `label` and a `detail` string and nothing else, which made
/// two different things the same field. `label` was shown to the reader *and*
/// handed to `AstroGlyph.forBody`; `detail` was shown to the reader *and* split
/// on whitespace so its first word could be handed to `AstroGlyph.forSign`. Both
/// worked exactly as long as the strings stayed English — the moment `Sun`
/// became `Słońce`, every glyph in the Vessel would have silently vanished,
/// because a failed lookup returns null and null draws nothing.
///
/// So identity and presentation are separated. [bodyCanonical] and
/// [signCanonical] are the chart engine's own English names and are what the
/// glyph tables and caches key on; the label and the degree line are composed at
/// render time from the active language. A position that is not a chart point —
/// a Life Path, a place in the matrix figure — carries a [displayLabel] instead
/// and no canonical body.
class _VesselPosition {
  const _VesselPosition({
    required this.key,
    required this.card,
    required this.keywords,
    this.bodyCanonical,
    this.displayLabel,
    this.signCanonical,
    this.degrees,
    this.retrograde = false,
    this.numeral,
  });

  /// Cache key for this position's composed reading. Never translated: it is
  /// part of the `VesselReadings` primary key.
  final String key;
  final MajorArcana card;
  final List<String> keywords;

  /// `'Sun'`, `'Moon'`, `'Ascendant'` — the engine's name, for glyphs and
  /// lookups. Null for the Life Path and the matrix positions.
  final String? bodyCanonical;

  /// Used when there is no canonical body to name, and already localised.
  final String? displayLabel;

  final String? signCanonical;
  final double? degrees;
  final bool retrograde;

  /// The matrix rows carry the card's Roman numeral where a sign position
  /// carries its degree. Language-independent by nature.
  final String? numeral;

  String label(EterStrings strings) => bodyCanonical == null
      ? displayLabel!
      : strings.bodyName(bodyCanonical!);

  /// The short second line: a degree and sign, a numeral, or nothing.
  String? detail(EterStrings strings) {
    if (numeral != null) return numeral;
    final sign = signCanonical;
    if (sign == null || degrees == null) return null;
    return strings.positionDetail(
      signName: strings.signName(sign),
      degrees: degrees!.toStringAsFixed(1),
      retrograde: retrograde,
    );
  }
}
