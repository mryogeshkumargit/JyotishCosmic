import 'dart:math' as math;

import 'calc_config.dart';
import 'ephemeris.dart';
import 'planetary_dignity.dart';
import 'precision_math.dart';
import 'vedic_math.dart';
import 'yogas_math.dart';

/// One component of a planet's strength, in virupas (1 rupa = 60 virupas).
class BalaComponent {
  final String name;
  final double value;
  final String rule;
  const BalaComponent(this.name, this.value, this.rule);
}

/// Shadbala of one planet (Volume 4 §12-13; BPHS strength chapter; Phaladeepika ch. 4).
class Shadbala {
  final String planet;
  final List<BalaComponent> sthana;
  final List<BalaComponent> kala;
  final double dig;
  final double cheshta;
  final double naisargika;
  final double drik;
  final double ishtaPhala;
  final double kashtaPhala;

  const Shadbala({
    required this.planet,
    required this.sthana,
    required this.kala,
    required this.dig,
    required this.cheshta,
    required this.naisargika,
    required this.drik,
    required this.ishtaPhala,
    required this.kashtaPhala,
  });

  double get sthanaBala => sthana.fold(0, (s, c) => s + c.value);
  double get kalaBala => kala.fold(0, (s, c) => s + c.value);
  double get total => sthanaBala + dig + kalaBala + cheshta + naisargika + drik;
  double get rupas => total / 60;
  double get minimumVirupas => ShadbalaMath.minimumVirupas[planet]!;
  double get ratio => total / minimumVirupas;
  bool get meetsMinimum => total >= minimumVirupas;
  String get name => VedicMath.planets[planet]!.name;

  /// The six components, in order.
  Map<String, double> get six => {
        'Sthana': sthanaBala,
        'Dig': dig,
        'Kala': kalaBala,
        'Cheshta': cheshta,
        'Naisargika': naisargika,
        'Drik': drik,
      };

  double component(String name) => [...sthana, ...kala].firstWhere((c) => c.name == name).value;
}

/// Strength of a house (Volume 4 §14).
class BhavaBala {
  final int house;
  final double madhya;
  final String lord;
  final double adhipati;
  final double dig;
  final double drishti;
  final double occupation;
  const BhavaBala(this.house, this.madhya, this.lord, this.adhipati, this.dig, this.drishti, this.occupation);
  double get total => adhipati + dig + drishti + occupation;
  double get rupas => total / 60;
}

class ShadbalaResult {
  final Map<String, Shadbala> planets;
  final List<BhavaBala> bhavas;
  final bool dayBirth;
  final List<String> notes;
  const ShadbalaResult(this.planets, this.bhavas, this.dayBirth, this.notes);

  /// Planets ordered from strongest to weakest relative to their minimum.
  List<Shadbala> get ranked => planets.values.toList()..sort((a, b) => b.ratio.compareTo(a.ratio));
}

/// Shadbala (six-fold strength) and Bhava Bala.
///
/// The formulas follow BPHS as presented in B. V. Raman, *Graha and Bhava
/// Balas*. Conventions that are not universal are labelled in [notes]:
/// Cheshta Bala uses true heliocentric/geocentric positions in place of the
/// classical mean planets, and the Abda/Masa lords are counted from the
/// Kali Yuga epoch in civil days.
class ShadbalaMath {
  static const List<String> planets = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];

  static const Map<String, double> minimumVirupas = {
    'sun': 390, 'moon': 360, 'mars': 300, 'mercury': 420, 'jupiter': 390, 'venus': 330, 'saturn': 300,
  };

  static const Map<String, double> naisargikaBala = {
    'sun': 60, 'moon': 51.43, 'venus': 42.86, 'jupiter': 34.29, 'mercury': 25.71, 'mars': 17.14, 'saturn': 8.57,
  };

  /// Weekday lords, Sunday first.
  static const List<String> weekdayLords = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];

  /// Chaldean order used for planetary hours.
  static const List<String> horaOrder = ['saturn', 'jupiter', 'mars', 'sun', 'venus', 'mercury', 'moon'];

  static const List<String> _saptavarga = ['D1', 'D2', 'D3', 'D7', 'D9', 'D12', 'D30'];
  static const Map<String, int> _divisions = {'D1': 1, 'D2': 2, 'D3': 3, 'D7': 7, 'D9': 9, 'D12': 12, 'D30': 30};

  /// Kali Yuga epoch (civil day number of 18 Feb 3102 BCE, a Friday).
  static const int kaliEpochDay = 588466;

  static double _arc(double a, double b) => PrecisionMath.separation(a, b);

  static double _circularMean(double a, double b) => VedicMath.norm360(a + PrecisionMath.norm180(b - a) / 2);

  static bool _benefic(ChartData c, String p) {
    final l = c.planetLongitudes;
    switch (p) {
      case 'jupiter':
      case 'venus':
        return true;
      case 'moon':
        return VedicMath.norm360(l['moon']! - l['sun']!) < 180;
      case 'mercury':
        final r = VedicMath.rashiIndex(l['mercury']!);
        return !['sun', 'mars', 'saturn', 'rahu', 'ketu'].any((m) => l[m] != null && VedicMath.rashiIndex(l[m]!) == r);
      default:
        return false;
    }
  }

  static ShadbalaResult compute(ChartData c, {CalcConfig cfg = CalcConfig.defaults}) {
    final l = c.planetLongitudes;
    final rashis = {for (final e in l.entries) e.key: VedicMath.rashiIndex(e.value)};
    final asc = c.ascendantSidereal;
    final mc = c.midheaven ?? VedicMath.norm360(asc + 270);
    final notes = <String>[];

    // Sunrise/sunset around birth.
    double? sunriseBefore = Ephemeris.nextSunrise(c.jd - 1, c.lat, c.lon);
    if (sunriseBefore != null && sunriseBefore > c.jd) sunriseBefore = Ephemeris.nextSunrise(c.jd - 2, c.lat, c.lon);
    final sunsetAfterSunrise = sunriseBefore == null ? null : Ephemeris.nextSunset(sunriseBefore, c.lat, c.lon);
    final nextSunrise = Ephemeris.nextSunrise(c.jd, c.lat, c.lon);
    final bool dayBirth = sunsetAfterSunrise != null ? c.jd < sunsetAfterSunrise : VedicMath.norm360(asc - l['sun']!) < 180;
    if (sunriseBefore == null) notes.add('Sunrise not defined at this latitude on the birth date; day/night taken from the Sun\'s position.');

    // Nearest apparent noon.
    final t1 = Ephemeris.nextSunTransit(c.jd - 1, c.lat, c.lon);
    final t2 = t1 == null ? null : Ephemeris.nextSunTransit(t1 + 0.1, c.lat, c.lon);
    double hoursFromNoon;
    if (t1 != null && t2 != null) {
      final d = math.min((c.jd - t1).abs(), (c.jd - t2).abs());
      hoursFromNoon = (d * 24).clamp(0, 12).toDouble();
    } else {
      hoursFromNoon = (_arc(l['sun']!, mc) / 15).clamp(0, 12).toDouble();
    }

    final elong = VedicMath.norm360(l['moon']! - l['sun']!);
    final pakshaBase = (elong <= 180 ? elong : 360 - elong) / 3;

    // Vara, Hora, Abda, Masa lords.
    final dayStart = sunriseBefore ?? (c.jd - 0.25);
    final civilDay = (dayStart + c.utcOffset / 24 + 0.5).floor();
    final varaLord = weekdayLords[(civilDay + 1) % 7];
    final horaIndex = ((c.jd - dayStart) * 24).floor().clamp(0, 23);
    final horaLord = horaOrder[(horaOrder.indexOf(varaLord) + horaIndex) % 7];
    final days = civilDay - kaliEpochDay;
    final abdaLord = weekdayLords[(kaliEpochDay + 360 * (days ~/ 360) + 1) % 7];
    final masaLord = weekdayLords[(kaliEpochDay + 30 * (days ~/ 30) + 1) % 7];

    // Tribhaga lords.
    String tribhagaLord;
    if (dayBirth && sunriseBefore != null && sunsetAfterSunrise != null) {
      final part = ((c.jd - sunriseBefore) / ((sunsetAfterSunrise - sunriseBefore) / 3)).floor().clamp(0, 2);
      tribhagaLord = const ['mercury', 'sun', 'saturn'][part];
    } else {
      final sunset = sunsetAfterSunrise != null && sunsetAfterSunrise <= c.jd ? sunsetAfterSunrise : Ephemeris.nextSunset(c.jd - 1, c.lat, c.lon);
      final rise = nextSunrise;
      if (sunset != null && rise != null && rise > sunset) {
        final part = ((c.jd - sunset) / ((rise - sunset) / 3)).floor().clamp(0, 2);
        tribhagaLord = const ['moon', 'venus', 'mars'][part];
      } else {
        tribhagaLord = 'moon';
      }
    }

    // Preliminary values needed before the war adjustment.
    final result = <String, Shadbala>{};
    final preWar = <String, double>{};
    for (final p in planets) {
      final lon = l[p]!;
      final r = rashis[p]!;
      final deg = VedicMath.degInRashi(lon);

      // --- Sthana Bala ---
      final deb = VedicMath.norm360(PlanetaryDignity.deepExaltation[p]! + 180);
      final uchcha = _arc(lon, deb) / 3;
      double sapta = 0;
      for (final v in _saptavarga) {
        final s = VedicMath.vargaRashi(lon, v, _divisions[v]!);
        final lordOfSign = VedicMath.rashis[s].lord;
        double pts;
        final range = PlanetaryDignity.moolatrikonaRanges[p];
        if (v == 'D1' && PlanetaryDignity.moolatrikonaSigns[p] == s && range != null && deg >= range.$1 && deg < range.$2) {
          pts = 45;
        } else if (lordOfSign == p) {
          pts = 30;
        } else {
          pts = switch (PlanetaryDignity.getCompoundRelationship(p, r, lordOfSign, rashis[lordOfSign]!)) {
            Relationship.greatFriend => 20,
            Relationship.friend => 15,
            Relationship.neutral => 10,
            Relationship.enemy => 4,
            Relationship.greatEnemy => 2,
          };
        }
        sapta += pts;
      }
      final nav = VedicMath.vargaRashi(lon, 'D9', 9);
      final feminine = p == 'moon' || p == 'venus';
      bool wanted(int sign) => feminine ? sign % 2 == 1 : sign % 2 == 0;
      final double oja = (wanted(r) ? 15.0 : 0.0) + (wanted(nav) ? 15.0 : 0.0);
      final house = VedicMath.houseOf(r, c.lagnaRashi);
      final kendradi = YogasMath.isKendra(house) ? 60.0 : (const [2, 5, 8, 11].contains(house) ? 30.0 : 15.0);
      final drekkana = (deg / 10).floor();
      final drekWanted = switch (p) { 'sun' || 'mars' || 'jupiter' => 0, 'mercury' || 'saturn' => 1, _ => 2 };
      final drekBala = drekkana == drekWanted ? 15.0 : 0.0;

      // --- Dig Bala ---
      final powerless = switch (p) {
        'sun' || 'mars' => VedicMath.norm360(mc + 180),
        'jupiter' || 'mercury' => VedicMath.norm360(asc + 180),
        'moon' || 'venus' => mc,
        _ => asc,
      };
      final dig = _arc(lon, powerless) / 3;

      // --- Kala Bala ---
      final night = hoursFromNoon / 12 * 60;
      final nathonnata = p == 'mercury' ? 60.0 : (['sun', 'jupiter', 'venus'].contains(p) ? 60 - night : night);
      double paksha = _benefic(c, p) ? pakshaBase : 60 - pakshaBase;
      if (p == 'moon') paksha = pakshaBase * 2;
      final tribhaga = (p == 'jupiter' || p == tribhagaLord) ? 60.0 : 0.0;
      final abda = p == abdaLord ? 15.0 : 0.0;
      final masa = p == masaLord ? 30.0 : 0.0;
      final vara = p == varaLord ? 45.0 : 0.0;
      final hora = p == horaLord ? 60.0 : 0.0;
      final decl = c.declinations[p] ?? _declinationFromLongitude(lon + c.ayanamsa);
      double ayana = switch (p) {
        'moon' || 'saturn' => (24 - decl) * 60 / 48,
        'mercury' => (24 + decl.abs()) * 60 / 48,
        _ => (24 + decl) * 60 / 48,
      };
      ayana = ayana.clamp(0, 60).toDouble();
      final ayanaKala = p == 'sun' ? ayana * 2 : ayana;

      // --- Cheshta Bala ---
      double cheshta;
      if (p == 'sun') {
        cheshta = ayana;
      } else if (p == 'moon') {
        cheshta = pakshaBase;
      } else {
        final helio = c.heliocentricLongitudes[p];
        final sun = l['sun']!;
        if (helio == null) {
          cheshta = (c.planetSpeeds[p] ?? 0) < 0 ? 60 : 15;
        } else if (p == 'mercury' || p == 'venus') {
          cheshta = _arc(helio, _circularMean(sun, lon)) / 3;
        } else {
          cheshta = _arc(sun, _circularMean(helio, lon)) / 3;
        }
      }

      // --- Drik Bala ---
      double drik = 0;
      for (final q in planets) {
        if (q == p) continue;
        final v = PrecisionMath.sputaDrishti(q, lon - l[q]!);
        drik += _benefic(c, q) ? v : -v;
      }
      drik /= 4;

      final sthana = [
        BalaComponent('Uchcha', uchcha, 'Arc from the debilitation point ÷ 3'),
        BalaComponent('Saptavargaja', sapta, 'D1, D2, D3, D7, D9, D12, D30: Moolatrikona 45, own 30, great friend 20, friend 15, neutral 10, enemy 4, great enemy 2'),
        BalaComponent('Ojayugma', oja, feminine ? 'Moon/Venus: 15 each for an even sign in D1 and D9' : '15 each for an odd sign in D1 and D9'),
        BalaComponent('Kendradi', kendradi, 'Kendra 60, Panaphara 30, Apoklima 15'),
        BalaComponent('Drekkana', drekBala, 'Male planets 1st, neutral 2nd, female 3rd drekkana: 15'),
      ];
      final kala = [
        BalaComponent('Nathonnata', nathonnata, p == 'mercury' ? 'Mercury always 60' : 'Day/night strength from the distance to apparent noon'),
        BalaComponent('Paksha', paksha, p == 'moon' ? 'Moon: elongation from the Sun ÷ 3, doubled' : 'Benefics: elongation ÷ 3; malefics: 60 minus that'),
        BalaComponent('Tribhaga', tribhaga, 'Lord of the third of the day/night (Jupiter always 60)'),
        BalaComponent('Abda', abda, 'Lord of the year (15)'),
        BalaComponent('Masa', masa, 'Lord of the month (30)'),
        BalaComponent('Vara', vara, 'Lord of the weekday (45)'),
        BalaComponent('Hora', hora, 'Lord of the planetary hour (60)'),
        BalaComponent('Ayana', ayanaKala, p == 'sun' ? 'From declination; doubled for the Sun' : 'From declination (kranti)'),
      ];
      final ishta = math.sqrt(uchcha * cheshta.clamp(0, 60));
      final kashta = math.sqrt((60 - uchcha) * (60 - cheshta.clamp(0, 60)));
      final sb = Shadbala(
        planet: p,
        sthana: sthana,
        kala: kala,
        dig: dig,
        cheshta: cheshta,
        naisargika: naisargikaBala[p]!,
        drik: drik,
        ishtaPhala: ishta,
        kashtaPhala: kashta,
      );
      result[p] = sb;
      preWar[p] = sb.total;
    }

    // Yuddha Bala: the difference of the totals moves from the loser to the winner.
    for (final w in PrecisionMath.wars(c, cfg)) {
      final winner = w.winner;
      if (winner == null) continue;
      final loser = w.loser!;
      final diff = (preWar[winner]! - preWar[loser]!).abs();
      for (final (p, sign) in [(winner, 1.0), (loser, -1.0)]) {
        final s = result[p]!;
        result[p] = Shadbala(
          planet: p,
          sthana: s.sthana,
          kala: [...s.kala, BalaComponent('Yuddha', sign * diff, 'Planetary war with ${VedicMath.planets[p == winner ? loser : winner]!.name}')],
          dig: s.dig,
          cheshta: s.cheshta,
          naisargika: s.naisargika,
          drik: s.drik,
          ishtaPhala: s.ishtaPhala,
          kashtaPhala: s.kashtaPhala,
        );
      }
      notes.add('Planetary war: ${VedicMath.planets[winner]!.name} defeats ${VedicMath.planets[loser]!.name} (${cfg.warRuleLabel}).');
    }

    notes.addAll([
      'Cheshta Bala uses true heliocentric and geocentric positions in place of the classical mean planets.',
      'Abda and Masa lords are counted in civil days from the Kali Yuga epoch (a Friday).',
      'Vara $varaLord, Hora $horaLord, Abda $abdaLord, Masa $masaLord, ${dayBirth ? 'day' : 'night'} birth.',
    ]);

    // --- Bhava Bala ---
    final bhavas = <BhavaBala>[];
    for (int h = 1; h <= 12; h++) {
      final madhya = VedicMath.norm360(asc + 30 * (h - 1));
      final sign = VedicMath.rashiIndex(madhya);
      final lord = VedicMath.rashis[(c.lagnaRashi + h - 1) % 12].lord;
      final adhipati = result[lord]?.total ?? 0;
      final degIn = VedicMath.degInRashi(madhya);
      // Strongest point by sign type: human -> 1st, quadruped -> 10th, watery -> 4th, insect -> 7th.
      final int strongHouse;
      if ([2, 5, 6, 10].contains(sign) || (sign == 8 && degIn < 15)) {
        strongHouse = 1;
      } else if ([0, 1, 4].contains(sign) || (sign == 8 && degIn >= 15) || (sign == 9 && degIn < 15)) {
        strongHouse = 10;
      } else if (sign == 7) {
        strongHouse = 7;
      } else {
        strongHouse = 4;
      }
      final distance = (h - strongHouse).abs();
      final dig = (6 - math.min(distance, 12 - distance)) * 10.0;
      double drishti = 0;
      for (final q in planets) {
        final v = PrecisionMath.sputaDrishti(q, madhya - l[q]!);
        final signed = _benefic(c, q) ? v : -v;
        drishti += (q == 'jupiter' || q == 'mercury') ? signed : signed / 4;
      }
      double occupation = 0;
      for (final q in planets) {
        if (VedicMath.houseOf(rashis[q]!, c.lagnaRashi) != h) continue;
        if (q == 'jupiter' || q == 'mercury') occupation += 60;
        if (q == 'saturn' || q == 'mars' || q == 'sun') occupation -= 60;
      }
      bhavas.add(BhavaBala(h, madhya, lord, adhipati, dig, drishti, occupation));
    }
    return ShadbalaResult(result, bhavas, dayBirth, notes);
  }

  static double _declinationFromLongitude(double tropicalLongitude) {
    const eps = 23.44 * math.pi / 180;
    return math.asin(math.sin(eps) * math.sin(tropicalLongitude * math.pi / 180)) * 180 / math.pi;
  }
}
