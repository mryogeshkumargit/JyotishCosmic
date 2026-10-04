import '../l10n.dart';

/// Plain-language meaning of each yoga the engine detects (English, Hindi).
///
/// Summarised from the results given in BPHS (yoga chapters), Phaladeepika
/// ch. 6-7, Saravali, Brihat Jataka ch. 12-13 and 15, rewritten in everyday
/// words. Classical results describe tendencies; their strength depends on
/// the planets involved and on the Daśā that activates them.
class YogaMeanings {
  static const Map<String, (String, String)> byName = {
    // Pancha Mahapurusha
    'Ruchaka': (
      'Mars is strong in a key house. You tend to be brave, energetic and able to take charge. You can do well in technical work, engineering, sports, the police or army, or property. Keep anger and haste in check.',
      'मंगल एक मुख्य भाव में बलवान है। आप साहसी, ऊर्जावान और नेतृत्व करने वाले होते हैं। तकनीकी काम, इंजीनियरिंग, खेल, पुलिस-सेना या भूमि-संपत्ति में अच्छा कर सकते हैं। क्रोध और जल्दबाज़ी पर नियंत्रण रखें।',
    ),
    'Bhadra': (
      'Mercury is strong in a key house. You have a sharp mind and good speech, and can succeed in business, writing, accounts, teaching, analysis or communication.',
      'बुध एक मुख्य भाव में बलवान है। आपकी बुद्धि तेज़ और वाणी अच्छी है; व्यापार, लेखन, हिसाब-किताब, अध्यापन, विश्लेषण या संचार में सफलता मिल सकती है।',
    ),
    'Hamsa': (
      'Jupiter is strong in a key house. You tend to be wise, ethical and respected. Teaching, advising, law, finance or spiritual work suit you, and good fortune and children are favoured.',
      'गुरु एक मुख्य भाव में बलवान है। आप समझदार, नैतिक और सम्मानित होते हैं। अध्यापन, सलाह, कानून, वित्त या आध्यात्मिक कार्य आपके अनुकूल हैं; भाग्य और संतान सुख अच्छा रहता है।',
    ),
    'Malavya': (
      'Venus is strong in a key house. You tend to be attractive and artistic, enjoy comforts and vehicles, and have good prospects in marriage. Arts, beauty, design, hospitality or luxury fields suit you.',
      'शुक्र एक मुख्य भाव में बलवान है। आप आकर्षक और कलात्मक होते हैं, सुख-सुविधाओं और वाहनों का आनंद लेते हैं और वैवाहिक सुख अच्छा रहता है। कला, सौंदर्य, डिज़ाइन, होटल या विलासिता के क्षेत्र अनुकूल हैं।',
    ),
    'Sasa': (
      'Saturn is strong in a key house. You are disciplined and hard-working, with the ability to organise and lead many people. Progress comes slowly but lasts; administration, politics, industry or public service suit you.',
      'शनि एक मुख्य भाव में बलवान है। आप अनुशासित और परिश्रमी हैं और बहुत लोगों को संगठित कर सकते हैं। प्रगति धीरे-धीरे पर स्थायी होती है; प्रशासन, राजनीति, उद्योग या जनसेवा अनुकूल है।',
    ),
    // Moon yogas
    'Sunapha': (
      'Planets in the 2nd from your Moon: you earn and save through your own effort, think clearly and build a good name.',
      'चन्द्र से दूसरे भाव में ग्रह: आप अपने प्रयास से कमाते और बचाते हैं, स्पष्ट सोचते हैं और अच्छा नाम बनाते हैं।',
    ),
    'Anapha': (
      'Planets in the 12th from your Moon: you are independent, well-mannered and generous, and like to spend on comfort and good causes.',
      'चन्द्र से बारहवें भाव में ग्रह: आप स्वतंत्र, शालीन और उदार हैं; सुख-सुविधा और अच्छे कार्यों पर खर्च करना पसंद करते हैं।',
    ),
    'Durudhara': (
      'Planets on both sides of your Moon: you are well supported by people and resources, enjoy comforts and are generous.',
      'चन्द्र के दोनों ओर ग्रह: आपको लोगों और साधनों का अच्छा सहारा मिलता है, सुख-सुविधा रहती है और आप उदार होते हैं।',
    ),
    'Kemadruma': (
      'No planet next to your Moon. At times you may feel alone or unsupported and your mood may swing, so building your own support system helps. It is often cancelled by other planets; check the cancellations shown.',
      'चन्द्र के आस-पास कोई ग्रह नहीं। कभी-कभी अकेलापन या सहारे की कमी महसूस हो सकती है और मन अस्थिर रह सकता है; अपना सहारा खुद बनाना मदद करता है। यह अक्सर अन्य ग्रहों से भंग हो जाता है; दिखाए गए भंग देखें।',
    ),
    'Gaja Kesari': (
      'Jupiter in a key position from the Moon: good judgement, reputation and the ability to overcome problems. It is a common yoga, so its effect depends on Jupiter and the Moon being strong.',
      'चन्द्र से केन्द्र में गुरु: अच्छी समझ, प्रतिष्ठा और समस्याओं से उबरने की क्षमता। यह सामान्य योग है, इसलिए इसका असर गुरु और चन्द्र के बल पर निर्भर करता है।',
    ),
    'Adhi': (
      'Benefic planets in the 6th, 7th and 8th from the Moon: leadership, comfort, victory over opponents and a respected position.',
      'चन्द्र से 6, 7, 8वें भाव में शुभ ग्रह: नेतृत्व, सुख, विरोधियों पर विजय और सम्मानित पद।',
    ),
    'Lagnadhi': (
      'Benefic planets in the 6th, 7th and 8th from the Lagna: a respected, learned and happy life.',
      'लग्न से 6, 7, 8वें भाव में शुभ ग्रह: सम्मानित, विद्वान और सुखी जीवन।',
    ),
    'Chandra-Mangala': (
      'Moon with Mars: enterprising and good at earning, often through business, property or bold ventures. Feelings can be intense, so stay patient.',
      'चन्द्र-मंगल साथ: उद्यमी और कमाने में कुशल, अक्सर व्यापार, संपत्ति या साहसिक कार्यों से। भावनाएँ तीव्र हो सकती हैं, धैर्य रखें।',
    ),
    'Sakata': (
      'Jupiter in the 6th, 8th or 12th from the Moon: fortune moves up and down like a cart wheel, with phases of gain and setback. Steady effort and savings smooth it out.',
      'चन्द्र से 6, 8 या 12वें भाव में गुरु: भाग्य गाड़ी के पहिये की तरह ऊपर-नीचे होता है; लाभ और रुकावट के दौर आते हैं। निरंतर प्रयास और बचत से संतुलन आता है।',
    ),
    'Vasumati': (
      'Benefic planets in growth houses: your wealth tends to keep growing over the years.',
      'उपचय (वृद्धि) भावों में शुभ ग्रह: समय के साथ आपका धन लगातार बढ़ता है।',
    ),
    // Sun yogas
    'Vesi': (
      'A planet in the 2nd from the Sun: balanced, truthful and steadily progressing, with a good name.',
      'सूर्य से दूसरे भाव में ग्रह: संतुलित, सत्यवादी, धीरे-धीरे प्रगति करने वाले और अच्छी प्रतिष्ठा।',
    ),
    'Vasi': (
      'A planet in the 12th from the Sun: skilled, charitable and liked by people in authority.',
      'सूर्य से बारहवें भाव में ग्रह: कुशल, दानशील और अधिकारियों के प्रिय।',
    ),
    'Ubhayachari': (
      'Planets on both sides of the Sun: confident, well-balanced and respected, a leader in your circle.',
      'सूर्य के दोनों ओर ग्रह: आत्मविश्वासी, संतुलित और सम्मानित; अपने क्षेत्र में अग्रणी।',
    ),
    'Budha-Aditya': (
      'Sun with Mercury: a bright mind, good communication and administrative skill. Mercury is always near the Sun, so this is common; it works best when Mercury is not combust.',
      'सूर्य-बुध साथ: तेज़ बुद्धि, अच्छा संवाद और प्रशासनिक कौशल। बुध हमेशा सूर्य के पास रहता है इसलिए यह सामान्य है; बुध अस्त न हो तो अधिक फल देता है।',
    ),
    // Raja and special
    'Yogakaraka': (
      'One planet rules both a house of action and a house of luck. It is especially helpful for status and success, most of all during its Daśā.',
      'एक ही ग्रह कर्म (केन्द्र) और भाग्य (त्रिकोण) दोनों भावों का स्वामी है। यह पद और सफलता के लिए विशेष शुभ है, ख़ासकर अपनी दशा में।',
    ),
    'Kendra-Trikona Raja': (
      'The lords of action and luck are connected: a rise in status, success and recognition, most clearly during the Daśās of these planets.',
      'कर्म और भाग्य के स्वामी आपस में जुड़े हैं: पद, सफलता और पहचान में वृद्धि, ख़ासकर इन ग्रहों की दशा में।',
    ),
    'Dharma-Karmadhipati': (
      'The lords of the 9th (luck) and 10th (career) are connected: luck supports your work, giving honest success and a good name in your field.',
      '9वें (भाग्य) और 10वें (कर्म) के स्वामी जुड़े हैं: भाग्य आपके काम का साथ देता है, ईमानदार सफलता और अपने क्षेत्र में नाम मिलता है।',
    ),
    'Parvata': (
      'Benefics hold the key houses: prosperity, fame, generosity and leadership in your community.',
      'केन्द्र भावों में शुभ ग्रह: समृद्धि, यश, उदारता और समाज में नेतृत्व।',
    ),
    'Kahala': (
      'Bold and energetic, sometimes stubborn; you can gain authority and lead a group.',
      'साहसी और ऊर्जावान, कभी-कभी ज़िद्दी; अधिकार प्राप्त कर समूह का नेतृत्व कर सकते हैं।',
    ),
    'Sankha': ('Kind, learned and blessed with a good family, wealth and a long life.', 'दयालु, विद्वान, अच्छे परिवार, धन और दीर्घायु से युक्त।'),
    'Bheri': ('Wealth, a happy family life, long life and respect.', 'धन, सुखी पारिवारिक जीवन, दीर्घायु और सम्मान।'),
    'Chamara': ('Honour from those in power, learning, eloquence and fame.', 'सत्ता से सम्मान, विद्वत्ता, वाक्पटुता और प्रसिद्धि।'),
    'Lakshmi': ('Wealth, prosperity, grace and generosity: the blessing of Goddess Lakshmi.', 'धन, समृद्धि, शोभा और उदारता: माँ लक्ष्मी की कृपा।'),
    'Saraswati': ('Learning, knowledge, arts and fine speech; success in education and creative fields.', 'विद्या, ज्ञान, कला और मधुर वाणी; शिक्षा और रचनात्मक क्षेत्रों में सफलता।'),
    'Chatussagara': ('Fame that spreads far, wealth and a good reputation.', 'दूर-दूर तक फैली प्रसिद्धि, धन और अच्छी प्रतिष्ठा।'),
    'Kurma': ('Fame, kindness, contentment and leadership.', 'यश, दया, संतोष और नेतृत्व।'),
    'Matsya': ('Compassionate, wise and well known, with a religious or spiritual leaning.', 'करुणामय, बुद्धिमान और प्रसिद्ध; धार्मिक या आध्यात्मिक रुझान।'),
    'Devendra': ('High status, comforts, popularity and power.', 'ऊँचा पद, सुख-सुविधा, लोकप्रियता और शक्ति।'),
    'Indra': ('Courage, fame and leadership, sometimes a brilliant rise.', 'साहस, यश और नेतृत्व; कभी-कभी तेज़ उन्नति।'),
    'Mahabhagya': (
      'A birth time that classical texts call highly fortunate: good luck, wealth, a long life and leadership.',
      'शास्त्रों के अनुसार अत्यंत भाग्यशाली जन्म समय: अच्छा भाग्य, धन, दीर्घायु और नेतृत्व।',
    ),
    'Amala': ('Only benefics in the 10th: a clean reputation, ethical conduct and work that people appreciate.', '10वें भाव में केवल शुभ ग्रह: बेदाग़ प्रतिष्ठा, नैतिक आचरण और सराहा जाने वाला काम।'),
    // Wealth
    'Dhana': (
      'The lords of wealth houses are connected: a good capacity to earn and build wealth, especially during the Daśās of these planets.',
      'धन भावों के स्वामी जुड़े हैं: कमाने और धन जोड़ने की अच्छी क्षमता, ख़ासकर इन ग्रहों की दशा में।',
    ),
    'Daridra': (
      'Wealth lords sit in difficult houses, so money can slip away. Careful budgeting and saving help. This is a tendency, not a certainty of poverty.',
      'धन के स्वामी कठिन भावों में हैं, इसलिए पैसा हाथ से निकल सकता है। सोच-समझकर खर्च और बचत से मदद मिलती है। यह प्रवृत्ति है, गरीबी निश्चित नहीं।',
    ),
    // Viparita
    'Harsha': ('The lord of the 6th is in a difficult house: you overcome enemies and illness, and problems can turn into gains.', 'छठे भाव का स्वामी कठिन भाव में: आप शत्रुओं और रोगों पर विजय पाते हैं, समस्याएँ लाभ में बदल सकती हैं।'),
    'Sarala': ('The lord of the 8th is in a difficult house: fearless, long-lived and successful after hardship.', 'आठवें भाव का स्वामी कठिन भाव में: निडर, दीर्घायु और कठिनाई के बाद सफल।'),
    'Vimala': ('The lord of the 12th is in a difficult house: careful with money, independent and of good conduct.', 'बारहवें भाव का स्वामी कठिन भाव में: पैसे में सावधान, स्वतंत्र और अच्छे आचरण वाले।'),
    // Parivartana
    'Maha Parivartana': (
      'Two lords of good houses exchange signs: these areas of life support each other strongly and bring prosperity.',
      'दो शुभ भावों के स्वामी राशि बदले हुए हैं: जीवन के ये क्षेत्र एक-दूसरे को मज़बूती से सहारा देते हैं और समृद्धि लाते हैं।',
    ),
    'Khala Parivartana': (
      'An exchange involving the 3rd house: gains through effort, with ups and downs; temperament can be changeable.',
      'तीसरे भाव से जुड़ा परिवर्तन: प्रयास से लाभ, पर उतार-चढ़ाव; स्वभाव कभी-कभी बदलता रहता है।',
    ),
    'Dainya Parivartana': (
      'An exchange involving a difficult house (6, 8 or 12): struggles, opponents or losses connected with these areas, which call for extra effort.',
      'कठिन भाव (6, 8 या 12) से जुड़ा परिवर्तन: इन क्षेत्रों में संघर्ष, विरोध या हानि; अतिरिक्त प्रयास की ज़रूरत।',
    ),
    'Parivartana': (
      'Two planets exchange signs, so their areas of life become closely linked.',
      'दो ग्रहों ने राशि बदली है, इसलिए उनके जीवन क्षेत्र आपस में गहराई से जुड़ जाते हैं।',
    ),
    'Neecha Bhanga Raja': (
      'A weak (debilitated) planet has its weakness cancelled: early struggles in its area later turn into strength and a rise.',
      'नीच ग्रह का नीचत्व भंग हुआ: उसके क्षेत्र में शुरुआती संघर्ष बाद में शक्ति और उन्नति में बदलते हैं।',
    ),
    'Neecha Bhanga': (
      'A weak (debilitated) planet is partly repaired by other factors, so its results improve with time and effort.',
      'नीच ग्रह को अन्य कारकों से सहारा मिला है, इसलिए समय और प्रयास से उसके फल सुधरते हैं।',
    ),
    'Debilitated': (
      'A planet is debilitated (in its weakest sign) and no classical cancellation applies. The things it rules need conscious effort and support; results come slowly rather than being denied.',
      'एक ग्रह नीच (अपनी सबसे कमज़ोर राशि) में है और कोई शास्त्रीय भंग लागू नहीं होता। उस ग्रह से जुड़े विषयों में सचेत प्रयास और सहारे की ज़रूरत है; फल रुकते नहीं, धीरे मिलते हैं।',
    ),
    // Kartari
    'Subha Kartari': ('This house is flanked by benefic planets: it is protected and helped.', 'यह भाव शुभ ग्रहों से घिरा है: इसे सुरक्षा और सहायता मिलती है।'),
    'Papa Kartari': ('This house is flanked by malefic planets: there is pressure and obstacles in this area of life, so patience is needed.', 'यह भाव पाप ग्रहों से घिरा है: इस क्षेत्र में दबाव और रुकावटें आती हैं; धैर्य की ज़रूरत है।'),
    // Nabhasa
    'Rajju': ('Most planets in movable signs: you love travel and change, may be restless and may live away from your birthplace.', 'अधिकतर ग्रह चर राशियों में: यात्रा और बदलाव पसंद, मन चंचल, जन्मस्थान से दूर रह सकते हैं।'),
    'Musala': ('Most planets in fixed signs: steady, determined and proud, with stable wealth.', 'अधिकतर ग्रह स्थिर राशियों में: स्थिर, दृढ़ निश्चयी, स्वाभिमानी और स्थिर धन।'),
    'Nala': ('Most planets in dual signs: flexible and skilled, with many interests.', 'अधिकतर ग्रह द्विस्वभाव राशियों में: लचीले, कुशल और अनेक रुचियों वाले।'),
    'Mala': ('Benefics in three key houses: comforts, happiness and a pleasant life.', 'तीन केन्द्रों में शुभ ग्रह: सुख-सुविधा, प्रसन्नता और सुखद जीवन।'),
    'Sarpa': ('Malefics in three key houses: hardships and dependence on others at times; patience brings relief.', 'तीन केन्द्रों में पाप ग्रह: कभी-कभी कठिनाइयाँ और दूसरों पर निर्भरता; धैर्य से राहत।'),
    'Gada': ('Planets in two neighbouring key houses: wealth through effort and a religious nature.', 'दो पास-पास के केन्द्रों में ग्रह: प्रयास से धन और धार्मिक स्वभाव।'),
    'Shakata': ('Planets in the 1st and 7th: ups and downs in life, success through steady hard work.', 'पहले और सातवें भाव में ग्रह: जीवन में उतार-चढ़ाव, निरंतर परिश्रम से सफलता।'),
    'Vihaga': ('Planets in the 4th and 10th: travel and a role as a go-between or messenger.', 'चौथे और दसवें भाव में ग्रह: यात्राएँ और मध्यस्थ या संदेशवाहक की भूमिका।'),
    'Shringataka': ('Planets in the 1st, 5th and 9th: happy, fortunate and well liked.', 'पहले, पाँचवें और नौवें भाव में ग्रह: सुखी, भाग्यशाली और लोकप्रिय।'),
    'Hala': ('Planets in trines other than the Lagna: hard-working, connected with land or farming.', 'लग्न के अलावा त्रिकोणों में ग्रह: परिश्रमी, भूमि या खेती से जुड़े।'),
    'Vajra': ('Happiness in early and late life, with more effort in the middle years.', 'जीवन के आरंभ और अंत में सुख, बीच के वर्षों में अधिक परिश्रम।'),
    'Yava': ('More happiness and success in the middle years of life.', 'जीवन के मध्य वर्षों में अधिक सुख और सफलता।'),
    'Kamala': ('Famous, virtuous and long-lived.', 'प्रसिद्ध, गुणवान और दीर्घायु।'),
    'Vapi': ('Good at saving; comfortable and secure.', 'बचत में कुशल; सुखी और सुरक्षित।'),
    'Yupa': ('Generous and religious, drawn to rituals and good works.', 'उदार और धार्मिक, पूजा-पाठ और शुभ कार्यों में रुचि।'),
    'Ishu': ('Sharp and forceful; suited to competitive or protective roles.', 'तेज़ और प्रबल; प्रतिस्पर्धी या रक्षक भूमिकाओं के अनुकूल।'),
    'Shakti': ('A fighter by nature, though wealth may come slowly.', 'स्वभाव से संघर्षशील, हालांकि धन धीरे आ सकता है।'),
    'Danda': ('Periods of distance from dear ones; self-reliance helps.', 'प्रियजनों से दूरी के दौर; आत्मनिर्भरता मदद करती है।'),
    'Nauka': ('Fame and wealth, sometimes linked with water or travel, but fortune can be changeable.', 'यश और धन, कभी-कभी जल या यात्रा से जुड़ा, पर भाग्य बदलता रहता है।'),
    'Kuta': ('Classical texts warn of harshness or deceit around you; be careful in dealings.', 'शास्त्र कठोरता या छल की चेतावनी देते हैं; लेन-देन में सावधानी रखें।'),
    'Chhatra': ('Helpful and kind to others, with a happier later life.', 'दूसरों के लिए सहायक और दयालु; जीवन का उत्तरार्ध अधिक सुखी।'),
    'Chapa': ('Brave and fond of travel, with happiness later in life.', 'साहसी और यात्रा प्रिय; बाद के जीवन में सुख।'),
    'Ardha Chandra': ('Leadership ability, a pleasing appearance and wealth.', 'नेतृत्व क्षमता, आकर्षक व्यक्तित्व और धन।'),
    'Chakra': ('Respected like a ruler in your circle.', 'अपने क्षेत्र में राजा जैसा सम्मान।'),
    'Samudra': ('Wealth like the ocean, comforts and generosity.', 'सागर जैसा धन, सुख-सुविधा और उदारता।'),
    'Veena': ('Fond of music and the arts, many friends and leadership.', 'संगीत और कला प्रेमी, अनेक मित्र और नेतृत्व।'),
    'Dama': ('Generous and helpful, wealthy and well known.', 'उदार और सहायक, धनवान और प्रसिद्ध।'),
    'Pasha': ('Skilled at earning, with many people depending on you; circumstances can feel binding.', 'कमाने में कुशल, अनेक लोग आप पर निर्भर; परिस्थितियाँ बंधन जैसी लग सकती हैं।'),
    'Kedara': ('Useful to others, truthful and prosperous, often through land.', 'दूसरों के लिए उपयोगी, सत्यवादी और समृद्ध, अक्सर भूमि से।'),
    'Shula': ('Sharp and brave, but prone to quarrels; choose battles wisely.', 'तेज़ और साहसी, पर झगड़ों की प्रवृत्ति; सोच-समझकर टकराव चुनें।'),
    'Yuga': ('Unconventional views and an unusual life path; wealth may be modest.', 'अपरंपरागत विचार और अलग जीवन मार्ग; धन सामान्य रह सकता है।'),
    'Gola': ('Classical texts describe hardship; effort and learning are the remedy.', 'शास्त्र कठिनाइयों का वर्णन करते हैं; परिश्रम और शिक्षा इसका उपाय हैं।'),
    // Renunciation and Arishta
    'Pravrajya': (
      'Several planets gather with a strong one: a pull towards spirituality, research or a detached way of life. Today this usually shows as deep inner interests, not literally renouncing the world.',
      'कई ग्रह एक बलवान ग्रह के साथ: आध्यात्मिकता, शोध या विरक्त जीवन की ओर खिंचाव। आज यह अक्सर गहरी आंतरिक रुचि के रूप में दिखता है, संसार त्यागने के रूप में नहीं।',
    ),
    'Chandra Arishta': (
      'A classical warning about the Moon, traditionally read for health in early childhood. For adults it mainly points to emotional sensitivity.',
      'चन्द्र से जुड़ी शास्त्रीय चेतावनी, जो परंपरागत रूप से बचपन के स्वास्थ्य के लिए देखी जाती है। वयस्कों के लिए यह मुख्यतः भावनात्मक संवेदनशीलता दर्शाती है।',
    ),
    'Lagna Arishta': (
      'A classical warning about the Lagna lord, traditionally read for health in early life. Strong benefics usually reduce it.',
      'लग्नेश से जुड़ी शास्त्रीय चेतावनी, जो परंपरागत रूप से प्रारंभिक जीवन के स्वास्थ्य के लिए देखी जाती है। बलवान शुभ ग्रह इसे प्रायः कम करते हैं।',
    ),
    'Arishta-bhanga': (
      'Protective factors that cancel the classical warnings: health and longevity are supported.',
      'शास्त्रीय चेतावनियों को भंग करने वाले रक्षक योग: स्वास्थ्य और आयु को सहारा।',
    ),
  };

  /// Family-level explanation used when a yoga has no specific entry.
  static const Map<String, (String, String)> families = {
    'Pancha Mahapurusha': ('Yogas of the five great persons: one planet is strong in a key house and shapes your character.', 'पंच महापुरुष योग: एक ग्रह मुख्य भाव में बलवान होकर आपके चरित्र को आकार देता है।'),
    'Raja Yogas': ('Combinations for status, power and success.', 'पद, शक्ति और सफलता देने वाले योग।'),
    'Dhana Yogas': ('Combinations for earning and wealth.', 'कमाई और धन देने वाले योग।'),
    'Moon (Chandra) Yogas': ('Combinations around the Moon, describing mind, support and resources.', 'चन्द्र के आस-पास के योग, जो मन, सहारे और साधनों का वर्णन करते हैं।'),
    'Sun (Surya) Yogas': ('Combinations around the Sun, describing confidence and reputation.', 'सूर्य के आस-पास के योग, जो आत्मविश्वास और प्रतिष्ठा का वर्णन करते हैं।'),
    'Special Yogas': ('Named classical combinations with specific results.', 'विशेष फल देने वाले नामित शास्त्रीय योग।'),
    'Viparita Raja Yogas': ('Lords of difficult houses in difficult houses: problems turn into strength.', 'कठिन भावों के स्वामी कठिन भावों में: समस्याएँ शक्ति में बदलती हैं।'),
    'Parivartana Yogas': ('Planets exchanging signs, linking two areas of life.', 'राशि परिवर्तन: जीवन के दो क्षेत्र आपस में जुड़ते हैं।'),
    'Neecha Bhanga': ('Cancellation of a planet\'s weakness.', 'ग्रह की कमज़ोरी (नीचत्व) का भंग।'),
    'Kartari Yogas': ('A house or planet hemmed in on both sides.', 'दोनों ओर से घिरा भाव या ग्रह।'),
    'Daridra Yogas': ('Combinations that make wealth harder to keep.', 'धन रोकना कठिन करने वाले योग।'),
    'Pravrajya (Renunciation)': ('Combinations for detachment and spiritual life.', 'वैराग्य और आध्यात्मिक जीवन के योग।'),
    'Arishta & Arishta-bhanga': ('Classical health warnings and their cancellations.', 'स्वास्थ्य संबंधी शास्त्रीय चेतावनियाँ और उनका भंग।'),
    'Nabhasa · Ashraya': ('Pattern yogas from the type of signs the planets occupy; they describe your general nature for life.', 'ग्रहों की राशि के प्रकार से बने नभस योग; ये जीवन भर के सामान्य स्वभाव को बताते हैं।'),
    'Nabhasa · Dala': ('Pattern yogas from benefics or malefics in the key houses; they describe your general nature for life.', 'केन्द्रों में शुभ या पाप ग्रहों से बने नभस योग; ये जीवन भर के सामान्य स्वभाव को बताते हैं।'),
    'Nabhasa · Akriti': ('Pattern yogas from the shape the planets form in the chart; they describe your general nature for life.', 'कुंडली में ग्रहों की आकृति से बने नभस योग; ये जीवन भर के सामान्य स्वभाव को बताते हैं।'),
    'Nabhasa · Sankhya': ('Pattern yogas from the number of signs occupied; they describe your general nature for life.', 'भरी हुई राशियों की संख्या से बने नभस योग; ये जीवन भर के सामान्य स्वभाव को बताते हैं।'),
  };

  /// Hindi names of the yoga families.
  static const Map<String, String> familyHindi = {
    'Pancha Mahapurusha': 'पंच महापुरुष योग',
    'Raja Yogas': 'राज योग',
    'Dhana Yogas': 'धन योग',
    'Moon (Chandra) Yogas': 'चन्द्र योग',
    'Sun (Surya) Yogas': 'सूर्य योग',
    'Special Yogas': 'विशेष योग',
    'Viparita Raja Yogas': 'विपरीत राज योग',
    'Parivartana Yogas': 'परिवर्तन योग',
    'Neecha Bhanga': 'नीचभंग',
    'Kartari Yogas': 'कर्तरी योग',
    'Nabhasa · Ashraya': 'नभस · आश्रय',
    'Nabhasa · Dala': 'नभस · दल',
    'Nabhasa · Akriti': 'नभस · आकृति',
    'Nabhasa · Sankhya': 'नभस · संख्या',
    'Daridra Yogas': 'दरिद्र योग',
    'Pravrajya (Renunciation)': 'प्रव्रज्या (वैराग्य) योग',
    'Arishta & Arishta-bhanga': 'अरिष्ट और अरिष्ट-भंग',
  };

  static String family(String f) => L10n.hi ? (familyHindi[f] ?? f) : f;

  /// Lookup key: the name without " Yoga" and without parentheses.
  static String keyOf(String name) {
    var k = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').replaceAll(' Yoga', '').trim();
    if (k.startsWith('Yogakaraka')) k = 'Yogakaraka';
    if (k.startsWith('Dhana')) k = 'Dhana';
    if (k.startsWith('Daridra')) k = 'Daridra';
    if (k.startsWith('Pravrajya')) k = 'Pravrajya';
    if (k.startsWith('Papa Kartari')) k = 'Papa Kartari';
    if (k.startsWith('Subha Kartari')) k = 'Subha Kartari';
    if (k.startsWith('Debilitated')) k = 'Debilitated';
    return k;
  }

  /// Plain meaning of a yoga; falls back to its family description.
  static String meaning(String name, String family) {
    final m = byName[keyOf(name)];
    if (m != null) return tr(m.$1, m.$2);
    final f = families[family];
    return f == null ? '' : tr(f.$1, f.$2);
  }
}
