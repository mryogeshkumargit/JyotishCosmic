import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/calc_config.dart';
import '../../core/ephemeris.dart';
import '../../core/l10n.dart';
import '../../core/plain/interpret.dart';
import '../../core/precision_math.dart';
import '../../core/shadbala_math.dart';
import '../../core/vedic_math.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/analysis_widgets.dart';

String _n(String p) => L10n.planet(p);

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
          title: Text(tr('Strength', 'ग्रह बल')),
          bottom: TabBar(tabs: [Tab(text: tr('Shadbala', 'षड्बल')), Tab(text: tr('Bhāva Bala', 'भाव बल')), Tab(text: tr('Precision', 'सूक्ष्म'))]),
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
        SimpleMeaningCard(Interpret.shadbala(result)),
        SectionCard(
          title: tr('Six-fold strength', 'छह प्रकार का बल'),
          subtitle: tr('Virupas (60 = 1 rupa). The bar shows the total against the BPHS minimum (marker at 1.0×). Minimums are reference values, not a ranking of planets.',
              'विरूप (60 = 1 रूप)। पट्टी कुल बल को BPHS के न्यूनतम (1.0× चिह्न) से तुलना में दिखाती है। न्यूनतम मान संदर्भ हैं, ग्रहों की रैंकिंग नहीं।'),
          children: [
            for (final s in ranked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text('${s.rupas.toStringAsFixed(2)} ${tr('rupas', 'रूप')} · ${s.ratio.toStringAsFixed(2)}×', style: const TextStyle(fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  RatioBar(s.ratio),
                ]),
              ),
          ],
        ),
        SectionCard(
          title: tr('Components', 'घटक'),
          children: [
            CompactTable(
              header: L10n.hi
                  ? const ['ग्रह', 'स्थान', 'दिक्', 'काल', 'चेष्टा', 'नैसर्गिक', 'दृक्', 'कुल']
                  : const ['Planet', 'Sthāna', 'Dig', 'Kāla', 'Cheṣṭā', 'Naisarg.', 'Dṛk', 'Total'],
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
          title: tr('Ishta and Kashta Phala', 'इष्ट और कष्ट फल'),
          subtitle: tr('Ishta = √(Uchcha × Cheṣṭā), Kashta = √((60 − Uchcha)(60 − Cheṣṭā)). Read with lordship; not a good/bad label.',
              'इष्ट = √(उच्च × चेष्टा), कष्ट = √((60 − उच्च)(60 − चेष्टा))। भाव स्वामित्व के साथ पढ़ें; यह अच्छा/बुरा लेबल नहीं।'),
          children: [
            CompactTable(
              header: [tr('Planet', 'ग्रह'), tr('Ishta', 'इष्ट'), tr('Kashta', 'कष्ट')],
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
              title: Text('${_n(p)} — ${tr('details', 'विवरण')}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tr('Minimum ${(result.planets[p]!.minimumVirupas / 60).toStringAsFixed(1)} rupas', 'न्यूनतम ${(result.planets[p]!.minimumVirupas / 60).toStringAsFixed(1)} रूप'), style: const TextStyle(fontSize: 12)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Sthāna Bala', 'स्थान बल'), style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold)),
                for (final c in result.planets[p]!.sthana) BulletLine('${c.label}: ${c.value.toStringAsFixed(2)} — ${c.rule}'),
                const SizedBox(height: 6),
                Text(tr('Kāla Bala', 'काल बल'), style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold)),
                for (final c in result.planets[p]!.kala) BulletLine('${c.label}: ${c.value.toStringAsFixed(2)} — ${c.rule}'),
                const SizedBox(height: 6),
                BulletLine(tr('Dig Bala ${result.planets[p]!.dig.toStringAsFixed(2)}: arc from the powerless point ÷ 3', 'दिक् बल ${result.planets[p]!.dig.toStringAsFixed(2)}: निर्बल बिंदु से दूरी ÷ 3')),
                BulletLine('${tr('Cheṣṭā Bala', 'चेष्टा बल')} ${result.planets[p]!.cheshta.toStringAsFixed(2)}'),
                BulletLine('${tr('Naisargika Bala', 'नैसर्गिक बल')} ${result.planets[p]!.naisargika.toStringAsFixed(2)}'),
                BulletLine(tr('Dṛk Bala ${result.planets[p]!.drik.toStringAsFixed(2)}: (benefic − malefic sputa drishti) ÷ 4', 'दृक् बल ${result.planets[p]!.drik.toStringAsFixed(2)}: (शुभ − पाप स्फुट दृष्टि) ÷ 4')),
              ],
            ),
          ),
        SectionCard(
          title: tr('Conventions', 'नियम-परंपराएँ'),
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
        SimpleMeaningCard(Interpret.bhavaBala(result)),
        SectionCard(
          title: tr('Bhāva Bala', 'भाव बल'),
          subtitle: tr('Lord\'s Shadbala + directional strength of the Bhāva sign + aspects on the Bhāva madhya (Jupiter and Mercury in full) '
              '+ occupation (Jupiter/Mercury +60; Saturn/Mars/Sun −60), after B. V. Raman.',
              'स्वामी का षड्बल + भाव राशि का दिक् बल + भाव मध्य पर दृष्टि (गुरु और बुध पूर्ण) + भाव में स्थित ग्रह (गुरु/बुध +60; शनि/मंगल/सूर्य −60), बी. वी. रमन के अनुसार।'),
          children: [
            for (final b in result.bhavas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(tr('House ${b.house} · lord ${_n(b.lord)}', 'भाव ${b.house} · स्वामी ${_n(b.lord)}'), style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text('${b.rupas.toStringAsFixed(2)} ${tr('rupas', 'रूप')}', style: const TextStyle(fontSize: 12)),
                  ]),
                  const SizedBox(height: 3),
                  LinearProgressIndicator(value: (b.total / maxTotal).clamp(0, 1), minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  Text(tr('Adhipati ${b.adhipati.toStringAsFixed(0)} · Dig ${b.dig.toStringAsFixed(0)} · Dṛṣṭi ${b.drishti.toStringAsFixed(1)} · Occupation ${b.occupation.toStringAsFixed(0)}',
                          'अधिपति ${b.adhipati.toStringAsFixed(0)} · दिक् ${b.dig.toStringAsFixed(0)} · दृष्टि ${b.drishti.toStringAsFixed(1)} · स्थित ग्रह ${b.occupation.toStringAsFixed(0)}'),
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

  String _motion(GrahaRecord g) => g.isNode
      ? tr('retro (node)', 'वक्री (छाया)')
      : (g.stationary ? tr('stationary', 'स्थिर') : (g.retrograde ? tr('retrograde', 'वक्री') : tr('direct', 'मार्गी')));

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
          title: tr('Exact positions', 'सटीक स्थितियाँ'),
          subtitle: tr('Sidereal longitude, ecliptic latitude and daily motion from the Swiss Ephemeris.', 'स्विस एफ़ेमेरिस से निरयन भोगांश, शर (अक्षांश) और दैनिक गति।'),
          children: [
            CompactTable(
              header: L10n.hi
                  ? const ['ग्रह', 'भोगांश', 'शर', 'गति', 'चाल', 'नक्षत्र (शेष)']
                  : const ['Graha', 'Longitude', 'Lat.', 'Speed', 'Motion', 'Nakshatra (left)'],
              rows: [
                for (final g in recs.values)
                  [
                    _n(g.planet),
                    '${L10n.hi ? L10n.sign(g.rashi) : VedicMath.rashis[g.rashi].name.substring(0, 3)} ${VedicMath.formatDegree(g.longitude)}',
                    g.latitude.toStringAsFixed(2),
                    g.speed.toStringAsFixed(3),
                    _motion(g),
                    '${L10n.nakshatra(VedicMath.nakshatraIndex(g.longitude))} ${g.pada} (${g.remainingNakshatraArc.toStringAsFixed(2)}°)',
                  ],
              ],
            ),
          ],
        ),
        SectionCard(
          title: tr('Dignity, Navāṃśa and combustion', 'गरिमा, नवांश और अस्त'),
          subtitle: tr('Degree-sensitive dignity (Moolatrikona ranges, deep exaltation). Combustion from the exact Sun distance.', 'अंश के अनुसार गरिमा (मूलत्रिकोण सीमा, परम उच्च)। अस्त सूर्य से सटीक दूरी से।'),
          children: [
            CompactTable(
              header: L10n.hi
                  ? const ['ग्रह', 'गरिमा', 'उच्च से', 'D9', 'सूर्य से', 'अस्त']
                  : const ['Graha', 'Dignity', 'From exalt.', 'D9', 'Sun dist.', 'Combust'],
              rows: [
                for (final g in recs.values)
                  [
                    _n(g.planet),
                    g.isNode ? tr('Node', 'छाया ग्रह') : L10n.dignity(g.dignity),
                    g.distanceFromExaltation == null ? '—' : '${g.distanceFromExaltation!.toStringAsFixed(1)}°',
                    '${L10n.hi ? L10n.sign(g.navamsa) : VedicMath.rashis[g.navamsa].name.substring(0, 3)}${g.vargottama ? ' (V)' : ''}',
                    g.sunDistance == null ? '—' : '${g.sunDistance!.toStringAsFixed(1)}°',
                    g.combustionOrb == null
                        ? '—'
                        : (g.combust ? (g.deeplyCombust ? tr('deep', 'गहरा') : tr('yes', 'हाँ')) : '${tr('no', 'नहीं')} (${g.combustionOrb!.toStringAsFixed(0)}°)'),
                  ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
                tr('(V) = vargottama. ', '(V) = वर्गोत्तम। ') +
                    (recs.values.where((g) => g.sandhi).isEmpty
                        ? tr('No planet is at a Bhāva-sandhi.', 'कोई ग्रह भाव-संधि पर नहीं है।')
                        : '${tr('At a Bhāva-sandhi', 'भाव-संधि पर')}: ${recs.values.where((g) => g.sandhi).map((g) => _n(g.planet)).join(', ')}.'),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        ),
        SectionCard(
          title: tr('Planetary war (Graha Yuddha)', 'ग्रह युद्ध'),
          subtitle: '${cfg.warRuleLabel}; ${tr('within', 'सीमा')} ${cfg.warOrb.toStringAsFixed(1)}°.',
          children: [
            if (wars.isEmpty) BulletLine(tr('No planetary war in this chart.', 'इस कुंडली में कोई ग्रह युद्ध नहीं।')),
            for (final w in wars)
              BulletLine(
                  tr('${_n(w.a)} and ${_n(w.b)} ${w.separation.toStringAsFixed(2)}° apart: ${w.winner == null ? 'winner undetermined' : '${_n(w.winner!)} wins'}',
                      '${_n(w.a)} और ${_n(w.b)} ${w.separation.toStringAsFixed(2)}° दूर: ${w.winner == null ? 'विजेता अनिश्चित' : '${_n(w.winner!)} विजयी'}'),
                  mark: '⚔'),
          ],
        ),
        SectionCard(
          title: tr('Aspects with degrees', 'अंशों सहित दृष्टि'),
          subtitle: tr('Parashari full aspects by sign, with the exact angle, orb from the exact aspect point and BPHS sputa drishti. ${cfg.nodeAspectLabel}.',
              'राशि आधारित पाराशरी पूर्ण दृष्टि, सटीक कोण, सटीक दृष्टि बिंदु से अंतर और BPHS स्फुट दृष्टि सहित। ${cfg.nodeAspectLabel}।'),
          children: [
            CompactTable(
              header: L10n.hi ? const ['से', 'पर', 'दृष्टि', 'अंतर', 'स्फुट', 'स्थिति'] : const ['From', 'To', 'Aspect', 'Orb', 'Sputa', 'Phase'],
              rows: [
                for (final a in aspects)
                  [
                    _n(a.from),
                    _n(a.to),
                    L10n.ordinal(a.houseDistance),
                    '${a.orb.toStringAsFixed(1)}°',
                    a.sputaValue.toStringAsFixed(0),
                    a.applying ? tr('applying', 'निकट आ रहा') : tr('separating', 'दूर जा रहा'),
                  ],
              ],
            ),
          ],
        ),
        SectionCard(
          title: tr('Quality control', 'गुणवत्ता जाँच'),
          subtitle: tr('Checks run on every chart before the analysis is accepted (Volume 4 §28).', 'विश्लेषण स्वीकार करने से पहले हर कुंडली पर चलने वाली जाँच (खंड 4 §28)।'),
          children: [
            for (final q in qc)
              BulletLine('${q.description} — ${q.detail}', mark: q.passed ? '✓' : '✗', color: q.passed ? Colors.green : scheme.error, tag: q.id),
          ],
        ),
      ],
    );
  }
}
