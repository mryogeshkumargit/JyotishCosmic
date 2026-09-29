import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/profile_provider.dart';
import '../services/ai_service.dart';
import '../core/ephemeris.dart';
import '../core/database.dart';
import 'kundali_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Namaste. I am your cosmic guide. Ask me anything about your astrological charts.'},
  ];
  bool _isLoading = false;
  Profile? _selectedProfile;
  bool _initialized = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isLoading = true;
    });

    final settings = ref.read(settingsProvider);
    String contextPrompt = '';
    
    if (_selectedProfile != null) {
      final profile = _selectedProfile!;
      final chartData = Ephemeris.computeChart(
        profile.dob.year,
        profile.dob.month,
        profile.dob.day,
        profile.dob.hour.toDouble(),
        profile.dob.minute.toDouble(),
        profile.lat,
        profile.lon,
        profile.timezone,
      );
      
      contextPrompt = "User Profile Context (Name: ${profile.name}):\n"
          "Ascendant: ${chartData.ascendantSidereal}\n"
          "Planets: ${chartData.planetLongitudes.entries.map((e) => '${e.key}: ${e.value}').join(', ')}\n\n";
    }

    final fullPrompt = "User asks: $text\n\n$contextPrompt"
        "Provide a detailed Vedic astrological interpretation addressing the user's question.";

    try {
      final response = await AiService.interpret(settings, fullPrompt);
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Error fetching response: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);

    return Column(
      children: [
        profilesAsync.when(
          data: (profiles) {
            if (!_initialized && profiles.isNotEmpty) {
              _selectedProfile = profiles.first;
              _initialized = true;
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Profile?>(
                        isExpanded: true,
                        hint: const Text('Select Kundali Context'),
                        value: _selectedProfile,
                        icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                        items: [
                          ...profiles.map((p) => DropdownMenuItem<Profile?>(
                                value: p,
                                child: Text('Context: ${p.name}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                              )),
                          DropdownMenuItem<Profile?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Create New Kundali', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == null) {
                            // Navigate to Kundali creation
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const KundaliScreen()));
                          } else {
                            setState(() {
                              _selectedProfile = val;
                              _messages.add({'role': 'ai', 'text': 'Context switched to ${val.name}. How can I assist you with this chart?'});
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => const SizedBox(),
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser ? null : Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Text(
                    msg['text']!,
                    style: TextStyle(color: isUser ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Ask about your Dasha or Gochar...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
            onPressed: _sendMessage,
          )
        ],
      ),
    );
  }
}
