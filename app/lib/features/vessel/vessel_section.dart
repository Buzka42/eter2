import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aether/guidance_mode.dart';
import '../../core/arcana/animated_arcana_card.dart';
import '../../core/arcana/major_arcana.dart';
import '../../core/arcana/symbol_content.dart';
import '../../core/arcana/zodiac.dart';
import '../../core/arrival.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
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
  });

  final AppDatabase db;
  final DateTime now;
  final VoidCallback onClose;

  @override
  ConsumerState<VesselSection> createState() => _VesselSectionState();
}

class _VesselSectionState extends ConsumerState<VesselSection> {
  late Future<_VesselData?> _data;
  StreamSubscription<ProfileRow?>? _profileSubscription;
  String? _profileFingerprint;
  bool _readingOpen = false;
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
    final content = await SymbolContent.load();
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
    final hash = [
      profile.dob.toIso8601String(),
      profile.birthTimeMinutes ?? 'unknown-time',
      profile.birthUtcOffsetMinutes ?? 'unknown-offset',
      profile.birthLatitude ?? 'unknown-latitude',
      profile.birthLongitude ?? 'unknown-longitude',
    ].join('|');
    final readings = <String, VesselReadingRow?>{
      for (final key in const ['lifePath', 'sun', 'moon', 'ascendant'])
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
      inputHash: hash,
      mode: switch (profile.guidanceMode) {
        'grounded' => GuidanceMode.grounded,
        'immersive' => GuidanceMode.immersive,
        _ => GuidanceMode.balanced,
      },
      usedApproximateTime: profile.birthTimeMinutes == null ||
          profile.birthUtcOffsetMinutes == null,
      usedApproximatePlace:
          profile.birthLatitude == null || profile.birthLongitude == null,
    );
  }

  Future<void> _compose(_VesselData data) async {
    if (_composing) return;
    final provider = ref.read(vesselReadingTransportProvider);
    if (provider == null) {
      setState(() {
        _compositionMessage =
            'Personal reading composition is not connected on this build yet.';
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
          positions: [
            for (final position in data.positions)
              VesselReadingPosition(
                key: position.key,
                label: position.label,
                card: position.card.title,
                keywords: position.keywords,
                detail: position.detail,
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
            ? 'Every personal reading is already composed for this chart.'
            : 'The missing personal readings have been composed.';
      });
    } on VesselReadingException catch (error) {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage = error.reason == 'AI processing is not permitted'
            ? 'Enable AI guidance in the Sanctum before composing.'
            : 'The response could not be accepted safely. Nothing changed.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _composing = false;
        _compositionMessage =
            'Composition is unavailable right now. Cached readings remain.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = EterInk.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder<_VesselData?>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 1, color: ink.line),
            Row(
              children: [
                Text('THE VESSEL', style: text.labelSmall),
                const Spacer(),
                EterAction(
                  label: 'Close',
                  emphasis: EterActionEmphasis.quiet,
                  onPressed: widget.onClose,
                ),
              ],
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              Text(
                'Reading the chart held on this device…',
                style: text.bodyMedium,
              )
            else if (data == null)
              Text(
                'Birth details are needed before the Vessel can be drawn.',
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
                  _approximationNote(data),
                  style: text.bodySmall?.copyWith(color: ink.labelMuted),
                ),
              ],
              const SizedBox(height: EterSpace.s24),
              // One list at two depths, never two lists. Read deeper used to
              // append a second copy of the same four positions underneath the
              // first, so the same headings appeared twice on one screen; it
              // now deepens the list in place.
              for (final position in data.positions)
                if (_readingOpen)
                  _ComposedReading(
                    position: position,
                    reading: data.readings[position.key],
                    // The Sun card is already on screen at full width a few
                    // lines above; a position resolving to the same card does
                    // not print it twice.
                    showCard: position.key != 'sun',
                  )
                else
                  _PositionLine(position: position),
              const SizedBox(height: EterSpace.s16),
              EterAction(
                label: _readingOpen ? 'Show less' : 'Read deeper',
                emphasis: EterActionEmphasis.secondary,
                onPressed: () => setState(() => _readingOpen = !_readingOpen),
              ),
              if (_readingOpen) ...[
                const SizedBox(height: EterSpace.s16),
                if (data.readings.values.any((reading) => reading == null))
                  EterAction(
                    label: _composing ? 'Composing' : 'Compose readings',
                    emphasis: EterActionEmphasis.quiet,
                    busy: _composing,
                    onPressed: () => _compose(data),
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

  static String _approximationNote(_VesselData data) {
    if (data.usedApproximateTime && data.usedApproximatePlace) {
      return 'Birth time and place are incomplete. Noon and zero coordinates '
          'are used provisionally; the Ascendant is not reliable.';
    }
    if (data.usedApproximateTime) {
      return 'Birth time is unknown. Noon is used provisionally; the '
          'Ascendant is not reliable.';
    }
    return 'Birth place is incomplete. The Ascendant is provisional.';
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
    final sun = data.positions.firstWhere((p) => p.key == 'sun');
    final attributes = data.content.card(sun.card);
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
                  semanticLabel: '${sun.card.title}, your Sun card',
                ),
              ),
            ),
          ),
          const SizedBox(height: EterSpace.s16),
          Text('YOUR CARD', style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          Text(sun.card.title, style: text.headlineSmall),
          if (attributes != null) ...[
            const SizedBox(height: EterSpace.s4),
            Text(attributes.subtitle, style: text.bodySmall),
          ],
          const SizedBox(height: EterSpace.s8),
          Text(
            'Your Sun sits in ${sun.detail ?? 'its own sign'}, which is what '
            'sets this card. It does not change.',
            style: text.bodySmall,
          ),
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
      label: semanticLabel ?? card.title,
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool compose = false}) async {
    if (_busy) return;
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
            ? 'Enable AI guidance in the Sanctum before reading today.'
            : 'Today’s reading is not connected on this build yet. The '
                'positions below are calculated on this device.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Today’s reading could not be written. The positions '
            'below are unchanged.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = EterInk.of(context);
    final reading = _reading;
    if (reading == null) return const SizedBox.shrink();

    final contacts = reading.contacts.take(4).toList();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ink.line)),
      ),
      padding: const EdgeInsets.only(top: EterSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POSITIONS TODAY', style: text.labelSmall),
          const SizedBox(height: EterSpace.s8),
          Text(
            'A ${reading.moonPhaseLabel} moon in ${reading.toJson()['moonSign']}, '
            'the sun in ${reading.toJson()['sunSign']}.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: EterSpace.s12),
          if (contacts.isEmpty)
            Text(
              'Nothing in the sky stands close to your chart today.',
              style: text.bodySmall,
            )
          else
            for (final contact in contacts)
              Padding(
                padding: const EdgeInsets.only(bottom: EterSpace.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${contact.transiting} ${contact.type} '
                        'natal ${contact.natal}',
                        style: text.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: EterSpace.s8),
                    Text(
                      '${contact.orb.toStringAsFixed(1)}° '
                      '${contact.applying ? 'applying' : 'separating'}',
                      style: text.labelSmall,
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
              label: _busy ? 'Reading' : 'Read today',
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
              if (AstroGlyph.forBody(position.label) case final glyph?) ...[
                AstroGlyphMark(
                  glyph: glyph,
                  color: ink.labelMuted,
                  size: 14,
                ),
                const SizedBox(width: EterSpace.s8),
              ],
              Text(position.label.toUpperCase(), style: text.labelSmall),
            ],
          ),
          const SizedBox(height: EterSpace.s4),
          Text(
            '${position.card.title} · ${position.keywords.join(', ')}',
            style: text.titleMedium,
          ),
          if (position.detail != null) ...[
            const SizedBox(height: EterSpace.s4),
            Row(
              children: [
                if (AstroGlyph.forSign(position.detail!.split(' ').first)
                    case final sign?) ...[
                  AstroGlyphMark(
                    glyph: sign,
                    color: ink.labelMuted,
                    size: 12,
                  ),
                  const SizedBox(width: EterSpace.s4),
                ],
                Text(position.detail!, style: text.bodySmall),
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
  });

  final _VesselPosition position;
  final VesselReadingRow? reading;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                child: EterArcanaPlate(
                  card: position.card,
                  width: 132,
                  semanticLabel: '${position.card.title}, ${position.label}',
                ),
              ),
            ),
            const SizedBox(height: EterSpace.s12),
          ],
          Text(position.label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          // The keywords stay visible at depth: the passage interprets them,
          // and losing them on opening made the deeper view feel like a
          // different subject rather than the same one, closer.
          Text(
            '${position.card.title} · ${position.keywords.join(', ')}',
            style: text.titleMedium,
          ),
          const SizedBox(height: EterSpace.s8),
          Text(
            passage ??
                'This personal reading has not been composed yet. The '
                    'keywords are shipped with the app and stand on their own.',
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
    required this.inputHash,
    required this.mode,
    required this.usedApproximateTime,
    required this.usedApproximatePlace,
  });

  final SymbolContent content;
  final NatalChart chart;
  final int lifePath;
  final Map<String, VesselReadingRow?> readings;
  final String inputHash;
  final GuidanceMode mode;
  final bool usedApproximateTime;
  final bool usedApproximatePlace;

  List<_VesselPosition> get positions {
    _VesselPosition signPosition(
      String key,
      String label,
      ZodiacPosition point,
    ) {
      final sign =
          Zodiac.values.firstWhere((value) => value.label == point.sign);
      final card = MajorArcana.forZodiac(sign);
      final attributes = content.card(card)!;
      return _VesselPosition(
        key: key,
        label: label,
        card: card,
        keywords: attributes.keywords,
        detail: '${point.sign} ${point.degreeInSign.toStringAsFixed(1)}°'
            '${point.retrograde ? ' retrograde' : ''}',
      );
    }

    final lifeCard = MajorArcana.forLifePath(lifePath);
    return [
      _VesselPosition(
        key: 'lifePath',
        label: 'Life Path $lifePath',
        card: lifeCard,
        keywords: content.lifePath(lifePath)!.keywords,
      ),
      signPosition('sun', 'Sun', chart.sun),
      signPosition('moon', 'Moon', chart.moon),
      signPosition('ascendant', 'Ascendant', chart.ascendant),
    ];
  }
}

class _VesselPosition {
  const _VesselPosition({
    required this.key,
    required this.label,
    required this.card,
    required this.keywords,
    this.detail,
  });

  final String key;
  final String label;
  final MajorArcana card;
  final List<String> keywords;
  final String? detail;
}
