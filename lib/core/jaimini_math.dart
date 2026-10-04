import 'ephemeris.dart';
import 'l10n.dart';
import 'vedic_math.dart';

/// A Jaimini Chara Karaka (variable significator).
class CharaKaraka {
  final String code;
  final String name;
  final String signifies;
  final String planet;

  /// Degrees used for the ranking (Rahu counted from the end of its sign).
  final double degree;
  const CharaKaraka(this.code, this.name, this.signifies, this.planet, this.degree);
}

/// Arudha Pada of a house.
class ArudhaPada {
  final int house;
  final String code;
  final String name;
  final int rashi;

  /// House of the Arudha counted from the Lagna.
  final int fromLagna;

  /// True when the 10th-from exception was applied.
  final bool exception;
  const ArudhaPada(this.house, this.code, this.name, this.rashi, this.fromLagna, this.exception);
}

class JaiminiResult {
  final int scheme;
  final List<CharaKaraka> karakas;
  final List<ArudhaPada> arudhas;

  /// Navamsa sign of the Atmakaraka.
  final int karakamsa;
  const JaiminiResult(this.scheme, this.karakas, this.arudhas, this.karakamsa);

  CharaKaraka? karaka(String code) {
    for (final k in karakas) {
      if (k.code == code) return k;
    }
    return null;
  }

  String? planetFor(String code) => karaka(code)?.planet;
  ArudhaPada get arudhaLagna => arudhas[0];
  ArudhaPada get upapada => arudhas[11];
}

/// Chara Karakas, Arudha Padas and Upapada (Jaimini Upadesa Sutras; BPHS).
///
/// The 7- and 8-karaka schemes differ by tradition, so the scheme is
/// configurable (CalcConfig.karakaScheme). Scorpio and Aquarius use their
/// primary lords (Mars and Saturn), which is a simplifying convention.
class JaiminiMath {
  static const List<(String, String, String, String, String)> _eight = [
    ('AK', 'Ātmakāraka', 'self, soul', 'आत्मकारक', 'स्वयं, आत्मा'),
    ('AmK', 'Amātyakāraka', 'career, counsel', 'अमात्यकारक', 'करियर, परामर्श'),
    ('BK', 'Bhrātṛkāraka', 'siblings, effort', 'भ्रातृकारक', 'भाई-बहन, प्रयास'),
    ('MK', 'Mātṛkāraka', 'mother, home', 'मातृकारक', 'माता, घर'),
    ('PiK', 'Pitṛkāraka', 'father', 'पितृकारक', 'पिता'),
    ('PK', 'Putrakāraka', 'children, creativity', 'पुत्रकारक', 'संतान, रचनात्मकता'),
    ('GK', 'Jñātikāraka', 'rivals, obstacles', 'ज्ञातिकारक', 'प्रतिद्वंद्वी, बाधाएँ'),
    ('DK', 'Dārakāraka', 'spouse, partnerships', 'दारकारक', 'जीवनसाथी, साझेदारी'),
  ];

  static const List<String> _padaNamesEn = [
    'Ārūḍha Lagna', 'Dhana Pada', 'Bhrātṛ Pada', 'Mātṛ Pada', 'Mantra Pada', 'Śatru Pada',
    'Dāra Pada', 'Roga Pada', 'Bhāgya Pada', 'Rājya Pada', 'Lābha Pada', 'Upapada',
  ];
  static const List<String> _padaNamesHi = [
    'आरूढ़ लग्न', 'धन पद', 'भ्रातृ पद', 'मातृ पद', 'मंत्र पद', 'शत्रु पद', 'दार पद', 'रोग पद', 'भाग्य पद', 'राज्य पद', 'लाभ पद', 'उपपद',
  ];

  static List<String> get padaNames => L10n.hi ? _padaNamesHi : _padaNamesEn;

  /// Chara Karakas ranked by degree within the sign, highest first.
  static List<CharaKaraka> karakas(ChartData c, {int scheme = 8}) {
    final names = scheme == 7 ? _eight.where((k) => k.$1 != 'PiK').toList() : _eight;
    final candidates = [
      for (final p in ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', if (scheme == 8) 'rahu'])
        if (c.planetLongitudes.containsKey(p))
          (p, p == 'rahu' ? 30 - VedicMath.degInRashi(c.planetLongitudes[p]!) : VedicMath.degInRashi(c.planetLongitudes[p]!)),
    ];
    candidates.sort((a, b) {
      final d = b.$2.compareTo(a.$2);
      return d != 0 ? d : Ephemeris.planetOrder.indexOf(a.$1).compareTo(Ephemeris.planetOrder.indexOf(b.$1));
    });
    return [
      for (int i = 0; i < candidates.length && i < names.length; i++)
        CharaKaraka(names[i].$1, L10n.hi ? names[i].$4 : names[i].$2, L10n.hi ? names[i].$5 : names[i].$3, candidates[i].$1, candidates[i].$2),
    ];
  }

  /// Arudha of [house]: count from the house to its lord, then the same count
  /// again from the lord. If that lands in the house or the 7th from it, the
  /// 10th from that sign is taken instead.
  static ArudhaPada arudha(ChartData c, int house) {
    final sign = (c.lagnaRashi + house - 1) % 12;
    final lord = VedicMath.rashis[sign].lord;
    final lordSign = VedicMath.rashiIndex(c.planetLongitudes[lord]!);
    final n = VedicMath.houseOf(lordSign, sign);
    var pada = (lordSign + n - 1) % 12;
    var exception = false;
    if (pada == sign || pada == (sign + 6) % 12) {
      pada = (pada + 9) % 12;
      exception = true;
    }
    return ArudhaPada(house, house == 1 ? 'AL' : (house == 12 ? 'UL' : 'A$house'), padaNames[house - 1], pada,
        VedicMath.houseOf(pada, c.lagnaRashi), exception);
  }

  static JaiminiResult compute(ChartData c, {int scheme = 8}) {
    final ks = karakas(c, scheme: scheme);
    final ak = ks.first.planet;
    return JaiminiResult(
      scheme,
      ks,
      [for (int h = 1; h <= 12; h++) arudha(c, h)],
      VedicMath.vargaRashi(c.planetLongitudes[ak]!, 'D9', 9),
    );
  }
}
