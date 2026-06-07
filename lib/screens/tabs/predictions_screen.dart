import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ephemeris.dart';
import '../../providers/settings_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/ai_service.dart';

class PredictionsScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;

  const PredictionsScreen({super.key, required this.chartData, this.profileId});

  void _showAIModal(BuildContext context, WidgetRef ref, String title, String prompt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<String>(
                  future: AiService.interpret(ref.read(settingsProvider), prompt),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }
                    
                    final text = snapshot.data ?? 'No response';
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.5),
                          ),
                          if (profileId != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () async {
                                try {
                                  await ref.read(profileNotifierProvider.notifier).saveInterpretation(profileId!, text);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interpretation Saved')));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
                                  }
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: const Text("Save Interpretation to Profile"),
                            )
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      {
        'title': 'Comprehensive Life Prediction',
        'icon': Icons.public,
        'description': 'A complete overview of your life path, strengths, and major themes based on your Kundali.',
        'prompt': 'Provide a comprehensive life prediction based on the following Vedic chart data:\n'
            'Ascendant: ${chartData.ascendantSidereal}\n'
            'Planets: ${chartData.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n'
      },
      {
        'title': 'Career & Wealth Prediction',
        'icon': Icons.work,
        'description': 'Insights into your profession, financial success, and potential career paths.',
        'prompt': 'Provide a detailed prediction focusing entirely on Career and Wealth based on the following Vedic chart data:\n'
            'Ascendant: ${chartData.ascendantSidereal}\n'
            'Planets: ${chartData.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n'
      },
      {
        'title': 'Love & Marriage Prediction',
        'icon': Icons.favorite,
        'description': 'Understand relationship dynamics, marriage timing, and partner characteristics.',
        'prompt': 'Provide a detailed prediction focusing entirely on Love and Marriage based on the following Vedic chart data:\n'
            'Ascendant: ${chartData.ascendantSidereal}\n'
            'Planets: ${chartData.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n'
      },
      {
        'title': 'Health & Vitality Prediction',
        'icon': Icons.health_and_safety,
        'description': 'Astrological insights into your overall well-being, energy levels, and health predispositions.',
        'prompt': 'Provide a detailed prediction focusing entirely on Health and Vitality based on the following Vedic chart data:\n'
            'Ascendant: ${chartData.ascendantSidereal}\n'
            'Planets: ${chartData.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => _showAIModal(context, ref, cat['title'] as String, cat['prompt'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cat['icon'] as IconData, size: 32, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat['title'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            cat['description'] as String,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
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
