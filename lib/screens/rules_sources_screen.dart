import 'package:flutter/material.dart';
import '../core/knowledge_registry.dart';
import '../widgets/analysis_widgets.dart';

/// Rule and source registries with the coverage report (Volume 6 §58-59, §104-105).
class RulesSourcesScreen extends StatelessWidget {
  const RulesSourcesScreen({super.key});

  static Color classColor(String c, ColorScheme scheme) => switch (c) {
        'DIRECT_CLASSICAL' => Colors.green,
        'CLASSICAL_DERIVED' => Colors.teal,
        'CONFIGURABLE_TRADITION' => Colors.orange,
        'ENGINEERING_HEURISTIC' => scheme.error,
        _ => scheme.secondary,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cov = KnowledgeRegistry.coverage();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rules & Sources'),
          bottom: const TabBar(tabs: [Tab(text: 'Rules'), Tab(text: 'Sources'), Tab(text: 'Coverage')]),
        ),
        body: TabBarView(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: [
              for (final r in KnowledgeRegistry.rules)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${r.id} · ${r.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        Pill(r.classification, classColor(r.classification, scheme)),
                        Pill('priority ${r.priority}', scheme.outline),
                        if (r.appAddition) Pill('APP ADDITION', scheme.primary),
                      ]),
                      const SizedBox(height: 6),
                      Text(r.condition, style: const TextStyle(fontSize: 13, height: 1.35)),
                      if (r.sourceIds.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Sources: ${r.sourceIds.map((s) => '$s ${KnowledgeRegistry.sourceLabel(s)}').join('; ')}',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ]),
                  ),
                ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: [
              Text(
                'Sources are reference records (text, chapter, topic). The app does not hold verified verse text, so no rule quotes scripture; '
                'engineering heuristics are labelled as such.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              for (final s in KnowledgeRegistry.sources)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('${s.id} · ${s.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s.locator}\n${s.description}\n${s.classification} · ${s.verificationState}${s.appAddition ? ' · app addition' : ''}'),
                    isThreeLine: true,
                  ),
                ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: [
              SectionCard(
                title: 'Rule coverage report',
                subtitle: 'Knowledge registry v${KnowledgeRegistry.version}',
                children: [for (final e in cov.entries) KeyValueRow(e.key.replaceAll('_', ' '), '${e.value}')],
              ),
              SectionCard(
                title: 'By classification',
                children: [
                  for (final c in {for (final r in KnowledgeRegistry.rules) r.classification})
                    KeyValueRow(c, '${KnowledgeRegistry.rules.where((r) => r.classification == c).length}'),
                ],
              ),
              SectionCard(
                title: 'External references (not ingested)',
                subtitle: 'Listed by the Master Knowledge Base as integration sources. Their content is not bundled; it would be imported according to each repository\'s licence.',
                children: [
                  for (final x in KnowledgeRegistry.external) BulletLine('${x.id} ${x.name} — ${x.role}\n${x.url}', mark: '↗'),
                ],
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
