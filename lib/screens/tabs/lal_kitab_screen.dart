import 'package:flutter/material.dart';
import '../../core/ephemeris.dart';
import '../../core/lal_kitab_math.dart';
import '../../core/l10n.dart';

class LalKitabScreen extends StatefulWidget {
  final ChartData chartData;

  const LalKitabScreen({super.key, required this.chartData});

  @override
  State<LalKitabScreen> createState() => _LalKitabScreenState();
}

class _LalKitabScreenState extends State<LalKitabScreen> {
  String? _lang;
  late List<LalKitabPlanet> _planetsCache;

  /// Recomputed when the app language changes (the engine writes bilingual text).
  List<LalKitabPlanet> get planets {
    if (_lang != L10n.lang) {
      _lang = L10n.lang;
      _planetsCache = LalKitabMath.compute(widget.chartData);
    }
    return _planetsCache;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Lal Kitab', 'लाल किताब'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: planets.length,
        itemBuilder: (context, index) {
          final p = planets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Text(p.planetData.symbol, style: TextStyle(fontSize: 32, color: p.planetData.color)),
              title: Text(L10n.hi ? p.planetData.hindi : '${p.planetData.name} (${p.planetData.hindi})'),
              subtitle: Text(tr('House ${p.natalHouse} • Kalpurush Sign: ${p.rashiData.name}', 'भाव ${p.natalHouse} • कालपुरुष राशि: ${p.rashiData.hindi}')),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.isSleeping ? Colors.grey.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.isSleeping ? tr('Sleeping', 'सोया हुआ') : tr('Awake', 'जाग्रत'),
                  style: TextStyle(color: p.isSleeping ? Colors.grey : Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.healing, color: Theme.of(context).colorScheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${tr('Remedy', 'उपाय')}: ${p.remedy}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
