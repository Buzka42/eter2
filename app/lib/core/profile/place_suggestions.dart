import 'dart:async';

import 'package:flutter/material.dart';

/// One place the geocoder offered for what was typed so far.
///
/// The label is whatever the device geocoder returned in its own locale —
/// a Polish phone suggests "Warszawa" and an English one "Warsaw", and both
/// are accepted as typed. Showing the answer in the app's language would need
/// a second lookup per keystroke for a spelling the person did not use.
class PlaceCandidate {
  const PlaceCandidate({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

/// Turns a partial query into candidate places.
///
/// Deliberately not part of [BirthplaceResolver]: resolving on save is a
/// promise every fake in the tests keeps, and suggesting-as-you-type is a
/// convenience only the platform geocoder actually provides.
abstract interface class PlaceSuggester {
  Future<List<PlaceCandidate>> suggest(String query);
}

/// Debounces typing into suggestion lookups, latest query wins.
///
/// Pure orchestration so it can be tested without a platform geocoder: the
/// debounce interval is injectable and a stale answer — one that returns
/// after a newer query was typed — is dropped rather than shown.
class PlaceSuggestionController extends ChangeNotifier {
  PlaceSuggestionController({
    required this.suggester,
    this.debounce = const Duration(milliseconds: 400),
    this.minimumQueryLength = 3,
  });

  final PlaceSuggester suggester;
  final Duration debounce;
  final int minimumQueryLength;

  Timer? _timer;
  int _generation = 0;
  List<PlaceCandidate> _candidates = const [];

  List<PlaceCandidate> get candidates => _candidates;

  void onQueryChanged(String query) {
    _timer?.cancel();
    final trimmed = query.trim();
    _generation++;
    if (trimmed.length < minimumQueryLength) {
      _setCandidates(const []);
      return;
    }
    final generation = _generation;
    _timer = Timer(debounce, () => _lookup(trimmed, generation));
  }

  /// Clears the list immediately — after a candidate is chosen, or when the
  /// field loses focus.
  void dismiss() {
    _timer?.cancel();
    _generation++;
    _setCandidates(const []);
  }

  Future<void> _lookup(String query, int generation) async {
    List<PlaceCandidate> found;
    try {
      found = await suggester.suggest(query);
    } catch (_) {
      // A geocoder that is offline or does not know the place is the same
      // outcome as no suggestions: the typed text still resolves on save.
      found = const [];
    }
    if (generation != _generation) return;
    _setCandidates(found);
  }

  void _setCandidates(List<PlaceCandidate> value) {
    if (_candidates.isEmpty && value.isEmpty) return;
    _candidates = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// The suggestion rows under a place field.
///
/// Renders nothing at all while there are no candidates, so the field reads
/// as the plain field it always was until the geocoder has something to say.
class PlaceSuggestionList extends StatelessWidget {
  const PlaceSuggestionList({
    super.key,
    required this.controller,
    required this.onChosen,
  });

  final PlaceSuggestionController controller;
  final ValueChanged<PlaceCandidate> onChosen;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final candidates = controller.candidates;
        if (candidates.isEmpty) return const SizedBox.shrink();
        final text = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final candidate in candidates)
              InkWell(
                // Keyed on the coordinates, which the suggester has already
                // deduplicated, rather than on the label — two Springfields
                // in the same state share a name, and two identical keys
                // among siblings is a framework error, not a cosmetic one.
                key: ValueKey(
                  'place-suggestion-'
                  '${candidate.latitude},${candidate.longitude}',
                ),
                onTap: () => onChosen(candidate),
                child: Container(
                  // The product's own tap floor. The padding alone left the
                  // rows at 44 dp, and these are the smallest targets in
                  // onboarding.
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(candidate.label, style: text.bodyMedium),
                ),
              ),
          ],
        );
      },
    );
  }
}
