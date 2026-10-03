import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/conjunction_db.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/analysis_widgets.dart';

String _n(String p) => ConjunctionDb.planetName(p);

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
          title: const Text('Conjunctions'),
          bottom: TabBar(tabs: [Tab(text: 'Chart (${found.length})'), const Tab(text: 'Nodes'), const Tab(text: 'Database')]),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No two classical planets share a sign in this chart. See the Nodes and Database tabs.', textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
          'Each conjunction is decomposed into all its pairs (Phaladeepika 18.5) with exact separations, then read through the house, sign, '
          'dispositor, Lagna lordship, strength and Daśā. Database records are systematic synthesis, not classical verses.',
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
    return SectionCard(
      title: '${r.clusterId} · ${r.clusterLabel}${cj.nodes.isEmpty ? '' : ' (+ ${cj.nodes.map(_n).join(', ')})'}',
      subtitle: '${r.recordId} · house ${r.bhava} (${ConjunctionDb.bhavaNames[r.bhava - 1]}) · ${VedicMath.rashis[r.rashi].name}',
      children: [
        Wrap(spacing: 6, runSpacing: 4, children: [
          Pill('${r.size} planets · ${r.pairs.length} pairs', scheme.secondary),
          if (cj.activeNow.isNotEmpty) Pill('Active in current Daśā', scheme.primary),
          if (m.combustionLinks > 0) Pill('Combustion', scheme.error),
          if (m.warLinks > 0) const Pill('Graha Yuddha', Colors.orange),
        ]),
        const SizedBox(height: 8),
        KeyValueRow('House domain', ConjunctionDb.bhavaDomains[r.bhava - 1]),
        KeyValueRow('Sign', '${r.element} · ${r.modality} · dispositor ${_n(r.dispositor)} (house ${cj.dispositorRecord.house}, ${cj.dispositorRecord.dignity})'),
        KeyValueRow('Core themes', r.coreThemes),
        KeyValueRow('Lordship', r.functionalLordshipText),
        KeyValueRow('Dominant planet', _n(cj.dominantPlanet)),
        KeyValueRow('Source tier', r.sourceTier),
        KeyValueRow('Classical source', r.directSource),
        const SizedBox(height: 8),
        Text('Pair geometry', style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        CompactTable(
          header: const ['Pair', 'Sep.', 'Phase', 'Notes'],
          rows: [
            for (final e in cj.edges)
              [
                '${_n(e.a)}–${_n(e.b)}',
                '${e.separation.toStringAsFixed(2)}°',
                e.applying ? 'applying' : 'separating',
                [
                  e.closeness,
                  if (e.combustionLink) 'combust',
                  if (e.war != null) 'war${e.war!.winner != null ? ': ${_n(e.war!.winner!)} wins' : ''}',
                ].join(', '),
              ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Separations: min ${m.minSeparation.toStringAsFixed(1)}°, max ${m.maxSeparation.toStringAsFixed(1)}°, mean ${m.meanSeparation.toStringAsFixed(1)}°, median ${m.medianSeparation.toStringAsFixed(1)}° · '
          '${m.closePairs} close pair(s) · ${m.retrogradeParticipants} retrograde · ${m.vargottamaParticipants} vargottama (descriptive metrics, not scores)',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Text('Members', style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
        for (final g in cj.grahas.values)
          BulletLine('${g.name} ${VedicMath.formatDegree(g.longitude)} · ${g.dignity}${g.retrograde ? ' · retrograde' : ''}${g.combust ? ' · combust (${g.sunDistance!.toStringAsFixed(1)}°)' : ''}'
              '${g.vargottama ? ' · vargottama' : ''} · D9 ${VedicMath.rashis[g.navamsa].name}'),
        if (cj.namedYogas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Named yogas confirmed by the yoga engine', style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
          for (final y in cj.namedYogas) BulletLine('${y.name} (${y.strength})', mark: '✓', color: Colors.green),
        ],
        const SizedBox(height: 8),
        Text('Timing', style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
        if (cj.activeNow.isEmpty) const BulletLine('Not activated by the current Daśā.'),
        for (final a in cj.activeNow) BulletLine(a, mark: '✓', color: Colors.green),
        for (final u in upcoming) BulletLine('${_n(u.mahaLord)} / ${_n(u.lord)}: ${u.start} – ${u.end} (${u.reason})', mark: '→'),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Database pair records (Volume 2)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          children: [
            for (final t in r.pairTexts())
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${t.id} ${t.pair}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  BulletLine(t.bhava, tag: 'Bhāva'),
                  BulletLine(t.rashi, tag: 'Rāśi'),
                  BulletLine(t.lagna, tag: 'Lagna'),
                ]),
              ),
            Text(ConjunctionRecord.interpretiveRule, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant)),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Ask AI to interpret this conjunction'),
            onPressed: () {
              final prompt = 'Interpret this conjunction of a Vedic birth chart. First apply any classical multi-planet rule for the exact cluster '
                  '(${r.directSource}), then combine the pairwise results, then the house, sign, dispositor, Lagna lordship, dignity, '
                  'degrees, combustion, planetary war and Daśā timing given below. Label classical statements separately from synthesis.\n\n'
                  'Cluster ${r.clusterId}: ${r.clusterLabel} in house ${r.bhava} (${ConjunctionDb.bhavaDomains[r.bhava - 1]}), ${VedicMath.rashis[r.rashi].name}, '
                  'dispositor ${_n(r.dispositor)}. Lordship: ${r.functionalLordshipText}.\n'
                  'Pairs: ${cj.edges.map((e) => '${_n(e.a)}–${_n(e.b)} ${e.separation.toStringAsFixed(2)}° ${e.applying ? 'applying' : 'separating'}${e.combustionLink ? ', combust' : ''}${e.war != null ? ', planetary war' : ''}').join('; ')}.\n'
                  'Members: ${cj.grahas.values.map((g) => '${g.name} ${g.dignity}${g.retrograde ? ' retrograde' : ''}').join('; ')}.\n'
                  'Timing: ${[...cj.activeNow, ...upcoming.take(3).map((u) => '${_n(u.mahaLord)}/${_n(u.lord)} ${u.start}-${u.end}')].join('; ')}.\n\n'
                  'Chart:\n${ChartSummary.describe(cj.chart, name: name)}';
              showAiSheet(context, ref, title: '${r.clusterLabel} Conjunction', prompt: prompt, profileId: profileId);
            },
          ),
        ),
      ],
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
        Text('Rahu and Ketu are kept outside the seven-planet cluster engine. A node with a planet is a node-graha pair: the planet keeps its own dignity and dispositor.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 12),
        for (final n in nodes)
          SectionCard(
            title: '${_n(n.node)} in ${VedicMath.rashis[n.graha.rashi].name} ${VedicMath.formatDegree(n.graha.longitude)}',
            subtitle: 'House ${n.graha.house} · ${n.graha.nakshatra} pada ${n.graha.pada} (lord ${_n(n.graha.nakshatraLord)}) · D9 ${VedicMath.rashis[n.graha.navamsa].name}',
            children: [
              KeyValueRow('Dispositor', _n(n.dispositor)),
              KeyValueRow('Motion', 'Retrograde (mean node)'),
              KeyValueRow('Associated planets', n.planets.isEmpty ? 'none' : n.planets.map(_n).join(', ')),
              for (final e in n.edges)
                BulletLine('${n.nodePairType}: ${_n(e.b)} at ${e.separation.toStringAsFixed(2)}° (${e.closeness}, ${e.applying ? 'applying' : 'separating'})'),
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
        Text('Browse all ${ConjunctionDb.totalRecords} records: 120 clusters (2-7 planets) × 12 Bhāvas × 12 Rāśis.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _cluster,
          decoration: const InputDecoration(labelText: 'Cluster'),
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
              decoration: const InputDecoration(labelText: 'Bhāva'),
              items: [for (int h = 1; h <= 12; h++) DropdownMenuItem(value: h, child: Text('$h ${ConjunctionDb.bhavaNames[h - 1]}', overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _bhava = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _rashi,
              decoration: const InputDecoration(labelText: 'Rāśi'),
              items: [for (int s = 0; s < 12; s++) DropdownMenuItem(value: s, child: Text(VedicMath.rashis[s].name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _rashi = v!),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SectionCard(
          title: r.recordId,
          subtitle: '${r.clusterId} — ${r.clusterLabel}',
          children: [
            KeyValueRow('Cluster size', '${r.size}'),
            KeyValueRow('Bhāva', '${r.bhava} (${ConjunctionDb.bhavaNames[r.bhava - 1]}) — ${ConjunctionDb.bhavaDomains[r.bhava - 1]}'),
            KeyValueRow('Rāśi', VedicMath.rashis[r.rashi].name),
            KeyValueRow('Dispositor', _n(r.dispositor)),
            KeyValueRow('Element / modality', '${r.element} / ${r.modality}'),
            KeyValueRow('Derived Lagna', VedicMath.rashis[r.derivedLagna].name),
            KeyValueRow('Pairs (${r.pairs.length})', r.pairwiseText),
            KeyValueRow('Functional lordship', r.functionalLordshipText),
            KeyValueRow('Source tier', r.sourceTier),
            KeyValueRow('Classical source', r.directSource),
            KeyValueRow('Core themes', r.coreThemes),
            BulletLine(r.bhavaInteraction, tag: 'Bhāva'),
            BulletLine(r.rashiInteraction, tag: 'Rāśi'),
            BulletLine(ConjunctionRecord.interpretiveRule, tag: 'Rule'),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Pair records (Volume 2)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              children: [
                for (final t in r.pairTexts())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${t.id} ${t.pair}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      BulletLine(t.bhava, tag: 'Bhāva'),
                      BulletLine(t.rashi, tag: 'Rāśi'),
                      BulletLine(t.lagna, tag: 'Lagna'),
                    ]),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
