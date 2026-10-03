import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';

/// Renders AI output (Markdown) with selectable text.
class AiMarkdown extends StatelessWidget {
  final String text;
  const AiMarkdown(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.5),
      ),
    );
  }
}

/// Bottom sheet that asks the configured AI a question and shows the answer,
/// with an option to save it to the profile.
Future<void> showAiSheet(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String prompt,
  int? profileId,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _AiSheet(title: title, prompt: prompt, profileId: profileId),
  );
}

class _AiSheet extends ConsumerStatefulWidget {
  final String title;
  final String prompt;
  final int? profileId;

  const _AiSheet({required this.title, required this.prompt, this.profileId});

  @override
  ConsumerState<_AiSheet> createState() => _AiSheetState();
}

class _AiSheetState extends ConsumerState<_AiSheet> {
  String _text = '';
  String? _error;
  bool _done = false;
  bool _saved = false;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final run = ++_run;
    setState(() {
      _text = '';
      _error = null;
      _done = false;
    });
    try {
      final text = await AiService.interpret(ref.read(settingsProvider), widget.prompt, onPartial: (partial) {
        if (mounted && run == _run) setState(() => _text = partial);
      });
      if (mounted && run == _run) setState(() => _text = text);
    } catch (e) {
      if (mounted && run == _run) setState(() => _error = '$e');
    } finally {
      if (mounted && run == _run) setState(() => _done = true);
    }
  }

  Future<void> _save(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileNotifierProvider.notifier).saveInterpretation(widget.profileId!, '# ${widget.title}\n\n$text');
      setState(() => _saved = true);
      messenger.showSnackBar(const SnackBar(content: Text('Interpretation saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          if (!_done) LinearProgressIndicator(color: scheme.secondary, minHeight: 2),
          const SizedBox(height: 12),
          Expanded(child: SafeArea(top: false, child: _body(scheme))),
        ],
      ),
    );
  }

  Widget _body(ColorScheme scheme) {
    if (_error != null && _text.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.error_outline, color: scheme.error, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _start, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_text.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: scheme.secondary),
            const SizedBox(height: 16),
            Text('Waiting for the AI… reasoning models can take a minute before they start writing.',
                textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AiMarkdown(_text),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
            TextButton(onPressed: _start, child: const Text('Retry')),
          ],
          if (_done && _error == null && widget.profileId != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saved ? null : () => _save(_text),
              icon: Icon(_saved ? Icons.check : Icons.save),
              label: Text(_saved ? 'Saved' : 'Save Interpretation to Profile'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
