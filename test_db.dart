import 'package:drift/native.dart';
import 'lib/core/database.dart';
import 'package:drift/drift.dart';

void main() async {
  final db = AppDatabase();
  
  // Create a profile
  final id = await db.into(db.profiles).insert(ProfilesCompanion.insert(
    name: 'Test',
    dob: DateTime.now(),
    pob: 'Test',
    lat: 0.0,
    lon: 0.0,
  ));
  
  print('Inserted profile with id $id');
  
  // Save interpretation
  final profile = await (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingle();
  await db.update(db.profiles).replace(profile.copyWith(
    aiInterpretation: Value('This is a test interpretation'),
  ));
  
  // Fetch again
  final updatedProfile = await (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingle();
  print('Updated aiInterpretation: ${updatedProfile.aiInterpretation}');
  
}
