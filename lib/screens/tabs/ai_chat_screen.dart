import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ephemeris.dart';
import '../../providers/settings_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final ChartData chartData;
  final int? profileId;

  const AiChatScreen({super.key, required this.chartData, this.profileId});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Namaste. I am your cosmic guide. Ask me anything about this Kundali.'},
  ];
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isLoading = true;
    });

    final prompt = "User asks: $text\n\nAstrological Chart Data Context:\n"
        "Ascendant: ${widget.chartData.ascendantSidereal}\n"
        "Planets: ${widget.chartData.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n"
        "Provide a detailed Vedic astrological interpretation addressing the user's question.";

    try {
      final response = await AiService.interpret(ref.read(settingsProvider), prompt);
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Error fetching response: \$e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInterpretation(String text) async {
    if (widget.profileId != null) {
      try {
        await ref.read(profileNotifierProvider.notifier).saveInterpretation(widget.profileId!, text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interpretation Saved')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            msg['text']!,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        if (!isUser && widget.profileId != null && index > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8, right: 8),
                            child: TextButton.icon(
                              onPressed: () => _saveInterpretation(msg['text']!),
                              icon: const Icon(Icons.save, size: 16),
                              label: const Text('Save Interpretation', style: TextStyle(fontSize: 12)),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
            ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Ask about career, marriage, etc...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary),
              onPressed: _sendMessage,
            )
          ],
        ),
      ),
    );
  }
}
