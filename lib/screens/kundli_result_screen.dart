import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/kundli_chart.dart';
import '../core/ephemeris.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../providers/profile_provider.dart';
import 'tabs/graha_screen.dart';
import 'tabs/dasha_screen.dart';
import 'tabs/panchang_screen.dart';
import 'tabs/yogas_screen.dart';
import 'tabs/doshas_screen.dart';
import 'tabs/generic_data_screen.dart';
import 'tabs/varga_screen.dart';
import 'tabs/transit_screen.dart';
import 'tabs/nakshatra_screen.dart';
import 'tabs/kp_system_screen.dart';
import 'tabs/lal_kitab_screen.dart';
import 'tabs/barshphal_screen.dart';
import 'tabs/planet_cons_screen.dart';
import 'tabs/interpretation_screen.dart';
import 'tabs/ai_chat_screen.dart';
import 'tabs/remedies_screen.dart';
import 'tabs/predictions_screen.dart';

class KundliResultScreen extends ConsumerStatefulWidget {
  final String name;
  final DateTime date;
  final TimeOfDay time;
  final double lat;
  final double lon;
  final double timezone;
  final int? profileId;

  const KundliResultScreen({
    super.key,
    required this.name,
    required this.date,
    required this.time,
    required this.lat,
    required this.lon,
    required this.timezone,
    this.profileId,
  });

  @override
  ConsumerState<KundliResultScreen> createState() => _KundliResultScreenState();
}

class _KundliResultScreenState extends ConsumerState<KundliResultScreen> {
  late ChartData _chartData;

  final List<Map<String, dynamic>> _actionButtons = [
    {'title': 'Planet', 'icon': Icons.public},
    {'title': 'Dasha', 'icon': Icons.timeline},
    {'title': 'Predictions', 'icon': Icons.auto_awesome},
    {'title': 'KP System', 'icon': Icons.calculate},
    {'title': 'Shodashvarga', 'icon': Icons.grid_view},
    {'title': 'Lal Kitab', 'icon': Icons.menu_book},
    {'title': 'Barshphal', 'icon': Icons.calendar_today},
    {'title': 'Transit', 'icon': Icons.sync},
    {'title': 'Nakshtra', 'icon': Icons.wb_twilight},
    {'title': 'Planet Cons.', 'icon': Icons.balance},
    {'title': 'Daily Panchang', 'icon': Icons.today},
    {'title': 'Dosha', 'icon': Icons.warning_amber},
    {'title': 'Yogas', 'icon': Icons.psychology},
    {'title': 'Remedies', 'icon': Icons.healing},
    {'title': 'Interpretation', 'icon': Icons.lightbulb_outline},
    {'title': 'Ask AI', 'icon': Icons.chat_bubble_outline},
  ];

  @override
  void initState() {
    super.initState();
    _computeChart();
  }

  void _computeChart() {
    _chartData = Ephemeris.computeChart(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      widget.time.hour.toDouble(),
      widget.time.minute.toDouble(),
      widget.lat,
      widget.lon,
      widget.timezone,
    );
  }

  void _showAIModal(String title, String prompt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                          const SizedBox(height: 20),
                          if (widget.profileId != null)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () async {
                                try {
                                  await ref.read(profileNotifierProvider.notifier).saveInterpretation(widget.profileId!, text);
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _handleHouseTapped(int houseNum) {
    final planets = _chartData.housePlanets[houseNum] ?? [];
    final prompt = 'Analyze House $houseNum of this Vedic birth chart.\n'
        'Planets present: ${planets.isEmpty ? 'Empty house' : planets.join(', ')}.\n'
        'Provide a detailed Vedic astrological interpretation.';
    _showAIModal('House $houseNum Analysis', prompt);
  }

  void _handleActionTapped(String featureTitle) {
    if (featureTitle == 'Planet') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => GrahaScreen(chartData: _chartData)));
    } else if (featureTitle == 'Dasha') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DashaScreen(chartData: _chartData, birthDate: widget.date)));
    } else if (featureTitle == 'Daily Panchang') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PanchangScreen(chartData: _chartData, lat: widget.lat, lon: widget.lon)));
    } else if (featureTitle == 'Dosha' || featureTitle == 'Doshas') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DoshasScreen(chartData: _chartData)));
    } else if (featureTitle == 'Yogas') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => YogasScreen(chartData: _chartData)));
    } else if (featureTitle == 'Shodashvarga') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VargaScreen(chartData: _chartData, profileId: widget.profileId)));
    } else if (featureTitle == 'Transit') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TransitScreen(chartData: _chartData, timezone: widget.timezone, profileId: widget.profileId)));
    } else if (featureTitle == 'Nakshtra') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NakshatraScreen(chartData: _chartData)));
    } else if (featureTitle == 'KP System') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => KPSystemScreen(chartData: _chartData, lat: widget.lat, lon: widget.lon)));
    } else if (featureTitle == 'Lal Kitab') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LalKitabScreen(chartData: _chartData)));
    } else if (featureTitle == 'Predictions') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PredictionsScreen(chartData: _chartData, profileId: widget.profileId)));
    } else if (featureTitle == 'Barshphal') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BarshphalScreen(chartData: _chartData, birthYear: widget.date.year, lat: widget.lat, lon: widget.lon)));
    } else if (featureTitle == 'Remedies') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RemediesScreen(chartData: _chartData)));
    } else if (featureTitle == 'Planet Cons.') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlanetConsScreen(chartData: _chartData)));
    } else if (featureTitle == 'Interpretation') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => InterpretationScreen(profileId: widget.profileId)));
    } else if (featureTitle == 'Ask AI') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AiChatScreen(chartData: _chartData, profileId: widget.profileId)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => GenericDataScreen(
        chartData: _chartData,
        featureTitle: featureTitle,
        birthDate: widget.date,
        birthTime: widget.time,
        lat: widget.lat,
        lon: widget.lon,
      )));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.name}\'s Horoscope'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () async {
            final pdfService = PdfService();
            await pdfService.generateAndShareAstrologicalReport(_chartData, widget.name, widget.date);
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(
              '${widget.date.toIso8601String().split('T')[0]} • ${widget.time.format(context)}',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap on any house for AI Interpretation',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.8), fontSize: 14),
            ),
            KundliChart(
              housePlanets: _chartData.housePlanets,
              ascendantSign: (_chartData.ascendantSidereal / 30).floor() + 1,
              onHouseTapped: _handleHouseTapped,
            ),
            const SizedBox(height: 24),
            
            // Action Buttons Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _actionButtons.map((btn) => _buildActionButton(btn['title'] as String, btn['icon'] as IconData)).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleActionTapped(title),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
