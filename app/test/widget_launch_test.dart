import 'package:eter/core/widget/widget_launch.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the home-screen widget asks the app to do.
///
/// Two controls on the widget open Eter *into* the journal — one already
/// listening, one with the keyboard up — and the request reaches Dart by two
/// different routes depending on whether the app was running.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('eter/widget-launch');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  String? pending;
  var takes = 0;

  setUp(() {
    pending = null;
    takes = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'take') {
        takes++;
        final answer = pending;
        // The activity clears it on the way out, and so does this: a request
        // to start dictating is answered once, not on every resume.
        pending = null;
        return answer;
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// A container with a `WidgetRef`-shaped view of it, which is what the shell
  /// hands the launcher.
  Future<ProviderContainer> start(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    late WidgetRef captured;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await EterWidgetLaunch(captured).start();
    return container;
  }

  testWidgets('a cold start collects what arrived before Flutter did',
      (tester) async {
    pending = 'speak';
    final container = await start(tester);
    expect(container.read(widgetLaunchProvider), EterWidgetAction.speak);
    expect(takes, 1);
  });

  testWidgets('nothing pending asks for nothing to be done', (tester) async {
    final container = await start(tester);
    expect(container.read(widgetLaunchProvider), isNull);
  });

  testWidgets('a running app is told through the channel', (tester) async {
    // `onNewIntent`: the second press of the widget's button, with Eter
    // already open. Nothing is waiting to ask, so it comes straight through.
    final container = await start(tester);
    expect(container.read(widgetLaunchProvider), isNull);

    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('action', 'write'),
      ),
      (_) {},
    );
    expect(container.read(widgetLaunchProvider), EterWidgetAction.write);
  });

  testWidgets('an action nobody knows is not acted on at all', (tester) async {
    // A widget from a newer build, or a launcher replaying something odd.
    pending = 'delete-everything';
    final container = await start(tester);
    expect(container.read(widgetLaunchProvider), isNull);
  });

  testWidgets('a platform with no widget is not a failure', (tester) async {
    // Every platform but Android. The channel answers with
    // `MissingPluginException` and the app starts normally — the alternative
    // being an app that will not open on iOS because a home screen it does not
    // have did not reply.
    //
    // Thrown explicitly rather than by leaving the channel unhandled: an
    // unhandled channel under the test binding never completes at all, and the
    // test hangs for ten minutes instead of failing.
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException('no widget on this platform');
    });
    final container = await start(tester);
    expect(container.read(widgetLaunchProvider), isNull);
  });

  test('only the two actions the widget can send are understood', () {
    expect(EterWidgetAction.fromName('speak'), EterWidgetAction.speak);
    expect(EterWidgetAction.fromName('write'), EterWidgetAction.write);
    expect(EterWidgetAction.fromName(null), isNull);
    expect(EterWidgetAction.fromName(''), isNull);
  });
}
