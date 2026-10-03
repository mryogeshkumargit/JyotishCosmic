import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/calc_config.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/synthesis_engine.dart';
import '../../core/vedic_math.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/analysis_widgets.dart';

Color _statusColor(PredictionStatus s, ColorScheme scheme) => switch (s) {
      PredictionStatus.natalContradiction || PredictionStatus.insufficientData => scheme.error,
      PredictionStatus.natalPromiseWeak || PredictionStatus.partialConvergence => Colors.orange,
      _ => Colors.green,
    };

Color _markColor(Polarity p, ColorScheme scheme) => switch (p) {
      Polarity.support => Colors.green,
      Polarity.obstruction => scheme.error,
      Polarity.neutral => Colors.orange,
    };

/// Volume 5 predictive synthesis: domain-by-domain evidence, timing windows,
/// rectification/backtesting and the audit log.
class SynthesisScreen extends ConsumerStatefulWidget {
  final ChartData chartData;
  final int? profileId;
  final String? name;
  const SynthesisScreen({super.key, required this.chartData, this.profileId, this.name});

  @override
  ConsumerState<SynthesisScreen> createState() => _SynthesisScreenState();
}

class _SynthesisScreenState extends ConsumerState<SynthesisScreen> {
  late CalcConfig _cfg = ref.read(settingsProvider).calc;
  late SynthesisReport _report = SynthesisEngine.analyse(widget.chartData, cfg: _cfg);

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(settingsProvider.select((s) => s.calc));
    if (!identical(cfg, _cfg)) {
      _cfg = cfg;
      _report = SynthesisEngine.analyse(widget.chartData, cfg: cfg);
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Synthesis'),
          bottom: const TabBar(tabs: [Tab(text: 'Domains'), Tab(text: 'Rectify'), Tab(text: 'Audit')]),
        ),
        body: TabBarView(children: [
          _DomainsTab(report: _report, profileId: widget.profileId, name: widget.name),
          _RectifyTab(chart: widget.chartData, cfg: cfg),
          _AuditTab(report: _report),
        ]),
      ),
    );
  }
}

class _LayerStrip extends StatelessWidget {
  final DomainSynthesis d;
  const _LayerStrip(this.d);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(spacing: 4, runSpacing: 4, children: [
      for (final l in EvidenceLayer.values)
        () {
          final items = d.layer(l);
          final sup = items.any((e) => e.polarity == Polarity.support);
          final obs = items.any((e) => e.polarity == Polarity.obstruction);
          final color = items.isEmpty ? scheme.outline : (sup && !obs ? Colors.green : (sup ? Colors.orange : (obs ? scheme.error : scheme.outline)));
          return Pill('${l.level} ${items.isEmpty ? '–' : (sup && !obs ? '✓' : (sup ? '△' : (obs ? '✗' : '△')))}', color);
        }(),
    ]);
  }
}

class _DomainsTab extends StatelessWidget {
  final SynthesisReport report;
  final int? profileId;
  final String? name;
  const _DomainsTab({required this.report, this.profileId, this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
          'Prediction = natal promise × strength × Daśā activation × transit × context. Each domain shows which evidence layers are present: '
          'A natal, B strength, C Daśā, D transit, E Varga, F Ashtakavarga. These are technical evidence states, not guaranteed events.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        if (report.running.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Current Daśā: ${report.running.map((l) => VedicMath.planets[l]!.name).join(' / ')}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
        for (final f in report.inputFlags.where((f) => f.severity != 'info'))
          BulletLine(f.message, mark: '⚠', color: f.severity == 'critical' ? scheme.error : Colors.orange),
        const SizedBox(height: 8),
        for (final d in report.domains)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DomainDetailScreen(report: report, domain: d, profileId: profileId, name: name))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(d.domain.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    const Icon(Icons.chevron_right),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Pill(d.primaryStatus.code, _statusColor(d.primaryStatus, scheme)),
                    if (d.statuses.contains(PredictionStatus.timingActive)) Pill('TIMING_ACTIVE', scheme.primary),
                  ]),
                  const SizedBox(height: 6),
                  _LayerStrip(d),
                  const SizedBox(height: 6),
                  Text(d.interpretation, style: const TextStyle(fontSize: 13, height: 1.35)),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

/// One domain in the "no black box" layout (Volume 5 §36, §48).
class DomainDetailScreen extends ConsumerWidget {
  final SynthesisReport report;
  final DomainSynthesis domain;
  final int? profileId;
  final String? name;
  const DomainDetailScreen({super.key, required this.report, required this.domain, this.profileId, this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final d = domain;
    String state(EvidenceLayer l) {
      final items = d.layer(l);
      if (items.isEmpty) return 'absent';
      final sup = items.where((e) => e.polarity == Polarity.support).length;
      final obs = items.where((e) => e.polarity == Polarity.obstruction).length;
      if (sup > 0 && obs == 0) return 'supported';
      if (sup > 0) return 'partial';
      if (obs > 0) return 'obstructed';
      return 'not strongly activated';
    }

    return Scaffold(
      appBar: AppBar(title: Text(d.domain.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          SectionCard(
            title: 'Result',
            subtitle: 'Houses ${d.domain.bhavas.join(', ')} · karakas ${d.domain.karakas.map((k) => VedicMath.planets[k]!.name).join(', ')} · ${d.domain.varga}',
            children: [
              Text(d.interpretation, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 8),
              KeyValueRow('Promise', state(EvidenceLayer.natal)),
              KeyValueRow('Obstruction', d.conflicts.isEmpty ? 'none found' : 'present (${d.conflicts.length})'),
              KeyValueRow('Timing', state(EvidenceLayer.dasha)),
              KeyValueRow('Transit', state(EvidenceLayer.transit)),
              KeyValueRow('Varga', state(EvidenceLayer.varga)),
              KeyValueRow('Source tier', d.tier.label),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final st in d.statuses) Pill(st.code, _statusColor(st, scheme)),
                Pill(d.tier.code, scheme.secondary),
              ]),
              const SizedBox(height: 6),
              KeyValueRow('Dimensions', d.domain.dimensions.join(', ')),
            ],
          ),
          for (final l in EvidenceLayer.values)
            if (d.layer(l).isNotEmpty)
              SectionCard(
                title: '${l.level}. ${l.label}',
                children: [
                  for (final e in d.layer(l))
                    BulletLine('${e.text}  [${e.tier.code}; ${e.rule}]', mark: e.mark, color: _markColor(e.polarity, scheme), tag: e.id),
                ],
              ),
          SectionCard(
            title: 'Bhāva-lord chains',
            subtitle: 'Bhāva → lord → lord\'s sign → dispositor → dispositor\'s house and strength',
            children: [for (final c in d.lordChains) BulletLine(c, mark: '→')],
          ),
          SectionCard(
            title: 'Event windows',
            subtitle: 'Antardaśās in the next 15 years whose lords activate this domain, with Pratyantardaśā peaks. Windows, not dates.',
            children: [
              if (d.windows.isEmpty) const BulletLine('No strongly activating period found in the next 15 years.'),
              for (final w in d.windows.take(8)) ...[
                Text('${w.label}: ${w.start} – ${w.end}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                for (final f in w.factors) BulletLine(f),
                if (w.peakPeriods.isNotEmpty) BulletLine('Peaks: ${w.peakPeriods.take(3).join('; ')}', mark: '◆'),
                const SizedBox(height: 6),
              ],
            ],
          ),
          SectionCard(
            title: 'Slow-planet contacts (next 3 years)',
            children: [
              if (d.transits.isEmpty) const BulletLine('Jupiter and Saturn do not enter this house sign in the next three years.'),
              for (final t in d.transits) BulletLine('${t.date}: ${t.note}${t.retrogradeRecontact ? ' (retrograde re-contact)' : ''}', mark: '→'),
            ],
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy report'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: d.report()));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied')));
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Ask AI to write it up'),
              onPressed: () {
                final prompt = 'Write a ${d.domain.name.toLowerCase()} reading from the evidence trace below, produced by a rule-based Jyotisha engine. '
                    'Rules: use only this evidence; cite the rule IDs (R1, R2...) for each statement; keep supporting and obstructing factors visible; '
                    'separate natal promise, Daśā timing and transit confirmation; never claim an event will definitely happen; '
                    'label systematic synthesis as such. ${d.domain.caution ?? ''}\n\n${d.report()}\n\nLord chains:\n${d.lordChains.join('\n')}\n\n'
                    'Event windows:\n${d.windows.take(5).map((w) => '${w.label} ${w.start}-${w.end}: ${w.factors.join('; ')}').join('\n')}\n\n'
                    'Chart:\n${ChartSummary.describe(report.chart, name: name)}';
                showAiSheet(context, ref, title: d.domain.name, prompt: prompt, profileId: profileId);
              },
            ),
          ]),
        ],
      ),
    );
  }
}

class _RectifyTab extends StatefulWidget {
  final ChartData chart;
  final CalcConfig cfg;
  const _RectifyTab({required this.chart, required this.cfg});

  @override
  State<_RectifyTab> createState() => _RectifyTabState();
}

class _RectifyTabState extends State<_RectifyTab> {
  final List<LifeEvent> _events = [];
  int _range = 30;
  int _step = 5;
  List<RectificationCandidate>? _candidates;
  List<BacktestResult>? _backtests;

  Future<void> _addEvent() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 5),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final domainId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('What kind of event?', style: TextStyle(fontWeight: FontWeight.bold))),
          for (final d in SynthesisEngine.domains) ListTile(title: Text(d.name), onTap: () => Navigator.pop(ctx, d.id)),
        ]),
      ),
    );
    if (domainId == null) return;
    setState(() {
      _events.add(LifeEvent(date, domainId));
      _candidates = null;
      _backtests = null;
    });
  }

  void _run() {
    final c = widget.chart;
    setState(() {
      _backtests = [for (final e in _events) SynthesisEngine.backtest(c, e, cfg: widget.cfg)];
      _candidates = SynthesisEngine.rectify(
        (m) => Ephemeris.computeChartForJd(c.jd + m / 1440, c.lat, c.lon, utcOffset: c.utcOffset),
        _events,
        rangeMinutes: _range,
        stepMinutes: _step,
        cfg: widget.cfg,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final best = _candidates == null || _candidates!.isEmpty ? null : _candidates!.map((c) => c.score).reduce((a, b) => a > b ? a : b);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
          'Enter known life events to test the chart (backtesting) and compare candidate birth times (rectification). '
          'Each candidate recomputes the Lagna, Vargas and Daśā balance. The saved birth time is never changed.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _events.length; i++)
          Card(
            child: ListTile(
              dense: true,
              title: Text(SynthesisEngine.domain(_events[i].domainId).name),
              subtitle: Text('${_events[i].date.year}-${_events[i].date.month.toString().padLeft(2, '0')}-${_events[i].date.day.toString().padLeft(2, '0')}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() {
                  _events.removeAt(i);
                  _candidates = null;
                  _backtests = null;
                }),
              ),
            ),
          ),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _addEvent, icon: const Icon(Icons.add), label: const Text('Add a known event'))),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _range,
              decoration: const InputDecoration(labelText: 'Range ±'),
              items: [for (final v in const [10, 30, 60, 120]) DropdownMenuItem(value: v, child: Text('$v min'))],
              onChanged: (v) => setState(() => _range = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _step,
              decoration: const InputDecoration(labelText: 'Step'),
              items: [for (final v in const [2, 5, 10, 15]) DropdownMenuItem(value: v, child: Text('$v min'))],
              onChanged: (v) => setState(() => _step = v!),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _events.isEmpty ? null : _run, child: const Text('Test events and candidate times')),
        if (_backtests != null) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Backtest at the saved birth time',
            subtitle: 'Natal rules are known before the event; only timing is evaluated at the event date.',
            children: [
              for (final b in _backtests!) ...[
                BulletLine(
                  '${SynthesisEngine.domain(b.event.domainId).name} (${b.event.date.year}-${b.event.date.month.toString().padLeft(2, '0')}): Daśā ${b.periods.join(', ')} — '
                  '${b.expectedDomainActivated ? 'domain activated by both MD and AD' : 'not activated by both MD and AD'}',
                  mark: b.expectedDomainActivated ? '✓' : '✗',
                  color: b.expectedDomainActivated ? Colors.green : scheme.error,
                ),
                for (final t in b.trace) Padding(padding: const EdgeInsets.only(left: 20), child: BulletLine(t)),
              ],
            ],
          ),
        ],
        if (_candidates != null)
          SectionCard(
            title: 'Candidate birth times',
            subtitle: 'Consistency score: +1 MD, +1.5 AD, +0.5 PD lord activating the event\'s domain. A heuristic, not a classical rule.',
            children: [
              for (final c in _candidates!)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('${c.offsetMinutes == 0 ? 'Saved time' : '${c.offsetMinutes > 0 ? '+' : ''}${c.offsetMinutes} min'} · ${VedicMath.rashis[c.chart.lagnaRashi].name} Lagna',
                      style: TextStyle(fontWeight: c.score == best ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text('Score ${c.score.toStringAsFixed(1)}${c.score == best ? ' (highest)' : ''}', style: const TextStyle(fontSize: 12)),
                  children: [for (final d in c.details) BulletLine(d)],
                ),
            ],
          ),
      ],
    );
  }
}

class _AuditTab extends StatelessWidget {
  final SynthesisReport report;
  const _AuditTab({required this.report});

  String _json() => const JsonEncoder.withIndent('  ').convert({
        'audit': report.audit,
        'input_flags': [for (final f in report.inputFlags) {'severity': f.severity, 'message': f.message}],
        'predictions': [
          for (final d in report.domains)
            {
              'domain': d.domain.name,
              'target_bhavas': d.domain.bhavas,
              'status': d.statuses.map((s) => s.code).toList(),
              'source_tier': d.tier.code,
              'rule_trace': [for (final e in d.evidence) '${e.id} ${e.layer.level} ${e.mark} ${e.text} [${e.rule}]'],
              'interpretation': d.interpretation,
            },
        ],
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        SectionCard(
          title: 'Input quality',
          children: [
            for (final f in report.inputFlags)
              BulletLine(f.message,
                  mark: f.severity == 'info' ? 'ℹ' : '⚠', color: f.severity == 'critical' ? scheme.error : (f.severity == 'warning' ? Colors.orange : scheme.secondary)),
          ],
        ),
        SectionCard(
          title: 'Audit log',
          subtitle: 'Everything needed to reproduce these results.',
          children: [for (final e in report.audit.entries) KeyValueRow(e.key.replaceAll('_', ' '), e.value)],
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy audit log and rule traces (JSON)'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _json()));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audit log copied')));
          },
        ),
      ],
    );
  }
}
