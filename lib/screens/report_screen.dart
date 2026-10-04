import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/chart_summary.dart';
import '../core/database.dart';
import '../core/profile_chart.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import '../widgets/ai_sheet.dart';
import '../core/l10n.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isLoading = false;
  String? _resultText;
  String? _error;
  int? _selectedId;
  bool _exporting = false;

  Future<void> _generateFullReport(Profile profile) async {
    setState(() {
      _isLoading = true;
      _resultText = null;
      _error = null;
    });

    final prompt = 'Generate a comprehensive, premium Vedic Astrology Life Report for ${profile.name}. '
        'Include sections on: 1. Personality & Life Path, 2. Career & Finance, 3. Love & Relationships, '
        '4. Health & Vitality, 5. Current and upcoming Dasha periods, 6. Spiritual Journey & Karmic Lessons, 7. Remedies. '
        'Format it as a professional Markdown document with headings.\n\n'
        '${ChartSummary.describe(profile.computeChart(), name: profile.name)}';

    try {
      final response = await AiService.interpret(ref.read(settingsProvider), prompt, onPartial: (partial) {
        if (mounted) setState(() => _resultText = partial);
      });
      if (mounted) setState(() => _resultText = response);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf(Profile profile) async {
    setState(() => _exporting = true);
    try {
      await PdfService().shareMarkdownReport(title: tr('Vedic Life Report', 'वैदिक जीवन रिपोर्ट'), name: profile.name, markdown: _resultText!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('PDF export failed', 'PDF निर्यात विफल')}: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);
    final scheme = Theme.of(context).colorScheme;

    return profilesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('${tr('Error', 'त्रुटि')}: $err'))),
      data: (profiles) {
        Profile? active;
        for (final p in profiles) {
          if (p.id == _selectedId) active = p;
        }
        active ??= profiles.isNotEmpty ? profiles.first : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('Premium Report', 'विस्तृत रिपोर्ट')),
            actions: [
              if (_resultText != null && !_isLoading && active != null)
                IconButton(
                  icon: _exporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download),
                  tooltip: tr('Export PDF', 'PDF निर्यात'),
                  onPressed: _exporting ? null : () => _exportPdf(active!),
                ),
            ],
          ),
          body: active == null
              ? Center(child: Text(tr('Create a profile to generate a report.', 'रिपोर्ट बनाने के लिए एक प्रोफ़ाइल बनाएँ।')))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: InputDecoration(labelText: tr('Profile', 'प्रोफ़ाइल')),
                      initialValue: active.id,
                      items: profiles.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: _isLoading
                          ? null
                          : (id) => setState(() {
                                _selectedId = id;
                                _resultText = null;
                                _error = null;
                              }),
                    ),
                    const SizedBox(height: 24),
                    if (_resultText == null && !_isLoading) ...[
                      Icon(Icons.picture_as_pdf, size: 80, color: scheme.secondary),
                      const SizedBox(height: 24),
                      Text(tr('Generate a 360° comprehensive Vedic Life Report for ${active.name}.', '${active.name} के लिए 360° विस्तृत वैदिक जीवन रिपोर्ट बनाएँ।'),
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _generateFullReport(active!),
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(tr('Generate Report', 'रिपोर्ट बनाएँ')),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: scheme.error), textAlign: TextAlign.center),
                      ],
                    ],
                    if (_isLoading && _resultText == null)
                      Padding(
                        padding: EdgeInsets.all(48),
                        child: Column(children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(tr('Writing your report… long reports can take a few minutes.', 'आपकी रिपोर्ट लिखी जा रही है… लंबी रिपोर्ट में कुछ मिनट लग सकते हैं।'), textAlign: TextAlign.center),
                        ]),
                      ),
                    if (_isLoading && _resultText != null) const LinearProgressIndicator(minHeight: 2),
                    if (_resultText != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.secondary.withValues(alpha: 0.5)),
                        ),
                        child: AiMarkdown(_resultText!),
                      ),
                    if (_resultText != null && _error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: scheme.error)),
                    ],
                    if (_resultText != null && !_isLoading) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _generateFullReport(active!),
                          icon: const Icon(Icons.refresh),
                          label: Text(tr('Generate again', 'फिर से बनाएँ')),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
