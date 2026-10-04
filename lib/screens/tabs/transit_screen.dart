import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/transit_math.dart';
import '../../core/vedic_math.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/kundli_chart.dart';
import '../../core/l10n.dart';
import '../../core/plain/meanings.dart';
import '../../widgets/analysis_widgets.dart';

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
      appBar: AppBar(title: Text(tr('Transits (Gochar)', 'गोचर'))),
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
              title: Text('${tr('${t.planetData.name} in ${t.rashiData.name}', '${L10n.planet(t.planet)} ${L10n.sign(t.transitRashi)} में')} ${VedicMath.formatDegree(t.sid)}${t.retrograde ? ' ℞' : ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(tr('House ${t.houseFromLagna} from Lagna • House ${t.houseFromMoon} from Moon', 'लग्न से भाव ${t.houseFromLagna} • चन्द्र से भाव ${t.houseFromMoon}'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (t.aspectOnNatal != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(tr('${t.aspectOnNatal} natal ${t.planetData.name}', 'जन्म के ${L10n.planet(t.planet)} से ${t.aspectOnNatal}'),
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
              segments: [
                ButtonSegment<bool>(value: true, label: Text(tr('From Moon', 'चन्द्र से')), icon: const Icon(Icons.nightlight_round)),
                ButtonSegment<bool>(value: false, label: Text(tr('From Lagna', 'लग्न से')), icon: const Icon(Icons.person)),
              ],
              selected: {_viewFromMoon},
              onSelectionChanged: (s) => setState(() => _viewFromMoon = s.first),
            ),
            const SizedBox(height: 16),
            Text(tr('Transit Chart (${_viewFromMoon ? "Chandra Lagna" : "Natal Ascendant"})', 'गोचर कुंडली (${_viewFromMoon ? "चन्द्र लग्न" : "जन्म लग्न"})'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            KundliChart(
              housePlanets: houses,
              ascendantSign: _baseRashi + 1,
              showLegend: true,
              onHouseTapped: (house) => _handleHouseTapped(house, houses),
            ),
            const SizedBox(height: 12),
            SimpleMeaningCard(_plain()),
          ],
        ),
      ),
    );
  }

  /// Plain summary: how many transits help, and where the slow planets are.
  List<String> _plain() {
    final good = transits.where((t) => t.effectType == 'good').map((t) => L10n.planet(t.planet)).toList();
    final hard = transits.where((t) => t.effectType == 'difficult').map((t) => L10n.planet(t.planet)).toList();
    String slow(String p) {
      final t = transits.firstWhere((x) => x.planet == p);
      return tr('${L10n.planet(p)} is passing your ${L10n.ordinal(t.houseFromMoon)} house from the Moon (${Meanings.house(t.houseFromMoon)}): ${t.effect}.',
          '${L10n.planet(p)} चन्द्र से ${t.houseFromMoon}वें भाव (${Meanings.house(t.houseFromMoon)}) से गुज़र रहा है: ${t.effect}।');
    }

    return [
      tr('Transits (Gochar) are where the planets are today, counted from your Moon sign. Slow planets (Saturn, Jupiter, Rahu, Ketu) shape the long phases of life; fast ones (Moon, Sun, Mercury, Venus, Mars) colour days and weeks.',
          'गोचर का अर्थ है आज ग्रह कहाँ हैं, आपकी चन्द्र राशि से गिनकर। धीमे ग्रह (शनि, गुरु, राहु, केतु) जीवन के लंबे दौर तय करते हैं; तेज़ ग्रह (चन्द्र, सूर्य, बुध, शुक्र, मंगल) दिनों और हफ़्तों को रंगते हैं।'),
      if (good.isNotEmpty) tr('Helpful now: ${L10n.join(good)}.', 'अभी सहायक: ${L10n.join(good)}।'),
      if (hard.isNotEmpty) tr('Testing now: ${L10n.join(hard)}.', 'अभी परीक्षा लेने वाले: ${L10n.join(hard)}।'),
      slow('saturn'),
      slow('jupiter'),
    ];
  }

  void _handleHouseTapped(int houseNum, Map<int, List<ChartLabel>> houses) {
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

    showAiSheet(context, ref, title: tr('Transit House $houseNum Analysis', 'गोचर भाव $houseNum विश्लेषण'), prompt: prompt, profileId: widget.profileId);
  }
}
