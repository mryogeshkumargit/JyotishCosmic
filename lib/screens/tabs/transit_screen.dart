import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/transit_math.dart';
import '../../core/vedic_math.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/kundli_chart.dart';

class TransitScreen extends ConsumerStatefulWidget {
  final ChartData chartData;
  final int? profileId;

  const TransitScreen({super.key, required this.chartData, this.profileId});

  @override
  ConsumerState<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends ConsumerState<TransitScreen> {
  late final List<TransitResult> transits;
  bool _viewFromMoon = true; // Default to Chandra Lagna

  @override
  void initState() {
    super.initState();
    transits = TransitMath.compute(widget.chartData);
  }

  int get _baseRashi => _viewFromMoon
      ? VedicMath.rashiIndex(widget.chartData.planetLongitudes['moon'] ?? 0)
      : widget.chartData.lagnaRashi;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transits (Gochar)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transits.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildTransitChart();

          final t = transits[index - 1];
          final Color effectColor = t.effectType == 'good'
              ? Colors.green
              : (t.effectType == 'difficult' ? Colors.redAccent : Colors.orangeAccent);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Text(t.planetData.symbol, style: TextStyle(fontSize: 32, color: t.planetData.color)),
              title: Text('${t.planetData.name} in ${t.rashiData.name} ${VedicMath.formatDegree(t.sid)}${t.retrograde ? ' ℞' : ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('House ${t.houseFromLagna} from Lagna • House ${t.houseFromMoon} from Moon',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (t.aspectOnNatal != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${t.aspectOnNatal} natal ${t.planetData.name}',
                          style: const TextStyle(fontSize: 12, color: Colors.amber)),
                    ),
                  const SizedBox(height: 8),
                  Text(t.effect, style: TextStyle(color: effectColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransitChart() {
    final Map<String, double> longs = {for (final t in transits) t.planet: t.sid};
    final Map<String, double> speeds = {for (final t in transits) t.planet: t.retrograde ? -1.0 : 1.0};
    final houses = buildHouseLabels(longs, _baseRashi, speeds: speeds);

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: true, label: Text('From Moon'), icon: Icon(Icons.nightlight_round)),
                ButtonSegment<bool>(value: false, label: Text('From Lagna'), icon: Icon(Icons.person)),
              ],
              selected: {_viewFromMoon},
              onSelectionChanged: (s) => setState(() => _viewFromMoon = s.first),
            ),
            const SizedBox(height: 16),
            Text('Transit Chart (${_viewFromMoon ? "Chandra Lagna" : "Natal Ascendant"})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: KundliChart(
                housePlanets: houses,
                ascendantSign: _baseRashi + 1,
                onHouseTapped: (house) => _handleHouseTapped(house, houses),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleHouseTapped(int houseNum, Map<int, List<String>> houses) {
    final planets = transits.where((t) => VedicMath.houseOf(t.transitRashi, _baseRashi) == houseNum).toList();
    final String baseName = _viewFromMoon ? 'the natal Moon sign (Chandra Lagna)' : 'the natal Ascendant';
    final sign = VedicMath.rashis[(_baseRashi + houseNum - 1) % 12].name;
    final today = DateTime.now();

    final prompt = 'Today is ${today.year}-${today.month}-${today.day}. Analyze house $houseNum ($sign) counted from '
        '$baseName in the current Gochar (transit) chart.\n'
        'Planets currently transiting this house: '
        '${planets.isEmpty ? 'none' : planets.map((t) => '${t.planetData.name} ${VedicMath.formatDegree(t.sid)}${t.retrograde ? ' (retrograde)' : ''}').join(', ')}.\n\n'
        'All current transits: ${transits.map((t) => '${t.planetData.name} in ${t.rashiData.name}').join(', ')}.\n\n'
        'Natal chart:\n${ChartSummary.describe(widget.chartData)}';

    showAiSheet(context, ref, title: 'Transit House $houseNum Analysis', prompt: prompt, profileId: widget.profileId);
  }
}
