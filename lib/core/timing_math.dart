import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'calc_config.dart';
import 'ephemeris.dart';
import 'jaimini_math.dart';
import 'l10n.dart';
import 'precision_math.dart';
import 'vedic_math.dart';

/// A natal point a transit can trigger.
class TriggerTarget {
  /// Stable code, e.g. NATAL_SUN, BHAVA_10 (equal-house cusp from the Lagna degree).
  final String code;
  final String label;
  final double longitude;
  const TriggerTarget(this.code, this.label, this.longitude);
}

/// One pass of a slow planet through the orb of an exact aspect point
/// (Volume 6 §37 and §93).
class TransitTrigger {
  final String transit;
  final TriggerTarget target;

  /// Angle from the transiting planet to the target: 0, 60, 120, 180, 240 or 270.
  final int angle;
  final double enterJd;
  final double exitJd;
  final List<double> exactJds;

  /// A second or later pass of the same point within the scan (retrograde loop).
  final bool recontact;

  /// Closest approach (degrees) during the pass.
  final double minOrb;
  final double utcOffset;

  const TransitTrigger(this.transit, this.target, this.angle, this.enterJd, this.exitJd, this.exactJds, this.recontact, this.minOrb, this.utcOffset);

  static const Map<int, String> aspectCodes = {0: 'CONJUNCTION', 60: '3RD', 120: '5TH', 180: '7TH', 240: '9TH', 270: '10TH'};
  String get aspect => aspectCodes[angle] ?? '$angle';
  String get aspectLabel => angle == 0
      ? tr('conjunction', 'युति')
      : tr('${aspect.toLowerCase()}-house aspect', '${aspect.replaceAll(RegExp('[A-Z]'), '')}वीं दृष्टि');

  String date(double jd) => VedicMath.jdToDate(jd + utcOffset / 24);
  String get enterDate => date(enterJd);
  String get exitDate => date(exitJd);
  List<String> get exactDates => [for (final j in exactJds) date(j)];

  bool activeAt(double jd) => jd >= enterJd && jd <= exitJd;

  /// Applying while an exact date is still ahead within the pass.
  bool applyingAt(double jd) => activeAt(jd) && exactJds.any((e) => e >= jd);

  String get strength => exactJds.isEmpty ? 'LOW' : (exactJds.length > 1 || minOrb < 0.25 ? 'HIGH' : 'MEDIUM');

  /// Activation tag in the Volume 6 §92 style.
  String get tag => '${transit.toUpperCase()}_${angle == 0 ? 'TRANSIT' : '${aspect}_ASPECT'}_${target.code.replaceFirst('NATAL_', '').replaceFirst('BHAVA_', 'H')}';

  String get summary => tr(
      '${VedicMath.planets[transit]!.name} $aspectLabel to ${target.label}: '
          '$enterDate → ${exactDates.isEmpty ? 'closest ${minOrb.toStringAsFixed(2)}°' : 'exact ${exactDates.join(', ')}'} → $exitDate'
          '${recontact ? ' (retrograde re-contact)' : ''}',
      '${L10n.planet(transit)} की ${target.label} पर $aspectLabel: '
          '$enterDate → ${exactDates.isEmpty ? 'निकटतम ${minOrb.toStringAsFixed(2)}°' : 'सटीक ${exactDates.join(', ')}'} → $exitDate'
          '${recontact ? ' (वक्री होकर दोबारा संपर्क)' : ''}');

  Map<String, dynamic> toJson() => {
        'transit': transit.toUpperCase(),
        'target': target.code,
        'aspect': aspect,
        'enter_date': enterDate,
        'exact_dates': exactDates,
        'separating_date': exitDate,
        'min_orb': double.parse(minOrb.toStringAsFixed(3)),
        'recontact': recontact,
        'trigger_strength': strength,
      };
}

/// Daśā period intersected with a transit trigger (Volume 6 §91-92).
class TimingWindow {
  final String domainCode;
  final double startJd;
  final double endJd;
  final String start;
  final String end;
  final List<String> activation;
  final String status;
  final List<TransitTrigger> triggers;
  const TimingWindow(this.domainCode, this.startJd, this.endJd, this.start, this.end, this.activation, this.status, this.triggers);

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'event_domain': domainCode,
        'activation': activation,
        'status': status,
        'triggers': [for (final t in triggers) t.toJson()],
      };
}

/// Birth-time sensitivity (Volume 6 §94).
class SensitivityResult {
  final List<int> offsets;

  /// Factor -> value at each offset.
  final Map<String, List<String>> values;
  const SensitivityResult(this.offsets, this.values);

  List<String> get stable => [for (final e in values.entries) if (e.value.toSet().length == 1) e.key];
  List<String> get sensitive => [for (final e in values.entries) if (e.value.toSet().length > 1) e.key];

  Map<String, dynamic> toJson() => {'offsets_minutes': offsets, 'stable': stable, 'sensitive': sensitive};
}

class TimingMath {
  /// Slow planets and the angles (planet → target) they trigger.
  static const Map<String, List<int>> aspectAngles = {
    'jupiter': [0, 120, 180, 240],
    'saturn': [0, 60, 180, 270],
    'rahu': [0],
    'ketu': [0],
  };

  static const double _step = 2;

  /// Natal planets plus the twelve equal-house cusps from the Lagna degree.
  static List<TriggerTarget> natalTargets(ChartData c) => [
        for (final p in Ephemeris.planetOrder)
          if (c.planetLongitudes.containsKey(p))
            TriggerTarget('NATAL_${p.toUpperCase()}', tr('natal ${VedicMath.planets[p]!.name}', 'जन्म के ${L10n.planet(p)}'), c.planetLongitudes[p]!),
        for (int h = 1; h <= 12; h++)
          TriggerTarget('BHAVA_$h', h == 1 ? tr('the Lagna degree', 'लग्न अंश') : tr('the ${VedicMath.ordinal(h)} cusp', '$hवें भाव की संधि'),
              VedicMath.norm360(c.ascendantSidereal + (h - 1) * 30)),
      ];

  /// Every pass of Jupiter, Saturn, Rahu and Ketu through the orb of an exact
  /// aspect point of [targets] between [fromJd] and [fromJd] + [years].
  static List<TransitTrigger> triggers(ChartData c, List<TriggerTarget> targets,
      {required double fromJd, double years = 3, double orb = 2.0, Iterable<String>? planets}) {
    final n = (years * 365.25 / _step).ceil() + 1;
    final out = <TransitTrigger>[];
    for (final p in planets ?? aspectAngles.keys) {
      final lons = List<double>.generate(n, (k) => Ephemeris.siderealLongitude(p, fromJd + k * _step));
      double lonAt(double jd) => Ephemeris.siderealLongitude(p, jd);
      for (final t in targets) {
        if (t.code == 'NATAL_${p.toUpperCase()}') continue;
        for (final a in aspectAngles[p]!) {
          final point = VedicMath.norm360(t.longitude - a);
          double f(double jd) => PrecisionMath.norm180(lonAt(jd) - point);
          final fs = [for (final l in lons) PrecisionMath.norm180(l - point)];
          double? enter;
          double minOrb = 999;
          var exacts = <double>[];
          var passes = 0;
          void close(double exit) {
            out.add(TransitTrigger(p, t, a, enter!, exit, exacts, passes > 0, minOrb, c.utcOffset));
            passes++;
            enter = null;
            exacts = [];
            minOrb = 999;
          }

          for (int k = 0; k < n; k++) {
            final jd = fromJd + k * _step;
            final inside = fs[k].abs() <= orb;
            if (inside && enter == null) {
              enter = k == 0 ? jd : _bisect((x) => f(x).abs() - orb, jd - _step, jd);
            }
            if (enter != null) {
              if (fs[k].abs() < minOrb) minOrb = fs[k].abs();
              if (k > 0 && fs[k - 1].sign != fs[k].sign && fs[k - 1].abs() < 20 && fs[k].abs() < 20) {
                exacts.add(_bisect(f, jd - _step, jd));
                minOrb = 0;
              }
              if (!inside) close(_bisect((x) => f(x).abs() - orb, jd - _step, jd));
            }
          }
          if (enter != null) close(fromJd + (n - 1) * _step);
        }
      }
    }
    out.sort((a, b) => a.enterJd.compareTo(b.enterJd));
    return out;
  }

  /// Root of [f] in [a, b] where f(a) and f(b) differ in sign.
  static double _bisect(double Function(double) f, double a, double b) {
    var fa = f(a);
    for (int i = 0; i < 24; i++) {
      final m = (a + b) / 2;
      final fm = f(m);
      if ((fm < 0) == (fa < 0)) {
        a = m;
        fa = fm;
      } else {
        b = m;
      }
    }
    return (a + b) / 2;
  }

  /// Factors compared across nearby birth times.
  static Map<String, String> sensitivityFactors(ChartData c, {int scheme = 8}) {
    final l = c.planetLongitudes;
    String sign(int r) => L10n.sign(r);
    String varga(String key, int div) => sign(VedicMath.vargaRashi(c.ascendantSidereal, key, div));
    final dashas = DashaCalculations.compute(c.jd, l['moon']!, utcOffset: c.utcOffset);
    final first = dashas.mahadashas.first;
    final ak = JaiminiMath.karakas(c, scheme: scheme).first.planet;
    return {
      tr('Lagna sign', 'लग्न राशि'): sign(c.lagnaRashi),
      tr('Moon sign', 'चन्द्र राशि'): sign(VedicMath.rashiIndex(l['moon']!)),
      tr('Sun sign', 'सूर्य राशि'): sign(VedicMath.rashiIndex(l['sun']!)),
      tr('Moon nakshatra', 'चन्द्र नक्षत्र'): L10n.nakshatra(VedicMath.nakshatraIndex(l['moon']!)),
      tr('Planet houses', 'ग्रहों के भाव'): [for (final p in Ephemeris.planetOrder) VedicMath.houseOf(VedicMath.rashiIndex(l[p]!), c.lagnaRashi)].join(','),
      tr('D9 Lagna', 'D9 लग्न'): varga('D9', 9),
      tr('D10 Lagna', 'D10 लग्न'): varga('D10', 10),
      tr('D60 Lagna', 'D60 लग्न'): varga('D60', 60),
      tr('Daśā balance', 'दशा शेष'): '${L10n.planet(first.lord)} ${((first.endJD - c.jd) / DashaCalculations.yearDays).toStringAsFixed(1)} ${tr('y', 'व')}',
      tr('Mahādaśā boundaries', 'महादशा सीमाएँ'): [for (final m in dashas.mahadashas.skip(1).take(3)) m.startDate].join(', '),
      tr('Ātmakāraka', 'आत्मकारक'): L10n.planet(ak),
    };
  }

  /// Recomputes the chart at T-5, T-2, T, T+2 and T+5 minutes.
  static SensitivityResult sensitivity(ChartData Function(int offsetMinutes) chartAt,
      {List<int> offsets = const [-5, -2, 0, 2, 5], int scheme = 8}) {
    final values = <String, List<String>>{};
    for (final m in offsets) {
      sensitivityFactors(chartAt(m), scheme: scheme).forEach((k, v) => values.putIfAbsent(k, () => []).add(v));
    }
    return SensitivityResult(offsets, values);
  }

  // ---------------------------------------------------------------------------
  // Fingerprints (Volume 6 §63, §65)
  // ---------------------------------------------------------------------------

  static String sha256Of(Object json) => sha256.convert(utf8.encode(jsonEncode(json))).toString();

  /// Normalised birth input + calculation config + ephemeris version.
  static Map<String, dynamic> normalizedInput(ChartData c, CalcConfig cfg) => {
        'jd_ut': c.jd.toStringAsFixed(8),
        'latitude': c.lat.toStringAsFixed(6),
        'longitude': c.lon.toStringAsFixed(6),
        'utc_offset': c.utcOffset.toString(),
        'config': cfg.ruleVersions,
        'ephemeris': Ephemeris.ephemerisLabel,
      };

  static String inputsHash(ChartData c, CalcConfig cfg) => sha256Of(normalizedInput(c, cfg));

  /// Hash of the calculated positions (rounded to 1e-6°), for determinism checks.
  static String calculationHash(ChartData c) => sha256Of({
        'ascendant': c.ascendantSidereal.toStringAsFixed(6),
        'ayanamsa': c.ayanamsa.toStringAsFixed(6),
        for (final p in Ephemeris.planetOrder)
          if (c.planetLongitudes.containsKey(p)) p: c.planetLongitudes[p]!.toStringAsFixed(6),
      });
}
