import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../widgets/ai_sheet.dart';
import '../../core/l10n.dart';

class PredictionsScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;
  final String? name;

  const PredictionsScreen({super.key, required this.chartData, this.profileId, this.name});

  static List<(String, IconData, String, String)> get _categories => [
    (
      tr('Comprehensive Life Prediction', 'संपूर्ण जीवन भविष्यफल'),
      Icons.public,
      tr('A complete overview of your life path, strengths, and major themes based on your Kundali.', 'आपकी कुंडली के आधार पर जीवन मार्ग, शक्तियों और मुख्य विषयों का पूरा अवलोकन।'),
      'Provide a comprehensive life prediction',
    ),
    (
      tr('Career & Wealth Prediction', 'करियर और धन भविष्यफल'),
      Icons.work,
      tr('Insights into your profession, financial success, and potential career paths.', 'आपके व्यवसाय, आर्थिक सफलता और संभावित करियर मार्गों की जानकारी।'),
      'Provide a detailed prediction focusing entirely on career and wealth',
    ),
    (
      tr('Love & Marriage Prediction', 'प्रेम और विवाह भविष्यफल'),
      Icons.favorite,
      tr('Understand relationship dynamics, marriage timing, and partner characteristics.', 'संबंधों की प्रकृति, विवाह का समय और जीवनसाथी के गुण समझें।'),
      'Provide a detailed prediction focusing entirely on love and marriage, including timing from the dashas',
    ),
    (
      tr('Health & Vitality Prediction', 'स्वास्थ्य और ऊर्जा भविष्यफल'),
      Icons.health_and_safety,
      tr('Astrological insights into your overall well-being, energy levels, and health predispositions.', 'आपकी समग्र भलाई, ऊर्जा स्तर और स्वास्थ्य प्रवृत्तियों की ज्योतिषीय जानकारी।'),
      'Provide a detailed prediction focusing entirely on health and vitality',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ChartSummary.describe(chartData, name: name);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Predictions', 'भविष्यफल'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final (title, icon, description, instruction) = _categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => showAiSheet(
                context,
                ref,
                title: title,
                profileId: profileId,
                prompt: '$instruction based on this Vedic birth chart:\n\n$summary',
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, size: 32, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(description, style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
