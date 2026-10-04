import 'package:flutter/material.dart';
import '../core/knowledge_registry.dart';
import '../widgets/analysis_widgets.dart';
import '../core/l10n.dart';

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
          title: Text(tr('Rules & Sources', 'नियम और स्रोत')),
          bottom: TabBar(tabs: [Tab(text: tr('Rules', 'नियम')), Tab(text: tr('Sources', 'स्रोत')), Tab(text: tr('Coverage', 'कवरेज'))]),
        ),
        body: TabBarView(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: [
              if (L10n.hi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('नियमों की तकनीकी शर्तें अंग्रेज़ी में दिखाई गई हैं।', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
              for (final r in KnowledgeRegistry.rules)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${r.id} · ${KnowledgeRegistry.ruleName(r.id)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        Pill(r.classification, classColor(r.classification, scheme)),
                        Pill('${tr('priority', 'प्राथमिकता')} ${r.priority}', scheme.outline),
                        if (r.appAddition) Pill(tr('APP ADDITION', 'ऐप द्वारा जोड़ा'), scheme.primary),
                      ]),
                      const SizedBox(height: 6),
                      Text(r.condition, style: const TextStyle(fontSize: 13, height: 1.35)),
                      if (r.sourceIds.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${tr('Sources', 'स्रोत')}: ${r.sourceIds.map((s) => '$s ${KnowledgeRegistry.sourceLabel(s)}').join('; ')}',
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
                tr('Sources are reference records (text, chapter, topic). The app does not hold verified verse text, so no rule quotes scripture; '
                    'engineering heuristics are labelled as such.',
                    'स्रोत संदर्भ रिकॉर्ड हैं (ग्रंथ, अध्याय, विषय)। ऐप में सत्यापित श्लोक नहीं हैं, इसलिए कोई नियम शास्त्र को उद्धृत नहीं करता; इंजीनियरिंग अनुमान को अलग से चिह्नित किया गया है।'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              for (final s in KnowledgeRegistry.sources)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('${s.id} · ${s.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s.locator}\n${s.description}\n${s.classification} · ${s.verificationState}${s.appAddition ? ' · ${tr('app addition', 'ऐप द्वारा जोड़ा')}' : ''}'),
                    isThreeLine: true,
                  ),
                ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: [
              SectionCard(
                title: tr('Rule coverage report', 'नियम कवरेज रिपोर्ट'),
                subtitle: '${tr('Knowledge registry', 'ज्ञान रजिस्ट्री')} v${KnowledgeRegistry.version}',
                children: [for (final e in cov.entries) KeyValueRow(e.key.replaceAll('_', ' '), '${e.value}')],
              ),
              SectionCard(
                title: tr('By classification', 'वर्गीकरण के अनुसार'),
                children: [
                  for (final c in {for (final r in KnowledgeRegistry.rules) r.classification})
                    KeyValueRow(c, '${KnowledgeRegistry.rules.where((r) => r.classification == c).length}'),
                ],
              ),
              SectionCard(
                title: tr('External references (not ingested)', 'बाहरी संदर्भ (शामिल नहीं)'),
                subtitle: tr('Listed by the Master Knowledge Base as integration sources. Their content is not bundled; it would be imported according to each repository\'s licence.',
                    'मास्टर ज्ञान कोष में एकीकरण स्रोत के रूप में सूचीबद्ध। इनकी सामग्री ऐप में नहीं है; इसे हर रिपॉज़िटरी के लाइसेंस के अनुसार जोड़ा जाएगा।'),
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
