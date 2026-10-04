import 'calc_config.dart';
import 'ephemeris.dart';
import 'l10n.dart';
import 'plain/meanings.dart';
import 'precision_math.dart';
import 'vedic_math.dart';
import 'yogas_math.dart';

/// One record of the Conjunction Database (Volumes 2 and 3): a cluster of
/// 2-7 classical planets in a given Bhava and Rashi.
///
/// The 17,280 records (120 clusters x 12 Bhavas x 12 Rashis) are generated
/// from the dictionaries below exactly as the database volumes define them,
/// so they are computed on demand instead of being stored.
class ConjunctionRecord {
  final String recordId;
  final String clusterId;
  final List<String> planets;
  final int bhava;
  final int rashi;
  final int derivedLagna;

  const ConjunctionRecord(this.recordId, this.clusterId, this.planets, this.bhava, this.rashi, this.derivedLagna);

  int get size => planets.length;
  String get dispositor => VedicMath.rashis[rashi].lord;
  String get element => ConjunctionDb.element(rashi);
  String get modality => ConjunctionDb.modality(rashi);
  List<(String, String)> get pairs => ConjunctionDb.pairsOf(planets);
  String get sourceTier => ConjunctionDb.sourceTier(size);
  String get directSource => ConjunctionDb.directSource(size);
  String get clusterLabel => planets.map(ConjunctionDb.planetName).join(' + ');

  /// Houses owned by each planet for the derived (whole-sign) Lagna.
  Map<String, List<int>> get functionalLordship => {for (final p in planets) p: ConjunctionDb.housesOwned(p, derivedLagna)};

  String get functionalLordshipText => planets
      .map((p) => '${ConjunctionDb.planetName(p)}: ${functionalLordship[p]!.join(',')} '
          '(${functionalLordship[p]!.map((h) => L10n.hi ? ConjunctionDb.houseClassHi[h] : ConjunctionDb.houseClass[h]).join('; ')})')
      .join(' | ');

  String get pairwiseText => pairs.map((p) => '${ConjunctionDb.planetName(p.$1)}-${ConjunctionDb.planetName(p.$2)}').join('; ');

  String get coreThemes => planets.map((p) => (L10n.hi ? ConjunctionDb.planetThemesHi : ConjunctionDb.planetThemes)[p]!).join('; ');

  String get bhavaInteraction => tr('The cluster concentrates its combined planetary significations into the ${ConjunctionDb.bhavaNames[bhava - 1]} domain.',
      'यह युति अपने ग्रहों के संयुक्त फलों को ${ConjunctionDb.bhavaNamesHi[bhava - 1]} भाव के क्षेत्र में केंद्रित करती है।');

  String get rashiInteraction => tr(
      'The ${VedicMath.rashis[rashi].name} environment modifies expression through '
          '${element.toLowerCase()} element, ${modality.toLowerCase()} modality, and ${ConjunctionDb.planetName(dispositor)} as dispositor.',
      '${L10n.sign(rashi)} राशि का वातावरण ${L10n.element(element)} तत्व, ${ConjunctionDb.modalityLabel(rashi)} स्वभाव और राशि स्वामी ${L10n.planet(dispositor)} के माध्यम से फल को बदलता है।');

  static String get interpretiveRule => tr(
      'Do not read this record in isolation. First check any exact classical multi-planet rule for the cluster; then integrate '
          'the pairwise rules; then apply Lagna lordship, dignity, dispositor, aspects, strength, Vargas and timing.',
      'इस रिकॉर्ड को अलग से न पढ़ें। पहले इस युति का कोई सटीक शास्त्रीय नियम देखें; फिर जोड़ों के नियम मिलाएँ; फिर लग्न स्वामित्व, गरिमा, राशि स्वामी, दृष्टि, बल, वर्ग और समय लागू करें।');

  /// Volume 2 pair texts for this placement (pair x Bhava, pair x Rashi, pair x Lagna).
  List<({String id, String pair, String bhava, String rashi, String lagna})> pairTexts() => [
        for (final (a, b) in pairs)
          (
            id: ConjunctionDb.pairId(a, b),
            pair: '${ConjunctionDb.planetName(a)}–${ConjunctionDb.planetName(b)}',
            bhava: ConjunctionDb.pairBhavaText(a, b, bhava),
            rashi: ConjunctionDb.pairRashiText(a, b, rashi),
            lagna: ConjunctionDb.pairLagnaText(a, b, derivedLagna),
          ),
      ];

  Map<String, Object?> toJson() => {
        'record_id': recordId,
        'cluster_id': clusterId,
        'cluster_size': size,
        'planets': planets.map(ConjunctionDb.planetName).toList(),
        'bhava': bhava,
        'rashi': VedicMath.rashis[rashi].name,
        'dispositor': ConjunctionDb.planetName(dispositor),
        'derived_lagna': VedicMath.rashis[derivedLagna].name,
        'element': element,
        'modality': modality,
        'pairwise': pairs.map((p) => '${ConjunctionDb.planetName(p.$1)}-${ConjunctionDb.planetName(p.$2)}').toList(),
        'functional_lordship': {for (final e in functionalLordship.entries) ConjunctionDb.planetName(e.key): e.value},
        'source_tier': sourceTier,
        'synthesis': {
          'bhava_theme': ConjunctionDb.bhavaDomains[bhava - 1],
          'sign_modifier': '$element/$modality/${ConjunctionDb.planetName(dispositor)} dispositor',
        },
      };
}

class ConjunctionDb {
  /// Canonical planet order (Volume 3 §4).
  static const List<String> classical = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];

  static const Map<String, String> planetThemes = {
    'sun': 'identity, authority, vitality, status',
    'moon': 'mind, emotion, nourishment, adaptability',
    'mars': 'action, courage, initiative, conflict',
    'mercury': 'intellect, speech, analysis, commerce',
    'jupiter': 'wisdom, learning, expansion, counsel',
    'venus': 'relationships, pleasure, art, values',
    'saturn': 'discipline, duty, delay, structure, endurance',
  };

  /// Base interaction of the 21 canonical pairs (Volume 2 §2), keyed "a-b" in canonical order.
  static const Map<String, String> pairThemes = {
    'sun-moon': 'will/identity + mind/feeling',
    'sun-mars': 'authority + action/courage',
    'sun-mercury': 'authority + intellect/communication',
    'sun-jupiter': 'authority + wisdom/learning',
    'sun-venus': 'authority + aesthetics/relationships',
    'sun-saturn': 'authority + duty/structure',
    'moon-mars': 'emotion + action/enterprise',
    'moon-mercury': 'mind + intellect/communication',
    'moon-jupiter': 'mind + wisdom/nurturing',
    'moon-venus': 'mind + pleasure/aesthetics',
    'moon-saturn': 'mind + restraint/duty',
    'mars-mercury': 'action + intellect/strategy',
    'mars-jupiter': 'action + wisdom/leadership',
    'mars-venus': 'action + desire/creativity',
    'mars-saturn': 'force + restraint/endurance',
    'mercury-jupiter': 'intellect + wisdom/synthesis',
    'mercury-venus': 'intellect + aesthetics/commerce',
    'mercury-saturn': 'intellect + structure/systems',
    'jupiter-venus': 'wisdom + pleasure/values',
    'jupiter-saturn': 'expansion + structure',
    'venus-saturn': 'pleasure + discipline/craft',
  };

  static const Map<String, String> planetThemesHi = {
    'sun': 'पहचान, अधिकार, जीवनशक्ति, पद',
    'moon': 'मन, भावना, पोषण, अनुकूलन',
    'mars': 'कर्म, साहस, पहल, संघर्ष',
    'mercury': 'बुद्धि, वाणी, विश्लेषण, व्यापार',
    'jupiter': 'ज्ञान, विद्या, विस्तार, परामर्श',
    'venus': 'संबंध, सुख, कला, मूल्य',
    'saturn': 'अनुशासन, कर्तव्य, विलंब, संरचना, सहनशीलता',
  };

  static const Map<String, String> pairThemesHi = {
    'sun-moon': 'इच्छाशक्ति/पहचान + मन/भावना',
    'sun-mars': 'अधिकार + कर्म/साहस',
    'sun-mercury': 'अधिकार + बुद्धि/संवाद',
    'sun-jupiter': 'अधिकार + ज्ञान/विद्या',
    'sun-venus': 'अधिकार + सौंदर्य/संबंध',
    'sun-saturn': 'अधिकार + कर्तव्य/संरचना',
    'moon-mars': 'भावना + कर्म/उद्यम',
    'moon-mercury': 'मन + बुद्धि/संवाद',
    'moon-jupiter': 'मन + ज्ञान/पोषण',
    'moon-venus': 'मन + सुख/सौंदर्य',
    'moon-saturn': 'मन + संयम/कर्तव्य',
    'mars-mercury': 'कर्म + बुद्धि/रणनीति',
    'mars-jupiter': 'कर्म + ज्ञान/नेतृत्व',
    'mars-venus': 'कर्म + इच्छा/रचनात्मकता',
    'mars-saturn': 'शक्ति + संयम/सहनशीलता',
    'mercury-jupiter': 'बुद्धि + ज्ञान/संश्लेषण',
    'mercury-venus': 'बुद्धि + सौंदर्य/व्यापार',
    'mercury-saturn': 'बुद्धि + संरचना/प्रणाली',
    'jupiter-venus': 'ज्ञान + सुख/मूल्य',
    'jupiter-saturn': 'विस्तार + संरचना',
    'venus-saturn': 'सुख + अनुशासन/कारीगरी',
  };

  static const List<String> bhavaNamesHi = ['तनु', 'धन', 'सहज', 'सुख', 'पुत्र', 'अरि', 'युवती', 'रंध्र', 'धर्म', 'कर्म', 'लाभ', 'व्यय'];

  static const List<String> bhavaDomainsHi = [
    'पहचान, शरीर, स्वभाव, आत्म-दिशा',
    'वाणी, परिवार, संचित धन, भोजन और मूल्य',
    'साहस, कौशल, संवाद, पहल और छोटे भाई-बहन',
    'घर, माता, संपत्ति, वाहन, शिक्षा और आंतरिक सुरक्षा',
    'बुद्धि, रचनात्मकता, संतान, विद्या और सट्टा/निवेश',
    'सेवा, प्रतियोगिता, कर्ज़, शत्रु, दिनचर्या और स्वास्थ्य',
    'विवाह, साझेदारी, अनुबंध, ग्राहक और लोक व्यवहार',
    'परिवर्तन, आयु, विरासत, संयुक्त धन और शोध',
    'भाग्य, पिता/गुरु, उच्च शिक्षा, नैतिकता और तीर्थ',
    'व्यवसाय, अधिकार, प्रतिष्ठा और दिखने वाले कर्म',
    'लाभ, संपर्क, आय के स्रोत, बड़े भाई-बहन और महत्वाकांक्षाएँ',
    'खर्च, विदेश, एकांत, नींद, मुक्ति और निजता',
  ];

  static const Map<int, String> houseClassHi = {
    1: 'केन्द्र/त्रिकोण/लग्न', 2: 'मारक', 3: 'उपचय', 4: 'केन्द्र', 5: 'त्रिकोण', 6: 'उपचय/दुःस्थान',
    7: 'केन्द्र/मारक', 8: 'दुःस्थान', 9: 'त्रिकोण', 10: 'केन्द्र/उपचय', 11: 'उपचय', 12: 'दुःस्थान',
  };

  /// House domain in the app language (Volume 3 wording in English).
  static String bhavaDomain(int bhava) => L10n.hi ? bhavaDomainsHi[bhava - 1] : bhavaDomains[bhava - 1];
  static String bhavaName(int bhava) => L10n.hi ? bhavaNamesHi[bhava - 1] : bhavaNames[bhava - 1];
  static String modalityLabel(int rashi) => L10n.hi ? const ['चर', 'स्थिर', 'द्विस्वभाव'][rashi % 3] : modality(rashi);

  static const List<String> bhavaNames = [
    'Tanu', 'Dhana', 'Sahaja', 'Sukha', 'Putra', 'Ari', 'Yuvati', 'Randhra', 'Dharma', 'Karma', 'Labha', 'Vyaya',
  ];

  /// Bhava domains (Volume 3 §7).
  static const List<String> bhavaDomains = [
    'identity, body, temperament, self-direction',
    'speech, family, resources, food, values',
    'courage, skills, communication, initiative, younger siblings',
    'home, mother, property, vehicles, education, inner security',
    'intelligence, creativity, children, learning, speculation',
    'service, competition, debts, enemies, routines, health',
    'marriage, partnerships, contracts, clients, public interaction',
    'transformation, longevity, inheritance, joint resources, research',
    'fortune, father, guru, higher learning, ethics, pilgrimage',
    'profession, authority, reputation, visible action',
    'gains, networks, income, elder siblings, ambitions',
    'expenditure, foreign places, retreat, sleep, release, privacy',
  ];

  /// Bhava domains as worded in Volume 2 §4.
  static const List<String> bhavaDomainsV2 = [
    'identity, body, temperament, self-direction',
    'speech, family, accumulated resources, food and values',
    'courage, skills, communication, initiative and younger siblings',
    'home, mother, property, vehicles, education and inner security',
    'intelligence, creativity, children, learning and speculation',
    'service, competition, debts, enemies, routines and health',
    'marriage, partnerships, contracts, clients and public interaction',
    'transformation, longevity, inheritance, joint resources and research',
    'fortune, father/guru, higher learning, ethics and pilgrimage',
    'profession, authority, reputation and visible action',
    'gains, networks, income channels, elder siblings and ambitions',
    'expenditure, foreign places, retreat, sleep, release and privacy',
  ];

  static const Map<int, String> houseClass = {
    1: 'Kendra/Trikona/Lagna', 2: 'Maraka', 3: 'Upachaya', 4: 'Kendra', 5: 'Trikona', 6: 'Upachaya/Dusthana',
    7: 'Kendra/Maraka', 8: 'Dusthana', 9: 'Trikona', 10: 'Kendra/Upachaya', 11: 'Upachaya', 12: 'Dusthana',
  };

  static const List<String> _rashiAbbr = ['ARI', 'TAU', 'GEM', 'CAN', 'LEO', 'VIR', 'LIB', 'SCO', 'SAG', 'CAP', 'AQU', 'PIS'];
  static const Map<int, String> _prefix = {2: 'P', 3: 'T', 4: 'Q', 5: 'F', 6: 'S', 7: 'H'};

  static String planetName(String p) => VedicMath.planets[p] == null ? VedicMath.capitalize(p) : L10n.planet(p);
  static String element(int rashi) => VedicMath.rashis[rashi].element;
  static String modality(int rashi) => const ['Movable', 'Fixed', 'Dual'][rashi % 3];

  static List<String> canonical(Iterable<String> ps) => classical.where(ps.contains).toList();

  static List<(String, String)> pairsOf(List<String> ps) {
    final c = canonical(ps);
    return [
      for (int i = 0; i < c.length; i++)
        for (int j = i + 1; j < c.length; j++) (c[i], c[j]),
    ];
  }

  static String pairTheme(String a, String b) {
    final c = canonical([a, b]);
    return (L10n.hi ? pairThemesHi : pairThemes)['${c[0]}-${c[1]}']!;
  }

  static String pairId(String a, String b) => clusterIdOf([a, b]);

  static List<int> housesOwned(String p, int lagna) => [
        for (int h = 1; h <= 12; h++)
          if (VedicMath.rashis[(lagna + h - 1) % 12].lord == p) h,
      ];

  /// Volume 2 §5: pair x Bhava interpretation.
  static String pairBhavaText(String a, String b, int bhava) => tr(
      '${pairTheme(a, b)} expressed through ${bhavaDomainsV2[bhava - 1]}. Judge the house lord, Karaka, sign and dispositor before final synthesis.',
      '${pairTheme(a, b)}, ${bhavaDomainsHi[bhava - 1]} के माध्यम से व्यक्त। अंतिम निष्कर्ष से पहले भाव स्वामी, कारक, राशि और राशि स्वामी देखें।');

  /// Volume 2 §7: pair x Rashi interpretation.
  static String pairRashiText(String a, String b, int rashi) => tr(
      '${pairTheme(a, b)} operating through ${element(rashi).toLowerCase()} ${modality(rashi).toLowerCase()} '
          '${VedicMath.rashis[rashi].name} symbolism; ${planetName(VedicMath.rashis[rashi].lord)} is the dispositor.',
      '${pairTheme(a, b)}, ${L10n.element(element(rashi))} तत्व की ${modalityLabel(rashi)} ${L10n.sign(rashi)} राशि के स्वभाव से; राशि स्वामी ${L10n.planet(VedicMath.rashis[rashi].lord)}।');

  /// Volume 2 §9: pair x Lagna functional-lordship question.
  static String pairLagnaText(String a, String b, int lagna) => tr(
      '${lordshipSentence(a, b, lagna)} Combine these house significations with the house occupied by the conjunction.',
      '${lordshipSentence(a, b, lagna)} इन भावों के फलों को युति वाले भाव के साथ मिलाकर पढ़ें।');

  static String lordshipSentence(String a, String b, int lagna) => tr(
      '${planetName(a)} owns ${housesOwned(a, lagna).join(',')}; ${planetName(b)} owns ${housesOwned(b, lagna).join(',')}.',
      '${planetName(a)} भाव ${housesOwned(a, lagna).join(',')} का स्वामी; ${planetName(b)} भाव ${housesOwned(b, lagna).join(',')} का स्वामी।');

  static String sourceTier(int size) => switch (size) {
        2 => 'CLASSICAL-DIRECT + SYSTEMATIC-SYNTHESIS',
        7 => 'CLASSICAL-PAIRWISE + SYSTEMATIC-SYNTHESIS',
        _ => 'CLASSICAL-DIRECT-WHERE-SOURCE-EXACT; OTHERWISE CLASSICAL-PAIRWISE + SYSTEMATIC-SYNTHESIS',
      };

  static String directSource(int size) => switch (size) {
        2 => tr('Phaladeepika 18.1-5; Brihat Jataka 14.1-5', 'फलदीपिका 18.1-5; बृहत् जातक 14.1-5'),
        3 => tr('Saravali ch. 16 (three-planet conjunctions); pairwise per Phaladeepika 18.5', 'सारावली अ. 16 (त्रिग्रह युति); जोड़े फलदीपिका 18.5 के अनुसार'),
        4 => tr('Saravali ch. 17; Jataka Parijata 8.23; pairwise per Phaladeepika 18.5', 'सारावली अ. 17; जातक पारिजात 8.23; जोड़े फलदीपिका 18.5 के अनुसार'),
        5 => tr('Saravali ch. 18; Jataka Parijata 8.26; pairwise per Phaladeepika 18.5', 'सारावली अ. 18; जातक पारिजात 8.26; जोड़े फलदीपिका 18.5 के अनुसार'),
        6 => tr('Saravali ch. 19; pairwise per Phaladeepika 18.5', 'सारावली अ. 19; जोड़े फलदीपिका 18.5 के अनुसार'),
        _ => tr('No classical verse for the seven-planet cluster; synthesis of the 21 pairs (Phaladeepika 18.5)', 'सात ग्रहों की युति के लिए कोई शास्त्रीय श्लोक नहीं; 21 जोड़ों का संश्लेषण (फलदीपिका 18.5)'),
      };

  /// The 120 clusters in catalogue order (P01-P21, T01-T35, Q01-Q35, F01-F21, S01-S07, H01).
  static final List<(String, List<String>)> clusters = () {
    final out = <(String, List<String>)>[];
    for (int size = 2; size <= 7; size++) {
      int n = 0;
      void rec(int start, List<String> acc) {
        if (acc.length == size) {
          n++;
          out.add(('${_prefix[size]}${n.toString().padLeft(2, '0')}', List.unmodifiable(acc)));
          return;
        }
        for (int i = start; i < classical.length; i++) {
          rec(i + 1, [...acc, classical[i]]);
        }
      }

      rec(0, []);
    }
    return List<(String, List<String>)>.unmodifiable(out);
  }();

  static String clusterIdOf(Iterable<String> ps) {
    final c = canonical(ps);
    return clusters.firstWhere((e) => e.$2.length == c.length && e.$2.every(c.contains)).$1;
  }

  static List<String> planetsOf(String clusterId) => clusters.firstWhere((e) => e.$1 == clusterId).$2;

  /// Record for a cluster placed in [bhava] (1-12) and [rashi] (0-11).
  static ConjunctionRecord record(String clusterId, int bhava, int rashi) {
    final planets = planetsOf(clusterId);
    final lagna = (rashi - (bhava - 1) + 12) % 12;
    final id = 'V3-$clusterId-B${bhava.toString().padLeft(2, '0')}-${_rashiAbbr[rashi]}';
    return ConjunctionRecord(id, clusterId, planets, bhava, rashi, lagna);
  }

  static const int totalRecords = 120 * 12 * 12;

  // ---------------------------------------------------------------------------
  // Deep Research additions (Planetary Conjunctions Deep Research, §3, §6, §12, §17, §19)
  // ---------------------------------------------------------------------------

  /// Dominant modifier of each Rashi (Deep Research §6).
  static const List<String> signModifiers = [
    'initiative', 'resources and stability', 'communication and learning', 'care and emotion', 'authority and creativity',
    'analysis and service', 'partnership and negotiation', 'depth and transformation', 'learning and expansion',
    'structure and career', 'systems and groups', 'imagination and synthesis',
  ];

  /// Modern-neutral summaries of the Phaladeepika ch. 18 pair results (Deep Research §3).
  static const Map<String, String> classicalObservations = {
    'sun-moon': 'identity and emotional mind become closely linked.',
    'sun-mars': 'authority, courage and action combine; the classical literature gives an energetic/forceful interpretation.',
    'sun-mercury': 'intellect, communication and administration; this is the basis of the commonly named Budha-Āditya combination, but the conjunction alone does not establish an exceptional result.',
    'sun-jupiter': 'authority, learning, counsel and principles.',
    'sun-venus': 'visibility, aesthetics, relationships and creative/luxury themes.',
    'sun-saturn': 'authority, duty, endurance and institutional structure.',
    'moon-mars': 'enterprise, initiative and emotional heat; associated with the Chandra-Maṅgala framework.',
    'moon-mercury': 'learning, speech, interpretation and adaptability.',
    'moon-jupiter': 'nurturing, learning, counsel and support; Gaja-Kesari is more specifically a Kendra relationship of Jupiter to Moon.',
    'moon-venus': 'aesthetics, relationships, comfort and artistic feeling.',
    'moon-saturn': 'responsibility, seriousness and endurance.',
    'mars-mercury': 'technical reasoning, strategy, debate, engineering/trading-type themes.',
    'mars-jupiter': 'leadership, initiative and strategic action guided by principles.',
    'mars-venus': 'passion, creativity, competition and desire.',
    'mars-saturn': 'force plus restraint; persistence, engineering and pressure tolerance.',
    'mercury-jupiter': 'scholarship, writing, advising, finance/law-type reasoning.',
    'mercury-venus': 'language, literature, design, music, negotiation and commerce.',
    'mercury-saturn': 'systems, calculation, technical work and disciplined communication.',
    'jupiter-venus': 'learning, wealth, arts and relationships; possible tension between principle and pleasure.',
    'jupiter-saturn': 'expansion plus structure; long-term planning and institution-building.',
    'venus-saturn': 'craftsmanship, disciplined creativity, durable resources and serious relationship expectations.',
  };

  static String classicalObservation(String a, String b) {
    if (L10n.hi) return '${Meanings.pair(a, b)}।';
    final c = canonical([a, b]);
    return classicalObservations['${c[0]}-${c[1]}']!;
  }

  static const List<String> signModifiersHi = [
    'पहल', 'संसाधन और स्थिरता', 'संवाद और विद्या', 'देखभाल और भावना', 'अधिकार और रचनात्मकता', 'विश्लेषण और सेवा',
    'साझेदारी और बातचीत', 'गहराई और परिवर्तन', 'विद्या और विस्तार', 'संरचना और करियर', 'प्रणालियाँ और समूह', 'कल्पना और संश्लेषण',
  ];

  static String signModifier(int rashi) => L10n.hi ? signModifiersHi[rashi] : signModifiers[rashi];

  /// Deep Research §7: pair x Rashi with the sign's dominant modifier.
  static String pairSignModifierText(String a, String b, int rashi) => tr(
      '${pairTheme(a, b)}; expressed through ${signModifiers[rashi]}. The condition of ${planetName(VedicMath.rashis[rashi].lord)}, the dispositor, becomes decisive.',
      '${pairTheme(a, b)}; ${signModifiersHi[rashi]} के माध्यम से व्यक्त। राशि स्वामी ${planetName(VedicMath.rashis[rashi].lord)} की स्थिति निर्णायक होती है।');

  /// Vargas (from [vargas]) in which every planet of [planets] shares one sign (Deep Research §17).
  static List<String> vargaRepetition(ChartData chart, List<String> planets, List<String> vargas) {
    final out = <String>[];
    for (final v in vargas) {
      final div = VedicMath.vargaDefs.firstWhere((d) => d.key == v).div;
      final signs = {for (final p in planets) VedicMath.vargaRashi(chart.planetLongitudes[p]!, v, div)};
      if (signs.length == 1) out.add(v);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Chart analysis
  // ---------------------------------------------------------------------------

  /// Every conjunction of classical planets in [chart], with the degree layer.
  static List<ChartConjunction> find(ChartData chart, {CalcConfig cfg = CalcConfig.defaults, double? atJd}) {
    final bySign = <int, List<String>>{};
    for (final p in classical) {
      final l = chart.planetLongitudes[p];
      if (l != null) bySign.putIfAbsent(VedicMath.rashiIndex(l), () => []).add(p);
    }
    final yogas = YogasMath.forChart(chart).where((y) => y.formed).toList();
    final running = _running(chart, atJd);
    final out = <ChartConjunction>[];
    for (final e in bySign.entries) {
      if (e.value.length < 2) continue;
      final members = canonical(e.value);
      final rec = record(clusterIdOf(members), VedicMath.houseOf(e.key, chart.lagnaRashi), e.key);
      final nodes = ['rahu', 'ketu'].where((n) => chart.planetLongitudes[n] != null && VedicMath.rashiIndex(chart.planetLongitudes[n]!) == e.key).toList();
      out.add(ChartConjunction(chart, rec, nodes, cfg, yogas, running));
    }
    out.sort((a, b) => b.record.size.compareTo(a.record.size));
    return out;
  }

  /// Rahu/Ketu associations (Volume 2 §15, Volume 4 §15): node with the planets in its sign.
  static List<NodeAssociation> nodeAssociations(ChartData chart, {CalcConfig cfg = CalcConfig.defaults}) {
    final out = <NodeAssociation>[];
    for (final node in ['rahu', 'ketu']) {
      final l = chart.planetLongitudes[node];
      if (l == null) continue;
      final r = VedicMath.rashiIndex(l);
      final with_ = classical.where((p) => chart.planetLongitudes[p] != null && VedicMath.rashiIndex(chart.planetLongitudes[p]!) == r).toList();
      out.add(NodeAssociation(chart, node, with_, cfg));
    }
    return out;
  }

  static List<String> _running(ChartData chart, double? atJd) {
    final moon = chart.planetLongitudes['moon'];
    if (moon == null) return const [];
    return DashaCalculations.compute(chart.jd, moon, utcOffset: chart.utcOffset).runningAt(atJd ?? Ephemeris.nowJd()).map((d) => d.lord).toList();
  }
}

/// A Daśā period that activates a conjunction (Volume 4 §19, Volume 2 §18).
class DashaActivation {
  final String level; // Mahadasha, Antardasha
  final String lord;
  final String mahaLord;
  final String start;
  final String end;
  final double startJd;
  final String reason;
  const DashaActivation(this.level, this.lord, this.mahaLord, this.start, this.end, this.startJd, this.reason);
}

/// A conjunction found in a chart: database record + degree graph + timing.
class ChartConjunction {
  final ChartData chart;
  final ConjunctionRecord record;
  final List<String> nodes;
  final CalcConfig cfg;
  final List<YogaResult> _formedYogas;

  /// Running [Maha, Antar, Pratyantar] lords.
  final List<String> runningLords;

  ChartConjunction(this.chart, this.record, this.nodes, this.cfg, this._formedYogas, this.runningLords);

  late final List<PairEdge> edges = PrecisionMath.edges(chart, record.planets, cfg);
  late final ClusterMetrics metrics = PrecisionMath.metrics(chart, record.planets, cfg);
  late final Map<String, GrahaRecord> grahas = {for (final p in record.planets) p: PrecisionMath.record(chart, p, cfg)};
  late final GrahaRecord dispositorRecord = PrecisionMath.record(chart, record.dispositor, cfg);

  late final ClusterDiagnostics diagnostics = ClusterDiagnostics.of(this);

  String get signModifier => ConjunctionDb.signModifier(record.rashi);

  /// Phaladeepika ch. 18 pair summaries for every pair in the cluster.
  List<(String, String)> get classicalObservations => [
        for (final (a, b) in record.pairs) ('${ConjunctionDb.planetName(a)}–${ConjunctionDb.planetName(b)}', ConjunctionDb.classicalObservation(a, b)),
      ];

  /// D9 and D10 repetition of the whole cluster, then of each pair (Deep Research §17).
  late final List<String> vargaRepetition = ConjunctionDb.vargaRepetition(chart, record.planets, const ['D9', 'D10']);
  late final List<String> pairRepetitions = [
    for (final (a, b) in record.pairs)
      for (final v in ConjunctionDb.vargaRepetition(chart, [a, b], const ['D9', 'D10'])) '${ConjunctionDb.planetName(a)}–${ConjunctionDb.planetName(b)} ${tr('in', 'में')} $v',
  ];

  /// Common-error cautions that apply to this cluster (Deep Research §12, §19).
  List<String> get cautions {
    final out = <String>[];
    final ps = record.planets;
    if (ps.contains('moon') && ps.contains('jupiter')) {
      out.add(tr('Moon–Jupiter in one sign is not by itself Gaja-Kesari: that yoga is defined by Jupiter in a Kendra from the Moon and needs strength.',
          'एक राशि में चन्द्र-गुरु अपने आप गजकेसरी नहीं है: वह योग चन्द्र से केन्द्र में गुरु से बनता है और उसे बल चाहिए।'));
    }
    if (ps.contains('sun') && ps.contains('mercury')) {
      final e = edges.firstWhere((e) => {e.a, e.b}.containsAll(['sun', 'mercury']));
      out.add(tr('Sun–Mercury (${e.separation.toStringAsFixed(1)}° apart${grahas['mercury']!.combust ? ', Mercury combust' : ''}) is not automatically an exceptional Budha-Āditya result; check degree, combustion, dignity, house and dispositor.',
          'सूर्य-बुध (${e.separation.toStringAsFixed(1)}° दूर${grahas['mercury']!.combust ? ', बुध अस्त' : ''}) अपने आप असाधारण बुध-आदित्य फल नहीं है; अंश, अस्त, गरिमा, भाव और राशि स्वामी देखें।'));
    }
    if (ps.contains('sun') && ps.any((p) => p != 'sun' && p != 'moon' && grahas[p]!.combust)) {
      final c = ps.where((p) => p != 'sun' && p != 'moon' && grahas[p]!.combust).map(ConjunctionDb.planetName).join(', ');
      out.add(tr('Same-sign is not the same as close: $c is combust and judged with that modifier.', 'एक ही राशि होना पास होना नहीं है: $c अस्त है और उसी के अनुसार आंका गया।'));
    }
    if (ps.length >= 3) {
      out.add(tr('${ps.length} planets give ${ps.length * (ps.length - 1) ~/ 2} pair relationships; read the dominant planet, dispositor and closest pair before the full list.',
          '${ps.length} ग्रहों से ${ps.length * (ps.length - 1) ~/ 2} जोड़े बनते हैं; पूरी सूची से पहले प्रमुख ग्रह, राशि स्वामी और सबसे निकट जोड़ा देखें।'));
    }
    return out;
  }

  PairEdge? get closestPair => edges.isEmpty ? null : (List.of(edges)..sort((a, b) => a.separation.compareTo(b.separation))).first;

  /// The planet with the strongest sign dignity (ties: the one closest to the cluster centre).
  String get dominantPlanet {
    int rank(String d) => switch (d) {
          'Exalted' => 6,
          'Moolatrikona' => 5,
          'Own Sign' => 4,
          final x when x.contains('Great Friend') => 3,
          final x when x.contains('Friend') => 2,
          final x when x.contains('Neutral') => 1,
          'Debilitated' => -2,
          _ => 0,
        };
    final ps = List.of(record.planets)..sort((a, b) => rank(grahas[b]!.dignity).compareTo(rank(grahas[a]!.dignity)));
    return ps.first;
  }

  /// Named yogas whose planets all sit in this cluster and that the yoga engine confirms.
  List<YogaResult> get namedYogas => _formedYogas
      .where((y) => y.planets.isNotEmpty && y.planets.toSet().difference({...record.planets, ...nodes}).isEmpty && y.planets.length >= 2)
      .toList();

  /// Running periods that activate the cluster.
  List<String> get activeNow {
    final out = <String>[];
    final levels = L10n.hi ? const ['महादशा', 'अंतर्दशा', 'प्रत्यंतर्दशा'] : const ['Mahadasha', 'Antardasha', 'Pratyantardasha'];
    for (int i = 0; i < runningLords.length && i < 3; i++) {
      final l = runningLords[i];
      final n = ConjunctionDb.planetName(l);
      if (record.planets.contains(l)) out.add(tr('${levels[i]} lord $n is a member of the cluster', '${levels[i]} स्वामी $n युति का सदस्य है'));
      if (l == record.dispositor && !record.planets.contains(l)) out.add(tr('${levels[i]} lord $n is the dispositor', '${levels[i]} स्वामी $n राशि स्वामी है'));
      if (nodes.contains(l)) out.add(tr('${levels[i]} lord $n is a node joined with the cluster', '${levels[i]} स्वामी $n युति के साथ छाया ग्रह है'));
      final h = record.bhava;
      if (VedicMath.rashis[(chart.lagnaRashi + h - 1) % 12].lord == l && !record.planets.contains(l) && l != record.dispositor) {
        out.add(tr('${levels[i]} lord $n owns the occupied house', '${levels[i]} स्वामी $n उस भाव का स्वामी है'));
      }
    }
    return out;
  }

  /// Upcoming Mahadasha/Antardasha periods ruled by a cluster member or its dispositor.
  List<DashaActivation> upcoming({int limit = 8, double? fromJd}) {
    final moon = chart.planetLongitudes['moon'];
    if (moon == null) return const [];
    final now = fromJd ?? Ephemeris.nowJd();
    final dashas = DashaCalculations.compute(chart.jd, moon, utcOffset: chart.utcOffset);
    final out = <DashaActivation>[];
    for (final md in dashas.mahadashas) {
      for (final ad in md.subPeriods) {
        if (ad.endJD < now) continue;
        final mdIn = record.planets.contains(md.lord), adIn = record.planets.contains(ad.lord);
        if (!mdIn && !adIn && ad.lord != record.dispositor) continue;
        final reason = mdIn && adIn
            ? tr('Both Mahadasha and Antardasha lords are in the cluster', 'महादशा और अंतर्दशा दोनों के स्वामी युति में हैं')
            : (adIn
                ? tr('Antardasha lord in the cluster', 'अंतर्दशा स्वामी युति में')
                : (mdIn ? tr('Mahadasha lord in the cluster', 'महादशा स्वामी युति में') : tr('Antardasha of the dispositor', 'राशि स्वामी की अंतर्दशा')));
        out.add(DashaActivation('Antardasha', ad.lord, md.lord, ad.startDate, ad.endDate, ad.startJD, reason));
        if (out.length >= limit) return out;
      }
    }
    return out;
  }
}

/// Volume 6 §17-18 cluster compression. These values are engineering
/// diagnostics (ENGINEERING_HEURISTIC), not classical scores.
class ClusterDiagnostics {
  final int size;
  final int pairEdges;
  final double degreeSpan;
  final double centerLongitude;
  final PairEdge? nearestPair;
  final PairEdge? widestPair;
  final String centralPlanet;
  final String dominantDignity;

  String get dominantDignityLabel => switch (dominantDignity) {
        'strong' => tr('strong', 'बलवान'),
        'weak' => tr('weak', 'कमज़ोर'),
        _ => tr('neutral', 'सम'),
      };
  final int combustCount;
  final int retrogradeCount;
  final List<String> nodes;
  final double compactness;
  final double dignityCoherence;
  final double houseCoherence;
  final double activationPotential;
  const ClusterDiagnostics(this.size, this.pairEdges, this.degreeSpan, this.centerLongitude, this.nearestPair, this.widestPair, this.centralPlanet,
      this.dominantDignity, this.combustCount, this.retrogradeCount, this.nodes, this.compactness, this.dignityCoherence, this.houseCoherence,
      this.activationPotential);

  static const String classification = 'ENGINEERING_HEURISTIC';

  static String dignityClass(String d) => switch (d) {
        'Exalted' || 'Moolatrikona' || 'Own Sign' => 'strong',
        'Debilitated' => 'weak',
        final x when x.contains('Enemy') => 'weak',
        _ => 'neutral',
      };

  /// Smallest arc containing all [longitudes] and its midpoint.
  static (double, double) arc(List<double> longitudes) {
    final ls = [for (final l in longitudes) VedicMath.norm360(l)]..sort();
    if (ls.length < 2) return (0, ls.isEmpty ? 0 : ls.first);
    var gap = 360 - ls.last + ls.first;
    var startIdx = 0;
    for (int i = 1; i < ls.length; i++) {
      if (ls[i] - ls[i - 1] > gap) {
        gap = ls[i] - ls[i - 1];
        startIdx = i;
      }
    }
    final span = 360 - gap;
    return (span, VedicMath.norm360(ls[startIdx] + span / 2));
  }

  factory ClusterDiagnostics.of(ChartConjunction cj) {
    final c = cj.chart;
    final ps = cj.record.planets;
    final (span, center) = arc([for (final p in ps) c.planetLongitudes[p]!]);
    final sorted = List.of(cj.edges)..sort((a, b) => a.separation.compareTo(b.separation));
    String central = ps.first;
    double best = double.infinity;
    for (final p in ps) {
      final sum = ps.fold<double>(0, (s, q) => s + PrecisionMath.separation(c.planetLongitudes[p]!, c.planetLongitudes[q]!));
      if (sum < best) {
        best = sum;
        central = p;
      }
    }
    final classes = [for (final p in ps) dignityClass(cj.grahas[p]!.dignity)];
    final counts = <String, int>{};
    for (final k in classes) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final top = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
    // Equal houses from the ascendant degree: whole-sign members can straddle a Bhava cusp.
    final eqHouses = [for (final p in ps) (VedicMath.norm360(c.planetLongitudes[p]! - c.ascendantSidereal + 15) / 30).floor() % 12];
    final hc = <int, int>{};
    for (final h in eqHouses) {
      hc[h] = (hc[h] ?? 0) + 1;
    }
    final levels = cj.activeNow.map((s) => s.split(' ').first).toSet().length;
    return ClusterDiagnostics(
      ps.length,
      cj.edges.length,
      span,
      center,
      sorted.isEmpty ? null : sorted.first,
      sorted.isEmpty ? null : sorted.last,
      central,
      top.key,
      ps.where((p) => cj.grahas[p]!.combust).length,
      ps.where((p) => cj.grahas[p]!.retrograde).length,
      cj.nodes,
      (1 - span / 30).clamp(0.0, 1.0),
      top.value / ps.length,
      hc.values.reduce((a, b) => a > b ? a : b) / ps.length,
      cj.runningLords.isEmpty ? 0 : levels / cj.runningLords.length.clamp(1, 3),
    );
  }

  Map<String, Object?> toJson() => {
        'classification': classification,
        'size': size,
        'pair_edges': pairEdges,
        'degree_span': double.parse(degreeSpan.toStringAsFixed(3)),
        'center_longitude': double.parse(centerLongitude.toStringAsFixed(2)),
        'nearest_pair': nearestPair == null ? null : '${nearestPair!.a}-${nearestPair!.b}',
        'widest_pair': widestPair == null ? null : '${widestPair!.a}-${widestPair!.b}',
        'central_planet': centralPlanet,
        'dominant_dignity': dominantDignity,
        'combust': combustCount,
        'retrograde': retrogradeCount,
        'nodes': nodes,
        'cluster_strength': {
          'compactness': double.parse(compactness.toStringAsFixed(2)),
          'dignity_coherence': double.parse(dignityCoherence.toStringAsFixed(2)),
          'house_coherence': double.parse(houseCoherence.toStringAsFixed(2)),
          'activation_potential': double.parse(activationPotential.toStringAsFixed(2)),
        },
      };
}

class NodeAssociation {
  final ChartData chart;
  final String node;
  final List<String> planets;
  final CalcConfig cfg;
  NodeAssociation(this.chart, this.node, this.planets, this.cfg);

  late final GrahaRecord graha = PrecisionMath.record(chart, node, cfg);
  late final List<PairEdge> edges = [for (final p in planets) PrecisionMath.edge(chart, node, p, cfg)];

  String get dispositor => graha.dispositor;
  String get nodePairType => node == 'rahu' ? 'Rahu-graha' : 'Ketu-graha';

  /// Phaladeepika: a node in a Kendra or Trikona joined with a Trikona or Kendra lord can give Raja Yoga.
  List<String> get contextualRole {
    final out = <String>[];
    final h = graha.house;
    final lagna = chart.lagnaRashi;
    String lordOf(int house) => VedicMath.rashis[(lagna + house - 1) % 12].lord;
    final kendraLords = {lordOf(1), lordOf(4), lordOf(7), lordOf(10)};
    final trikonaLords = {lordOf(1), lordOf(5), lordOf(9)};
    if (YogasMath.isKendra(h) && planets.any(trikonaLords.contains)) {
      final t = ConjunctionDb.planetName(planets.firstWhere(trikonaLords.contains));
      out.add(tr('In a Kendra with a Trikona lord ($t): can act as a Raja Yoga giver.', 'केन्द्र में त्रिकोण स्वामी ($t) के साथ: राज योग दे सकता है।'));
    }
    if (YogasMath.isTrikona(h) && planets.any(kendraLords.contains)) {
      final k = ConjunctionDb.planetName(planets.firstWhere(kendraLords.contains));
      out.add(tr('In a Trikona with a Kendra lord ($k): can act as a Raja Yoga giver.', 'त्रिकोण में केन्द्र स्वामी ($k) के साथ: राज योग दे सकता है।'));
    }
    if (YogasMath.isDusthana(h)) out.add(tr('In a dusthana (house $h).', 'दुःस्थान में (भाव $h)।'));
    final dh = PrecisionMath.record(chart, dispositor, cfg).house;
    out.add(tr('Results follow its dispositor ${ConjunctionDb.planetName(dispositor)} (house $dh) and nakshatra lord ${ConjunctionDb.planetName(graha.nakshatraLord)}.',
        'फल इसके राशि स्वामी ${ConjunctionDb.planetName(dispositor)} (भाव $dh) और नक्षत्र स्वामी ${ConjunctionDb.planetName(graha.nakshatraLord)} के अनुसार।'));
    return out;
  }
}
