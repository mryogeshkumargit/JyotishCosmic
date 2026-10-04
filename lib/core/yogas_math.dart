import 'doshas_math.dart';
import 'ephemeris.dart';
import 'planetary_dignity.dart';
import 'precision_math.dart';
import 'l10n.dart';
import 'vedic_math.dart';

/// Whether a yoga is traditionally favourable, adverse or mixed.
enum YogaNature { benefic, adverse, mixed }

/// One classical yoga checked against a chart.
class YogaResult {
  /// Family, e.g. 'Nabhasa · Akriti', 'Raja Yoga', 'Moon Yoga'.
  final String category;
  final String name;
  final String hindi;
  final bool formed;

  /// 'Strong', 'Moderate', 'Weak', 'Cancelled', 'Mitigated', 'Challenging'...
  final String strength;

  /// Traditional results.
  final String description;
  final List<String> planets;

  /// Exact formation rule used by this app.
  final String rule;

  /// Classical source of the rule.
  final String source;

  /// How the yoga forms (or fails to form) in this chart.
  final List<String> reasons;

  /// Strength factors: dignity, combustion, retrogression, Navamsa, cancellations.
  final List<String> modifiers;
  final YogaNature nature;

  /// A participating planet runs the current Mahadasha or Antardasha.
  final bool active;

  const YogaResult({
    required this.category,
    required this.name,
    required this.hindi,
    required this.formed,
    this.strength = 'Moderate',
    required this.description,
    this.planets = const [],
    this.rule = '',
    this.source = '',
    this.reasons = const [],
    this.modifiers = const [],
    this.nature = YogaNature.benefic,
    this.active = false,
  });

  YogaResult withActive(bool value) => YogaResult(
        category: category,
        name: name,
        hindi: hindi,
        formed: formed,
        strength: strength,
        description: description,
        planets: planets,
        rule: rule,
        source: source,
        reasons: reasons,
        modifiers: modifiers,
        nature: nature,
        active: value,
      );
}

/// Yoga families in display order.
class YogaFamilies {
  static const String mahapurusha = 'Pancha Mahapurusha';
  static const String moon = 'Moon (Chandra) Yogas';
  static const String sun = 'Sun (Surya) Yogas';
  static const String raja = 'Raja Yogas';
  static const String dhana = 'Dhana Yogas';
  static const String daridra = 'Daridra Yogas';
  static const String viparita = 'Viparita Raja Yogas';
  static const String parivartana = 'Parivartana Yogas';
  static const String neecha = 'Neecha Bhanga';
  static const String special = 'Special Yogas';
  static const String kartari = 'Kartari Yogas';
  static const String nabhasaAshraya = 'Nabhasa · Ashraya';
  static const String nabhasaDala = 'Nabhasa · Dala';
  static const String nabhasaAkriti = 'Nabhasa · Akriti';
  static const String nabhasaSankhya = 'Nabhasa · Sankhya';
  static const String pravrajya = 'Pravrajya (Renunciation)';
  static const String arishta = 'Arishta & Arishta-bhanga';

  static const List<String> order = [
    mahapurusha, raja, dhana, moon, sun, special, viparita, parivartana, neecha, kartari,
    nabhasaAshraya, nabhasaDala, nabhasaAkriti, nabhasaSankhya, daridra, pravrajya, arishta,
  ];
}

/// Classical yoga engine (BPHS, Brihat Jataka, Phaladeepika, Saravali).
///
/// Conventions used throughout:
/// * whole-sign houses from the Lagna (or from the Moon/Sun where stated);
/// * "the seven planets" are Sun to Saturn; Rahu and Ketu are excluded from
///   Nabhasa, Moon and Sun yogas;
/// * natural benefics: Jupiter, Venus, Mercury (unless conjunct a malefic) and
///   the waxing Moon; natural malefics: Sun, Mars, Saturn, Rahu, Ketu and the
///   waning Moon (Nabhasa yogas use the fixed groups Jupiter/Venus/Mercury/Moon
///   and Sun/Mars/Saturn);
/// * a relationship (sambandha) between two lords means conjunction, mutual
///   aspect or exchange of signs;
/// * a "strong" planet is in its exaltation, Moolatrikona or own sign, or in a
///   Kendra/Trikona while not debilitated, combust or in an enemy's sign.
class YogasMath {
  static const List<String> seven = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
  static const List<String> _nabhasaBenefics = ['moon', 'mercury', 'jupiter', 'venus'];
  static const List<String> _nabhasaMalefics = ['sun', 'mars', 'saturn'];

  static String _yn(bool v) => v ? 'हाँ' : 'नहीं';

  static bool isKendra(int h) => h == 1 || h == 4 || h == 7 || h == 10;
  static bool isTrikona(int h) => h == 1 || h == 5 || h == 9;
  static bool isDusthana(int h) => h == 6 || h == 8 || h == 12;
  static bool isUpachaya(int h) => h == 3 || h == 6 || h == 10 || h == 11;
  static bool isExalted(String p, int r) => VedicMath.planets[p]?.exalt == r;
  static bool isDebilitated(String p, int r) => VedicMath.planets[p]?.debi == r;
  static bool isOwn(String p, int r) => VedicMath.planets[p]?.ownSigns.contains(r) ?? false;

  /// Lord of the [house]th house from [lagnaRashi].
  static String lord(int lagnaRashi, int house) => VedicMath.rashis[(lagnaRashi + house - 1) % 12].lord;

  /// Checks every yoga for [chart]; formed ones first is up to the caller.
  /// [gender] ('Male'/'Female') is only used by Mahabhagya Yoga.
  static List<YogaResult> forChart(ChartData chart, {String? gender, double? atJd}) {
    List<String> running = const [];
    final moon = chart.planetLongitudes['moon'];
    if (moon != null) {
      final dashas = DashaCalculations.compute(chart.jd, moon, utcOffset: chart.utcOffset);
      running = dashas.runningAt(atJd ?? Ephemeris.nowJd()).take(2).map((d) => d.lord).toList();
    }
    return computeAllYogas(
      chart.planetLongitudes,
      chart.lagnaRashi,
      speeds: chart.planetSpeeds,
      ascendant: chart.ascendantSidereal,
      gender: gender,
      dashaLords: running,
    );
  }

  static List<YogaResult> computeAllYogas(
    Map<String, double> longs,
    int lagnaRashi, {
    Map<String, double> speeds = const {},
    double? ascendant,
    String? gender,
    List<String> dashaLords = const [],
  }) {
    final c = _Chart(longs, lagnaRashi, speeds, ascendant);
    final results = <YogaResult>[
      ..._mahapurusha(c),
      ..._moonYogas(c),
      ..._sunYogas(c),
      ..._rajaYogas(c),
      ..._specialYogas(c, gender),
      ..._dhanaYogas(c),
      ..._daridraYogas(c),
      ..._viparita(c),
      ..._parivartana(c),
      ..._neechaBhanga(c),
      ..._kartari(c),
      ..._nabhasa(c),
      ..._pravrajya(c),
      ..._arishta(c),
    ];
    return [
      for (final y in results) y.formed && y.planets.any(dashaLords.contains) ? y.withActive(true) : y,
    ];
  }

  // ---------------------------------------------------------------------------
  // Pancha Mahapurusha
  // ---------------------------------------------------------------------------

  static List<YogaResult> _mahapurusha(_Chart c) {
    const data = [
      ('mars', 'Ruchaka', 'रुचक', 'Courage, physical strength, command, initiative and martial qualities.'),
      ('mercury', 'Bhadra', 'भद्र', 'Intellect, communication, learning, administration and analytical ability.'),
      ('jupiter', 'Hamsa', 'हंस', 'Wisdom, ethics, learning, dignity and prosperity.'),
      ('venus', 'Malavya', 'मालव्य', 'Beauty, comforts, relationships, vehicles, refinement and enjoyment.'),
      ('saturn', 'Sasa', 'शश', 'Organisation, authority, endurance, administration and influence over many people.'),
    ];
    final out = <YogaResult>[];
    for (final (p, name, hindi, desc) in data) {
      if (!c.has(p)) continue;
      final r = c.rashi(p);
      final dignity = isExalted(p, r) ? tr('exalted', 'उच्च') : (isOwn(p, r) ? tr('in its own sign', 'स्वराशि') : null);
      final fromLagna = isKendra(c.house(p));
      final fromMoon = c.has('moon') && isKendra(c.houseFrom(p, c.rashi('moon')));
      final formed = dignity != null && fromLagna;
      final reasons = <String>[
        tr('${c.name(p)} is in ${c.signName(p)} (${dignity ?? 'neither own nor exaltation sign'}), house ${c.house(p)} from Lagna.',
            '${c.name(p)} ${c.signName(p)} में है (${dignity ?? 'न स्वराशि, न उच्च'}), लग्न से ${c.house(p)}वें भाव में।'),
        if (dignity != null && !fromLagna && fromMoon)
          tr('It is in a Kendra from the Moon only: the yoga applies from the Moon (Chandra Lagna) in some traditions.',
              'यह केवल चन्द्र से केन्द्र में है: कुछ परंपराओं में योग चन्द्र लग्न से माना जाता है।'),
      ];
      out.add(YogaResult(
        category: YogaFamilies.mahapurusha,
        name: '$name Yoga',
        hindi: '$hindi योग',
        formed: formed,
        strength: formed ? c.strengthOf([p]) : (dignity != null && fromMoon ? 'From Moon only' : 'Not formed'),
        description: desc,
        planets: [p],
        rule: tr('${c.en(p)} in a Kendra (1, 4, 7, 10) from the Lagna while in its own or exaltation sign.',
            '${c.name(p)} लग्न से केन्द्र (1, 4, 7, 10) में हो और अपनी स्वराशि या उच्च राशि में हो।'),
        source: 'BPHS (Pancha Mahapurusha Yogas); Phaladeepika ch. 6',
        reasons: reasons,
        modifiers: formed ? c.modifiers([p]) : const [],
      ));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Moon yogas
  // ---------------------------------------------------------------------------

  static List<YogaResult> _moonYogas(_Chart c) {
    if (!c.has('moon')) return const [];
    final out = <YogaResult>[];
    final moonR = c.rashi('moon');
    const others = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    final in2 = others.where((p) => c.has(p) && c.houseFrom(p, moonR) == 2).toList();
    final in12 = others.where((p) => c.has(p) && c.houseFrom(p, moonR) == 12).toList();
    const src = 'BPHS (Chandra Yogas); Brihat Jataka ch. 13; Phaladeepika ch. 6';

    out.add(YogaResult(
      category: YogaFamilies.moon,
      name: 'Sunapha Yoga',
      hindi: 'सुनफा योग',
      formed: in2.isNotEmpty && in12.isEmpty,
      strength: in2.isNotEmpty && in12.isEmpty ? c.strengthOf(in2) : 'Not formed',
      description: 'Self-acquired wealth, intelligence, reputation and initiative.',
      planets: in2,
      rule: tr('One or more planets other than the Sun (and the nodes) in the 2nd house from the Moon, with the 12th from the Moon empty.',
          'चन्द्र से दूसरे भाव में सूर्य (और राहु-केतु) के अलावा एक या अधिक ग्रह हों और चन्द्र से 12वाँ भाव खाली हो।'),
      source: src,
      reasons: [in2.isEmpty ? tr('No planet in the 2nd from the Moon.', 'चन्द्र से दूसरे भाव में कोई ग्रह नहीं है।') : tr('${c.names(in2)} in the 2nd from the Moon.', '${c.names(in2)} चन्द्र से दूसरे भाव में है।')],
      modifiers: in2.isNotEmpty && in12.isEmpty ? c.modifiers(in2) : const [],
    ));
    out.add(YogaResult(
      category: YogaFamilies.moon,
      name: 'Anapha Yoga',
      hindi: 'अनफा योग',
      formed: in12.isNotEmpty && in2.isEmpty,
      strength: in12.isNotEmpty && in2.isEmpty ? c.strengthOf(in12) : 'Not formed',
      description: 'Independence, good health, reputation, strength and refinement.',
      planets: in12,
      rule: tr('One or more planets other than the Sun (and the nodes) in the 12th house from the Moon, with the 2nd from the Moon empty.',
          'चन्द्र से 12वें भाव में सूर्य (और राहु-केतु) के अलावा एक या अधिक ग्रह हों और चन्द्र से दूसरा भाव खाली हो।'),
      source: src,
      reasons: [in12.isEmpty ? tr('No planet in the 12th from the Moon.', 'चन्द्र से 12वें भाव में कोई ग्रह नहीं है।') : tr('${c.names(in12)} in the 12th from the Moon.', '${c.names(in12)} चन्द्र से 12वें भाव में है।')],
      modifiers: in12.isNotEmpty && in2.isEmpty ? c.modifiers(in12) : const [],
    ));
    final duru = in2.isNotEmpty && in12.isNotEmpty;
    out.add(YogaResult(
      category: YogaFamilies.moon,
      name: 'Durudhara Yoga',
      hindi: 'दुरुधरा योग',
      formed: duru,
      strength: duru ? c.strengthOf([...in2, ...in12]) : 'Not formed',
      description: 'Resources, comforts, vehicles, supporters and the capacity for sustained activity.',
      planets: [...in2, ...in12],
      rule: tr('Planets other than the Sun (and the nodes) in both the 2nd and the 12th houses from the Moon.',
          'चन्द्र से दूसरे और 12वें, दोनों भावों में सूर्य (और राहु-केतु) के अलावा ग्रह हों।'),
      source: src,
      reasons: [
        duru
            ? tr('${c.names(in2)} in the 2nd and ${c.names(in12)} in the 12th from the Moon.', 'चन्द्र से दूसरे भाव में ${c.names(in2)} और 12वें भाव में ${c.names(in12)} है।')
            : tr('The 2nd and 12th from the Moon are not both occupied.', 'चन्द्र से दूसरा और 12वाँ भाव दोनों भरे हुए नहीं हैं।')
      ],
      modifiers: duru ? c.modifiers([...in2, ...in12]) : const [],
    ));

    final kema = DoshasMath.computeKemadrumaDosha(c.longs);
    final kemaFormed = in2.isEmpty && in12.isEmpty;
    out.add(YogaResult(
      category: YogaFamilies.moon,
      name: 'Kemadruma Yoga',
      hindi: 'केमद्रुम योग',
      formed: kemaFormed,
      strength: !kemaFormed ? 'Not formed' : (kema.present ? 'Challenging' : 'Cancelled'),
      description: 'Loneliness, mental unrest and struggles for resources. Classical texts give cancellations, so it should not be read from the two houses alone.',
      planets: const ['moon'],
      rule: tr('No planet other than the Sun (and the nodes) in the 2nd or 12th from the Moon. Cancelled by a planet conjunct the Moon or in a Kendra from the Moon.',
          'चन्द्र से दूसरे या 12वें भाव में सूर्य (और राहु-केतु) के अलावा कोई ग्रह न हो। चन्द्र के साथ या चन्द्र से केन्द्र में ग्रह होने पर यह भंग हो जाता है।'),
      source: 'BPHS (Chandra Yogas); Phaladeepika ch. 6',
      reasons: [
        kemaFormed
            ? tr('The 2nd and 12th from the Moon are empty.', 'चन्द्र से दूसरा और 12वाँ भाव खाली है।')
            : tr('Planets flank the Moon, so Kemadruma does not form.', 'चन्द्र के दोनों ओर ग्रह हैं, इसलिए केमद्रुम नहीं बनता।')
      ],
      modifiers: kemaFormed ? [for (final e in kema.exceptions) '${tr('Cancellation', 'भंग')}: $e'] : const [],
      nature: YogaNature.adverse,
    ));

    // Gaja Kesari
    if (c.has('jupiter')) {
      final h = c.houseFrom('jupiter', moonR);
      final formed = isKendra(h);
      final weak = <String>[
        if (isDebilitated('jupiter', c.rashi('jupiter'))) tr('Jupiter is debilitated', 'गुरु नीच का है'),
        if (c.isCombust('jupiter')) tr('Jupiter is combust', 'गुरु अस्त है'),
        if (c.dignity('jupiter').contains('Enemy')) tr('Jupiter is in an enemy\'s sign', 'गुरु शत्रु राशि में है'),
      ];
      out.add(YogaResult(
        category: YogaFamilies.moon,
        name: 'Gaja Kesari Yoga',
        hindi: 'गजकेसरी योग',
        formed: formed,
        strength: !formed ? 'Not formed' : (weak.isEmpty ? c.strengthOf(['jupiter', 'moon']) : 'Weak'),
        description: 'Intelligence, reputation, dignity, courage and capacity for achievement; lasting fame.',
        planets: const ['jupiter', 'moon'],
        rule: tr('Jupiter in a Kendra (1, 4, 7, 10) from the Moon. Classical texts add that Jupiter should not be debilitated, combust or in an enemy\'s sign.',
            'चन्द्र से केन्द्र (1, 4, 7, 10) में गुरु। शास्त्र यह भी कहते हैं कि गुरु नीच, अस्त या शत्रु राशि में न हो।'),
        source: 'Phaladeepika ch. 6; BPHS',
        reasons: [tr('Jupiter is in house $h from the Moon.', 'गुरु चन्द्र से $hवें भाव में है।')],
        modifiers: formed ? [...weak.map((w) => '${tr('Weakened', 'कमज़ोर')}: $w'), ...c.modifiers(['jupiter', 'moon'])] : const [],
      ));
    }

    // Adhi yoga (from Moon) and Lagnadhi yoga.
    for (final fromLagna in [false, true]) {
      final ref = fromLagna ? c.lagna : moonR;
      const bens = ['mercury', 'jupiter', 'venus'];
      final placed = bens.where((p) => c.has(p) && [6, 7, 8].contains(c.houseFrom(p, ref))).toList();
      final malefics = c.present(['sun', 'mars', 'saturn', 'rahu', 'ketu']).where((p) => [6, 7, 8].contains(c.houseFrom(p, ref))).toList();
      final formed = placed.length >= 2 && malefics.isEmpty;
      out.add(YogaResult(
        category: fromLagna ? YogaFamilies.special : YogaFamilies.moon,
        name: fromLagna ? 'Lagnadhi Yoga' : 'Adhi Yoga',
        hindi: fromLagna ? 'लग्नाधि योग' : 'अधि योग',
        formed: formed,
        strength: !formed ? 'Not formed' : (placed.length == 3 ? 'Strong' : 'Moderate'),
        description: fromLagna
            ? 'Learning, a good name, a comfortable and long life; a leader of people.'
            : 'Authority, influence, prosperity and victory over opponents (as a commander, minister or leader by strength).',
        planets: placed,
        rule: tr(
            'Natural benefics (Mercury, Jupiter, Venus) in the 6th, 7th and 8th from the ${fromLagna ? 'Lagna' : 'Moon'}, '
                'with no malefic there. All three: full yoga; two: medium.',
            'नैसर्गिक शुभ ग्रह (बुध, गुरु, शुक्र) ${_Chart.ref(fromLagna ? 'Lagna' : 'Moon')} से 6, 7 और 8वें भाव में हों और वहाँ कोई पाप ग्रह न हो। तीनों हों तो पूर्ण योग; दो हों तो मध्यम।'),
        source: 'Phaladeepika ch. 6; BPHS',
        reasons: [
          placed.isEmpty
              ? tr('No benefic in the 6th, 7th or 8th from the ${fromLagna ? 'Lagna' : 'Moon'}.', '${_Chart.ref(fromLagna ? 'Lagna' : 'Moon')} से 6, 7 या 8वें भाव में कोई शुभ ग्रह नहीं है।')
              : tr('${c.names(placed)} in the 6th/7th/8th from the ${fromLagna ? 'Lagna' : 'Moon'}.', '${c.names(placed)} ${_Chart.ref(fromLagna ? 'Lagna' : 'Moon')} से 6/7/8वें भाव में है।'),
          if (malefics.isNotEmpty) tr('${c.names(malefics)} also occupy these houses.', '${c.names(malefics)} भी इन भावों में है।'),
        ],
        modifiers: formed ? c.modifiers(placed) : const [],
      ));
    }

    // Chandra-Mangala
    if (c.has('mars')) {
      final conj = c.rashi('mars') == moonR;
      final opp = c.houseFrom('mars', moonR) == 7;
      final formed = conj || opp;
      out.add(YogaResult(
        category: YogaFamilies.moon,
        name: 'Chandra-Mangala Yoga',
        hindi: 'चन्द्र-मंगल योग',
        formed: formed,
        strength: formed ? c.strengthOf(['moon', 'mars']) : 'Not formed',
        description: 'Initiative, enterprise and earning through trade or bold action; emotional intensity depending on the Moon\'s condition.',
        planets: const ['moon', 'mars'],
        rule: tr('Moon and Mars conjunct (same sign) or in mutual aspect (7th from each other).', 'चन्द्र और मंगल एक ही राशि में हों या एक-दूसरे से सातवें भाव में होकर परस्पर दृष्टि रखें।'),
        source: 'Later manuals (e.g. Phaladeepika commentaries)',
        reasons: [
          conj
              ? tr('Moon and Mars are in the same sign.', 'चन्द्र और मंगल एक ही राशि में हैं।')
              : (opp ? tr('Moon and Mars aspect each other from the 1st/7th.', 'चन्द्र और मंगल 1/7 से एक-दूसरे को देखते हैं।') : tr('Moon and Mars are not connected.', 'चन्द्र और मंगल का संबंध नहीं है।'))
        ],
        modifiers: formed ? c.modifiers(['moon', 'mars']) : const [],
        nature: YogaNature.mixed,
      ));
    }

    // Sakata (Moon-Jupiter)
    if (c.has('jupiter')) {
      final h = c.houseFrom('moon', c.rashi('jupiter'));
      final formed = h == 6 || h == 8 || h == 12;
      final cancelled = isKendra(c.house('moon'));
      out.add(YogaResult(
        category: YogaFamilies.moon,
        name: 'Sakata Yoga',
        hindi: 'शकट योग',
        formed: formed,
        strength: !formed ? 'Not formed' : (cancelled ? 'Cancelled' : 'Challenging'),
        description: 'Fluctuating fortune, like the rise and fall of a cart wheel; loss followed by recovery.',
        planets: const ['moon', 'jupiter'],
        rule: tr('The Moon in the 6th, 8th or 12th house from Jupiter. Cancelled when the Moon is in a Kendra from the Lagna.',
            'गुरु से 6, 8 या 12वें भाव में चन्द्र। चन्द्र लग्न से केन्द्र में हो तो यह भंग हो जाता है।'),
        source: 'Phaladeepika ch. 6',
        reasons: [tr('The Moon is in house $h from Jupiter.', 'चन्द्र गुरु से $hवें भाव में है।')],
        modifiers: formed && cancelled
            ? [tr('Cancellation: the Moon is in a Kendra (house ${c.house('moon')}) from the Lagna.', 'भंग: चन्द्र लग्न से केन्द्र (${c.house('moon')}वें भाव) में है।')]
            : const [],
        nature: YogaNature.adverse,
      ));
    }

    // Vasumati
    {
      const bens = ['mercury', 'jupiter', 'venus'];
      final ok = bens.every(c.has);
      final fromLagna = ok && bens.every((p) => isUpachaya(c.house(p)));
      final fromMoon = ok && bens.every((p) => isUpachaya(c.houseFrom(p, moonR)));
      final formed = fromLagna || fromMoon;
      out.add(YogaResult(
        category: YogaFamilies.dhana,
        name: 'Vasumati Yoga',
        hindi: 'वसुमती योग',
        formed: formed,
        strength: formed ? c.strengthOf(bens) : 'Not formed',
        description: 'Steady accumulation of wealth; the native is rich and independent.',
        planets: bens,
        rule: tr('All natural benefics (Mercury, Jupiter, Venus) in Upachaya houses (3, 6, 10, 11) from the Lagna or from the Moon.',
            'सभी नैसर्गिक शुभ ग्रह (बुध, गुरु, शुक्र) लग्न या चन्द्र से उपचय भावों (3, 6, 10, 11) में हों।'),
        source: 'Phaladeepika ch. 6; BPHS',
        reasons: [
          formed
              ? tr('The benefics occupy Upachaya houses from the ${fromLagna ? 'Lagna' : 'Moon'}.', 'शुभ ग्रह ${_Chart.ref(fromLagna ? 'Lagna' : 'Moon')} से उपचय भावों में हैं।')
              : tr('Not all benefics are in Upachaya houses (from Lagna: ${bens.where(c.has).map((p) => '${c.name(p)} ${c.house(p)}').join(', ')}).',
                  'सभी शुभ ग्रह उपचय भावों में नहीं हैं (लग्न से: ${bens.where(c.has).map((p) => '${c.name(p)} ${c.house(p)}').join(', ')})।')
        ],
        modifiers: formed ? c.modifiers(bens) : const [],
      ));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Sun yogas
  // ---------------------------------------------------------------------------

  static List<YogaResult> _sunYogas(_Chart c) {
    if (!c.has('sun')) return const [];
    final sunR = c.rashi('sun');
    const others = ['mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    final in2 = others.where((p) => c.has(p) && c.houseFrom(p, sunR) == 2).toList();
    final in12 = others.where((p) => c.has(p) && c.houseFrom(p, sunR) == 12).toList();
    String kind(List<String> ps) {
      final b = ps.where(c.isBenefic).length;
      if (b == ps.length) return 'Shubha (benefic) ';
      if (b == 0) return 'Papa (malefic) ';
      return 'Mixed ';
    }

    const src = 'BPHS (Surya Yogas); Phaladeepika ch. 6';
    final vesi = in2.isNotEmpty && in12.isEmpty;
    final vasi = in12.isNotEmpty && in2.isEmpty;
    final ubh = in2.isNotEmpty && in12.isNotEmpty;
    return [
      YogaResult(
        category: YogaFamilies.sun,
        name: 'Vesi Yoga',
        hindi: 'वेशि योग',
        formed: vesi,
        strength: vesi ? '${kind(in2)}· ${c.strengthOf(in2)}' : 'Not formed',
        description: 'Balanced outlook, truthfulness and a good name; benefics give eloquence and wealth, malefics make the native harsh.',
        planets: in2,
        rule: tr('Planets other than the Moon (and the nodes) in the 2nd from the Sun, with the 12th from the Sun empty.',
            'सूर्य से दूसरे भाव में चन्द्र (और राहु-केतु) के अलावा ग्रह हों और सूर्य से 12वाँ भाव खाली हो।'),
        source: src,
        reasons: [in2.isEmpty ? tr('No planet in the 2nd from the Sun.', 'सूर्य से दूसरे भाव में कोई ग्रह नहीं है।') : tr('${c.names(in2)} in the 2nd from the Sun.', '${c.names(in2)} सूर्य से दूसरे भाव में है।')],
        modifiers: vesi ? c.modifiers(in2) : const [],
        nature: vesi && in2.every(c.isBenefic) ? YogaNature.benefic : YogaNature.mixed,
      ),
      YogaResult(
        category: YogaFamilies.sun,
        name: 'Vasi Yoga',
        hindi: 'वाशि योग',
        formed: vasi,
        strength: vasi ? '${kind(in12)}· ${c.strengthOf(in12)}' : 'Not formed',
        description: 'Skill, charity and the favour of authorities; benefics give happiness and fame, malefics hardship.',
        planets: in12,
        rule: tr('Planets other than the Moon (and the nodes) in the 12th from the Sun, with the 2nd from the Sun empty.',
            'सूर्य से 12वें भाव में चन्द्र (और राहु-केतु) के अलावा ग्रह हों और सूर्य से दूसरा भाव खाली हो।'),
        source: src,
        reasons: [in12.isEmpty ? tr('No planet in the 12th from the Sun.', 'सूर्य से 12वें भाव में कोई ग्रह नहीं है।') : tr('${c.names(in12)} in the 12th from the Sun.', '${c.names(in12)} सूर्य से 12वें भाव में है।')],
        modifiers: vasi ? c.modifiers(in12) : const [],
        nature: vasi && in12.every(c.isBenefic) ? YogaNature.benefic : YogaNature.mixed,
      ),
      YogaResult(
        category: YogaFamilies.sun,
        name: 'Ubhayachari Yoga',
        hindi: 'उभयचरी योग',
        formed: ubh,
        strength: ubh ? '${kind([...in2, ...in12])}· ${c.strengthOf([...in2, ...in12])}' : 'Not formed',
        description: 'Eloquence, a well-built body, popularity and wealth, like a king.',
        planets: [...in2, ...in12],
        rule: tr('Planets other than the Moon (and the nodes) in both the 2nd and the 12th from the Sun.', 'सूर्य से दूसरे और 12वें, दोनों भावों में चन्द्र (और राहु-केतु) के अलावा ग्रह हों।'),
        source: src,
        reasons: [
          ubh
              ? tr('${c.names(in2)} in the 2nd and ${c.names(in12)} in the 12th from the Sun.', 'सूर्य से दूसरे भाव में ${c.names(in2)} और 12वें भाव में ${c.names(in12)} है।')
              : tr('The 2nd and 12th from the Sun are not both occupied.', 'सूर्य से दूसरा और 12वाँ भाव दोनों भरे हुए नहीं हैं।')
        ],
        modifiers: ubh ? c.modifiers([...in2, ...in12]) : const [],
      ),
      if (c.has('mercury'))
        () {
          final formed = c.rashi('mercury') == sunR;
          final combust = c.isCombust('mercury');
          return YogaResult(
            category: YogaFamilies.sun,
            name: 'Budha-Aditya Yoga',
            hindi: 'बुध-आदित्य योग',
            formed: formed,
            strength: !formed ? 'Not formed' : (combust ? 'Weak (Mercury combust)' : c.strengthOf(['sun', 'mercury'])),
            description: 'Intelligence, communication, administrative and analytical ability. Common, because Mercury never moves far from the Sun, so it is not exceptional on its own.',
            planets: const ['sun', 'mercury'],
            rule: tr('Sun and Mercury in the same sign. Mercury should not be combust (within 14°, or 12° when retrograde) for full results.',
                'सूर्य और बुध एक ही राशि में हों। पूर्ण फल के लिए बुध अस्त न हो (14° के भीतर, वक्री हो तो 12°)।'),
            source: 'Later manuals; see Phaladeepika on combustion',
            reasons: [
              formed
                  ? tr('Sun and Mercury are together in ${c.signName('sun')}, ${c.separation('sun', 'mercury').toStringAsFixed(1)}° apart.',
                      'सूर्य और बुध ${c.signName('sun')} में साथ हैं, ${c.separation('sun', 'mercury').toStringAsFixed(1)}° की दूरी पर।')
                  : tr('Sun and Mercury are in different signs.', 'सूर्य और बुध अलग-अलग राशियों में हैं।')
            ],
            modifiers: formed ? c.modifiers(['mercury']) : const [],
          );
        }(),
    ];
  }

  // ---------------------------------------------------------------------------
  // Raja yogas
  // ---------------------------------------------------------------------------

  static List<YogaResult> _rajaYogas(_Chart c) {
    final out = <YogaResult>[];
    final l = c.lagna;
    final seen = <String>{};
    final pairs = <YogaResult>[];

    // Yogakaraka: one planet owning a Kendra and a Trikona (other than the Lagna).
    for (final k in [4, 7, 10]) {
      for (final t in [5, 9]) {
        final p = lord(l, k);
        if (p == lord(l, t) && seen.add('yk:$p')) {
          out.add(YogaResult(
            category: YogaFamilies.raja,
            name: 'Yogakaraka ${c.en(p)}',
            hindi: 'योगकारक',
            formed: true,
            strength: c.strengthOf([p]),
            description: '${c.en(p)} rules both the ${VedicMath.ordinal(k)} and the ${VedicMath.ordinal(t)} houses, becoming the chief giver of Raja Yoga for this Lagna, especially in its Dasha.',
            planets: [p],
            rule: tr('A single planet owning both a Kendra (4, 7, 10) and a Trikona (5, 9) is a Yogakaraka.', 'जो एक ही ग्रह केन्द्र (4, 7, 10) और त्रिकोण (5, 9) दोनों का स्वामी हो, वह योगकारक होता है।'),
            source: 'BPHS (Yogakaraka planets)',
            reasons: [
              tr('${c.name(p)} lords houses $k and $t; it sits in house ${c.house(p)} (${c.signName(p)}).',
                  '${c.name(p)} $k और $tवें भाव का स्वामी है; यह ${c.house(p)}वें भाव (${c.signName(p)}) में है।')
            ],
            modifiers: c.modifiers([p]),
          ));
        }
      }
    }

    for (final k in [1, 4, 7, 10]) {
      for (final t in [1, 5, 9]) {
        if (k == t) continue;
        final lk = lord(l, k), lt = lord(l, t);
        if (lk == lt || !c.has(lk) || !c.has(lt)) continue;
        final rel = c.relation(lk, lt);
        if (rel == null) continue;
        final key = ([lk, lt]..sort()).join('-');
        if (!seen.add(key)) continue;
        pairs.add(YogaResult(
          category: YogaFamilies.raja,
          name: 'Kendra-Trikona Raja Yoga',
          hindi: 'केन्द्र-त्रिकोण राज योग',
          formed: true,
          strength: c.strengthOf([lk, lt], bonus: rel == 'conjunct' || rel == 'exchange signs' ? 0.5 : 0),
          description: 'Authority, status, success and recognition, especially in the Dashas of the two lords.',
          planets: [lk, lt],
          rule: tr('The lord of a Kendra (1, 4, 7, 10) and the lord of a Trikona (1, 5, 9) related by conjunction, mutual aspect or exchange of signs.',
              'केन्द्र (1, 4, 7, 10) का स्वामी और त्रिकोण (1, 5, 9) का स्वामी युति, परस्पर दृष्टि या राशि परिवर्तन से जुड़े हों।'),
          source: 'BPHS (Raja Yogas)',
          reasons: [
            tr('${c.name(lk)} (lord of ${VedicMath.ordinal(k)}) and ${c.name(lt)} (lord of ${VedicMath.ordinal(t)}) are $rel.',
                '${c.name(lk)} ($kवें का स्वामी) और ${c.name(lt)} ($tवें का स्वामी) ${_Chart.relText(rel)}।')
          ],
          modifiers: c.modifiers([lk, lt]),
        ));
      }
    }
    out.addAll(pairs);
    if (pairs.isEmpty) {
      out.add(YogaResult(
        category: YogaFamilies.raja,
        name: 'Kendra-Trikona Raja Yoga',
        hindi: 'केन्द्र-त्रिकोण राज योग',
        formed: false,
        strength: 'Not formed',
        description: 'Authority, status, success and recognition.',
        rule: tr('The lord of a Kendra (1, 4, 7, 10) and the lord of a Trikona (1, 5, 9) related by conjunction, mutual aspect or exchange of signs.',
              'केन्द्र (1, 4, 7, 10) का स्वामी और त्रिकोण (1, 5, 9) का स्वामी युति, परस्पर दृष्टि या राशि परिवर्तन से जुड़े हों।'),
        source: 'BPHS (Raja Yogas)',
        reasons: [tr('No Kendra lord is conjunct, in mutual aspect or exchanging signs with a Trikona lord.', 'कोई केन्द्रेश किसी त्रिकोणेश के साथ युति, परस्पर दृष्टि या राशि परिवर्तन में नहीं है।')],
      ));
    }

    // Dharma-Karmadhipati
    final l9 = lord(l, 9), l10 = lord(l, 10);
    final same = l9 == l10;
    final rel = same ? 'the same planet' : c.relation(l9, l10);
    out.add(YogaResult(
      category: YogaFamilies.raja,
      name: 'Dharma-Karmadhipati Yoga',
      hindi: 'धर्म-कर्माधिपति योग',
      formed: rel != null,
      strength: rel != null ? c.strengthOf([l9, l10]) : 'Not formed',
      description: 'Dharma (principles, fortune) joins Karma (action, profession): recognition, responsibility and professional achievement.',
      planets: {l9, l10}.toList(),
      rule: tr('The lords of the 9th and 10th houses related by conjunction, mutual aspect or exchange of signs (or one planet owning both).',
          '9वें और 10वें भाव के स्वामी युति, परस्पर दृष्टि या राशि परिवर्तन से जुड़े हों (या एक ही ग्रह दोनों का स्वामी हो)।'),
      source: 'BPHS (Raja Yogas)',
      reasons: [
        rel != null
            ? tr('9th lord ${c.name(l9)} and 10th lord ${c.name(l10)} are $rel.', 'नवमेश ${c.name(l9)} और दशमेश ${c.name(l10)} ${_Chart.relText(rel)}।')
            : tr('9th lord ${c.name(l9)} and 10th lord ${c.name(l10)} are not related.', 'नवमेश ${c.name(l9)} और दशमेश ${c.name(l10)} का संबंध नहीं है।')
      ],
      modifiers: rel != null ? c.modifiers({l9, l10}.toList()) : const [],
    ));
    return out;
  }

  // ---------------------------------------------------------------------------
  // Special named yogas
  // ---------------------------------------------------------------------------

  static List<YogaResult> _specialYogas(_Chart c, String? gender) {
    final out = <YogaResult>[];
    final l = c.lagna;
    final l1 = lord(l, 1);
    YogaResult y(String name, String hindi, bool formed, List<String> planets, String desc, String rule, String source,
            List<String> reasons, {String family = YogaFamilies.special, YogaNature nature = YogaNature.benefic}) =>
        YogaResult(
          category: family,
          name: name,
          hindi: hindi,
          formed: formed,
          strength: formed ? c.strengthOf(planets) : 'Not formed',
          description: desc,
          planets: planets,
          rule: rule,
          source: source,
          reasons: reasons,
          modifiers: formed ? c.modifiers(planets) : const [],
          nature: nature,
        );

    // Amala
    {
      final from = <String>[];
      final benefics = <String>[];
      for (final (label, ref) in [('Lagna', l), if (c.has('moon')) ('Moon', c.rashi('moon'))]) {
        final tenth = c.present(c.all).where((p) => c.houseFrom(p, ref) == 10).toList();
        if (tenth.isNotEmpty && tenth.every(c.isBenefic)) {
          from.add(label);
          benefics.addAll(tenth);
        }
      }
      out.add(y('Amala Yoga', 'अमल योग', from.isNotEmpty, benefics.toSet().toList(),
          'Good reputation, virtuous conduct, publicly appreciated work and lasting prosperity.',
          tr('Only natural benefics occupy the 10th house from the Lagna or from the Moon.', 'लग्न या चन्द्र से 10वें भाव में केवल नैसर्गिक शुभ ग्रह हों।'), 'Phaladeepika ch. 6',
          [
            from.isNotEmpty
                ? tr('Benefic(s) ${c.names(benefics.toSet().toList())} alone in the 10th from the ${from.join(' and ')}.',
                    'शुभ ग्रह ${c.names(benefics.toSet().toList())} अकेले ${L10n.join(from.map(_Chart.ref).toList())} से 10वें भाव में हैं।')
                : tr('The 10th from the Lagna and the Moon is empty or holds a malefic.', 'लग्न और चन्द्र से 10वाँ भाव खाली है या उसमें पाप ग्रह है।')
          ]));
    }

    // Parvata
    {
      final kendraPlanets = c.present(c.all).where((p) => isKendra(c.house(p))).toList();
      final ok68 = c.present(c.all).where((p) => c.house(p) == 6 || c.house(p) == 8).every(c.isBenefic);
      final formed = kendraPlanets.isNotEmpty && kendraPlanets.every(c.isBenefic) && ok68;
      out.add(y('Parvata Yoga', 'पर्वत योग', formed, kendraPlanets,
          'Prosperity, fame, eloquence, charity and leadership of a town or group.',
          tr('Benefics in the Kendras (and no malefic there), with the 6th and 8th houses empty or occupied only by benefics.',
              'केन्द्रों में शुभ ग्रह हों (और वहाँ कोई पाप ग्रह न हो), और 6ठा व 8वाँ भाव खाली हो या केवल शुभ ग्रहों से युक्त हो।'),
          'BPHS (Raja Yogas); Phaladeepika ch. 6',
          [
            kendraPlanets.isEmpty ? tr('No planet in the Kendras.', 'केन्द्रों में कोई ग्रह नहीं है।') : tr('Kendras hold ${c.names(kendraPlanets)}.', 'केन्द्रों में ${c.names(kendraPlanets)} हैं।'),
            ok68 ? tr('The 6th and 8th are empty or benefic.', '6ठा और 8वाँ भाव खाली या शुभ है।') : tr('A malefic occupies the 6th or 8th.', '6ठे या 8वें भाव में पाप ग्रह है।')
          ],
          family: YogaFamilies.raja));
    }

    // Kahala
    {
      final l4 = lord(l, 4), l9 = lord(l, 9);
      final mutual = c.has(l4) && c.has(l9) && isKendra(c.houseFrom(l9, c.rashi(l4)));
      final formed = l4 != l9 && mutual && c.isStrong(l1);
      out.add(y('Kahala Yoga', 'कहल योग', formed, {l4, l9, l1}.toList(),
          'Courage, a stubborn and bold nature, authority and command over others.',
          tr('The lords of the 4th and 9th in Kendras from each other, with a strong Lagna lord.', 'चतुर्थेश और नवमेश एक-दूसरे से केन्द्र में हों और लग्नेश बलवान हो।'),
          'BPHS (Raja Yogas); Phaladeepika ch. 6',
          [
            tr('4th lord ${c.name(l4)} and 9th lord ${c.name(l9)} ${mutual ? 'are' : 'are not'} in mutual Kendras.',
                'चतुर्थेश ${c.name(l4)} और नवमेश ${c.name(l9)} परस्पर केन्द्र में ${mutual ? 'हैं' : 'नहीं हैं'}।'),
            tr('Lagna lord ${c.name(l1)} is ${c.isStrong(l1) ? '' : 'not '}strong (${c.dignity(l1)}, house ${c.house(l1)}).',
                'लग्नेश ${c.name(l1)} ${c.isStrong(l1) ? '' : 'नहीं '}बलवान है (${c.dig(l1)}, ${c.house(l1)}वाँ भाव)।')
          ],
          family: YogaFamilies.raja));
    }

    // Sankha
    {
      final l5 = lord(l, 5), l6 = lord(l, 6), l10 = lord(l, 10), l9 = lord(l, 9);
      final a = l5 != l6 && c.has(l5) && c.has(l6) && isKendra(c.houseFrom(l6, c.rashi(l5))) && c.isStrong(l1);
      final b = c.rashi(l1) == c.rashi(l10) && l1 != l10 && c.rashi(l1) % 3 == 0 && c.isStrong(l9);
      out.add(y('Sankha Yoga', 'शंख योग', a || b, a ? {l5, l6, l1}.toList() : {l1, l10, l9}.toList(),
          'Learning, morality, a long life, prosperity, a good spouse and children; humane and righteous.',
          tr('Lords of the 5th and 6th in mutual Kendras with a strong Lagna lord; or the Lagna lord and 10th lord together in a movable sign with a strong 9th lord.',
              'पंचमेश और षष्ठेश परस्पर केन्द्र में हों और लग्नेश बलवान हो; या लग्नेश और दशमेश साथ में चर राशि में हों और नवमेश बलवान हो।'),
          'BPHS (Raja Yogas); Phaladeepika ch. 6',
          [
            tr('5th lord ${c.name(l5)} and 6th lord ${c.name(l6)}: ${a ? 'in mutual Kendras with a strong Lagna lord' : 'condition 1 not met'}.',
                'पंचमेश ${c.name(l5)} और षष्ठेश ${c.name(l6)}: ${a ? 'परस्पर केन्द्र में, लग्नेश बलवान' : 'पहली शर्त पूरी नहीं'}।'),
            tr('Lagna lord ${c.name(l1)} with 10th lord ${c.name(l10)} in a movable sign: ${b ? 'yes, 9th lord strong' : 'condition 2 not met'}.',
                'लग्नेश ${c.name(l1)} दशमेश ${c.name(l10)} के साथ चर राशि में: ${b ? 'हाँ, नवमेश बलवान' : 'दूसरी शर्त पूरी नहीं'}।')
          ],
          family: YogaFamilies.raja));
    }

    // Bheri
    {
      final l9 = lord(l, 9);
      final allIn = c.present(seven).every((p) => [1, 2, 7, 12].contains(c.house(p)));
      final kendra = ['venus', 'jupiter', l1].every((p) => c.has(p) && isKendra(c.house(p)));
      final formed = (allIn || kendra) && c.isStrong(l9);
      out.add(y('Bheri Yoga', 'भेरी योग', formed, {'venus', 'jupiter', l1, l9}.toList(),
          'Wealth, comforts, reputation, a long life and enjoyment; a noble and famous person.',
          tr('The 9th lord strong and either all planets in the 1st, 2nd, 7th and 12th houses, or Venus, Jupiter and the Lagna lord in Kendras.',
              'नवमेश बलवान हो और या तो सभी ग्रह 1, 2, 7 और 12वें भाव में हों, या शुक्र, गुरु और लग्नेश केन्द्र में हों।'),
          'BPHS (Raja Yogas); Phaladeepika ch. 6',
          [
            tr('9th lord ${c.name(l9)} is ${c.isStrong(l9) ? '' : 'not '}strong.', 'नवमेश ${c.name(l9)} ${c.isStrong(l9) ? '' : 'नहीं '}बलवान है।'),
            allIn
                ? tr('All planets are in the 1st, 2nd, 7th and 12th.', 'सभी ग्रह 1, 2, 7 और 12वें भाव में हैं।')
                : (kendra ? tr('Venus, Jupiter and the Lagna lord are in Kendras.', 'शुक्र, गुरु और लग्नेश केन्द्र में हैं।') : tr('Neither placement pattern is met.', 'कोई भी स्थिति पूरी नहीं होती।')),
          ],
          family: YogaFamilies.raja));
    }

    // Chamara
    {
      final a = c.has(l1) && isExalted(l1, c.rashi(l1)) && isKendra(c.house(l1)) && c.aspects('jupiter', c.rashi(l1));
      final housesOk = [1, 7, 9, 10];
      int? houseWithTwo;
      for (final h in housesOk) {
        if (c.present(c.all).where((p) => c.house(p) == h && c.isBenefic(p)).length >= 2) houseWithTwo = h;
      }
      final formed = a || houseWithTwo != null;
      out.add(y('Chamara Yoga', 'चामर योग', formed, a ? [l1, 'jupiter'] : c.present(c.all).where((p) => c.house(p) == houseWithTwo && c.isBenefic(p)).toList(),
          'Learning, eloquence, leadership and royal recognition; a long life.',
          tr('The Lagna lord exalted in a Kendra and aspected by Jupiter, or two benefics together in the 1st, 7th, 9th or 10th house.',
              'लग्नेश केन्द्र में उच्च का हो और गुरु की दृष्टि हो, या दो शुभ ग्रह 1, 7, 9 या 10वें भाव में साथ हों।'),
          'BPHS (Raja Yogas); Phaladeepika ch. 6',
          [
            a
                ? tr('The Lagna lord is exalted in a Kendra and aspected by Jupiter.', 'लग्नेश केन्द्र में उच्च का है और उस पर गुरु की दृष्टि है।')
                : (houseWithTwo != null ? tr('Two benefics are together in house $houseWithTwo.', 'दो शुभ ग्रह $houseWithTwoवें भाव में साथ हैं।') : tr('Neither condition is met.', 'कोई भी शर्त पूरी नहीं होती।'))
          ],
          family: YogaFamilies.raja));
    }

    // Lakshmi
    {
      final l9 = lord(l, 9);
      final r9 = c.has(l9) ? c.rashi(l9) : -1;
      final dign = r9 >= 0 && (isOwn(l9, r9) || isExalted(l9, r9) || PlanetaryDignity.moolatrikonaSigns[l9] == r9);
      final place = r9 >= 0 && (isKendra(c.house(l9)) || isTrikona(c.house(l9)));
      final formed = dign && place && c.isStrong(l1);
      out.add(y('Lakshmi Yoga', 'लक्ष्मी योग', formed, {l1, l9}.toList(),
          'Prosperity, fortune, nobility, learning and a well-known family.',
          tr('The 9th lord in its own, Moolatrikona or exaltation sign placed in a Kendra or Trikona, with a strong Lagna lord.',
              'नवमेश स्वराशि, मूलत्रिकोण या उच्च राशि में होकर केन्द्र या त्रिकोण में हो और लग्नेश बलवान हो।'),
          'BPHS (Raja Yogas; the formulation varies between texts)',
          [
            tr('9th lord ${c.name(l9)}: ${c.dignity(l9)} in house ${c.house(l9)}.', 'नवमेश ${c.name(l9)}: ${c.dig(l9)}, ${c.house(l9)}वें भाव में।'),
            tr('Lagna lord ${c.name(l1)} is ${c.isStrong(l1) ? '' : 'not '}strong.', 'लग्नेश ${c.name(l1)} ${c.isStrong(l1) ? '' : 'नहीं '}बलवान है।')
          ],
          family: YogaFamilies.dhana));
    }

    // Saraswati
    {
      const ps = ['jupiter', 'venus', 'mercury'];
      final placed = ps.every((p) => c.has(p) && (isKendra(c.house(p)) || isTrikona(c.house(p)) || c.house(p) == 2));
      final jr = c.has('jupiter') ? c.rashi('jupiter') : -1;
      final jupOk = c.has('jupiter') && (isOwn('jupiter', jr) || isExalted('jupiter', jr) || c.dignity('jupiter').contains('Friend'));
      final formed = placed && jupOk;
      out.add(y('Saraswati Yoga', 'सरस्वती योग', formed, ps,
          'Learning, eloquence, scholarship, poetry, the arts and intellectual ability.',
          tr('Jupiter, Venus and Mercury in Kendras, Trikonas or the 2nd house, with Jupiter in its own, exaltation or a friend\'s sign.',
              'गुरु, शुक्र और बुध केन्द्र, त्रिकोण या दूसरे भाव में हों और गुरु स्वराशि, उच्च या मित्र राशि में हो।'),
          'Phaladeepika ch. 6',
          [
            '${tr('Placements', 'स्थिति')}: ${ps.where(c.has).map((p) => '${c.name(p)} ${c.hs(c.house(p))}').join(', ')}.',
            '${c.name('jupiter')}: ${c.dig('jupiter')}.'
          ]));
    }

    // Chatussagara
    {
      final occupied = [1, 4, 7, 10].where((h) => c.present(c.all).any((p) => c.house(p) == h)).toList();
      final formed = occupied.length == 4;
      out.add(y('Chatussagara Yoga', 'चतुःसागर योग', formed, c.present(c.all).where((p) => isKendra(c.house(p))).toList(),
          'Fame reaching the "four oceans": wealth, authority and social prominence.',
          tr('All four Kendras (1, 4, 7, 10) occupied by planets.', 'चारों केन्द्र (1, 4, 7, 10) ग्रहों से भरे हों।'),
          'Phaladeepika ch. 6',
          ['${tr('Occupied Kendras', 'भरे हुए केन्द्र')}: ${occupied.isEmpty ? tr('none', 'कोई नहीं') : occupied.join(', ')}.'],
          family: YogaFamilies.raja));
    }

    // Kurma
    {
      final bens = c.present(['mercury', 'jupiter', 'venus']);
      final mals = c.present(['sun', 'mars', 'saturn']);
      final bensOk = bens.isNotEmpty && bens.every((p) => [5, 6, 7].contains(c.house(p)) && !isDebilitated(p, c.rashi(p)) && !c.dignity(p).contains('Enemy'));
      final malsOk = mals.isNotEmpty && mals.every((p) => [1, 3, 11].contains(c.house(p)) && (isOwn(p, c.rashi(p)) || isExalted(p, c.rashi(p))));
      out.add(y('Kurma Yoga', 'कूर्म योग', bensOk && malsOk, [...bens, ...mals],
          'Fame, authority, wealth, virtue and a happy, steady life.',
          tr('Benefics in the 5th, 6th and 7th in friendly, own or exaltation signs, and malefics in the 1st, 3rd and 11th in own or exaltation signs.',
              'शुभ ग्रह 5, 6 और 7वें भाव में मित्र, स्व या उच्च राशि में हों, और पाप ग्रह 1, 3 और 11वें भाव में स्व या उच्च राशि में हों।'),
          'BPHS (Nabhasa and other yogas)',
          [
            tr('Benefics ${bensOk ? 'meet' : 'do not meet'} the 5/6/7 condition; malefics ${malsOk ? 'meet' : 'do not meet'} the 1/3/11 condition.',
                'शुभ ग्रह 5/6/7 की शर्त ${bensOk ? 'पूरी करते हैं' : 'पूरी नहीं करते'}; पाप ग्रह 1/3/11 की शर्त ${malsOk ? 'पूरी करते हैं' : 'पूरी नहीं करते'}।')
          ]));
    }

    // Matsya
    {
      List<String> at(int h) => c.present(c.all).where((p) => c.house(p) == h).toList();
      final b1 = at(1).isNotEmpty && at(1).every(c.isBenefic);
      final b9 = at(9).isNotEmpty && at(9).every(c.isBenefic);
      final m4 = at(4).isNotEmpty && at(4).every((p) => !c.isBenefic(p));
      final m8 = at(8).isNotEmpty && at(8).every((p) => !c.isBenefic(p));
      final five = at(5).isNotEmpty;
      out.add(y('Matsya Yoga', 'मत्स्य योग', b1 && b9 && m4 && m8 && five, [...at(1), ...at(9), ...at(5)],
          'A learned, compassionate and religious person of good character; an astrologer or knower of time.',
          tr('Benefics in the 1st and 9th, malefics in the 4th and 8th, and planets (of mixed nature) in the 5th.', '1 और 9वें भाव में शुभ ग्रह, 4 और 8वें में पाप ग्रह, और 5वें भाव में (मिश्रित) ग्रह हों।'),
          'BPHS',
          [
            tr('1st benefic: $b1, 9th benefic: $b9, 4th malefic: $m4, 8th malefic: $m8, 5th occupied: $five.',
                '1 में शुभ: ${_yn(b1)}, 9 में शुभ: ${_yn(b9)}, 4 में पाप: ${_yn(m4)}, 8 में पाप: ${_yn(m8)}, 5वाँ भरा: ${_yn(five)}।')
          ]));
    }

    // Devendra
    {
      final l11 = lord(l, 11), l2 = lord(l, 2), l10 = lord(l, 10);
      final fixed = l % 3 == 1;
      final ex1 = c.exchange(l1, l11);
      final ex2 = c.exchange(l2, l10);
      out.add(y('Devendra Yoga', 'देवेन्द्र योग', fixed && ex1 && ex2, {l1, l11, l2, l10}.toList(),
          'Prosperity, attractiveness, authority and enjoyment; a leader admired by many.',
          tr('A fixed-sign Lagna, the Lagna lord and 11th lord exchanging signs, and the 2nd and 10th lords exchanging signs.',
              'स्थिर राशि का लग्न हो, लग्नेश और एकादशेश में राशि परिवर्तन हो, और द्वितीयेश व दशमेश में राशि परिवर्तन हो।'),
          'Later manuals (e.g. Jataka Parijata); rules differ between texts',
          [tr('Fixed Lagna: $fixed; 1st-11th exchange: $ex1; 2nd-10th exchange: $ex2.', 'स्थिर लग्न: ${_yn(fixed)}; 1-11 परिवर्तन: ${_yn(ex1)}; 2-10 परिवर्तन: ${_yn(ex2)}।')]));
    }

    // Indra
    {
      final l5 = lord(l, 5), l11 = lord(l, 11);
      final ex = c.exchange(l5, l11);
      final moon5 = c.has('moon') && c.house('moon') == 5;
      out.add(y('Indra Yoga', 'इन्द्र योग', ex && moon5, {l5, l11, 'moon'}.toList(),
          'Courage, wealth, authority and recognition; a famous and generous person.',
          tr('The 5th and 11th lords exchange signs and the Moon is in the 5th house.', 'पंचमेश और एकादशेश में राशि परिवर्तन हो और चन्द्र 5वें भाव में हो।'),
          'Later manuals; formulations vary',
          [tr('5th-11th exchange: $ex; Moon in the 5th: $moon5.', '5-11 परिवर्तन: ${_yn(ex)}; चन्द्र 5वें भाव में: ${_yn(moon5)}।')]));
    }

    // Mahabhagya
    {
      final day = c.isDayBirth;
      bool odd(int r) => r % 2 == 0; // Aries (0) is an odd sign
      final signs = [l, if (c.has('sun')) c.rashi('sun'), if (c.has('moon')) c.rashi('moon')];
      final male = day == true && signs.every(odd);
      final female = day == false && signs.every((r) => !odd(r));
      final formed = gender == 'Male' ? male : (gender == 'Female' ? female : male || female);
      out.add(y('Mahabhagya Yoga', 'महाभाग्य योग', formed, const ['sun', 'moon'],
          'Great fortune, generosity, fame and a long life.',
          tr(
              'For a man born by day: Lagna, Sun and Moon in odd signs. For a woman born by night: Lagna, Sun and Moon in even signs. '
                  '(A historical rule, reported as such.)',
              'दिन में जन्मे पुरुष के लिए: लग्न, सूर्य और चन्द्र विषम राशियों में। रात में जन्मी स्त्री के लिए: लग्न, सूर्य और चन्द्र सम राशियों में। (यह ऐतिहासिक नियम है, जैसा है वैसा बताया गया है।)'),
          'Phaladeepika ch. 6; BPHS',
          [
            day == null
                ? tr('Day/night birth unknown (no ascendant degree).', 'दिन/रात का जन्म ज्ञात नहीं (लग्न अंश नहीं)।')
                : (day ? tr('Born during the day.', 'दिन में जन्म।') : tr('Born at night.', 'रात में जन्म।')),
            tr('Lagna, Sun and Moon signs are ${signs.every(odd) ? 'all odd' : (signs.every((r) => !odd(r)) ? 'all even' : 'mixed odd/even')}.',
                'लग्न, सूर्य और चन्द्र की राशियाँ ${signs.every(odd) ? 'सभी विषम' : (signs.every((r) => !odd(r)) ? 'सभी सम' : 'मिश्रित विषम/सम')} हैं।'),
            if (gender == null) tr('Gender not recorded in the profile: both versions were checked.', 'प्रोफ़ाइल में लिंग दर्ज नहीं है: दोनों स्थितियाँ जाँची गईं।'),
          ]));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Dhana and Daridra
  // ---------------------------------------------------------------------------

  static List<YogaResult> _dhanaYogas(_Chart c) {
    final l = c.lagna;
    final out = <YogaResult>[];
    final seen = <String>{};
    const pairs = [(2, 11), (2, 5), (2, 9), (5, 11), (9, 11), (1, 2), (1, 11), (1, 5), (1, 9), (5, 9)];
    for (final (a, b) in pairs) {
      final la = lord(l, a), lb = lord(l, b);
      if (la == lb || !c.has(la) || !c.has(lb)) continue;
      final rel = c.relation(la, lb);
      if (rel == null) continue;
      final key = ([la, lb]..sort()).join('-');
      if (!seen.add(key)) continue;
      // 1-5, 1-9 and 5-9 pairs are wealth yogas only together with the 2nd/11th; skip as Raja yogas cover them.
      if ((a == 1 || a == 5) && (b == 5 || b == 9)) continue;
      out.add(YogaResult(
        category: YogaFamilies.dhana,
        name: 'Dhana Yoga (${VedicMath.ordinal(a)} & ${VedicMath.ordinal(b)} lords)',
        hindi: 'धन योग',
        formed: true,
        strength: c.strengthOf([la, lb]),
        description: 'Wealth-producing potential through the matters of the ${VedicMath.ordinal(a)} and ${VedicMath.ordinal(b)} houses; realised in the Dashas of these lords.',
        planets: [la, lb],
        rule: tr('Lords of the wealth houses (1, 2, 5, 9, 11) related by conjunction, mutual aspect or exchange of signs.',
            'धन भावों (1, 2, 5, 9, 11) के स्वामी युति, परस्पर दृष्टि या राशि परिवर्तन से जुड़े हों।'),
        source: 'BPHS (Dhana Yogas)',
        reasons: [
          tr('${c.name(la)} (lord of ${VedicMath.ordinal(a)}) and ${c.name(lb)} (lord of ${VedicMath.ordinal(b)}) are $rel.',
              '${c.name(la)} ($aवें का स्वामी) और ${c.name(lb)} ($bवें का स्वामी) ${_Chart.relText(rel)}।')
        ],
        modifiers: c.modifiers([la, lb]),
      ));
    }
    if (out.isEmpty) {
      out.add(YogaResult(
        category: YogaFamilies.dhana,
        name: 'Dhana Yoga',
        hindi: 'धन योग',
        formed: false,
        strength: 'Not formed',
        description: 'Wealth-producing potential.',
        rule: tr('Lords of the wealth houses (1, 2, 5, 9, 11) related by conjunction, mutual aspect or exchange of signs.',
            'धन भावों (1, 2, 5, 9, 11) के स्वामी युति, परस्पर दृष्टि या राशि परिवर्तन से जुड़े हों।'),
        source: 'BPHS (Dhana Yogas)',
        reasons: [tr('No pair of 2nd/11th-related wealth lords is connected.', 'धन भावों के स्वामियों का कोई जोड़ा आपस में जुड़ा नहीं है।')],
      ));
    }
    return out;
  }

  static List<YogaResult> _daridraYogas(_Chart c) {
    final l = c.lagna;
    final l1 = lord(l, 1), l2 = lord(l, 2), l11 = lord(l, 11), l12 = lord(l, 12), l6 = lord(l, 6), l7 = lord(l, 7);
    final out = <YogaResult>[];
    YogaResult d(String name, bool formed, List<String> planets, String rule, List<String> reasons, {List<String> mods = const []}) => YogaResult(
          category: YogaFamilies.daridra,
          name: name,
          hindi: 'दरिद्र योग',
          formed: formed,
          strength: !formed ? 'Not formed' : (mods.isEmpty ? 'Challenging' : 'Mitigated'),
          description: 'Obstacles to accumulating resources. One isolated condition does not mean lifelong poverty; the whole chart and Dasha timing matter.',
          planets: planets,
          rule: rule,
          source: 'BPHS (Daridra Yogas)',
          reasons: reasons,
          modifiers: mods,
          nature: YogaNature.adverse,
        );

    final ex112 = c.exchange(l1, l12);
    final maraka = c.has(l2) && c.has(l7) && (c.rashi(l2) == c.rashi(l1) || c.rashi(l7) == c.rashi(l1) || c.aspects(l2, c.rashi(l1)) || c.aspects(l7, c.rashi(l1)));
    out.add(d('Daridra Yoga (1st-12th exchange)', l1 != l12 && ex112 && maraka, [l1, l12],
        tr('The Lagna lord in the 12th and the 12th lord in the Lagna, joined or aspected by a maraka (2nd or 7th lord).',
            'लग्नेश 12वें भाव में और द्वादशेश लग्न में हो, और मारक (द्वितीयेश या सप्तमेश) की युति या दृष्टि हो।'),
        [
          tr('Lagna lord ${c.name(l1)} and 12th lord ${c.name(l12)} ${ex112 ? 'exchange signs' : 'do not exchange signs'}${ex112 ? (maraka ? ', with maraka influence' : ', without maraka influence') : ''}.',
              'लग्नेश ${c.name(l1)} और द्वादशेश ${c.name(l12)} में राशि परिवर्तन ${ex112 ? 'है' : 'नहीं है'}${ex112 ? (maraka ? ', मारक प्रभाव के साथ' : ', मारक प्रभाव के बिना') : ''}।')
        ]));

    final ex16 = c.exchange(l1, l6);
    final maraka6 = c.has(l2) && c.has(l7) && (c.aspects(l2, c.rashi(l1)) || c.aspects(l7, c.rashi(l1)) || c.rashi(l2) == c.rashi(l1) || c.rashi(l7) == c.rashi(l1));
    out.add(d('Daridra Yoga (1st-6th exchange)', l1 != l6 && ex16 && maraka6, [l1, l6],
        tr('The Lagna lord in the 6th and the 6th lord in the Lagna, joined or aspected by the 2nd or 7th lord.', 'लग्नेश 6ठे भाव में और षष्ठेश लग्न में हो, और द्वितीयेश या सप्तमेश की युति या दृष्टि हो।'),
        [tr('Lagna lord ${c.name(l1)} and 6th lord ${c.name(l6)} ${ex16 ? 'exchange signs' : 'do not exchange signs'}.', 'लग्नेश ${c.name(l1)} और षष्ठेश ${c.name(l6)} में राशि परिवर्तन ${ex16 ? 'है' : 'नहीं है'}।')]));

    final h11 = c.has(l11) ? c.house(l11) : 0;
    final h2 = c.has(l2) ? c.house(l2) : 0;
    final both = isDusthana(h11) && isDusthana(h2) && l2 != l11;
    final mods = <String>[
      if (both && c.isStrong(l1)) tr('Mitigated: the Lagna lord is strong.', 'प्रभाव कम: लग्नेश बलवान है।'),
      if (both && c.has('jupiter') && isKendra(c.house('jupiter'))) tr('Mitigated: Jupiter is in a Kendra.', 'प्रभाव कम: गुरु केन्द्र में है।'),
    ];
    out.add(d('Daridra Yoga (wealth lords in dusthanas)', both, [l2, l11],
        tr('Both the 2nd lord (accumulated wealth) and the 11th lord (gains) placed in dusthanas (6, 8, 12).', 'द्वितीयेश (संचित धन) और एकादशेश (लाभ) दोनों दुःस्थानों (6, 8, 12) में हों।'),
        [tr('2nd lord ${c.name(l2)} in house $h2; 11th lord ${c.name(l11)} in house $h11.', 'द्वितीयेश ${c.name(l2)} $h2वें भाव में; एकादशेश ${c.name(l11)} $h11वें भाव में।')],
        mods: mods));
    return out;
  }

  // ---------------------------------------------------------------------------
  // Viparita Raja
  // ---------------------------------------------------------------------------

  static List<YogaResult> _viparita(_Chart c) {
    final l = c.lagna;
    const data = [
      (6, 'Harsha', 'हर्ष', 'Happiness, good health, victory over enemies and gains through adversity.'),
      (8, 'Sarala', 'सरल', 'Long life, fearlessness, learning and prosperity after difficulties.'),
      (12, 'Vimala', 'विमल', 'Frugality, independence, good conduct and wealth through saving.'),
    ];
    final good = {for (final h in [1, 2, 4, 5, 7, 9, 10, 11]) lord(l, h)};
    return [
      for (final (h, name, hindi, desc) in data)
        () {
          final p = lord(l, h);
          final hh = c.has(p) ? c.house(p) : 0;
          final inDus = isDusthana(hh);
          final ownsGood = good.contains(p);
          final joined = c.present(c.all).where((q) => q != p && good.contains(q) && !{lord(l, 6), lord(l, 8), lord(l, 12)}.contains(q) && c.rashi(q) == c.rashi(p)).toList();
          final formed = inDus;
          return YogaResult(
            category: YogaFamilies.viparita,
            name: '$name Yoga',
            hindi: '$hindi योग',
            formed: formed,
            strength: !formed ? 'Not formed' : (joined.isEmpty && !ownsGood ? 'Strong' : 'Moderate'),
            description: '$desc A difficulty becomes a source of resilience or advantage.',
            planets: [p],
            rule: tr('The ${VedicMath.ordinal(h)} lord placed in a dusthana (6, 8 or 12). It is purest when that lord does not also own a good house and is not joined by lords of good houses.',
                '$hवें भाव का स्वामी दुःस्थान (6, 8 या 12) में हो। यह सबसे शुद्ध तब है जब वह स्वामी किसी शुभ भाव का भी स्वामी न हो और शुभ भावों के स्वामियों के साथ न हो।'),
            source: 'Phaladeepika ch. 6; Uttara Kalamrita',
            reasons: [tr('${VedicMath.ordinal(h)} lord ${c.name(p)} is in house $hh.', '$hवें भाव का स्वामी ${c.name(p)} $hhवें भाव में है।')],
            modifiers: formed
                ? [
                    if (ownsGood) tr('${c.name(p)} also owns a good house, so the reversal is mixed.', '${c.name(p)} किसी शुभ भाव का भी स्वामी है, इसलिए फल मिश्रित है।'),
                    if (joined.isNotEmpty) tr('Joined by ${c.names(joined)} (lords of good houses), which dilutes it.', '${c.names(joined)} (शुभ भावों के स्वामी) साथ हैं, जिससे इसका प्रभाव घटता है।'),
                    ...c.modifiers([p]),
                  ]
                : const [],
          );
        }(),
    ];
  }

  // ---------------------------------------------------------------------------
  // Parivartana
  // ---------------------------------------------------------------------------

  static List<YogaResult> _parivartana(_Chart c) {
    final out = <YogaResult>[];
    final ps = c.present(seven);
    for (int i = 0; i < ps.length; i++) {
      for (int j = i + 1; j < ps.length; j++) {
        final a = ps[i], b = ps[j];
        if (!c.exchange(a, b)) continue;
        final ha = c.house(a), hb = c.house(b);
        final type = isDusthana(ha) || isDusthana(hb) ? 'Dainya' : (ha == 3 || hb == 3 ? 'Khala' : 'Maha');
        out.add(YogaResult(
          category: YogaFamilies.parivartana,
          name: '$type Parivartana Yoga',
          hindi: '${type == 'Maha' ? 'महा' : (type == 'Khala' ? 'खल' : 'दैन्य')} परिवर्तन योग',
          formed: true,
          strength: type == 'Maha' ? c.strengthOf([a, b], bonus: 0.5) : (type == 'Khala' ? 'Mixed' : 'Challenging'),
          description: switch (type) {
            'Maha' => 'A powerful exchange between good houses: the two houses support each other, bringing wealth, status and comforts.',
            'Khala' => 'Exchange involving the 3rd house: fluctuating fortunes, sometimes arrogance, success through effort.',
            _ => 'Exchange involving a dusthana: obstacles and struggles connected with these houses, which can turn into growth.',
          },
          planets: [a, b],
          rule: tr('Two planets each in the other\'s sign. Maha: houses among 1, 2, 4, 5, 7, 9, 10, 11; Khala: involves the 3rd; Dainya: involves the 6th, 8th or 12th.',
              'दो ग्रह एक-दूसरे की राशि में हों। महा: भाव 1, 2, 4, 5, 7, 9, 10, 11 में से; खल: तीसरा भाव शामिल; दैन्य: 6, 8 या 12वाँ भाव शामिल।'),
          source: 'Phaladeepika ch. 6',
          reasons: [
            tr('${c.name(a)} in ${c.signName(a)} (house $ha) and ${c.name(b)} in ${c.signName(b)} (house $hb) exchange signs.',
                '${c.name(a)} ${c.signName(a)} ($haवाँ भाव) में और ${c.name(b)} ${c.signName(b)} ($hbवाँ भाव) में हैं; दोनों में राशि परिवर्तन है।')
          ],
          modifiers: c.modifiers([a, b]),
          nature: type == 'Maha' ? YogaNature.benefic : (type == 'Khala' ? YogaNature.mixed : YogaNature.adverse),
        ));
      }
    }
    if (out.isEmpty) {
      out.add(YogaResult(
        category: YogaFamilies.parivartana,
        name: 'Parivartana Yoga',
        hindi: 'परिवर्तन योग',
        formed: false,
        strength: 'Not formed',
        description: 'Mutual exchange of signs.',
        rule: tr('Two planets each in the other\'s sign.', 'दो ग्रह एक-दूसरे की राशि में हों।'),
        source: 'Phaladeepika ch. 6',
        reasons: [tr('No two planets exchange signs.', 'किन्हीं दो ग्रहों में राशि परिवर्तन नहीं है।')],
      ));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Neecha Bhanga
  // ---------------------------------------------------------------------------

  static List<YogaResult> _neechaBhanga(_Chart c) {
    final out = <YogaResult>[];
    final refs = [('Lagna', c.lagna), if (c.has('moon')) ('Moon', c.rashi('moon'))];
    for (final p in c.present(seven)) {
      final r = c.rashi(p);
      if (!isDebilitated(p, r)) continue;
      final dispositor = VedicMath.rashis[r].lord;
      final exaltLord = VedicMath.rashis[VedicMath.planets[p]!.exalt].lord;
      final exaltsHere = VedicMath.planets.entries
          .where((e) => e.key != 'rahu' && e.key != 'ketu' && e.value.exalt == r)
          .map((e) => e.key)
          .toList();
      final conditions = <String>[];
      void kendraCheck(String q, String role, String roleHi) {
        if (!c.has(q) || q == p) return;
        for (final (label, ref) in refs) {
          if (isKendra(c.houseFrom(q, ref))) {
            conditions.add(tr('$role ${c.name(q)} is in a Kendra from the $label.', '$roleHi ${c.name(q)}, ${_Chart.ref(label)} से केन्द्र में है।'));
            return;
          }
        }
      }

      kendraCheck(dispositor, 'The lord of the debilitation sign,', 'नीच राशि का स्वामी');
      kendraCheck(exaltLord, 'The lord of its exaltation sign,', 'उसकी उच्च राशि का स्वामी');
      for (final q in exaltsHere) {
        kendraCheck(q, 'The planet exalted in this sign,', 'इस राशि में उच्च होने वाला ग्रह');
      }
      final dn = c.name(dispositor);
      if (c.has(dispositor) && dispositor != p && c.aspects(dispositor, r)) conditions.add(tr('Aspected by its dispositor $dn.', 'राशि स्वामी $dn की दृष्टि है।'));
      if (c.has(dispositor) && dispositor != p && c.rashi(dispositor) == r) conditions.add(tr('Conjunct its dispositor $dn.', 'राशि स्वामी $dn के साथ युति है।'));
      if (c.has(exaltLord) && exaltLord != p && c.rashi(exaltLord) == r) {
        conditions.add(tr('Conjunct its exaltation lord ${c.name(exaltLord)}.', 'उच्च राशि के स्वामी ${c.name(exaltLord)} के साथ युति है।'));
      }
      if (c.exchange(p, dispositor)) conditions.add(tr('Exchanges signs with its dispositor $dn.', 'राशि स्वामी $dn के साथ राशि परिवर्तन है।'));
      if (isExalted(p, c.navamsa(p))) conditions.add(tr('Exalted in the Navamsa.', 'नवांश में उच्च का है।'));
      if (isKendra(c.house(p))) conditions.add(tr('The debilitated planet itself is in a Kendra from the Lagna.', 'नीच ग्रह स्वयं लग्न से केन्द्र में है।'));

      final formed = conditions.isNotEmpty;
      final raja = conditions.length >= 2;
      out.add(YogaResult(
        category: YogaFamilies.neecha,
        name: formed ? (raja ? 'Neecha Bhanga Raja Yoga (${c.en(p)})' : 'Neecha Bhanga (${c.en(p)})') : 'Debilitated ${c.en(p)} (no cancellation)',
        hindi: formed ? (raja ? 'नीचभंग राज योग (${c.name(p)})' : 'नीचभंग (${c.name(p)})') : 'नीच ${c.name(p)} (भंग नहीं)',
        formed: formed,
        strength: !formed ? 'Debilitated' : (raja ? 'Strong' : 'Moderate'),
        description: formed
            ? 'The debilitation of ${c.en(p)} is cancelled: after early difficulty its significations can rise strongly${raja ? ', a rise after hardship' : ''}.'
            : '${c.en(p)} is debilitated in ${c.signEn(p)} with no classical cancellation; its significations need support.',
        planets: [p, if (c.has(dispositor) && dispositor != p) dispositor],
        rule: tr(
            'A debilitated planet is cancelled when: the lord of its debilitation sign, the lord of its exaltation sign, or the planet exalted in that sign is in a Kendra from the Lagna or Moon; '
                'or it is aspected by or conjunct its dispositor; or it exchanges signs with its dispositor; or it is exalted in the Navamsa. '
                'This app calls two or more conditions a Neecha Bhanga Raja Yoga.',
            'नीच ग्रह का नीचत्व भंग होता है जब: उसकी नीच राशि का स्वामी, उच्च राशि का स्वामी, या उस राशि में उच्च होने वाला ग्रह लग्न या चन्द्र से केन्द्र में हो; '
                'या राशि स्वामी की दृष्टि या युति हो; या राशि स्वामी से राशि परिवर्तन हो; या वह नवांश में उच्च का हो। '
                'दो या अधिक शर्तें पूरी होने पर यह ऐप इसे नीचभंग राज योग कहता है।'),
        source: 'Phaladeepika ch. 7; BPHS',
        reasons: [tr('${c.name(p)} is debilitated in ${c.signName(p)} (house ${c.house(p)}).', '${c.name(p)} ${c.signName(p)} (${c.house(p)}वाँ भाव) में नीच का है।'), ...conditions],
        nature: formed ? YogaNature.benefic : YogaNature.adverse,
      ));
    }
    if (out.isEmpty) {
      out.add(YogaResult(
        category: YogaFamilies.neecha,
        name: 'Neecha Bhanga',
        hindi: 'नीचभंग',
        formed: false,
        strength: 'Not applicable',
        description: 'Cancellation of debilitation.',
        rule: tr('Applies only to debilitated planets.', 'यह केवल नीच ग्रहों पर लागू होता है।'),
        source: 'Phaladeepika ch. 7',
        reasons: [tr('No planet is debilitated in this chart.', 'इस कुंडली में कोई ग्रह नीच का नहीं है।')],
      ));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Kartari
  // ---------------------------------------------------------------------------

  static List<YogaResult> _kartari(_Chart c) {
    final out = <YogaResult>[];
    for (final (label, ref) in [('Lagna', c.lagna), if (c.has('moon')) ('Moon', c.rashi('moon'))]) {
      final second = c.present(c.all).where((p) => c.houseFrom(p, ref) == 2).toList();
      final twelfth = c.present(c.all).where((p) => c.houseFrom(p, ref) == 12).toList();
      final shubha = second.isNotEmpty && twelfth.isNotEmpty && [...second, ...twelfth].every(c.isBenefic);
      final papa = second.isNotEmpty && twelfth.isNotEmpty && [...second, ...twelfth].every((p) => !c.isBenefic(p));
      final lh = _Chart.ref(label);
      final reason = second.isEmpty || twelfth.isEmpty
          ? tr('The 2nd and 12th from the $label are not both occupied.', '$lh से दूसरा और 12वाँ भाव दोनों भरे हुए नहीं हैं।')
          : tr('${c.names(second)} in the 2nd and ${c.names(twelfth)} in the 12th from the $label.', '$lh से दूसरे भाव में ${c.names(second)} और 12वें भाव में ${c.names(twelfth)} है।');
      out.add(YogaResult(
        category: YogaFamilies.kartari,
        name: 'Subha Kartari Yoga ($label)',
        hindi: 'शुभ कर्तरी योग ($lh)',
        formed: shubha,
        strength: shubha ? 'Protective' : 'Not formed',
        description: label == 'Lagna' ? 'The self and body are protected and supported: health, confidence and good fortune.' : 'The mind is protected: emotional stability and support from others.',
        planets: [...second, ...twelfth],
        rule: tr('Natural benefics in both the 2nd and 12th from the $label (hemming it in).', '$lh से दूसरे और 12वें, दोनों भावों में नैसर्गिक शुभ ग्रह हों (उसे घेरते हुए)।'),
        source: 'Phaladeepika; Jaimini tradition',
        reasons: [reason],
      ));
      out.add(YogaResult(
        category: YogaFamilies.kartari,
        name: 'Papa Kartari Yoga ($label)',
        hindi: 'पाप कर्तरी योग ($lh)',
        formed: papa,
        strength: papa ? 'Challenging' : 'Not formed',
        description: label == 'Lagna' ? 'The self is hemmed in by malefics: pressure, obstacles and health concerns.' : 'The mind is hemmed in by malefics: anxiety and restlessness.',
        planets: [...second, ...twelfth],
        rule: tr('Natural malefics in both the 2nd and 12th from the $label.', '$lh से दूसरे और 12वें, दोनों भावों में नैसर्गिक पाप ग्रह हों।'),
        source: 'Phaladeepika; Jaimini tradition',
        reasons: [reason],
        nature: YogaNature.adverse,
      ));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Nabhasa (32)
  // ---------------------------------------------------------------------------

  static const Map<String, String> _nabhasaRulesHi = {
    'Rajju': 'सातों ग्रह चर राशियों (मेष, कर्क, तुला, मकर) में हों।',
    'Musala': 'सातों ग्रह स्थिर राशियों (वृषभ, सिंह, वृश्चिक, कुंभ) में हों।',
    'Nala': 'सातों ग्रह द्विस्वभाव राशियों (मिथुन, कन्या, धनु, मीन) में हों।',
    'Mala (Srik)': 'गुरु, शुक्र और बुध तीन अलग-अलग केन्द्रों में हों और कोई पाप ग्रह (सूर्य, मंगल, शनि) केन्द्र में न हो।',
    'Sarpa': 'सूर्य, मंगल और शनि तीन अलग-अलग केन्द्रों में हों और कोई शुभ ग्रह केन्द्र में न हो।',
    'Gada': 'सभी ग्रह दो लगातार केन्द्रों (1-4, 4-7, 7-10 या 10-1) में हों।',
    'Shakata': 'सभी ग्रह 1 और 7वें भाव में हों।',
    'Vihaga': 'सभी ग्रह 4 और 10वें भाव में हों।',
    'Shringataka': 'सभी ग्रह 1, 5 और 9वें भाव (लग्न के त्रिकोण) में हों।',
    'Hala': 'सभी ग्रह लग्न त्रिकोण के अलावा किसी एक त्रिकोण समूह में हों: 2-6-10, 3-7-11 या 4-8-12।',
    'Vajra': 'सभी शुभ ग्रह (चन्द्र, बुध, गुरु, शुक्र) 1 और 7वें भाव में, सभी पाप ग्रह (सूर्य, मंगल, शनि) 4 और 10वें भाव में हों।',
    'Yava': 'सभी पाप ग्रह 1 और 7वें भाव में, सभी शुभ ग्रह 4 और 10वें भाव में हों (वज्र का उल्टा)।',
    'Kamala (Padma)': 'सभी ग्रह चारों केन्द्रों में हों और चारों केन्द्र भरे हों।',
    'Vapi': 'सभी ग्रह पणफर भावों (2, 5, 8, 11) में या सभी आपोक्लिम भावों (3, 6, 9, 12) में हों।',
    'Yupa': 'सभी ग्रह लग्न से चार भावों (1-4) में हों और हर भाव भरा हो।',
    'Ishu (Shara)': 'सभी ग्रह 4थे भाव से चार भावों (4-7) में हों और हर भाव भरा हो।',
    'Shakti': 'सभी ग्रह 7वें भाव से चार भावों (7-10) में हों और हर भाव भरा हो।',
    'Danda': 'सभी ग्रह 10वें भाव से चार भावों (10-1) में हों और हर भाव भरा हो।',
    'Nauka': 'सातों ग्रह लग्न से सात भावों (1-7) में, हर भाव में एक।',
    'Kuta': 'सातों ग्रह 4थे भाव से सात भावों (4-10) में।',
    'Chhatra': 'सातों ग्रह 7वें भाव से सात भावों (7-1) में।',
    'Chapa (Karmuka)': 'सातों ग्रह 10वें भाव से सात भावों (10-4) में।',
    'Ardha Chandra': 'सातों ग्रह किसी ऐसे भाव से शुरू होकर लगातार सात भावों में हों जो केन्द्र न हो।',
    'Chakra': 'ग्रह लग्न से शुरू होकर एक छोड़कर छह भावों (1, 3, 5, 7, 9, 11) में हों और छहों भरे हों।',
    'Samudra': 'ग्रह दूसरे भाव से शुरू होकर एक छोड़कर छह भावों (2, 4, 6, 8, 10, 12) में हों और छहों भरे हों।',
  };

  static List<YogaResult> _nabhasa(_Chart c) {
    final ps = c.present(seven);
    if (ps.length < 7) return const [];
    final houses = {for (final p in ps) p: c.house(p)};
    final occupied = houses.values.toSet();
    final signs = ps.map(c.rashi).toSet();
    bool within(Set<int> hs) => occupied.every(hs.contains);
    bool exactly(Set<int> hs) => within(hs) && hs.every(occupied.contains);
    final out = <YogaResult>[];
    const src = 'BPHS (Nabhasa Yogas); Brihat Jataka ch. 12; Saravali';
    final hl = (occupied.toList()..sort()).join(', ');
    final reason = tr('The seven planets occupy houses $hl (${signs.length} sign${signs.length == 1 ? '' : 's'}).', 'सातों ग्रह भाव $hl में हैं (${signs.length} राशियाँ)।');

    void add(String family, String name, String hindi, bool formed, String rule, String desc, {YogaNature nature = YogaNature.mixed}) {
      out.add(YogaResult(
        category: family,
        name: '$name Yoga',
        hindi: '$hindi योग',
        formed: formed,
        strength: formed ? 'Formed' : 'Not formed',
        description: desc,
        planets: formed ? ps : const [],
        rule: tr(rule, _nabhasaRulesHi[name] ?? rule),
        source: src,
        reasons: [reason],
        nature: nature,
      ));
    }

    // Ashraya
    add(YogaFamilies.nabhasaAshraya, 'Rajju', 'रज्जु', ps.every((p) => c.rashi(p) % 3 == 0), 'All seven planets in movable signs (Aries, Cancer, Libra, Capricorn).',
        'Movement, travel, mobility and changing circumstances; fond of wandering.');
    add(YogaFamilies.nabhasaAshraya, 'Musala', 'मुसल', ps.every((p) => c.rashi(p) % 3 == 1), 'All seven planets in fixed signs (Taurus, Leo, Scorpio, Aquarius).',
        'Firmness, stability, persistence, honour and status.', nature: YogaNature.benefic);
    add(YogaFamilies.nabhasaAshraya, 'Nala', 'नल', ps.every((p) => c.rashi(p) % 3 == 2), 'All seven planets in dual signs (Gemini, Virgo, Sagittarius, Pisces).',
        'Adaptability, mixed circumstances and practical intelligence.');

    // Dala
    final bens = ['jupiter', 'venus', 'mercury'];
    final mals = ['sun', 'mars', 'saturn'];
    final benK = bens.map((p) => houses[p]!).where(isKendra).toSet();
    final malK = mals.map((p) => houses[p]!).where(isKendra).toSet();
    final mala = bens.every((p) => isKendra(houses[p]!)) && benK.length == 3 && malK.isEmpty;
    final sarpa = mals.every((p) => isKendra(houses[p]!)) && malK.length == 3 && benK.isEmpty;
    add(YogaFamilies.nabhasaDala, 'Mala (Srik)', 'माला', mala, 'Jupiter, Venus and Mercury in three different Kendras, with no malefic (Sun, Mars, Saturn) in a Kendra.',
        'Comforts, prosperity, vehicles and pleasant circumstances.', nature: YogaNature.benefic);
    add(YogaFamilies.nabhasaDala, 'Sarpa', 'सर्प', sarpa, 'Sun, Mars and Saturn in three different Kendras, with no benefic in a Kendra.',
        'Struggle, tension and difficult circumstances.', nature: YogaNature.adverse);

    // Akriti (20)
    final b = _nabhasaBenefics.where(houses.containsKey).map((p) => houses[p]!).toSet();
    final m = _nabhasaMalefics.map((p) => houses[p]!).toSet();
    bool consecutive(int start, int n) => exactly({for (int i = 0; i < n; i++) (start - 1 + i) % 12 + 1});
    final gada = [{1, 4}, {4, 7}, {7, 10}, {10, 1}].any(exactly);
    add(YogaFamilies.nabhasaAkriti, 'Gada', 'गदा', gada, 'All planets in two adjacent Kendras (1-4, 4-7, 7-10 or 10-1).',
        'Wealth through effort, devotion to religious duties and learning.');
    add(YogaFamilies.nabhasaAkriti, 'Shakata', 'शकट', exactly({1, 7}), 'All planets in the 1st and 7th houses.',
        'A cart-like life of ups and downs; earning through vehicles or labour.', nature: YogaNature.adverse);
    add(YogaFamilies.nabhasaAkriti, 'Vihaga', 'विहग', exactly({4, 10}), 'All planets in the 4th and 10th houses.',
        'A wanderer or messenger; travel and changeable occupation.');
    add(YogaFamilies.nabhasaAkriti, 'Shringataka', 'शृंगाटक', exactly({1, 5, 9}), 'All planets in the 1st, 5th and 9th houses (the trines from the Lagna).',
        'Happiness, prosperity and a quarrelsome but fortunate nature; happy later life.', nature: YogaNature.benefic);
    final hala = [{2, 6, 10}, {3, 7, 11}, {4, 8, 12}].any(within) && occupied.length >= 2;
    add(YogaFamilies.nabhasaAkriti, 'Hala', 'हल', hala, 'All planets in one group of mutually trine houses other than the Lagna trine: 2-6-10, 3-7-11 or 4-8-12.',
        'Agriculture, hard work and a large family; earning through the land.');
    final vajra = b.every({1, 7}.contains) && m.every({4, 10}.contains) && b.isNotEmpty && m.isNotEmpty;
    final yava = m.every({1, 7}.contains) && b.every({4, 10}.contains) && b.isNotEmpty && m.isNotEmpty;
    add(YogaFamilies.nabhasaAkriti, 'Vajra', 'वज्र', vajra, 'All benefics (Moon, Mercury, Jupiter, Venus) in the 1st and 7th, all malefics (Sun, Mars, Saturn) in the 4th and 10th.',
        'Happy early and late life, courage and good looks; difficulties in middle age.');
    add(YogaFamilies.nabhasaAkriti, 'Yava', 'यव', yava, 'All malefics in the 1st and 7th, all benefics in the 4th and 10th (the complement of Vajra).',
        'Happiness and wealth in middle age; charitable and steady.');
    final kamala = exactly({1, 4, 7, 10});
    add(YogaFamilies.nabhasaAkriti, 'Kamala (Padma)', 'कमल', kamala, 'All planets in the four Kendras, with all four occupied.',
        'Fame, virtue, a long life and high status, like a lotus.', nature: YogaNature.benefic);
    final vapi = !kamala && (within({2, 5, 8, 11}) || within({3, 6, 9, 12}));
    add(YogaFamilies.nabhasaAkriti, 'Vapi', 'वापी', vapi, 'All planets in the Panapharas (2, 5, 8, 11) or all in the Apoklimas (3, 6, 9, 12).',
        'Accumulation and hoarding of wealth; comfortable but not generous.');
    add(YogaFamilies.nabhasaAkriti, 'Yupa', 'यूप', consecutive(1, 4), 'All planets in the four houses from the Lagna (1-4), each occupied.',
        'Spiritual knowledge, sacrifice and religious rites; liberal and virtuous.');
    add(YogaFamilies.nabhasaAkriti, 'Ishu (Shara)', 'इषु', consecutive(4, 4), 'All planets in the four houses from the 4th (4-7), each occupied.',
        'Hunting, weapons or making arrows; a harsh but skilled worker.');
    add(YogaFamilies.nabhasaAkriti, 'Shakti', 'शक्ति', consecutive(7, 4), 'All planets in the four houses from the 7th (7-10), each occupied.',
        'Poverty and difficulties early on, but perseverance, success in disputes and a long life.');
    add(YogaFamilies.nabhasaAkriti, 'Danda', 'दण्ड', consecutive(10, 4), 'All planets in the four houses from the 10th (10-1), each occupied.',
        'Separation from family and dependence on others; serving others.', nature: YogaNature.adverse);
    add(YogaFamilies.nabhasaAkriti, 'Nauka', 'नौका', consecutive(1, 7), 'The seven planets in the seven houses from the Lagna (1-7), one in each.',
        'Earning from water, shipping or travel; fame but some instability.');
    add(YogaFamilies.nabhasaAkriti, 'Kuta', 'कूट', consecutive(4, 7), 'The seven planets in the seven houses from the 4th (4-10).',
        'Deceitful or a jailer in classical texts; living in hills or forts.', nature: YogaNature.adverse);
    add(YogaFamilies.nabhasaAkriti, 'Chhatra', 'छत्र', consecutive(7, 7), 'The seven planets in the seven houses from the 7th (7-1).',
        'Protector of family and dependents; happy in early and late life.', nature: YogaNature.benefic);
    add(YogaFamilies.nabhasaAkriti, 'Chapa (Karmuka)', 'चाप', consecutive(10, 7), 'The seven planets in the seven houses from the 10th (10-4).',
        'Brave, wandering and fond of adventure; a protector or guard.');
    final ardha = [2, 3, 5, 6, 8, 9, 11, 12].any((s) => consecutive(s, 7));
    add(YogaFamilies.nabhasaAkriti, 'Ardha Chandra', 'अर्धचन्द्र', ardha, 'The seven planets in seven consecutive houses starting from a house that is not a Kendra.',
        'A handsome leader, commander or chief; wealthy and respected.', nature: YogaNature.benefic);
    add(YogaFamilies.nabhasaAkriti, 'Chakra', 'चक्र', exactly({1, 3, 5, 7, 9, 11}), 'The planets in six alternate houses beginning with the Lagna (1, 3, 5, 7, 9, 11), all six occupied.',
        'An emperor among people: power, authority and respect.', nature: YogaNature.benefic);
    add(YogaFamilies.nabhasaAkriti, 'Samudra', 'समुद्र', exactly({2, 4, 6, 8, 10, 12}), 'The planets in six alternate houses beginning with the 2nd (2, 4, 6, 8, 10, 12), all six occupied.',
        'Wealth like the ocean, comforts and generosity.', nature: YogaNature.benefic);

    // Sankhya (7)
    const sankhya = [
      (7, 'Veena (Vallaki)', 'वीणा', 'Fond of music and the arts, many friends, leadership.'),
      (6, 'Dama', 'दाम', 'Generous, helpful to others, wealthy and famous.'),
      (5, 'Pasha', 'पाश', 'Skilful in earning, with many dependents; can be bound by circumstances.'),
      (4, 'Kedara', 'केदार', 'Agriculture and land; useful to others, wealthy and truthful.'),
      (3, 'Shula', 'शूल', 'Sharp, brave and sometimes cruel; quarrels and wounds.'),
      (2, 'Yuga', 'युग', 'Heterodox views, limited wealth and an unconventional life.'),
      (1, 'Gola', 'गोल', 'Poverty, little learning and hardship in classical texts.'),
    ];
    final other = out.any((y) => y.formed);
    for (final (n, name, hindi, desc) in sankhya) {
      final formed = signs.length == n;
      out.add(YogaResult(
        category: YogaFamilies.nabhasaSankhya,
        name: '$name Yoga',
        hindi: '$hindi योग',
        formed: formed,
        strength: !formed ? 'Not formed' : (other ? 'Secondary' : 'Formed'),
        description: desc,
        planets: formed ? ps : const [],
        rule: tr('The seven planets occupy exactly $n sign${n == 1 ? '' : 's'}. Sankhya yogas apply when no other Nabhasa yoga is present.',
            'सातों ग्रह ठीक $n राशि${n == 1 ? '' : 'यों'} में हों। संख्या योग तभी लागू होते हैं जब कोई अन्य नाभस योग न हो।'),
        source: src,
        reasons: [reason, if (formed && other) tr('Another Nabhasa yoga is present, which takes precedence.', 'एक अन्य नाभस योग मौजूद है, जिसे प्राथमिकता मिलती है।')],
        nature: n >= 5 ? YogaNature.benefic : (n <= 2 ? YogaNature.adverse : YogaNature.mixed),
      ));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Pravrajya
  // ---------------------------------------------------------------------------

  static List<YogaResult> _pravrajya(_Chart c) {
    const ascetic = {
      'sun': 'Vanaprastha (forest-dweller, ascetic of the Sun)',
      'moon': 'Kapalika (Vriddha-shravaka)',
      'mars': 'Shakya (Raktapata, red-robed monk)',
      'mercury': 'Ajivika (Ekadandi)',
      'jupiter': 'Bhikshu (Yati, mendicant)',
      'venus': 'Charaka (wandering ascetic)',
      'saturn': 'Nirgrantha (Digambara)',
    };
    final out = <YogaResult>[];
    final groups = <int, List<String>>{};
    for (final p in c.present(seven)) {
      groups.putIfAbsent(c.rashi(p), () => []).add(p);
    }
    final big = groups.entries.where((e) => e.value.length >= 4).toList();
    if (big.isEmpty) {
      out.add(YogaResult(
        category: YogaFamilies.pravrajya,
        name: 'Pravrajya Yoga',
        hindi: 'प्रव्रज्या योग',
        formed: false,
        strength: 'Not formed',
        description: 'Renunciation or withdrawal from ordinary material life.',
        rule: tr('Four or more of the seven planets together in one sign; the strongest of them shows the type of renunciation.',
            'सात में से चार या अधिक ग्रह एक ही राशि में हों; उनमें सबसे बलवान ग्रह संन्यास का प्रकार बताता है।'),
        source: 'Brihat Jataka ch. 15; BPHS',
        reasons: [tr('No sign holds four or more planets.', 'किसी राशि में चार या अधिक ग्रह नहीं हैं।')],
        nature: YogaNature.mixed,
      ));
    }
    for (final e in big) {
      final members = e.value;
      final ranked = [...members]..sort((a, b) => c.score(b).compareTo(c.score(a)));
      final strongest = ranked.first;
      final combust = c.isCombust(strongest);
      out.add(YogaResult(
        category: YogaFamilies.pravrajya,
        name: 'Pravrajya Yoga',
        hindi: 'प्रव्रज्या योग',
        formed: true,
        strength: combust ? 'Weak (strongest planet combust)' : 'Formed',
        description: 'A pull towards renunciation, spiritual study, research or solitary work. In modern life this need not mean literal monkhood. '
            'Type indicated: ${ascetic[strongest]}.',
        planets: members,
        rule: tr(
            'Four or more of the seven planets together in one sign; the strongest of them shows the type of renunciation. '
                'If that planet is combust, the native is drawn to it but does not take formal vows.',
            'सात में से चार या अधिक ग्रह एक ही राशि में हों; उनमें सबसे बलवान ग्रह संन्यास का प्रकार बताता है। '
                'यदि वह ग्रह अस्त हो, तो व्यक्ति उस ओर आकर्षित होता है पर औपचारिक दीक्षा नहीं लेता।'),
        source: 'Brihat Jataka ch. 15; BPHS',
        reasons: [
          tr('${c.names(members)} are together in ${VedicMath.rashis[e.key].name}; the strongest is ${c.name(strongest)}.',
              '${c.names(members)} ${L10n.sign(e.key)} में साथ हैं; सबसे बलवान ${c.name(strongest)} है।')
        ],
        modifiers: c.modifiers(members),
        nature: YogaNature.mixed,
      ));
    }

    // Janma-rashi lord aspected only by Saturn.
    if (c.has('moon')) {
      final moonLord = VedicMath.rashis[c.rashi('moon')].lord;
      if (c.has(moonLord)) {
        final aspecting = c.present(seven).where((p) => p != moonLord && c.aspects(p, c.rashi(moonLord))).toList();
        final formed = aspecting.length == 1 && aspecting.first == 'saturn' && moonLord != 'saturn';
        out.add(YogaResult(
          category: YogaFamilies.pravrajya,
          name: 'Pravrajya Yoga (Moon-sign lord aspected by Saturn)',
          hindi: 'प्रव्रज्या योग',
          formed: formed,
          strength: formed ? 'Formed' : 'Not formed',
          description: 'Detachment and a serious, renunciate turn of mind under Saturn\'s influence.',
          planets: [moonLord, 'saturn'],
          rule: tr('The lord of the Moon\'s sign is aspected by Saturn alone (and by no other planet).', 'चन्द्र राशि के स्वामी पर केवल शनि की दृष्टि हो (किसी अन्य ग्रह की नहीं)।'),
          source: 'Brihat Jataka ch. 15',
          reasons: [
            tr('Moon-sign lord ${c.name(moonLord)} is aspected by ${aspecting.isEmpty ? 'no planet' : c.names(aspecting)}.',
                'चन्द्र राशि के स्वामी ${c.name(moonLord)} पर ${aspecting.isEmpty ? 'किसी ग्रह की दृष्टि नहीं है' : '${c.names(aspecting)} की दृष्टि है'}।')
          ],
          nature: YogaNature.mixed,
        ));
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Arishta and Arishta-bhanga
  // ---------------------------------------------------------------------------

  static List<YogaResult> _arishta(_Chart c) {
    if (!c.has('moon')) return const [];
    final out = <YogaResult>[];
    final moonR = c.rashi('moon');
    final protections = <String>[
      if (c.has('jupiter') && isKendra(c.house('jupiter')))
        tr('Jupiter is in a Kendra from the Lagna (classically the strongest protection).', 'गुरु लग्न से केन्द्र में है (शास्त्रों में सबसे प्रबल रक्षा)।'),
      if (c.isStrong(lord(c.lagna, 1)) && isKendra(c.house(lord(c.lagna, 1)))) tr('The Lagna lord is strong and in a Kendra.', 'लग्नेश बलवान है और केन्द्र में है।'),
      if (c.moonPhase >= 150 && c.moonPhase <= 210) tr('The Moon is (nearly) full.', 'चन्द्र (लगभग) पूर्ण है।'),
      if (c.present(['jupiter', 'venus', 'mercury']).any((p) => c.aspects(p, moonR) || c.rashi(p) == moonR))
        tr('The Moon is joined or aspected by a benefic.', 'चन्द्र के साथ शुभ ग्रह है या उस पर शुभ दृष्टि है।'),
    ];
    final moonHouse = c.house('moon');
    final afflicters = c.present(['mars', 'saturn', 'rahu', 'ketu', 'sun']).where((p) => c.rashi(p) == moonR || (p != 'sun' && c.aspects(p, moonR))).toList();
    final benAspect = c.present(['jupiter', 'venus', 'mercury']).any((p) => c.aspects(p, moonR) || c.rashi(p) == moonR);
    final formed = isDusthana(moonHouse) && afflicters.isNotEmpty && !benAspect;
    out.add(YogaResult(
      category: YogaFamilies.arishta,
      name: 'Chandra Arishta',
      hindi: 'चन्द्र अरिष्ट',
      formed: formed,
      strength: !formed ? 'Not formed' : (protections.isEmpty ? 'Challenging' : 'Mitigated'),
      description: 'A classical indicator of an afflicted Moon (vitality and mind in childhood). It is not a medical prediction; read it with the whole chart.',
      planets: ['moon', ...afflicters],
      rule: tr('The Moon in the 6th, 8th or 12th from the Lagna, joined or aspected by malefics and not joined or aspected by any benefic.',
          'चन्द्र लग्न से 6, 8 या 12वें भाव में हो, पाप ग्रहों की युति या दृष्टि हो और किसी शुभ ग्रह की युति या दृष्टि न हो।'),
      source: 'BPHS (Arishta); Saravali',
      reasons: [
        tr('The Moon is in house $moonHouse${afflicters.isEmpty ? '' : ', afflicted by ${c.names(afflicters)}'}${benAspect ? ', with benefic support' : ''}.',
            'चन्द्र $moonHouseवें भाव में है${afflicters.isEmpty ? '' : ', ${c.names(afflicters)} से पीड़ित'}${benAspect ? ', शुभ ग्रह के सहारे के साथ' : ''}।')
      ],
      modifiers: formed ? protections.map((p) => '${tr('Arishta-bhanga', 'अरिष्ट भंग')}: $p').toList() : const [],
      nature: YogaNature.adverse,
    ));

    final l1 = lord(c.lagna, 1);
    final lagnaMalefics = c.present(['sun', 'mars', 'saturn', 'rahu', 'ketu']).where((p) => c.house(p) == 1).toList();
    final weakLord = c.has(l1) && isDusthana(c.house(l1)) && (c.isCombust(l1) || isDebilitated(l1, c.rashi(l1)));
    final lagnaFormed = weakLord && lagnaMalefics.isNotEmpty;
    out.add(YogaResult(
      category: YogaFamilies.arishta,
      name: 'Lagna Arishta',
      hindi: 'लग्न अरिष्ट',
      formed: lagnaFormed,
      strength: !lagnaFormed ? 'Not formed' : (protections.isEmpty ? 'Challenging' : 'Mitigated'),
      description: 'A weak Lagna lord with malefics in the Lagna: a classical sign of low vitality that calls for care. Not a medical prediction.',
      planets: [l1, ...lagnaMalefics],
      rule: tr('The Lagna lord in a dusthana while combust or debilitated, and malefics in the Lagna.', 'लग्नेश दुःस्थान में अस्त या नीच होकर हो, और लग्न में पाप ग्रह हों।'),
      source: 'BPHS (Arishta)',
      reasons: [
        tr('Lagna lord ${c.name(l1)}: house ${c.has(l1) ? c.house(l1) : '-'}, ${c.dignity(l1)}${c.isCombust(l1) ? ', combust' : ''}. Malefics in Lagna: ${lagnaMalefics.isEmpty ? 'none' : c.names(lagnaMalefics)}.',
            'लग्नेश ${c.name(l1)}: भाव ${c.has(l1) ? c.house(l1) : '-'}, ${c.dig(l1)}${c.isCombust(l1) ? ', अस्त' : ''}। लग्न में पाप ग्रह: ${lagnaMalefics.isEmpty ? 'कोई नहीं' : c.names(lagnaMalefics)}।')
      ],
      modifiers: lagnaFormed ? protections.map((p) => '${tr('Arishta-bhanga', 'अरिष्ट भंग')}: $p').toList() : const [],
      nature: YogaNature.adverse,
    ));

    out.add(YogaResult(
      category: YogaFamilies.arishta,
      name: 'Arishta-bhanga',
      hindi: 'अरिष्ट भंग',
      formed: protections.isNotEmpty,
      strength: protections.length >= 2 ? 'Strong' : (protections.isEmpty ? 'Not formed' : 'Moderate'),
      description: 'Protective factors that cancel or soften afflictions in the chart.',
      planets: [if (c.has('jupiter') && isKendra(c.house('jupiter'))) 'jupiter', 'moon', l1],
      rule: tr('Jupiter in a Kendra, a strong Lagna lord in a Kendra, a full Moon, or the Moon joined or aspected by benefics.',
          'केन्द्र में गुरु, केन्द्र में बलवान लग्नेश, पूर्ण चन्द्र, या चन्द्र पर शुभ ग्रहों की युति या दृष्टि।'),
      source: 'BPHS (Arishta-bhanga)',
      reasons: protections.isEmpty ? [tr('None of the protective conditions is present.', 'कोई भी रक्षक स्थिति मौजूद नहीं है।')] : protections,
    ));
    return out;
  }
}

/// Chart helpers shared by the yoga rules.
class _Chart {
  final Map<String, double> longs;
  final int lagna;
  final Map<String, double> speeds;
  final double? ascendant;
  late final Map<String, int> rashis = {for (final e in longs.entries) e.key: VedicMath.rashiIndex(e.value)};

  _Chart(this.longs, this.lagna, this.speeds, this.ascendant);

  List<String> get all => Ephemeris.planetOrder;
  bool has(String p) => longs.containsKey(p);
  List<String> present(List<String> ps) => ps.where(has).toList();
  int rashi(String p) => rashis[p]!;
  int house(String p) => VedicMath.houseOf(rashi(p), lagna);
  int houseFrom(String p, int refRashi) => VedicMath.houseOf(rashi(p), refRashi);
  int navamsa(String p) => VedicMath.vargaRashi(longs[p]!, 'D9', 9);
  /// Planet name in the app language.
  String name(String p) => VedicMath.planets[p] != null ? L10n.planet(p) : VedicMath.capitalize(p);

  /// English planet name (yoga names and classical descriptions).
  String en(String p) => VedicMath.planets[p]?.name ?? VedicMath.capitalize(p);
  String names(List<String> ps) => ps.map(name).join(', ');
  String signName(String p) => L10n.sign(rashi(p));
  String signEn(String p) => VedicMath.rashis[rashi(p)].name;

  /// Dignity in the app language.
  String dig(String p) => L10n.dignity(dignity(p));

  /// "house 5" / "5वाँ भाव".
  String hs(Object h) => tr('house $h', '$hवाँ भाव');

  /// "in house 5" / "5वें भाव में".
  String inH(Object h) => tr('in house $h', '$hवें भाव में');

  /// "9th lord" / "9वें भाव का स्वामी".
  String lordOf(int h) => h == 1 ? tr('Lagna lord', 'लग्नेश') : tr('${VedicMath.ordinal(h)} lord', '$hवें भाव का स्वामी');

  /// 'Lagna' / 'Moon' reference in the app language.
  static String ref(String label) => label == 'Lagna' ? tr('Lagna', 'लग्न') : tr('Moon', 'चन्द्र');

  /// Relation text from [relation] in the app language.
  static String relText(String rel) => tr(
      rel,
      switch (rel) {
        'conjunct' => 'युति में हैं',
        'exchange signs' => 'राशि परिवर्तन में हैं',
        'in mutual aspect' => 'परस्पर दृष्टि में हैं',
        'the same planet' => 'एक ही ग्रह हैं',
        _ => rel,
      });
  String dignity(String p) => has(p) ? PlanetaryDignity.getAdvancedDignity(p, rashi(p), rashis, degree: VedicMath.degInRashi(longs[p]!)) : 'Unknown';

  /// Moon's elongation from the Sun (0 = new, 180 = full).
  double get moonPhase => has('moon') && has('sun') ? VedicMath.norm360(longs['moon']! - longs['sun']!) : 180;

  /// Natural benefic, with the waxing/waning Moon and Mercury's association.
  bool isBenefic(String p) {
    switch (p) {
      case 'jupiter':
      case 'venus':
        return true;
      case 'moon':
        return moonPhase < 180;
      case 'mercury':
        return !present(['sun', 'mars', 'saturn', 'rahu', 'ketu']).any((m) => rashi(m) == rashi('mercury'));
      default:
        return false;
    }
  }

  /// Day birth when the Sun is above the horizon (between the descendant and the ascendant through the MC).
  bool? get isDayBirth {
    final asc = ascendant;
    if (asc == null || !has('sun')) return null;
    return VedicMath.norm360(asc - longs['sun']!) < 180;
  }

  double separation(String a, String b) {
    final d = (longs[a]! - longs[b]!).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  bool isRetro(String p) => p != 'rahu' && p != 'ketu' && (speeds[p] ?? 0) < 0;

  bool isCombust(String p) {
    if (p == 'sun' || p == 'rahu' || p == 'ketu' || !has(p) || !has('sun')) return false;
    final orb = switch (p) {
      'moon' => 12.0,
      'mars' => 17.0,
      'mercury' => isRetro(p) ? 12.0 : 14.0,
      'jupiter' => 11.0,
      'venus' => isRetro(p) ? 8.0 : 10.0,
      'saturn' => 15.0,
      _ => 0.0,
    };
    return separation(p, 'sun') < orb;
  }

  /// Graha drishti by sign: every planet aspects the 7th; Mars also the 4th
  /// and 8th, Jupiter the 5th and 9th, Saturn the 3rd and 10th.
  bool aspects(String p, int targetRashi) {
    if (!has(p)) return false;
    final n = VedicMath.houseOf(targetRashi, rashi(p));
    if (n == 7) return true;
    return switch (p) {
      'mars' => n == 4 || n == 8,
      'jupiter' => n == 5 || n == 9,
      'saturn' => n == 3 || n == 10,
      'rahu' || 'ketu' => n == 5 || n == 9,
      _ => false,
    };
  }

  bool exchange(String a, String b) {
    if (a == b || !has(a) || !has(b)) return false;
    return VedicMath.rashis[rashi(a)].lord == b && VedicMath.rashis[rashi(b)].lord == a;
  }

  /// Sambandha between two planets, or null.
  String? relation(String a, String b) {
    if (!has(a) || !has(b) || a == b) return null;
    if (rashi(a) == rashi(b)) return 'conjunct';
    if (exchange(a, b)) return 'exchange signs';
    if (aspects(a, rashi(b)) && aspects(b, rashi(a))) return 'in mutual aspect';
    return null;
  }

  bool isStrong(String p) {
    if (!has(p)) return false;
    final r = rashi(p);
    if (YogasMath.isExalted(p, r) || YogasMath.isOwn(p, r) || PlanetaryDignity.moolatrikonaSigns[p] == r) return true;
    final h = house(p);
    return (YogasMath.isKendra(h) || YogasMath.isTrikona(h)) &&
        !YogasMath.isDebilitated(p, r) &&
        !isCombust(p) &&
        !dignity(p).contains('Enemy');
  }

  /// Numeric strength of one planet (dignity, combustion, house, Navamsa).
  double score(String p) {
    if (!has(p)) return 0;
    final r = rashi(p);
    double s = 0;
    final d = dignity(p);
    if (d == 'Exalted') {
      s += 2;
    } else if (d == 'Moolatrikona' || d == 'Own Sign') {
      s += 1.5;
    } else if (d.contains('Friend')) {
      s += 0.5;
    } else if (d.contains('Enemy')) {
      s -= 0.5;
    } else if (d == 'Debilitated') {
      s -= 2;
    }
    if (isCombust(p)) s -= 1.5;
    final h = house(p);
    if (YogasMath.isKendra(h) || YogasMath.isTrikona(h)) s += 0.5;
    if (YogasMath.isDusthana(h)) s -= 0.5;
    if (p != 'rahu' && p != 'ketu') {
      final n = navamsa(p);
      if (n == r) s += 1; // vargottama
      if (YogasMath.isExalted(p, n) || YogasMath.isOwn(p, n)) s += 0.5;
      if (YogasMath.isDebilitated(p, n)) s -= 0.5;
    }
    return s;
  }

  String strengthOf(List<String> ps, {double bonus = 0}) {
    final list = present(ps);
    if (list.isEmpty) return 'Moderate';
    final avg = list.map(score).reduce((a, b) => a + b) / list.length + bonus;
    if (avg >= 1.5) return 'Strong';
    if (avg >= 0) return 'Moderate';
    return 'Weak';
  }

  /// Human-readable strength factors for [ps].
  List<String> modifiers(List<String> ps) {
    final out = <String>[];
    for (final p in present(ps).toSet()) {
      final d = dignity(p);
      final n = name(p);
      if (d == 'Exalted' || d == 'Moolatrikona' || d == 'Own Sign') {
        out.add(tr('$n is ${d == 'Own Sign' ? 'in its own sign' : d.toLowerCase()} (+).', '$n ${L10n.dignity(d)} में है (+)।'));
      }
      if (d == 'Debilitated') out.add(tr('$n is debilitated (−).', '$n नीच का है (−)।'));
      if (d.contains('Enemy')) out.add(tr('$n is in an enemy\'s sign (−).', '$n शत्रु राशि में है (−)।'));
      if (isCombust(p)) {
        final sep = separation(p, 'sun').toStringAsFixed(1);
        out.add(tr('$n is combust, $sep° from the Sun (−).', '$n अस्त है, सूर्य से $sep° दूर (−)।'));
      }
      if (isRetro(p)) out.add(tr('$n is retrograde (modifies expression and timing).', '$n वक्री है (फल देने का ढंग और समय बदलता है)।'));
      if (YogasMath.isDusthana(house(p))) out.add(tr('$n sits in a dusthana, house ${house(p)} (−).', '$n दुःस्थान (${house(p)}वें भाव) में है (−)।'));
      if (ascendant != null && PrecisionMath.inSandhi(longs[p]!, ascendant!, 1)) {
        out.add(tr('$n is at a Bhāva-sandhi, which reduces its effectiveness (−).', '$n भाव-संधि पर है, जिससे उसका प्रभाव घटता है (−)।'));
      }
      if (p != 'rahu' && p != 'ketu') {
        final nv = navamsa(p);
        if (nv == rashi(p)) out.add(tr('$n is vargottama (same sign in D1 and D9) (+).', '$n वर्गोत्तम है (D1 और D9 में एक ही राशि) (+)।'));
        if (YogasMath.isDebilitated(p, nv)) out.add(tr('$n is debilitated in the Navamsa (−).', '$n नवांश में नीच का है (−)।'));
        if (YogasMath.isExalted(p, nv)) out.add(tr('$n is exalted in the Navamsa (+).', '$n नवांश में उच्च का है (+)।'));
      }
    }
    return out;
  }
}
