import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../core/database.dart';
import '../providers/database_provider.dart';
import '../services/sync_service.dart';

final profileListProvider = FutureProvider<List<Profile>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.select(db.profiles).get();
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

  Future<void> addProfile(String name, DateTime dob, String pob, double lat, double lon, double timezone) async {
    try {
      final db = ref.read(databaseProvider);
      final syncService = ref.read(syncServiceProvider);
      
      await db.into(db.profiles).insert(ProfilesCompanion.insert(
        name: name,
        dob: dob,
        pob: pob,
        lat: lat,
        lon: lon,
        timezone: Value(timezone),
        needsSync: const Value(true),
      ));
      
      ref.invalidate(profileListProvider);
      syncService.syncProfiles();
    } catch (e) {
      print("Error saving profile: $e");
    }
  }

  Future<void> updateProfile(Profile profile) async {
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);

    await db.update(db.profiles).replace(profile.copyWith(
      updatedAt: DateTime.now(),
      needsSync: true,
    ));
    
    ref.invalidate(profileListProvider);
    syncService.syncProfiles();
  }

  Future<void> deleteProfile(Profile profile) async {
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);

    await db.delete(db.profiles).delete(profile);
    ref.invalidate(profileListProvider);
    syncService.syncProfiles();
  }

  Future<void> saveInterpretation(int profileId, String interpretation) async {
    final db = ref.read(databaseProvider);
    final syncService = ref.read(syncServiceProvider);

    final profile = await (db.select(db.profiles)..where((t) => t.id.equals(profileId))).getSingle();
    
    String newInterpretation = interpretation;
    if (profile.aiInterpretation != null && profile.aiInterpretation!.isNotEmpty) {
      newInterpretation = '${profile.aiInterpretation}\n\n---\n\n$interpretation';
    }

    await (db.update(db.profiles)..where((t) => t.id.equals(profileId))).write(
      ProfilesCompanion(
        aiInterpretation: Value(newInterpretation),
        updatedAt: Value(DateTime.now()),
        needsSync: const Value(true),
      ),
    );
    
    ref.invalidate(profileListProvider);
    // syncService.syncProfiles(); // Temporarily disabled to prevent any possible sync overwrites
  }
}
