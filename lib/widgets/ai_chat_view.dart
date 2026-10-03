import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import 'ai_sheet.dart';

/// Multi-turn chat with the configured AI. [chartContext] (if any) is sent
/// with the first question so the model can refer back to it later.
class AiChatView extends ConsumerStatefulWidget {
  final String? chartContext;
  final int? profileId;
  final String greeting;
  final String hint;

  const AiChatView({
    super.key,
    this.chartContext,
    this.profileId,
    this.greeting = 'Namaste. I am your cosmic guide. Ask me anything about this Kundali.',
    this.hint = 'Ask about career, marriage, dasha...',
  });

  @override
  ConsumerState<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends ConsumerState<AiChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _history = [];
  final List<(bool isUser, String text, bool isError)> _display = [];
  bool _isLoading = false;
  String _streaming = '';

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final content = _history.isEmpty && widget.chartContext != null
        ? 'Chart data:\n${widget.chartContext}\n\nQuestion: $text'
        : text;

    setState(() {
      _display.add((true, text, false));
      _history.add(ChatMessage.user(content));
      _controller.clear();
      _isLoading = true;
    });
    _scrollToEnd();

    try {
      final response = await AiService.chat(ref.read(settingsProvider), List.of(_history), onPartial: (partial) {
        if (!mounted) return;
        final first = _streaming.isEmpty;
        setState(() => _streaming = partial);
        if (first) _scrollToEnd();
      });
      if (!mounted) return;
      setState(() {
        _streaming = '';
        _history.add(ChatMessage.assistant(response));
        _display.add((false, response, false));
      });
    } catch (e) {
      if (!mounted) return;
      // Drop the unanswered question from the history so the next turn stays valid.
      _history.removeLast();
      setState(() {
        if (_streaming.isNotEmpty) _display.add((false, _streaming, false));
        _streaming = '';
        _display.add((false, '$e', true));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToEnd();
    }
  }

  Future<void> _save(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileNotifierProvider.notifier).saveInterpretation(widget.profileId!, text);
      messenger.showSnackBar(const SnackBar(content: Text('Interpretation saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [(false, widget.greeting, false), ..._display, if (_streaming.isNotEmpty) (false, _streaming, false)];
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final (isUser, text, isError) = items[index];
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser ? null : Border.all(color: scheme.outline.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser)
                        Text(text, style: TextStyle(color: scheme.onPrimaryContainer))
                      else if (isError)
                        Text(text, style: TextStyle(color: scheme.error))
                      else
                        AiMarkdown(text),
                      if (!isUser && !isError && index > 0 && widget.profileId != null && !(_isLoading && index == items.length - 1))
                        TextButton.icon(
                          onPressed: () => _save(text),
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text('Save Interpretation', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading) LinearProgressIndicator(color: scheme.secondary, minHeight: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: scheme.surfaceContainerHighest,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: scheme.secondary),
                  onPressed: _isLoading ? null : _sendMessage,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
