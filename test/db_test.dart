import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

void main() {
  test('Save Interpretation Test', () async {
    final db = AppDatabase();
    
    final id = await db.into(db.profiles).insert(ProfilesCompanion.insert(
      name: 'Test',
      dob: DateTime.now(),
      pob: 'Test',
      lat: 0.0,
      lon: 0.0,
    ));
    
    var profile = await (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingle();
    expect(profile.aiInterpretation, null);
    
    await db.update(db.profiles).replace(profile.copyWith(
      aiInterpretation: const Value('Test Interpretation'),
    ));
    
    profile = await (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingle();
    expect(profile.aiInterpretation, 'Test Interpretation');
    
    print('SUCCESS! AI Interpretation was saved: \${profile.aiInterpretation}');
  });
}
