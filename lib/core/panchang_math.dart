import 'ephemeris.dart';
import 'vedic_math.dart';

class Tithi {
  final int number;
  final String name;
  final String hindi;
  final String type;

  const Tithi(this.number, this.name, this.hindi, this.type);
}

class PanchangMath {
  static const List<Tithi> tithis = [
    Tithi(1, 'Pratipada', 'प्रतिपदा', 'Nanda'), Tithi(2, 'Dwitiya', 'द्वितीया', 'Bhadra'),
    Tithi(3, 'Tritiya', 'तृतीया', 'Jaya'), Tithi(4, 'Chaturthi', 'चतुर्थी', 'Rikta'),
    Tithi(5, 'Panchami', 'पञ्चमी', 'Purna'), Tithi(6, 'Shashthi', 'षष्ठी', 'Nanda'),
    Tithi(7, 'Saptami', 'सप्तमी', 'Bhadra'), Tithi(8, 'Ashtami', 'अष्टमी', 'Jaya'),
    Tithi(9, 'Navami', 'नवमी', 'Rikta'), Tithi(10, 'Dashami', 'दशमी', 'Purna'),
    Tithi(11, 'Ekadashi', 'एकादशी', 'Nanda'), Tithi(12, 'Dwadashi', 'द्वादशी', 'Bhadra'),
    Tithi(13, 'Trayodashi', 'त्रयोदशी', 'Jaya'), Tithi(14, 'Chaturdashi', 'चतुर्दशी', 'Rikta'),
    Tithi(15, 'Purnima', 'पूर्णिमा', 'Purna'), Tithi(30, 'Amavasya', 'अमावस्या', 'Rikta'),
  ];

  static const List<Map<String, dynamic>> varas = [
    {'n': 0, 'name': 'Sunday', 'hindi': 'रविवार', 'lord': 'Sun'},
    {'n': 1, 'name': 'Monday', 'hindi': 'सोमवार', 'lord': 'Moon'},
    {'n': 2, 'name': 'Tuesday', 'hindi': 'मंगलवार', 'lord': 'Mars'},
    {'n': 3, 'name': 'Wednesday', 'hindi': 'बुधवार', 'lord': 'Mercury'},
    {'n': 4, 'name': 'Thursday', 'hindi': 'गुरुवार', 'lord': 'Jupiter'},
    {'n': 5, 'name': 'Friday', 'hindi': 'शुक्रवार', 'lord': 'Venus'},
    {'n': 6, 'name': 'Saturday', 'hindi': 'शनिवार', 'lord': 'Saturn'},
  ];

  static const List<String> yogas = ['Vishkambha','Priti','Ayushman','Saubhagya','Shobhana','Atiganda','Sukarma','Dhriti','Shula','Ganda','Vriddhi','Dhruva','Vyaghata','Harshana','Vajra','Siddhi','Vyatipata','Variyana','Parigha','Shiva','Siddha','Sadhya','Shubha','Shukla','Brahma','Indra','Vaidhriti'];
  static const List<String> yogasH = ['विष्कम्भ','प्रीति','आयुष्मान','सौभाग्य','शोभन','अतिगण्ड','सुकर्मा','धृति','शूल','गण्ड','वृद्धि','ध्रुव','व्याघात','हर्षण','वज्र','सिद्धि','व्यतीपात','वरीयान','परिघ','शिव','सिद्ध','साध्य','शुभ','शुक्ल','ब्रह्म','इन्द्र','वैधृति'];
  static const List<String> karanas = ['Bava','Balava','Kaulava','Taitila','Garija','Vanija','Vishti','Shakuni','Chatushpada','Naga','Kimstughna'];
  static const List<String> karanasH = ['बव','बालव','कौलव','तैतिल','गरज','वणिज','विष्टि','शकुनि','चतुष्पाद','नाग','किंस्तुघ्न'];

  /// Karana names in the order they occur within a lunar month (60 half-tithis):
  /// Kimstughna, then Bava..Vishti repeated 8 times, then Shakuni, Chatushpada, Naga.
  static int karanaIndexForHalfTithi(int halfTithi) {
    if (halfTithi == 0) return 10; // Kimstughna
    if (halfTithi >= 57) return 7 + (halfTithi - 57); // Shakuni, Chatushpada, Naga
    return (halfTithi - 1) % 7; // Bava .. Vishti
  }

  // Portions (1/8 of daytime, 0-based) by weekday, Sunday first.
  static const List<int> rahuKaalPart = [7, 1, 6, 4, 5, 3, 2];
  static const List<int> gulikaPart = [6, 5, 4, 3, 2, 1, 0];
  static const List<int> yamagandaPart = [4, 3, 2, 1, 0, 6, 5];

  static String fmtTime(double h) {
    final int totalMin = ((h % 24 + 24) % 24 * 60).round() % (24 * 60);
    final int hh = totalMin ~/ 60;
    final int mm = totalMin % 60;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  /// Local clock hour (0-24) of a UT Julian day.
  static double _localHour(double jd, double utcOffset) {
    final double x = jd + 0.5 + utcOffset / 24;
    return (x - x.floor()) * 24;
  }

  /// Weekday (0 = Sunday) of the local civil date containing [jd].
  static int civilWeekday(double jd, double utcOffset) => ((jd + 1.5 + utcOffset / 24).floor()) % 7;

  static Map<String, dynamic> computePanchang(ChartData chartData, double lat, double lon, double utcOffset) {
    final double jd = chartData.jd;
    final double sunSid = chartData.planetLongitudes['sun']!;
    final double moonSid = chartData.planetLongitudes['moon']!;

    // Sunrise/sunset of the local civil day.
    final double localMidnight = (jd + 0.5 + utcOffset / 24).floor() - 0.5 - utcOffset / 24;
    final double? sunrise = Ephemeris.nextSunrise(localMidnight, lat, lon);
    final double? sunset = sunrise == null ? null : Ephemeris.nextSunset(sunrise, lat, lon);

    // Vedic day (vara) runs from sunrise to sunrise.
    int dayOfWeek = civilWeekday(jd, utcOffset);
    if (sunrise != null && jd < sunrise) dayOfWeek = (dayOfWeek + 6) % 7;
    final Map<String, dynamic> vara = varas[dayOfWeek];

    // Tithi
    final double moonSunAngle = VedicMath.norm360(moonSid - sunSid);
    final int tithiNum = (moonSunAngle / 12).floor() + 1;
    final int tithiIdx = tithiNum <= 15 ? tithiNum - 1 : (tithiNum == 30 ? 15 : tithiNum - 16);
    final Tithi tithiObj = tithis[tithiIdx];
    final Map<String, dynamic> tithi = {'num': tithiNum, 'name': tithiObj.name, 'hindi': tithiObj.hindi, 'type': tithiObj.type};
    final Map<String, String> paksha = tithiNum <= 15 ? {'en': 'Shukla (Bright)', 'hi': 'शुक्ल पक्ष'} : {'en': 'Krishna (Dark)', 'hi': 'कृष्ण पक्ष'};

    // Nakshatra
    final int nakIdx = VedicMath.nakshatraIndex(moonSid);
    final Nakshatra nakObj = VedicMath.nakshatras[nakIdx];
    final Map<String, dynamic> nak = {
      'name': nakObj.name, 'hindi': nakObj.hindi, 'lord': VedicMath.planets[nakObj.lord]!.name,
      'deity': nakObj.deity, 'pada': VedicMath.pada(moonSid)
    };

    // Yoga
    final int yogaIdx = (VedicMath.norm360(sunSid + moonSid) / (360 / 27)).floor();
    final Map<String, String> yoga = {'en': yogas[yogaIdx], 'hi': yogasH[yogaIdx]};

    // Karana
    final int karanaIdx = karanaIndexForHalfTithi((moonSunAngle / 6).floor());
    final Map<String, String> karana = {'en': karanas[karanaIdx], 'hi': karanasH[karanaIdx]};

    Map<String, String> part(List<int> table) {
      if (sunrise == null || sunset == null) return {'start': '--:--', 'end': '--:--'};
      final double len = sunset - sunrise;
      final int k = table[civilWeekday(localMidnight + 0.5, utcOffset)];
      return {
        'start': fmtTime(_localHour(sunrise + len * k / 8, utcOffset)),
        'end': fmtTime(_localHour(sunrise + len * (k + 1) / 8, utcOffset)),
      };
    }

    return {
      'tithi': tithi,
      'paksha': paksha,
      'vara': vara,
      'nakshatra': nak,
      'yoga': yoga,
      'karana': karana,
      'sunrise': sunrise == null ? '--:--' : fmtTime(_localHour(sunrise, utcOffset)),
      'sunset': sunset == null ? '--:--' : fmtTime(_localHour(sunset, utcOffset)),
      'rahuKaal': part(rahuKaalPart),
      'gulikaKaal': part(gulikaPart),
      'yamaganda': part(yamagandaPart),
    };
  }
}
