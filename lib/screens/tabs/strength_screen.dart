import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/calc_config.dart';
import '../../core/ephemeris.dart';
import '../../core/precision_math.dart';
import '../../core/shadbala_math.dart';
import '../../core/vedic_math.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/analysis_widgets.dart';

String _n(String p) => VedicMath.planets[p]?.name ?? p;

/// Volume 4 strength and precision layers: Shadbala, Bhava Bala, exact
/// degrees, motion, combustion, planetary war, aspects and quality control.
class StrengthScreen extends ConsumerWidget {
  final ChartData chartData;
  const StrengthScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(settingsProvider.select((s) => s.calc));
    final sb = ShadbalaMath.compute(chartData, cfg: cfg);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Strength'),
          bottom: const TabBar(tabs: [Tab(text: 'Shadbala'), Tab(text: 'Bhāva Bala'), Tab(text: 'Precision')]),
        ),
        body: TabBarView(children: [
          _ShadbalaTab(result: sb),
          _BhavaTab(result: sb),
          _PrecisionTab(chart: chartData, cfg: cfg),
        ]),
      ),
    );
  }
}

class _ShadbalaTab extends StatelessWidget {
  final ShadbalaResult result;
  const _ShadbalaTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ranked = result.ranked;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        SectionCard(
          title: 'Six-fold strength',
          subtitle: 'Virupas (60 = 1 rupa). The bar shows the total against the BPHS minimum (marker at 1.0×). Minimums are reference values, not a ranking of planets.',
          children: [
            for (final s in ranked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text('${s.rupas.toStringAsFixed(2)} rupas · ${s.ratio.toStringAsFixed(2)}×', style: const TextStyle(fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  RatioBar(s.ratio),
                ]),
              ),
          ],
        ),
        SectionCard(
          title: 'Components',
          children: [
            CompactTable(
              header: const ['Planet', 'Sthāna', 'Dig', 'Kāla', 'Cheṣṭā', 'Naisarg.', 'Dṛk', 'Total'],
              rows: [
                for (final p in ShadbalaMath.planets)
                  () {
                    final s = result.planets[p]!;
                    return [
                      s.name,
                      for (final v in s.six.values) v.toStringAsFixed(1),
                      s.total.toStringAsFixed(1),
                    ];
                  }(),
              ],
            ),
          ],
        ),
        SectionCard(
          title: 'Ishta and Kashta Phala',
          subtitle: 'Ishta = √(Uchcha × Cheṣṭā), Kashta = √((60 − Uchcha)(60 − Cheṣṭā)). Read with lordship; not a good/bad label.',
          children: [
            CompactTable(
              header: const ['Planet', 'Ishta', 'Kashta'],
              rows: [
                for (final p in ShadbalaMath.planets)
                  [_n(p), result.planets[p]!.ishtaPhala.toStringAsFixed(1), result.planets[p]!.kashtaPhala.toStringAsFixed(1)],
              ],
            ),
          ],
        ),
        for (final p in ShadbalaMath.planets)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text('${_n(p)} — details', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Minimum ${(result.planets[p]!.minimumVirupas / 60).toStringAsFixed(1)} rupas', style: const TextStyle(fontSize: 12)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sthāna Bala', style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold)),
                for (final c in result.planets[p]!.sthana) BulletLine('${c.name}: ${c.value.toStringAsFixed(2)} — ${c.rule}'),
                const SizedBox(height: 6),
                Text('Kāla Bala', style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold)),
                for (final c in result.planets[p]!.kala) BulletLine('${c.name}: ${c.value.toStringAsFixed(2)} — ${c.rule}'),
                const SizedBox(height: 6),
                BulletLine('Dig Bala ${result.planets[p]!.dig.toStringAsFixed(2)}: arc from the powerless point ÷ 3'),
                BulletLine('Cheṣṭā Bala ${result.planets[p]!.cheshta.toStringAsFixed(2)}'),
                BulletLine('Naisargika Bala ${result.planets[p]!.naisargika.toStringAsFixed(2)}'),
                BulletLine('Dṛk Bala ${result.planets[p]!.drik.toStringAsFixed(2)}: (benefic − malefic sputa drishti) ÷ 4'),
              ],
            ),
          ),
        SectionCard(
          title: 'Conventions',
          children: [for (final n in result.notes) BulletLine(n)],
        ),
      ],
    );
  }
}

class _BhavaTab extends StatelessWidget {
  final ShadbalaResult result;
  const _BhavaTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final maxTotal = result.bhavas.map((b) => b.total).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        SectionCard(
          title: 'Bhāva Bala',
          subtitle: 'Lord\'s Shadbala + directional strength of the Bhāva sign + aspects on the Bhāva madhya (Jupiter and Mercury in full) '
              '+ occupation (Jupiter/Mercury +60; Saturn/Mars/Sun −60), after B. V. Raman.',
          children: [
            for (final b in result.bhavas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('House ${b.house} · lord ${_n(b.lord)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text('${b.rupas.toStringAsFixed(2)} rupas', style: const TextStyle(fontSize: 12)),
                  ]),
                  const SizedBox(height: 3),
                  LinearProgressIndicator(value: (b.total / maxTotal).clamp(0, 1), minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  Text('Adhipati ${b.adhipati.toStringAsFixed(0)} · Dig ${b.dig.toStringAsFixed(0)} · Dṛṣṭi ${b.drishti.toStringAsFixed(1)} · Occupation ${b.occupation.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11)),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

class _PrecisionTab extends StatelessWidget {
  final ChartData chart;
  final CalcConfig cfg;
  const _PrecisionTab({required this.chart, required this.cfg});

  String _motion(GrahaRecord g) => g.isNode ? 'retro (node)' : (g.stationary ? 'stationary' : (g.retrograde ? 'retrograde' : 'direct'));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recs = PrecisionMath.records(chart, cfg);
    final wars = PrecisionMath.wars(chart, cfg);
    final aspects = PrecisionMath.aspects(chart, cfg);
    final qc = PrecisionMath.qualityControl(chart, cfg);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        SectionCard(
          title: 'Exact positions',
          subtitle: 'Sidereal longitude, ecliptic latitude and daily motion from the Swiss Ephemeris.',
          children: [
            CompactTable(
              header: const ['Graha', 'Longitude', 'Lat.', 'Speed', 'Motion', 'Nakshatra (left)'],
              rows: [
                for (final g in recs.values)
                  [
                    g.name,
                    '${VedicMath.rashis[g.rashi].name.substring(0, 3)} ${VedicMath.formatDegree(g.longitude)}',
                    g.latitude.toStringAsFixed(2),
                    g.speed.toStringAsFixed(3),
                    _motion(g),
                    '${g.nakshatra} ${g.pada} (${g.remainingNakshatraArc.toStringAsFixed(2)}°)',
                  ],
              ],
            ),
          ],
        ),
        SectionCard(
          title: 'Dignity, Navāṃśa and combustion',
          subtitle: 'Degree-sensitive dignity (Moolatrikona ranges, deep exaltation). Combustion from the exact Sun distance.',
          children: [
            CompactTable(
              header: const ['Graha', 'Dignity', 'From exalt.', 'D9', 'Sun dist.', 'Combust'],
              rows: [
                for (final g in recs.values)
                  [
                    g.name,
                    g.dignity,
                    g.distanceFromExaltation == null ? '—' : '${g.distanceFromExaltation!.toStringAsFixed(1)}°',
                    '${VedicMath.rashis[g.navamsa].name.substring(0, 3)}${g.vargottama ? ' (V)' : ''}',
                    g.sunDistance == null ? '—' : '${g.sunDistance!.toStringAsFixed(1)}°',
                    g.combustionOrb == null ? '—' : (g.combust ? (g.deeplyCombust ? 'deep' : 'yes') : 'no (${g.combustionOrb!.toStringAsFixed(0)}°)'),
                  ],
              ],
            ),
            const SizedBox(height: 4),
            Text('(V) = vargottama. ${recs.values.where((g) => g.sandhi).isEmpty ? 'No planet is at a Bhāva-sandhi.' : 'At a Bhāva-sandhi: ${recs.values.where((g) => g.sandhi).map((g) => g.name).join(', ')}.'}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        ),
        SectionCard(
          title: 'Planetary war (Graha Yuddha)',
          subtitle: '${cfg.warRuleLabel}; within ${cfg.warOrb.toStringAsFixed(1)}°.',
          children: [
            if (wars.isEmpty) const BulletLine('No planetary war in this chart.'),
            for (final w in wars)
              BulletLine('${_n(w.a)} and ${_n(w.b)} ${w.separation.toStringAsFixed(2)}° apart: ${w.winner == null ? 'winner undetermined' : '${_n(w.winner!)} wins'}', mark: '⚔'),
          ],
        ),
        SectionCard(
          title: 'Aspects with degrees',
          subtitle: 'Parashari full aspects by sign, with the exact angle, orb from the exact aspect point and BPHS sputa drishti. ${cfg.nodeAspectLabel}.',
          children: [
            CompactTable(
              header: const ['From', 'To', 'Aspect', 'Orb', 'Sputa', 'Phase'],
              rows: [
                for (final a in aspects)
                  [
                    _n(a.from),
                    _n(a.to),
                    VedicMath.ordinal(a.houseDistance),
                    '${a.orb.toStringAsFixed(1)}°',
                    a.sputaValue.toStringAsFixed(0),
                    a.applying ? 'applying' : 'separating',
                  ],
              ],
            ),
          ],
        ),
        SectionCard(
          title: 'Quality control',
          subtitle: 'Checks run on every chart before the analysis is accepted (Volume 4 §28).',
          children: [
            for (final q in qc)
              BulletLine('${q.description} — ${q.detail}', mark: q.passed ? '✓' : '✗', color: q.passed ? Colors.green : scheme.error, tag: q.id),
          ],
        ),
      ],
    );
  }
}
