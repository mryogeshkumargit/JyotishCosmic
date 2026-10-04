import 'package:flutter/material.dart';
import '../../core/ashtakavarga_math.dart';
import '../../core/ephemeris.dart';
import '../../core/l10n.dart';
import '../../core/plain/interpret.dart';
import '../../core/vedic_math.dart';
import '../../widgets/analysis_widgets.dart';

String _n(String p) => p == 'lagna' ? tr('Lagna', 'लग्न') : L10n.planet(p);

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
      appBar: AppBar(title: Text(tr('Ashtakavarga', 'अष्टकवर्ग'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          SimpleMeaningCard(Interpret.ashtakavarga(av)),
          SectionCard(
            title: '${tr('Sarvāṣṭakavarga', 'सर्वाष्टकवर्ग')} (${av.sarvaTotal})',
            subtitle: tr('Bindus per house from the Lagna. 28 is average; more bindus favour the matters of the house and transits through it.',
                'लग्न से हर भाव के बिंदु। 28 औसत है; अधिक बिंदु भाव के विषयों और उसमें गोचर के लिए शुभ हैं।'),
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
                            Text(tr('H$h', 'भा$h'), style: const TextStyle(fontSize: 11)),
                            Text('$v', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                            Text(L10n.signShort((lagna + h - 1) % 12), style: const TextStyle(fontSize: 10)),
                          ]),
                        ),
                      );
                    }(),
                ],
              ),
            ],
          ),
          SectionCard(
            title: tr('Bhinnāṣṭakavarga', 'भिन्नाष्टकवर्ग'),
            subtitle: tr('Each planet\'s own chart. Totals are fixed by the classical tables (Sun 48 … Saturn 39).', 'हर ग्रह का अपना चक्र। कुल बिंदु शास्त्रीय तालिकाओं से निश्चित हैं (सूर्य 48 … शनि 39)।'),
            children: [
              CompactTable(
                header: ['', for (int s = 0; s < 12; s++) L10n.signShort(s, 2), 'Σ'],
                minColumnWidth: 30,
                rows: [
                  for (final q in AshtakavargaMath.planets)
                    [L10n.planetAbbr(q), for (final v in av.bhinna[q]!.bindus) '$v', '${av.bhinna[q]!.total}'],
                  ['SAV', for (final v in av.sarva) '$v', '${av.sarvaTotal}'],
                ],
              ),
            ],
          ),
          SectionCard(
            title: tr('Contributions and Shodhya Pinda', 'योगदान और शोध्य पिंड'),
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _planet,
                decoration: InputDecoration(labelText: tr('Planet', 'ग्रह')),
                items: [for (final q in AshtakavargaMath.planets) DropdownMenuItem(value: q, child: Text(_n(q)))],
                onChanged: (v) => setState(() => _planet = v!),
              ),
              const SizedBox(height: 8),
              for (final e in b.contributions.entries)
                BulletLine(tr('${_n(e.key)} gives ${e.value.length}: ', '${_n(e.key)} देता है ${e.value.length}: ') + e.value.map((s) => L10n.signShort(s)).join(', ')),
              const SizedBox(height: 8),
              CompactTable(
                header: ['', for (int s = 0; s < 12; s++) L10n.signShort(s, 2)],
                minColumnWidth: 30,
                rows: [
                  [tr('Bindus', 'बिंदु'), for (final v in b.bindus) '$v'],
                  [tr('Trikona', 'त्रिकोण'), for (final v in p.afterTrikona) '$v'],
                  [tr('Ekādhip.', 'एकाधिपत्य'), for (final v in p.afterEkadhipatya) '$v'],
                ],
              ),
              const SizedBox(height: 6),
              KeyValueRow(tr('Rāśi Pinda', 'राशि पिंड'), '${p.rashiPinda}'),
              KeyValueRow(tr('Graha Pinda', 'ग्रह पिंड'), '${p.grahaPinda}'),
              KeyValueRow(tr('Shodhya Pinda', 'शोध्य पिंड'), '${p.total}'),
            ],
          ),
          if (_transit != null)
            SectionCard(
              title: tr('Transit support now', 'अभी गोचर का सहारा'),
              subtitle: tr('A transiting planet does better in a sign where its own Ashtakavarga has 4 or more bindus.', 'गोचर करता ग्रह उस राशि में अच्छा फल देता है जहाँ उसके अपने अष्टकवर्ग में 4 या अधिक बिंदु हों।'),
              children: [
                for (final q in AshtakavargaMath.planets)
                  () {
                    final r = VedicMath.rashiIndex(_transit!.planetLongitudes[q]!);
                    final bindus = av.bindusFor(q, r);
                    return BulletLine('${tr('${_n(q)} in ${L10n.sign(r)}', '${_n(q)} ${L10n.sign(r)} में')}: ${AshtakavargaMath.transitSupport(av, q, r)}',
                        mark: bindus >= 4 ? '✓' : '✗', color: bindus >= 4 ? Colors.green : scheme.error);
                  }(),
              ],
            ),
        ],
      ),
    );
  }
}
