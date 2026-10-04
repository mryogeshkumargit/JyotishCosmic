import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/remedies_math.dart';
import '../../core/l10n.dart';
import '../../widgets/analysis_widgets.dart';

class RemediesScreen extends StatefulWidget {
  final ChartData chartData;

  const RemediesScreen({super.key, required this.chartData});

  @override
  State<RemediesScreen> createState() => _RemediesScreenState();
}

class _RemediesScreenState extends State<RemediesScreen> {
  String? _lang;
  late List<RemedyResult> _remediesCache;

  /// Recomputed when the app language changes (the engine writes bilingual text).
  List<RemedyResult> get _remedies {
    if (_lang != L10n.lang) {
      _lang = L10n.lang;
      _remediesCache = RemediesMath.compute(widget.chartData);
    }
    return _remediesCache;
  }


  @override
  Widget build(BuildContext context) {
    final gemstones = _remedies.where((r) => r.type == 'gemstone').toList();
    final charities = _remedies.where((r) => r.type == 'charity').toList();
    final doshas = _remedies.where((r) => r.type == 'dosha').toList();

    return Scaffold(
      appBar: AppBar(title: Text(tr('Remedies', 'उपाय'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SimpleMeaningCard([
            tr('Remedies are traditional practices meant to strengthen helpful planets and calm difficult ones. Gemstones are suggested only for the lords of your 1st, 5th and 9th houses (your most helpful planets); mantras and charity are suggested for the planets that rule difficult houses. Always consult an experienced astrologer before wearing a gemstone.',
                'उपाय पारंपरिक साधन हैं जो सहायक ग्रहों को बल देने और कठिन ग्रहों को शांत करने के लिए हैं। रत्न केवल आपके 1, 5 और 9वें भाव के स्वामियों (सबसे सहायक ग्रह) के लिए सुझाए गए हैं; मंत्र और दान कठिन भावों के स्वामियों के लिए। रत्न पहनने से पहले किसी अनुभवी ज्योतिषी से सलाह अवश्य लें।'),
          ]),
          Text(tr('Recommended Gemstones (Benefics)', 'अनुशंसित रत्न (शुभ ग्रह)'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          Text(tr('These gemstones strengthen your functional benefic planets (Lords of 1st, 5th, and 9th houses).', 'ये रत्न आपके कार्यात्मक शुभ ग्रहों (1, 5 और 9वें भाव के स्वामी) को बल देते हैं।'), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ...gemstones.map((g) => _buildRemedyCard(g, Icons.diamond, Colors.blueAccent)),
          
          const SizedBox(height: 24),
          Text(tr('Pacification (Mantras & Charity)', 'शांति (मंत्र और दान)'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          Text(tr('These practices pacify functional malefic planets to reduce their negative impacts.', 'ये साधन कार्यात्मक पाप ग्रहों को शांत करके उनके नकारात्मक प्रभाव कम करते हैं।'), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ...charities.map((c) => _buildRemedyCard(c, Icons.clean_hands, Colors.orangeAccent)),

          if (doshas.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(tr('Dosha Specific Remedies', 'दोष के विशेष उपाय'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 8),
            Text(tr('Specific remedies prescribed for the Doshas present in your chart.', 'आपकी कुंडली में उपस्थित दोषों के लिए विशेष उपाय।'), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...doshas.map((d) => _buildRemedyCard(d, Icons.warning_amber_rounded, Colors.redAccent)),
          ]
        ],
      ),
    );
  }

  Widget _buildRemedyCard(RemedyResult remedy, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(remedy.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(remedy.description, style: const TextStyle(height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
