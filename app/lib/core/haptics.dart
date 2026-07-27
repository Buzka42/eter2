import 'package:flutter/services.dart';

abstract final class EterHaptics {
  static const _channel = MethodChannel('com.eterhealth.eter/haptics');

  static Future<void> milestone({bool inSession = false}) async {
    try {
      await _channel.invokeMethod<void>('milestone', {'inSession': inSession});
    } on MissingPluginException {
      await HapticFeedback.mediumImpact();
    } on PlatformException {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> light() => _invokeWithFallback('light');
  static Future<void> restDone() => _invokeWithFallback('restDone');

  static Future<void> _invokeWithFallback(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      await HapticFeedback.lightImpact();
    } on PlatformException {
      await HapticFeedback.lightImpact();
    }
  }
}
