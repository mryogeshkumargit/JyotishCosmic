import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

/// Birth profiles, stored in the on-device SQLite database and optionally
/// synced to the cloud when the user signs in to Cloud Sync.
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

  /// Id of this profile on the sync server (null until first uploaded).
  TextColumn get cloudflareId => text().nullable()();

  /// True when local changes have not been uploaded yet.
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
}

/// Cloud ids of profiles deleted locally whose deletion has not reached the server.
class PendingDeletions extends Table {
  TextColumn get cloudId => text()();

  @override
  Set<Column> get primaryKey => {cloudId};
}

@DriftDatabase(tables: [Profiles, PendingDeletions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

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
        }
        if (from < 5) {
          // Cloud sync columns: present since schema 1, but may be missing on
          // pre-release builds of schema 4 that dropped them.
          final existing = (await customSelect('PRAGMA table_info(profiles)').get())
              .map((r) => r.read<String>('name'))
              .toSet();
          if (!existing.contains('cloudflare_id')) await m.addColumn(profiles, profiles.cloudflareId);
          if (!existing.contains('needs_sync')) await m.addColumn(profiles, profiles.needsSync);
          await m.createTable(pendingDeletions);
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
