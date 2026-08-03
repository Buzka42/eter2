import 'package:geocoding/geocoding.dart' as geocoding;

import '../db/app_database.dart';
import 'birth_time.dart';
import 'place_suggestions.dart';

abstract interface class BirthplaceResolver {
  Future<BirthplaceCoordinates> resolve(String place);
}

class PlatformBirthplaceResolver
    implements BirthplaceResolver, PlaceSuggester {
  const PlatformBirthplaceResolver();

  /// The geocoder's forward lookup returns coordinates without names, so each
  /// candidate is named by reverse-geocoding it. Capped low: this runs per
  /// debounced keystroke and every extra candidate is another platform call.
  static const _maximumCandidates = 4;

  @override
  Future<List<PlaceCandidate>> suggest(String query) async {
    final locations = await geocoding.locationFromAddress(query);
    final seen = <String>{};
    final candidates = <PlaceCandidate>[];
    for (final location in locations.take(_maximumCandidates)) {
      // Two candidates within ~1 km are the same place answered twice.
      final key = '${location.latitude.toStringAsFixed(2)},'
          '${location.longitude.toStringAsFixed(2)}';
      if (!seen.add(key)) continue;
      final placemarks = await geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      final mark = placemarks.isEmpty ? null : placemarks.first;
      final label = [
        mark?.locality,
        mark?.administrativeArea,
        mark?.country,
      ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
      if (label.isEmpty) continue;
      candidates.add(PlaceCandidate(
        label: label,
        latitude: location.latitude,
        longitude: location.longitude,
      ));
    }
    return candidates;
  }

  @override
  Future<BirthplaceCoordinates> resolve(String place) async {
    final results = await geocoding.locationFromAddress(place);
    if (results.isEmpty) {
      throw const BirthContextException(
        BirthContextError.placeNotLocated,
      );
    }
    final first = results.first;
    return BirthplaceCoordinates(
      latitude: first.latitude,
      longitude: first.longitude,
    );
  }
}

class BirthplaceCoordinates {
  const BirthplaceCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class BirthContextService {
  BirthContextService({
    required this.database,
    required this.resolver,
  });

  final AppDatabase database;
  final BirthplaceResolver resolver;

  Future<void> save({
    required String time,
    required String utcOffset,
    required String place,
    BirthTimePrecision precision = BirthTimePrecision.exact,
    BirthTimePeriod? period,
    DateTime? dob,
  }) async {
    final profile = await database.loadProfile();
    if (profile == null) {
      throw const BirthContextException(
        BirthContextError.profileUnavailable,
      );
    }
    // An approximate time is a chosen period, not a typed clock value: the
    // representative minute comes from the period so the two can never
    // disagree.
    final timeMinutes = switch (precision) {
      BirthTimePrecision.unknown => null,
      BirthTimePrecision.approximate => period?.representativeMinutes,
      BirthTimePrecision.exact => parseClockMinutes(time),
    };
    if (precision == BirthTimePrecision.approximate && period == null) {
      throw const BirthContextException(
        BirthContextError.choosePartOfDay,
      );
    }
    final offsetMinutes = parseUtcOffsetMinutes(utcOffset);
    // A time of any precision needs an offset to be placed in UTC at all.
    // An offset without a time is simply unused — it used to be an error,
    // which made "I do not know the time" impossible to answer once an offset
    // had been typed.
    if (timeMinutes != null && offsetMinutes == null) {
      throw const BirthContextException(BirthContextError.addUtcOffset);
    }
    final normalizedPlace = place.trim();
    BirthplaceCoordinates? coordinates;
    if (normalizedPlace.isNotEmpty) {
      try {
        coordinates = await resolver.resolve(normalizedPlace);
      } on BirthContextException {
        rethrow;
      } catch (_) {
        throw const BirthContextException(
          BirthContextError.placeNotLocatedNow,
        );
      }
    }
    await database.updateBirthContext(
      dob: dob,
      birthTimeMinutes: timeMinutes,
      birthTimePrecision: timeMinutes == null ? 'unknown' : precision.name,
      birthUtcOffsetMinutes: timeMinutes == null ? null : offsetMinutes,
      birthPlace: normalizedPlace.isEmpty ? null : normalizedPlace,
      birthLatitude: coordinates?.latitude,
      birthLongitude: coordinates?.longitude,
    );
  }

  static int? parseClockMinutes(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(trimmed);
    if (match == null) {
      throw const BirthContextException(BirthContextError.timeFormat);
    }
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  static int? parseUtcOffsetMinutes(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final match = RegExp(r'^([+-])(\d{1,2}):([0-5]\d)$').firstMatch(trimmed);
    if (match == null) {
      throw const BirthContextException(BirthContextError.utcOffsetFormat);
    }
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3)!);
    if (hours > 14 || (hours == 14 && minutes != 0)) {
      throw const BirthContextException(BirthContextError.utcOffsetRange);
    }
    final total = hours * 60 + minutes;
    return match.group(1) == '-' ? -total : total;
  }
}

/// Where the person lives now, for the register to read the sun from.
///
/// Shares [BirthplaceResolver] with [BirthContextService] and nothing else,
/// because it is not birth data and must not be filed with it: the chart is cast
/// where someone was born and never recast, while sunrise is a fact about where
/// they are standing. Keeping the two apart in code is what stops the next
/// change from conflating them again.
class HomePlaceService {
  HomePlaceService({required this.database, required this.resolver});

  final AppDatabase database;
  final BirthplaceResolver resolver;

  /// Saves a place, or forgets it when [place] is blank.
  ///
  /// A failed lookup changes nothing, which matches how birth place already
  /// behaves: half-writing a label without its coordinates would leave the
  /// register reading a horizon nobody named.
  Future<void> save(String place) async {
    final normalized = place.trim();
    if (normalized.isEmpty) {
      await database.updateHomePlace();
      return;
    }
    BirthplaceCoordinates coordinates;
    try {
      coordinates = await resolver.resolve(normalized);
    } on BirthContextException {
      rethrow;
    } catch (_) {
      throw const BirthContextException(BirthContextError.placeNotLocatedNow);
    }
    await database.updateHomePlace(
      place: normalized,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  }
}

/// Why saving a birth context was refused.
///
/// A code rather than a sentence. These are thrown from `static` parsers that
/// have no access to a widget tree and no business holding a language table, and
/// the same failure has to be sayable in every language Eter speaks — so the
/// layer that knows what went wrong names it, and the layer that knows who is
/// reading words it. See `EterStrings.birthContextError`.
enum BirthContextError {
  /// The typed date is not one the calendar has, is in the future, or is far
  /// enough back to be a typo.
  birthDateInvalid,

  /// Under sixteen.
  birthDateTooYoung,

  placeNotLocated,
  profileUnavailable,
  choosePartOfDay,
  addUtcOffset,
  placeNotLocatedNow,
  timeFormat,
  utcOffsetFormat,
  utcOffsetRange,
}

class BirthContextException implements Exception {
  const BirthContextException(this.error);

  final BirthContextError error;

  /// Diagnostic only — never shown. The surface renders [error] through the
  /// active string table.
  @override
  String toString() => 'BirthContextException(${error.name})';
}
