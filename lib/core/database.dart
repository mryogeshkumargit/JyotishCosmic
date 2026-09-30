import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

/// Birth profiles, stored only in the on-device SQLite database.
///
/// [dob] holds the local wall-clock birth time encoded as a UTC [DateTime]
/// (e.g. 05:30 local is stored as 05:30Z). This keeps the birth time stable
/// regardless of the phone's own time zone or daylight saving rules; the
/// place's offset lives in [timezone].
@DataClassName('Profile')
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get dob => dateTime()();
  TextColumn get pob => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get aiInterpretation => text().nullable()();

  /// UTC offset in hours at the time of birth (e.g. 5.5 for IST).
  RealColumn get timezone => real().withDefault(const Constant(5.5))();

  /// IANA time zone of the birth place, when chosen from the city list.
  TextColumn get tzName => text().nullable()();

  /// 'Male' / 'Female' (optional).
  TextColumn get gender => text().nullable()();
}

@DriftDatabase(tables: [Profiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(profiles, profiles.aiInterpretation);
        }
        if (from < 3) {
          await m.addColumn(profiles, profiles.timezone);
        }
        if (from < 4) {
          await m.addColumn(profiles, profiles.tzName);
          await m.addColumn(profiles, profiles.gender);

          // Earlier versions stored the birth time as a device-local instant.
          // Re-encode it as wall-clock-in-UTC (see [Profiles.dob]).
          final rows = await customSelect('SELECT id, dob FROM profiles').get();
          for (final row in rows) {
            final local = DateTime.fromMillisecondsSinceEpoch(row.read<int>('dob') * 1000);
            final wall = DateTime.utc(local.year, local.month, local.day, local.hour, local.minute, local.second);
            await customUpdate(
              'UPDATE profiles SET dob = ? WHERE id = ?',
              variables: [Variable.withInt(wall.millisecondsSinceEpoch ~/ 1000), Variable.withInt(row.read<int>('id'))],
              updates: {profiles},
            );
          }

          // Drop the obsolete cloud-sync columns (cloudflare_id, needs_sync).
          await m.alterTable(TableMigration(profiles));
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
