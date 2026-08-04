import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aether/guidance_mode.dart';
import '../../core/arcana/arcana_card_media.dart';
import '../../core/arcana/major_arcana.dart';
import '../../core/arcana/matrix.dart';
import '../../core/arcana/symbol_content.dart';
import '../../core/arcana/zodiac.dart';
import '../../core/arrival.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
import '../../core/i18n/language.dart';
import '../../core/i18n/strings.dart';
import '../../core/profile/birth_time.dart';
import '../../core/symbolic/chart_wheel.dart';
import '../../core/symbolic/transits.dart';
import '../../core/vessel/positions_composer.dart';
import '../../core/symbolic/natal_chart.dart';
import '../../core/symbolic/numerology.dart';
import '../../core/tokens.dart';
import '../../core/vessel/chart_reading.dart';
import '../../core/vessel/reading_composer.dart';
import '../../main.dart';

class VesselSection extends ConsumerStatefulWidget {
  const VesselSection({
    super.key,
    required this.db,
    required this.now,
    this.showHeading = true,
  });

  final AppDatabase db;
  final DateTime now;

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
  bool _composing = false;

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
    final stored = await widget.db.loadVesselReading(
      inputHash: hash,
      positionKey: vesselConfigurationKey,
    );
    return _VesselData(
      content: content,
      chart: chart,
      lifePath: lifePath,
      movements: stored == null
          ? const []
          : VesselConfiguration.decode(stored.contentJson),
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
      birthTimeGiven: profile.birthTimeMinutes != null &&
          profile.birthUtcOffsetMinutes != null,
    );
  }

  /// Writes the chart's reading if it is missing and can be written.
  ///
  /// Silent, and with no control anywhere near it. The reading is composed
  /// when a birth time is saved — see `InitialVesselReadings` — and this is
  /// the retry for the save that happened with no network, no consent yet, or
  /// no transport. Without it a single failed attempt would leave the reading
  /// permanently unwritten, because there is no longer a button to ask again
  /// with and no background poll to notice.
  Future<void> _composeIfMissing(_VesselData data) async {
    if (_composing || data.movements.isNotEmpty) return;
    // Nothing is written from a noon guess. A chart's angles are most of what
    // makes a configuration particular, and a reading of the wrong ones would
    // cache for life.
    if (!data.knowsBirthTime) return;
    final provider = ref.read(vesselReadingTransportProvider);
    if (provider == null) return;
    final strings = EterStrings.of(context);
    setState(() => _composing = true);
    try {
      final profile = await widget.db.loadProfile();
      // Every exit from here clears the flag in the `finally`. It used to be
      // cleared on the success path and in `catch`, which left these two early
      // returns holding it forever: the guard at the top of this method then
      // refused every later attempt, so a missing profile or an unbuildable
      // request meant the reading was never composed again for the life of the
      // widget — and the surface sat saying it was still writing.
      if (profile == null) return;
      // The same builder the save-time compose uses, so what is cached is
      // always about the positions this list shows.
      final request = buildChartReadingRequest(
        profile: profile,
        strings: strings,
        content: data.content,
      );
      if (request == null) return;
      final result = await VesselReadingComposer(
        database: widget.db,
        provider: provider,
      ).compose(
        inputHash: data.inputHash,
        request: request,
        now: widget.now,
      );
      if (!mounted) return;
      setState(() => data.movements = result.movements);
    } catch (_) {
      // Best-effort in the strict sense: the surface says the reading is not
      // written yet, which is true, and says nothing about why. The next time
      // the Vessel opens it tries again.
    } finally {
      if (mounted) setState(() => _composing = false);
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
        // The reading used to be asked for when the disclosure was opened.
        // With no disclosure there is no moment to hang it on but this one:
        // the surface is on screen, so the writing it exists to show is
        // composed if it is missing. Guarded inside, and idempotent.
        if (data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_composeIfMissing(data));
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No close. The depths row above is always on screen and is the
            // only way in or out of this section, so a control that emptied
            // the page had nothing left to return to.
            if (widget.showHeading) ...[
              Container(height: 1, color: ink.line),
              Text(strings.theVessel, style: text.labelSmall),
            ],
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
              // No disclosure. `READ DEEPER` stood here and the reading — the
              // thing this surface exists to deliver — was behind it, which is
              // why the owner could look at the Vessel and see nothing but a
              // column of cards analysed one at a time. It was there.
              //
              // Everything the Vessel has to say is on the page now, in order.
              _ChartReading(
                data: data,
                composing: _composing,
              ),
              const SizedBox(height: EterSpace.s24),
              // The whole chart in one list: the Life Path, the three
              // personal points, the figure, and the seven remaining
              // bodies. Each keeps its card, which is what the deck is
              // for; the writing above is about how they stand together.
              for (final position in data.everyPosition(strings))
                _PositionCard(
                  position: position,
                  // The Sun card is already on screen at full width a few
                  // lines above; a position resolving to the same card does
                  // not print it twice.
                  showCard: position.key != 'sun',
                  fullWidth:
                      Theme.of(context).brightness == Brightness.dark &&
                          data.mode != GuidanceMode.grounded,
                ),
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
        // The chart this surface already holds. Without it the reading can
        // name a transit and cannot say what it is landing on.
        chart: widget.data.chart,
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

class _ChartReading extends StatelessWidget {
  const _ChartReading({required this.data, required this.composing});

  final _VesselData data;
  final bool composing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final strings = EterStrings.of(context);

    if (data.movements.isEmpty) {
      // Three states, and they are genuinely different things: the chart is
      // waiting on a birth time, it is being written now, or it has not been
      // written and will be attempted again. None of them is a control.
      final waiting = !data.knowsBirthTime
          ? strings.readingWaitsForBirthTime
          : composing
              ? strings.composingChartReading
              : strings.chartReadingNotWrittenYet;
      return Semantics(
        liveRegion: true,
        child: Text(
          waiting,
          style: text.bodyMedium?.copyWith(color: ink.labelMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final movement in data.movements) ...[
          Text(movement.title.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          Text(
            movement.passage,
            style: text.headlineSmall?.copyWith(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: EterSpace.s24),
        ],
      ],
    );
  }
}

/// One position, with its card, inside the opened menu.
///
/// It carries no passage of its own any more. What it says is what the device
/// computed — the body, the sign and degree, the card and its keywords — and
/// the writing about how it stands to the rest is above, once.
class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.position,
    this.showCard = true,
    this.fullWidth = false,
  });

  final _VesselPosition position;
  final bool showCard;

  /// Whether this card takes the Sun card's measure rather than the 132 dp
  /// thumbnail. Decided by the caller, who knows the sky and the register.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final title = strings.arcanaTitle(position.card.assetSlug);
    final detail = position.detail(strings);
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            '$title · ${position.keywords.join(', ')}',
            style: text.titleMedium,
          ),
          if (detail != null) ...[
            const SizedBox(height: EterSpace.s4),
            Text(detail, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _VesselData {
  _VesselData({
    required this.content,
    required this.chart,
    required this.lifePath,
    required this.movements,
    required this.dob,
    required this.inputHash,
    required this.mode,
    required this.usedApproximateTime,
    required this.usedApproximatePlace,
    required this.birthTimeGiven,
  });

  final SymbolContent content;
  final NatalChart chart;
  final int lifePath;
  /// The whole chart read as one thing, or empty while it is unwritten.
  List<VesselMovement> movements;
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

  /// Whether the angles rest on a stated birth time rather than on noon.
  ///
  /// An approximate time counts — the owner asked for that explicitly — so
  /// this is about whether a time was given at all, not about its precision.
  bool get knowsBirthTime => !usedApproximatePlace && birthTimeGiven;

  final bool birthTimeGiven;

  /// The whole chart in one list: the Life Path, the three personal points,
  /// the figure, then the seven remaining bodies. One menu, in the order a
  /// reader meets them.
  List<_VesselPosition> everyPosition(EterStrings strings) => [
        ...positions(strings),
        ...chartPositions(),
      ];

  /// The rest of the chart, one position per planet. Same shape as
  /// [positions] so one list, one composer and one cache serve the whole
  /// chart — the point of not making the astrogram a second subject.
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
