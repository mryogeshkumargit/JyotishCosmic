import '../ashtakavarga_math.dart';
import '../conjunction_db.dart';
import '../l10n.dart';
import '../shadbala_math.dart';
import '../synthesis_engine.dart';
import '../yogas_math.dart';
import 'meanings.dart';
import 'yoga_meanings.dart';

/// Turns the technical results into short explanations a non-astrologer can
/// follow. Every sentence is derived from the computed chart factors; nothing
/// here predicts a definite event.
class Interpret {
  static String _p(String p) => L10n.planet(p);

  // ---------------------------------------------------------------------------
  // Life domains
  // ---------------------------------------------------------------------------

  static const Map<String, String> domainHindi = {
    'identity': 'व्यक्तित्व और स्वास्थ्य-ऊर्जा',
    'wealth': 'धन और बचत',
    'skills': 'कौशल, संवाद और भाई-बहन',
    'home': 'घर, संपत्ति और माता',
    'children': 'संतान और रचनात्मकता',
    'health': 'स्वास्थ्य, सेवा और प्रतियोगिता',
    'marriage': 'विवाह और साझेदारी',
    'transformation': 'परिवर्तन, विरासत और शोध',
    'fortune': 'भाग्य, पिता और उच्च शिक्षा',
    'career': 'करियर और पद',
    'gains': 'लाभ और संपर्क',
    'foreign': 'खर्च, विदेश और एकांत',
    'education': 'शिक्षा और बुद्धि',
    'spiritual': 'आध्यात्मिक साधना और शोध',
  };

  static String domainName(LifeDomain d) => L10n.hi ? (domainHindi[d.id] ?? d.name) : d.name;

  static const Map<String, String> _dimensionsHi = {
    'identity': 'स्वभाव, आत्म-दिशा, जीवनशक्ति',
    'wealth': 'संचित धन, आय, निवेश, भाग्य',
    'skills': 'पहल, संवाद, छोटे भाई-बहन',
    'home': 'खरीद, निर्माण, स्थान परिवर्तन, बिक्री, विरासत',
    'children': 'संतान, रचनात्मकता, बुद्धि',
    'health': 'दिनचर्या, प्रतियोगिता, कर्ज़, जीवनशक्ति',
    'marriage': 'संबंध की शुरुआत, साझेदारी, औपचारिकता, तनाव, अलगाव के संकेत',
    'transformation': 'शोध, संयुक्त धन, बड़ा परिवर्तन',
    'fortune': 'भाग्य, पिता/गुरु, तीर्थ',
    'career': 'नौकरी, पदोन्नति/अधिकार, भूमिका परिवर्तन, व्यवसाय, कार्यस्थल विवाद, काम से लाभ',
    'gains': 'आय के स्रोत, संपर्क, महत्वाकांक्षाएँ',
    'foreign': 'यात्रा, अस्थायी निवास, स्थान परिवर्तन, विदेश में काम, दीर्घकालिक निवास',
    'education': 'प्रारंभिक शिक्षा, उच्च शिक्षा, विशेष अध्ययन, अध्यापन/शोध',
    'spiritual': 'आध्यात्मिक साधना, शैक्षणिक शोध, गूढ़ रुचियाँ, जीवन परिवर्तन',
  };

  static String dimensions(LifeDomain d) => L10n.hi ? (_dimensionsHi[d.id] ?? d.dimensions.join(', ')) : d.dimensions.join(', ');

  static String v6Label(V6Status s) => L10n.hi
      ? const {
          V6Status.notSupported: 'समर्थित नहीं',
          V6Status.natalPromise: 'जन्म का वादा',
          V6Status.supported: 'समर्थित',
          V6Status.activated: 'सक्रिय',
          V6Status.timingWindow: 'समय आगे',
          V6Status.confirmedByTransit: 'गोचर से पुष्ट',
          V6Status.conflicted: 'मिश्रित संकेत',
          V6Status.insufficientData: 'अपर्याप्त जानकारी',
        }[s]!
      : s.code;

  /// Label for a V6 status code string (e.g. a timing window status).
  static String v6CodeLabel(String code) {
    for (final s in V6Status.values) {
      if (s.code == code) return v6Label(s);
    }
    return code;
  }

  static String confidenceLabel(Confidence c) => L10n.hi ? confidenceWord(c) : c.code;

  static String statusLabel(PredictionStatus s) => L10n.hi
      ? const {
          PredictionStatus.natalPromisePresent: 'वादा उपस्थित',
          PredictionStatus.natalPromiseWeak: 'वादा कमज़ोर',
          PredictionStatus.natalContradiction: 'विरोधाभास',
          PredictionStatus.timingActive: 'समय सक्रिय',
          PredictionStatus.transitConfirmed: 'गोचर पुष्ट',
          PredictionStatus.vargaConfirmed: 'वर्ग पुष्ट',
          PredictionStatus.partialConvergence: 'आंशिक सहमति',
          PredictionStatus.insufficientData: 'अपर्याप्त जानकारी',
        }[s]!
      : s.code;

  /// Master KB codes (dependency states and status policy).
  static String codeLabel(String code) => L10n.hi
      ? (const {
            'SUPPORTING': 'समर्थक',
            'OPPOSING': 'विरोधी',
            'MIXED': 'मिश्रित',
            'ABSENT': 'अनुपस्थित',
            'NOT_APPLICABLE': 'लागू नहीं',
            'PRESENT': 'उपस्थित',
            'SUPPORTED': 'समर्थित',
            'CONDITIONALLY_SUPPORTED': 'शर्तों सहित समर्थित',
            'CONFLICTED': 'विरोधाभासी',
            'INSUFFICIENT_INPUT': 'अपर्याप्त जानकारी',
            'NATAL_PROMISE': 'जन्म का वादा',
            'BHAVA_LORD_CHAIN': 'भावेश श्रृंखला',
            'PLANETARY_STRENGTH': 'ग्रह बल',
            'CONJUNCTION_SYNTHESIS': 'युति संश्लेषण',
            'DASHA_ACTIVATION': 'दशा सक्रियता',
            'TRANSIT_CONFIRMATION': 'गोचर पुष्टि',
            'HIGH': 'प्रबल',
            'MEDIUM': 'मध्यम',
            'LOW': 'कमज़ोर',
          }[code] ??
          code)
      : code.replaceAll('_', ' ').toLowerCase();

  /// Activation tag such as MERCURY_MD or SATURN_3RD_ASPECT_SUN, in words.
  static String tag(String t) {
    if (!L10n.hi) return t;
    const planets = ['SUN', 'MOON', 'MARS', 'MERCURY', 'JUPITER', 'VENUS', 'SATURN', 'RAHU', 'KETU'];
    return t.split('_').map((w) {
      if (planets.contains(w)) return L10n.planet(w.toLowerCase());
      if (w == 'MD') return 'महादशा';
      if (w == 'AD') return 'अंतर्दशा';
      if (w == 'TRANSIT') return 'गोचर';
      if (w == 'ASPECT') return 'दृष्टि';
      if (RegExp(r'^\d+(ST|ND|RD|TH)$').hasMatch(w)) return '${w.replaceAll(RegExp('[A-Z]'), '')}वीं';
      if (RegExp(r'^H\d+$').hasMatch(w)) return '${w.substring(1)}वाँ भाव';
      return w;
    }).join(' ');
  }

  /// Headline for a domain in plain words.
  static String domainHeadline(DomainSynthesis d) => switch (d.v6Status) {
        V6Status.confirmedByTransit => tr('Active now: your running planetary period and current planet movements both support this area.',
            'अभी सक्रिय: चल रही दशा और वर्तमान ग्रह-गोचर दोनों इस क्षेत्र का साथ दे रहे हैं।'),
        V6Status.activated => tr('Switched on now: your running planetary period (Daśā) is connected with this area, so it is likely to be a focus.',
            'अभी चालू: चल रही दशा इस क्षेत्र से जुड़ी है, इसलिए यह अभी ध्यान का विषय रहेगा।'),
        V6Status.timingWindow => tr('Promised, with timing ahead: the chart supports this area and the next active periods are listed below.',
            'वादा है, समय आगे है: कुंडली इस क्षेत्र का साथ देती है और आगे के सक्रिय समय नीचे दिए गए हैं।'),
        V6Status.supported => tr('Well supported in the birth chart, though not specially active right now.',
            'जन्म कुंडली में अच्छा सहारा है, हालांकि अभी विशेष रूप से सक्रिय नहीं है।'),
        V6Status.natalPromise => tr('Some promise, with limited support: results come mainly through your own effort.',
            'कुछ संभावना है पर सहारा सीमित है: फल मुख्यतः आपके प्रयास से मिलेंगे।'),
        V6Status.notSupported => tr('Not strongly indicated: this is unlikely to be a main theme of your life for now.',
            'प्रबल संकेत नहीं: फ़िलहाल यह आपके जीवन का मुख्य विषय होने की संभावना कम है।'),
        V6Status.conflicted => tr('Mixed signals: some factors help and others hold back; the outcome depends on effort and timing.',
            'मिले-जुले संकेत: कुछ कारक मदद करते हैं और कुछ रोकते हैं; परिणाम प्रयास और समय पर निर्भर है।'),
        V6Status.insufficientData => tr('Not enough data to judge this area.', 'इस क्षेत्र को आंकने के लिए पर्याप्त जानकारी नहीं।'),
      };

  static String confidenceWord(Confidence c) => switch (c) {
        Confidence.veryStrong => tr('very strong', 'बहुत प्रबल'),
        Confidence.strong => tr('strong', 'प्रबल'),
        Confidence.moderate => tr('moderate', 'मध्यम'),
        Confidence.low => tr('weak', 'कमज़ोर'),
        Confidence.conflicted => tr('mixed', 'मिश्रित'),
        Confidence.insufficient => tr('unclear', 'अस्पष्ट'),
      };

  /// Plain explanation of one domain: what helps, what holds back, when.
  static List<String> domain(DomainSynthesis d, {required double now}) {
    final out = <String>[domainHeadline(d)];
    int count(EvidenceLayer l, Polarity p) => d.layer(l).where((e) => e.polarity == p).length;
    final plus = count(EvidenceLayer.natal, Polarity.support) + count(EvidenceLayer.strength, Polarity.support);
    final minus = count(EvidenceLayer.natal, Polarity.obstruction) + count(EvidenceLayer.strength, Polarity.obstruction);
    out.add(tr('Overall evidence is ${confidenceWord(d.confidence)}: $plus factors in your birth chart help this area and $minus hold it back.',
        'कुल प्रमाण ${confidenceWord(d.confidence)} है: जन्म कुंडली के $plus कारक इस क्षेत्र की मदद करते हैं और $minus रुकावट डालते हैं।'));

    final h = d.domain.bhavas.first;
    out.add(tr('This area is judged mainly from your ${L10n.house(h)} (${Meanings.house(h)}).',
        'यह क्षेत्र मुख्यतः आपके ${L10n.house(h)} (${Meanings.house(h)}) से देखा जाता है।'));

    final dasha = d.layer(EvidenceLayer.dasha).where((e) => e.polarity == Polarity.support).isNotEmpty;
    out.add(dasha
        ? tr('Timing: your current Daśā lords are linked with this area, which usually brings related events or decisions now.',
            'समय: आपकी वर्तमान दशा के स्वामी इस क्षेत्र से जुड़े हैं, जिससे अभी इससे जुड़ी घटनाएँ या निर्णय आते हैं।')
        : tr('Timing: your current Daśā lords are not directly linked with this area, so it is quieter for now.',
            'समय: आपकी वर्तमान दशा के स्वामी इस क्षेत्र से सीधे नहीं जुड़े हैं, इसलिए यह अभी शांत है।'));

    final next = d.timingWindows.where((w) => w.endJd >= now).take(2).toList();
    if (next.isNotEmpty) {
      out.add(tr('Likely active periods: ${next.map((w) => '${w.start} – ${w.end}').join('; ')}. These are windows, not exact dates.',
          'संभावित सक्रिय समय: ${next.map((w) => '${w.start} – ${w.end}').join('; ')}। ये समय-सीमाएँ हैं, सटीक तिथियाँ नहीं।'));
    } else if (d.windows.isNotEmpty) {
      final w = d.windows.first;
      out.add(tr('Next supportive Daśā period: ${w.start} – ${w.end}.', 'अगली सहायक दशा: ${w.start} – ${w.end}।'));
    }
    if (d.domain.caution != null) {
      out.add(tr(d.domain.caution!, switch (d.domain.id) {
        'wealth' => 'कर्ज़ और हानि अलग से 6, 8 और 12वें भाव से देखे जाते हैं।',
        'health' => 'यह केवल पारंपरिक संकेत है; चिकित्सकीय सलाह का विकल्प नहीं।',
        _ => d.domain.caution!,
      }));
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Conjunctions
  // ---------------------------------------------------------------------------

  static List<String> conjunction(ChartConjunction cj) {
    final r = cj.record;
    final names = L10n.join(r.planets.map(_p).toList());
    final out = <String>[
      tr('$names sit together ${L10n.inHouse(r.bhava)} in ${L10n.sign(r.rashi)}. Their energies blend, and the result shows up mainly in ${Meanings.house(r.bhava)}, expressed ${Meanings.sign(r.rashi)}.',
          '$names एक साथ ${L10n.inHouse(r.bhava)} ${L10n.sign(r.rashi)} राशि में हैं। इनकी ऊर्जाएँ मिलती हैं और परिणाम मुख्यतः ${Meanings.house(r.bhava)} में दिखता है, ${Meanings.sign(r.rashi)}।'),
    ];
    for (final (a, b) in r.pairs.take(3)) {
      out.add('${_p(a)} + ${_p(b)}: ${Meanings.pair(a, b)}${tr('.', '।')}');
    }
    if (r.pairs.length > 3) {
      out.add(tr('With ${r.size} planets there are ${r.pairs.length} pairings; read the leading planet first.',
          '${r.size} ग्रहों से ${r.pairs.length} जोड़े बनते हैं; पहले प्रमुख ग्रह को देखें।'));
    }
    final dom = cj.dominantPlanet;
    out.add(tr('${_p(dom)} is the strongest member, so its themes (${Meanings.planet(dom)}) lead this combination.',
        '${_p(dom)} सबसे बलवान सदस्य है, इसलिए इसके विषय (${Meanings.planet(dom)}) इस युति में आगे रहते हैं।'));
    final disp = r.dispositor;
    out.add(tr('The sign lord ${_p(disp)} (house ${cj.dispositorRecord.house}) decides how well the combination can deliver; its condition is ${L10n.dignity(cj.dispositorRecord.dignity).toLowerCase()}.',
        'राशि स्वामी ${_p(disp)} (भाव ${cj.dispositorRecord.house}) तय करता है कि यह युति कितना फल देगी; उसकी स्थिति ${L10n.dignity(cj.dispositorRecord.dignity)} है।'));
    final combust = r.planets.where((p) => p != 'sun' && cj.grahas[p]!.combust).toList();
    if (combust.isNotEmpty) {
      out.add(tr('${L10n.join(combust.map(_p).toList())} is very close to the Sun (combust), so its results are weaker or hidden until effort brings them out.',
          '${L10n.join(combust.map(_p).toList())} सूर्य के बहुत पास (अस्त) है, इसलिए इसके फल कमज़ोर या छिपे रहते हैं जब तक प्रयास उन्हें बाहर न लाए।'));
    }
    if (cj.vargaRepetition.isNotEmpty) {
      out.add(tr('The same combination repeats in ${cj.vargaRepetition.join(' and ')}, which makes it more important in your life.',
          'यही युति ${cj.vargaRepetition.join(' और ')} में भी दोहराई गई है, जो इसे आपके जीवन में और महत्वपूर्ण बनाती है।'));
    }
    out.add(cj.activeNow.isNotEmpty
        ? tr('It is active now because your current Daśā is ruled by a member or by its sign lord.', 'यह अभी सक्रिय है क्योंकि आपकी वर्तमान दशा इसके किसी सदस्य या राशि स्वामी की है।')
        : tr('It becomes most noticeable during the Daśās of its planets or of its sign lord.', 'यह इसके ग्रहों या राशि स्वामी की दशा में सबसे अधिक दिखती है।'));
    return out;
  }

  // ---------------------------------------------------------------------------
  // Strength
  // ---------------------------------------------------------------------------

  static List<String> shadbala(ShadbalaResult sb) {
    final ranked = sb.ranked;
    if (ranked.isEmpty) return const [];
    final strong = ranked.where((s) => s.meetsMinimum).toList();
    final weak = ranked.where((s) => !s.meetsMinimum).toList();
    final out = <String>[
      tr('Shadbala measures how much power each planet has to give its results (six kinds of strength from position, direction, time, motion, nature and aspects). A planet at or above its required minimum can deliver well.',
          'षड्बल बताता है कि हर ग्रह में अपना फल देने की कितनी शक्ति है (स्थान, दिशा, काल, गति, स्वभाव और दृष्टि से छह प्रकार का बल)। जो ग्रह अपने आवश्यक न्यूनतम बल पर या उससे ऊपर है, वह अच्छा फल दे सकता है।'),
      tr('Strongest: ${_p(ranked.first.planet)} — areas of ${Meanings.planet(ranked.first.planet)} come to you more easily.',
          'सबसे बलवान: ${_p(ranked.first.planet)} — ${Meanings.planet(ranked.first.planet)} से जुड़े क्षेत्र आपको आसानी से मिलते हैं।'),
      tr('Weakest: ${_p(ranked.last.planet)} — areas of ${Meanings.planet(ranked.last.planet)} need more effort and care.',
          'सबसे कमज़ोर: ${_p(ranked.last.planet)} — ${Meanings.planet(ranked.last.planet)} से जुड़े क्षेत्रों में अधिक प्रयास और ध्यान चाहिए।'),
    ];
    if (strong.isNotEmpty) {
      out.add(tr('Planets with enough strength: ${L10n.join(strong.map((s) => _p(s.planet)).toList())}.',
          'पर्याप्त बल वाले ग्रह: ${L10n.join(strong.map((s) => _p(s.planet)).toList())}।'));
    }
    if (weak.isNotEmpty) {
      out.add(tr('Planets below their minimum: ${L10n.join(weak.map((s) => _p(s.planet)).toList())}. Their Daśās can feel harder, and remedies traditionally focus on them.',
          'न्यूनतम से कम बल वाले ग्रह: ${L10n.join(weak.map((s) => _p(s.planet)).toList())}। इनकी दशा कठिन लग सकती है और परंपरागत उपाय इन्हीं पर केंद्रित होते हैं।'));
    }
    return out;
  }

  static List<String> bhavaBala(ShadbalaResult sb) {
    if (sb.bhavas.isEmpty) return const [];
    final sorted = List.of(sb.bhavas)..sort((a, b) => b.total.compareTo(a.total));
    final top = sorted.take(3).toList();
    final low = sorted.reversed.take(2).toList();
    return [
      tr('Bhāva Bala shows which areas of life are naturally strong in your chart.', 'भाव बल बताता है कि आपकी कुंडली में जीवन के कौन से क्षेत्र स्वाभाविक रूप से मज़बूत हैं।'),
      tr('Strongest houses: ${top.map((b) => '${L10n.ordinal(b.house)} (${Meanings.houseArea(b.house)})').join(', ')} — these areas tend to go well with less struggle.',
          'सबसे मज़बूत भाव: ${top.map((b) => '${L10n.ordinal(b.house)} (${Meanings.houseArea(b.house)})').join(', ')} — ये क्षेत्र कम संघर्ष में अच्छे चलते हैं।'),
      tr('Weakest houses: ${low.map((b) => '${L10n.ordinal(b.house)} (${Meanings.houseArea(b.house)})').join(', ')} — give these areas extra attention.',
          'सबसे कमज़ोर भाव: ${low.map((b) => '${L10n.ordinal(b.house)} (${Meanings.houseArea(b.house)})').join(', ')} — इन क्षेत्रों पर अधिक ध्यान दें।'),
    ];
  }

  static List<String> ashtakavarga(AshtakavargaResult av) {
    final houses = [for (int h = 1; h <= 12; h++) (h, av.sarvaInHouse(h))];
    final good = houses.where((x) => x.$2 >= 28).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final weak = houses.where((x) => x.$2 < 25).toList()..sort((a, b) => a.$2.compareTo(b.$2));
    String list(List<(int, int)> xs) => xs.map((x) => '${L10n.ordinal(x.$1)} (${Meanings.houseArea(x.$1)}, ${x.$2})').join(', ');
    return [
      tr('Ashtakavarga gives each house points (bindus) from all planets. The average is 28; more points mean that area gets more support, especially when slow planets like Jupiter and Saturn pass through it.',
          'अष्टकवर्ग हर भाव को सभी ग्रहों से अंक (बिंदु) देता है। औसत 28 है; अधिक अंक का अर्थ है उस क्षेत्र को अधिक सहारा, ख़ासकर जब गुरु और शनि जैसे धीमे ग्रह वहाँ से गोचर करें।'),
      if (good.isNotEmpty)
        tr('Well-supported houses: ${list(good.take(4).toList())}.', 'अच्छे सहारे वाले भाव: ${list(good.take(4).toList())}।'),
      if (weak.isNotEmpty)
        tr('Houses with fewer points: ${list(weak.take(3).toList())}. Transits through these signs usually bring more effort for less result.',
            'कम अंक वाले भाव: ${list(weak.take(3).toList())}। इन राशियों से गोचर प्रायः अधिक प्रयास और कम फल देता है।'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Yogas
  // ---------------------------------------------------------------------------

  static String yogaStrength(String s) {
    if (!L10n.hi) return s;
    // Longer phrases first so 'Not formed' is not split by 'Formed'.
    const m = {
      'Weak (Mercury combust)': 'कमज़ोर (बुध अस्त)',
      'Weak (strongest planet combust)': 'कमज़ोर (सबसे बलवान ग्रह अस्त)',
      'Shubha (benefic)': 'शुभ',
      'Papa (malefic)': 'पाप',
      'From Moon only': 'केवल चन्द्र से',
      'Not applicable': 'लागू नहीं',
      'Not formed': 'नहीं बना',
      'Strong': 'प्रबल', 'Moderate': 'मध्यम', 'Weak': 'कमज़ोर', 'Cancelled': 'भंग', 'Mitigated': 'कम प्रभावी', 'Challenging': 'चुनौतीपूर्ण',
      'Formed': 'बना', 'Secondary': 'गौण', 'Protective': 'रक्षक', 'Debilitated': 'नीच', 'Mixed': 'मिश्रित',
    };
    var out = s;
    for (final e in m.entries) {
      out = out.replaceAll(e.key, e.value);
    }
    return out;
  }

  static String yoga(YogaResult y) {
    final b = StringBuffer(YogaMeanings.meaning(y.name, y.category));
    if (y.formed) {
      final s = y.strength;
      if (s.contains('Cancelled')) {
        b.write(tr(' In your chart it is cancelled by other factors, so its effect is small.', ' आपकी कुंडली में यह अन्य कारकों से भंग है, इसलिए इसका प्रभाव कम है।'));
      } else if (s.contains('Weak') || s.contains('Mitigated')) {
        b.write(tr(' In your chart it is weak, so expect a milder result.', ' आपकी कुंडली में यह कमज़ोर है, इसलिए फल हल्का रहेगा।'));
      } else if (s.contains('Strong')) {
        b.write(tr(' In your chart it is strong.', ' आपकी कुंडली में यह प्रबल है।'));
      }
      if (y.active) {
        b.write(tr(' It is especially active now because your current Daśā is run by one of its planets.',
            ' यह अभी विशेष रूप से सक्रिय है क्योंकि वर्तमान दशा इसके किसी ग्रह की है।'));
      } else if (y.planets.isNotEmpty) {
        b.write(tr(' It works most clearly during the Daśā of ${L10n.join(y.planets.toSet().map(_p).toList())}.',
            ' यह ${L10n.join(y.planets.toSet().map(_p).toList())} की दशा में सबसे स्पष्ट फल देता है।'));
      }
    }
    return b.toString();
  }

  /// One-paragraph overview of the formed yogas.
  static String yogaSummary(List<YogaResult> formed) {
    final good = formed.where((y) => y.nature != YogaNature.adverse && !y.category.startsWith('Nabhasa')).length;
    final hard = formed.where((y) => y.nature == YogaNature.adverse).length;
    final active = formed.where((y) => y.active).length;
    return tr(
        'Yogas are special planetary combinations. Your chart forms $good helpful and $hard challenging yogas (plus general pattern yogas). $active of them are active in your current Daśā. A yoga shows a potential; it gives results mainly in the Daśā of its planets and in proportion to their strength.',
        'योग ग्रहों के विशेष मेल हैं। आपकी कुंडली में $good शुभ और $hard चुनौतीपूर्ण योग बनते हैं (साथ में सामान्य नभस योग)। इनमें से $active आपकी वर्तमान दशा में सक्रिय हैं। योग एक संभावना दिखाता है; यह मुख्यतः अपने ग्रहों की दशा में और उनके बल के अनुसार फल देता है।');
  }

  /// Short house-and-planet line used in several screens.
  static String planetInHouse(String p, int house, int sign) => tr(
      '${_p(p)} ${L10n.inHouse(house)} (${Meanings.houseArea(house)}) in ${L10n.sign(sign)}: ${Meanings.planet(p)} are expressed through ${Meanings.house(house)}.',
      '${_p(p)} ${L10n.inHouse(house)} (${Meanings.houseArea(house)}), ${L10n.sign(sign)} राशि में: ${Meanings.planet(p)} — ये ${Meanings.house(house)} के माध्यम से व्यक्त होते हैं।');
}
