import 'package:drift/native.dart';
import 'package:eter/core/ai/install_id.dart';
import 'package:eter/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one identifier Eter has, and what it is deliberately not.
///
/// It exists so the endpoint can meter one install rather than refusing everybody
/// when one install loops. Everything below is about keeping it worthless to
/// anyone who holds it.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('is minted once and then stable', () async {
    final first = await EterInstallId.ensure(database);
    final second = await EterInstallId.ensure(database);

    expect(first, second);
    expect(first, hasLength(32), reason: '16 bytes, hex');
    expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('two installs do not collide', () async {
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);

    expect(
      await EterInstallId.ensure(database),
      isNot(await EterInstallId.ensure(other)),
    );
  });

  test('deleting local data forgets it', () async {
    final first = await EterInstallId.ensure(database);
    await database.deleteAllLocalData();
    final second = await EterInstallId.ensure(database);

    // It lives in `IntakeAnswers`, which delete-everything truncates. An
    // identifier that survived "remove every local Eter record" would be the one
    // thing that did, which is exactly the property that makes an id personal.
    expect(second, isNot(first));
  });

  test('it is not derived from anything about the person', () async {
    // A weak assertion of a strong intent, and worth making anyway: the profile
    // is populated before the id is minted, and nothing in the id reflects it.
    await database.saveProfile(ProfilesCompanion.insert(
      dob: DateTime(1990, 3, 14),
      sex: 'other',
      weightKg: 70,
      units: 'metric',
    ));
    final id = await EterInstallId.ensure(database);

    for (final trace in ['1990', '03', '14', '70', 'other']) {
      expect(id, isNot(startsWith(trace)));
    }
  });

  test('is not offered to the prompt builder as intake', () async {
    await EterInstallId.ensure(database);
    final answers = await database.loadIntakeAnswers();

    // It shares a table with the onboarding answers, so it has to be graded in a
    // way that keeps it out of what the prompt builder weighs.
    expect(answers[EterInstallId.answerKey]?.tier, 'optional');
  });
}
