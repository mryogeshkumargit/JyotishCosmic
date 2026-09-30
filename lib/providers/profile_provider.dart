import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../core/database.dart';
import '../providers/database_provider.dart';

/// All saved profiles. Backed by a drift query stream so every screen updates
/// as soon as the local database changes. Nothing is ever sent off-device.
final profileListProvider = StreamProvider<List<Profile>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.profiles)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
});

final editProfileProvider = NotifierProvider<EditProfileNotifier, Profile?>(EditProfileNotifier.new);

class EditProfileNotifier extends Notifier<Profile?> {
  @override
  Profile? build() => null;
  void setProfile(Profile? profile) => state = profile;
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, void>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Inserts a profile and returns its id. [dob] must be a wall-clock time
  /// encoded as UTC (see `encodeWallClock`).
  Future<int> addProfile({
    required String name,
    required DateTime dob,
    required String pob,
    required double lat,
    required double lon,
    required double timezone,
    String? tzName,
    String? gender,
  }) {
    final db = ref.read(databaseProvider);
    return db.into(db.profiles).insert(ProfilesCompanion.insert(
      name: name,
      dob: dob,
      pob: pob,
      lat: lat,
      lon: lon,
      timezone: Value(timezone),
      tzName: Value(tzName),
      gender: Value(gender),
    ));
  }

  Future<void> updateProfile(Profile profile) async {
    final db = ref.read(databaseProvider);
    await db.update(db.profiles).replace(profile.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteProfile(Profile profile) async {
    final db = ref.read(databaseProvider);
    await db.delete(db.profiles).delete(profile);
  }

  /// Appends an AI interpretation to the profile's saved interpretations.
  Future<void> saveInterpretation(int profileId, String interpretation) async {
    final db = ref.read(databaseProvider);
    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(profileId))).getSingle();

    String newInterpretation = interpretation;
    if (profile.aiInterpretation != null && profile.aiInterpretation!.isNotEmpty) {
      newInterpretation = '${profile.aiInterpretation}\n\n---\n\n$interpretation';
    }

    await (db.update(db.profiles)..where((t) => t.id.equals(profileId))).write(
      ProfilesCompanion(
        aiInterpretation: Value(newInterpretation),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
