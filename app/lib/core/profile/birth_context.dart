import 'package:geocoding/geocoding.dart' as geocoding;

import '../db/app_database.dart';

abstract interface class BirthplaceResolver {
  Future<BirthplaceCoordinates> resolve(String place);
}

class PlatformBirthplaceResolver implements BirthplaceResolver {
  @override
  Future<BirthplaceCoordinates> resolve(String place) async {
    final results = await geocoding.locationFromAddress(place);
    if (results.isEmpty) {
      throw const BirthContextException(
        'That place could not be located. Try a city and country.',
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
  }) async {
    final profile = await database.loadProfile();
    if (profile == null) {
      throw const BirthContextException('The local profile is unavailable.');
    }
    final timeMinutes = parseClockMinutes(time);
    final offsetMinutes = parseUtcOffsetMinutes(utcOffset);
    if ((timeMinutes == null) != (offsetMinutes == null)) {
      throw const BirthContextException(
        'Add both birth time and its UTC offset, or leave both blank.',
      );
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
          'That place could not be located right now. Nothing changed.',
        );
      }
    }
    await database.updateBirthContext(
      birthTimeMinutes: timeMinutes,
      birthUtcOffsetMinutes: offsetMinutes,
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
      throw const BirthContextException(
        'Enter birth time as HH:MM, or leave it blank.',
      );
    }
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  static int? parseUtcOffsetMinutes(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final match = RegExp(r'^([+-])(\d{1,2}):([0-5]\d)$').firstMatch(trimmed);
    if (match == null) {
      throw const BirthContextException(
        'Enter the birth-place UTC offset like +01:00.',
      );
    }
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3)!);
    if (hours > 14 || (hours == 14 && minutes != 0)) {
      throw const BirthContextException(
        'UTC offset must be between −14:00 and +14:00.',
      );
    }
    final total = hours * 60 + minutes;
    return match.group(1) == '-' ? -total : total;
  }
}

class BirthContextException implements Exception {
  const BirthContextException(this.message);

  final String message;

  @override
  String toString() => message;
}
