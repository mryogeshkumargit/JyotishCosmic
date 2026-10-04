import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/barshphal_math.dart';
import '../../widgets/kundli_chart.dart';
import '../../core/l10n.dart';

class BarshphalScreen extends StatefulWidget {
  final ChartData chartData;

  const BarshphalScreen({super.key, required this.chartData});

  @override
  State<BarshphalScreen> createState() => _BarshphalScreenState();
}

class _BarshphalScreenState extends State<BarshphalScreen> {
  late int _age;
  late BarshphalData data;

  @override
  void initState() {
    super.initState();
    _age = BarshphalMath.currentAge(widget.chartData);
    data = BarshphalMath.compute(widget.chartData, _age);
  }

  void _setAge(int age) {
    if (age < 0) return;
    setState(() {
      _age = age;
      data = BarshphalMath.compute(widget.chartData, _age);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Varshaphal', 'वर्षफल'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(tr('Annual chart for completed age', 'पूर्ण आयु का वार्षिक चार्ट'), style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: _age > 0 ? () => _setAge(_age - 1) : null),
                        Text('${data.age}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber)),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _setAge(_age + 1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(tr('Varsha Pravesh (sidereal solar return, birth place time)', 'वर्ष प्रवेश (निरयन सूर्य वापसी, जन्म स्थान का समय)'), textAlign: TextAlign.center),
                    Text(data.solarReturnDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailCard(
              tr('Muntha', 'मुंथा'),
              L10n.hi ? data.munthaRashiData.hindi : '${data.munthaRashiData.name} (${data.munthaRashiData.hindi})',
              '${tr('Lord', 'स्वामी')}: ${L10n.hi ? data.munthaLord.hindi : data.munthaLord.name}',
              data.munthaLord.color,
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              tr('Varsha Lagna (Year Ascendant)', 'वर्ष लग्न'),
              L10n.hi ? data.yearLagnaData.hindi : '${data.yearLagnaData.name} (${data.yearLagnaData.hindi})',
              '${tr('Lagna lord', 'लग्नेश')}: ${L10n.hi ? data.yearLagnaLord.hindi : data.yearLagnaLord.name}',
              data.yearLagnaLord.color,
            ),
            const SizedBox(height: 24),
            Text(tr('Annual Chart (Varshfal)', 'वार्षिक कुंडली (वर्षफल)'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _buildVarshfalChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildVarshfalChart() {
    final chart = data.varshaphalChart;
    return KundliChart(
      housePlanets: chartLabels(chart),
      ascendantSign: chart.lagnaRashi + 1,
      showLegend: true,
      onHouseTapped: (house) {},
    );
  }

  Widget _buildDetailCard(String title, String value, String subtitle, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
