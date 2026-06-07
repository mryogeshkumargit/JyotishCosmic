import 'dart:math' as math;
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
    {'n': 0, 'name': 'Sunday', 'hindi': 'रविवार', 'lord': 'sun'},
    {'n': 1, 'name': 'Monday', 'hindi': 'सोमवार', 'lord': 'moon'},
    {'n': 2, 'name': 'Tuesday', 'hindi': 'मंगलवार', 'lord': 'mars'},
    {'n': 3, 'name': 'Wednesday', 'hindi': 'बुधवार', 'lord': 'mercury'},
    {'n': 4, 'name': 'Thursday', 'hindi': 'गुरुवार', 'lord': 'jupiter'},
    {'n': 5, 'name': 'Friday', 'hindi': 'शुक्रवार', 'lord': 'venus'},
    {'n': 6, 'name': 'Saturday', 'hindi': 'शनिवार', 'lord': 'saturn'},
  ];

  static const List<String> yogas = ['Vishkambha','Priti','Ayushman','Saubhagya','Shobhana','Atiganda','Sukarma','Dhriti','Shula','Ganda','Vriddhi','Dhruva','Vyaghata','Harshana','Vajra','Siddhi','Vyatipata','Variyana','Parigha','Shiva','Siddha','Sadhya','Shubha','Shukla','Brahma','Indra','Vaidhriti'];
  static const List<String> yogasH = ['विष्कम्भ','प्रीति','आयुष्मान','सौभाग्य','शोभन','अतिगण्ड','सुकर्मा','धृति','शूल','गण्ड','वृद्धि','ध्रुव','व्याघात','हर्षण','वज्र','सिद्धि','व्यतीपात','वरीयान','परिघ','शिव','सिद्ध','साध्य','शुभ','शुक्ल','ब्रह्म','इन्द्र','वैधृति'];
  static const List<String> karanas = ['Bava','Balava','Kaulava','Taitila','Garija','Vanija','Vishti','Shakuni','Chatushpada','Naga','Kimstughna'];
  static const List<String> karanasH = ['बव','बालव','कौलव','तैतिल','गरज','वणिज','विष्टि','शकुनि','चतुष्पाद','नाग','किंस्तुघ्न'];

  static const List<List<double>> rahuFrac = [
    [0.875, 1], [0.125, 0.25], [0.875, 1], [0.5, 0.625],
    [0.625, 0.75], [0.375, 0.5], [0.25, 0.375]
  ];

  static String _fmtTime(double h) {
    int hh = h.floor() % 24;
    int mm = ((h % 1) * 60).floor();
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  static Map<String, double> sunriseSunset(double jd, double lat, double lon) {
    double d = jd - 2451545.0;
    double g = VedicMath.norm360(357.529 + 0.9856003 * d);
    double l = VedicMath.norm360(280.459 + 0.9856474 * d + 1.915 * math.sin(g * math.pi / 180) + 0.02 * math.sin(2 * g * math.pi / 180));
    double e = 23.439 - 0.0000004 * d;
    double sinDec = math.sin(e * math.pi / 180) * math.sin(l * math.pi / 180);
    double dec = math.asin(sinDec) * 180 / math.pi;
    
    double cosH = (math.sin(-0.8333 * math.pi / 180) - math.sin(lat * math.pi / 180) * math.sin(dec * math.pi / 180)) / 
                  (math.cos(lat * math.pi / 180) * math.cos(dec * math.pi / 180));
    
    if (cosH < -1 || cosH > 1) return {'sunrise': 6.0, 'sunset': 18.0};
    
    double hDeg = math.acos(cosH) * 180 / math.pi;
    return {'sunrise': 12.0 - hDeg / 15.0 + lon / 15.0, 'sunset': 12.0 + hDeg / 15.0 + lon / 15.0};
  }

  static Map<String, dynamic> computePanchang(ChartData chartData, double lat, double lon, double utcOffset) {
    double jd = chartData.jd;
    double sunSid = chartData.planetLongitudes['sun']!;
    double moonSid = chartData.planetLongitudes['moon']!;

    int dayOfWeek = (jd + 1.5).floor() % 7;
    Map<String, dynamic> vara = varas[dayOfWeek];

    // Tithi
    double moonSunAngle = VedicMath.norm360(moonSid - sunSid);
    int tithiNum = (moonSunAngle / 12).floor() + 1;
    int tithiIdx = tithiNum <= 15 ? tithiNum - 1 : (tithiNum == 30 ? 15 : tithiNum - 16);
    Tithi tithiObj = tithis[math.min(tithiIdx, 15)];
    Map<String, dynamic> tithi = {'num': tithiNum, 'name': tithiObj.name, 'hindi': tithiObj.hindi, 'type': tithiObj.type};
    Map<String, String> paksha = tithiNum <= 15 ? {'en': 'Shukla (Bright)', 'hi': 'शुक्ल पक्ष'} : {'en': 'Krishna (Dark)', 'hi': 'कृष्ण पक्ष'};

    // Nakshatra
    int nakIdx = VedicMath.nakshatraIndex(moonSid);
    int padaNo = VedicMath.pada(moonSid);
    Nakshatra nakObj = VedicMath.nakshatras[nakIdx];
    Map<String, dynamic> nak = {
      'name': nakObj.name, 'hindi': nakObj.hindi, 'lord': nakObj.lord,
      'deity': nakObj.deity, 'pada': padaNo
    };

    // Yoga
    int yogaIdx = (VedicMath.norm360(sunSid + moonSid) / (360 / 27)).floor();
    Map<String, String> yoga = {'en': yogas[yogaIdx], 'hi': yogasH[yogaIdx]};

    // Karana
    int karanaIdx = ((moonSunAngle / 6).floor()) % 11;
    Map<String, String> karana = {'en': karanas[karanaIdx], 'hi': karanasH[karanaIdx]};

    // Sunrise/Sunset
    var srss = sunriseSunset(jd, lat, lon);
    double srUTC = srss['sunrise']!;
    double ssUTC = srss['sunset']!;
    String sunriseStr = _fmtTime(srUTC + utcOffset);
    String sunsetStr = _fmtTime(ssUTC + utcOffset);
    double dayLen = ssUTC - srUTC;

    // Rahu Kaal
    double r1 = rahuFrac[dayOfWeek][0];
    double r2 = rahuFrac[dayOfWeek][1];
    Map<String, String> rahuKaal = {
      'start': _fmtTime(srUTC + r1 * dayLen + utcOffset),
      'end': _fmtTime(srUTC + r2 * dayLen + utcOffset)
    };

    // Gulika
    List<List<int>> gulikaFractions = [[6, 7], [5, 6], [4, 5], [3, 4], [2, 3], [1, 2], [0, 1]];
    double g1 = gulikaFractions[dayOfWeek][0] / 8.0;
    double g2 = gulikaFractions[dayOfWeek][1] / 8.0;
    Map<String, String> gulikaKaal = {
      'start': _fmtTime(srUTC + g1 * dayLen + utcOffset),
      'end': _fmtTime(srUTC + g2 * dayLen + utcOffset)
    };

    return {
      'tithi': tithi,
      'paksha': paksha,
      'vara': vara,
      'nakshatra': nak,
      'yoga': yoga,
      'karana': karana,
      'sunrise': sunriseStr,
      'sunset': sunsetStr,
      'rahuKaal': rahuKaal,
      'gulikaKaal': gulikaKaal,
    };
  }
}
