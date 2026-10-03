import 'package:flutter/material.dart';
import '../../core/ashtakavarga_math.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../widgets/analysis_widgets.dart';

String _n(String p) => p == 'lagna' ? 'Lagna' : (VedicMath.planets[p]?.name ?? p);

/// Ashtakavarga (BPHS): Bhinnashtakavarga, Sarvashtakavarga, Shodhya Pinda and
/// current transit support.
class AshtakavargaScreen extends StatefulWidget {
  final ChartData chartData;
  const AshtakavargaScreen({super.key, required this.chartData});

  @override
  State<AshtakavargaScreen> createState() => _AshtakavargaScreenState();
}

class _AshtakavargaScreenState extends State<AshtakavargaScreen> {
  late final AshtakavargaResult av = AshtakavargaMath.compute(widget.chartData);
  ChartData? _transit;
  String _planet = 'sun';

  @override
  void initState() {
    super.initState();
    try {
      final c = widget.chartData;
      _transit = Ephemeris.computeChartForJd(Ephemeris.nowJd(), c.lat, c.lon, utcOffset: c.utcOffset);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lagna = widget.chartData.lagnaRashi;
    final b = av.bhinna[_planet]!;
    final p = av.pinda[_planet]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Ashtakavarga')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          SectionCard(
            title: 'Sarvāṣṭakavarga (${av.sarvaTotal})',
            subtitle: 'Bindus per house from the Lagna. 28 is average; more bindus favour the matters of the house and transits through it.',
            children: [
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.25,
                children: [
                  for (int h = 1; h <= 12; h++)
                    () {
                      final v = av.sarvaInHouse(h);
                      final color = v >= 28 ? Colors.green : (v < 25 ? scheme.error : Colors.orange);
                      return Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          border: Border.all(color: color.withValues(alpha: 0.6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(children: [
                            Text('H$h', style: const TextStyle(fontSize: 11)),
                            Text('$v', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                            Text(VedicMath.rashis[(lagna + h - 1) % 12].name.substring(0, 3), style: const TextStyle(fontSize: 10)),
                          ]),
                        ),
                      );
                    }(),
                ],
              ),
            ],
          ),
          SectionCard(
            title: 'Bhinnāṣṭakavarga',
            subtitle: 'Each planet\'s own chart. Totals are fixed by the classical tables (Sun 48 … Saturn 39).',
            children: [
              CompactTable(
                header: ['', for (int s = 0; s < 12; s++) VedicMath.rashis[s].name.substring(0, 2), 'Σ'],
                minColumnWidth: 30,
                rows: [
                  for (final q in AshtakavargaMath.planets)
                    [_n(q).substring(0, 2), for (final v in av.bhinna[q]!.bindus) '$v', '${av.bhinna[q]!.total}'],
                  ['SAV', for (final v in av.sarva) '$v', '${av.sarvaTotal}'],
                ],
              ),
            ],
          ),
          SectionCard(
            title: 'Contributions and Shodhya Pinda',
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _planet,
                decoration: const InputDecoration(labelText: 'Planet'),
                items: [for (final q in AshtakavargaMath.planets) DropdownMenuItem(value: q, child: Text(_n(q)))],
                onChanged: (v) => setState(() => _planet = v!),
              ),
              const SizedBox(height: 8),
              for (final e in b.contributions.entries)
                BulletLine('${_n(e.key)} gives ${e.value.length}: ${e.value.map((s) => VedicMath.rashis[s].name.substring(0, 3)).join(', ')}'),
              const SizedBox(height: 8),
              CompactTable(
                header: ['', for (int s = 0; s < 12; s++) VedicMath.rashis[s].name.substring(0, 2)],
                minColumnWidth: 30,
                rows: [
                  ['Bindus', for (final v in b.bindus) '$v'],
                  ['Trikona', for (final v in p.afterTrikona) '$v'],
                  ['Ekādhip.', for (final v in p.afterEkadhipatya) '$v'],
                ],
              ),
              const SizedBox(height: 6),
              KeyValueRow('Rāśi Pinda', '${p.rashiPinda}'),
              KeyValueRow('Graha Pinda', '${p.grahaPinda}'),
              KeyValueRow('Shodhya Pinda', '${p.total}'),
            ],
          ),
          if (_transit != null)
            SectionCard(
              title: 'Transit support now',
              subtitle: 'A transiting planet does better in a sign where its own Ashtakavarga has 4 or more bindus.',
              children: [
                for (final q in AshtakavargaMath.planets)
                  () {
                    final r = VedicMath.rashiIndex(_transit!.planetLongitudes[q]!);
                    final bindus = av.bindusFor(q, r);
                    return BulletLine('${_n(q)} in ${VedicMath.rashis[r].name}: ${AshtakavargaMath.transitSupport(av, q, r)}',
                        mark: bindus >= 4 ? '✓' : '✗', color: bindus >= 4 ? Colors.green : scheme.error);
                  }(),
              ],
            ),
        ],
      ),
    );
  }
}
