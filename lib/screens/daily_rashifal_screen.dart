import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import '../core/l10n.dart';
import '../core/rashifal/rashifal_models.dart';
import '../providers/profile_provider.dart';
import '../providers/rashifal_provider.dart';
import '../providers/settings_provider.dart';
import '../services/rashifal_pdf.dart';
import '../widgets/analysis_widgets.dart';
import 'rashifal_history_screen.dart';
import 'rashifal_settings_screen.dart';

/// Colour that represents a rating, readable on light and dark themes.
Color ratingColor(BuildContext context, DayRating? r) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (r) {
    DayRating.good => dark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
    DayRating.average => dark ? const Color(0xFFFFCA28) : const Color(0xFFB26A00),
    DayRating.bad => dark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
    null => Theme.of(context).colorScheme.secondary,
  };
}

const Map<String, IconData> _icons = {
  'overall': Icons.wb_sunny_outlined,
  'family': Icons.family_restroom,
  'marriage': Icons.favorite_outline,
  'health': Icons.health_and_safety_outlined,
  'career': Icons.work_outline,
  'mind': Icons.self_improvement,
  'finance': Icons.account_balance_wallet_outlined,
  'social': Icons.groups_outlined,
  'muhurat': Icons.schedule,
  'travel': Icons.flight_takeoff,
  'financeDecisions': Icons.trending_up,
  'unexpected': Icons.bolt_outlined,
  'mantra': Icons.record_voice_over_outlined,
  'upay': Icons.spa_outlined,
  'donation': Icons.volunteer_activism_outlined,
  'colour': Icons.palette_outlined,
  'dosDonts': Icons.checklist,
};

/// Detailed daily Rashifal of one Kundali: opened from the morning
/// notification, the dashboard, the Rashifal screen or the saved history.
class DailyRashifalScreen extends ConsumerStatefulWidget {
  final int? profileId;
  final DateTime? date;

  /// Opens this saved report exactly as stored.
  final int? reportId;

  const DailyRashifalScreen({super.key, this.profileId, this.date, this.reportId});

  @override
  ConsumerState<DailyRashifalScreen> createState() => _DailyRashifalScreenState();
}

class _DailyRashifalScreenState extends ConsumerState<DailyRashifalScreen> {
  int? _profileId;
  late DateTime _date;
  DailyRashifalReport? _report;
  bool _loading = true;
  String? _error;
  bool _aiRunning = false;
  int _aiChars = 0;
  String? _aiError;
  bool _exporting = false;
  final Set<String> _autoAiTried = {};

  @override
  void initState() {
    super.initState();
    _profileId = widget.profileId;
    final d = widget.date ?? DateTime.now();
    _date = DateTime(d.year, d.month, d.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reportId: widget.reportId));
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<Profile?> _profile() async {
    final profiles = await ref.read(profileListProvider.future);
    if (profiles.isEmpty) return null;
    final prefs = ref.read(settingsProvider).rashifal;
    final id = _profileId ?? prefs.profileId;
    return profiles.where((p) => p.id == id).firstOrNull ?? profiles.first;
  }

  Future<void> _load({int? reportId, bool recompute = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _aiError = null;
    });
    try {
      await ref.read(settingsProvider.notifier).loaded;
      if (reportId != null) {
        final saved = await ref.read(rashifalRepositoryProvider).loadById(reportId);
        if (saved != null) {
          if (!mounted) return;
          setState(() {
            _report = saved;
            _profileId = saved.profileId;
            _date = saved.date;
            _loading = false;
          });
          return;
        }
      }
      final profile = await _profile();
      if (profile == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      _profileId = profile.id;
      final report = await ref.read(rashifalServiceProvider).open(profile, _date, ref.read(settingsProvider).rashifal, recompute: recompute);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
      _maybeAutoAi(report);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  bool get _aiConfigured {
    final s = ref.read(settingsProvider);
    return s.apiKey.trim().isNotEmpty || s.llmProvider == 'Custom';
  }

  void _maybeAutoAi(DailyRashifalReport r) {
    final s = ref.read(settingsProvider);
    final key = '${r.profileId}|${r.dateKey}';
    if (r.hasAi || !s.rashifal.autoAi || !_aiConfigured || !_sameDay(r.date, DateTime.now()) || _autoAiTried.contains(key)) return;
    _autoAiTried.add(key);
    _runAi();
  }

  Future<void> _runAi() async {
    final profile = await _profile();
    if (profile == null || _aiRunning) return;
    setState(() {
      _aiRunning = true;
      _aiChars = 0;
      _aiError = null;
    });
    try {
      final r = await ref
          .read(rashifalServiceProvider)
          .runAi(
            ref.read(settingsProvider),
            profile,
            _date,
            onProgress: (n) {
              if (mounted) setState(() => _aiChars = n);
            },
          );
      if (mounted && r.profileId == _profileId && r.dateKey == dateKeyOf(_date)) setState(() => _report = r);
    } catch (e) {
      if (mounted) setState(() => _aiError = '$e');
    } finally {
      if (mounted) setState(() => _aiRunning = false);
    }
  }

  void _shiftDay(int days) {
    if (_aiRunning) return;
    setState(() => _date = DateTime(_date.year, _date.month, _date.day + days));
    _load();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1900), lastDate: DateTime(2399, 12, 31));
    if (picked != null && !_aiRunning) {
      setState(() => _date = picked);
      _load();
    }
  }

  Future<void> _exportPdf() async {
    final r = _report;
    if (r == null) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await RashifalPdf.share(r);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('${tr('PDF export failed', 'PDF निर्यात विफल')}: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmRecompute() async {
    final hasAi = _report?.hasAi ?? false;
    final ok =
        !hasAi ||
        await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(tr('Recalculate this day?', 'इस दिन की पुनर्गणना करें?')),
                content: Text(tr('The saved AI analysis of this day will be replaced by a fresh calculation.', 'इस दिन का सहेजा गया AI विश्लेषण नई गणना से बदल जाएगा।')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel', 'रद्द करें'))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Recalculate', 'पुनर्गणना'))),
                ],
              ),
            ) ==
            true;
    if (ok) _load(recompute: true);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profileListProvider).value ?? const <Profile>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Daily Rashifal', 'दैनिक राशिफल')),
        actions: [
          IconButton(
            tooltip: tr('Saved Rashifals', 'सहेजे गए राशिफल'),
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RashifalHistoryScreen())),
          ),
          IconButton(
            tooltip: tr('Download PDF', 'PDF डाउनलोड करें'),
            icon: _exporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _report == null || _exporting ? null : _exportPdf,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const RashifalSettingsScreen()));
              if (v == 'recompute') _confirmRecompute();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'settings', child: Text(tr('Notification settings', 'सूचना सेटिंग्स'))),
              PopupMenuItem(value: 'recompute', child: Text(tr('Recalculate this day', 'इस दिन की पुनर्गणना'))),
            ],
          ),
        ],
      ),
      body: profiles.isEmpty && !_loading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(tr('Create a profile to view your Rashifal.', 'राशिफल देखने के लिए एक प्रोफ़ाइल बनाएँ।'), textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                children: [
                  _controls(profiles),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_loading && _error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  if (!_loading && _report != null) ..._content(_report!),
                ],
              ),
            ),
    );
  }

  Widget _controls(List<Profile> profiles) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = _sameDay(_date, DateTime.now());
    return Column(
      children: [
        if (profiles.length > 1)
          DropdownButtonFormField<int>(
            key: ValueKey('profile-$_profileId'),
            initialValue: profiles.any((p) => p.id == _profileId) ? _profileId : profiles.first.id,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr('Kundali', 'कुंडली'), isDense: true),
            items: [
              for (final p in profiles)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _aiRunning
                ? null
                : (v) {
                    setState(() => _profileId = v);
                    _load();
                  },
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(onPressed: _aiRunning ? null : () => _shiftDay(-1), icon: const Icon(Icons.chevron_left), tooltip: tr('Previous day', 'पिछला दिन')),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        '${L10n.weekday(_date.weekday)}, ${_date.day} ${L10n.month(_date.month)} ${_date.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (isToday) Text(tr('Today', 'आज'), style: TextStyle(color: scheme.secondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(onPressed: _aiRunning ? null : () => _shiftDay(1), icon: const Icon(Icons.chevron_right), tooltip: tr('Next day', 'अगला दिन')),
          ],
        ),
      ],
    );
  }

  List<Widget> _content(DailyRashifalReport r) {
    final overall = r.areas.firstWhere((a) => a.key == 'overall', orElse: () => r.areas.first);
    return [
      _Hero(report: r),
      const SizedBox(height: 12),
      _aiBar(r),
      if (r.aiSummary != null)
        SectionCard(
          title: tr('AI overview', 'AI सारांश'),
          children: [Text(r.aiSummary!, style: const TextStyle(height: 1.45))],
        ),
      _heading(tr('Your day', 'आपका दिन'), Icons.today),
      _SectionTile(section: overall, initiallyExpanded: true),
      for (final s in r.areas.where((a) => a.key != 'overall')) _SectionTile(section: s),
      _heading(tr('Also today', 'आज यह भी'), Icons.explore_outlined),
      for (final s in r.outlook) s.key == 'muhurat' ? _MuhuratCard(section: s) : _SectionTile(section: s),
      _heading(tr('Remedies & guidance', 'उपाय और मार्गदर्शन'), Icons.spa_outlined),
      for (final s in r.remedies) _RemedyCard(section: s),
      _heading(tr('Daily planetary & astrological analysis', 'दैनिक ग्रह और ज्योतिषीय विश्लेषण'), Icons.public),
      for (final (i, a) in r.analysis.indexed) _AnalysisTile(index: i + 1, block: a),
      const SizedBox(height: 16),
      Text(
        tr(
          'Calculated on this device with the Swiss Ephemeris for ${r.placeName}. Scores weigh classical factors (Chandra Bala, Tara Bala, Gochar, Ashtakavarga, Dasha, Panchang) with a transparent heuristic; muhurats, remedies and colours follow common tradition. Saved ${_stamp(r.generatedAt)}${r.hasAi ? ' · AI: ${r.aiModel}' : ''}.',
          '${r.placeName} के लिए स्विस एफ़ेमेरिस से इसी डिवाइस पर गणना। अंक शास्त्रीय कारकों (चन्द्र बल, तारा बल, गोचर, अष्टकवर्ग, दशा, पंचांग) को एक पारदर्शी पद्धति से तौलते हैं; मुहूर्त, उपाय और रंग प्रचलित परंपरा पर आधारित हैं। सहेजा गया ${_stamp(r.generatedAt)}${r.hasAi ? ' · AI: ${r.aiModel}' : ''}।',
        ),
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ];
  }

  static String _stamp(DateTime t) => '${t.day} ${L10n.month(t.month)} ${t.year}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _heading(String text, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Icon(icon, color: scheme.secondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.secondary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiBar(DailyRashifalReport r) {
    final scheme = Theme.of(context).colorScheme;
    if (_aiRunning) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('AI is analysing your chart, transits, dasha and Panchang…', 'AI आपकी कुंडली, गोचर, दशा और पंचांग का विश्लेषण कर रहा है…'), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              if (_aiChars > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(tr('$_aiChars characters received', '$_aiChars अक्षर प्राप्त'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(r.hasAi ? Icons.auto_awesome : Icons.memory, color: scheme.secondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.hasAi
                        ? tr('Interpreted by AI (${r.aiModel})', 'AI द्वारा व्याख्या (${r.aiModel})')
                        : tr('On-device analysis. Ask the AI for a deeper, personalised reading.', 'डिवाइस पर विश्लेषण। गहरी, व्यक्तिगत व्याख्या के लिए AI से पूछें।'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (!_aiConfigured) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(tr('Add your AI provider and API key in Settings > AI first.', 'पहले सेटिंग्स > AI में अपना AI प्रदाता और API कुंजी जोड़ें।'))));
                      return;
                    }
                    _runAi();
                  },
                  icon: Icon(r.hasAi ? Icons.refresh : Icons.auto_awesome, size: 18),
                  label: Text(r.hasAi ? tr('Regenerate', 'फिर से') : tr('AI analysis', 'AI विश्लेषण')),
                ),
              ],
            ),
            if (_aiError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_aiError!, style: TextStyle(color: scheme.error, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final DailyRashifalReport report;
  const _Hero({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ratingColor(context, report.rating);
    final gochar = report.analysis.where((a) => a.key == 'gochar').firstOrNull;
    final moon = gochar != null && gochar.table.length > 2 ? gochar.table[2][1] : null;
    final panchang = report.analysis.where((a) => a.key == 'panchang').firstOrNull;
    String cell(int row) => panchang != null && panchang.table.length > row ? panchang.table[row][1] : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.28), scheme.surfaceContainerHighest], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(value: report.score / 100, strokeWidth: 8, color: color, backgroundColor: scheme.outline.withValues(alpha: 0.2)),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${report.score}',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                        ),
                        Text('/100', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.profileName,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tr('${report.rating.label} day', '${report.rating.label} दिन'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(report.notificationLine1, style: const TextStyle(fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(report.headline, style: const TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (moon != null) Pill('${tr('Moon', 'चन्द्र')}: $moon', scheme.secondary),
              if (cell(3).isNotEmpty) Pill('${tr('Nakshatra', 'नक्षत्र')}: ${cell(3)}', scheme.secondary),
              if (cell(1).isNotEmpty) Pill('${tr('Tithi', 'तिथि')}: ${cell(1)}', scheme.secondary),
              Pill(report.placeName, scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreBar(this.score, this.color);

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(value: score / 100, minHeight: 6, color: color, backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
  );
}

class _SectionTile extends StatelessWidget {
  final RashifalSection section;
  final bool initiallyExpanded;
  const _SectionTile({required this.section, this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ratingColor(context, section.rating);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icons[section.key] ?? Icons.circle_outlined, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(section.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                if (section.rating != null) Pill('${section.rating!.label}${section.score == null ? '' : ' · ${section.score}'}', color),
              ],
            ),
            if (section.score != null) ...[const SizedBox(height: 8), _ScoreBar(section.score!, color)],
            const SizedBox(height: 8),
            Text(section.text, style: const TextStyle(height: 1.45)),
            if (section.factors.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: initiallyExpanded,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(tr('Why (astrological factors)', 'क्यों (ज्योतिषीय कारण)'), style: TextStyle(fontSize: 13, color: scheme.secondary)),
                  children: [
                    for (final f in section.factors)
                      BulletLine(f.substring(1).trim(), mark: f.startsWith('+') ? '▲' : '▼', color: f.startsWith('+') ? ratingColor(context, DayRating.good) : ratingColor(context, DayRating.bad)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MuhuratCard extends StatelessWidget {
  final RashifalSection section;
  const _MuhuratCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final good = ratingColor(context, DayRating.good), bad = ratingColor(context, DayRating.bad);
    Widget row(String s, Color c, IconData icon) {
      final i = s.indexOf(':');
      final name = i < 0 ? s : s.substring(0, i);
      final rest = i < 0 ? '' : s.substring(i + 1).trim();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$name  ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: rest),
                  ],
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icons['muhurat'], color: good, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(section.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(section.text, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 8),
            for (final s in section.items) row(s, good, Icons.check_circle_outline),
            const Divider(),
            for (final s in section.items2) row(s, bad, Icons.block),
          ],
        ),
      ),
    );
  }
}

class _RemedyCard extends StatelessWidget {
  final RashifalSection section;
  const _RemedyCard({required this.section});

  static Color? _hex(String? s) {
    if (s == null || !s.startsWith('#') || s.length != 7) return null;
    final v = int.tryParse(s.substring(1), radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final good = ratingColor(context, DayRating.good), bad = ratingColor(context, DayRating.bad);
    final children = <Widget>[];
    switch (section.key) {
      case 'mantra':
        children.addAll([
          if (section.extra['devanagari'] != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SelectableText(
                    section.extra['devanagari']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 18, color: scheme.secondary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    section.extra['transliteration'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),
          Text(section.text, style: const TextStyle(height: 1.45)),
          for (final s in section.items.skip(section.extra['devanagari'] != null ? 2 : 0)) BulletLine(s),
        ]);
      case 'colour':
        final c = _hex(section.extra['hex']);
        final avoid = _hex(section.extra['avoidHex']);
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c != null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outline),
                  ),
                ),
              if (avoid != null) ...[
                const SizedBox(width: 6),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: avoid,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outline),
                      ),
                    ),
                    Icon(Icons.close, size: 18, color: bad),
                  ],
                ),
              ],
              const SizedBox(width: 12),
              Expanded(child: Text(section.text, style: const TextStyle(height: 1.45))),
            ],
          ),
        );
      case 'dosDonts':
        children.addAll([
          Text(section.text, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            tr('Do', 'करें'),
            style: TextStyle(color: good, fontWeight: FontWeight.bold),
          ),
          for (final s in section.items) BulletLine(s, mark: '✓', color: good),
          const SizedBox(height: 6),
          Text(
            tr('Don\'t', 'न करें'),
            style: TextStyle(color: bad, fontWeight: FontWeight.bold),
          ),
          for (final s in section.items2) BulletLine(s, mark: '✗', color: bad),
        ]);
      default:
        children.addAll([
          Text(section.text, style: const TextStyle(height: 1.45)),
          for (final s in section.items) BulletLine(s),
          if (section.extra['deity'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${tr('Deity', 'देवता')}: ${section.extra['deity']}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
        ]);
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icons[section.key] ?? Icons.spa_outlined, color: scheme.secondary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(section.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final int index;
  final AnalysisBlock block;
  const _AnalysisTile({required this.index, required this.block});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: scheme.secondary.withValues(alpha: 0.15),
            child: Text(
              '$index',
              style: TextStyle(fontSize: 12, color: scheme.secondary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(block.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            block.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(block.summary, style: const TextStyle(height: 1.45)),
            if (block.table.length > 1) ...[const SizedBox(height: 10), CompactTable(header: block.table.first, rows: block.table.skip(1).toList(), minColumnWidth: 70)],
            if (block.points.isNotEmpty) const SizedBox(height: 8),
            for (final p in block.points) BulletLine(p),
          ],
        ),
      ),
    );
  }
}
