import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/database.dart';
import 'package:mobile_jyotish/core/profile_chart.dart';

void main() {
  test('profiles are stored locally and keep the birth wall-clock time', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.into(db.profiles).insert(ProfilesCompanion.insert(
      name: 'Test',
      dob: encodeWallClock(1990, 3, 11, 2, 30),
      pob: 'Pune, Maharashtra, India',
      lat: 18.52,
      lon: 73.86,
      timezone: const Value(5.5),
      tzName: const Value('Asia/Kolkata'),
      gender: const Value('Female'),
    ));

    var profile = await (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingle();
    expect(profile.aiInterpretation, isNull);
    final b = profile.birthWallClock;
    expect([b.year, b.month, b.day, b.hour, b.minute], [1990, 3, 11, 2, 30]);
    expect(profile.gender, 'Female');

    await db.update(db.profiles).replace(profile.copyWith(aiInterpretation: const Value('Test Interpretation')));
    profile = await (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingle();
    expect(profile.aiInterpretation, 'Test Interpretation');
  });

  test('migration from schema 3 drops cloud-sync columns and re-encodes birth time', () async {
    // A device-local instant as written by schema 3 (drift stores unix seconds).
    final oldLocal = DateTime(1985, 7, 4, 23, 45);
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE profiles (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          cloudflare_id TEXT NULL,
          name TEXT NOT NULL,
          dob INTEGER NOT NULL,
          pob TEXT NOT NULL,
          lat REAL NOT NULL,
          lon REAL NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
          needs_sync INTEGER NOT NULL DEFAULT 1,
          ai_interpretation TEXT NULL,
          timezone REAL NOT NULL DEFAULT 5.5
        );
      ''');
      raw.execute(
          "INSERT INTO profiles (cloudflare_id, name, dob, pob, lat, lon, needs_sync) VALUES ('cf-1', 'Old', ${oldLocal.millisecondsSinceEpoch ~/ 1000}, 'Delhi', 28.6, 77.2, 1)");
      raw.execute('PRAGMA user_version = 3');
    });
    final db = AppDatabase.forTesting(executor);
    addTearDown(db.close);

    final profile = await db.select(db.profiles).getSingle();
    final b = profile.birthWallClock;
    expect([b.year, b.month, b.day, b.hour, b.minute], [1985, 7, 4, 23, 45]);

    final columns = await db.customSelect('PRAGMA table_info(profiles)').get();
    final names = columns.map((r) => r.read<String>('name')).toSet();
    expect(names.contains('cloudflare_id'), isFalse);
    expect(names.contains('needs_sync'), isFalse);
    expect(names.containsAll({'tz_name', 'gender'}), isTrue);
  });
}
