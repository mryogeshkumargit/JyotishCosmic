// Verifies AstroEngine and the modules built on it against reference values produced by the
// Swiss Ephemeris command-line tool (see tool/gen_reference.py).
//
// Needs the native Swiss Ephemeris library. CI builds it and sets SWEPH_DYLIB_PATH; when it is
// not available the whole group is skipped.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/astro_engine.dart';
import 'package:mobile_jyotish/core/barshphal_math.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/kp_math.dart';
import 'package:mobile_jyotish/core/panchang_math.dart';
import 'package:mobile_jyotish/core/vedic_math.dart';
import 'package:sweph/sweph.dart' show AssetLoader;

class _PackageFileLoader implements AssetLoader {
  final String packageRoot;
  _PackageFileLoader(this.packageRoot);

  @override
  Future<Uint8List> load(String assetPath) async {
    final rel = assetPath.replaceFirst('packages/sweph/', '');
    return File('$packageRoot/$rel').readAsBytesSync();
  }
}

/// Angle difference in degrees (handles the 0/360 wrap).
double _d(double a, double b) => VedicMath.angularDistance(a, b);

void main() {
  final fixtures = (jsonDecode(File('test/fixtures/swe_reference.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  String? skipReason;

  setUpAll(() async {
    try {
      final libUri = await Isolate.resolvePackageUri(Uri.parse('package:sweph/sweph.dart'));
      final packageRoot = File.fromUri(libUri!).parent.parent.path;
      final tmp = Directory.systemTemp.createTempSync('ephe');
      await AstroEngine.init(assetLoader: _PackageFileLoader(packageRoot), epheFilesPath: tmp.path);
    } catch (e) {
      // In CI the library is always provided, so a failure there must fail the tests.
      if (Platform.environment.containsKey('SWEPH_DYLIB_PATH')) rethrow;
      skipReason = 'Swiss Ephemeris native library not available: $e';
    }
  });

  bool skip() {
    if (skipReason != null) {
      // ignore: avoid_print
      print('SKIPPED: $skipReason');
      return true;
    }
    return false;
  }

  for (final f in fixtures) {
    final name = f['name'] as String;
    final date = (f['date'] as List).cast<int>();
    final time = (f['time'] as List).cast<int>();
    final offset = (f['utcOffset'] as num).toDouble();
    final lat = (f['lat'] as num).toDouble();
    final lon = (f['lon'] as num).toDouble();

    ChartData chart() => Ephemeris.computeChart(
        date[0], date[1], date[2], time[0].toDouble(), time[1].toDouble(), lat, lon, offset);

    group(name, () {
      test('Julian Day and ayanamsa', () {
        if (skip()) return;
        final c = chart();
        expect(c.jd, closeTo((f['jd'] as num).toDouble(), 1e-6));
        expect(c.ayanamsa, closeTo((f['ayanamsaLahiri'] as num).toDouble(), 1e-4));
      });

      test('Planet longitudes (Lahiri) within 0.001° and retrograde state', () {
        if (skip()) return;
        final c = chart();
        final ref = (f['planets'] as Map).cast<String, dynamic>();
        ref.forEach((planet, v) {
          final refLon = (v['lon'] as num).toDouble();
          final refSpeed = (v['speed'] as num).toDouble();
          expect(_d(c.planetLongitudes[planet]!, refLon), lessThan(0.001), reason: planet);
          if (planet != 'rahu') {
            expect(c.planets[planet]!.speed < 0, refSpeed < 0, reason: '$planet retrograde');
          }
        });
        final rahu = (ref['rahu']['lon'] as num).toDouble();
        expect(_d(c.planetLongitudes['ketu']!, rahu + 180), lessThan(0.001));
      });

      test('Ascendant within 0.001°', () {
        if (skip()) return;
        expect(_d(chart().ascendantSidereal, (f['ascendant'] as num).toDouble()), lessThan(0.001));
      });

      test('Whole-sign houses match planet signs', () {
        if (skip()) return;
        final c = chart();
        c.planetLongitudes.forEach((p, lon0) {
          final h = VedicMath.houseOf(VedicMath.rashiIndex(lon0), c.lagnaRashi);
          expect(c.housePlanets[h], contains(Ephemeris.abbreviations[p]));
        });
      });

      test('KP Placidus cusps (Krishnamurti ayanamsa) within 0.001°', () {
        if (skip()) return;
        final c = chart();
        final cusps = KPMath.placidusCusps(c.jd, lat, lon);
        final ref = (f['kpCusps'] as List).map((e) => (e as num).toDouble()).toList();
        for (int i = 1; i <= 12; i++) {
          expect(_d(cusps[i], ref[i - 1]), lessThan(0.001), reason: 'cusp $i');
        }
        // The Lahiri setting must be restored afterwards.
        expect(AstroEngine.ayanamsa, AyanamsaSystem.lahiri);
        final kp = KPMath.computeKPPlanets(c);
        final refKp = (f['kpPlanets'] as Map).cast<String, dynamic>();
        expect(_d(kp['moon']!.longitude, (refKp['moon'] as num).toDouble()), lessThan(0.001));
      });

      test('Sunrise and sunset within 1 minute', () {
        if (skip()) return;
        final localMidnightUt =
            Ephemeris.julianDay(date[0], date[1], date[2], 0) - offset / 24.0;
        final rise = AstroEngine.nextSunrise(localMidnightUt, lat, lon)!;
        final set = AstroEngine.nextSunset(localMidnightUt, lat, lon)!;
        expect(rise, closeTo((f['sunriseJd'] as num).toDouble(), 1 / 1440));
        expect(set, closeTo((f['sunsetJd'] as num).toDouble(), 1 / 1440));
      });

      test('Panchang: limbs consistent with positions and end times', () {
        if (skip()) return;
        final c = chart();
        final p = PanchangMath.forChart(c);
        final elong = VedicMath.norm360(c.planetLongitudes['moon']! - c.planetLongitudes['sun']!);
        expect(p.tithi.index + 1, PanchangMath.tithiNumber(elong));
        expect(p.nakshatra.index, VedicMath.nakshatraIndex(c.planetLongitudes['moon']!));

        // At the tithi end time the elongation must sit on a 12° boundary.
        final tEnd = p.tithi.endsAtJd!;
        expect(tEnd, greaterThan(c.jd));
        expect(tEnd - c.jd, lessThan(1.2));
        final atEnd = VedicMath.norm360(AstroEngine.planet(tEnd, 'moon').longitude -
            AstroEngine.planet(tEnd, 'sun').longitude);
        expect(_d(atEnd, (p.tithi.index + 1) * 12.0), lessThan(1e-4));

        final nEnd = p.nakshatra.endsAtJd!;
        final moonAtEnd = AstroEngine.planet(nEnd, 'moon').longitude;
        expect(_d(moonAtEnd, (p.nakshatra.index + 1) * 360 / 27), lessThan(1e-4));

        // Rahu Kaal lies within the day and lasts one eighth of it.
        final rk = p.rahuKaal!;
        final dayLen = p.sunsetJd! - p.sunriseJd!;
        expect(rk.endJd - rk.startJd, closeTo(dayLen / 8, 1e-9));
        expect(rk.startJd, greaterThanOrEqualTo(p.sunriseJd! - 1e-9));
        expect(rk.endJd, lessThanOrEqualTo(p.sunsetJd! + 1e-9));
      });

      test('Solar return lands on the natal Sun', () {
        if (skip()) return;
        final c = chart();
        final natalSun = c.planetLongitudes['sun']!;
        final sr = BarshphalMath.solarReturnNear(natalSun, c.jd + 30 * 365.2422);
        expect(_d(AstroEngine.planet(sr, 'sun').longitude, natalSun), lessThan(1e-5));
        expect((sr - c.jd) / 365.25, closeTo(30, 0.05));
      });
    });
  }

  test('Vara follows the Hindu day (starts at sunrise)', () {
    if (skip()) return;
    // New York 1975-11-03 04:10 local is before sunrise, so it is still Sunday.
    final ny = fixtures.firstWhere((f) => f['name'] == 'New York 1975');
    final c = Ephemeris.computeChart(1975, 11, 3, 4, 10, 40.7128, -74.0060, -5);
    expect(PanchangMath.forChart(c).varaName, 'Sunday');
    expect(ny, isNotNull);
    // Delhi 1990-08-15 06:30 is after sunrise: Wednesday.
    final delhi = Ephemeris.computeChart(1990, 8, 15, 6, 30, 28.6139, 77.2090, 5.5);
    expect(PanchangMath.forChart(delhi).varaName, 'Wednesday');
  });

  test('Dasha starts from the Moon nakshatra lord', () {
    if (skip()) return;
    final c = Ephemeris.computeChart(1990, 8, 15, 6, 30, 28.6139, 77.2090, 5.5);
    final d = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!);
    final lord = VedicMath.nakshatraLord[VedicMath.nakshatraIndex(c.planetLongitudes['moon']!)];
    expect(d.runningAt(c.jd).first.lord, lord);
  });
}
