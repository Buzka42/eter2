import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:eter/core/clock.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:eter/core/aether/guidance_contract.dart';
import 'package:eter/core/register.dart';
import 'package:eter/core/journal/classification_contract.dart';
import 'package:eter/core/theme.dart';
import 'package:eter/core/vessel/reading_composer.dart';
import 'package:eter/features/prototype/fixtures.dart';
import 'package:eter/features/shell/eter_shell.dart';
import 'package:eter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pinned prototype moment: a Wednesday in late July, mid-morning, so the
/// balanced register resolves to day at the fixture's London coordinates.
final DateTime eterPinnedNow = DateTime(2026, 7, 27, 10, 8);

/// An in-memory store carrying the prototype fixtures.
Future<AppDatabase> eterTestDatabase({DateTime? now}) async {
  // Widget tests intentionally create a fresh in-memory store per case and
  // leave it open to avoid Drift's FakeAsync close deadlock. They never share
  // an executor, so the global duplicate-class warning is noise here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  await PrototypeFixtures.seedIfEmpty(db, now ?? eterPinnedNow);
  return db;
}

/// Loads the real Cormorant Garamond and Inter faces from disk, so goldens
/// render the product's actual typography rather than the test fallback.
Future<void> loadEterFonts() async {
  ByteData bytes(String path) =>
      ByteData.view(File(path).readAsBytesSync().buffer);
  final cormorant = FontLoader('Cormorant Garamond');
  for (final file in const [
    'CormorantGaramond-Light.ttf',
    'CormorantGaramond-Regular.ttf',
    'CormorantGaramond-Medium.ttf',
    'CormorantGaramond-Italic.ttf',
    'CormorantGaramond-MediumItalic.ttf',
  ]) {
    cormorant.addFont(Future.value(bytes('assets/fonts/$file')));
  }
  final inter = FontLoader('Inter');
  for (final file in const [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
    'Inter-ExtraBold.ttf',
  ]) {
    inter.addFont(Future.value(bytes('assets/fonts/$file')));
  }
  await Future.wait([cormorant.load(), inter.load()]);
}

/// The shell as the prototype ships it, against the pinned clock and an
/// explicit register.
Widget eterPrototypeApp({
  required AppDatabase db,
  DateTime? now,
  EterRegister register = EterRegister.day,
  bool reduceMotion = false,
  double textScale = 1.0,
  JournalClassificationProvider? journalProvider,
  AetherProvider? aetherProvider,
  VesselReadingProvider? vesselProvider,
}) {
  final pinned = now ?? eterPinnedNow;
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      nowProvider.overrideWithValue(() => pinned),
      if (journalProvider != null)
        journalClassificationProvider.overrideWithValue(journalProvider),
      if (aetherProvider != null)
        aetherTransportProvider.overrideWithValue(aetherProvider),
      if (vesselProvider != null)
        vesselReadingTransportProvider.overrideWithValue(vesselProvider),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EterTheme.day(),
      darkTheme: EterTheme.night(),
      themeMode:
          register == EterRegister.night ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) {
          // Merge into the real MediaQuery — replacing it wholesale would
          // drop the size and padding the shell's SafeArea depends on.
          final query = MediaQuery.of(context);
          return MediaQuery(
            data: query.copyWith(
              disableAnimations: reduceMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: EterRegisterScope(
              register: register,
              child: const EterShell(),
            ),
          );
        },
      ),
    ),
  );
}

/// Sizes the test surface like a phone in logical pixels (ratio 1:1).
void eterSurfaceSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
