import 'package:flutter/material.dart';
import '../widgets/yoga_guide_view.dart';
import 'research_screen.dart';
import 'rules_sources_screen.dart';
import '../core/l10n.dart';

/// The bundled research documents (Vedic Knowledge Base).
class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  static const List<(String, String)> _hindi = [
    ('योगों की विस्तृत मार्गदर्शिका', 'योग परिवार, शास्त्रीय संख्या और नियम'),
    ('युति डेटाबेस — खंड 2', '21 जोड़े × भाव × राशि × लग्न'),
    ('युति डेटाबेस — खंड 4', 'अंश, बल, वर्ग, दृष्टि और दशा इंजन'),
    ('युति डेटाबेस — खंड 5', 'भविष्यवाणी संश्लेषण इंजन'),
    ('युति डेटाबेस — खंड 6', 'स्वचालित कुंडली विश्लेषक और भविष्यवाणी API'),
    ('ग्रह युति — गहन शोध', 'जोड़ा × भाव × राशि × लग्न, सामान्य गलतियों सहित'),
    ('मास्टर ज्ञान कोष v1.0.0', 'पाँच-स्तरीय संरचना और बाहरी स्रोत'),
    ('प्रोडक्शन नॉलेज ग्राफ़ v1.0.0', 'ऑन्टोलॉजी, उद्गम, प्रमाण और भविष्यवाणी मॉडल'),
  ];

  static const List<(String, String, String)> documents = [
    ('Comprehensive Guide to Yogas', 'Yoga families, classical counts and rules', 'assets/docs/vedic_yogas_guide.md'),
    ('Conjunction Database — Volume 2', '21 pairs × Bhāva × Rāśi × Lagna', 'assets/docs/conjunction_db_vol2.md'),
    ('Conjunction Database — Volume 4', 'Degree, strength, Varga, aspect and Daśā engine', 'assets/docs/conjunction_db_vol4.md'),
    ('Conjunction Database — Volume 5', 'Predictive synthesis engine', 'assets/docs/conjunction_db_vol5.md'),
    ('Conjunction Database — Volume 6', 'Automated chart interpreter and prediction API', 'assets/docs/conjunction_db_vol6.md'),
    ('Planetary Conjunctions — Deep Research', 'Pair × Bhāva × Rāśi × Lagna, with common errors', 'assets/docs/conjunctions_deep_research.md'),
    ('Master Knowledge Base v1.0.0', 'Five-layer architecture and external sources', 'assets/docs/master_kb_readme.md'),
    ('Production Knowledge Graph v1.0.0', 'Ontology, provenance, evidence and prediction model', 'assets/docs/production_knowledge_graph.md'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Knowledge Base', 'ज्ञान कोष'))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (L10n.hi)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('ये शोध दस्तावेज़ मूल रूप से अंग्रेज़ी में हैं।', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
          for (final (i, d) in documents.indexed)
            Card(
              child: ListTile(
                leading: Icon(Icons.menu_book, color: scheme.secondary),
                title: Text(L10n.hi ? _hindi[i].$1 : d.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(L10n.hi ? _hindi[i].$2 : d.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(appBar: AppBar(title: Text(d.$1.split(' — ').last)), body: MarkdownDocView(asset: d.$3)),
                  ),
                ),
              ),
            ),
          Card(
            child: ListTile(
              leading: Icon(Icons.rule, color: scheme.primary),
              title: Text(tr('Rules & Sources', 'नियम और स्रोत'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tr('Rule registry, classical source records and the coverage report', 'नियम सूची, शास्त्रीय स्रोत और कवरेज रिपोर्ट')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RulesSourcesScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.query_stats, color: scheme.primary),
              title: Text(tr('Research', 'शोध'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tr('Find a conjunction by house, sign, Daśā or D9 across saved charts', 'सहेजी गई कुंडलियों में भाव, राशि, दशा या D9 के अनुसार युति खोजें')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResearchScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.storage, color: scheme.secondary),
              title: Text(tr('Conjunction Database — Volume 3', 'युति डेटाबेस — खंड 3'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tr('All 17,280 cluster × Bhāva × Rāśi records are generated in the app. Open a chart and choose Conjunctions → Database to browse them.',
                  'सभी 17,280 समूह × भाव × राशि रिकॉर्ड ऐप में ही बनते हैं। इन्हें देखने के लिए कोई कुंडली खोलें और युति → डेटाबेस चुनें।')),
            ),
          ),
        ],
      ),
    );
  }
}
