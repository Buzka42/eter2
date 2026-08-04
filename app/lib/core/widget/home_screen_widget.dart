/// One sentence, on the home screen.
///
/// The smallest surface Eter has, and the only one a person's household can
/// read over their shoulder. Every decision here follows from that.
///
/// * **One sentence of the day's synthesis, and nothing else.** No counts, no
///   step total, no streak. A widget with a number on it is a scoreboard, and
///   the whole argument of this product is that it is not one.
/// * **The synthesis, specifically.** It is the one passage written to be read
///   on its own, and it is already the passage the Correspondence is allowed to
///   send to another person — so it is the part of guidance that has been
///   thought about as something somebody else might see.
/// * **Today's, or nothing.** A sentence from Tuesday shown on Thursday is the
///   one thing this surface must not do, so the day is written beside it and
///   the widget compares rather than reading a clock of its own.
/// * **Cleared when it should be.** Withdrawing AI consent, or a day where
///   nothing composed, takes the words off the home screen. A revocation that
///   left prose sitting on a launcher would be the one place in this product
///   where withdrawing consent changed nothing.
///
/// Android only. The iOS half is WidgetKit and SwiftUI, which cannot be built
/// or verified without a Mac.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';

/// The platform side, kept behind an interface so the rule above can be tested
/// without a phone.
abstract interface class HomeWidgetSink {
  /// [sentence] null clears whatever is showing.
  Future<void> publish({
    required String? sentence,
    required String? date,
    required String today,
  });
}

class PlatformHomeWidgetSink implements HomeWidgetSink {
  const PlatformHomeWidgetSink();

  static const _channel = MethodChannel('eter/widget');

  @override
  Future<void> publish({
    required String? sentence,
    required String? date,
    required String today,
  }) async {
    try {
      await _channel.invokeMethod<void>('publish', {
        'sentence': sentence,
        'date': date,
        'today': today,
      });
    } on MissingPluginException {
      // Every other platform. The widget is Android's, and its absence is not
      // a failure of anything.
    } catch (error) {
      // Deliberately everything.
      //
      // A launcher that does not redraw must never be able to fail a
      // composition, and the ways this can throw are not all exceptions anyone
      // would think to name: in a plain Dart test there is no `ServicesBinding`
      // at all, and `MethodChannel` asserts rather than throwing
      // `MissingPluginException`. That surfaced as three unrelated composer
      // tests failing over a home screen none of them has.
      debugPrint('The home-screen widget was not updated: $error');
    }
  }
}

/// Decides what the widget should say, and says it.
class HomeScreenWidget {
  const HomeScreenWidget({
    required this.database,
    this.sink = const PlatformHomeWidgetSink(),
  });

  final AppDatabase database;
  final HomeWidgetSink sink;

  /// Pushes the sentence for [now]'s local day, or clears it.
  ///
  /// Called after guidance composes and whenever consent changes. Best-effort
  /// throughout: nothing upstream may fail because a launcher did not redraw.
  Future<void> refresh({required DateTime now}) async {
    final today = isoDate(now);
    String? sentence;
    String? date;
    try {
      // Consent is re-read, never cached — the same rule as everywhere else.
      // Without it there is nothing composed to show anyway; with it withdrawn
      // there may still be rows, and those must come off the home screen.
      final profile = await database.loadProfile();
      if (profile?.aiConsentAt != null) {
        sentence = await sentenceFor(today);
        if (sentence != null) date = today;
      }
    } catch (_) {
      // Reading failed. Clearing is the safe answer: a blank widget is honest
      // and a stale one is not.
    }
    await sink.publish(sentence: sentence, date: date, today: today);
  }

  /// The first sentence of [date]'s synthesis, or null.
  ///
  /// The first rather than all of them: a home-screen widget is a glance, and
  /// the synthesis is written so that its opening sentence stands alone —
  /// which is exactly the property the Correspondence already relies on.
  Future<String?> sentenceFor(String date) async {
    final rows = await database.loadGuidanceForDate(date);
    for (final row in rows) {
      if (row.dimension != 'synthesis') continue;
      final sentence = firstSentence(row.contentJson);
      if (sentence != null) return sentence;
    }
    return null;
  }

  /// Reads the stored passage without going through the parser.
  ///
  /// The parser validates a whole composition and refuses one that is short a
  /// dimension; this is reading one row that has already been validated once
  /// and stored. A widget is not the place to re-litigate a contract.
  @visibleForTesting
  static String? firstSentence(String contentJson) {
    try {
      final decoded = jsonDecode(contentJson);
      if (decoded is! Map) return null;
      final sentences = decoded['sentences'];
      if (sentences is! List) return null;
      for (final sentence in sentences) {
        if (sentence is String && sentence.trim().isNotEmpty) {
          return sentence.trim();
        }
      }
    } on FormatException {
      // A row that will not decode is a row nothing else could show either.
    }
    return null;
  }

  /// Local `yyyy-MM-dd`, which is what the row keys are.
  static String isoDate(DateTime at) {
    final local = at.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
