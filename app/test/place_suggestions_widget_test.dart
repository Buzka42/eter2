import 'package:eter/core/profile/place_suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The suggestion rows themselves.
///
/// Worth their own file because nothing else can reach them: the platform
/// geocoder is the only real [PlaceSuggester], and it throws under a test
/// binding, so onboarding and the Sanctum never render a single row in the
/// rest of the suite.
void main() {
  Future<PlaceSuggestionController> pumpList(
    WidgetTester tester,
    List<PlaceCandidate> candidates, {
    void Function(PlaceCandidate)? onChosen,
  }) async {
    final controller = PlaceSuggestionController(
      suggester: _Suggester(candidates),
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceSuggestionList(
            controller: controller,
            onChosen: onChosen ?? (_) {},
          ),
        ),
      ),
    );
    controller.onQueryChanged('Springfield');
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    return controller;
  }

  testWidgets('nothing is drawn until the geocoder has something to say',
      (tester) async {
    final controller = PlaceSuggestionController(
      suggester: const _Suggester([]),
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceSuggestionList(
            controller: controller,
            onChosen: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('two places may share a name and both still draw',
      (tester) async {
    // Candidates are deduplicated by coordinate, not by label, so this is
    // reachable: there are two Springfields in Illinois' geocoder results and
    // several more in the United States. Keying the rows on the label put two
    // identical keys among siblings, which is a framework error rather than a
    // cosmetic one.
    await pumpList(tester, const [
      PlaceCandidate(
        label: 'Springfield, Illinois, United States',
        latitude: 39.79,
        longitude: -89.64,
      ),
      PlaceCandidate(
        label: 'Springfield, Illinois, United States',
        latitude: 39.80,
        longitude: -89.90,
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Springfield, Illinois, United States'), findsNWidgets(2));
  });

  testWidgets('choosing a row hands back the place that was tapped',
      (tester) async {
    PlaceCandidate? chosen;
    await pumpList(
      tester,
      const [
        PlaceCandidate(label: 'Warszawa, Polska', latitude: 52.23,
            longitude: 21.01),
        PlaceCandidate(label: 'Warszawa, Missouri', latitude: 38.24,
            longitude: -93.52),
      ],
      onChosen: (candidate) => chosen = candidate,
    );

    await tester.tap(find.text('Warszawa, Missouri'));
    await tester.pump();
    // The coordinates, not just the name: choosing the wrong Warszawa would
    // cast a chart on the other side of the Atlantic.
    expect(chosen?.latitude, 38.24);
  });

  testWidgets('a row meets the 48 dp tap floor', (tester) async {
    await pumpList(tester, const [
      PlaceCandidate(label: 'Kraków, Polska', latitude: 50.06, longitude: 19.94),
    ]);

    final row = tester.getSize(find.byType(InkWell).first);
    expect(row.height, greaterThanOrEqualTo(48));
  });

  testWidgets('the rows clear once a place is taken', (tester) async {
    final controller = await pumpList(tester, const [
      PlaceCandidate(label: 'Gdańsk, Polska', latitude: 54.35, longitude: 18.65),
    ]);
    expect(find.byType(InkWell), findsOneWidget);

    controller.dismiss();
    await tester.pump();
    expect(find.byType(InkWell), findsNothing);
  });
}

class _Suggester implements PlaceSuggester {
  const _Suggester(this.candidates);

  final List<PlaceCandidate> candidates;

  @override
  Future<List<PlaceCandidate>> suggest(String query) async => candidates;
}
