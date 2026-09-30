import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled offline city database finds Indian towns with time zones', () async {
    final results = await LocationService().searchCity('Varanasi');
    expect(results, isNotEmpty);
    expect(results.first.displayName, contains('Uttar Pradesh'));
    expect(results.first.tzName, 'Asia/Kolkata');
    expect(results.first.lat, closeTo(25.32, 0.05));

    final accent = await LocationService().searchCity('Sao Paulo');
    expect(accent.first.displayName, startsWith('São Paulo'));
  });

  test('historical UTC offsets including DST and Indian war time', () {
    expect(LocationService.utcOffsetFor('Asia/Kolkata', DateTime(1990, 1, 1, 12)), 5.5);
    expect(LocationService.utcOffsetFor('Asia/Kolkata', DateTime(1943, 6, 1, 12)), 6.5);
    expect(LocationService.utcOffsetFor('America/New_York', DateTime(2020, 7, 1, 12)), -4);
    expect(LocationService.utcOffsetFor('America/New_York', DateTime(2020, 1, 1, 12)), -5);
    expect(LocationService.utcOffsetFor(null, DateTime(2020)), isNull);
  });
}
