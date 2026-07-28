import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aether/guidance_mode.dart';
import '../../core/arcana/major_arcana.dart';
import '../../core/arcana/symbol_content.dart';
import '../../core/arcana/zodiac.dart';
import '../../core/controls.dart';
import '../../core/db/app_database.dart';
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
    final today = '${widget.now.year.toString().padLeft(4, '0')}-'
        '${widget.now.month.toString().padLeft(2, '0')}-'
        '${widget.now.day.toString().padLeft(2, '0')}';
    final daily = await widget.db.loadDailyCard(today);
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
      daily: daily,
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
              if (data.daily != null) _DailyCard(data: data),
              if (data.usedApproximateTime || data.usedApproximatePlace) ...[
                const SizedBox(height: EterSpace.s16),
                Text(
                  _approximationNote(data),
                  style: text.bodySmall?.copyWith(color: ink.labelMuted),
                ),
              ],
              const SizedBox(height: EterSpace.s24),
              for (final position in data.positions)
                _PositionLine(position: position),
              const SizedBox(height: EterSpace.s16),
              EterAction(
                label: _readingOpen ? 'Keywords' : 'Read deeper',
                emphasis: EterActionEmphasis.secondary,
                onPressed: () => setState(() => _readingOpen = !_readingOpen),
              ),
              if (_readingOpen) ...[
                const SizedBox(height: EterSpace.s24),
                for (final position in data.positions)
                  _ComposedReading(
                    position: position,
                    reading: data.readings[position.key],
                  ),
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

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.data});

  final _VesselData data;

  @override
  Widget build(BuildContext context) {
    final card = MajorArcana.bySlug(data.daily!.arcanaSlug);
    if (card == null) return const SizedBox.shrink();
    final attributes = data.content.card(card);
    final brightness = Theme.of(context).brightness;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: EterSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(EterSpace.rChip),
            child: Image.asset(
              card.assetFor(brightness),
              width: 92,
              height: 137,
              fit: BoxFit.cover,
              semanticLabel: '${card.title}, card of the day',
            ),
          ),
          const SizedBox(width: EterSpace.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY’S CARD', style: text.labelSmall),
                const SizedBox(height: EterSpace.s4),
                Text(card.title, style: text.headlineSmall),
                if (attributes != null) ...[
                  const SizedBox(height: EterSpace.s4),
                  Text(attributes.subtitle, style: text.bodySmall),
                ],
                const SizedBox(height: EterSpace.s8),
                Text(data.daily!.reason, style: text.bodySmall),
              ],
            ),
          ),
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
          Text(position.label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: EterSpace.s4),
          Text(
            '${position.card.title} · ${position.keywords.join(', ')}',
            style: text.titleMedium,
          ),
          if (position.detail != null) ...[
            const SizedBox(height: EterSpace.s4),
            Text(position.detail!, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _ComposedReading extends StatelessWidget {
  const _ComposedReading({required this.position, required this.reading});

  final _VesselPosition position;
  final VesselReadingRow? reading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final passage = reading == null ? null : _passage(reading!.contentJson);
    return Padding(
      padding: const EdgeInsets.only(bottom: EterSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(position.label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: EterSpace.s8),
          Text(
            passage ??
                'This personal reading has not been composed yet. The '
                    'offline keywords above remain available.',
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
    required this.daily,
    required this.readings,
    required this.inputHash,
    required this.mode,
    required this.usedApproximateTime,
    required this.usedApproximatePlace,
  });

  final SymbolContent content;
  final NatalChart chart;
  final int lifePath;
  final DailyCardRow? daily;
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
