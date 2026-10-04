import '../l10n.dart';

/// Everyday meanings of planets, houses and signs, summarised from the
/// classical significations (karakatva) in BPHS (ch. on graha and bhava
/// significations), Phaladeepika ch. 2 and 15, and Saravali. Written in plain
/// language for people who are not astrologers.
class Meanings {
  /// What a planet stands for in daily life.
  static const Map<String, (String, String)> planets = {
    'sun': (
      'self-confidence, authority, father, government, health and reputation',
      'आत्मविश्वास, अधिकार, पिता, सरकार, स्वास्थ्य और मान-सम्मान',
    ),
    'moon': (
      'mind and emotions, mother, peace of mind, home comforts and the public',
      'मन और भावनाएँ, माता, मानसिक शांति, घर का सुख और जनता',
    ),
    'mars': (
      'energy, courage, younger siblings, land and property, sports, technical skill and temper',
      'ऊर्जा, साहस, छोटे भाई-बहन, भूमि-संपत्ति, खेल, तकनीकी कौशल और क्रोध',
    ),
    'mercury': (
      'intelligence, speech, learning, business and trade, writing, calculation and friends',
      'बुद्धि, वाणी, पढ़ाई, व्यापार, लेखन, गणना और मित्र',
    ),
    'jupiter': (
      'wisdom, teachers, children, wealth, faith, ethics and good fortune',
      'ज्ञान, गुरु, संतान, धन, आस्था, नैतिकता और सौभाग्य',
    ),
    'venus': (
      'love and marriage, spouse, beauty, art and music, comforts, vehicles and luxury',
      'प्रेम और विवाह, जीवनसाथी, सुंदरता, कला-संगीत, सुख-सुविधा, वाहन और विलासिता',
    ),
    'saturn': (
      'discipline, hard work, patience, delays, long life, workers and service, justice',
      'अनुशासन, कड़ी मेहनत, धैर्य, देरी, दीर्घायु, सेवा और कर्मचारी, न्याय',
    ),
    'rahu': (
      'ambition, desire, foreign things, technology, unconventional paths and sudden events',
      'महत्वाकांक्षा, इच्छाएँ, विदेश, तकनीक, अपरंपरागत रास्ते और अचानक घटनाएँ',
    ),
    'ketu': (
      'detachment, spirituality, research, intuition, past-life tendencies and sudden separations',
      'वैराग्य, आध्यात्मिकता, शोध, अंतर्ज्ञान, पूर्व जन्म के संस्कार और अचानक अलगाव',
    ),
  };

  /// Life areas of each house.
  static const List<(String, String)> houses = [
    ('your self, body, health, personality and overall direction in life', 'आप स्वयं, शरीर, स्वास्थ्य, व्यक्तित्व और जीवन की दिशा'),
    ('money and savings, family, speech and food', 'धन और बचत, परिवार, वाणी और भोजन'),
    ('courage, effort, skills, communication, younger siblings and short journeys', 'साहस, प्रयास, कौशल, संवाद, छोटे भाई-बहन और छोटी यात्राएँ'),
    ('home, mother, property, vehicles, inner happiness and schooling', 'घर, माता, संपत्ति, वाहन, मन का सुख और प्रारंभिक शिक्षा'),
    ('children, intelligence, creativity, romance, studies and investments', 'संतान, बुद्धि, रचनात्मकता, प्रेम, पढ़ाई और निवेश'),
    ('job and daily work, competition, enemies, debts and health issues', 'नौकरी और रोज़ का काम, प्रतियोगिता, शत्रु, कर्ज़ और रोग'),
    ('marriage, spouse, partnerships, contracts and dealing with the public', 'विवाह, जीवनसाथी, साझेदारी, अनुबंध और लोगों से व्यवहार'),
    ('sudden changes, longevity, inheritance, secrets, research and transformation', 'अचानक बदलाव, आयु, विरासत, रहस्य, शोध और परिवर्तन'),
    ('luck, father, teachers, religion, higher education and long journeys', 'भाग्य, पिता, गुरु, धर्म, उच्च शिक्षा और लंबी यात्राएँ'),
    ('career, status, actions, authority and public reputation', 'करियर, पद-प्रतिष्ठा, कर्म, अधिकार और समाज में नाम'),
    ('income, gains, friends, networks, elder siblings and fulfilment of wishes', 'आय, लाभ, मित्र, संपर्क, बड़े भाई-बहन और इच्छापूर्ति'),
    ('expenses, losses, foreign lands, sleep, hospitals, retreat and spirituality', 'खर्च, हानि, विदेश, नींद, अस्पताल, एकांत और आध्यात्मिकता'),
  ];

  /// One-word area names of the houses for short sentences.
  static const List<(String, String)> houseShort = [
    ('self', 'स्वयं'), ('money & family', 'धन व परिवार'), ('courage & effort', 'साहस व प्रयास'), ('home & mother', 'घर व माता'),
    ('children & intellect', 'संतान व बुद्धि'), ('work & competition', 'काम व प्रतियोगिता'), ('marriage & partners', 'विवाह व साझेदारी'),
    ('sudden change', 'अचानक परिवर्तन'), ('luck & dharma', 'भाग्य व धर्म'), ('career', 'करियर'), ('gains & friends', 'लाभ व मित्र'),
    ('expenses & foreign', 'खर्च व विदेश'),
  ];

  /// How each sign colours what happens there (Deep Research §6).
  static const List<(String, String)> signStyle = [
    ('with initiative and speed', 'पहल और तेज़ी के साथ'),
    ('steadily, with a focus on resources and stability', 'स्थिरता से, धन और सुरक्षा पर ध्यान देते हुए'),
    ('through communication and learning', 'संवाद और सीखने के माध्यम से'),
    ('with care and emotion', 'देखभाल और भावनाओं के साथ'),
    ('with authority and creativity', 'अधिकार और रचनात्मकता के साथ'),
    ('through analysis, detail and service', 'विश्लेषण, बारीकी और सेवा के माध्यम से'),
    ('through partnership, balance and negotiation', 'साझेदारी, संतुलन और बातचीत के माध्यम से'),
    ('intensely, with depth and transformation', 'गहराई और परिवर्तन के साथ, तीव्रता से'),
    ('with optimism, learning and expansion', 'आशावाद, ज्ञान और विस्तार के साथ'),
    ('with structure, discipline and career focus', 'व्यवस्था, अनुशासन और करियर पर ध्यान के साथ'),
    ('through systems, groups and new ideas', 'व्यवस्थाओं, समूहों और नए विचारों के माध्यम से'),
    ('with imagination, compassion and intuition', 'कल्पना, करुणा और अंतर्ज्ञान के साथ'),
  ];

  /// Plain summaries of the 21 pairs (Phaladeepika ch. 18 via the Deep Research report).
  static const Map<String, (String, String)> pairs = {
    'sun-moon': ('your identity and your emotions are closely tied together; what you feel shapes how you act', 'आपकी पहचान और भावनाएँ गहराई से जुड़ी हैं; जो आप महसूस करते हैं वही आपके काम को दिशा देता है'),
    'sun-mars': ('authority, courage and action combine; energetic and forceful, but needs control of anger', 'अधिकार, साहस और कर्म का मेल; ऊर्जावान और दृढ़, पर क्रोध पर नियंत्रण ज़रूरी'),
    'sun-mercury': ('intelligence, communication and administration (Budha-Aditya); a good mind for planning and speaking, if Mercury is not too close to the Sun', 'बुद्धि, संवाद और प्रशासन (बुध-आदित्य); योजना और वाणी के लिए अच्छा मन, यदि बुध सूर्य के बहुत पास (अस्त) न हो'),
    'sun-jupiter': ('authority guided by wisdom; respected for knowledge, advice and principles', 'ज्ञान से निर्देशित अधिकार; ज्ञान, सलाह और सिद्धांतों के लिए सम्मान'),
    'sun-venus': ('visibility, charm and creativity; interest in beauty, art, relationships and comforts', 'आकर्षण, रचनात्मकता और प्रसिद्धि; सुंदरता, कला, संबंधों और सुख-सुविधा में रुचि'),
    'sun-saturn': ('authority meets duty and endurance; success through patience, often after delays or friction with authority', 'अधिकार और कर्तव्य-सहनशीलता का मेल; धैर्य से सफलता, अक्सर देरी या उच्चाधिकारियों से खटपट के बाद'),
    'moon-mars': ('enterprise and emotional fire (Chandra-Mangala); good at earning and taking initiative, but feelings can run hot', 'उद्यम और भावनात्मक जोश (चन्द्र-मंगल); कमाने और पहल करने में अच्छे, पर भावनाएँ जल्दी भड़क सकती हैं'),
    'moon-mercury': ('quick, adaptable mind; good at learning, speaking and understanding people', 'तेज़ और लचीला मन; सीखने, बोलने और लोगों को समझने में अच्छे'),
    'moon-jupiter': ('caring, wise and supportive; good counsel and inner faith (true Gaja-Kesari needs Jupiter in a Kendra from the Moon and good strength)', 'देखभाल करने वाले, समझदार और सहायक; अच्छी सलाह और आंतरिक आस्था (सच्चा गजकेसरी योग चन्द्र से केन्द्र में बलवान गुरु से बनता है)'),
    'moon-venus': ('gentle, artistic and affectionate; loves comfort, beauty and harmony in relationships', 'कोमल, कलात्मक और स्नेही; सुख, सुंदरता और संबंधों में सामंजस्य पसंद'),
    'moon-saturn': ('serious and responsible; emotions held back, with great endurance; can feel low at times', 'गंभीर और ज़िम्मेदार; भावनाएँ नियंत्रित, बहुत सहनशक्ति; कभी-कभी मन उदास हो सकता है'),
    'mars-mercury': ('technical and strategic mind; good at debate, engineering, trading and problem-solving, but words can be sharp', 'तकनीकी और रणनीतिक दिमाग; बहस, इंजीनियरिंग, व्यापार और समस्या सुलझाने में अच्छे, पर वाणी तीखी हो सकती है'),
    'mars-jupiter': ('leadership with principles; bold action guided by wisdom', 'सिद्धांतों के साथ नेतृत्व; ज्ञान से निर्देशित साहसिक कर्म'),
    'mars-venus': ('passion, creativity and desire; strong attraction and drive in love and art', 'जुनून, रचनात्मकता और इच्छा; प्रेम और कला में तीव्र आकर्षण और ऊर्जा'),
    'mars-saturn': ('force meets restraint; persistence and toughness, but frustration when progress is blocked', 'शक्ति और संयम का मेल; दृढ़ता और कठोर परिश्रम, पर रुकावट में झुंझलाहट'),
    'mercury-jupiter': ('scholarly mind; good for writing, teaching, advising, finance and law', 'विद्वान बुद्धि; लेखन, अध्यापन, सलाह, वित्त और कानून के लिए अच्छा'),
    'mercury-venus': ('talent with language, design, music, negotiation and commerce', 'भाषा, डिज़ाइन, संगीत, बातचीत और व्यापार में प्रतिभा'),
    'mercury-saturn': ('systematic, practical mind; good with numbers, technical work and careful communication', 'व्यवस्थित और व्यावहारिक बुद्धि; गणना, तकनीकी काम और सावधान संवाद में अच्छे'),
    'jupiter-venus': ('learning, wealth, arts and relationships; enjoys good things, with some tension between principle and pleasure', 'ज्ञान, धन, कला और संबंध; अच्छी चीज़ों का आनंद, पर सिद्धांत और सुख के बीच कुछ खिंचाव'),
    'jupiter-saturn': ('expansion with structure; long-term planning, building institutions and steady growth', 'व्यवस्था के साथ विस्तार; दीर्घकालिक योजना, संस्थाओं का निर्माण और स्थिर प्रगति'),
    'venus-saturn': ('craftsmanship and disciplined creativity; lasting resources and serious, committed relationships', 'कारीगरी और अनुशासित रचनात्मकता; टिकाऊ संसाधन और गंभीर, प्रतिबद्ध संबंध'),
  };

  static String planet(String p) {
    final m = planets[p];
    return m == null ? p : tr(m.$1, m.$2);
  }

  static String house(int h) => tr(houses[h - 1].$1, houses[h - 1].$2);
  static String houseArea(int h) => tr(houseShort[h - 1].$1, houseShort[h - 1].$2);
  static String sign(int r) => tr(signStyle[r].$1, signStyle[r].$2);

  static String pair(String a, String b) {
    const order = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];
    final x = order.indexOf(a) <= order.indexOf(b) ? '$a-$b' : '$b-$a';
    final m = pairs[x];
    return m == null ? '' : tr(m.$1, m.$2);
  }
}
