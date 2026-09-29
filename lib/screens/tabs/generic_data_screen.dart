import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../services/ai_service.dart';
import '../../providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenericDataScreen extends ConsumerWidget {
  final ChartData chartData;
  final String featureTitle;
  final DateTime birthDate;
  final TimeOfDay birthTime;
  final double lat;
  final double lon;

  const GenericDataScreen({
    super.key, 
    required this.chartData, 
    required this.featureTitle,
    required this.birthDate,
    required this.birthTime,
    required this.lat,
    required this.lon,
  });

  void _showAIInterpretation(BuildContext context, WidgetRef ref) {
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
                  Text('$featureTitle Analysis', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<String>(
                  future: AiService.interpret(
                    ref.read(settingsProvider), 
                    'Perform a detailed $featureTitle analysis for a person born on '
                    '${birthDate.toIso8601String().split('T')[0]} at ${birthTime.hour}:${birthTime.minute} '
                    'at coordinates ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}. '
                    'Focus specifically on $featureTitle according to Vedic Astrology.'
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }
                    return SingleChildScrollView(
                      child: Text(
                        snapshot.data ?? 'No response',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.5),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(featureTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                '$featureTitle is currently under construction.\nCheck back in the next update!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        icon: const Icon(Icons.auto_awesome),
        label: Text('Generate $featureTitle'),
        onPressed: () => _showAIInterpretation(context, ref),
      ),
    );
  }
}
