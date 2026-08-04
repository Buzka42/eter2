import 'package:eter/core/i18n/language.dart';
import 'package:eter/core/i18n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The language of a route that is *pushed*, rather than one that is built.
///
/// Found on a phone: the Journal's History sheet came up in English on a
/// Polish app — HISTORY, CLOSE, "Tuesday 4 August", KEEP LOCAL — while every
/// surface behind it was Polish.
///
/// The cause is a shape, not a string. `EterStringsScope` was installed as
/// `MaterialApp.home`, and `home` is a *route*: anything pushed on top of it
/// is a sibling rather than a child and inherits nothing from it.
/// `EterStrings.of` documents its own fallback as English, so a modal sheet
/// got English and said nothing about it.
///
/// Nothing in the suite could see it, because a widget test pumps a sheet
/// under whatever scope it likes. This test pushes one the way the app does.
void main() {
  /// The app's shape: scopes wrapping every route through `builder`.
  Widget appWith({required AppLanguage language, required Widget home}) =>
      MaterialApp(
        builder: (context, child) => EterStringsScope(
          strings: EterStrings.forLanguage(language),
          child: child ?? const SizedBox.shrink(),
        ),
        home: home,
      );

  testWidgets('a pushed route speaks the language the app is in',
      (tester) async {
    await tester.pumpWidget(appWith(
      language: AppLanguage.polish,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (context) => Text(EterStrings.of(context).journalHistory),
          ),
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final polish = EterStrings.forLanguage(AppLanguage.polish).journalHistory;
    final english = EterStrings.forLanguage(AppLanguage.english).journalHistory;
    expect(polish, isNot(english), reason: 'the fixture word must differ');
    expect(find.text(polish), findsOneWidget);
    expect(find.text(english), findsNothing);
  });

  testWidgets('the same is true of a dialog', (tester) async {
    await tester.pumpWidget(appWith(
      language: AppLanguage.polish,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => Text(EterStrings.of(context).close),
          ),
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text(EterStrings.forLanguage(AppLanguage.polish).close),
      findsOneWidget,
    );
  });

  testWidgets('installed only on home, a pushed route falls back to English',
      (tester) async {
    // The shape that shipped, kept as a test so the reason the `builder` is
    // there cannot be forgotten and quietly undone.
    await tester.pumpWidget(MaterialApp(
      home: EterStringsScope(
        strings: EterStrings.forLanguage(AppLanguage.polish),
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) =>
                  Text(EterStrings.of(context).journalHistory),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text(EterStrings.forLanguage(AppLanguage.english).journalHistory),
      findsOneWidget,
      reason: 'this is the bug, and it is here to show what fixed it',
    );
  });
}
