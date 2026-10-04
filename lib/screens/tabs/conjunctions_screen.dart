import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/conjunction_db.dart';
import '../../core/ephemeris.dart';
import '../../core/l10n.dart';
import '../../core/plain/interpret.dart';
import '../../core/vedic_math.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/analysis_widgets.dart';

String _n(String p) => ConjunctionDb.planetName(p);

String _closeness(String c) => switch (c) {
      'exact' => tr('exact', 'सटीक'),
      'close' => tr('close', 'निकट'),
      _ => tr('wide', 'दूर'),
    };

String _phase(bool applying) => applying ? tr('applying', 'निकट आ रहा') : tr('separating', 'दूर जा रहा');

/// Conjunction Database (Volumes 2-4): the chart's conjunctions with exact
/// geometry and timing, Rahu/Ketu associations, and the full record browser.
class ConjunctionsScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;
  final String? name;
  const ConjunctionsScreen({super.key, required this.chartData, this.profileId, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(settingsProvider.select((s) => s.calc));
    final found = ConjunctionDb.find(chartData, cfg: cfg);
    final nodes = ConjunctionDb.nodeAssociations(chartData, cfg: cfg);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('Conjunctions', 'युति')),
          bottom: TabBar(tabs: [
            Tab(text: tr('Chart (${found.length})', 'कुंडली (${found.length})')),
            Tab(text: tr('Nodes', 'राहु-केतु')),
            Tab(text: tr('Database', 'डेटाबेस')),
          ]),
        ),
        body: TabBarView(children: [
          _ChartTab(chart: chartData, found: found, profileId: profileId, name: name),
          _NodesTab(nodes: nodes),
          _DatabaseTab(chart: chartData),
        ]),
      ),
    );
  }
}

class _ChartTab extends ConsumerWidget {
  final ChartData chart;
  final List<ChartConjunction> found;
  final int? profileId;
  final String? name;
  const _ChartTab({required this.chart, required this.found, this.profileId, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (found.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
              tr('No two classical planets share a sign in this chart. See the Nodes and Database tabs.',
                  'इस कुंडली में कोई दो ग्रह एक राशि में नहीं हैं। राहु-केतु और डेटाबेस टैब देखें।'),
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        SimpleMeaningCard([
          tr('A conjunction (yuti) is two or more planets in the same sign. Their energies mix, so you experience them together rather than separately. '
              'What it means depends on the house (which area of life), the sign (in what style) and the strength of the planets.',
              'युति का अर्थ है दो या अधिक ग्रह एक ही राशि में। उनकी ऊर्जाएँ मिल जाती हैं, इसलिए आप उन्हें अलग-अलग नहीं बल्कि साथ अनुभव करते हैं। '
                  'इसका अर्थ भाव (जीवन का कौन सा क्षेत्र), राशि (किस तरह से) और ग्रहों के बल पर निर्भर करता है।'),
        ]),
        Text(
          tr('Each conjunction is decomposed into all its pairs (Phaladeepika 18.5) with exact separations, then read through the house, sign, '
              'dispositor, Lagna lordship, strength and Daśā. Database records are systematic synthesis, not classical verses.',
              'हर युति को उसके सभी जोड़ों (फलदीपिका 18.5) में सटीक दूरी के साथ बाँटा गया है, फिर भाव, राशि, राशि स्वामी, लग्न स्वामित्व, बल और दशा से पढ़ा गया है। '
                  'डेटाबेस रिकॉर्ड व्यवस्थित संश्लेषण हैं, शास्त्रीय श्लोक नहीं।'),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 12),
        for (final cj in found) _ConjunctionCard(cj: cj, profileId: profileId, name: name),
      ],
    );
  }
}

class _ConjunctionCard extends ConsumerWidget {
  final ChartConjunction cj;
  final int? profileId;
  final String? name;
  const _ConjunctionCard({required this.cj, this.profileId, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final r = cj.record;
    final m = cj.metrics;
    final upcoming = cj.upcoming(limit: 6);
    TextStyle head() => TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold, fontSize: 13);
    return SectionCard(
      title: '${r.clusterId} · ${r.clusterLabel}${cj.nodes.isEmpty ? '' : ' (+ ${cj.nodes.map(_n).join(', ')})'}',
      subtitle: '${r.recordId} · ${tr('house', 'भाव')} ${r.bhava} (${ConjunctionDb.bhavaName(r.bhava)}) · ${L10n.sign(r.rashi)}',
      children: [
        SimpleMeaningCard(Interpret.conjunction(cj)),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Pill(tr('${r.size} planets · ${r.pairs.length} pairs', '${r.size} ग्रह · ${r.pairs.length} जोड़े'), scheme.secondary),
          if (cj.activeNow.isNotEmpty) Pill(tr('Active in current Daśā', 'वर्तमान दशा में सक्रिय'), scheme.primary),
          if (m.combustionLinks > 0) Pill(tr('Combustion', 'अस्त'), scheme.error),
          if (m.warLinks > 0) Pill(tr('Graha Yuddha', 'ग्रह युद्ध'), Colors.orange),
          if (cj.vargaRepetition.isNotEmpty) Pill('${tr('Repeated in', 'दोहराई गई')} ${cj.vargaRepetition.join(', ')}', Colors.green),
        ]),
        const SizedBox(height: 8),
        KeyValueRow(tr('House domain', 'भाव क्षेत्र'), ConjunctionDb.bhavaDomain(r.bhava)),
        KeyValueRow(tr('Sign modifier', 'राशि प्रभाव'), cj.signModifier),
        KeyValueRow(
            tr('Sign', 'राशि'),
            '${L10n.element(r.element)} · ${ConjunctionDb.modalityLabel(r.rashi)} · ${tr('dispositor', 'राशि स्वामी')} ${_n(r.dispositor)} '
                '(${tr('house', 'भाव')} ${cj.dispositorRecord.house}, ${L10n.dignity(cj.dispositorRecord.dignity)})'),
        KeyValueRow(tr('Core themes', 'मुख्य विषय'), r.coreThemes),
        KeyValueRow(tr('Lordship', 'भाव स्वामित्व'), r.functionalLordshipText),
        KeyValueRow(tr('Dominant planet', 'प्रमुख ग्रह'), _n(cj.dominantPlanet)),
        KeyValueRow(tr('Source tier', 'स्रोत स्तर'), r.sourceTier),
        KeyValueRow(tr('Classical source', 'शास्त्रीय स्रोत'), r.directSource),
        const SizedBox(height: 8),
        Text(tr('Pair geometry', 'जोड़ों की ज्यामिति'), style: head()),
        const SizedBox(height: 4),
        CompactTable(
          header: [tr('Pair', 'जोड़ा'), tr('Sep.', 'दूरी'), tr('Phase', 'स्थिति'), tr('Notes', 'टिप्पणी')],
          rows: [
            for (final e in cj.edges)
              [
                '${_n(e.a)}–${_n(e.b)}',
                '${e.separation.toStringAsFixed(2)}°',
                _phase(e.applying),
                [
                  _closeness(e.closeness),
                  if (e.combustionLink) tr('combust', 'अस्त'),
                  if (e.war != null) '${tr('war', 'युद्ध')}${e.war!.winner != null ? ': ${_n(e.war!.winner!)} ${tr('wins', 'विजयी')}' : ''}',
                ].join(', '),
              ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          tr(
              'Separations: min ${m.minSeparation.toStringAsFixed(1)}°, max ${m.maxSeparation.toStringAsFixed(1)}°, mean ${m.meanSeparation.toStringAsFixed(1)}°, median ${m.medianSeparation.toStringAsFixed(1)}° · '
                  '${m.closePairs} close pair(s) · ${m.retrogradeParticipants} retrograde · ${m.vargottamaParticipants} vargottama (descriptive metrics, not scores)',
              'दूरी: न्यूनतम ${m.minSeparation.toStringAsFixed(1)}°, अधिकतम ${m.maxSeparation.toStringAsFixed(1)}°, औसत ${m.meanSeparation.toStringAsFixed(1)}°, माध्य ${m.medianSeparation.toStringAsFixed(1)}° · '
                  '${m.closePairs} निकट जोड़े · ${m.retrogradeParticipants} वक्री · ${m.vargottamaParticipants} वर्गोत्तम (वर्णनात्मक माप, अंक नहीं)'),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Text(tr('Cluster diagnostics', 'युति विश्लेषण'), style: head()),
        _Diagnostics(cj.diagnostics),
        if (cj.pairRepetitions.isNotEmpty)
          BulletLine('${tr('Pairs repeated in Vargas', 'वर्गों में दोहराए गए जोड़े')}: ${cj.pairRepetitions.join('; ')}', mark: '✓', color: Colors.green),
        for (final c in cj.cautions) BulletLine(c, mark: '⚠', color: Colors.orange),
        const SizedBox(height: 8),
        Text(tr('Members', 'सदस्य ग्रह'), style: head()),
        for (final g in cj.grahas.values)
          BulletLine('${g.name} ${VedicMath.formatDegree(g.longitude)} · ${L10n.dignity(g.dignity)}${g.retrograde ? ' · ${tr('retrograde', 'वक्री')}' : ''}'
              '${g.combust ? ' · ${tr('combust', 'अस्त')} (${g.sunDistance!.toStringAsFixed(1)}°)' : ''}'
              '${g.vargottama ? ' · ${tr('vargottama', 'वर्गोत्तम')}' : ''} · D9 ${L10n.sign(g.navamsa)}'),
        if (cj.namedYogas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(tr('Named yogas confirmed by the yoga engine', 'योग इंजन द्वारा पुष्ट नामित योग'), style: head()),
          for (final y in cj.namedYogas) BulletLine('${L10n.hi ? y.hindi : y.name} (${Interpret.yogaStrength(y.strength)})', mark: '✓', color: Colors.green),
        ],
        const SizedBox(height: 8),
        Text(tr('Timing', 'समय'), style: head()),
        if (cj.activeNow.isEmpty) BulletLine(tr('Not activated by the current Daśā.', 'वर्तमान दशा से सक्रिय नहीं।')),
        for (final a in cj.activeNow) BulletLine(a, mark: '✓', color: Colors.green),
        for (final u in upcoming) BulletLine('${_n(u.mahaLord)} / ${_n(u.lord)}: ${u.start} – ${u.end} (${u.reason})', mark: '→'),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(tr('Database pair records (Volume 2)', 'डेटाबेस जोड़ा रिकॉर्ड (खंड 2)'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          children: [
            for (final (pair, obs) in cj.classicalObservations) BulletLine('$pair: $obs', tag: tr('Ph. 18', 'फल. 18')),
            for (final t in r.pairTexts()) _PairRecord(t, r.rashi),
            Text(ConjunctionRecord.interpretiveRule, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant)),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(tr('Ask AI to interpret this conjunction', 'AI से इस युति का विश्लेषण कराएँ')),
            onPressed: () {
              final prompt = 'Interpret this conjunction of a Vedic birth chart. First apply any classical multi-planet rule for the exact cluster '
                  '(${ConjunctionDb.directSource(r.size)}), then combine the pairwise results, then the house, sign, dispositor, Lagna lordship, dignity, '
                  'degrees, combustion, planetary war and Daśā timing given below. Label classical statements separately from synthesis.\n\n'
                  'Cluster ${r.clusterId}: ${r.clusterLabel} in house ${r.bhava} (${ConjunctionDb.bhavaDomains[r.bhava - 1]}), ${VedicMath.rashis[r.rashi].name}, '
                  'dispositor ${_n(r.dispositor)}. Lordship: ${r.functionalLordshipText}.\n'
                  'Pairs: ${cj.edges.map((e) => '${_n(e.a)}–${_n(e.b)} ${e.separation.toStringAsFixed(2)}° ${e.applying ? 'applying' : 'separating'}${e.combustionLink ? ', combust' : ''}${e.war != null ? ', planetary war' : ''}').join('; ')}.\n'
                  'Sign modifier: ${ConjunctionDb.signModifiers[r.rashi]}. ${cj.vargaRepetition.isEmpty ? 'Not repeated in D9/D10.' : 'Repeated in ${cj.vargaRepetition.join(', ')}.'}\n'
                  'Cautions: ${cj.cautions.join(' ')}\n'
                  'Members: ${cj.grahas.values.map((g) => '${g.name} ${g.dignity}${g.retrograde ? ' retrograde' : ''}').join('; ')}.\n'
                  'Timing: ${[...cj.activeNow, ...upcoming.take(3).map((u) => '${_n(u.mahaLord)}/${_n(u.lord)} ${u.start}-${u.end}')].join('; ')}.\n\n'
                  'Chart:\n${ChartSummary.describe(cj.chart, name: name)}';
              showAiSheet(context, ref, title: '${r.clusterLabel} ${tr('Conjunction', 'युति')}', prompt: prompt, profileId: profileId);
            },
          ),
        ),
      ],
    );
  }
}

class _PairRecord extends StatelessWidget {
  final ({String id, String pair, String bhava, String rashi, String lagna}) t;
  final int rashi;
  const _PairRecord(this.t, this.rashi);

  @override
  Widget build(BuildContext context) {
    final ps = ConjunctionDb.planetsOf(t.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${t.id} ${t.pair}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        BulletLine(t.bhava, tag: tr('Bhāva', 'भाव')),
        BulletLine(t.rashi, tag: tr('Rāśi', 'राशि')),
        BulletLine(ConjunctionDb.pairSignModifierText(ps[0], ps[1], rashi), tag: tr('Sign', 'प्रभाव')),
        BulletLine(t.lagna, tag: tr('Lagna', 'लग्न')),
      ]),
    );
  }
}

class _NodesTab extends StatelessWidget {
  final List<NodeAssociation> nodes;
  const _NodesTab({required this.nodes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
            tr('Rahu and Ketu are kept outside the seven-planet cluster engine. A node with a planet is a node-graha pair: the planet keeps its own dignity and dispositor.',
                'राहु और केतु को सात-ग्रह युति इंजन से अलग रखा गया है। ग्रह के साथ छाया ग्रह एक छाया-ग्रह जोड़ा है: ग्रह अपनी गरिमा और राशि स्वामी बनाए रखता है।'),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 12),
        for (final n in nodes)
          SectionCard(
            title: tr('${_n(n.node)} in ${L10n.sign(n.graha.rashi)} ${VedicMath.formatDegree(n.graha.longitude)}',
                '${_n(n.node)} ${L10n.sign(n.graha.rashi)} में ${VedicMath.formatDegree(n.graha.longitude)}'),
            subtitle: '${tr('House', 'भाव')} ${n.graha.house} · ${L10n.nakshatra(VedicMath.nakshatraIndex(n.graha.longitude))} ${tr('pada', 'पद')} ${n.graha.pada} '
                '(${tr('lord', 'स्वामी')} ${_n(n.graha.nakshatraLord)}) · D9 ${L10n.sign(n.graha.navamsa)}',
            children: [
              KeyValueRow(tr('Dispositor', 'राशि स्वामी'), _n(n.dispositor)),
              KeyValueRow(tr('Motion', 'गति'), tr('Retrograde (node)', 'वक्री (छाया ग्रह)')),
              KeyValueRow(tr('Associated planets', 'साथ के ग्रह'), n.planets.isEmpty ? tr('none', 'कोई नहीं') : n.planets.map(_n).join(', ')),
              for (final e in n.edges)
                BulletLine('${_n(n.node)}–${_n(e.b)}: ${e.separation.toStringAsFixed(2)}° (${_closeness(e.closeness)}, ${_phase(e.applying)})'),
              const SizedBox(height: 4),
              for (final r in n.contextualRole) BulletLine(r, mark: '→'),
            ],
          ),
      ],
    );
  }
}

class _DatabaseTab extends StatefulWidget {
  final ChartData chart;
  const _DatabaseTab({required this.chart});

  @override
  State<_DatabaseTab> createState() => _DatabaseTabState();
}

class _DatabaseTabState extends State<_DatabaseTab> {
  String _cluster = 'P01';
  int _bhava = 1;
  late int _rashi = widget.chart.lagnaRashi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = ConjunctionDb.record(_cluster, _bhava, _rashi);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
            tr('Browse all ${ConjunctionDb.totalRecords} records: 120 clusters (2-7 planets) × 12 Bhāvas × 12 Rāśis.',
                'सभी ${ConjunctionDb.totalRecords} रिकॉर्ड देखें: 120 युतियाँ (2-7 ग्रह) × 12 भाव × 12 राशियाँ।'),
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _cluster,
          decoration: InputDecoration(labelText: tr('Cluster', 'युति')),
          items: [
            for (final c in ConjunctionDb.clusters)
              DropdownMenuItem(value: c.$1, child: Text('${c.$1} · ${c.$2.map(_n).join(' + ')}', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _cluster = v!),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _bhava,
              decoration: InputDecoration(labelText: tr('Bhāva', 'भाव')),
              items: [for (int h = 1; h <= 12; h++) DropdownMenuItem(value: h, child: Text('$h ${ConjunctionDb.bhavaName(h)}', overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _bhava = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _rashi,
              decoration: InputDecoration(labelText: tr('Rāśi', 'राशि')),
              items: [for (int s = 0; s < 12; s++) DropdownMenuItem(value: s, child: Text(L10n.sign(s), overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _rashi = v!),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(
          title: r.recordId,
          subtitle: '${r.clusterId} — ${r.clusterLabel}',
          children: [
            KeyValueRow(tr('Cluster size', 'युति में ग्रह'), '${r.size}'),
            KeyValueRow(tr('Bhāva', 'भाव'), '${r.bhava} (${ConjunctionDb.bhavaName(r.bhava)}) — ${ConjunctionDb.bhavaDomain(r.bhava)}'),
            KeyValueRow(tr('Rāśi', 'राशि'), L10n.sign(r.rashi)),
            KeyValueRow(tr('Dispositor', 'राशि स्वामी'), _n(r.dispositor)),
            KeyValueRow(tr('Element / modality', 'तत्व / स्वभाव'), '${L10n.element(r.element)} / ${ConjunctionDb.modalityLabel(r.rashi)}'),
            KeyValueRow(tr('Derived Lagna', 'व्युत्पन्न लग्न'), L10n.sign(r.derivedLagna)),
            KeyValueRow(tr('Pairs (${r.pairs.length})', 'जोड़े (${r.pairs.length})'), r.pairwiseText),
            KeyValueRow(tr('Functional lordship', 'कार्यात्मक स्वामित्व'), r.functionalLordshipText),
            KeyValueRow(tr('Source tier', 'स्रोत स्तर'), r.sourceTier),
            KeyValueRow(tr('Classical source', 'शास्त्रीय स्रोत'), r.directSource),
            KeyValueRow(tr('Core themes', 'मुख्य विषय'), r.coreThemes),
            BulletLine(r.bhavaInteraction, tag: tr('Bhāva', 'भाव')),
            BulletLine(r.rashiInteraction, tag: tr('Rāśi', 'राशि')),
            BulletLine(ConjunctionRecord.interpretiveRule, tag: tr('Rule', 'नियम')),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(tr('Pair records (Volume 2)', 'जोड़ा रिकॉर्ड (खंड 2)'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              children: [for (final t in r.pairTexts()) _PairRecord(t, r.rashi)],
            ),
          ],
        ),
      ],
    );
  }
}

/// Volume 6 §18 cluster compression (engineering diagnostics).
class _Diagnostics extends StatelessWidget {
  final ClusterDiagnostics d;
  const _Diagnostics(this.d);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      KeyValueRow(tr('Degree span', 'अंश विस्तार'),
          '${d.degreeSpan.toStringAsFixed(2)}° ${tr('around', 'केंद्र')} ${VedicMath.formatDegree(d.centerLongitude)} ${L10n.sign(VedicMath.rashiIndex(d.centerLongitude))}'),
      if (d.nearestPair != null)
        KeyValueRow(tr('Nearest / widest', 'सबसे निकट / सबसे दूर'), '${_n(d.nearestPair!.a)}–${_n(d.nearestPair!.b)} / ${_n(d.widestPair!.a)}–${_n(d.widestPair!.b)}'),
      KeyValueRow(tr('Central planet', 'केंद्रीय ग्रह'), _n(d.centralPlanet)),
      KeyValueRow(
          tr('Strength profile', 'बल प्रोफ़ाइल'),
          tr(
              'compactness ${d.compactness.toStringAsFixed(2)} · dignity coherence ${d.dignityCoherence.toStringAsFixed(2)} (${d.dominantDignityLabel}) · '
                  'house coherence ${d.houseCoherence.toStringAsFixed(2)} · activation ${d.activationPotential.toStringAsFixed(2)}',
              'सघनता ${d.compactness.toStringAsFixed(2)} · गरिमा सामंजस्य ${d.dignityCoherence.toStringAsFixed(2)} (${d.dominantDignityLabel}) · '
                  'भाव सामंजस्य ${d.houseCoherence.toStringAsFixed(2)} · सक्रियता ${d.activationPotential.toStringAsFixed(2)}')),
      Text('${ClusterDiagnostics.classification}: ${tr('engineering diagnostics, not classical scores.', 'तकनीकी विश्लेषण, शास्त्रीय अंक नहीं।')}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
    ]);
  }
}
