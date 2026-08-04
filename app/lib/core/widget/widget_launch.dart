/// What the home-screen widget asked for when it opened the app.
///
/// The widget has three targets: the sentence, which opens Eter where the
/// person left it, and two controls that open it **into the journal** — one
/// already listening, one with the keyboard up. The fastest thing somebody
/// wants from a home screen is to get a thought down before it goes, and
/// opening the app, finding the Journal and reaching the composer is three
/// steps too many for that.
///
/// The action arrives twice over, because there are two cases and they are not
/// the same:
///
/// * **Cold start.** The intent exists before Flutter is listening, so the
///   activity holds it and Dart *takes* it on the first frame it could act on.
///   Taken once: a request to start dictating is answered when it is made and
///   never again, or every later resume would open the microphone.
/// * **Already running.** `onNewIntent` pushes it straight through, because
///   nothing is waiting to ask.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EterWidgetAction {
  /// Open the journal and start dictating.
  speak,

  /// Open the journal with the keyboard up.
  write;

  static EterWidgetAction? fromName(String? name) => switch (name) {
        'speak' => EterWidgetAction.speak,
        'write' => EterWidgetAction.write,
        _ => null,
      };
}

/// The action waiting to be acted on, or null.
///
/// Whoever acts on it clears it. It is a request, not a state: leaving it set
/// would mean the journal reopened its microphone on every rebuild.
final widgetLaunchProvider = StateProvider<EterWidgetAction?>((ref) => null);

/// Listens for the widget's requests and puts them in [widgetLaunchProvider].
class EterWidgetLaunch {
  EterWidgetLaunch(this.ref);

  /// A `WidgetRef`, because the only thing that starts this is a widget: the
  /// shell, on its first frame, which is the first thing in the app that could
  /// act on the answer.
  final WidgetRef ref;

  static const _channel = MethodChannel('eter/widget-launch');

  /// Starts listening, and collects anything that arrived before Flutter did.
  Future<void> start() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'action') {
        _deliver(EterWidgetAction.fromName(call.arguments as String?));
      }
      return null;
    });
    try {
      _deliver(
        EterWidgetAction.fromName(await _channel.invokeMethod<String>('take')),
      );
    } catch (error) {
      // Every platform but Android, and every test binding. A home screen that
      // does not exist is not a failure of anything.
      debugPrint('No widget launch action: $error');
    }
  }

  void _deliver(EterWidgetAction? action) {
    if (action == null) return;
    ref.read(widgetLaunchProvider.notifier).state = action;
  }
}
