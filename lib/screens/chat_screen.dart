import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/chart_summary.dart';
import '../core/database.dart';
import '../core/profile_chart.dart';
import '../providers/profile_provider.dart';
import '../widgets/ai_chat_view.dart';
import 'kundali_screen.dart';
import '../core/l10n.dart';

/// Dashboard "Ask AI" tab: chat with a saved profile's chart as context.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${tr('Error', 'त्रुटि')}: $err')),
        data: (profiles) {
          Profile? selected;
          for (final p in profiles) {
            if (p.id == _selectedId) selected = p;
          }
          selected ??= profiles.isNotEmpty ? profiles.first : null;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  border: Border(bottom: BorderSide(color: scheme.outline)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          hint: Text(tr('No Kundali context', 'कोई कुंडली संदर्भ नहीं')),
                          value: selected?.id,
                          items: [
                            ...profiles.map((p) => DropdownMenuItem<int?>(
                                  value: p.id,
                                  child: Text('${tr('Context', 'संदर्भ')}: ${p.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                )),
                            DropdownMenuItem<int?>(
                              value: -1,
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline, color: scheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(tr('Create New Kundali', 'नई कुंडली बनाएँ'),
                                      style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == -1) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const KundaliScreen(initialTab: 1)));
                            } else {
                              setState(() => _selectedId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AiChatView(
                  // A new key resets the conversation when the profile changes.
                  key: ValueKey(selected?.id),
                  chartContext: selected == null ? null : ChartSummary.describe(selected.computeChart(), name: selected.name),
                  profileId: selected?.id,
                  greeting: selected == null
                      ? tr('Namaste. Create a Kundali to get answers based on your chart, or ask a general question.', 'नमस्ते। अपनी कुंडली पर आधारित उत्तर पाने के लिए कुंडली बनाएँ, या कोई सामान्य प्रश्न पूछें।')
                      : tr('Namaste. Ask me anything about ${selected.name}\'s chart.', 'नमस्ते। ${selected.name} की कुंडली के बारे में कुछ भी पूछें।'),
                  hint: tr('Ask about your Dasha or Gochar...', 'अपनी दशा या गोचर के बारे में पूछें...'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
