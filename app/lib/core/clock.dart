import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time, as a dependency rather than a direct call.
///
/// Surfaces that derive numbers from the time of day — basal burn accrued so
/// far today, which day a record belongs to — cannot be captured or asserted
/// while they read the wall clock inline: the same input renders differently
/// one minute later. Overriding this provider pins them.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The local `yyyy-MM-dd` day key used by the database contracts.
String eterIsoDate(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

/// Local start and end of the day containing [local].
(DateTime, DateTime) eterDayBounds(DateTime local) {
  final start = DateTime(local.year, local.month, local.day);
  return (start, start.add(const Duration(days: 1)));
}
