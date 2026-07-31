import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eter/core/profile/place_suggestions.dart';

void main() {
  test('short queries suggest nothing and cancel a pending lookup', () {
    fakeAsync((async) {
      final suggester = _Suggester();
      final controller = PlaceSuggestionController(suggester: suggester);
      controller.onQueryChanged('Wa');
      async.elapse(const Duration(seconds: 1));
      expect(suggester.queries, isEmpty);
      controller.onQueryChanged('War');
      controller.onQueryChanged('W');
      async.elapse(const Duration(seconds: 1));
      expect(suggester.queries, isEmpty);
    });
  });

  test('typing debounces to one lookup for the final text', () {
    fakeAsync((async) {
      final suggester = _Suggester();
      final controller = PlaceSuggestionController(suggester: suggester);
      controller.onQueryChanged('War');
      async.elapse(const Duration(milliseconds: 100));
      controller.onQueryChanged('Wars');
      async.elapse(const Duration(milliseconds: 100));
      controller.onQueryChanged('Warsaw');
      async.elapse(const Duration(seconds: 1));
      expect(suggester.queries, ['Warsaw']);
      expect(controller.candidates.single.label, 'Warsaw for Warsaw');
    });
  });

  test('an answer that arrives after a newer query is dropped', () {
    fakeAsync((async) {
      final suggester = _Suggester();
      final controller = PlaceSuggestionController(suggester: suggester);
      suggester.delay = const Duration(seconds: 5);
      controller.onQueryChanged('Warsaw');
      async.elapse(const Duration(milliseconds: 500));
      suggester.delay = Duration.zero;
      controller.onQueryChanged('Wroclaw');
      async.elapse(const Duration(seconds: 10));
      expect(controller.candidates.single.label, 'Warsaw for Wroclaw');
    });
  });

  test('a failing suggester means no suggestions, not an error', () {
    fakeAsync((async) {
      final suggester = _Suggester()..fail = true;
      final controller = PlaceSuggestionController(suggester: suggester);
      controller.onQueryChanged('Warsaw');
      async.elapse(const Duration(seconds: 1));
      expect(controller.candidates, isEmpty);
    });
  });

  test('dismiss clears the list and cancels the pending lookup', () {
    fakeAsync((async) {
      final suggester = _Suggester();
      final controller = PlaceSuggestionController(suggester: suggester);
      controller.onQueryChanged('Warsaw');
      async.elapse(const Duration(seconds: 1));
      expect(controller.candidates, isNotEmpty);
      controller.onQueryChanged('Wroclaw');
      controller.dismiss();
      async.elapse(const Duration(seconds: 1));
      expect(controller.candidates, isEmpty);
      expect(suggester.queries, ['Warsaw']);
    });
  });
}

void fakeAsync(void Function(FakeAsync) body) => FakeAsync().run(body);

class _Suggester implements PlaceSuggester {
  final queries = <String>[];
  Duration delay = Duration.zero;
  bool fail = false;

  @override
  Future<List<PlaceCandidate>> suggest(String query) async {
    queries.add(query);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (fail) throw StateError('geocoder down');
    return [
      PlaceCandidate(label: 'Warsaw for $query', latitude: 52, longitude: 21),
    ];
  }
}
