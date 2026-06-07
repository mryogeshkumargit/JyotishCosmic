import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../core/ephemeris.dart';
import '../core/database.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isLoading = false;
  String? _resultText;

  void _generateFullReport(Profile profile) async {
    setState(() {
      _isLoading = true;
      _resultText = null;
    });

    try {
      final chartData = Ephemeris.computeChart(
        profile.dob.year, profile.dob.month, profile.dob.day,
        profile.dob.hour.toDouble(), profile.dob.minute.toDouble(),
        profile.lat, profile.lon, profile.timezone,
      );

      final prompt = "Generate a comprehensive, premium Vedic Astrology Life Report for ${profile.name}. "
          "Ascendant: ${chartData.ascendantSidereal} degrees. "
          "Planetary Longitudes: ${chartData.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}. "
          "Include sections on: 1. Personality & Life Path, 2. Career & Finance, 3. Love & Relationships, 4. Health & Vitality, 5. Spiritual Journey & Karmic Lessons. "
          "Format it as a highly professional, beautiful Markdown document suitable for a premium PDF export.";

      final settings = ref.read(settingsProvider);
      final response = await AiService.interpret(settings, prompt);

      setState(() {
        _resultText = response;
      });
    } catch (e) {
      setState(() {
        _resultText = "Error generating report: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Report'),
        actions: [
          if (_resultText != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download PDF',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export coming soon!')));
              },
            )
        ],
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(child: Text('Create a profile to generate a report.', style: TextStyle(color: AppTheme.starWhite)));
          }

          final activeProfile = profiles.first;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              if (_resultText == null && !_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 80, color: AppTheme.saffronAccent),
                      const SizedBox(height: 24),
                      Text(
                        'Generate a 360° Comprehensive Vedic Life Report for ${activeProfile.name}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.starWhite, fontSize: 18),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _generateFullReport(activeProfile),
                        icon: const Icon(Icons.auto_awesome, color: AppTheme.cosmicBlack),
                        label: const Text('Generate Report', style: TextStyle(color: AppTheme.cosmicBlack, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.saffronAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      )
                    ],
                  ),
                ),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.saffronAccent))),
              if (_resultText != null)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryMystic.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.saffronAccent.withOpacity(0.5)),
                      ),
                      child: Text(_resultText!, style: const TextStyle(color: AppTheme.starWhite, fontSize: 16, height: 1.5)),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
