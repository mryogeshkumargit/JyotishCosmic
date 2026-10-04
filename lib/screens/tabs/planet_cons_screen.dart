import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/avasthas_math.dart';
import '../../core/l10n.dart';
import '../../widgets/analysis_widgets.dart';

class PlanetConsScreen extends StatefulWidget {
  final ChartData chartData;

  const PlanetConsScreen({super.key, required this.chartData});

  @override
  State<PlanetConsScreen> createState() => _PlanetConsScreenState();
}

class _PlanetConsScreenState extends State<PlanetConsScreen> {
  String? _lang;
  late List<AvasthaData> _avasthasCache;

  /// Recomputed when the app language changes (the engine writes bilingual text).
  List<AvasthaData> get avasthas {
    if (_lang != L10n.lang) {
      _lang = L10n.lang;
      _avasthasCache = AvasthasMath.compute(widget.chartData);
    }
    return _avasthasCache;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Avasthas', 'अवस्थाएँ'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: avasthas.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return SimpleMeaningCard([
              tr('Avasthas are the "states" of a planet. The age state (Bālādi) shows how much of its result a planet can give: Yuva (adult) gives full results, Kumāra (youth) about half, Bāla (infant) a quarter, Vṛddha (old) very little and Mṛta (dead) almost none.',
                  'अवस्था ग्रह की "दशा-स्थिति" है। बालादि (आयु) अवस्था बताती है कि ग्रह अपना कितना फल दे सकता है: युवा पूरा फल, कुमार लगभग आधा, बाल चौथाई, वृद्ध बहुत कम और मृत लगभग कुछ नहीं।'),
              tr('The waking state (Jāgradādi) works the same way: Jāgrat (awake) gives full results, Svapna (dreaming) moderate and Suṣupti (asleep) little.',
                  'जाग्रदादि अवस्था भी इसी तरह है: जाग्रत पूरा फल देता है, स्वप्न मध्यम और सुषुप्त कम।'),
            ]);
          }
          final p = avasthas[i - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Text(p.planetData.symbol, style: TextStyle(fontSize: 32, color: p.planetData.color)),
              title: Text(L10n.hi ? p.planetData.hindi : '${p.planetData.name} (${p.planetData.hindi})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('${tr('Age State', 'आयु अवस्था')}: ${p.baladi}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  Text('${tr('Awake State', 'जाग्रदादि अवस्था')}: ${p.jagradadi}', style: const TextStyle(color: Colors.grey)),
                  Text('${tr('Degree', 'अंश')}: ${p.degreeInRashi.toStringAsFixed(2)}°', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
