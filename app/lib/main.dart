import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/db/app_database.dart';
import 'core/theme.dart';

/// Bootstrap.
///
/// Opens the canonical local store, then hands off. The surfaces themselves --
/// the Journal, the Dashboard and the Sanctum -- are not built yet; see
/// `docs/UI_BRIEF.md` for what they are and the contracts they render against.
///
/// Deliberately minimal. Firebase initialisation, the auth gate, the register
/// scope and the health resume-sync wrapper all belong in the wrapper chain
/// here and are added as those layers land.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const EterApp(),
    ),
  );
}

/// The canonical store. Overridden at the root so tests and the background
/// isolate can supply their own; reading it without an override is a
/// programming error rather than a silent fallback to a second database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider must be overridden'),
);

class EterApp extends StatelessWidget {
  const EterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eter',
      debugShowCheckedModeBanner: false,
      theme: EterTheme.day(),
      darkTheme: EterTheme.night(),
      home: const _Unbuilt(),
    );
  }
}

/// Placeholder until the shell lands. Not a splash screen and not a design --
/// it exists so `flutter run` boots and the theme can be eyeballed.
class _Unbuilt extends StatelessWidget {
  const _Unbuilt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Eter', style: Theme.of(context).textTheme.displaySmall),
      ),
    );
  }
}
