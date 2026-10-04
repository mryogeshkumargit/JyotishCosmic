import 'l10n.dart';
import 'planetary_dignity.dart';
import 'vedic_math.dart';

class DoshaResult {
  /// Stable identifier ('manglik', 'kaalsarp'...).
  final String id;
  final String name;
  final String hindi;
  final bool present;

  /// 'High', 'Medium' or 'Low' (Manglik only).
  final String severity;
  final List<String> exceptions;
  final List<String> conditions;
  final String description;
  final List<String> remedies;

  /// What it means in everyday words, for this chart.
  final List<String> simple;

  DoshaResult({
    this.id = '',
    required this.name,
    required this.hindi,
    required this.present,
    this.severity = '',
    this.exceptions = const [],
    this.conditions = const [],
    required this.description,
    required this.remedies,
    this.simple = const [],
  });

  /// Name in the app language.
  String get title => L10n.hi ? hindi : name;

  String get severityLabel => switch (severity) {
        'High' => tr('High', 'अधिक'),
        'Medium' => tr('Medium', 'मध्यम'),
        'Low' => tr('Low', 'कम'),
        _ => severity,
      };
}

/// Doshas (afflictions) with their classical or traditional rules.
///
/// Kemadruma is classical (BPHS, Phaladeepika ch. 6). Manglik, Kaal Sarp,
/// Pitru, Grahan and Guru Chandal come from later and popular traditions; the
/// explanations say so, because many people worry about them unnecessarily.
class DoshasMath {
  static String _p(String p) => L10n.planet(p);

  static DoshaResult? computeManglik(Map<String, double> planetLongitudes, int lagnaRashi) {
    if (!planetLongitudes.containsKey('mars')) return null;
    final marsRashi = VedicMath.rashiIndex(planetLongitudes['mars']!);
    final moonRashi = planetLongitudes.containsKey('moon') ? VedicMath.rashiIndex(planetLongitudes['moon']!) : null;
    final venusRashi = planetLongitudes.containsKey('venus') ? VedicMath.rashiIndex(planetLongitudes['venus']!) : null;

    const mangHouses = [1, 2, 4, 7, 8, 12];
    final fl = VedicMath.houseOf(marsRashi, lagnaRashi);
    final fm = moonRashi != null ? VedicMath.houseOf(marsRashi, moonRashi) : null;
    final fv = venusRashi != null ? VedicMath.houseOf(marsRashi, venusRashi) : null;

    final dl = mangHouses.contains(fl);
    final dm = fm != null && mangHouses.contains(fm);
    final dv = fv != null && mangHouses.contains(fv);

    final exceptions = <String>[];
    final planetRashis = <String, int>{};
    planetLongitudes.forEach((p, sid) => planetRashis[p] = VedicMath.rashiIndex(sid));
    final dignity = PlanetaryDignity.getAdvancedDignity('mars', marsRashi, planetRashis);

    if (dignity == 'Exalted') exceptions.add(tr('Mars is exalted (cancelled/reduced)', 'मंगल उच्च का है (दोष भंग/कम)'));
    if (dignity == 'Own Sign' || dignity == 'Moolatrikona') {
      exceptions.add(tr('Mars is in its own sign (cancelled/reduced)', 'मंगल स्वराशि में है (दोष भंग/कम)'));
    }
    if (planetLongitudes.containsKey('jupiter')) {
      final jupRashi = VedicMath.rashiIndex(planetLongitudes['jupiter']!);
      if (jupRashi == marsRashi) exceptions.add(tr('Jupiter conjunct Mars', 'गुरु मंगल के साथ'));
      if (VedicMath.houseOf(jupRashi, lagnaRashi) == 1) exceptions.add(tr('Jupiter in Lagna', 'गुरु लग्न में'));
    }

    final severityCount = [dl, dm, dv].where((e) => e).length;
    final severity = severityCount == 3 ? 'High' : severityCount == 2 ? 'Medium' : severityCount == 1 ? 'Low' : '';
    final formed = dl || dm || dv;
    final present = formed && exceptions.isEmpty;

    return DoshaResult(
      id: 'manglik',
      name: 'Manglik Dosha',
      hindi: 'मांगलिक दोष',
      present: present,
      severity: severity,
      exceptions: exceptions,
      conditions: [
        if (dl) tr('Mars in house $fl from Lagna', 'लग्न से $flवें भाव में मंगल'),
        if (dm) tr('Mars in house $fm from Moon', 'चन्द्र से $fmवें भाव में मंगल'),
        if (dv) tr('Mars in house $fv from Venus', 'शुक्र से $fvवें भाव में मंगल'),
      ],
      description: tr('Mars in the 1st, 2nd, 4th, 7th, 8th or 12th house (from Lagna, Moon or Venus) — traditionally said to affect marital harmony.',
          'लग्न, चन्द्र या शुक्र से 1, 2, 4, 7, 8 या 12वें भाव में मंगल — परंपरा के अनुसार वैवाहिक सामंजस्य पर असर।'),
      remedies: [
        tr('Worship Hanuman on Tuesdays', 'मंगलवार को हनुमान जी की पूजा करें'),
        tr('Recite the Mangal Stotra daily', 'प्रतिदिन मंगल स्तोत्र का पाठ करें'),
        tr('Red Coral gemstone (consult an astrologer)', 'मूंगा रत्न (ज्योतिषी से सलाह लेकर)'),
        tr('Kumbh Vivah before marriage', 'विवाह से पहले कुंभ विवाह'),
        tr('Donate red lentils on Tuesdays', 'मंगलवार को मसूर दाल का दान करें'),
      ],
      simple: present
          ? [
              tr('Mars is the planet of energy and drive. When it sits in a marriage-related house, it can bring impatience, arguments or a strong will in married life.',
                  'मंगल ऊर्जा और जोश का ग्रह है। जब यह विवाह से जुड़े भाव में होता है, तो वैवाहिक जीवन में अधीरता, बहस या ज़िद ला सकता है।'),
              tr('Your level is ${severity == 'High' ? 'high' : (severity == 'Medium' ? 'medium' : 'low')} (counted from ${[if (dl) tr('Lagna', 'लग्न'), if (dm) tr('Moon', 'चन्द्र'), if (dv) tr('Venus', 'शुक्र')].join(', ')}).',
                  'आपका स्तर ${severity == 'High' ? 'अधिक' : (severity == 'Medium' ? 'मध्यम' : 'कम')} है (${[if (dl) 'लग्न', if (dm) 'चन्द्र', if (dv) 'शुक्र'].join(', ')} से गिना गया)।'),
              tr('Traditionally it is balanced by marrying a partner who is also Manglik, and its effect is said to soften with age. It is a tendency, not a guarantee of marriage problems.',
                  'परंपरा में यह मांगलिक जीवनसाथी से विवाह करने पर संतुलित माना जाता है और उम्र के साथ इसका असर कम होता है। यह एक प्रवृत्ति है, वैवाहिक समस्या की गारंटी नहीं।'),
            ]
          : [
              formed
                  ? tr('Mars is in a Manglik house, but the dosha is cancelled (${exceptions.join('; ')}), so it is not considered a problem.',
                      'मंगल मांगलिक भाव में है, पर दोष भंग है (${exceptions.join('; ')}), इसलिए इसे समस्या नहीं माना जाता।')
                  : tr('Mars is not in a Manglik house, so you are not Manglik.', 'मंगल मांगलिक भाव में नहीं है, इसलिए आप मांगलिक नहीं हैं।'),
            ],
    );
  }

  static DoshaResult? computeKaalSarp(Map<String, double> longs, int lagnaRashi) {
    if (!longs.containsKey('rahu') || !longs.containsKey('ketu')) return null;
    final rd = longs['rahu']!;
    const planets7 = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    final between = <String>[];
    final outside = <String>[];
    for (final p in planets7) {
      if (!longs.containsKey(p)) continue;
      if (VedicMath.norm360(longs[p]! - rd) < 180) {
        between.add(p);
      } else {
        outside.add(p);
      }
    }

    const types = ['Anant', 'Kulik', 'Vasuki', 'Shankhapal', 'Padma', 'Mahapadma', 'Takshak', 'Karkotak', 'Shankhachood', 'Ghatak', 'Vishdhar', 'Sheshnaag'];
    const typesHi = ['अनंत', 'कुलिक', 'वासुकि', 'शंखपाल', 'पद्म', 'महापद्म', 'तक्षक', 'कर्कोटक', 'शंखचूड़', 'घातक', 'विषधर', 'शेषनाग'];
    // The type is named after Rahu's house from the Lagna (Anant = 1st ... Sheshnaag = 12th).
    final rahuHouse = VedicMath.houseOf(VedicMath.rashiIndex(rd), lagnaRashi);
    final present = outside.isEmpty || between.isEmpty;
    final ketuHouse = (rahuHouse + 5) % 12 + 1;

    return DoshaResult(
      id: 'kaalsarp',
      name: 'Kaal Sarp Dosha',
      hindi: 'काल सर्प दोष',
      present: present,
      conditions: [tr('Type: ${types[rahuHouse - 1]} (Rahu in house $rahuHouse)', 'प्रकार: ${typesHi[rahuHouse - 1]} (राहु $rahuHouseवें भाव में)')],
      description: tr('All seven planets between Rahu and Ketu — traditionally linked with obstacles and sudden ups and downs.',
          'सभी सात ग्रह राहु और केतु के बीच — परंपरा में रुकावटों और अचानक उतार-चढ़ाव से जोड़ा जाता है।'),
      remedies: [
        tr('Shiva worship on Mondays', 'सोमवार को शिव पूजा'),
        tr('Kaal Sarp Shanti puja (e.g. at Trimbakeshwar)', 'काल सर्प शांति पूजा (जैसे त्र्यंबकेश्वर में)'),
        tr('Maha Mrityunjaya Mantra 108 times', 'महामृत्युंजय मंत्र 108 बार'),
        tr('Silver bangle on the left wrist', 'बाएँ हाथ में चांदी का कड़ा'),
        tr('Donate food on Saturdays', 'शनिवार को अन्न दान'),
      ],
      simple: present
          ? [
              tr('All seven planets fall on one side of the Rahu–Ketu axis. This rule is not in the classical texts like BPHS; it comes from later tradition.',
                  'सभी सात ग्रह राहु-केतु अक्ष के एक ओर हैं। यह नियम BPHS जैसे शास्त्रीय ग्रंथों में नहीं है; यह बाद की परंपरा से आया है।'),
              tr('It is usually read as a life with sudden turns: delays or struggles first, then success through persistence. Many successful people have it.',
                  'इसे प्रायः अचानक मोड़ वाले जीवन के रूप में पढ़ा जाता है: पहले देरी या संघर्ष, फिर लगन से सफलता। कई सफल लोगों की कुंडली में यह होता है।'),
              tr('The areas involved are the ${L10n.house(rahuHouse)} (${_area(rahuHouse)}) and the ${L10n.house(ketuHouse)} (${_area(ketuHouse)}).',
                  'जुड़े हुए क्षेत्र ${L10n.house(rahuHouse)} (${_area(rahuHouse)}) और ${L10n.house(ketuHouse)} (${_area(ketuHouse)}) हैं।'),
            ]
          : [
              tr('The planets are on both sides of the Rahu–Ketu axis, so there is no Kaal Sarp Dosha.', 'ग्रह राहु-केतु अक्ष के दोनों ओर हैं, इसलिए काल सर्प दोष नहीं है।'),
            ],
    );
  }

  static String _area(int h) => tr(_houseAreas[h - 1].$1, _houseAreas[h - 1].$2);
  static const List<(String, String)> _houseAreas = [
    ('self', 'स्वयं'), ('money & family', 'धन व परिवार'), ('courage & effort', 'साहस व प्रयास'), ('home & mother', 'घर व माता'),
    ('children & intellect', 'संतान व बुद्धि'), ('work & competition', 'काम व प्रतियोगिता'), ('marriage & partners', 'विवाह व साझेदारी'),
    ('sudden change', 'अचानक परिवर्तन'), ('luck & dharma', 'भाग्य व धर्म'), ('career', 'करियर'), ('gains & friends', 'लाभ व मित्र'),
    ('expenses & foreign', 'खर्च व विदेश'),
  ];

  static DoshaResult computeSadesati(int moonRashi, int saturnRashi) {
    final prev = (moonRashi - 1 + 12) % 12;
    final next = (moonRashi + 1) % 12;
    int phase = 0;
    if (saturnRashi == prev) {
      phase = 1;
    } else if (saturnRashi == moonRashi) {
      phase = 2;
    } else if (saturnRashi == next) {
      phase = 3;
    }
    final phaseText = switch (phase) {
      1 => tr('Rising (1st phase)', 'आरंभ (पहला चरण)'),
      2 => tr('Peak (2nd phase)', 'चरम (दूसरा चरण)'),
      3 => tr('Setting (3rd phase)', 'उतार (तीसरा चरण)'),
      _ => '',
    };
    // Saturn is friendly to the signs of Venus and Mercury and owns Capricorn/Aquarius.
    final mild = const [1, 2, 5, 6, 9, 10].contains(moonRashi);

    return DoshaResult(
      id: 'sadesati',
      name: 'Shani Sadesati',
      hindi: 'शनि साढ़े साती',
      present: phase != 0,
      conditions: phase != 0 ? [phaseText] : [],
      description: tr('Saturn transiting the 12th, 1st and 2nd from the Moon sign — about 7½ years of tests and restructuring.',
          'चन्द्र राशि से 12वें, पहले और दूसरे भाव में शनि का गोचर — लगभग साढ़े सात वर्ष की परीक्षा और पुनर्गठन।'),
      remedies: [
        tr('Shani worship on Saturdays', 'शनिवार को शनि पूजा'),
        tr('Chant "Om Sham Shanaishcharaya Namah" 108 times', '"ॐ शं शनैश्चराय नमः" 108 बार जपें'),
        tr('Mustard oil lamp under a peepal tree on Saturdays', 'शनिवार को पीपल के नीचे सरसों के तेल का दीपक'),
        tr('Donate black sesame and cloth on Saturdays', 'शनिवार को काले तिल और वस्त्र का दान'),
        tr('Feed crows and birds', 'कौओं और पक्षियों को भोजन'),
      ],
      simple: phase != 0
          ? [
              tr('Saturn is now passing close to your Moon sign. This 7½-year period asks for patience, discipline and hard work; responsibilities grow and shortcuts stop working.',
                  'शनि अभी आपकी चन्द्र राशि के पास से गुज़र रहा है। यह साढ़े सात साल का समय धैर्य, अनुशासन और मेहनत माँगता है; ज़िम्मेदारियाँ बढ़ती हैं और शॉर्टकट काम नहीं करते।'),
              switch (phase) {
                1 => tr('You are in the first phase: pressure usually shows in expenses, sleep and plans.', 'आप पहले चरण में हैं: दबाव प्रायः खर्च, नींद और योजनाओं में दिखता है।'),
                2 => tr('You are in the peak phase: it touches health, mind and personal life most directly, so pace yourself.', 'आप चरम चरण में हैं: यह स्वास्थ्य, मन और निजी जीवन को सबसे सीधे छूता है, इसलिए संयम से चलें।'),
                _ => tr('You are in the last phase: pressure moves to money and family matters and then eases.', 'आप अंतिम चरण में हैं: दबाव धन और परिवार के मामलों में जाता है और फिर कम होता है।'),
              },
              if (mild)
                tr('Saturn is friendly to your Moon sign, so this Sade Sati is traditionally milder and can even bring promotion through effort.',
                    'शनि आपकी चन्द्र राशि का मित्र है, इसलिए परंपरा के अनुसार यह साढ़े साती हल्की रहती है और मेहनत से उन्नति भी दे सकती है।'),
            ]
          : [tr('Saturn is not near your Moon sign now, so Sade Sati is not running.', 'शनि अभी आपकी चन्द्र राशि के पास नहीं है, इसलिए साढ़े साती नहीं चल रही।')],
    );
  }

  static DoshaResult computePitruDosha(Map<String, double> longs, int lagnaRashi) {
    final conditions = <String>[];
    if (longs.containsKey('sun') && longs.containsKey('rahu')) {
      if (VedicMath.rashiIndex(longs['sun']!) == VedicMath.rashiIndex(longs['rahu']!)) conditions.add(tr('Sun conjunct Rahu', 'सूर्य राहु के साथ'));
      if (VedicMath.houseOf(VedicMath.rashiIndex(longs['sun']!), lagnaRashi) == 9) conditions.add(tr('Sun in the 9th house', 'सूर्य नौवें भाव में'));
    }
    if (longs.containsKey('sun') && longs.containsKey('saturn')) {
      if (VedicMath.rashiIndex(longs['sun']!) == VedicMath.rashiIndex(longs['saturn']!)) conditions.add(tr('Sun conjunct Saturn', 'सूर्य शनि के साथ'));
    }
    if (longs.containsKey('moon') && longs.containsKey('rahu')) {
      if (VedicMath.rashiIndex(longs['moon']!) == VedicMath.rashiIndex(longs['rahu']!)) conditions.add(tr('Moon conjunct Rahu', 'चन्द्र राहु के साथ'));
      if (VedicMath.houseOf(VedicMath.rashiIndex(longs['moon']!), lagnaRashi) == 9) conditions.add(tr('Moon in the 9th house', 'चन्द्र नौवें भाव में'));
    }
    final present = conditions.length >= 2;

    return DoshaResult(
      id: 'pitru',
      name: 'Pitru Dosha',
      hindi: 'पितृ दोष',
      present: present,
      conditions: conditions,
      description: tr('Traditionally linked with unresolved ancestral karma affecting family prosperity.', 'परंपरा में पूर्वजों के अधूरे कर्म से जुड़ा, जो परिवार की समृद्धि पर असर डालता है।'),
      remedies: [
        tr('Pitru Tarpan on Amavasya', 'अमावस्या को पितृ तर्पण'),
        tr('Shraddh during Pitru Paksha', 'पितृ पक्ष में श्राद्ध'),
        tr('Feed crows and cows on Amavasya', 'अमावस्या को कौओं और गायों को भोजन'),
        tr('Narayan Nagbali puja', 'नारायण नागबली पूजा'),
        tr('Chant "Om Pitrubhyo Namah" 108 times', '"ॐ पितृभ्यो नमः" 108 बार जपें'),
      ],
      simple: present
          ? [
              tr('The Sun (father, ancestors) or the 9th house (lineage, blessings) is touched by Rahu or Saturn in more than one way.',
                  'सूर्य (पिता, पूर्वज) या नौवाँ भाव (वंश, आशीर्वाद) एक से अधिक प्रकार से राहु या शनि से प्रभावित है।'),
              tr('In everyday terms this can show as distance or friction with the father, family responsibilities that fall on you, or delays in luck. This dosha is a later tradition, not a classical rule; honouring elders and ancestors is the traditional response.',
                  'रोज़मर्रा में यह पिता से दूरी या खटपट, परिवार की ज़िम्मेदारियाँ आप पर आना या भाग्य में देरी के रूप में दिख सकता है। यह बाद की परंपरा है, शास्त्रीय नियम नहीं; बड़ों और पूर्वजों का सम्मान इसका पारंपरिक उपाय है।'),
            ]
          : [tr('The conditions for Pitru Dosha are not met.', 'पितृ दोष की शर्तें पूरी नहीं होतीं।')],
    );
  }

  static double _separation(double a, double b) {
    final d = VedicMath.norm360(a - b);
    return d > 180 ? 360 - d : d;
  }

  static DoshaResult computeGrahanDosha(Map<String, double> longs) {
    final cond = <String>[];
    bool near(String a, String b) => longs.containsKey(a) && longs.containsKey(b) && _separation(longs[a]!, longs[b]!) < 10;
    final sun = near('sun', 'rahu') || near('sun', 'ketu');
    final moon = near('moon', 'rahu') || near('moon', 'ketu');
    if (near('sun', 'rahu')) cond.add(tr('Sun within 10° of Rahu (solar-eclipse pattern)', 'सूर्य राहु से 10° के भीतर (सूर्य ग्रहण योग)'));
    if (near('moon', 'rahu')) cond.add(tr('Moon within 10° of Rahu (lunar-eclipse pattern)', 'चन्द्र राहु से 10° के भीतर (चन्द्र ग्रहण योग)'));
    if (near('sun', 'ketu')) cond.add(tr('Sun within 10° of Ketu', 'सूर्य केतु से 10° के भीतर'));
    if (near('moon', 'ketu')) cond.add(tr('Moon within 10° of Ketu', 'चन्द्र केतु से 10° के भीतर'));

    return DoshaResult(
      id: 'grahan',
      name: 'Grahan Dosha',
      hindi: 'ग्रहण दोष',
      present: cond.isNotEmpty,
      conditions: cond,
      description: tr('Sun or Moon closely conjunct Rahu/Ketu — an eclipse pattern at birth.', 'सूर्य या चन्द्र राहु/केतु के बहुत पास — जन्म के समय ग्रहण जैसा योग।'),
      remedies: [
        tr('Surya/Chandra mantra recitation', 'सूर्य/चन्द्र मंत्र का जाप'),
        tr('Donate at temples on eclipse days', 'ग्रहण के दिन मंदिर में दान'),
        tr('Grahan Shanti Homa', 'ग्रहण शांति हवन'),
      ],
      simple: cond.isNotEmpty
          ? [
              if (sun)
                tr('The Sun (confidence, father, recognition) is close to a node, so self-confidence or recognition can feel "eclipsed" at times; it often improves with age and self-belief.',
                    'सूर्य (आत्मविश्वास, पिता, पहचान) एक छाया ग्रह के पास है, इसलिए कभी-कभी आत्मविश्वास या पहचान "ढकी" हुई लग सकती है; यह प्रायः उम्र और आत्म-विश्वास से सुधरती है।'),
              if (moon)
                tr('The Moon (mind, emotions, mother) is close to a node, so worries or mood swings can come up; calm routines, meditation and sleep help a lot.',
                    'चन्द्र (मन, भावनाएँ, माता) एक छाया ग्रह के पास है, इसलिए चिंता या मन की अस्थिरता आ सकती है; शांत दिनचर्या, ध्यान और अच्छी नींद बहुत मदद करते हैं।'),
            ]
          : [tr('Sun and Moon are not close to Rahu or Ketu, so there is no Grahan Dosha.', 'सूर्य और चन्द्र राहु या केतु के पास नहीं हैं, इसलिए ग्रहण दोष नहीं है।')],
    );
  }

  static DoshaResult computeGuruChandalDosha(Map<String, double> longs) {
    var present = false;
    final cond = <String>[];
    for (final node in ['rahu', 'ketu']) {
      if (longs.containsKey('jupiter') && longs.containsKey(node) && VedicMath.rashiIndex(longs['jupiter']!) == VedicMath.rashiIndex(longs[node]!)) {
        present = true;
        cond.add(tr('Jupiter conjunct ${VedicMath.planets[node]!.name}', 'गुरु ${_p(node)} के साथ'));
      }
    }

    return DoshaResult(
      id: 'guruchandal',
      name: 'Guru Chandal Dosha',
      hindi: 'गुरु चांडाल दोष',
      present: present,
      conditions: cond,
      description: tr('Jupiter conjunct Rahu or Ketu — traditionally said to confuse values and bring clashes with teachers or elders.',
          'गुरु राहु या केतु के साथ — परंपरा में मूल्यों में भ्रम और गुरुओं या बड़ों से टकराव से जोड़ा जाता है।'),
      remedies: [
        tr('Respect teachers and elders', 'गुरुओं और बड़ों का सम्मान करें'),
        tr('Worship Lord Vishnu / Brihaspati', 'भगवान विष्णु / बृहस्पति की पूजा'),
        tr('Donate yellow items on Thursdays', 'गुरुवार को पीली वस्तुओं का दान'),
      ],
      simple: present
          ? [
              tr('Jupiter (wisdom, teachers, faith) shares a sign with a node. You may question traditions and go your own way in beliefs, education or advice; at times this brings friction with teachers or elders, or poor advice from others.',
                  'गुरु (ज्ञान, गुरुजन, आस्था) एक छाया ग्रह के साथ है। आप परंपराओं पर प्रश्न उठा सकते हैं और विश्वास, शिक्षा या सलाह में अपना रास्ता चुन सकते हैं; कभी-कभी इससे गुरुओं या बड़ों से खटपट या दूसरों से गलत सलाह मिल सकती है।'),
              tr('Its weight depends on how strong Jupiter is; a strong Jupiter turns it into unconventional wisdom.', 'इसका असर गुरु के बल पर निर्भर है; बलवान गुरु इसे अपरंपरागत ज्ञान में बदल देता है।'),
            ]
          : [tr('Jupiter is not with Rahu or Ketu, so there is no Guru Chandal Dosha.', 'गुरु राहु या केतु के साथ नहीं है, इसलिए गुरु चांडाल दोष नहीं है।')],
    );
  }

  /// Kemadruma: no planet (other than Sun, Rahu, Ketu) in the 2nd or 12th from the Moon.
  /// Cancelled when a planet is conjunct the Moon or in a kendra from the Moon.
  static DoshaResult computeKemadrumaDosha(Map<String, double> longs) {
    if (!longs.containsKey('moon')) {
      return DoshaResult(id: 'kemadruma', name: 'Kemadruma Dosha', hindi: 'केमद्रुम दोष', present: false, description: '', remedies: []);
    }

    final moonRashi = VedicMath.rashiIndex(longs['moon']!);
    const truePlanets = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];

    var adjacent = false;
    final cancellations = <String>[];
    for (final p in truePlanets) {
      if (!longs.containsKey(p)) continue;
      final h = VedicMath.houseOf(VedicMath.rashiIndex(longs[p]!), moonRashi);
      if (h == 2 || h == 12) adjacent = true;
      if (h == 1) cancellations.add(tr('${VedicMath.planets[p]!.name} conjunct Moon', '${_p(p)} चन्द्र के साथ'));
      if (h == 4 || h == 7 || h == 10) cancellations.add(tr('${VedicMath.planets[p]!.name} in a Kendra from the Moon', '${_p(p)} चन्द्र से केन्द्र में'));
    }

    final formed = !adjacent;
    final present = formed && cancellations.isEmpty;
    return DoshaResult(
      id: 'kemadruma',
      name: 'Kemadruma Dosha',
      hindi: 'केमद्रुम दोष',
      present: present,
      exceptions: formed ? cancellations : const [],
      description: tr('Moon without planets on either side — classically linked with loneliness, mental unrest and struggles.',
          'चन्द्र के दोनों ओर कोई ग्रह नहीं — शास्त्रों में अकेलेपन, मानसिक अशांति और संघर्ष से जोड़ा गया।'),
      remedies: [
        tr('Worship Lord Shiva daily', 'प्रतिदिन भगवान शिव की पूजा'),
        tr('Offer milk on a Shivling', 'शिवलिंग पर दूध चढ़ाएँ'),
        tr('Keep a silver square with you', 'अपने पास चांदी का चौकोर टुकड़ा रखें'),
      ],
      simple: present
          ? [
              tr('Your Moon (mind) has no planet beside it. This is a classical yoga (BPHS, Phaladeepika). You may often feel you must manage on your own, and moods can swing.',
                  'आपके चन्द्र (मन) के पास कोई ग्रह नहीं है। यह शास्त्रीय योग है (BPHS, फलदीपिका)। आपको अक्सर लग सकता है कि सब खुद ही संभालना है, और मन ऊपर-नीचे हो सकता है।'),
              tr('Building a support network, regular routines and spiritual practice are the traditional ways to balance it.', 'सहायक संबंध बनाना, नियमित दिनचर्या और आध्यात्मिक साधना इसे संतुलित करने के पारंपरिक तरीके हैं।'),
            ]
          : [
              formed
                  ? tr('The Moon is alone on both sides, but the yoga is cancelled (${cancellations.join('; ')}), so it does not apply.',
                      'चन्द्र के दोनों ओर कोई ग्रह नहीं, पर योग भंग है (${cancellations.join('; ')}), इसलिए यह लागू नहीं होता।')
                  : tr('Planets sit next to your Moon, so there is no Kemadruma.', 'आपके चन्द्र के पास ग्रह हैं, इसलिए केमद्रुम नहीं है।'),
            ],
    );
  }
}
