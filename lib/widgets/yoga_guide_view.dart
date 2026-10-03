import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// The bundled "Comprehensive Guide to Yogas" (assets/docs/vedic_yogas_guide.md).
class YogaGuideView extends StatefulWidget {
  const YogaGuideView({super.key});

  static const String asset = 'assets/docs/vedic_yogas_guide.md';

  @override
  State<YogaGuideView> createState() => _YogaGuideViewState();
}

class _YogaGuideViewState extends State<YogaGuideView> {
  late final Future<String> _text = rootBundle.loadString(YogaGuideView.asset);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: _text,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not open the guide: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return Markdown(
          data: snapshot.data!,
          selectable: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, height: 1.5),
            h1: TextStyle(color: theme.colorScheme.primary, fontSize: 22, fontWeight: FontWeight.bold),
            h2: TextStyle(color: theme.colorScheme.secondary, fontSize: 19, fontWeight: FontWeight.bold),
            h3: TextStyle(color: theme.colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.bold),
            tableBody: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
            tableHead: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
            tableColumnWidth: const FlexColumnWidth(),
            tableCellsPadding: const EdgeInsets.all(6),
            blockquoteDecoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            codeblockDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            code: TextStyle(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface),
          ),
        );
      },
    );
  }
}

/// Stand-alone page for the guide (opened from the dashboard).
class YogaGuideScreen extends StatelessWidget {
  const YogaGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yoga Guide')),
      body: const YogaGuideView(),
    );
  }
}
