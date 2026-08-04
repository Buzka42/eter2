import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aether/guidance_mode.dart';
import '../../core/arcana/arcana_card_media.dart';
import '../../core/arcana/house_cards.dart';
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

  /// The parts already asked for while this Vessel has been open.
  ///
  /// The compose pass is hung on a post-frame callback, so it runs again on
  /// every rebuild — and a part that fails leaves its row unwritten, which is
  /// exactly the condition that starts the pass. Without this, one part the
  /// model keeps refusing would be requested again on every frame that
  /// touched this surface, and every one of those requests is billed. Once
  /// per opening is what the retry was ever meant to be.
  final _attempted = <String>{};

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
    // A reload means the birth context changed, so this is a different chart
    // with different rows. Whatever was refused for the old one says nothing
    // about this one.
    _attempted.clear();
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
    Future<String?> storedPart(String key) async =>
        (await widget.db.loadVesselReading(inputHash: hash, positionKey: key))
            ?.contentJson;

    final stored = await storedPart(vesselConfigurationKey);
    final housesJson = await storedPart(VesselReadingPart.houses.storageKey);
    final aspectsJson = await storedPart(VesselReadingPart.aspects.storageKey);
    final matrixJson = await storedPart(VesselReadingPart.matrix.storageKey);
    final matrixSynopsisJson =
        await storedPart(VesselReadingPart.matrixSynopsis.storageKey);

    return _VesselData(
      content: content,
      chart: chart,
      lifePath: lifePath,
      movements:
          stored == null ? const [] : VesselConfiguration.decode(stored),
      housePassages: _keyed(housesJson),
      // The angles come back in the movements shape, the same one the chart's
      // synopsis uses — it is the part where relating *is* the content.
      aspectMovements:
          aspectsJson == null ? const [] : VesselConfiguration.decode(aspectsJson),
      figurePassages: _keyed(matrixJson),
      figureSynopsis: matrixSynopsisJson == null
          ? ''
          : VesselSynopsis.decode(matrixSynopsisJson),
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

  /// The keyed parts as a lookup, so the surface can ask for one house or one
  /// place without walking a list twelve times.
  static Map<String, String> _keyed(String? contentJson) => contentJson == null
      ? const {}
      : {
          for (final passage in VesselKeyedPassage.decode(contentJson))
            passage.key: passage.passage,
        };

  /// Writes the chart's reading if it is missing and can be written.
  ///
  /// Silent, and with no control anywhere near it. The reading is composed
  /// when a birth time is saved — see `InitialVesselReadings` — and this is
  /// the retry for the save that happened with no network, no consent yet, or
  /// no transport. Without it a single failed attempt would leave the reading
  /// permanently unwritten, because there is no longer a button to ask again
  /// with and no background poll to notice.
  Future<void> _composeIfMissing(_VesselData data) async {
    if (_composing || data.isWritten) return;
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
      final composer = VesselReadingComposer(
        database: widget.db,
        provider: provider,
      );

      // Each part is attempted alone and caught alone. They are five separate
      // rows for exactly this reason: a part that fails must not take the four
      // that succeeded with it, and the surface shows whatever has been
      // written so far rather than nothing at all.
      //
      // `needed` is false where the part is already written, or where there is
      // nothing for it to be written about — no houses without reliable
      // angles, no angles on a chart the engine found none in. Both would
      // otherwise be asked for on every open, forever.
      Future<void> attempt(
        VesselReadingPart part, {
        required bool needed,
        required Future<void> Function() one,
      }) async {
        if (!needed || !_attempted.add(part.storageKey)) return;
        try {
          await one();
        } catch (_) {
          // Best-effort in the strict sense: the surface says that part is not
          // written yet, which is true, and says nothing about why. The next
          // time the Vessel is opened it tries again.
        }
      }

      await attempt(
        VesselReadingPart.chartSynopsis,
        needed: data.movements.isEmpty,
        one: () async {
          final result = await composer.compose(
            inputHash: data.inputHash,
            request: request,
            now: widget.now,
          );
          data.movements = result.movements;
        },
      );
      await attempt(
        VesselReadingPart.houses,
        needed: data.housePassages.isEmpty && request.houses.isNotEmpty,
        one: () async {
          data.housePassages = _keyed(await composer.composePart(
            inputHash: data.inputHash,
            request: request,
            part: VesselReadingPart.houses,
            now: widget.now,
          ));
        },
      );
      await attempt(
        VesselReadingPart.aspects,
        needed: data.aspectMovements.isEmpty && request.aspects.isNotEmpty,
        one: () async {
          data.aspectMovements = VesselConfiguration.decode(
            await composer.composePart(
              inputHash: data.inputHash,
              request: request,
              part: VesselReadingPart.aspects,
              now: widget.now,
            ),
          );
        },
      );
      await attempt(
        VesselReadingPart.matrix,
        needed: data.figurePassages.isEmpty,
        one: () async {
          data.figurePassages = _keyed(await composer.composePart(
            inputHash: data.inputHash,
            request: request,
            part: VesselReadingPart.matrix,
            now: widget.now,
          ));
        },
      );
      await attempt(
        VesselReadingPart.matrixSynopsis,
        needed: data.figureSynopsis.isEmpty,
        one: () async {
          data.figureSynopsis = VesselSynopsis.decode(
            await composer.composePart(
              inputHash: data.inputHash,
              request: request,
              part: VesselReadingPart.matrixSynopsis,
              now: widget.now,
            ),
          );
        },
      );
    } catch (_) {
      // Everything outside the per-part attempts: no profile, no request, a
      // transport that cannot be built at all.
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
              // The wheel is led by the three points a person is most likely
              // to already know about themselves. Their passages travel with
              // them here rather than waiting in the list below, which is why
              // the list further down does not print these three again.
              _SunCard(data: data),
              if (data.figurePassages['sun'] case final passage?) ...[
                const SizedBox(height: EterSpace.s8),
                _Passage(passage),
              ],
              const SizedBox(height: EterSpace.s24),
              for (final key in const ['moon', 'ascendant'])
                for (final position in data
                    .positions(strings)
                    .where((one) => one.key == key))
                  _PositionCard(
                    position: position,
                    passage: data.figurePassages[key],
                    fullWidth: _fullWidth(context, data),
                  ),
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
              // Everything the Vessel has to say is on the page now, in the
              // order the owner asked for: the wheel and its three points,
              // the twelve houses, the angles, the whole chart, the figure
              // place by place, and the figure as one thing.

              // 2 · the twelve houses, each with the card on its cusp.
              if (data.houses.isNotEmpty) ...[
                _SectionHeading(strings.headingHouses),
                for (final house in data.houses)
                  _HouseCard(
                    house: house,
                    data: data,
                    passage: data.housePassages['${house.house}'],
                    fullWidth: _fullWidth(context, data),
                  ),
                const SizedBox(height: EterSpace.s8),
              ],

              // 3 · what the geometry says.
              if (data.aspectMovements.isNotEmpty) ...[
                _SectionHeading(strings.headingAngles),
                _Movements(data.aspectMovements),
              ],

              // 4 · the whole chart, and the longest part of the surface.
              _SectionHeading(strings.headingWholeChart),
              _ChartReading(
                data: data,
                composing: _composing,
              ),
              const SizedBox(height: EterSpace.s24),

              // 5 · the figure, place by place — the Life Path, the places in
              // the figure, and the remaining bodies. The Sun, Moon and
              // Ascendant are not printed again; they led the wheel above.
              _SectionHeading(strings.headingTheFigure),
              for (final position in data.everyPosition(strings))
                if (!const ['sun', 'moon', 'ascendant'].contains(position.key))
                  _PositionCard(
                    position: position,
                    passage: data.figurePassages[position.key],
                    fullWidth: _fullWidth(context, data),
                  ),

              // 6 · the figure as one thing.
              if (data.figureSynopsis.isNotEmpty) ...[
                _SectionHeading(strings.headingFigureAsAWhole),
                _Passage(data.figureSynopsis),
                const SizedBox(height: EterSpace.s24),
              ],
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

/// Whether a card in this column takes the Sun card's measure.
///
/// The Sun card's clamp at night outside the grounded register; the 132 dp
/// thumbnail by day and in grounded. One decision, in one place, because every
/// card on this surface has to make it the same way.
bool _fullWidth(BuildContext context, _VesselData data) =>
    Theme.of(context).brightness == Brightness.dark &&
    data.mode != GuidanceMode.grounded;

/// The name of one of the six parts.
///
/// A rule and a label, so the parts read as parts. There is no control here
/// and nothing collapses: `READ DEEPER` and every `CLOSE` are gone from this
/// surface, and a heading that could be tapped would be inviting somebody to
/// look for one.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: ink.line),
          const SizedBox(height: EterSpace.s8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// One written passage, in the measure the Vessel reads its prose at.
class _Passage extends StatelessWidget {
  const _Passage(this.passage);

  final String passage;

  @override
  Widget build(BuildContext context) {
    return Text(
      passage,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
    );
  }
}

/// Titled movements — the shape the chart's synopsis and the angles share.
class _Movements extends StatelessWidget {
  const _Movements(this.movements);

  final List<VesselMovement> movements;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final movement in movements) ...[
          Text(movement.title.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          _Passage(movement.passage),
          const SizedBox(height: EterSpace.s24),
        ],
      ],
    );
  }
}

/// One house: the card on its cusp, who is standing in it, and its passage.
///
/// The first house says so. It *is* the Ascendant — `houseCusps[0]` is the
/// ascending degree — and its card is already on screen above, so without the
/// note it reads as the same plate printed twice for no reason.
class _HouseCard extends StatelessWidget {
  const _HouseCard({
    required this.house,
    required this.data,
    required this.passage,
    required this.fullWidth,
  });

  final HouseCard house;
  final _VesselData data;
  final String? passage;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strings = EterStrings.of(context);
    final title = strings.arcanaTitle(house.card.assetSlug);
    final label = strings.houseLabel(house.house);
    final keywords = data.content.card(house.card)?.keywords ?? const [];
    final occupants = data.occupantsOf(house.house);
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EterSpace.rChip),
              child: LayoutBuilder(
                builder: (context, constraints) => EterArcanaPlate(
                  card: house.card,
                  width: fullWidth
                      ? constraints.maxWidth.clamp(200.0, 420.0)
                      : 132,
                  semanticLabel: strings.positionCardSemantic(
                    cardTitle: title,
                    positionLabel: label,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: EterSpace.s12),
          Text(label, style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          Text(
            keywords.isEmpty ? title : '$title · ${keywords.join(', ')}',
            style: text.titleMedium,
          ),
          const SizedBox(height: EterSpace.s4),
          Text(
            strings.positionDetail(
              signName: strings.signName(house.sign.label),
              degrees: house.degreeInSign.toStringAsFixed(1),
              retrograde: false,
            ),
            style: text.bodySmall,
          ),
          // Nothing at all for an empty house. A house with nobody in it is an
          // ordinary thing for a chart to have, and printing "none" would make
          // it look like a measurement that came back zero.
          if (occupants.isNotEmpty) ...[
            const SizedBox(height: EterSpace.s4),
            Text(
              strings.houseOccupants(
                [for (final name in occupants) strings.bodyName(name)].join(', '),
              ),
              style: text.bodySmall,
            ),
          ],
          if (passage != null) ...[
            const SizedBox(height: EterSpace.s12),
            _Passage(passage!),
          ],
        ],
      ),
    );
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

    return _Movements(data.movements);
  }
}

/// One position, with its card and the passage written about it.
///
/// The passage came back with the split into parts: the figure is read place
/// by place again, but shortly, and the relating is saved for the synopsis
/// that follows. A place with no passage yet shows what the device computed
/// and nothing else, which is still a true row.
class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.position,
    this.passage,
    this.fullWidth = false,
  });

  final _VesselPosition position;

  /// This place's own passage, or null while it is unwritten.
  final String? passage;

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
          // Always drawn. The Sun used to be the exception, because its card
          // stood at full width a few lines above and would have been printed
          // twice; the Sun, Moon and Ascendant are lifted out of this list
          // entirely now, so there is nothing left to suppress.
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
          if (passage != null) ...[
            const SizedBox(height: EterSpace.s12),
            _Passage(passage!),
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
    required this.housePassages,
    required this.aspectMovements,
    required this.figurePassages,
    required this.figureSynopsis,
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

  /// One passage per house, keyed by the house number as a string.
  Map<String, String> housePassages;

  /// What the geometry says, in the movements shape.
  List<VesselMovement> aspectMovements;

  /// One passage per place in the list, keyed by the position's own key —
  /// the same keys `everyPosition` carries.
  Map<String, String> figurePassages;

  /// The figure read as one thing, or empty while it is unwritten.
  String figureSynopsis;

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

  /// Whether the angles rest on something real enough to draw houses from.
  ///
  /// The same condition `buildChartReadingRequest` uses to decide whether to
  /// send them, so the surface never has a band of houses the reading was
  /// never asked about.
  bool get anglesReliable => !usedApproximateTime && !usedApproximatePlace;

  /// The houses this chart actually has, with the card on each cusp.
  List<HouseCard> get houses =>
      anglesReliable && chart.houseCusps.length == 12
          ? houseCardsFor(chart)
          : const [];

  /// The bodies standing in a house, in the chart's own order.
  List<String> occupantsOf(int house) => [
        for (final point in chart.positions)
          if (point.name != 'Ascendant' &&
              point.name != 'Midheaven' &&
              houseOf(point.longitude, chart.houseCusps) == house)
            point.name,
      ];

  /// Whether every part that can be written has been.
  ///
  /// The houses are excluded when the angles cannot support them: without
  /// them there is nothing to compose, so a chart with no birth place would
  /// otherwise ask again on every open, forever.
  bool get isWritten =>
      movements.isNotEmpty &&
      (aspectMovements.isNotEmpty || chart.aspects.isEmpty) &&
      figurePassages.isNotEmpty &&
      figureSynopsis.isNotEmpty &&
      (housePassages.isNotEmpty || houses.isEmpty);

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
