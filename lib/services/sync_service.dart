import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/database.dart';
import 'package:drift/drift.dart' as drift;
import '../services/api_client.dart';
import '../providers/database_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(apiClientProvider), ref.read(databaseProvider));
});

class SyncService {
  final Dio _api;
  final AppDatabase _db;

  SyncService(this._api, this._db);

  /// Triggers a bidirectional sync between local Drift DB and Cloudflare.
  Future<void> syncProfiles() async {
    try {
      // 1. Push local changes to remote
      final localUnsynced = await _db.select(_db.profiles)
        ..where((t) => t.needsSync.equals(true));
      final unsyncedList = await localUnsynced.get();

      for (var p in unsyncedList) {
        // Send to Cloudflare backend
        try {
          final response = await _api.post('/api/profiles', data: {
            'id': p.id.toString(), // Optional, let server generate or use uuid
            'name': p.name,
            'dob': p.dob.toIso8601String(),
            'pob': p.pob,
            'lat': p.lat,
            'lon': p.lon,
          });
          
          // Update local with cloudflareId and mark as synced
          await _db.update(_db.profiles).replace(p.copyWith(
            cloudflareId: drift.Value(response.data['id']?.toString() ?? ''),
            needsSync: false
          ));
        } catch (e) {
          print("Failed to push profile ${p.name}: $e");
        }
      }

      // 2. Fetch remote changes to local
      try {
        final response = await _api.get('/api/profiles');
        final remoteProfiles = response.data as List;
        
        for (var rp in remoteProfiles) {
          // Check if it exists locally by cloudflareId
          final existing = await (_db.select(_db.profiles)
            ..where((t) => t.cloudflareId.equals(rp['id'].toString()))).getSingleOrNull();

          final remoteDob = DateTime.parse(rp['dob'].toString());

          if (existing == null) {
            // Insert
            await _db.into(_db.profiles).insert(ProfilesCompanion.insert(
              name: rp['name'].toString(),
              dob: remoteDob,
              pob: rp['pob'].toString(),
              lat: double.tryParse(rp['lat'].toString()) ?? 0.0,
              lon: double.tryParse(rp['lon'].toString()) ?? 0.0,
              cloudflareId: drift.Value(rp['id'].toString()),
              needsSync: const drift.Value(false),
            ));
          } else {
            // Update
            await _db.update(_db.profiles).replace(existing.copyWith(
              name: rp['name'].toString(),
              dob: remoteDob,
              pob: rp['pob'].toString(),
              lat: double.tryParse(rp['lat'].toString()) ?? existing.lat,
              lon: double.tryParse(rp['lon'].toString()) ?? existing.lon,
              needsSync: false,
            ));
          }
        }
      } catch (e) {
        print("Failed to pull remote profiles: $e");
      }
      
      print("Sync completed securely in the background!");
    } catch (e) {
      print("Sync failed: $e");
    }
  }
}
