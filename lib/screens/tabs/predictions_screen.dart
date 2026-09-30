import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../widgets/ai_sheet.dart';

class PredictionsScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;
  final String? name;

  const PredictionsScreen({super.key, required this.chartData, this.profileId, this.name});

  static const List<(String, IconData, String, String)> _categories = [
    (
      'Comprehensive Life Prediction',
      Icons.public,
      'A complete overview of your life path, strengths, and major themes based on your Kundali.',
      'Provide a comprehensive life prediction',
    ),
    (
      'Career & Wealth Prediction',
      Icons.work,
      'Insights into your profession, financial success, and potential career paths.',
      'Provide a detailed prediction focusing entirely on career and wealth',
    ),
    (
      'Love & Marriage Prediction',
      Icons.favorite,
      'Understand relationship dynamics, marriage timing, and partner characteristics.',
      'Provide a detailed prediction focusing entirely on love and marriage, including timing from the dashas',
    ),
    (
      'Health & Vitality Prediction',
      Icons.health_and_safety,
      'Astrological insights into your overall well-being, energy levels, and health predispositions.',
      'Provide a detailed prediction focusing entirely on health and vitality',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ChartSummary.describe(chartData, name: name);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Predictions')),
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
