import '../../services/location_service.dart';
import '../ashtakavarga_math.dart';
import '../chart_summary.dart';
import '../doshas_math.dart';
import '../ephemeris.dart';
import '../l10n.dart';
import '../panchang_math.dart';
import '../planetary_dignity.dart';
import '../shadbala_math.dart';
import '../transit_math.dart';
import '../vedic_math.dart';
import '../yogas_math.dart';
import 'rashifal_models.dart';
import 'rashifal_tables.dart';

/// Place used for the day's Panchang, sunrise and muhurats.
class RashifalPlace {
  final String name;
  final double lat;
  final double lon;

  /// IANA zone; when null [fallbackOffset] is used.
  final String? tzName;
  final double fallbackOffset;

  const RashifalPlace({required this.name, required this.lat, required this.lon, this.tzName, this.fallbackOffset = 5.5});

  /// UTC offset (hours) on [date], including daylight saving time.
  double offsetOn(DateTime date) => LocationService.utcOffsetFor(tzName, DateTime(date.year, date.month, date.day, 12)) ?? fallbackOffset;
}

/// Natal factors that do not change from day to day, computed once per Kundali.
class RashifalNatal {
  final int profileId;
  final String name;
  final String? gender;
  final ChartData chart;
  final AshtakavargaResult av;
  final ShadbalaResult? shadbala;
  final DashaCalculations dashas;
  final List<DoshaResult> doshas;
  final Set<String> vargottama;
  final Map<String, int> d9;
  final Map<String, int> d10;

  RashifalNatal._(this.profileId, this.name, this.gender, this.chart, this.av, this.shadbala, this.dashas, this.doshas, this.vargottama, this.d9, this.d10);

  factory RashifalNatal.fromChart(ChartData chart, {required int profileId, required String name, String? gender}) {
    final moon = chart.planetLongitudes['moon']!;
    ShadbalaResult? sb;
    try {
      sb = ShadbalaMath.compute(chart);
    } catch (_) {}
    final longs = chart.planetLongitudes;
    final doshas = <DoshaResult>[
      ?DoshasMath.computeManglik(longs, chart.lagnaRashi),
      ?DoshasMath.computeKaalSarp(longs, chart.lagnaRashi),
      DoshasMath.computePitruDosha(longs, chart.lagnaRashi),
      DoshasMath.computeGrahanDosha(longs),
      DoshasMath.computeGuruChandalDosha(longs),
      DoshasMath.computeKemadrumaDosha(longs),
    ].where((d) => d.present).toList();
    final d9 = {for (final e in longs.entries) e.key: VedicMath.vargaRashi(e.value, 'D9', 9)};
    final d10 = {for (final e in longs.entries) e.key: VedicMath.vargaRashi(e.value, 'D10', 10)};
    return RashifalNatal._(
      profileId,
      name,
      gender,
      chart,
      AshtakavargaMath.compute(chart),
      sb,
      DashaCalculations.compute(chart.jd, moon, utcOffset: chart.utcOffset),
      doshas,
      {
        for (final e in longs.entries)
          if (d9[e.key] == VedicMath.rashiIndex(e.value)) e.key,
      },
      d9,
      d10,
    );
  }

  int get lagna => chart.lagnaRashi;
  double get moonLon => chart.planetLongitudes['moon']!;
  int get moonRashi => VedicMath.rashiIndex(moonLon);
  int get birthNakshatra => VedicMath.nakshatraIndex(moonLon);
  int rashiOf(String p) => VedicMath.rashiIndex(chart.planetLongitudes[p]!);
  int houseOf(String p) => VedicMath.houseOf(rashiOf(p), lagna);

  /// Houses (from the Lagna) ruled by [planet].
  List<int> housesRuledBy(String planet) => [
    for (int h = 1; h <= 12; h++)
      if (VedicMath.rashis[(lagna + h - 1) % 12].lord == planet) h,
  ];

  String? _summary;

  /// Full natal description for the AI prompt (computed on first use).
  String get summary => _summary ??= ChartSummary.describe(chart, name: name);
}

class _F {
  final int w;
  final String text;
  const _F(this.w, this.text);
}

/// Output of [RashifalEngine.compute]: the localized report and the English
/// data sheet the AI interprets.
class RashifalComputation {
  final DailyRashifalReport report;
  final String aiContext;
  const RashifalComputation(this.report, this.aiContext);
}

/// Computes the daily Rashifal of a Kundali on the device.
///
/// Every factor is calculated with the Swiss Ephemeris for the chosen date
/// and place: Panchang at sunrise (Udaya tithi), Moon's Chandra Bala and
/// Tara Bala, Gochar of the nine grahas from the Moon and the Lagna with
/// their Ashtakavarga bindus, transit aspects and conjunctions on natal
/// points, the running Vimshottari Maha/Antar/Pratyantar Dasha, Sade Sati,
/// natal yogas, doshas and divisional charts. The factors are weighted into
/// a 0-100 score per day and per life area; the weights are a transparent
/// heuristic (each factor is listed with its sign), not a classical rule.
class RashifalEngine {
  static const List<String> _grahas = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn', 'rahu', 'ketu'];
  static const List<int> _chandraGood = [1, 3, 6, 7, 10, 11];
  static const Set<int> _upachaya = {3, 6, 10, 11};

  static const Map<String, (List<int>, List<String>, Bi)> areaDefs = {
    'family': ([2, 4], ['moon', 'jupiter'], ('Family Life', 'पारिवारिक जीवन')),
    'marriage': ([7], ['venus'], ('Married Life & Relationships', 'वैवाहिक जीवन और संबंध')),
    'health': ([1, 6, 8], ['sun', 'moon'], ('Health & Well-being', 'स्वास्थ्य और कल्याण')),
    'career': ([10, 6], ['saturn', 'sun', 'mercury'], ('Work Life (Career & Profession)', 'कार्य जीवन (करियर और व्यवसाय)')),
    'mind': ([4, 5], ['moon', 'mercury'], ('Mental Peace', 'मानसिक शांति')),
    'finance': ([2, 11], ['jupiter', 'venus'], ('Financial Matters', 'आर्थिक मामले')),
    'social': ([11, 3], ['mercury', 'venus'], ('Social Relations', 'सामाजिक संबंध')),
  };

  static const Map<String, List<Bi>> _areaAdvice = {
    'overall': [
      ('Use the day for important work and new beginnings, preferably in the auspicious windows below.', 'महत्वपूर्ण कार्यों और नई शुरुआत के लिए दिन का उपयोग करें, अच्छा हो कि नीचे दिए शुभ समय में।'),
      ('A mixed day: continue ongoing work and keep important starts for the auspicious windows.', 'मिश्रित दिन: चल रहे काम जारी रखें और महत्वपूर्ण शुरुआत शुभ समय में करें।'),
      (
        'A day for patience: avoid big decisions and new ventures, finish routine work and follow the remedy of the day.',
        'धैर्य का दिन: बड़े निर्णय और नए उद्यम टालें, नियमित काम पूरे करें और आज का उपाय करें।',
      ),
    ],
    'family': [
      ('A warm day at home: share a meal, settle family plans and reach out to elders.', 'घर में स्नेहपूर्ण दिन: साथ भोजन करें, पारिवारिक योजनाएँ तय करें और बड़ों से संपर्क करें।'),
      ('Family life stays steady; listen more than you speak and keep small promises.', 'पारिवारिक जीवन स्थिर रहेगा; बोलने से अधिक सुनें और छोटे वादे निभाएँ।'),
      (
        'A sensitive day at home: avoid old arguments and money talk with relatives, and be patient with elders.',
        'घर में संवेदनशील दिन: पुराने विवाद और रिश्तेदारों से पैसों की बात टालें, और बड़ों के साथ धैर्य रखें।',
      ),
    ],
    'marriage': [
      ('Harmony with your partner is favoured; a good day for quality time, romance or relationship talks.', 'जीवनसाथी से सामंजस्य के योग; साथ समय बिताने, प्रेम या रिश्ते की बात के लिए अच्छा दिन।'),
      ('Relationships are balanced; small misunderstandings clear quickly if you stay gentle.', 'संबंध संतुलित रहेंगे; नरमी रखें तो छोटी गलतफ़हमियाँ जल्दी दूर होंगी।'),
      (
        'Ego clashes or moodiness can strain the relationship; avoid blame and big relationship decisions today.',
        'अहं का टकराव या मनोदशा रिश्ते में खिंचाव ला सकती है; दोषारोपण और आज रिश्ते के बड़े निर्णय से बचें।',
      ),
    ],
    'health': [
      ('Good vitality and recovery; a fine day to start exercise or a healthy routine.', 'अच्छी ऊर्जा और स्वास्थ्य लाभ; व्यायाम या स्वस्थ दिनचर्या शुरू करने के लिए अच्छा दिन।'),
      ('Health is ordinary; keep meals regular, stay hydrated and get enough sleep.', 'स्वास्थ्य सामान्य; भोजन नियमित रखें, पानी पिएँ और पूरी नींद लें।'),
      (
        'Energy may dip; avoid overexertion, risky activities and careless driving, and look after digestion and rest.',
        'ऊर्जा कम रह सकती है; अधिक परिश्रम, जोखिम भरे काम और लापरवाह ड्राइविंग से बचें, पाचन और आराम का ध्यान रखें।',
      ),
    ],
    'career': [
      (
        'Work moves forward: present ideas, meet seniors and take on responsibility — your efforts get noticed.',
        'काम आगे बढ़ेगा: विचार रखें, वरिष्ठों से मिलें और ज़िम्मेदारी लें — आपकी मेहनत पर ध्यान जाएगा।',
      ),
      ('A routine work day; steady effort pays, but do not expect quick results.', 'सामान्य कार्य दिवस; लगातार प्रयास फल देगा, पर जल्दी परिणाम की आशा न रखें।'),
      (
        'Delays or friction at work are possible; double-check details, avoid confrontations with seniors and postpone big moves.',
        'काम में देरी या टकराव संभव; विवरण दोबारा जाँचें, वरिष्ठों से टकराव टालें और बड़े कदम स्थगित करें।',
      ),
    ],
    'mind': [
      ('A clear, calm and optimistic mind; good for planning, study and meditation.', 'स्पष्ट, शांत और आशावादी मन; योजना, अध्ययन और ध्यान के लिए अच्छा।'),
      ('Mood is changeable but manageable; short breaks and breathing exercises help.', 'मन बदलता रहेगा पर नियंत्रण में; छोटे विराम और प्राणायाम मदद करेंगे।'),
      (
        'Worry or restlessness may rise; avoid overthinking, limit screen time and keep quiet time for prayer or meditation.',
        'चिंता या बेचैनी बढ़ सकती है; अधिक सोचने से बचें, स्क्रीन कम देखें और प्रार्थना या ध्यान के लिए शांत समय रखें।',
      ),
    ],
    'finance': [
      ('Favourable for income, collections and planned investments; money matters move in your favour.', 'आय, वसूली और योजनाबद्ध निवेश के लिए अनुकूल; धन संबंधी मामले आपके पक्ष में।'),
      ('Finances are stable; stick to the budget and avoid impulse purchases.', 'आर्थिक स्थिति स्थिर; बजट पर टिके रहें और आवेग में खरीदारी से बचें।'),
      (
        'Unplanned expenses or losses are possible; avoid lending, speculation and signing financial papers in a hurry.',
        'अनियोजित खर्च या हानि संभव; उधार, सट्टा और जल्दबाज़ी में वित्तीय कागज़ों पर हस्ताक्षर से बचें।',
      ),
    ],
    'social': [
      ('Good for networking, meetings and help from friends; your words carry weight.', 'संपर्क बढ़ाने, बैठकों और मित्रों की मदद के लिए अच्छा; आपकी बात का प्रभाव रहेगा।'),
      ('Social life is ordinary; keep commitments and avoid gossip.', 'सामाजिक जीवन सामान्य; वादे निभाएँ और चुगली से बचें।'),
      ('Misunderstandings with friends or colleagues can arise; think before you speak or post online.', 'मित्रों या सहकर्मियों से गलतफ़हमी हो सकती है; बोलने या ऑनलाइन लिखने से पहले सोचें।'),
    ],
  };

  static const List<Bi> _houseMeaning = [
    ('self, body and personality', 'स्वयं, शरीर और व्यक्तित्व'),
    ('wealth, family and speech', 'धन, परिवार और वाणी'),
    ('courage, siblings, efforts and short trips', 'साहस, भाई-बहन, प्रयास और छोटी यात्राएँ'),
    ('home, mother, comforts and peace of mind', 'घर, माता, सुख और मन की शांति'),
    ('intelligence, children, romance and creativity', 'बुद्धि, संतान, प्रेम और रचनात्मकता'),
    ('health issues, debts, competition and service', 'रोग, ऋण, प्रतिस्पर्धा और सेवा'),
    ('partner, marriage and partnerships', 'जीवनसाथी, विवाह और साझेदारी'),
    ('sudden events, obstacles and hidden matters', 'अचानक घटनाएँ, बाधाएँ और गुप्त विषय'),
    ('luck, father, dharma and long journeys', 'भाग्य, पिता, धर्म और लंबी यात्राएँ'),
    ('career, status and actions', 'करियर, प्रतिष्ठा और कर्म'),
    ('gains, friends and fulfilled wishes', 'लाभ, मित्र और इच्छापूर्ति'),
    ('expenses, rest, foreign lands and spirituality', 'खर्च, विश्राम, विदेश और आध्यात्मिकता'),
  ];

  static const Map<String, Bi> _elementMood = {
    'Fire': ('enthusiasm, quick action and courage; watch impatience', 'उत्साह, त्वरित कार्य और साहस; अधीरता से बचें'),
    'Earth': ('practical tasks, money and steady routines; watch stubbornness', 'व्यावहारिक कार्य, धन और स्थिर दिनचर्या; हठ से बचें'),
    'Air': ('conversation, ideas, travel and social contact; watch scattered focus', 'बातचीत, विचार, यात्रा और सामाजिक संपर्क; बिखरे ध्यान से बचें'),
    'Water': ('emotions, intuition, care and family; watch moodiness', 'भावनाएँ, अंतर्ज्ञान, देखभाल और परिवार; मनोदशा के उतार-चढ़ाव से बचें'),
  };

  /// Chandra Vaas: direction where the Moon resides, by element of its sign.
  static const Map<String, Bi> _chandraVaas = {'Fire': ('East', 'पूर्व'), 'Earth': ('South', 'दक्षिण'), 'Air': ('West', 'पश्चिम'), 'Water': ('North', 'उत्तर')};

  static const Map<String, Bi> _transitNature = {
    'saturn': ('pressure, delays and responsibility', 'दबाव, देरी और ज़िम्मेदारी'),
    'jupiter': ('protection, growth and good counsel', 'संरक्षण, वृद्धि और सही मार्गदर्शन'),
    'mars': ('energy, haste and possible friction', 'ऊर्जा, जल्दबाज़ी और संभावित टकराव'),
    'rahu': ('restlessness, ambition and confusion', 'बेचैनी, महत्वाकांक्षा और भ्रम'),
    'ketu': ('detachment and sudden turns', 'वैराग्य और अचानक मोड़'),
    'sun': ('visibility, ego and authority', 'प्रतिष्ठा, अहं और अधिकार'),
    'venus': ('pleasure, harmony and attraction', 'आनंद, सामंजस्य और आकर्षण'),
    'mercury': ('communication, trade and thinking', 'संवाद, व्यापार और विचार'),
    'moon': ('a passing emotional focus for the day', 'दिन भर का भावनात्मक ध्यान'),
  };

  static List<int> aspectHouses(String p) => switch (p) {
    'mars' => const [4, 7, 8],
    'jupiter' => const [5, 7, 9],
    'saturn' => const [3, 7, 10],
    'rahu' || 'ketu' => const [5, 7, 9],
    _ => const [7],
  };

  static String _p(String p) => L10n.planet(p);
  static String _en(String p) => VedicMath.planets[p]!.name;

  /// Computes the report of [date] (local calendar date at [place]).
  /// With [full] false the expensive supporting analysis (yogas) is skipped;
  /// used when preparing notification texts for many days ahead.
  static RashifalComputation compute(RashifalNatal natal, DateTime date, RashifalPlace place, {bool full = true}) {
    final d = _Day(natal, date, place);
    return _Builder(d, full: full).build();
  }
}

/// Raw astronomical facts of the day.
class _Day {
  final RashifalNatal n;
  final DateTime date;
  final RashifalPlace place;
  late final double offset;
  late final double sunrise;
  late final double sunset;
  late final double nextSunrise;
  late final ChartData sky;
  late final Map<String, dynamic> panchang;
  late final List<TransitResult> transits;
  late final int weekday; // 0 = Sunday
  late final double moonLon;
  late final int moonRashi;
  late final int nak;
  late final int moonFromJanma;
  late final int moonFromLagna;
  late final int tara; // 1..9
  late final double moonSunAngle;
  late final int tithiNum;
  late final int yogaIdx;
  late final String karanaEn;
  late final List<DashaPeriod> dasha;
  late final double? tithiEnds;
  late final double? nakEnds;
  late final double? moonSignChange;
  late final Map<String, int> strength;
  late final Map<String, List<String>> strengthNotes;

  _Day(this.n, this.date, this.place) {
    offset = place.offsetOn(date);
    final midnight = Ephemeris.julianDay(date.year, date.month, date.day, -offset);
    sunrise = Ephemeris.nextSunrise(midnight, place.lat, place.lon) ?? midnight + 0.25;
    sunset = Ephemeris.nextSunset(sunrise, place.lat, place.lon) ?? sunrise + 0.5;
    nextSunrise = Ephemeris.nextSunrise(sunset, place.lat, place.lon) ?? sunrise + 1;
    sky = Ephemeris.computeChartForJd(sunrise + 1 / 1440, place.lat, place.lon, utcOffset: offset);
    panchang = PanchangMath.computePanchang(sky, place.lat, place.lon, offset);
    transits = TransitMath.compute(n.chart, sky.jd);
    weekday = PanchangMath.varas.indexWhere((v) => v['name'] == (panchang['vara'] as Map)['name']);
    moonLon = sky.planetLongitudes['moon']!;
    moonRashi = VedicMath.rashiIndex(moonLon);
    nak = VedicMath.nakshatraIndex(moonLon);
    moonFromJanma = VedicMath.houseOf(moonRashi, n.moonRashi);
    moonFromLagna = VedicMath.houseOf(moonRashi, n.lagna);
    tara = ((nak - n.birthNakshatra + 27) % 27) % 9 + 1;
    moonSunAngle = VedicMath.norm360(moonLon - sky.planetLongitudes['sun']!);
    tithiNum = (moonSunAngle / 12).floor() + 1;
    yogaIdx = (VedicMath.norm360(sky.planetLongitudes['sun']! + moonLon) / (360 / 27)).floor();
    karanaEn = (panchang['karana'] as Map)['en'] as String;
    dasha = n.dashas.runningAt(sky.jd);
    double moon(double jd) => Ephemeris.siderealLongitude('moon', jd);
    tithiEnds = _change(sunrise, nextSunrise, (jd) => (VedicMath.norm360(moon(jd) - Ephemeris.siderealLongitude('sun', jd)) / 12).floor());
    nakEnds = _change(sunrise, nextSunrise, (jd) => VedicMath.nakshatraIndex(moon(jd)));
    moonSignChange = _change(sunrise, nextSunrise, (jd) => VedicMath.rashiIndex(moon(jd)));
    _strengths();
  }

  /// First moment in [a, b] where [f] changes, to about a minute.
  static double? _change(double a, double b, int Function(double) f) {
    final start = f(a);
    if (f(b) == start) return null;
    double lo = a, hi = b;
    for (int i = 0; i < 18; i++) {
      final mid = (lo + hi) / 2;
      if (f(mid) == start) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }

  String hm(double jd) {
    final x = jd + 0.5 + offset / 24;
    return PanchangMath.fmtTime((x - x.floor()) * 24);
  }

  /// "14:05" or "14:05 (+1)" when the time falls after midnight.
  String hmDay(double jd) {
    final civil = (jd + 0.5 + offset / 24).floor();
    final today = (sunrise + 0.5 + offset / 24).floor();
    return civil > today ? '${hm(jd)} (+1)' : hm(jd);
  }

  bool get waxing => moonSunAngle < 180;
  bool get chandrashtama => moonFromJanma == 8;
  bool get chandraGood => RashifalEngine._chandraGood.contains(moonFromJanma) || (waxing && const [2, 5, 9].contains(moonFromJanma));
  int get taraValue => RashifalTables.taras[tara - 1].$2;
  bool get vishti => karanaEn == 'Vishti';
  String get tithiType => (panchang['tithi'] as Map)['type'] as String;

  TransitResult transit(String p) => transits.firstWhere((t) => t.planet == p);
  int fromMoon(String p) => transit(p).houseFromMoon;
  int skyRashi(String p) => VedicMath.rashiIndex(sky.planetLongitudes[p]!);
  bool favourable(String p) => TransitMath.favourableFromMoon[p]?.contains(fromMoon(p)) ?? false;

  bool combust(String p) {
    final orb0 = RashifalTables.combustOrb[p];
    if (orb0 == null) return false;
    final retro = sky.isRetrograde(p);
    final orb = p == 'mercury' && retro ? 12.0 : (p == 'venus' && retro ? 8.0 : orb0);
    final sep = (VedicMath.norm360(sky.planetLongitudes[p]! - sky.planetLongitudes['sun']! + 180) - 180).abs();
    return sep < orb;
  }

  /// Day strength of each graha from transit position, Ashtakavarga,
  /// dignity of the transit sign and combustion.
  void _strengths() {
    strength = {};
    strengthNotes = {};
    for (final p in RashifalEngine._grahas) {
      int s = 0;
      final notes = <String>[];
      final h = fromMoon(p);
      if (favourable(p)) {
        s += 2;
        notes.add(tr('favourable in the ${VedicMath.ordinal(h)} from Moon', 'चन्द्र से $hवें भाव में शुभ'));
      } else {
        s -= 2;
        notes.add(tr('unfavourable in the ${VedicMath.ordinal(h)} from Moon', 'चन्द्र से $hवें भाव में अशुभ'));
      }
      final r = skyRashi(p);
      if (n.av.bhinna.containsKey(p)) {
        final b = n.av.bindusFor(p, r);
        s += b >= 5 ? 2 : (b == 4 ? 1 : (b == 3 ? -1 : -2));
        notes.add(tr('$b Ashtakavarga bindus', '$b अष्टकवर्ग बिंदु'));
      }
      final pd = VedicMath.planets[p]!;
      if (pd.exalt == r) {
        s += 2;
        notes.add(tr('exalted', 'उच्च'));
      } else if (pd.debi == r) {
        s -= 2;
        notes.add(tr('debilitated', 'नीच'));
      } else if (pd.ownSigns.contains(r)) {
        s += 1;
        notes.add(tr('own sign', 'स्वराशि'));
      }
      if (combust(p)) {
        s -= 2;
        notes.add(tr('combust', 'अस्त'));
      }
      if (sky.isRetrograde(p)) notes.add(tr('retrograde (results delayed or revisited)', 'वक्री (परिणाम में देरी या पुनरावृत्ति)'));
      if (p == 'moon') {
        s += waxing ? 1 : -1;
        notes.add(waxing ? tr('waxing', 'शुक्ल पक्ष') : tr('waning', 'कृष्ण पक्ष'));
      }
      strength[p] = s;
      strengthNotes[p] = notes;
    }
  }
}

class _Builder {
  final _Day d;
  final bool full;
  _Builder(this.d, {required this.full});

  RashifalNatal get n => d.n;

  static String _p(String p) => RashifalEngine._p(p);
  static String _en(String p) => RashifalEngine._en(p);

  String _statusOf(int s) => s >= 3
      ? tr('Strongly benefic', 'अत्यंत शुभ')
      : s >= 1
      ? tr('Benefic', 'शुभ')
      : s == 0
      ? tr('Neutral', 'सम')
      : s >= -2
      ? tr('Challenging', 'प्रतिकूल')
      : tr('Strongly malefic', 'अत्यंत प्रतिकूल');

  // ---------------------------------------------------------------------------
  // Day score
  // ---------------------------------------------------------------------------

  List<_F> _dayFactors() {
    final f = <_F>[];
    final h = d.moonFromJanma;
    final moonSign = L10n.sign(d.moonRashi);
    if (d.chandrashtama) {
      f.add(
        _F(
          -14,
          tr(
            'Chandrashtama: the Moon transits the 8th from your Moon sign ($moonSign) — emotions and plans need extra care',
            'चन्द्राष्टम: चन्द्रमा आपकी राशि से 8वें भाव ($moonSign) में है — भावनाओं और योजनाओं में विशेष सावधानी',
          ),
        ),
      );
    } else if (RashifalEngine._chandraGood.contains(h)) {
      f.add(
        _F(10, tr('Chandra Bala is favourable: the Moon transits the ${VedicMath.ordinal(h)} from your Moon sign ($moonSign)', 'चन्द्र बल शुभ: चन्द्रमा आपकी राशि से $hवें भाव ($moonSign) में है')),
      );
    } else if (d.waxing && const [2, 5, 9].contains(h)) {
      f.add(_F(4, tr('The waxing Moon in the ${VedicMath.ordinal(h)} from your Moon sign gives mild Chandra Bala', 'शुक्ल पक्ष का चन्द्रमा आपकी राशि से $hवें भाव में — हल्का चन्द्र बल')));
    } else {
      f.add(_F(-7, tr('Weak Chandra Bala: the Moon transits the ${VedicMath.ordinal(h)} from your Moon sign ($moonSign)', 'कमज़ोर चन्द्र बल: चन्द्रमा आपकी राशि से $hवें भाव ($moonSign) में है')));
    }
    final tara = RashifalTables.taras[d.tara - 1];
    final tw = switch (tara.$2) {
      1 => 8,
      -1 => -8,
      -2 => -12,
      _ => -3,
    };
    f.add(
      _F(
        tw,
        tr('Tara Bala: today\'s nakshatra ${L10n.nakshatra(d.nak)} is ${tara.$1.$1} for your birth star', 'तारा बल: आज का नक्षत्र ${L10n.nakshatra(d.nak)} आपके जन्म नक्षत्र से ${tara.$1.$2} है'),
      ),
    );

    final tithi = d.panchang['tithi'] as Map;
    final tName = L10n.hi ? tithi['hindi'] : tithi['name'];
    if (d.tithiNum == 30) {
      f.add(_F(-6, tr('Amavasya (new Moon): low lunar strength, better for rest and prayers', 'अमावस्या: चन्द्र बल कम, विश्राम और पूजा के लिए बेहतर')));
    } else if (d.tithiType == 'Rikta') {
      f.add(_F(-4, tr('$tName is a Rikta tithi — not ideal for new beginnings', '$tName रिक्ता तिथि है — नई शुरुआत के लिए आदर्श नहीं')));
    } else if (d.tithiType == 'Purna') {
      f.add(_F(4, tr('$tName is a Purna tithi — supports completion and auspicious work', '$tName पूर्णा तिथि है — पूर्णता और शुभ कार्यों में सहायक')));
    }
    final yogaName = L10n.hi ? PanchangMath.yogasH[d.yogaIdx] : PanchangMath.yogas[d.yogaIdx];
    if (RashifalTables.badYogas.contains(d.yogaIdx)) {
      f.add(_F(-4, tr('$yogaName yoga of the Panchang is inauspicious', 'पंचांग का $yogaName योग अशुभ है')));
    } else {
      f.add(_F(2, tr('$yogaName yoga of the Panchang is auspicious', 'पंचांग का $yogaName योग शुभ है')));
    }
    if (d.vishti) f.add(_F(-5, tr('Vishti (Bhadra) karana at sunrise — avoid starting auspicious work in it', 'सूर्योदय पर विष्टि (भद्रा) करण — इसमें शुभ कार्य आरंभ न करें')));

    final mb = n.av.bindusFor('moon', d.moonRashi);
    if (mb >= 5) f.add(_F(5, tr('The Moon\'s Ashtakavarga gives $mb bindus in $moonSign — strong support', 'चन्द्र अष्टकवर्ग में $moonSign में $mb बिंदु — प्रबल सहारा')));
    if (mb <= 3) f.add(_F(-4, tr('The Moon\'s Ashtakavarga gives only $mb bindus in $moonSign', 'चन्द्र अष्टकवर्ग में $moonSign में केवल $mb बिंदु')));
    final sav = n.av.sarva[d.moonRashi];
    if (sav >= 30) f.add(_F(3, tr('Sarvashtakavarga $sav in the Moon\'s sign (above average)', 'चन्द्र की राशि में सर्वाष्टकवर्ग $sav (औसत से अधिक)')));
    if (sav < 25) f.add(_F(-3, tr('Sarvashtakavarga only $sav in the Moon\'s sign', 'चन्द्र की राशि में सर्वाष्टकवर्ग केवल $sav')));

    final vl = RashifalTables.varaLord[d.weekday];
    f.add(
      d.favourable(vl)
          ? _F(3, tr('The day lord ${_p(vl)} transits favourably from your Moon', 'वार स्वामी ${_p(vl)} आपके चन्द्र से शुभ गोचर में'))
          : _F(-2, tr('The day lord ${_p(vl)} transits unfavourably from your Moon', 'वार स्वामी ${_p(vl)} आपके चन्द्र से अशुभ गोचर में')),
    );

    final sat = d.fromMoon('saturn');
    if (const [12, 1, 2].contains(sat)) {
      f.add(_F(-5, tr('Shani Sade Sati is running (Saturn in the ${VedicMath.ordinal(sat)} from your Moon)', 'शनि की साढ़े साती चल रही है (शनि चन्द्र से $satवें भाव में)')));
    } else if (sat == 8) {
      f.add(_F(-5, tr('Ashtama Shani: Saturn transits the 8th from your Moon', 'अष्टम शनि: शनि चन्द्र से 8वें भाव में')));
    } else if (sat == 4) {
      f.add(_F(-3, tr('Kantaka Shani (Dhaiya): Saturn transits the 4th from your Moon', 'कंटक शनि (ढैय्या): शनि चन्द्र से चौथे भाव में')));
    } else if (d.favourable('saturn')) {
      f.add(_F(4, tr('Saturn transits a favourable house from your Moon', 'शनि चन्द्र से शुभ भाव में गोचर कर रहा है')));
    }
    f.add(
      d.favourable('jupiter')
          ? _F(5, tr('Jupiter transits a favourable house (${VedicMath.ordinal(d.fromMoon('jupiter'))}) from your Moon', 'गुरु चन्द्र से शुभ भाव (${d.fromMoon('jupiter')}वें) में गोचर कर रहा है'))
          : _F(-2, tr('Jupiter\'s transit (${VedicMath.ordinal(d.fromMoon('jupiter'))} from Moon) gives little support', 'गुरु का गोचर (चन्द्र से ${d.fromMoon('jupiter')}वाँ) कम सहारा देता है')),
    );

    const weights = [(2, 2), (3, 2), (4, 3)]; // (level, weight) maha, antar, pratyantar
    final names = [tr('Mahadasha', 'महादशा'), tr('Antardasha', 'अंतर्दशा'), tr('Pratyantar dasha', 'प्रत्यंतर दशा')];
    for (int i = 0; i < d.dasha.length && i < 3; i++) {
      final lord = d.dasha[i].lord;
      final w = weights[i].$1;
      f.add(
        d.favourable(lord)
            ? _F(w, tr('${names[i]} lord ${_p(lord)} transits favourably from your Moon', '${names[i]} स्वामी ${_p(lord)} चन्द्र से शुभ गोचर में'))
            : _F(-weights[i].$2, tr('${names[i]} lord ${_p(lord)} transits unfavourably from your Moon', '${names[i]} स्वामी ${_p(lord)} चन्द्र से अशुभ गोचर में')),
      );
    }

    for (final m in ['saturn', 'rahu', 'ketu', 'mars']) {
      if (d.skyRashi(m) == d.moonRashi) {
        f.add(_F(-4, tr('Today\'s Moon is joined by ${_p(m)} in $moonSign', 'आज चन्द्रमा $moonSign में ${_p(m)} के साथ है')));
      }
    }
    if (d.skyRashi('jupiter') == d.moonRashi || VedicMath.houseOf(d.moonRashi, d.skyRashi('jupiter')) == 7 || const [5, 9].contains(VedicMath.houseOf(d.moonRashi, d.skyRashi('jupiter')))) {
      f.add(_F(4, tr('Jupiter conjoins or aspects today\'s Moon — protective influence', 'गुरु आज के चन्द्रमा से युति या दृष्टि संबंध में — रक्षक प्रभाव')));
    }
    if (d.moonSunAngle < 36 || d.moonSunAngle > 324) {
      f.add(_F(-3, tr('The Moon is close to the Sun (weak Paksha Bala)', 'चन्द्रमा सूर्य के निकट है (पक्ष बल कमज़ोर)')));
    } else if (d.moonSunAngle >= 120 && d.moonSunAngle <= 240) {
      f.add(_F(2, tr('The Moon is bright and strong (good Paksha Bala)', 'चन्द्रमा उज्ज्वल और बलवान (अच्छा पक्ष बल)')));
    }
    return f;
  }

  static int _score(int base, List<_F> f) => (base + f.fold<int>(0, (s, x) => s + x.w)).clamp(5, 95);

  static List<String> _top(List<_F> f, [int k = 4]) {
    final sorted = [...f]..sort((a, b) => b.w.abs().compareTo(a.w.abs()));
    return [for (final x in sorted.take(k)) '${x.w > 0 ? '+' : '−'} ${x.text}'];
  }

  int _ratingIndex(DayRating r) => r.index;

  // ---------------------------------------------------------------------------
  // Life areas
  // ---------------------------------------------------------------------------

  RashifalSection _area(String key, int dayScore) {
    final def = RashifalEngine.areaDefs[key]!;
    final houses = def.$1;
    final f = <_F>[];
    for (final t in d.transits) {
      final p = t.planet;
      if (p == 'moon') continue;
      if (houses.contains(t.houseFromMoon)) {
        final h = t.houseFromMoon;
        if (RashifalTables.benefics.contains(p)) {
          f.add(
            _F(
              5,
              tr(
                '${_p(p)} transits your ${VedicMath.ordinal(h)} house from the Moon (${RashifalEngine._houseMeaning[h - 1].$1})',
                '${_p(p)} चन्द्र से आपके $hवें भाव (${RashifalEngine._houseMeaning[h - 1].$2}) में गोचर कर रहा है',
              ),
            ),
          );
        } else if (RashifalEngine._upachaya.contains(h)) {
          f.add(_F(3, tr('${_p(p)} in the ${VedicMath.ordinal(h)} from the Moon works well (upachaya house)', '${_p(p)} चन्द्र से $hवें (उपचय) भाव में अच्छा फल देता है')));
        } else {
          f.add(
            _F(
              -5,
              tr(
                '${_p(p)} transits your ${VedicMath.ordinal(h)} house from the Moon (${RashifalEngine._houseMeaning[h - 1].$1})',
                '${_p(p)} चन्द्र से आपके $hवें भाव (${RashifalEngine._houseMeaning[h - 1].$2}) में गोचर कर रहा है',
              ),
            ),
          );
        }
      } else if (houses.contains(t.houseFromLagna)) {
        final h = t.houseFromLagna;
        final good = RashifalTables.benefics.contains(p) || RashifalEngine._upachaya.contains(h);
        f.add(_F(good ? 3 : -3, tr('${_p(p)} transits the ${VedicMath.ordinal(h)} house from your Lagna', '${_p(p)} आपके लग्न से $hवें भाव में गोचर कर रहा है')));
      }
    }
    final mh = d.moonFromJanma;
    if (houses.contains(mh)) {
      f.add(
        d.chandraGood && !d.chandrashtama
            ? _F(7, tr('Today\'s Moon lights up this area (${VedicMath.ordinal(mh)} from your Moon sign)', 'आज का चन्द्रमा इस क्षेत्र को सक्रिय करता है (आपकी राशि से $mhवाँ भाव)'))
            : _F(
                -6,
                tr(
                  'Today\'s Moon stirs this area from a weak position (${VedicMath.ordinal(mh)} from your Moon sign)',
                  'आज का चन्द्रमा कमज़ोर स्थिति से इस क्षेत्र को प्रभावित करता है (आपकी राशि से $mhवाँ भाव)',
                ),
              ),
      );
    }
    final karakas = [...def.$2, if (key == 'marriage' && n.gender == 'Female') 'jupiter'];
    for (final k in karakas) {
      if (k == 'moon') {
        if (d.taraValue > 0) f.add(_F(4, tr('Supportive Tara for the Moon, the significator', 'कारक चन्द्रमा के लिए शुभ तारा')));
        if (d.taraValue < 0) f.add(_F(-4, tr('Unfavourable Tara for the Moon, the significator', 'कारक चन्द्रमा के लिए अशुभ तारा')));
        continue;
      }
      f.add(
        d.favourable(k)
            ? _F(4, tr('Significator ${_p(k)} transits favourably', 'कारक ${_p(k)} शुभ गोचर में'))
            : _F(-3, tr('Significator ${_p(k)} transits unfavourably', 'कारक ${_p(k)} अशुभ गोचर में')),
      );
      if (d.combust(k)) f.add(_F(-3, tr('Significator ${_p(k)} is combust today', 'कारक ${_p(k)} आज अस्त है')));
    }
    final primary = houses.first;
    final primaryRashi = (n.moonRashi + primary - 1) % 12;
    for (final (planet, w) in [('jupiter', 4), ('saturn', -3), ('mars', -3)]) {
      final from = d.skyRashi(planet);
      final hFrom = VedicMath.houseOf(primaryRashi, from);
      if (RashifalEngine.aspectHouses(planet).contains(hFrom)) {
        f.add(
          _F(
            w,
            w > 0
                ? tr('Jupiter aspects the ${VedicMath.ordinal(primary)} from your Moon — protection', 'गुरु की दृष्टि चन्द्र से $primaryवें भाव पर — संरक्षण')
                : tr('${_p(planet)} aspects the ${VedicMath.ordinal(primary)} from your Moon', '${_p(planet)} की दृष्टि चन्द्र से $primaryवें भाव पर'),
          ),
        );
      }
    }
    final sav = n.av.sarvaInHouse(primary);
    if (sav >= 30) f.add(_F(3, tr('Your ${VedicMath.ordinal(primary)} house has strong Sarvashtakavarga ($sav)', 'आपके $primaryवें भाव में प्रबल सर्वाष्टकवर्ग ($sav)')));
    if (sav <= 24) f.add(_F(-3, tr('Your ${VedicMath.ordinal(primary)} house has low Sarvashtakavarga ($sav)', 'आपके $primaryवें भाव में कम सर्वाष्टकवर्ग ($sav)')));
    for (int i = 0; i < d.dasha.length && i < 2; i++) {
      final lord = d.dasha[i].lord;
      if (houses.any((h) => n.housesRuledBy(lord).contains(h))) {
        final good = d.favourable(lord);
        f.add(
          _F(
            good ? 3 : -2,
            tr(
              'Your running ${i == 0 ? 'Mahadasha' : 'Antardasha'} lord ${_p(lord)} rules this area, so it is in focus',
              'आपकी चल रही ${i == 0 ? 'महादशा' : 'अंतर्दशा'} का स्वामी ${_p(lord)} इस क्षेत्र का स्वामी है, इसलिए यह क्षेत्र प्रमुख है',
            ),
          ),
        );
      }
    }
    switch (key) {
      case 'health':
        if (d.chandrashtama) f.add(_F(-6, tr('Chandrashtama lowers stamina and immunity', 'चन्द्राष्टम से ऊर्जा और रोग-प्रतिरोधक क्षमता घटती है')));
        if (const [1, 8].contains(d.fromMoon('saturn'))) f.add(_F(-4, tr('Saturn over the 1st/8th from the Moon asks for rest and care', 'चन्द्र से 1/8वें भाव पर शनि विश्राम और देखभाल माँगता है')));
      case 'career':
        if (d.fromMoon('sun') == 10) f.add(_F(4, tr('The Sun in the 10th from the Moon brings recognition', 'चन्द्र से 10वें भाव में सूर्य से मान-सम्मान')));
      case 'mind':
        if (d.skyRashi('rahu') == d.moonRashi || d.skyRashi('ketu') == d.moonRashi) {
          f.add(_F(-6, tr('The Moon with a node (Grahan-like) clouds the mind today', 'चन्द्रमा राहु/केतु के साथ (ग्रहण-सा योग) — आज मन अशांत रह सकता है')));
        }
        if (!d.waxing) f.add(_F(-2, tr('Waning Moon — energy turns inward', 'क्षीण चन्द्रमा — ऊर्जा भीतर की ओर')));
      case 'finance':
        if (d.sky.isRetrograde('mercury')) f.add(_F(-2, tr('Mercury retrograde: review deals and bills carefully', 'बुध वक्री: सौदों और बिलों को ध्यान से जाँचें')));
        if (d.tithiType == 'Rikta') f.add(_F(-2, tr('Rikta tithi — not ideal for new money commitments', 'रिक्ता तिथि — नई वित्तीय प्रतिबद्धता के लिए आदर्श नहीं')));
      case 'social':
        if (d.sky.isRetrograde('mercury')) f.add(_F(-2, tr('Mercury retrograde: messages can be misread', 'बुध वक्री: संदेशों का गलत अर्थ निकल सकता है')));
      case 'marriage':
        if (d.sky.isRetrograde('venus')) f.add(_F(-2, tr('Venus retrograde: old relationship issues may resurface', 'शुक्र वक्री: रिश्ते के पुराने मुद्दे उभर सकते हैं')));
        if (VedicMath.houseOf(d.skyRashi('mars'), n.lagna) == 7) {
          f.add(_F(-3, tr('Mars crosses your 7th house — keep the temper cool', 'मंगल आपके सातवें भाव से गुज़र रहा है — गुस्से पर नियंत्रण रखें')));
        }
    }
    final score = _score(50 + ((dayScore - 50) * 0.35).round(), f);
    final rating = DayRating.fromScore(score);
    return RashifalSection(key: key, title: def.$3.t, text: RashifalEngine._areaAdvice[key]![_ratingIndex(rating)].t, score: score, rating: rating, factors: _top(f, 3));
  }

  // ---------------------------------------------------------------------------
  // Time slots
  // ---------------------------------------------------------------------------

  ({double start, double end}) _part(List<int> table) {
    final len = d.sunset - d.sunrise;
    final k = table[d.weekday];
    return (start: d.sunrise + len * k / 8, end: d.sunrise + len * (k + 1) / 8);
  }

  List<TimeSlot> _slots() {
    final slots = <TimeSlot>[];
    final rahu = _part(PanchangMath.rahuKaalPart);
    final yama = _part(PanchangMath.yamagandaPart);
    final gulika = _part(PanchangMath.gulikaPart);
    bool overlaps(double s, double e) => s < rahu.end && e > rahu.start;

    final dayLen = d.sunset - d.sunrise;
    final muhurta = dayLen / 15;
    final midday = (d.sunrise + d.sunset) / 2;
    slots.add(
      TimeSlot(
        tr('Brahma Muhurta', 'ब्रह्म मुहूर्त'),
        d.hm(d.sunrise - 2 * 48 / 1440),
        d.hm(d.sunrise - 48 / 1440),
        'good',
        tr('Best for meditation, prayer and study', 'ध्यान, पूजा और अध्ययन के लिए श्रेष्ठ'),
      ),
    );
    slots.add(
      TimeSlot(
        tr('Abhijit Muhurta', 'अभिजित मुहूर्त'),
        d.hm(midday - muhurta / 2),
        d.hm(midday + muhurta / 2),
        d.weekday == 3 ? 'neutral' : 'good',
        d.weekday == 3 ? tr('Traditionally not used on Wednesday', 'परंपरा से बुधवार को वर्जित') : tr('Auspicious for most beginnings', 'अधिकांश शुभ आरंभ के लिए उत्तम'),
      ),
    );
    final cd = RashifalTables.choghadiya;
    for (int i = 0; i < 8; i++) {
      final idx = (RashifalTables.firstDayChoghadiya[d.weekday] + i) % 7;
      final s = d.sunrise + dayLen * i / 8, e = d.sunrise + dayLen * (i + 1) / 8;
      if (cd[idx].$2 == 1) {
        slots.add(
          TimeSlot(
            '${cd[idx].$1.t} ${tr('Choghadiya', 'चौघड़िया')}',
            d.hm(s),
            d.hm(e),
            overlaps(s, e) ? 'neutral' : 'good',
            overlaps(s, e) ? tr('Overlaps Rahu Kaal', 'राहु काल से मेल') : tr('Day', 'दिन'),
          ),
        );
      }
    }
    final nightLen = d.nextSunrise - d.sunset;
    for (int i = 0; i < 4; i++) {
      final idx = (RashifalTables.firstNightChoghadiya[d.weekday] - 2 * i + 14) % 7;
      final s = d.sunset + nightLen * i / 8, e = d.sunset + nightLen * (i + 1) / 8;
      if (cd[idx].$2 == 1) slots.add(TimeSlot('${cd[idx].$1.t} ${tr('Choghadiya', 'चौघड़िया')}', d.hm(s), d.hmDay(e), 'good', tr('Night', 'रात्रि')));
    }
    slots.add(TimeSlot(tr('Rahu Kaal', 'राहु काल'), d.hm(rahu.start), d.hm(rahu.end), 'avoid', tr('Do not start important work', 'महत्वपूर्ण कार्य आरंभ न करें')));
    slots.add(TimeSlot(tr('Yamaganda', 'यमगण्ड'), d.hm(yama.start), d.hm(yama.end), 'avoid', tr('Inauspicious for beginnings', 'आरंभ के लिए अशुभ')));
    slots.add(TimeSlot(tr('Gulika Kaal', 'गुलिक काल'), d.hm(gulika.start), d.hm(gulika.end), 'avoid', tr('Avoid new commitments', 'नई प्रतिबद्धता से बचें')));
    if (d.vishti) {
      final end = d.tithiEnds;
      slots.add(TimeSlot(tr('Bhadra (Vishti karana)', 'भद्रा (विष्टि करण)'), d.hm(d.sunrise), end == null ? '—' : d.hmDay(end), 'avoid', tr('Avoid auspicious beginnings', 'शुभ आरंभ से बचें')));
    }
    return slots;
  }

  // ---------------------------------------------------------------------------
  // Outlook
  // ---------------------------------------------------------------------------

  RashifalSection _muhurat(List<TimeSlot> slots) {
    final good = slots.where((s) => s.quality == 'good').toList();
    final avoid = slots.where((s) => s.quality == 'avoid').toList();
    final best = good.where((s) => s.note != tr('Night', 'रात्रि') && !s.name.startsWith(tr('Brahma', 'ब्रह्म'))).take(3).map((s) => '${s.name} ${s.range}');
    return RashifalSection(
      key: 'muhurat',
      title: tr('Shubh Muhurat', 'शुभ मुहूर्त'),
      text: tr(
        'Best windows today: ${best.join(', ')}. Avoid starting new work in ${avoid.map((s) => '${s.name} (${s.range})').join(', ')}.',
        'आज के श्रेष्ठ समय: ${best.join(', ')}। ${avoid.map((s) => '${s.name} (${s.range})').join(', ')} में नया काम शुरू न करें।',
      ),
      items: [for (final s in good) '${s.name}: ${s.range}${s.note.isEmpty ? '' : ' — ${s.note}'}'],
      items2: [for (final s in avoid) '${s.name}: ${s.range}${s.note.isEmpty ? '' : ' — ${s.note}'}'],
    );
  }

  static const List<Bi> _riskLevel = [('Low', 'कम'), ('Moderate', 'मध्यम'), ('High', 'अधिक')];

  RashifalSection _travel() {
    final f = <_F>[];
    if (const [3, 9, 12].contains(d.moonFromJanma)) {
      f.add(
        _F(
          4,
          tr(
            'The Moon activates a travel house (${VedicMath.ordinal(d.moonFromJanma)} from your Moon) — journeys are likely',
            'चन्द्रमा यात्रा भाव (आपकी राशि से ${d.moonFromJanma}वाँ) को सक्रिय करता है — यात्रा के योग',
          ),
        ),
      );
    }
    if (d.chandrashtama) f.add(_F(-12, tr('Chandrashtama — postpone long journeys if possible', 'चन्द्राष्टम — संभव हो तो लंबी यात्रा टालें')));
    if (d.taraValue > 0) f.add(_F(5, tr('Favourable Tara for setting out', 'यात्रा आरंभ के लिए शुभ तारा')));
    if (d.taraValue < 0) f.add(_F(-6, tr('Unfavourable Tara for setting out', 'यात्रा आरंभ के लिए अशुभ तारा')));
    final nature = RashifalTables.nakshatraNature[d.nak];
    if (RashifalTables.travelNakshatras.contains(d.nak)) {
      f.add(_F(8, tr('${L10n.nakshatra(d.nak)} is a classical travel nakshatra', '${L10n.nakshatra(d.nak)} यात्रा के लिए शास्त्रीय शुभ नक्षत्र है')));
    } else if (nature == 2 || nature == 6) {
      f.add(
        _F(
          -5,
          tr(
            '${L10n.nakshatra(d.nak)} (${RashifalTables.natures[nature].$1.$1}) is not suited to journeys',
            '${L10n.nakshatra(d.nak)} (${RashifalTables.natures[nature].$1.$2}) यात्रा के अनुकूल नहीं',
          ),
        ),
      );
    } else if (nature == 0) {
      f.add(_F(-4, tr('A fixed (Dhruva) nakshatra favours staying put', 'स्थिर (ध्रुव) नक्षत्र ठहराव के पक्ष में है')));
    }
    if (d.vishti) f.add(_F(-5, tr('Bhadra (Vishti) is running at sunrise', 'सूर्योदय पर भद्रा (विष्टि) है')));
    if (d.favourable('mercury')) f.add(_F(3, tr('Mercury supports short trips and logistics', 'बुध छोटी यात्राओं और व्यवस्थाओं में सहायक')));
    if (d.sky.isRetrograde('mercury')) f.add(_F(-3, tr('Mercury retrograde — confirm tickets and timings', 'बुध वक्री — टिकट और समय की पुष्टि करें')));
    final score = _score(55, f);
    final rating = DayRating.fromScore(score);
    final shool = RashifalTables.dishaShool[d.weekday].t;
    final vaas = RashifalEngine._chandraVaas[VedicMath.rashis[d.moonRashi].element]!.t;
    final advice = switch (rating) {
      DayRating.good => tr(
        'A good day to travel; journeys started in a Shubh/Labh/Amrit window should go smoothly.',
        'यात्रा के लिए अच्छा दिन; शुभ/लाभ/अमृत चौघड़िया में शुरू की गई यात्रा सुगम रहेगी।',
      ),
      DayRating.average => tr('Travel is fine for necessary trips; keep buffers for delays.', 'आवश्यक यात्राएँ ठीक हैं; देरी के लिए समय रखें।'),
      DayRating.bad => tr(
        'Avoid non-essential and long journeys today; if you must travel, plan carefully and drive safely.',
        'आज अनावश्यक और लंबी यात्राएँ टालें; जाना ज़रूरी हो तो सावधानी से योजना बनाएँ और सुरक्षित चलें।',
      ),
    };
    return RashifalSection(
      key: 'travel',
      title: tr('Travel Predictions', 'यात्रा भविष्यवाणी'),
      text:
          '$advice ${tr('Disha Shool today is in the $shool — avoid starting a journey towards it; if unavoidable, ${RashifalTables.dishaShoolRemedy[d.weekday].$1}. Chandra Vaas (the Moon\'s direction) is $vaas.', 'आज दिशा शूल $shool में है — उस दिशा में यात्रा आरंभ न करें; अनिवार्य हो तो ${RashifalTables.dishaShoolRemedy[d.weekday].$2}। चन्द्र वास (चन्द्रमा की दिशा) $vaas है।')}',
      score: score,
      rating: rating,
      factors: _top(f, 3),
      extra: {'dishaShool': shool, 'chandraVaas': vaas},
    );
  }

  RashifalSection _finance(int financeScore) {
    final f = <_F>[];
    if (const [2, 11].contains(d.moonFromJanma)) {
      f.add(_F(6, tr('The Moon transits your house of ${d.moonFromJanma == 2 ? 'wealth' : 'gains'}', 'चन्द्रमा आपके ${d.moonFromJanma == 2 ? 'धन' : 'लाभ'} भाव में है')));
    }
    if (d.moonFromJanma == 12) f.add(_F(-5, tr('The Moon in the 12th from your Moon raises expenses', 'आपकी राशि से 12वें भाव में चन्द्रमा खर्च बढ़ाता है')));
    if (d.favourable('jupiter')) f.add(_F(4, tr('Jupiter (wealth significator) transits favourably', 'गुरु (धन कारक) शुभ गोचर में')));
    if (d.sky.isRetrograde('mercury')) f.add(_F(-6, tr('Mercury retrograde — read contracts twice and avoid hasty deals', 'बुध वक्री — अनुबंध दो बार पढ़ें और जल्दबाज़ी के सौदे टालें')));
    if (d.tithiType == 'Rikta') f.add(_F(-4, tr('Rikta tithi — weak for fresh investments', 'रिक्ता तिथि — नए निवेश के लिए कमज़ोर')));
    if (d.vishti) f.add(_F(-4, tr('Bhadra (Vishti) at sunrise', 'सूर्योदय पर भद्रा (विष्टि)')));
    if (d.taraValue < 0) f.add(_F(-4, tr('Unfavourable Tara for decisions', 'निर्णयों के लिए अशुभ तारा')));
    if (d.weekday == 4 || d.weekday == 3) {
      f.add(_F(2, tr('${d.weekday == 4 ? 'Thursday' : 'Wednesday'} favours financial planning', '${d.weekday == 4 ? 'गुरुवार' : 'बुधवार'} वित्तीय योजना के लिए अनुकूल')));
    }
    final score = _score(financeScore, f);
    final rating = DayRating.fromScore(score);
    final text = switch (rating) {
      DayRating.good => tr(
        'Good for investments, purchases and money decisions — ideally during Labh or Amrit Choghadiya.',
        'निवेश, खरीदारी और धन संबंधी निर्णयों के लिए अच्छा — लाभ या अमृत चौघड़िया में बेहतर।',
      ),
      DayRating.average => tr(
        'Fine for routine transactions; postpone large investments if you can, and compare before buying.',
        'सामान्य लेन-देन ठीक है; हो सके तो बड़ा निवेश टालें, और खरीदने से पहले तुलना करें।',
      ),
      DayRating.bad => tr('Avoid new investments, loans, lending and speculation today; review rather than commit.', 'आज नए निवेश, ऋण, उधार और सट्टे से बचें; प्रतिबद्धता के बजाय समीक्षा करें।'),
    };
    return RashifalSection(key: 'financeDecisions', title: tr('Financial Decisions', 'वित्तीय निर्णय'), text: text, score: score, rating: rating, factors: _top(f, 3));
  }

  RashifalSection _unexpected() {
    final f = <_F>[];
    if (d.chandrashtama) f.add(_F(-20, tr('Chandrashtama (Moon in the 8th from your Moon sign)', 'चन्द्राष्टम (आपकी राशि से 8वें भाव में चन्द्रमा)')));
    for (final node in ['rahu', 'ketu']) {
      if (d.skyRashi(node) == d.moonRashi) f.add(_F(-12, tr('Today\'s Moon is with ${_p(node)}', 'आज चन्द्रमा ${_p(node)} के साथ है')));
    }
    for (final m in ['saturn', 'mars']) {
      if (d.skyRashi(m) == d.moonRashi) f.add(_F(-8, tr('Today\'s Moon is with ${_p(m)}', 'आज चन्द्रमा ${_p(m)} के साथ है')));
    }
    if (RashifalTables.gandaMoola.contains(d.nak)) f.add(_F(-6, tr('${L10n.nakshatra(d.nak)} is a Ganda Moola nakshatra', '${L10n.nakshatra(d.nak)} गंड मूल नक्षत्र है')));
    final deg = VedicMath.degInRashi(d.moonLon);
    final water = const [3, 7, 11].contains(d.moonRashi), fire = const [0, 4, 8].contains(d.moonRashi);
    if ((water && deg > 26.67) || (fire && deg < 3.33)) f.add(_F(-8, tr('The Moon is in Gandanta (water–fire junction)', 'चन्द्रमा गंडांत (जल-अग्नि संधि) में है')));
    if (d.vishti) f.add(_F(-5, tr('Bhadra (Vishti karana)', 'भद्रा (विष्टि करण)')));
    if (d.taraValue < 0) f.add(_F(-6, tr('Unfavourable Tara', 'अशुभ तारा')));
    final sun = d.sky.planetLongitudes['sun']!;
    for (final node in ['rahu', 'ketu']) {
      final sep = (VedicMath.norm360(sun - d.sky.planetLongitudes[node]! + 180) - 180).abs();
      if (sep < 15) f.add(_F(-6, tr('Eclipse season: the Sun is near ${_p(node)}', 'ग्रहण काल: सूर्य ${_p(node)} के निकट है')));
    }
    final ms = VedicMath.houseOf(d.skyRashi('saturn'), d.skyRashi('mars'));
    if (d.skyRashi('saturn') == d.skyRashi('mars') || const [4, 7, 8].contains(ms)) {
      f.add(_F(-5, tr('Mars and Saturn are in contact in the sky (accident-prone combination)', 'आकाश में मंगल और शनि का संबंध (दुर्घटना-प्रवण योग)')));
    }
    for (final node in ['rahu', 'ketu']) {
      final r = d.skyRashi(node);
      if (r == n.moonRashi || r == n.lagna) {
        f.add(_F(-5, tr('${_p(node)} transits your natal ${r == n.lagna ? 'Lagna' : 'Moon'} sign', '${_p(node)} आपकी जन्म ${r == n.lagna ? 'लग्न' : 'चन्द्र'} राशि से गुज़र रहा है')));
      }
    }
    final jh = VedicMath.houseOf(d.moonRashi, d.skyRashi('jupiter'));
    if (jh == 1 || RashifalEngine.aspectHouses('jupiter').contains(jh)) f.add(_F(6, tr('Jupiter protects today\'s Moon', 'गुरु आज के चन्द्रमा की रक्षा करता है')));
    if (d.taraValue > 0) f.add(_F(4, tr('Favourable Tara', 'शुभ तारा')));
    final score = _score(70, f);
    final rating = DayRating.fromScore(score);
    final level = rating == DayRating.good ? 0 : (rating == DayRating.average ? 1 : 2);
    final text = switch (level) {
      0 => tr('No strong signs of surprises; the day should run as planned.', 'अचानक घटनाओं के प्रबल संकेत नहीं; दिन योजना के अनुसार चलना चाहिए।'),
      1 => tr('Some surprises are possible — keep buffers in time and money and back up important data.', 'कुछ अचानक बदलाव संभव — समय और धन में गुंजाइश रखें और ज़रूरी डेटा का बैकअप लें।'),
      _ => tr(
        'Sudden changes are likely: avoid risks, drive carefully, keep plans flexible and stay calm in surprises.',
        'अचानक बदलाव संभावित: जोखिम से बचें, सावधानी से वाहन चलाएँ, योजनाएँ लचीली रखें और अप्रत्याशित स्थिति में शांत रहें।',
      ),
    };
    return RashifalSection(
      key: 'unexpected',
      title: tr('Unexpected Events', 'अप्रत्याशित घटनाएँ'),
      text: '${tr('Risk level', 'जोखिम स्तर')}: ${_riskLevel[level].t}. $text',
      score: score,
      rating: rating,
      factors: _top(f, 3),
      extra: {'risk': _riskLevel[level].$1},
    );
  }

  // ---------------------------------------------------------------------------
  // Remedies
  // ---------------------------------------------------------------------------

  String _keyPlanet() {
    final vl = RashifalTables.varaLord[d.weekday];
    final candidates = <String>{for (final p in d.dasha.reversed) p.lord, vl, 'moon'};
    String worst = vl;
    int ws = 99;
    for (final p in candidates) {
      final s = d.strength[p]!;
      if (s < ws) {
        ws = s;
        worst = p;
      }
    }
    return ws <= 0 ? worst : vl;
  }

  List<RashifalSection> _remedies(String keyPlanet, List<TimeSlot> slots) {
    final vl = RashifalTables.varaLord[d.weekday];
    final m = RashifalTables.beejMantra[keyPlanet]!;
    final why = keyPlanet == vl && d.strength[vl]! > 0
        ? tr('to strengthen ${_p(keyPlanet)}, lord of the day', 'वार स्वामी ${_p(keyPlanet)} को बल देने के लिए')
        : tr('to pacify ${_p(keyPlanet)}, which is under pressure today', 'आज दबाव में रहे ${_p(keyPlanet)} की शांति के लिए');
    final timing = const {'saturn', 'rahu', 'ketu'}.contains(keyPlanet) ? tr('in the evening', 'संध्या के समय') : tr('after bathing in the morning', 'सुबह स्नान के बाद');
    final vm = RashifalTables.beejMantra[vl]!;

    final strongest = (RashifalEngine._grahas.where((p) => p != 'rahu' && p != 'ketu').toList()..sort((a, b) => d.strength[b]!.compareTo(d.strength[a]!))).first;
    final weakest = (RashifalEngine._grahas.toList()..sort((a, b) => d.strength[a]!.compareTo(d.strength[b]!))).first;
    final luckyPlanet = d.strength[vl]! >= 0 ? vl : strongest;
    final lucky = RashifalTables.planetColour[luckyPlanet]!;
    final alt = RashifalTables.planetColour[strongest]!;
    final avoid = RashifalTables.planetColour[weakest]!;

    final upay = <String>[RashifalTables.upay[keyPlanet]!.t];
    if (d.chandrashtama) upay.add(tr('As the Moon is in your 8th, offer water to a Shiva Linga and avoid arguments.', 'चन्द्रमा आठवें भाव में है, इसलिए शिवलिंग पर जल चढ़ाएँ और विवाद से बचें।'));
    if (const [12, 1, 2, 4, 8].contains(d.fromMoon('saturn')) && keyPlanet != 'saturn') {
      upay.add(
        tr(
          'For Saturn\'s ongoing transit, recite the Hanuman Chalisa or light a mustard-oil lamp on Saturday evening.',
          'शनि के चल रहे गोचर के लिए हनुमान चालीसा पढ़ें या शनिवार शाम सरसों के तेल का दीपक जलाएँ।',
        ),
      );
    }

    final nature = RashifalTables.natures[RashifalTables.nakshatraNature[d.nak]];
    final tt = RashifalTables.tithiType[d.tithiType]!;
    final vdd = RashifalTables.varaDoDont[d.weekday];
    final rahu = slots.firstWhere((s) => s.name == tr('Rahu Kaal', 'राहु काल'));
    final best = slots.where((s) => s.quality == 'good' && s.note != tr('Night', 'रात्रि')).skip(1).firstOrNull;
    final dos = <String>[
      vdd.$1.t,
      tr('${L10n.nakshatra(d.nak)} is ${nature.$1.$1}: good for ${nature.$2.$1.toLowerCase()}', '${L10n.nakshatra(d.nak)} ${nature.$1.$2} नक्षत्र है: ${nature.$2.$2}'),
      tr('The tithi is ${tt.$1.$1}: suited to ${tt.$2.$1}', 'तिथि ${tt.$1.$2} है: ${tt.$2.$2} के लिए उपयुक्त'),
      if (best != null) tr('Start important work in ${best.name} (${best.range})', 'महत्वपूर्ण कार्य ${best.name} (${best.range}) में शुरू करें'),
      tr('Wear or carry ${lucky.$1.toLowerCase()}', '${lucky.$2} रंग पहनें या साथ रखें'),
    ];
    final donts = <String>[
      vdd.$2.t,
      tr('Avoid ${nature.$3.$1.toLowerCase()}', '${nature.$3.$2} से बचें'),
      tr('Don\'t begin important work in Rahu Kaal (${rahu.range})', 'राहु काल (${rahu.range}) में महत्वपूर्ण कार्य शुरू न करें'),
      if (d.chandrashtama) tr('Avoid major decisions and confrontations (Chandrashtama)', 'बड़े निर्णय और टकराव से बचें (चन्द्राष्टम)'),
      if (d.vishti) tr('Avoid auspicious beginnings during Bhadra (Vishti karana)', 'भद्रा (विष्टि करण) में शुभ आरंभ न करें'),
      if (d.sky.isRetrograde('mercury')) tr('Don\'t sign documents without re-reading them (Mercury retrograde)', 'दस्तावेज़ों को दोबारा पढ़े बिना हस्ताक्षर न करें (बुध वक्री)'),
    ];

    return [
      RashifalSection(
        key: 'mantra',
        title: tr('Today\'s Mantra', 'आज का मंत्र'),
        text: tr('Chant the beej mantra of ${_p(keyPlanet)} 108 times $timing, $why.', '${_p(keyPlanet)} के बीज मंत्र का 108 बार जाप करें ($timing), $why।'),
        items: [m.$1, m.$2, if (vl != keyPlanet) tr('Day lord (${_p(vl)}): ${vm.$2}', 'वार स्वामी (${_p(vl)}): ${vm.$1}')],
        extra: {'planet': keyPlanet, 'devanagari': m.$1, 'transliteration': m.$2, 'count': '108'},
      ),
      RashifalSection(key: 'upay', title: tr('Daily Remedy (Upay)', 'दैनिक उपाय'), text: upay.first, items: upay.skip(1).toList(), extra: {'deity': RashifalTables.deity[keyPlanet]!.t}),
      RashifalSection(
        key: 'donation',
        title: tr('Donation & Charity', 'दान और पुण्य'),
        text: tr('Donate for ${_p(keyPlanet)}: ${RashifalTables.donation[keyPlanet]!.$1}', '${_p(keyPlanet)} के लिए दान: ${RashifalTables.donation[keyPlanet]!.$2}'),
        items: [if (keyPlanet != vl) tr('For the day lord ${_p(vl)}: ${RashifalTables.donation[vl]!.$1}', 'वार स्वामी ${_p(vl)} के लिए: ${RashifalTables.donation[vl]!.$2}')],
      ),
      RashifalSection(
        key: 'colour',
        title: tr('Colour of the Day', 'आज का शुभ रंग'),
        text: tr(
          '${lucky.$1} — the colour of ${_p(luckyPlanet)}${luckyPlanet == vl ? ', lord of the day' : ', your strongest planet today'}.${strongest != luckyPlanet ? ' ${alt.$1} also helps.' : ''} Avoid ${avoid.$1.toLowerCase()} as the main colour (${_p(weakest)} is weak today).',
          '${lucky.$2} — ${_p(luckyPlanet)} का रंग${luckyPlanet == vl ? ', जो वार स्वामी है' : ', जो आज आपका सबसे बलवान ग्रह है'}।${strongest != luckyPlanet ? ' ${alt.$2} भी शुभ है।' : ''} मुख्य रंग के रूप में ${avoid.$2} से बचें (${_p(weakest)} आज कमज़ोर है)।',
        ),
        extra: {'hex': lucky.$3, 'name': L10n.hi ? lucky.$2 : lucky.$1, 'avoidHex': avoid.$3, 'avoid': L10n.hi ? avoid.$2 : avoid.$1},
      ),
      RashifalSection(
        key: 'dosDonts',
        title: tr('Today\'s Do\'s and Don\'ts', 'आज क्या करें और क्या न करें'),
        text: tr('Follow these simple guidelines drawn from the Panchang and your transits.', 'पंचांग और आपके गोचर पर आधारित ये सरल सुझाव अपनाएँ।'),
        items: dos,
        items2: donts,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------

  List<String> _aspectPoints() {
    final targets = <(String, String, double, int)>[
      ('lagna', tr('Lagna', 'लग्न'), n.chart.ascendantSidereal, 6),
      for (final p in RashifalEngine._grahas) (p, _p(p), n.chart.planetLongitudes[p]!, p == 'moon' ? 6 : (p == 'sun' ? 4 : (d.dasha.any((x) => x.lord == p) ? 4 : 1))),
    ];
    final hits = <(int, String)>[];
    for (final t in ['saturn', 'jupiter', 'rahu', 'ketu', 'mars', 'sun', 'venus', 'mercury', 'moon']) {
      final tl = d.sky.planetLongitudes[t]!;
      final tr0 = VedicMath.rashiIndex(tl);
      final slow = const {'saturn', 'jupiter', 'rahu', 'ketu', 'mars'}.contains(t);
      for (final target in targets) {
        if (target.$1 == t && slow) continue;
        final nr = VedicMath.rashiIndex(target.$3);
        final h = VedicMath.houseOf(nr, tr0);
        final isConj = h == 1;
        if (!isConj && (!slow || !RashifalEngine.aspectHouses(t).contains(h))) continue;
        if (!slow && !isConj) continue;
        final orb = (VedicMath.norm360(tl + (h - 1) * 30 - target.$3 + 180) - 180).abs();
        final kind = isConj ? tr('conjoins', 'की युति') : tr('aspects (${VedicMath.ordinal(h)} drishti)', 'की दृष्टि ($hवीं)');
        final importance = target.$4 * (slow ? 3 : 1) + (orb < 3 ? 6 : (orb < 8 ? 2 : 0)) + (t == 'moon' ? -2 : 0);
        hits.add((
          importance,
          tr(
            'Transit ${_p(t)} $kind your natal ${target.$2} (orb ${orb.toStringAsFixed(1)}°) — ${RashifalEngine._transitNature[t]!.$1}',
            'गोचर ${_p(t)} $kind आपके जन्म ${target.$2} पर (अंतर ${orb.toStringAsFixed(1)}°) — ${RashifalEngine._transitNature[t]!.$2}',
          ),
        ));
      }
    }
    hits.sort((a, b) => b.$1.compareTo(a.$1));
    final points = [for (final h in hits.take(9)) h.$2];
    final sky = <String>[];
    final ps = RashifalEngine._grahas;
    for (int i = 0; i < ps.length; i++) {
      for (int j = i + 1; j < ps.length; j++) {
        if ({ps[i], ps[j]}.containsAll({'rahu', 'ketu'})) continue;
        final a = d.sky.planetLongitudes[ps[i]]!, b = d.sky.planetLongitudes[ps[j]]!;
        if (VedicMath.rashiIndex(a) != VedicMath.rashiIndex(b)) continue;
        final sep = (VedicMath.norm360(a - b + 180) - 180).abs();
        sky.add(
          tr(
            'In the sky today: ${_p(ps[i])}–${_p(ps[j])} together in ${L10n.sign(VedicMath.rashiIndex(a))} (${sep.toStringAsFixed(1)}° apart)',
            'आज आकाश में: ${_p(ps[i])}–${_p(ps[j])} ${L10n.sign(VedicMath.rashiIndex(a))} में साथ (${sep.toStringAsFixed(1)}° दूर)',
          ),
        );
      }
    }
    return [...points, ...sky];
  }

  List<AnalysisBlock> _analysis(int score, DayRating rating, List<_F> dayF) {
    final blocks = <AnalysisBlock>[];
    final p = d.panchang;
    final vl = RashifalTables.varaLord[d.weekday];
    final lagnaLord = VedicMath.rashis[n.lagna].lord;
    final rel = PlanetaryDignity.getNaturalRelationship(vl, lagnaLord).name;
    final relText = vl == lagnaLord
        ? tr('is your Lagna lord itself', 'स्वयं आपका लग्नेश है')
        : tr(
            'is ${const {'greatFriend': 'a great friend', 'friend': 'a friend', 'neutral': 'neutral', 'enemy': 'an enemy', 'greatEnemy': 'a great enemy'}[rel] ?? rel} of your Lagna lord ${_p(lagnaLord)}',
            'आपके लग्नेश ${_p(lagnaLord)} का ${const {'greatFriend': 'अधिमित्र', 'friend': 'मित्र', 'neutral': 'सम', 'enemy': 'शत्रु', 'greatEnemy': 'अधिशत्रु'}[rel] ?? rel} है',
          );
    final dateLabel = '${L10n.weekday(d.date.weekday)}, ${d.date.day} ${L10n.month(d.date.month)} ${d.date.year}';
    blocks.add(
      AnalysisBlock(
        key: 'date',
        title: tr('Date and Day', 'दिनांक और वार'),
        summary: '$dateLabel — ${RashifalTables.varaSignificance[d.weekday].t}',
        points: [
          tr('Day lord ${_p(vl)} $relText and transits the ${VedicMath.ordinal(d.fromMoon(vl))} from your Moon.', 'वार स्वामी ${_p(vl)} $relText और आपके चन्द्र से ${d.fromMoon(vl)}वें भाव में है।'),
          tr(
            'Sunrise ${d.hm(d.sunrise)}, sunset ${d.hm(d.sunset)} at ${d.place.name} (UTC${d.offset >= 0 ? '+' : ''}${_fmtOffset(d.offset)}).',
            '${d.place.name} में सूर्योदय ${d.hm(d.sunrise)}, सूर्यास्त ${d.hm(d.sunset)} (UTC${d.offset >= 0 ? '+' : ''}${_fmtOffset(d.offset)})।',
          ),
        ],
      ),
    );

    final tithi = p['tithi'] as Map, nak = p['nakshatra'] as Map, yoga = p['yoga'] as Map, karana = p['karana'] as Map, paksha = p['paksha'] as Map;
    String ends(double? jd) => jd == null ? tr('all day', 'पूरे दिन') : tr('until ${d.hmDay(jd)}', '${d.hmDay(jd)} तक');
    final tt = RashifalTables.tithiType[d.tithiType]!;
    blocks.add(
      AnalysisBlock(
        key: 'panchang',
        title: tr('Today\'s Panchang', 'आज का पंचांग'),
        summary: tr(
          'Udaya tithi ${tithi['name']} (${tt.$1.$1}) — suited to ${tt.$2.$1}. Nakshatra ${nak['name']}, yoga ${yoga['en']}, karana ${karana['en']}.',
          'उदया तिथि ${tithi['hindi']} (${tt.$1.$2}) — ${tt.$2.$2} के लिए उपयुक्त। नक्षत्र ${nak['hindi']}, योग ${yoga['hi']}, करण ${karana['hi']}।',
        ),
        table: [
          [tr('Element', 'अंग'), tr('Today', 'आज'), tr('Details', 'विवरण')],
          [tr('Tithi', 'तिथि'), L10n.hi ? '${tithi['hindi']}' : '${tithi['name']}', '${L10n.hi ? paksha['hi'] : paksha['en']}, ${ends(d.tithiEnds)}'],
          [tr('Vara', 'वार'), L10n.hi ? '${(p['vara'] as Map)['hindi']}' : '${(p['vara'] as Map)['name']}', '${tr('Lord', 'स्वामी')}: ${_p(vl)}'],
          [tr('Nakshatra', 'नक्षत्र'), '${L10n.nakshatra(d.nak)} ${nak['pada']}', '${tr('Lord', 'स्वामी')}: ${_p(VedicMath.nakshatras[d.nak].lord)}, ${ends(d.nakEnds)}'],
          [tr('Yoga', 'योग'), L10n.hi ? '${yoga['hi']}' : '${yoga['en']}', RashifalTables.badYogas.contains(d.yogaIdx) ? tr('Inauspicious', 'अशुभ') : tr('Auspicious', 'शुभ')],
          [tr('Karana', 'करण'), L10n.hi ? '${karana['hi']}' : '${karana['en']}', d.vishti ? tr('Bhadra — avoid beginnings', 'भद्रा — आरंभ से बचें') : tr('At sunrise', 'सूर्योदय पर')],
        ],
        points: [
          '${tr('Sunrise', 'सूर्योदय')} ${p['sunrise']} · ${tr('Sunset', 'सूर्यास्त')} ${p['sunset']}',
          '${tr('Rahu Kaal', 'राहु काल')} ${(p['rahuKaal'] as Map)['start']}–${(p['rahuKaal'] as Map)['end']} · ${tr('Yamaganda', 'यमगण्ड')} ${(p['yamaganda'] as Map)['start']}–${(p['yamaganda'] as Map)['end']} · ${tr('Gulika', 'गुलिक')} ${(p['gulikaKaal'] as Map)['start']}–${(p['gulikaKaal'] as Map)['end']}',
        ],
      ),
    );

    final rashi = VedicMath.rashis[d.moonRashi];
    final mood = RashifalEngine._elementMood[rashi.element]!;
    blocks.add(
      AnalysisBlock(
        key: 'moonSign',
        title: tr('Moon Sign (Chandra Rashi)', 'चन्द्र राशि'),
        summary: tr(
          'The Moon is in ${rashi.name} (${rashi.element.toLowerCase()} sign ruled by ${_p(rashi.lord)}) today, favouring ${mood.$1}.',
          'आज चन्द्रमा ${rashi.hindi} (${L10n.element(rashi.element)} तत्व, स्वामी ${_p(rashi.lord)}) में है, जो ${mood.$2} के पक्ष में है।',
        ),
        points: [
          tr(
            'Moon at ${VedicMath.formatDegree(d.moonLon)} ${rashi.name}, ${d.waxing ? 'waxing' : 'waning'} (${d.moonSunAngle.toStringAsFixed(0)}° from the Sun).',
            'चन्द्रमा ${rashi.hindi} ${VedicMath.formatDegree(d.moonLon)} पर, ${d.waxing ? 'शुक्ल पक्ष' : 'कृष्ण पक्ष'} (सूर्य से ${d.moonSunAngle.toStringAsFixed(0)}°)।',
          ),
          if (d.moonSignChange != null)
            tr(
              'The Moon enters ${VedicMath.rashis[(d.moonRashi + 1) % 12].name} at ${d.hmDay(d.moonSignChange!)}.',
              'चन्द्रमा ${d.hmDay(d.moonSignChange!)} पर ${VedicMath.rashis[(d.moonRashi + 1) % 12].hindi} में प्रवेश करेगा।',
            ),
          tr(
            'Your Janma Rashi is ${L10n.sign(n.moonRashi)}; today\'s Moon sign is ${VedicMath.ordinal(d.moonFromJanma)} from it.',
            'आपकी जन्म राशि ${L10n.sign(n.moonRashi)} है; आज की चन्द्र राशि उससे ${d.moonFromJanma}वीं है।',
          ),
        ],
      ),
    );

    final mh = d.moonFromJanma, ml = d.moonFromLagna;
    blocks.add(
      AnalysisBlock(
        key: 'moonTransit',
        title: tr('Moon Transit', 'चन्द्र गोचर'),
        summary: tr(
          'The Moon transits the ${VedicMath.ordinal(mh)} house from your Janma Rashi (${RashifalEngine._houseMeaning[mh - 1].$1}) and the ${VedicMath.ordinal(ml)} from your Lagna (${RashifalEngine._houseMeaning[ml - 1].$1}).',
          'चन्द्रमा आपकी जन्म राशि से $mhवें भाव (${RashifalEngine._houseMeaning[mh - 1].$2}) और लग्न से $mlवें भाव (${RashifalEngine._houseMeaning[ml - 1].$2}) में गोचर कर रहा है।',
        ),
        points: [
          d.chandrashtama
              ? tr('Chandrashtama — the most sensitive Moon position of the month.', 'चन्द्राष्टम — महीने की सबसे संवेदनशील चन्द्र स्थिति।')
              : RashifalEngine._chandraGood.contains(mh)
              ? tr('Chandra Bala: favourable.', 'चन्द्र बल: शुभ।')
              : d.chandraGood
              ? tr('Chandra Bala: mildly favourable (waxing Moon in the 2nd, 5th or 9th).', 'चन्द्र बल: हल्का शुभ (शुक्ल पक्ष का चन्द्रमा 2, 5 या 9वें भाव में)।')
              : tr('Chandra Bala: weak.', 'चन्द्र बल: कमज़ोर।'),
          tr(
            'Moon\'s own Ashtakavarga: ${n.av.bindusFor('moon', d.moonRashi)} bindus; Sarvashtakavarga ${n.av.sarva[d.moonRashi]} in ${rashi.name}.',
            'चन्द्र अष्टकवर्ग: ${n.av.bindusFor('moon', d.moonRashi)} बिंदु; ${rashi.hindi} में सर्वाष्टकवर्ग ${n.av.sarva[d.moonRashi]}।',
          ),
        ],
      ),
    );

    final good = d.transits.where((t) => d.favourable(t.planet)).map((t) => _p(t.planet)).toList();
    blocks.add(
      AnalysisBlock(
        key: 'gochar',
        title: tr('Planetary Transits (Gochar)', 'ग्रह गोचर'),
        summary: tr(
          '${good.length} of 9 grahas transit favourable houses from your Moon${good.isEmpty ? '' : ': ${L10n.join(good)}'}.',
          '9 में से ${good.length} ग्रह आपके चन्द्र से शुभ भावों में हैं${good.isEmpty ? '' : ': ${L10n.join(good)}'}।',
        ),
        table: [
          [tr('Graha', 'ग्रह'), tr('Sign', 'राशि'), tr('Nakshatra', 'नक्षत्र'), tr('From Moon', 'चन्द्र से'), tr('From Lagna', 'लग्न से'), tr('Bindus', 'बिंदु'), tr('Effect', 'प्रभाव')],
          for (final pl in RashifalEngine._grahas)
            () {
              final t = d.transit(pl);
              final r = d.skyRashi(pl);
              return [
                '${_p(pl)}${d.sky.isRetrograde(pl) ? tr(' (R)', ' (व)') : ''}',
                '${L10n.sign(r)} ${VedicMath.formatDegree(t.sid)}',
                L10n.nakshatra(VedicMath.nakshatraIndex(t.sid)),
                '${t.houseFromMoon}',
                '${t.houseFromLagna}',
                n.av.bhinna.containsKey(pl) ? '${n.av.bindusFor(pl, r)}' : '—',
                t.effect,
              ];
            }(),
        ],
      ),
    );

    final aspects = _aspectPoints();
    blocks.add(
      AnalysisBlock(
        key: 'drishti',
        title: tr('Planetary Aspects (Drishti)', 'ग्रह दृष्टि'),
        summary: aspects.isEmpty
            ? tr('No major transit aspects or conjunctions on your natal points today.', 'आज आपके जन्म बिंदुओं पर कोई प्रमुख गोचर दृष्टि या युति नहीं।')
            : tr(
                'Transit contacts with your birth chart, strongest first (Parashari sign aspects; orb = distance from the exact aspect point).',
                'आपकी जन्म कुंडली से गोचर संबंध, प्रबलतम पहले (पाराशरी राशि दृष्टि; अंतर = सटीक दृष्टि बिंदु से दूरी)।',
              ),
        points: aspects,
      ),
    );

    final bn = VedicMath.nakshatras[n.birthNakshatra];
    final tn = VedicMath.nakshatras[d.nak];
    final tara = RashifalTables.taras[d.tara - 1];
    final nat = RashifalTables.natures[RashifalTables.nakshatraNature[d.nak]];
    blocks.add(
      AnalysisBlock(
        key: 'nakshatra',
        title: tr('Nakshatra Analysis', 'नक्षत्र विश्लेषण'),
        summary: tr(
          'Today\'s ${tn.name} is the ${VedicMath.ordinal(d.tara)} tara — ${tara.$1.$1} — from your birth star ${bn.name}: ${tara.$2 > 0 ? 'supportive' : (tara.$2 < 0 ? 'cautionary' : 'mixed')}.',
          'आज का ${tn.hindi} आपके जन्म नक्षत्र ${bn.hindi} से ${d.tara}वाँ तारा — ${tara.$1.$2} — है: ${tara.$2 > 0 ? 'सहायक' : (tara.$2 < 0 ? 'सावधानी वाला' : 'मिश्रित')}।',
        ),
        points: [
          tr(
            'Birth nakshatra: ${bn.name} pada ${VedicMath.pada(n.moonLon)}, lord ${_p(bn.lord)}, deity ${bn.deity}, ${bn.gana} gana.',
            'जन्म नक्षत्र: ${bn.hindi} पाद ${VedicMath.pada(n.moonLon)}, स्वामी ${_p(bn.lord)}, देवता ${bn.deity}, ${bn.gana} गण।',
          ),
          tr(
            'Today\'s nakshatra: ${tn.name}, lord ${_p(tn.lord)}, deity ${tn.deity} — ${nat.$1.$1}: ${nat.$2.$1}',
            'आज का नक्षत्र: ${tn.hindi}, स्वामी ${_p(tn.lord)}, देवता ${tn.deity} — ${nat.$1.$2}: ${nat.$2.$2}',
          ),
          tr(
            'Nakshatra lord ${_p(tn.lord)} transits the ${VedicMath.ordinal(d.fromMoon(tn.lord))} from your Moon (${d.favourable(tn.lord) ? 'favourable' : 'unfavourable'}).',
            'नक्षत्र स्वामी ${_p(tn.lord)} आपके चन्द्र से ${d.fromMoon(tn.lord)}वें भाव में (${d.favourable(tn.lord) ? 'शुभ' : 'अशुभ'})।',
          ),
          if (RashifalTables.gandaMoola.contains(d.nak)) tr('${tn.name} is a Ganda Moola nakshatra.', '${tn.hindi} गंड मूल नक्षत्र है।'),
        ],
      ),
    );

    final levels = [tr('Mahadasha', 'महादशा'), tr('Antardasha', 'अंतर्दशा'), tr('Pratyantar', 'प्रत्यंतर')];
    blocks.add(
      AnalysisBlock(
        key: 'dasha',
        title: tr('Dasha Analysis', 'दशा विश्लेषण'),
        summary: d.dasha.isEmpty
            ? tr('The date is outside the computed Vimshottari periods.', 'यह तिथि गणना की गई विंशोत्तरी दशा से बाहर है।')
            : tr(
                'Running ${d.dasha.take(3).map((x) => _p(x.lord)).join(' / ')} (Vimshottari). ${d.dasha.length > 2 ? 'The Pratyantar lord ${_p(d.dasha[2].lord)} colours the day most directly.' : ''}',
                'चल रही दशा ${d.dasha.take(3).map((x) => _p(x.lord)).join(' / ')} (विंशोत्तरी)। ${d.dasha.length > 2 ? 'प्रत्यंतर स्वामी ${_p(d.dasha[2].lord)} दिन को सबसे सीधे प्रभावित करता है।' : ''}',
              ),
        table: [
          [tr('Level', 'स्तर'), tr('Lord', 'स्वामी'), tr('Period', 'अवधि'), tr('Natal house', 'जन्म भाव'), tr('Rules', 'भाव स्वामित्व'), tr('Transit', 'गोचर')],
          for (int i = 0; i < d.dasha.length && i < 3; i++)
            [
              levels[i],
              _p(d.dasha[i].lord),
              '${d.dasha[i].startDate} – ${d.dasha[i].endDate}',
              '${n.houseOf(d.dasha[i].lord)} (${L10n.dignity(PlanetaryDignity.getAdvancedDignity(d.dasha[i].lord, n.rashiOf(d.dasha[i].lord), {for (final e in n.chart.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)}))})',
              n.housesRuledBy(d.dasha[i].lord).isEmpty ? '—' : n.housesRuledBy(d.dasha[i].lord).join(', '),
              '${d.fromMoon(d.dasha[i].lord)} ${d.favourable(d.dasha[i].lord) ? '✓' : '✗'}',
            ],
        ],
        points: [
          for (int i = 0; i < d.dasha.length && i < 3; i++)
            tr(
              '${levels[i]} lord ${_p(d.dasha[i].lord)}: Navamsa (D9) ${VedicMath.rashis[n.d9[d.dasha[i].lord]!].name}, Dashamsa (D10) ${VedicMath.rashis[n.d10[d.dasha[i].lord]!].name}${n.vargottama.contains(d.dasha[i].lord) ? ', vargottama' : ''}.',
              '${levels[i]} स्वामी ${_p(d.dasha[i].lord)}: नवांश (D9) ${VedicMath.rashis[n.d9[d.dasha[i].lord]!].hindi}, दशमांश (D10) ${VedicMath.rashis[n.d10[d.dasha[i].lord]!].hindi}${n.vargottama.contains(d.dasha[i].lord) ? ', वर्गोत्तम' : ''}।',
            ),
        ],
      ),
    );

    final ranked = [...RashifalEngine._grahas]..sort((a, b) => d.strength[b]!.compareTo(d.strength[a]!));
    final ben = ranked.where((x) => d.strength[x]! > 0).map(_p).toList();
    final mal = ranked.where((x) => d.strength[x]! < 0).map(_p).toList();
    blocks.add(
      AnalysisBlock(
        key: 'strength',
        title: tr('Daily Planetary Strength', 'दैनिक ग्रह बल'),
        summary: tr(
          'Benefic today: ${ben.isEmpty ? 'none' : L10n.join(ben)}. Challenging: ${mal.isEmpty ? 'none' : L10n.join(mal)}.',
          'आज शुभ: ${ben.isEmpty ? 'कोई नहीं' : L10n.join(ben)}। प्रतिकूल: ${mal.isEmpty ? 'कोई नहीं' : L10n.join(mal)}।',
        ),
        table: [
          [tr('Graha', 'ग्रह'), tr('Today', 'आज'), tr('Score', 'अंक'), tr('Natal Shadbala', 'जन्म षड्बल'), tr('Reasons', 'कारण')],
          for (final pl in ranked)
            [
              _p(pl),
              _statusOf(d.strength[pl]!),
              '${d.strength[pl]! > 0 ? '+' : ''}${d.strength[pl]}',
              n.shadbala?.planets[pl] == null ? '—' : '${n.shadbala!.planets[pl]!.ratio.toStringAsFixed(2)}×',
              d.strengthNotes[pl]!.join(', '),
            ],
        ],
      ),
    );

    final pos = dayF.where((x) => x.w > 0).toList()..sort((a, b) => b.w.compareTo(a.w));
    final neg = dayF.where((x) => x.w < 0).toList()..sort((a, b) => a.w.compareTo(b.w));
    blocks.add(
      AnalysisBlock(
        key: 'energy',
        title: tr('Today\'s Overall Energy', 'आज की समग्र ऊर्जा'),
        summary: tr(
          '${rating.label} day ($score/100). ${pos.isEmpty ? '' : 'Main support: ${pos.first.text}. '}${neg.isEmpty ? '' : 'Main challenge: ${neg.first.text}.'}',
          '${rating.label} दिन ($score/100)। ${pos.isEmpty ? '' : 'मुख्य सहारा: ${pos.first.text}। '}${neg.isEmpty ? '' : 'मुख्य चुनौती: ${neg.first.text}।'}',
        ),
        points: [
          for (final x in [...pos, ...neg]) '${x.w > 0 ? '+' : '−'}${x.w.abs()}  ${x.text}',
        ],
      ),
    );

    blocks.add(_supporting());
    return blocks;
  }

  AnalysisBlock _supporting() {
    final points = <String>[];
    if (full) {
      try {
        final yogas = YogasMath.forChart(n.chart, gender: n.gender, atJd: d.sky.jd).where((y) => y.formed && y.strength != 'Secondary').toList();
        final active = yogas.where((y) => y.active).map((y) => L10n.hi ? y.hindi : y.name).toList();
        final other = yogas.where((y) => !y.active).map((y) => L10n.hi ? y.hindi : y.name).take(6).toList();
        if (active.isNotEmpty) points.add(tr('Yogas activated by the running Dasha: ${active.join(', ')}', 'चल रही दशा से सक्रिय योग: ${active.join(', ')}'));
        if (other.isNotEmpty) points.add(tr('Other natal yogas: ${other.join(', ')}', 'अन्य जन्म योग: ${other.join(', ')}'));
      } catch (_) {}
    }
    final sade = DoshasMath.computeSadesati(n.moonRashi, d.skyRashi('saturn'));
    points.add(
      sade.present ? tr('Shani Sade Sati: ${sade.conditions.join(', ')}', 'शनि साढ़े साती: ${sade.conditions.join(', ')}') : tr('Shani Sade Sati is not running.', 'शनि साढ़े साती नहीं चल रही।'),
    );
    if (n.doshas.isNotEmpty) {
      points.add(tr('Natal doshas to keep in mind: ${n.doshas.map((x) => x.name).join(', ')}', 'ध्यान रखने योग्य जन्म दोष: ${n.doshas.map((x) => x.hindi).join(', ')}'));
    } else {
      points.add(tr('No major natal dosha is present.', 'कोई प्रमुख जन्म दोष नहीं है।'));
    }
    if (n.vargottama.isNotEmpty) {
      points.add(tr('Vargottama (same sign in D1 and D9, extra strength): ${n.vargottama.map(_p).join(', ')}', 'वर्गोत्तम (D1 और D9 में एक ही राशि, अतिरिक्त बल): ${n.vargottama.map(_p).join(', ')}'));
    }
    final houses = [for (int h = 1; h <= 12; h++) (h, n.av.sarvaInHouse(h))]..sort((a, b) => b.$2.compareTo(a.$2));
    points.add(
      tr(
        'Strongest houses by Sarvashtakavarga: ${houses.take(3).map((x) => '${x.$1} (${x.$2})').join(', ')}; weakest: ${houses.reversed.take(2).map((x) => '${x.$1} (${x.$2})').join(', ')}',
        'सर्वाष्टकवर्ग से प्रबल भाव: ${houses.take(3).map((x) => '${x.$1} (${x.$2})').join(', ')}; कमज़ोर: ${houses.reversed.take(2).map((x) => '${x.$1} (${x.$2})').join(', ')}',
      ),
    );
    final groups = <int, List<String>>{};
    for (final pl in RashifalEngine._grahas) {
      groups.putIfAbsent(n.rashiOf(pl), () => []).add(pl);
    }
    for (final g in groups.entries.where((e) => e.value.length > 1)) {
      points.add(
        tr(
          'Natal conjunction in house ${VedicMath.houseOf(g.key, n.lagna)}: ${g.value.map(_p).join(' + ')}${g.value.any((pl) => d.dasha.any((x) => x.lord == pl)) ? ' (activated by the Dasha)' : ''}',
          'भाव ${VedicMath.houseOf(g.key, n.lagna)} में जन्म युति: ${g.value.map(_p).join(' + ')}${g.value.any((pl) => d.dasha.any((x) => x.lord == pl)) ? ' (दशा से सक्रिय)' : ''}',
        ),
      );
    }
    return AnalysisBlock(
      key: 'supporting',
      title: tr('Yogas, Doshas, Vargas & Ashtakavarga', 'योग, दोष, वर्ग और अष्टकवर्ग'),
      summary: tr('Natal factors that shape how today\'s transits work for you.', 'वे जन्म कारक जो तय करते हैं कि आज के गोचर आप पर कैसे काम करेंगे।'),
      points: points,
    );
  }

  static String _fmtOffset(double h) {
    final m = (h.abs() * 60).round();
    return '${h < 0 ? '-' : ''}${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------

  RashifalComputation build() {
    final dayF = _dayFactors();
    final score = _score(50, dayF);
    final rating = DayRating.fromScore(score);
    final reasons = _top(dayF, 5);
    final areas = <RashifalSection>[
      RashifalSection(
        key: 'overall',
        title: tr('How will the day be', 'आज का दिन कैसा रहेगा'),
        text: RashifalEngine._areaAdvice['overall']![rating.index].t,
        score: score,
        rating: rating,
        factors: reasons,
      ),
      for (final k in RashifalEngine.areaDefs.keys) _area(k, score),
    ];
    final slots = _slots();
    final finance = areas.firstWhere((a) => a.key == 'finance').score!;
    final outlook = [_muhurat(slots), _travel(), _finance(finance), _unexpected()];
    final keyPlanet = _keyPlanet();
    final remedies = _remedies(keyPlanet, slots);
    final analysis = _analysis(score, rating, dayF);

    final lifeAreas = areas.skip(1).toList()..sort((a, b) => b.score!.compareTo(a.score!));
    final best = lifeAreas.first, worst = lifeAreas.last;
    final colour = remedies.firstWhere((s) => s.key == 'colour').extra['name']!;
    final shubh = slots.where((s) => s.quality == 'good' && s.note != tr('Night', 'रात्रि') && !s.name.startsWith(tr('Brahma', 'ब्रह्म'))).firstOrNull;
    final rahu = slots.firstWhere((s) => s.name == tr('Rahu Kaal', 'राहु काल'));
    final shortTitle = {
      'family': tr('family', 'परिवार'),
      'marriage': tr('relationships', 'संबंध'),
      'health': tr('health', 'स्वास्थ्य'),
      'career': tr('work', 'कार्य'),
      'mind': tr('peace of mind', 'मन की शांति'),
      'finance': tr('money', 'धन'),
      'social': tr('social life', 'सामाजिक जीवन'),
    };
    final line1 = best.score! - worst.score! < 6
        ? tr('${rating.label} day ($score/100) — balanced across all areas.', '${rating.label} दिन ($score/100) — सभी क्षेत्रों में संतुलन।')
        : tr(
            '${rating.label} day ($score/100) — best for ${shortTitle[best.key]}, care with ${shortTitle[worst.key]}.',
            '${rating.label} दिन ($score/100) — ${shortTitle[best.key]} के लिए श्रेष्ठ, ${shortTitle[worst.key]} में सावधानी।',
          );
    final line2 = tr(
      'Colour: $colour · ${shubh == null ? '' : 'Shubh ${shubh.range} · '}Rahu Kaal ${rahu.range}',
      'रंग: $colour · ${shubh == null ? '' : 'शुभ ${shubh.range} · '}राहु काल ${rahu.range}',
    );
    // Lead with the factor that best explains the rating.
    final lead = ([...dayF.where((x) => rating == DayRating.good ? x.w > 0 : (rating == DayRating.bad ? x.w < 0 : true))]..sort((a, b) => b.w.abs().compareTo(a.w.abs()))).firstOrNull;
    final headline = lead == null ? tr('${rating.label} day', '${rating.label} दिन') : tr('${rating.label} day — ${lead.text}', '${rating.label} दिन — ${lead.text}');

    final report = DailyRashifalReport(
      profileId: n.profileId,
      profileName: n.name,
      dateKey: dateKeyOf(d.date),
      lang: L10n.lang,
      placeName: d.place.name,
      score: score,
      rating: rating,
      headline: headline,
      dayReasons: reasons,
      notificationLine1: line1,
      notificationLine2: line2,
      areas: areas,
      outlook: outlook,
      remedies: remedies,
      timeSlots: slots,
      analysis: analysis,
      generatedAt: DateTime.now(),
    );
    return RashifalComputation(report, full ? _context(report, dayF, keyPlanet) : '');
  }

  /// English data sheet of the day for the AI (independent of the app language).
  String _context(DailyRashifalReport r, List<_F> dayF, String keyPlanet) {
    final b = StringBuffer();
    final p = d.panchang;
    String sign(int i) => VedicMath.rashis[i].name;
    String hm(double? jd) => jd == null ? 'all day' : d.hmDay(jd);
    b.writeln(
      'DATE: ${PanchangMath.varas[d.weekday]['name']}, ${r.dateKey}; place ${d.place.name} (lat ${d.place.lat.toStringAsFixed(2)}, lon ${d.place.lon.toStringAsFixed(2)}, UTC${d.offset >= 0 ? '+' : ''}${_fmtOffset(d.offset)}).',
    );
    b.writeln('Sunrise ${d.hm(d.sunrise)}, sunset ${d.hm(d.sunset)}.');
    b.writeln(
      'PANCHANG at sunrise: tithi ${(p['tithi'] as Map)['name']} (${d.tithiType}, ${(p['paksha'] as Map)['en']}) ends ${hm(d.tithiEnds)}; '
      'vara ${(p['vara'] as Map)['name']} (lord ${_en(RashifalTables.varaLord[d.weekday])}); nakshatra ${VedicMath.nakshatras[d.nak].name} pada ${(p['nakshatra'] as Map)['pada']} ends ${hm(d.nakEnds)}; '
      'yoga ${PanchangMath.yogas[d.yogaIdx]}${RashifalTables.badYogas.contains(d.yogaIdx) ? ' (inauspicious)' : ''}; karana ${d.karanaEn}.',
    );
    b.writeln(
      'MOON TODAY: ${sign(d.moonRashi)} ${VedicMath.formatDegree(d.moonLon)}, ${d.waxing ? 'waxing' : 'waning'}, ${d.moonSunAngle.toStringAsFixed(0)} deg from Sun; '
      '${d.moonFromJanma} from Janma Rashi ${sign(n.moonRashi)}, ${d.moonFromLagna} from Lagna ${sign(n.lagna)}; '
      'Chandra Bala ${d.chandrashtama ? 'CHANDRASHTAMA' : (d.chandraGood ? 'favourable' : 'weak')}; '
      'Tara ${d.tara} ${RashifalTables.taras[d.tara - 1].$1.$1}${d.moonSignChange != null ? '; enters ${sign((d.moonRashi + 1) % 12)} at ${d.hmDay(d.moonSignChange!)}' : ''}.',
    );
    b.writeln('BIRTH NAKSHATRA: ${VedicMath.nakshatras[n.birthNakshatra].name}.');
    b.writeln('GOCHAR (house from Moon / from Lagna / own-BAV bindus / day strength):');
    for (final pl in RashifalEngine._grahas) {
      final t = d.transit(pl);
      final rr = d.skyRashi(pl);
      b.writeln(
        '- ${_en(pl)} ${sign(rr)} ${VedicMath.formatDegree(t.sid)}${d.sky.isRetrograde(pl) ? ' R' : ''}${d.combust(pl) ? ' combust' : ''}: '
        '${t.houseFromMoon}/${t.houseFromLagna}/${n.av.bhinna.containsKey(pl) ? n.av.bindusFor(pl, rr) : '-'}/${d.strength[pl]! > 0 ? '+' : ''}${d.strength[pl]}'
        '${d.favourable(pl) ? ' favourable' : ' unfavourable'}',
      );
    }
    b.writeln('DASHA on this date: ${d.dasha.take(3).map((x) => '${_en(x.lord)} (${x.startDate} to ${x.endDate})').join(' > ')}.');
    final sat = d.fromMoon('saturn');
    b.writeln('SATURN from Moon: $sat${const [12, 1, 2].contains(sat) ? ' (Sade Sati)' : (sat == 8 ? ' (Ashtama Shani)' : (sat == 4 ? ' (Kantaka Shani)' : ''))}.');
    b.writeln('SAV by house from Lagna: ${[for (int h = 1; h <= 12; h++) '$h:${n.av.sarvaInHouse(h)}'].join(' ')}.');
    b.writeln('NATAL DOSHAS: ${n.doshas.isEmpty ? 'none' : n.doshas.map((x) => x.name).join(', ')}. VARGOTTAMA: ${n.vargottama.isEmpty ? 'none' : n.vargottama.map(_en).join(', ')}.');
    b.writeln('D9 / D10 signs: ${RashifalEngine._grahas.map((pl) => '${_en(pl)} ${sign(n.d9[pl]!)}/${sign(n.d10[pl]!)}').join('; ')}.');
    final analysis = r.analysis.firstWhere((a) => a.key == 'drishti');
    if (analysis.points.isNotEmpty) b.writeln('TRANSIT CONTACTS: ${analysis.points.join(' | ')}');
    final supporting = r.analysis.firstWhere((a) => a.key == 'supporting');
    b.writeln('SUPPORTING: ${supporting.points.join(' | ')}');
    b.writeln(
      'ENGINE SCORES (0-100, keep these ratings): day ${r.score} ${r.rating.name}; '
      '${[...r.areas.skip(1), ...r.outlook.where((s) => s.score != null)].map((s) => '${s.key} ${s.score} ${s.rating!.name}').join('; ')}.',
    );
    b.writeln('TIME WINDOWS: ${r.timeSlots.map((s) => '${s.name} ${s.range} [${s.quality}]').join('; ')}.');
    b.writeln('Disha Shool: ${RashifalTables.dishaShool[d.weekday].$1}. Remedy planet chosen by the engine: ${_en(keyPlanet)}.');
    return b.toString().trim();
  }
}
