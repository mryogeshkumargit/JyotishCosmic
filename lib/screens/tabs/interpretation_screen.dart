import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../widgets/ai_sheet.dart';
import '../../core/l10n.dart';

class InterpretationScreen extends ConsumerWidget {
  final int? profileId;

  const InterpretationScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profileId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('AI Interpretation', 'AI विश्लेषण'))),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(tr('This Kundali is not saved yet. Please save it to view AI interpretations.', 'यह कुंडली अभी सहेजी नहीं गई है। AI विश्लेषण देखने के लिए इसे सहेजें।'), textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final db = ref.watch(databaseProvider);
    final profileStream = db.select(db.profiles)..where((t) => t.id.equals(profileId!));

    return StreamBuilder(
      stream: profileStream.watchSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final profile = snapshot.data!;
        final text = profile.aiInterpretation;
        
        return Scaffold(
          appBar: AppBar(title: Text(tr('Interpretations', 'विश्लेषण'))),
          body: () {
            if (text == null || text.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  tr('No AI interpretation has been saved for this profile yet.\n\nGo back and tap on any house in the Kundali Chart to generate an interpretation, then click "Save Interpretation to Profile".',
                      'इस प्रोफ़ाइल के लिए अभी कोई AI विश्लेषण सहेजा नहीं गया है।\n\nवापस जाएँ और कुंडली चार्ट में किसी भाव पर टैप करके विश्लेषण बनाएँ, फिर "विश्लेषण प्रोफ़ाइल में सहेजें" दबाएँ।'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                ),
              )
            );
          }

          final interpretations = text.split('\n\n---\n\n');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interpretations.length,
            itemBuilder: (context, index) {
              final interp = interpretations[index].trim();
              if (interp.isEmpty) return const SizedBox.shrink();
              
              final lines = interp.split('\n');
              String title = '${tr('Interpretation', 'विश्लेषण')} ${index + 1}';
              String body = interp;

              if (lines.isNotEmpty) {
                final firstLineIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
                if (firstLineIndex != -1) {
                  final firstLine = lines[firstLineIndex].trim();
                  title = firstLine.replaceAll(RegExp(r'^#+\s*'), '');
                  body = lines.sublist(firstLineIndex + 1).join('\n').trim();
                }
              }
              
              if (body.isEmpty) {
                body = title;
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AiMarkdown(body),
                    ),
                  ],
                ),
              );
            },
          );
          }(),
        );
      },
    );
  }
}
