import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time, as a dependency rather than a direct call.
///
/// Surfaces that derive numbers from the time of day — basal burn accrued so
/// far today, which day a record belongs to — cannot be captured or asserted
/// while they read the wall clock inline: the same input renders differently
/// one minute later. Overriding this provider pins them.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
