import '../l10n.dart';

/// A text in English and Hindi; [t] picks the current app language.
typedef Bi = (String, String);

extension BiText on Bi {
  String get t => tr($1, $2);
}

/// Classical reference tables used by the daily Rashifal.
///
/// Sources: weekday lords, Choghadiya and Disha Shool follow the common
/// Muhurta texts (Muhurta Chintamani tradition); nakshatra natures follow
/// Muhurta Chintamani ch. 2; beej mantras and donations are the customary
/// Navagraha remedies. They are traditions, not astronomical facts, and the
/// report says so.
class RashifalTables {
  /// Weekday lord, 0 = Sunday.
  static const List<String> varaLord = ['sun', 'moon', 'mars', 'mercury', 'jupiter', 'venus', 'saturn'];

  static const List<Bi> varaSignificance = [
    (
      'Ruled by the Sun: authority, government work, health and dealings with father figures are favoured; good for leadership and starting medicines.',
      'सूर्य का दिन: अधिकार, सरकारी कार्य, स्वास्थ्य और पिता-तुल्य लोगों से जुड़े काम शुभ; नेतृत्व और दवा शुरू करने के लिए अच्छा।',
    ),
    (
      'Ruled by the Moon: emotions, mother, home, travel by water, creative and caring work are highlighted; good for gentle beginnings.',
      'चन्द्र का दिन: भावनाएँ, माता, घर, जल यात्रा, रचनात्मक और सेवा कार्य प्रमुख; सौम्य शुरुआत के लिए अच्छा।',
    ),
    (
      'Ruled by Mars: courage, sport, property, machinery and surgery; good for bold action, poor for lending money and starting quarrels.',
      'मंगल का दिन: साहस, खेल, संपत्ति, मशीनरी और शल्य चिकित्सा; साहसिक कार्य के लिए अच्छा, उधार देने और विवाद के लिए नहीं।',
    ),
    (
      'Ruled by Mercury: trade, learning, writing, communication and accounts; good for contracts, study and short trips.',
      'बुध का दिन: व्यापार, शिक्षा, लेखन, संवाद और हिसाब-किताब; अनुबंध, पढ़ाई और छोटी यात्राओं के लिए अच्छा।',
    ),
    (
      'Ruled by Jupiter: wisdom, teachers, religion, finance and children; one of the most auspicious days for beginnings and blessings.',
      'गुरु का दिन: ज्ञान, गुरु, धर्म, वित्त और संतान; शुभ आरंभ और आशीर्वाद के लिए सबसे अच्छे दिनों में से एक।',
    ),
    (
      'Ruled by Venus: love, marriage, arts, beauty, vehicles and luxury; good for relationships, shopping and celebrations.',
      'शुक्र का दिन: प्रेम, विवाह, कला, सौंदर्य, वाहन और विलासिता; संबंधों, खरीदारी और उत्सव के लिए अच्छा।',
    ),
    (
      'Ruled by Saturn: discipline, service, labour, land and long-term work; good for patient effort and charity, poor for hasty starts.',
      'शनि का दिन: अनुशासन, सेवा, श्रम, भूमि और दीर्घकालिक कार्य; धैर्यपूर्ण प्रयास और दान के लिए अच्छा, जल्दबाज़ी में शुरुआत के लिए नहीं।',
    ),
  ];

  /// Colour of each graha: (English, Hindi, hex).
  static const Map<String, (String, String, String)> planetColour = {
    'sun': ('Orange / Saffron', 'नारंगी / केसरिया', '#F57C00'),
    'moon': ('White / Silver', 'सफ़ेद / चाँदी', '#ECEFF1'),
    'mars': ('Red', 'लाल', '#D32F2F'),
    'mercury': ('Green', 'हरा', '#388E3C'),
    'jupiter': ('Yellow', 'पीला', '#FBC02D'),
    'venus': ('Pink / Light blue', 'गुलाबी / हल्का नीला', '#F48FB1'),
    'saturn': ('Dark blue / Black', 'गहरा नीला / काला', '#1A237E'),
    'rahu': ('Grey / Smoky', 'स्लेटी / धुएँ जैसा', '#757575'),
    'ketu': ('Brown / Multicolour', 'भूरा / चितकबरा', '#6D4C41'),
  };

  /// Beej mantra: (Devanagari, transliteration).
  static const Map<String, (String, String)> beejMantra = {
    'sun': ('ॐ ह्रां ह्रीं ह्रौं सः सूर्याय नमः', 'Om Hraam Hreem Hraum Sah Suryaya Namah'),
    'moon': ('ॐ श्रां श्रीं श्रौं सः चन्द्रमसे नमः', 'Om Shraam Shreem Shraum Sah Chandramase Namah'),
    'mars': ('ॐ क्रां क्रीं क्रौं सः भौमाय नमः', 'Om Kraam Kreem Kraum Sah Bhaumaya Namah'),
    'mercury': ('ॐ ब्रां ब्रीं ब्रौं सः बुधाय नमः', 'Om Braam Breem Braum Sah Budhaya Namah'),
    'jupiter': ('ॐ ग्रां ग्रीं ग्रौं सः गुरवे नमः', 'Om Graam Greem Graum Sah Gurave Namah'),
    'venus': ('ॐ द्रां द्रीं द्रौं सः शुक्राय नमः', 'Om Draam Dreem Draum Sah Shukraya Namah'),
    'saturn': ('ॐ प्रां प्रीं प्रौं सः शनैश्चराय नमः', 'Om Praam Preem Praum Sah Shanaishcharaya Namah'),
    'rahu': ('ॐ भ्रां भ्रीं भ्रौं सः राहवे नमः', 'Om Bhraam Bhreem Bhraum Sah Rahave Namah'),
    'ketu': ('ॐ स्रां स्रीं स्रौं सः केतवे नमः', 'Om Sraam Sreem Sraum Sah Ketave Namah'),
  };

  /// Deity associated with each graha for worship.
  static const Map<String, Bi> deity = {
    'sun': ('Lord Surya', 'भगवान सूर्य'),
    'moon': ('Lord Shiva', 'भगवान शिव'),
    'mars': ('Lord Hanuman', 'हनुमान जी'),
    'mercury': ('Lord Ganesha / Vishnu', 'गणेश जी / विष्णु'),
    'jupiter': ('Lord Vishnu / your Guru', 'भगवान विष्णु / गुरु'),
    'venus': ('Goddess Lakshmi', 'माँ लक्ष्मी'),
    'saturn': ('Lord Shani / Hanuman', 'शनि देव / हनुमान जी'),
    'rahu': ('Goddess Durga', 'माँ दुर्गा'),
    'ketu': ('Lord Ganesha', 'गणेश जी'),
  };

  static const Map<String, Bi> upay = {
    'sun': (
      'Offer water (Arghya) to the rising Sun from a copper vessel with a pinch of red sandal or a red flower, and respect your father and seniors.',
      'उगते सूर्य को तांबे के लोटे से जल (अर्घ्य) दें, उसमें लाल चंदन या लाल फूल डालें, और पिता व बड़ों का आदर करें।',
    ),
    'moon': (
      'Offer water or raw milk on a Shiva Linga, drink water from a silver glass and spend a few quiet minutes with your mother or in meditation.',
      'शिवलिंग पर जल या कच्चा दूध चढ़ाएँ, चाँदी के गिलास से पानी पिएँ और माता के साथ या ध्यान में कुछ शांत समय बिताएँ।',
    ),
    'mars': (
      'Recite the Hanuman Chalisa, offer sindoor and jaggery-gram at a Hanuman temple, and control anger in speech.',
      'हनुमान चालीसा का पाठ करें, हनुमान मंदिर में सिंदूर और गुड़-चना चढ़ाएँ, और वाणी में क्रोध पर नियंत्रण रखें।',
    ),
    'mercury': (
      'Feed green grass or spinach to a cow, worship Lord Ganesha with durva grass and keep your promises in writing.',
      'गाय को हरी घास या पालक खिलाएँ, दूर्वा से गणेश जी की पूजा करें और अपने वादे लिखित में रखें।',
    ),
    'jupiter': (
      'Apply a saffron or turmeric tilak, offer yellow flowers to Lord Vishnu or at a banana tree, and seek the blessing of a teacher or elder.',
      'केसर या हल्दी का तिलक लगाएँ, भगवान विष्णु या केले के पेड़ पर पीले फूल चढ़ाएँ, और गुरु या बड़ों का आशीर्वाद लें।',
    ),
    'venus': (
      'Worship Goddess Lakshmi with white flowers, wear clean bright clothes, use a mild fragrance and offer white sweets to young girls.',
      'सफ़ेद फूलों से माँ लक्ष्मी की पूजा करें, साफ़ उजले वस्त्र पहनें, हल्की सुगंध लगाएँ और कन्याओं को सफ़ेद मिठाई दें।',
    ),
    'saturn': (
      'Light a mustard-oil lamp under a peepal tree in the evening, help a labourer or elderly person, and finish pending duties patiently.',
      'शाम को पीपल के नीचे सरसों के तेल का दीपक जलाएँ, किसी श्रमिक या बुज़ुर्ग की मदद करें, और लंबित काम धैर्य से पूरे करें।',
    ),
    'rahu': (
      'Chant the Durga Kavach or "Om Durgayai Namah", feed birds, and avoid shortcuts, intoxicants and gossip today.',
      'दुर्गा कवच या "ॐ दुर्गायै नमः" का जाप करें, पक्षियों को दाना डालें, और आज शॉर्टकट, नशा और चुगली से बचें।',
    ),
    'ketu': (
      'Worship Lord Ganesha, feed a stray dog, and keep a few minutes of silence or prayer before important work.',
      'गणेश जी की पूजा करें, किसी आवारा कुत्ते को भोजन दें, और महत्वपूर्ण काम से पहले कुछ मिनट मौन या प्रार्थना करें।',
    ),
  };

  static const Map<String, Bi> donation = {
    'sun': ('Wheat, jaggery, copper or red cloth — ideally in the morning, to a temple or a needy person.', 'गेहूँ, गुड़, तांबा या लाल वस्त्र — सुबह किसी मंदिर या ज़रूरतमंद को।'),
    'moon': ('Rice, milk, curd, white cloth or silver — or water to the thirsty.', 'चावल, दूध, दही, सफ़ेद वस्त्र या चाँदी — या प्यासे को जल।'),
    'mars': (
      'Red lentils (masoor), jaggery, red cloth or sweets at a Hanuman temple; help a soldier or sportsperson.',
      'मसूर दाल, गुड़, लाल वस्त्र या हनुमान मंदिर में मिठाई; किसी सैनिक या खिलाड़ी की मदद।',
    ),
    'mercury': ('Green moong, green vegetables, books or stationery to students; green fodder to cows.', 'हरी मूंग, हरी सब्ज़ियाँ, विद्यार्थियों को किताबें या स्टेशनरी; गायों को हरा चारा।'),
    'jupiter': ('Chana dal, turmeric, bananas, yellow cloth or books; serve a teacher or a priest.', 'चना दाल, हल्दी, केले, पीला वस्त्र या पुस्तकें; किसी शिक्षक या पुरोहित की सेवा।'),
    'venus': ('Rice, sugar, white sweets, curd, perfume or clothes to women in need.', 'चावल, चीनी, सफ़ेद मिठाई, दही, इत्र या ज़रूरतमंद महिलाओं को वस्त्र।'),
    'saturn': (
      'Black sesame, mustard oil, black urad, iron items, shoes or a blanket to the poor and labourers.',
      'काले तिल, सरसों का तेल, काली उड़द, लोहे की वस्तुएँ, जूते या गरीबों व श्रमिकों को कंबल।',
    ),
    'rahu': ('A blue or black blanket, coconut, mustard or barley; feed birds.', 'नीला या काला कंबल, नारियल, सरसों या जौ; पक्षियों को दाना।'),
    'ketu': ('A multicoloured blanket, sesame or a meal for stray dogs.', 'चितकबरा कंबल, तिल या आवारा कुत्तों को भोजन।'),
  };

  /// Natural benefics (the Moon only when waxing, checked separately).
  static const Set<String> benefics = {'jupiter', 'venus', 'mercury', 'moon'};

  /// Combustion orbs (degrees from the Sun); retrograde Mercury 12, Venus 8.
  static const Map<String, double> combustOrb = {'moon': 12, 'mars': 17, 'mercury': 14, 'jupiter': 11, 'venus': 10, 'saturn': 15};

  /// Tara (count from the birth nakshatra, 1-9): name and whether favourable.
  static const List<(Bi, int)> taras = [
    (('Janma (birth star)', 'जन्म तारा'), 0),
    (('Sampat (wealth)', 'संपत् तारा'), 1),
    (('Vipat (danger)', 'विपत् तारा'), -1),
    (('Kshema (well-being)', 'क्षेम तारा'), 1),
    (('Pratyak (obstacle)', 'प्रत्यक् तारा'), -1),
    (('Sadhana (achievement)', 'साधना तारा'), 1),
    (('Naidhana (adversity)', 'नैधन तारा'), -2),
    (('Mitra (friend)', 'मित्र तारा'), 1),
    (('Parama Mitra (best friend)', 'परम मित्र तारा'), 1),
  ];

  /// Nature of each nakshatra (Muhurta Chintamani): index into [natures].
  static const List<int> nakshatraNature = [
    4, 2, 3, 0, 5, 6, 1, 4, 6, // Ashwini .. Ashlesha
    2, 2, 0, 4, 5, 1, 3, 5, 6, // Magha .. Jyeshtha
    6, 2, 0, 1, 1, 1, 2, 0, 5, // Mula .. Revati
  ];

  /// (name, suited activities, to avoid)
  static const List<(Bi, Bi, Bi)> natures = [
    (
      ('Dhruva (fixed)', 'ध्रुव (स्थिर)'),
      ('Foundations, house-warming, planting, long-term commitments and agreements.', 'नींव, गृह प्रवेश, पौधारोपण, दीर्घकालिक प्रतिबद्धताएँ और समझौते।'),
      ('Travel and hurried changes.', 'यात्रा और जल्दबाज़ी के बदलाव।'),
    ),
    (
      ('Chara (movable)', 'चर (चल)'),
      ('Travel, vehicles, changes of place, outings and new routines.', 'यात्रा, वाहन, स्थान परिवर्तन, घूमना और नई दिनचर्या।'),
      ('Permanent foundations.', 'स्थायी नींव रखना।'),
    ),
    (
      ('Ugra (fierce)', 'उग्र (क्रूर)'),
      ('Tough competition, demolition, disciplined effort and dealing with opponents.', 'कड़ी प्रतिस्पर्धा, तोड़-फोड़, अनुशासित प्रयास और विरोधियों से निपटना।'),
      ('Auspicious beginnings, ceremonies and new partnerships.', 'शुभ आरंभ, संस्कार और नई साझेदारी।'),
    ),
    (
      ('Mishra (mixed)', 'मिश्र (साधारण)'),
      ('Routine work, cooking, fire-related work and finishing pending tasks.', 'नियमित कार्य, भोजन बनाना, अग्नि संबंधी काम और लंबित काम पूरे करना।'),
      ('Major new ventures.', 'बड़े नए उद्यम।'),
    ),
    (
      ('Kshipra (swift)', 'क्षिप्र (लघु)'),
      ('Trade, quick deals, learning, healing, medicine and short journeys.', 'व्यापार, जल्दी सौदे, सीखना, उपचार, दवा और छोटी यात्राएँ।'),
      ('Marriage-type lifelong commitments.', 'विवाह जैसे जीवनभर के बंधन।'),
    ),
    (('Mridu (gentle)', 'मृदु (मैत्र)'), ('Friendship, romance, arts, music, new clothes and jewellery.', 'मित्रता, प्रेम, कला, संगीत, नए वस्त्र और आभूषण।'), ('Harsh confrontations.', 'कठोर टकराव।')),
    (
      ('Tikshna (sharp)', 'तीक्ष्ण (दारुण)'),
      ('Research, separation from bad habits, surgery-type decisive action and spiritual practice.', 'शोध, बुरी आदतें छोड़ना, निर्णायक कार्य और साधना।'),
      ('Celebrations, new friendships and soft negotiations.', 'उत्सव, नई मित्रता और नरम बातचीत।'),
    ),
  ];

  /// Ganda Moola nakshatras (junctions of water and fire signs).
  static const Set<int> gandaMoola = {0, 8, 9, 17, 18, 26};

  /// Nakshatras traditionally good for starting a journey.
  static const Set<int> travelNakshatras = {0, 4, 6, 7, 12, 16, 21, 22, 26};

  /// Disha Shool: direction to avoid when travelling, by weekday (0 = Sunday).
  static const List<Bi> dishaShool = [('West', 'पश्चिम'), ('East', 'पूर्व'), ('North', 'उत्तर'), ('North', 'उत्तर'), ('South', 'दक्षिण'), ('West', 'पश्चिम'), ('East', 'पूर्व')];

  /// Customary remedy before travelling against the Disha Shool.
  static const List<Bi> dishaShoolRemedy = [
    ('eat a little ghee or porridge (daliya) before leaving', 'निकलने से पहले थोड़ा घी या दलिया खाएँ'),
    ('look in a mirror or drink a little milk before leaving', 'निकलने से पहले दर्पण देखें या थोड़ा दूध पिएँ'),
    ('eat a little jaggery before leaving', 'निकलने से पहले थोड़ा गुड़ खाएँ'),
    ('eat a few sesame seeds or coriander before leaving', 'निकलने से पहले कुछ तिल या धनिया खाएँ'),
    ('eat a little curd before leaving', 'निकलने से पहले थोड़ा दही खाएँ'),
    ('eat a little curd or barley before leaving', 'निकलने से पहले थोड़ा दही या जौ खाएँ'),
    ('eat a little ginger or sesame before leaving', 'निकलने से पहले थोड़ा अदरक या तिल खाएँ'),
  ];

  /// Choghadiya names in their cyclic order, with quality (1 good, 0 neutral, -1 avoid).
  static const List<(Bi, int)> choghadiya = [
    (('Udveg', 'उद्वेग'), -1),
    (('Chal', 'चर'), 0),
    (('Labh', 'लाभ'), 1),
    (('Amrit', 'अमृत'), 1),
    (('Kaal', 'काल'), -1),
    (('Shubh', 'शुभ'), 1),
    (('Rog', 'रोग'), -1),
  ];

  /// Index into [choghadiya] of the first day / night period, by weekday (0 = Sunday).
  static const List<int> firstDayChoghadiya = [0, 3, 6, 2, 5, 1, 4];
  static const List<int> firstNightChoghadiya = [5, 1, 4, 0, 3, 6, 2];

  /// Inauspicious Panchang yogas (index into PanchangMath.yogas).
  static const Set<int> badYogas = {0, 5, 8, 9, 12, 14, 16, 18, 26};

  /// Tithi groups: Nanda, Bhadra, Jaya, Rikta, Purna.
  static const Map<String, (Bi, Bi)> tithiType = {
    'Nanda': (('Nanda (joyful)', 'नंदा (आनंद)'), ('festivities, arts and pleasant beginnings', 'उत्सव, कला और सुखद आरंभ')),
    'Bhadra': (('Bhadra (auspicious)', 'भद्रा (कल्याण)'), ('health, work, and steady progress', 'स्वास्थ्य, कार्य और स्थिर प्रगति')),
    'Jaya': (('Jaya (victorious)', 'जया (विजय)'), ('competition, courage and winning arguments', 'प्रतियोगिता, साहस और बहस जीतना')),
    'Rikta': (('Rikta (empty)', 'रिक्ता (रिक्त)'), ('clearing, cleaning and ending things — not new beginnings', 'सफ़ाई, निपटारा और समाप्ति — नई शुरुआत नहीं')),
    'Purna': (('Purna (full)', 'पूर्णा (पूर्ण)'), ('completion and all auspicious work', 'पूर्णता और सभी शुभ कार्य')),
  };

  /// Weekday-specific traditional do's and don'ts.
  static const List<(Bi, Bi)> varaDoDont = [
    (
      ('Begin the day with Surya Namaskar or Arghya; meet officials or seniors.', 'दिन की शुरुआत सूर्य नमस्कार या अर्घ्य से करें; अधिकारियों या बड़ों से मिलें।'),
      ('Avoid ego clashes with authority and heavy, salty food.', 'अधिकारियों से अहंकार के टकराव और भारी, नमकीन भोजन से बचें।'),
    ),
    (
      ('Do calm, creative and family work; drink enough water.', 'शांत, रचनात्मक और पारिवारिक काम करें; पर्याप्त पानी पिएँ।'),
      ('Avoid emotional decisions and arguments at home.', 'भावनात्मक निर्णय और घर में बहस से बचें।'),
    ),
    (
      ('Exercise, finish physical or technical work, deal with property.', 'व्यायाम करें, शारीरिक या तकनीकी काम पूरे करें, संपत्ति के काम निपटाएँ।'),
      ('Avoid lending money, quarrels, sharp tools in anger and rash driving.', 'उधार देने, झगड़े, गुस्से में धारदार औज़ार और तेज़ गाड़ी चलाने से बचें।'),
    ),
    (
      ('Sign papers, study, network, settle accounts.', 'कागज़ों पर हस्ताक्षर, पढ़ाई, संपर्क बढ़ाना, हिसाब निपटाना।'),
      ('Avoid careless words, gossip and unchecked documents.', 'लापरवाह शब्दों, चुगली और बिना जाँचे दस्तावेज़ों से बचें।'),
    ),
    (
      ('Start auspicious work, learn, invest wisely, respect teachers.', 'शुभ कार्य शुरू करें, सीखें, समझदारी से निवेश करें, गुरुओं का आदर करें।'),
      ('Avoid cutting hair or nails (tradition) and disrespecting elders.', 'बाल या नाखून काटने (परंपरा) और बड़ों के अनादर से बचें।'),
    ),
    (
      ('Spend time with your partner, shop for clothes or beauty, enjoy music and art.', 'जीवनसाथी के साथ समय बिताएँ, वस्त्र या सौंदर्य की खरीदारी करें, संगीत और कला का आनंद लें।'),
      ('Avoid over-indulgence and lavish spending.', 'अति-भोग और फ़िज़ूलखर्ची से बचें।'),
    ),
    (
      ('Work patiently, clear backlog, serve the needy, keep things orderly.', 'धैर्य से काम करें, बकाया निपटाएँ, ज़रूरतमंदों की सेवा करें, चीज़ें व्यवस्थित रखें।'),
      ('Avoid buying iron, oil or black items (tradition), and hasty new starts.', 'लोहा, तेल या काली वस्तुएँ खरीदने (परंपरा) और जल्दबाज़ी में नई शुरुआत से बचें।'),
    ),
  ];
}
