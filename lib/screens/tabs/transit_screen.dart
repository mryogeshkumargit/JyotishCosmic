import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ephemeris.dart';
import '../../core/transit_math.dart';
import '../../core/vedic_math.dart';
import '../../widgets/kundli_chart.dart';
import '../../services/ai_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/profile_provider.dart';

class TransitScreen extends ConsumerStatefulWidget {
  final ChartData chartData;
  final double timezone;
  final int? profileId;

  const TransitScreen({super.key, required this.chartData, required this.timezone, this.profileId});

  @override
  ConsumerState<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends ConsumerState<TransitScreen> {
  late List<TransitResult> transits;
  bool _viewFromMoon = true; // Default to Chandra Lagna

  @override
  void initState() {
    super.initState();
    transits = TransitMath.compute(widget.chartData, widget.timezone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Transits (Gochar)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transits.length + 1, // +1 for the chart
        itemBuilder: (context, index) {
          if (index == 0) return _buildTransitChart();
          
          final t = transits[index - 1];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Text(t.planetData.symbol, style: TextStyle(fontSize: 32, color: t.planetData.color)),
              title: Text('${t.planetData.name} in ${t.rashiData.name}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('House ${t.houseFromLagna} from Lagna • House ${t.houseFromMoon} from Moon', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (t.aspectOnNatal != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${t.aspectOnNatal} Natal ${t.planetData.name}', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                    ),
                  const SizedBox(height: 8),
                  Text(t.effect, style: TextStyle(color: t.effectType == 'good' ? Colors.green : (t.effectType == 'difficult' ? Colors.redAccent : Colors.orangeAccent))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransitChart() {
    int lagnaSign = (widget.chartData.ascendantSidereal / 30).floor() + 1;
    int moonSign = 1;
    if (widget.chartData.planetLongitudes.containsKey('moon')) {
      moonSign = (widget.chartData.planetLongitudes['moon']! / 30).floor() + 1;
    }

    int baseSign = _viewFromMoon ? moonSign : lagnaSign;

    Map<int, List<String>> houses = {for (var i = 1; i <= 12; i++) i: []};

    final Map<String, String> pNames = {
      'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me',
      'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa',
      'rahu': 'Ra', 'ketu': 'Ke'
    };

    for (var t in transits) {
      if (!pNames.containsKey(t.planet)) continue;
      int pSign = t.transitRashi + 1;
      int houseNum = (pSign - baseSign + 12) % 12 + 1;
      houses[houseNum]!.add(pNames[t.planet]!);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('From Moon'),
                  icon: Icon(Icons.nightlight_round),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('From Lagna'),
                  icon: Icon(Icons.person),
                ),
              ],
              selected: {_viewFromMoon},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _viewFromMoon = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Transit Chart (${_viewFromMoon ? "Chandra Lagna" : "Natal Ascendant"})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: KundliChart(
                housePlanets: houses,
                ascendantSign: baseSign,
                onHouseTapped: (house) => _handleHouseTapped(house, houses, baseSign),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleHouseTapped(int houseNum, Map<int, List<String>> houses, int baseSign) {
    final planets = houses[houseNum] ?? [];
    String baseName = _viewFromMoon ? "Chandra Lagna (Moon)" : "Natal Ascendant";
    
    final prompt = 'Analyze House $houseNum of this Vedic Gochar (Transit) chart relative to the $baseName.\n'
        'The Transit Ascendant/Base for this chart is Sign $baseSign.\n'
        'Planets currently transiting this house: ${planets.isEmpty ? 'Empty house' : planets.join(', ')}.\n'
        'Provide a detailed Vedic astrological interpretation of these transits and their effects.';
    
    _showAIModal('Transit House $houseNum Analysis', prompt);
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
                          if (widget.profileId != null) ...[
                            const SizedBox(height: 16),
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
}
