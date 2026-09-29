import 'astro_engine.dart';
import 'ephemeris.dart';
import 'vedic_math.dart';

class Tithi {
  final int number;
  final String name;
  final String hindi;
  final String type;

  const Tithi(this.number, this.name, this.hindi, this.type);
}

/// A time window in local civil time.
class TimeWindow {
  final double startJd; // UT
  final double endJd; // UT
  final double utcOffset;
  const TimeWindow(this.startJd, this.endJd, this.utcOffset);

  String get start => PanchangMath.formatTime(startJd, utcOffset);
  String get end => PanchangMath.formatTime(endJd, utcOffset);
  @override
  String toString() => '$start – $end';
}

/// One of the five limbs with the moment it ends.
class PanchangElement {
  final int index; // 0-based index into its list
  final String name;
  final String hindi;
  final double? endsAtJd; // UT; null if not computed
  final String extra;
  const PanchangElement(this.index, this.name, this.hindi, {this.endsAtJd, this.extra = ''});
}

class PanchangResult {
  final double jd; // moment the panchang is computed for (UT)
  final double utcOffset;
  final DateTime localDate;

  final PanchangElement tithi;
  final String tithiType; // Nanda/Bhadra/Jaya/Rikta/Purna
  final String paksha; // 'Shukla' or 'Krishna'
  final PanchangElement nakshatra;
  final int nakshatraPada;
  final PanchangElement yoga;
  final PanchangElement karana;
  final int varaIndex; // 0 = Sunday
  final String varaName;
  final String varaHindi;
  final String varaLord;

  final double? sunriseJd;
  final double? sunsetJd;
  final double? nextSunriseJd;
  final double? moonriseJd;
  final double? moonsetJd;

  final TimeWindow? rahuKaal;
  final TimeWindow? yamaganda;
  final TimeWindow? gulikaKaal;
  final TimeWindow? abhijit;

  final int sunRashi;
  final int moonRashi;

  const PanchangResult({
    required this.jd,
    required this.utcOffset,
    required this.localDate,
    required this.tithi,
    required this.tithiType,
    required this.paksha,
    required this.nakshatra,
    required this.nakshatraPada,
    required this.yoga,
    required this.karana,
    required this.varaIndex,
    required this.varaName,
    required this.varaHindi,
    required this.varaLord,
    required this.sunriseJd,
    required this.sunsetJd,
    required this.nextSunriseJd,
    required this.moonriseJd,
    required this.moonsetJd,
    required this.rahuKaal,
    required this.yamaganda,
    required this.gulikaKaal,
    required this.abhijit,
    required this.sunRashi,
    required this.moonRashi,
  });

  String time(double? jdUt) => jdUt == null ? '—' : PanchangMath.formatTime(jdUt, utcOffset);
}

class PanchangMath {
  static const List<String> tithiNames = [
    'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami', 'Shashthi', 'Saptami',
    'Ashtami', 'Navami', 'Dashami', 'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi',
  ];
  static const List<String> tithiNamesH = [
    'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पञ्चमी', 'षष्ठी', 'सप्तमी',
    'अष्टमी', 'नवमी', 'दशमी', 'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी',
  ];
  static const List<String> tithiTypes = ['Nanda', 'Bhadra', 'Jaya', 'Rikta', 'Purna'];

  /// Kept for backwards compatibility with older screens.
  static const List<Tithi> tithis = [
    Tithi(1, 'Pratipada', 'प्रतिपदा', 'Nanda'), Tithi(2, 'Dwitiya', 'द्वितीया', 'Bhadra'),
    Tithi(3, 'Tritiya', 'तृतीया', 'Jaya'), Tithi(4, 'Chaturthi', 'चतुर्थी', 'Rikta'),
    Tithi(5, 'Panchami', 'पञ्चमी', 'Purna'), Tithi(6, 'Shashthi', 'षष्ठी', 'Nanda'),
    Tithi(7, 'Saptami', 'सप्तमी', 'Bhadra'), Tithi(8, 'Ashtami', 'अष्टमी', 'Jaya'),
    Tithi(9, 'Navami', 'नवमी', 'Rikta'), Tithi(10, 'Dashami', 'दशमी', 'Purna'),
    Tithi(11, 'Ekadashi', 'एकादशी', 'Nanda'), Tithi(12, 'Dwadashi', 'द्वादशी', 'Bhadra'),
    Tithi(13, 'Trayodashi', 'त्रयोदशी', 'Jaya'), Tithi(14, 'Chaturdashi', 'चतुर्दशी', 'Rikta'),
    Tithi(15, 'Purnima', 'पूर्णिमा', 'Purna'), Tithi(30, 'Amavasya', 'अमावस्या', 'Purna'),
  ];

  static const List<Map<String, String>> varas = [
    {'name': 'Sunday', 'hindi': 'रविवार', 'lord': 'sun'},
    {'name': 'Monday', 'hindi': 'सोमवार', 'lord': 'moon'},
    {'name': 'Tuesday', 'hindi': 'मंगलवार', 'lord': 'mars'},
    {'name': 'Wednesday', 'hindi': 'बुधवार', 'lord': 'mercury'},
    {'name': 'Thursday', 'hindi': 'गुरुवार', 'lord': 'jupiter'},
    {'name': 'Friday', 'hindi': 'शुक्रवार', 'lord': 'venus'},
    {'name': 'Saturday', 'hindi': 'शनिवार', 'lord': 'saturn'},
  ];

  static const List<String> yogas = ['Vishkambha','Priti','Ayushman','Saubhagya','Shobhana','Atiganda','Sukarma','Dhriti','Shula','Ganda','Vriddhi','Dhruva','Vyaghata','Harshana','Vajra','Siddhi','Vyatipata','Variyana','Parigha','Shiva','Siddha','Sadhya','Shubha','Shukla','Brahma','Indra','Vaidhriti'];
  static const List<String> yogasH = ['विष्कम्भ','प्रीति','आयुष्मान','सौभाग्य','शोभन','अतिगण्ड','सुकर्मा','धृति','शूल','गण्ड','वृद्धि','ध्रुव','व्याघात','हर्षण','वज्र','सिद्धि','व्यतीपात','वरीयान','परिघ','शिव','सिद्ध','साध्य','शुभ','शुक्ल','ब्रह्म','इन्द्र','वैधृति'];

  /// The 7 movable (chara) karanas repeat 8 times; the 4 fixed (sthira) karanas occur once.
  static const List<String> movableKaranas = ['Bava', 'Balava', 'Kaulava', 'Taitila', 'Gara', 'Vanija', 'Vishti'];
  static const List<String> movableKaranasH = ['बव', 'बालव', 'कौलव', 'तैतिल', 'गर', 'वणिज', 'विष्टि (भद्रा)'];

  /// Name of the karana for half-tithi number [k] (0..59) counted from the new moon.
  static String karanaName(int k, {bool hindi = false}) {
    k = k % 60;
    if (k == 0) return hindi ? 'किंस्तुघ्न' : 'Kimstughna';
    if (k == 57) return hindi ? 'शकुनि' : 'Shakuni';
    if (k == 58) return hindi ? 'चतुष्पाद' : 'Chatushpada';
    if (k == 59) return hindi ? 'नाग' : 'Naga';
    final i = (k - 1) % 7;
    return hindi ? movableKaranasH[i] : movableKaranas[i];
  }

  /// 1-based eighth of the daytime ruled by Rahu Kaal, Yamaganda and Gulika, indexed by weekday
  /// (0 = Sunday).
  static const List<int> rahuKaalPart = [8, 2, 7, 5, 6, 4, 3];
  static const List<int> yamagandaPart = [5, 4, 3, 2, 1, 7, 6];
  static const List<int> gulikaPart = [7, 6, 5, 4, 3, 2, 1];

  static String formatTime(double jdUt, double utcOffset) {
    final dt = Ephemeris.jdToDateTime(jdUt + utcOffset / 24.0);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String formatDateTime(double jdUt, double utcOffset) {
    final dt = Ephemeris.jdToDateTime(jdUt + utcOffset / 24.0);
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${m[dt.month - 1]}, ${formatTime(jdUt, utcOffset)}';
  }

  /// Tithi (1..30) from the Moon–Sun elongation in degrees.
  static int tithiNumber(double elongation) => (VedicMath.norm360(elongation) / 12).floor() + 1;

  static String tithiName(int n) {
    if (n == 15) return 'Purnima';
    if (n == 30) return 'Amavasya';
    return tithiNames[(n - 1) % 15];
  }

  static String tithiNameHindi(int n) {
    if (n == 15) return 'पूर्णिमा';
    if (n == 30) return 'अमावस्या';
    return tithiNamesH[(n - 1) % 15];
  }

  static String tithiType(int n) => tithiTypes[(n - 1) % 5];

  /// Panchang for today at a place.
  static PanchangResult today(double lat, double lon, double utcOffset) =>
      compute(Ephemeris.nowJD(), lat, lon, utcOffset);

  /// Panchang for a birth chart moment.
  static PanchangResult forChart(ChartData chart) =>
      compute(chart.jd, chart.lat, chart.lon, chart.utcOffset);

  /// Full panchang for the moment [jdUt] at a place. The vara and the day's muhurta windows
  /// follow the Hindu day, which runs from sunrise to the next sunrise.
  static PanchangResult compute(double jdUt, double lat, double lon, double utcOffset) {
    // --- Hindu day: find the sunrise that starts the day containing jdUt.
    final localJd = jdUt + utcOffset / 24.0;
    final localMidnightUt = (localJd - 0.5).floor() + 0.5 - utcOffset / 24.0;
    double? sunrise = AstroEngine.nextSunrise(localMidnightUt, lat, lon);
    var civilDay = Ephemeris.jdToDateTime(localMidnightUt + utcOffset / 24.0 + 0.01);
    if (sunrise != null && jdUt < sunrise) {
      // Before today's sunrise: the Hindu day began at yesterday's sunrise.
      final prev = AstroEngine.nextSunrise(localMidnightUt - 1, lat, lon);
      if (prev != null) sunrise = prev;
      civilDay = civilDay.subtract(const Duration(days: 1));
    }
    final dayStart = sunrise ?? (localMidnightUt + 0.25);
    final sunset = AstroEngine.nextSunset(dayStart, lat, lon);
    final nextSunrise = AstroEngine.nextSunrise(dayStart + 0.1, lat, lon);
    final moonrise = AstroEngine.nextMoonrise(dayStart, lat, lon);
    final moonset = AstroEngine.nextMoonset(dayStart, lat, lon);

    final varaIndex = civilDay.weekday % 7; // DateTime: Monday=1..Sunday=7 -> Sunday=0
    final vara = varas[varaIndex];

    // --- Five limbs at the moment.
    final sunSid = AstroEngine.planet(jdUt, 'sun').longitude;
    final moonSid = AstroEngine.planet(jdUt, 'moon').longitude;
    final elong = VedicMath.norm360(moonSid - sunSid);

    double elongAt(double jd) =>
        AstroEngine.planet(jd, 'moon').longitude - AstroEngine.planet(jd, 'sun').longitude;
    double moonAt(double jd) => AstroEngine.planet(jd, 'moon').longitude;
    double sumAt(double jd) =>
        AstroEngine.planet(jd, 'moon').longitude + AstroEngine.planet(jd, 'sun').longitude;

    final tNum = tithiNumber(elong);
    final tithiEnd = AstroEngine.findAngle(jdUt, tNum * 12.0, elongAt, rate: 12.19);
    final tithi = PanchangElement(tNum - 1, tithiName(tNum), tithiNameHindi(tNum), endsAtJd: tithiEnd);

    final span = 360 / 27;
    final nIdx = VedicMath.nakshatraIndex(moonSid);
    final nakEnd = AstroEngine.findAngle(jdUt, (nIdx + 1) * span, moonAt, rate: 13.18);
    final nakObj = VedicMath.nakshatras[nIdx];
    final nakshatra = PanchangElement(nIdx, nakObj.name, nakObj.hindi,
        endsAtJd: nakEnd, extra: 'Lord: ${VedicMath.planets[nakObj.lord]!.name}');

    final yIdx = (VedicMath.norm360(sunSid + moonSid) / span).floor();
    final yogaEnd = AstroEngine.findAngle(jdUt, (yIdx + 1) * span, sumAt, rate: 14.17);
    final yoga = PanchangElement(yIdx, yogas[yIdx], yogasH[yIdx], endsAtJd: yogaEnd);

    final kIdx = (elong / 6).floor();
    final karanaEnd = AstroEngine.findAngle(jdUt, (kIdx + 1) * 6.0, elongAt, rate: 12.19);
    final karana = PanchangElement(kIdx, karanaName(kIdx), karanaName(kIdx, hindi: true),
        endsAtJd: karanaEnd);

    // --- Muhurta windows (daytime divided in 8 / 15 parts).
    TimeWindow? rahu, yama, gulika, abhijit;
    final double? sr = sunrise;
    if (sr != null && sunset != null) {
      final double part = (sunset - sr) / 8;
      TimeWindow eighth(int n) => TimeWindow(sr + (n - 1) * part, sr + n * part, utcOffset);
      rahu = eighth(rahuKaalPart[varaIndex]);
      yama = eighth(yamagandaPart[varaIndex]);
      gulika = eighth(gulikaPart[varaIndex]);
      final double muhurta = (sunset - sr) / 15;
      abhijit = TimeWindow(sr + 7 * muhurta, sr + 8 * muhurta, utcOffset);
    }

    return PanchangResult(
      jd: jdUt,
      utcOffset: utcOffset,
      localDate: civilDay,
      tithi: tithi,
      tithiType: tithiType(tNum),
      paksha: tNum <= 15 ? 'Shukla' : 'Krishna',
      nakshatra: nakshatra,
      nakshatraPada: VedicMath.pada(moonSid),
      yoga: yoga,
      karana: karana,
      varaIndex: varaIndex,
      varaName: vara['name']!,
      varaHindi: vara['hindi']!,
      varaLord: vara['lord']!,
      sunriseJd: sunrise,
      sunsetJd: sunset,
      nextSunriseJd: nextSunrise,
      moonriseJd: moonrise,
      moonsetJd: moonset,
      rahuKaal: rahu,
      yamaganda: yama,
      gulikaKaal: gulika,
      abhijit: abhijit,
      sunRashi: VedicMath.rashiIndex(sunSid),
      moonRashi: VedicMath.rashiIndex(moonSid),
    );
  }
}
