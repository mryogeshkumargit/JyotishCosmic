import 'vedic_math.dart';

/// App language (English or Hindi). Strings are written in both languages
/// beside each other with [tr], so a translation can never drift away from the
/// English text it belongs to.
class L10n {
  /// 'en' or 'hi'. Set from Settings at app start and on change.
  static String lang = 'en';

  static bool get hi => lang == 'hi';

  static const Map<String, String> languages = {'en': 'English', 'hi': 'हिन्दी'};

  static const List<String> _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const List<String> _monthsHi = ['जन॰', 'फ़र॰', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अग॰', 'सित॰', 'अक्टू॰', 'नव॰', 'दिस॰'];

  static String month(int m) => (hi ? _monthsHi : _monthsEn)[m - 1];

  static const List<String> _weekdaysHi = ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
  static const List<String> _weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// [weekday] as in DateTime.weekday (1 = Monday).
  static String weekday(int weekday) => (hi ? _weekdaysHi : _weekdaysEn)[weekday - 1];

  // ---------------------------------------------------------------------------
  // Astrological names
  // ---------------------------------------------------------------------------

  static String planet(String p) {
    final d = VedicMath.planets[p];
    if (d == null) return p;
    return hi ? d.hindi : d.name;
  }

  /// Short chart abbreviation (Su, Mo... / सू, च...).
  static String planetAbbr(String p) => hi ? (_abbrHi[p] ?? p) : (_abbrEn[p] ?? p);
  static const Map<String, String> _abbrEn = {
    'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me', 'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa', 'rahu': 'Ra', 'ketu': 'Ke',
  };
  static const Map<String, String> _abbrHi = {
    'sun': 'सू', 'moon': 'चं', 'mars': 'मं', 'mercury': 'बु', 'jupiter': 'गु', 'venus': 'शु', 'saturn': 'श', 'rahu': 'रा', 'ketu': 'के',
  };

  static String sign(int r) => hi ? VedicMath.rashis[r].hindi : VedicMath.rashis[r].name;

  /// Short sign name for tables: "Ari" / "मेष".
  static String signShort(int r, [int len = 3]) => hi ? VedicMath.rashis[r].hindi : VedicMath.rashis[r].name.substring(0, len);

  static String nakshatra(int i) => hi ? VedicMath.nakshatras[i].hindi : VedicMath.nakshatras[i].name;

  /// "10th" / "10वाँ".
  static String ordinal(int n) => hi ? '$nवाँ' : VedicMath.ordinal(n);

  /// "10th house" / "10वाँ भाव".
  static String house(int n) => hi ? '$nवाँ भाव' : '${VedicMath.ordinal(n)} house';

  /// "in the 10th house" / "10वें भाव में".
  static String inHouse(int n) => hi ? '$nवें भाव में' : 'in the ${VedicMath.ordinal(n)} house';

  /// "of the 10th house" / "10वें भाव का".
  static String ofHouse(int n) => hi ? '$nवें भाव का' : 'of the ${VedicMath.ordinal(n)} house';

  static String element(String e) => hi ? (const {'Fire': 'अग्नि', 'Earth': 'पृथ्वी', 'Air': 'वायु', 'Water': 'जल'}[e] ?? e) : e;

  static String dignity(String d) {
    if (!hi) return d;
    const m = {
      'Exalted': 'उच्च',
      'Debilitated': 'नीच',
      'Moolatrikona': 'मूलत्रिकोण',
      'Own Sign': 'स्वराशि',
      'Great Friend': 'अधिमित्र राशि',
      'Friend': 'मित्र राशि',
      'Neutral': 'सम राशि',
      'Enemy': 'शत्रु राशि',
      'Great Enemy': 'अधिशत्रु राशि',
    };
    for (final e in m.entries) {
      if (d == e.key) return e.value;
    }
    for (final e in m.entries) {
      if (d.contains(e.key)) return e.value;
    }
    return d;
  }

  /// Joins items: "a, b and c" / "a, b और c".
  static String join(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} ${hi ? 'और' : 'and'} ${items.last}';
  }
}

/// Picks the English or Hindi text for the current language.
String tr(String en, String hi) => L10n.hi ? hi : en;
