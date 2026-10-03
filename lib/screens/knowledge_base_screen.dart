import 'package:flutter/material.dart';
import '../widgets/yoga_guide_view.dart';

/// The bundled research documents (Vedic Knowledge Base).
class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  static const List<(String, String, String)> documents = [
    ('Comprehensive Guide to Yogas', 'Yoga families, classical counts and rules', 'assets/docs/vedic_yogas_guide.md'),
    ('Conjunction Database — Volume 2', '21 pairs × Bhāva × Rāśi × Lagna', 'assets/docs/conjunction_db_vol2.md'),
    ('Conjunction Database — Volume 4', 'Degree, strength, Varga, aspect and Daśā engine', 'assets/docs/conjunction_db_vol4.md'),
    ('Conjunction Database — Volume 5', 'Predictive synthesis engine', 'assets/docs/conjunction_db_vol5.md'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge Base')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final d in documents)
            Card(
              child: ListTile(
                leading: Icon(Icons.menu_book, color: scheme.secondary),
                title: Text(d.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(d.$2),
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
              leading: Icon(Icons.storage, color: scheme.secondary),
              title: const Text('Conjunction Database — Volume 3', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('All 17,280 cluster × Bhāva × Rāśi records are generated in the app. Open a chart and choose Conjunctions → Database to browse them.'),
            ),
          ),
        ],
      ),
    );
  }
}
