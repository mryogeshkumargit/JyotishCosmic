import 'package:flutter/material.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../widgets/ai_chat_view.dart';
import '../../core/l10n.dart';

class AiChatScreen extends StatelessWidget {
  final ChartData chartData;
  final int? profileId;
  final String? name;

  const AiChatScreen({super.key, required this.chartData, this.profileId, this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Ask AI', 'AI से पूछें'))),
      body: AiChatView(
        chartContext: ChartSummary.describe(chartData, name: name),
        profileId: profileId,
      ),
    );
  }
}
