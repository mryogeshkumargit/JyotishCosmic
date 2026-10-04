import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/calc_config.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/knowledge_registry.dart';
import '../../core/l10n.dart';
import '../../core/plain/interpret.dart';
import '../../core/plain/meanings.dart';
import '../../core/synthesis_engine.dart';
import '../../core/timing_math.dart';
import '../../core/vedic_math.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_service.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/analysis_widgets.dart';

Color _statusColor(PredictionStatus s, ColorScheme scheme) => switch (s) {
      PredictionStatus.natalContradiction || PredictionStatus.insufficientData => scheme.error,
      PredictionStatus.natalPromiseWeak || PredictionStatus.partialConvergence => Colors.orange,
      _ => Colors.green,
    };

Color _v6Color(V6Status s, ColorScheme scheme) => switch (s) {
      V6Status.conflicted || V6Status.insufficientData || V6Status.notSupported => scheme.error,
      V6Status.natalPromise || V6Status.supported => Colors.orange,
      _ => Colors.green,
    };

Color _confColor(Confidence c, ColorScheme scheme) => switch (c) {
      Confidence.conflicted || Confidence.insufficient => scheme.error,
      Confidence.low => scheme.outline,
      Confidence.moderate => Colors.orange,
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
  String _lang = L10n.lang;

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(settingsProvider.select((s) => s.calc));
    if (!identical(cfg, _cfg) || _lang != L10n.lang) {
      _cfg = cfg;
      _lang = L10n.lang;
      _report = SynthesisEngine.analyse(widget.chartData, cfg: cfg);
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('Synthesis', 'संश्लेषण')),
          bottom: TabBar(tabs: [
            Tab(text: tr('Domains', 'क्षेत्र')),
            Tab(text: tr('Timing', 'समय')),
            Tab(text: tr('Rectify', 'शोधन')),
            Tab(text: tr('Audit', 'ऑडिट')),
          ]),
        ),
        body: TabBarView(children: [
          _DomainsTab(report: _report, profileId: widget.profileId, name: widget.name),
          _TimingTab(report: _report),
          _RectifyTab(chart: widget.chartData, cfg: cfg, sensitivity: _report.sensitivity),
          _AuditTab(report: _report, name: widget.name),
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
        SimpleMeaningCard([
          tr('This page combines everything in your chart for each area of life: what the birth chart promises, how strong the planets are, '
              'whether your current planetary period (Daśā) switches it on, and whether today\'s planet movements (transits) confirm it. '
              'Tap any area for a plain explanation and the full evidence.',
              'यह पृष्ठ जीवन के हर क्षेत्र के लिए आपकी कुंडली की सारी बातें जोड़ता है: जन्म कुंडली क्या वादा करती है, ग्रह कितने बलवान हैं, '
                  'क्या वर्तमान दशा उसे सक्रिय करती है, और क्या आज का ग्रह-गोचर उसकी पुष्टि करता है। सरल व्याख्या और पूरे प्रमाण के लिए किसी क्षेत्र पर टैप करें।'),
        ]),
        Text(
          tr('Evidence layers: A natal, B strength, C Daśā, D transit, E Varga, F Ashtakavarga. These are evidence states, not guaranteed events.',
              'प्रमाण परतें: A जन्म कुंडली, B बल, C दशा, D गोचर, E वर्ग, F अष्टकवर्ग। ये प्रमाण की स्थितियाँ हैं, निश्चित घटनाएँ नहीं।'),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        if (report.running.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('${tr('Current Daśā', 'वर्तमान दशा')}: ${report.running.map(L10n.planet).join(' / ')}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
        for (final f in report.inputFlags.where((f) => f.severity != 'info'))
          BulletLine(f.message, mark: '⚠', color: f.severity == 'critical' ? scheme.error : Colors.orange),
        const SizedBox(height: 8),
        if (report.jaimini != null) _JaiminiCard(report),
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
                    Expanded(child: Text('${d.domain.code} · ${Interpret.domainName(d.domain)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    const Icon(Icons.chevron_right),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Pill(Interpret.v6Label(d.v6Status), _v6Color(d.v6Status, scheme)),
                    Pill(Interpret.confidenceLabel(d.confidence), _confColor(d.confidence, scheme)),
                    Pill(Interpret.statusLabel(d.primaryStatus), _statusColor(d.primaryStatus, scheme)),
                    if (d.timingWindows.isNotEmpty)
                      Pill(tr('${d.timingWindows.length} WINDOW${d.timingWindows.length == 1 ? '' : 'S'}', '${d.timingWindows.length} समय-सीमा'), scheme.primary),
                  ]),
                  const SizedBox(height: 6),
                  _LayerStrip(d),
                  const SizedBox(height: 6),
                  Text(Interpret.domainHeadline(d), style: const TextStyle(fontSize: 13, height: 1.35)),
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
      if (items.isEmpty) return tr('absent', 'अनुपस्थित');
      final sup = items.where((e) => e.polarity == Polarity.support).length;
      final obs = items.where((e) => e.polarity == Polarity.obstruction).length;
      if (sup > 0 && obs == 0) return tr('supported', 'समर्थित');
      if (sup > 0) return tr('partial', 'आंशिक');
      if (obs > 0) return tr('obstructed', 'बाधित');
      return tr('not strongly activated', 'प्रबल रूप से सक्रिय नहीं');
    }

    return Scaffold(
      appBar: AppBar(title: Text(Interpret.domainName(d.domain))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          SimpleMeaningCard(Interpret.domain(d, now: Ephemeris.nowJd())),
          SectionCard(
            title: tr('Result', 'परिणाम'),
            subtitle: '${d.domain.code} ${d.domain.v6Name} · ${tr('houses', 'भाव')} ${d.domain.bhavas.join(', ')} · ${tr('karakas', 'कारक')} '
                '${d.domain.karakas.map(L10n.planet).join(', ')} · ${d.domain.vargas.join(', ')}',
            children: [
              Text(d.interpretation, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 8),
              KeyValueRow(tr('Promise', 'वादा'), state(EvidenceLayer.natal)),
              KeyValueRow(tr('Obstruction', 'बाधा'), d.conflicts.isEmpty ? tr('none found', 'कोई नहीं') : tr('present (${d.conflicts.length})', 'उपस्थित (${d.conflicts.length})')),
              KeyValueRow(tr('Timing', 'समय'), state(EvidenceLayer.dasha)),
              KeyValueRow(tr('Transit', 'गोचर'), state(EvidenceLayer.transit)),
              KeyValueRow(tr('Varga', 'वर्ग'), state(EvidenceLayer.varga)),
              KeyValueRow(tr('Source tier', 'स्रोत स्तर'), d.tier.label),
              KeyValueRow(tr('Master KB status', 'मास्टर KB स्थिति'), Interpret.codeLabel(d.masterStatus)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                Pill(Interpret.v6Label(d.v6Status), _v6Color(d.v6Status, scheme)),
                Pill(Interpret.confidenceLabel(d.confidence), _confColor(d.confidence, scheme)),
                for (final st in d.statuses) Pill(Interpret.statusLabel(st), _statusColor(st, scheme)),
                Pill(d.tier.code, scheme.secondary),
              ]),
              const SizedBox(height: 6),
              KeyValueRow(tr('Dimensions', 'पहलू'), Interpret.dimensions(d.domain)),
              Text(tr('Confidence is an evidence state, not a probability.', 'विश्वास स्तर प्रमाण की स्थिति है, संभावना प्रतिशत नहीं।'),
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ],
          ),
          SectionCard(
            title: tr('Dependency check', 'निर्भरता जाँच'),
            subtitle: tr('Required layers from the Master Knowledge Base prediction template.', 'मास्टर ज्ञान आधार के भविष्यवाणी टेम्पलेट की आवश्यक परतें।'),
            children: [for (final e in d.dependencies.entries) KeyValueRow(Interpret.codeLabel(e.key), Interpret.codeLabel(e.value))],
          ),
          for (final l in EvidenceLayer.values)
            if (d.layer(l).isNotEmpty)
              SectionCard(
                title: '${l.level}. ${l.label}',
                children: [
                  for (final e in d.layer(l))
                    BulletLine('${e.text}  [${e.ruleId} ${KnowledgeRegistry.ruleName(e.ruleId)}; ${e.tier.code}; ${e.rule}]',
                        mark: e.mark, color: _markColor(e.polarity, scheme), tag: e.id),
                ],
              ),
          SectionCard(
            title: tr('Bhāva-lord chains', 'भावेश श्रृंखला'),
            subtitle: tr('Bhāva → lord → lord\'s sign → dispositor → its house and strength → next dispositor', 'भाव → स्वामी → स्वामी की राशि → राशि स्वामी → उसका भाव और बल → अगला राशि स्वामी'),
            children: [for (final c in d.lordChains) BulletLine(c, mark: '→')],
          ),
          SectionCard(
            title: tr('Event windows', 'घटना की समय-सीमाएँ'),
            subtitle: tr('Antardaśās in the next 15 years whose lords activate this domain, with Pratyantardaśā peaks. Windows, not dates.',
                'अगले 15 वर्षों की वे अंतर्दशाएँ जिनके स्वामी इस क्षेत्र को सक्रिय करते हैं, प्रत्यंतर्दशा के चरम सहित। समय-सीमाएँ, तिथियाँ नहीं।'),
            children: [
              if (d.windows.isEmpty) BulletLine(tr('No strongly activating period found in the next 15 years.', 'अगले 15 वर्षों में कोई प्रबल सक्रिय समय नहीं मिला।')),
              for (final w in d.windows.take(8)) ...[
                Text('${w.label}: ${w.start} – ${w.end}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                for (final f in w.factors) BulletLine(f),
                if (w.peakPeriods.isNotEmpty) BulletLine('${tr('Peaks', 'चरम')}: ${w.peakPeriods.take(3).join('; ')}', mark: '◆'),
                const SizedBox(height: 6),
              ],
            ],
          ),
          SectionCard(
            title: tr('Timing windows (Daśā ∩ transit)', 'समय-सीमाएँ (दशा ∩ गोचर)'),
            subtitle: tr('Antardaśā periods that activate the domain, narrowed to the passes of degree-exact transit triggers. Windows, not dates.',
                'क्षेत्र को सक्रिय करने वाली अंतर्दशाएँ, अंश-सटीक गोचर के समय तक सीमित। समय-सीमाएँ, तिथियाँ नहीं।'),
            children: [
              if (d.timingWindows.isEmpty)
                BulletLine(tr('No Daśā window coincides with a transit trigger in the next three years.', 'अगले तीन वर्षों में कोई दशा-सीमा गोचर से मेल नहीं खाती।')),
              for (final w in d.timingWindows.take(8)) ...[
                Row(children: [
                  Expanded(child: Text('${w.start} – ${w.end}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Pill(Interpret.v6CodeLabel(w.status), w.status == 'CONFIRMED_BY_TRANSIT' ? Colors.green : scheme.primary),
                ]),
                Wrap(spacing: 4, runSpacing: 4, children: [for (final a in w.activation) Pill(Interpret.tag(a), scheme.secondary)]),
                for (final t in w.triggers.take(4)) BulletLine(t.summary, mark: '→'),
                const SizedBox(height: 6),
              ],
            ],
          ),
          SectionCard(
            title: tr('Transit triggers (next 3 years)', 'गोचर संकेत (अगले 3 वर्ष)'),
            subtitle: tr('Jupiter, Saturn, Rahu and Ketu reaching an exact conjunction or Parashari aspect point of this domain\'s lords, karakas or cusps.',
                'गुरु, शनि, राहु और केतु का इस क्षेत्र के स्वामियों, कारकों या भाव संधियों से सटीक युति या पाराशरी दृष्टि बिंदु पर पहुँचना।'),
            children: [
              if (d.triggers.isEmpty) BulletLine(tr('No degree-exact trigger in the next three years.', 'अगले तीन वर्षों में कोई अंश-सटीक गोचर नहीं।')),
              for (final t in d.triggers.take(12)) BulletLine(t.summary, mark: t.exactJds.isEmpty ? '△' : '◎', tag: Interpret.codeLabel(t.strength)),
            ],
          ),
          SectionCard(
            title: tr('Slow-planet contacts (next 3 years)', 'धीमे ग्रहों का संपर्क (अगले 3 वर्ष)'),
            children: [
              if (d.transits.isEmpty) BulletLine(tr('Jupiter and Saturn do not enter this house sign in the next three years.', 'अगले तीन वर्षों में गुरु और शनि इस भाव की राशि में प्रवेश नहीं करते।')),
              for (final t in d.transits) BulletLine('${t.date}: ${t.note}${t.retrogradeRecontact ? tr(' (retrograde re-contact)', ' (वक्री होकर दोबारा संपर्क)') : ''}', mark: '→'),
            ],
          ),
          SectionCard(
            title: tr('Rule trace', 'नियम अनुरेख'),
            subtitle: tr('Rules evaluated for this domain; ✓ produced evidence.', 'इस क्षेत्र के लिए जाँचे गए नियम; ✓ = प्रमाण मिला।'),
            children: [
              Wrap(spacing: 4, runSpacing: 4, children: [
                for (final e in d.ruleTrace.entries) Pill('${e.key} ${e.value ? '✓' : '·'}', e.value ? Colors.green : scheme.outline),
              ]),
            ],
          ),
          SectionCard(
            title: tr('Explanation graph', 'व्याख्या ग्राफ़'),
            subtitle: tr('${d.graph.nodes.length} nodes, ${d.graph.edges.length} edges: prediction → event → layer → evidence → rule → source.',
                '${d.graph.nodes.length} नोड, ${d.graph.edges.length} कड़ियाँ: भविष्यवाणी → घटना → परत → प्रमाण → नियम → स्रोत।'),
            children: [
              for (final r in d.graph.nodes.values.where((n) => n.type == 'Rule'))
                BulletLine('${r.id.substring(5)} ${KnowledgeRegistry.ruleName(r.id.substring(5))} ← ${d.graph.edges.where((e) => e.to == r.id && e.relation == 'DERIVED_FROM').length} ${tr('evidence', 'प्रमाण')}'
                    '${d.graph.from(r.id).isEmpty ? '' : ' · ${d.graph.from(r.id).map((e) => d.graph.nodes[e.to]!.label).join('; ')}'}'),
            ],
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: Text(tr('Copy explanation (JSON)', 'व्याख्या कॉपी करें (JSON)')),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert({'explanation': d.explanation(), 'rule_trace': d.ruleTrace, 'graph': d.graph.toJson()})));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Explanation copied', 'व्याख्या कॉपी हुई'))));
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: Text(tr('Copy report', 'रिपोर्ट कॉपी करें')),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: d.report()));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Report copied', 'रिपोर्ट कॉपी हुई'))));
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(tr('Ask AI to write it up', 'AI से विस्तार से लिखवाएँ')),
              onPressed: () {
                final prompt = 'Write a ${d.domain.name.toLowerCase()} reading from the evidence trace below, produced by a rule-based Jyotisha engine. '
                    'Rules: use only this evidence; cite the evidence IDs (${d.domain.code}-EV1...) for each statement; keep supporting and obstructing factors visible; '
                    'separate natal promise, Daśā timing and transit confirmation; never claim an event will definitely happen; '
                    'label systematic synthesis as such. ${d.domain.caution ?? ''}\n\n${d.report()}\n\nLord chains:\n${d.lordChains.join('\n')}\n\n'
                    'Event windows:\n${d.windows.take(5).map((w) => '${w.label} ${w.start}-${w.end}: ${w.factors.join('; ')}').join('\n')}\n\n'
                    'Timing windows (Daśā ∩ transit):\n${d.timingWindows.take(5).map((w) => '${w.start}-${w.end}: ${w.activation.join(', ')}').join('\n')}\n\n'
                    'Chart:\n${ChartSummary.describe(report.chart, name: name)}';
                showAiSheet(context, ref, title: Interpret.domainName(d.domain), prompt: prompt, profileId: profileId);
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
  final SensitivityResult? sensitivity;
  const _RectifyTab({required this.chart, required this.cfg, this.sensitivity});

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
          ListTile(title: Text(tr('What kind of event?', 'किस प्रकार की घटना?'), style: const TextStyle(fontWeight: FontWeight.bold))),
          for (final d in SynthesisEngine.domains) ListTile(title: Text(Interpret.domainName(d)), onTap: () => Navigator.pop(ctx, d.id)),
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
          tr('Enter known life events to test the chart (backtesting) and compare candidate birth times (rectification). '
              'Each candidate recomputes the Lagna, Vargas and Daśā balance. The saved birth time is never changed.',
              'कुंडली को परखने (बैकटेस्ट) और संभावित जन्म समयों की तुलना (शोधन) के लिए जीवन की ज्ञात घटनाएँ दर्ज करें। '
                  'हर विकल्प के लिए लग्न, वर्ग और दशा शेष दोबारा गणना होते हैं। सहेजा गया जन्म समय कभी नहीं बदलता।'),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (widget.sensitivity != null)
          SectionCard(
            title: tr('Birth-time sensitivity', 'जन्म-समय संवेदनशीलता'),
            subtitle: tr('The chart recomputed at T−5, T−2, T, T+2 and T+5 minutes.', 'कुंडली T−5, T−2, T, T+2 और T+5 मिनट पर दोबारा गणना की गई।'),
            children: [
              for (final e in widget.sensitivity!.values.entries)
                BulletLine(
                  '${e.key}: ${e.value.toSet().length == 1 ? e.value.first : e.value.join(' | ')}',
                  mark: e.value.toSet().length == 1 ? '✓' : '⚠',
                  color: e.value.toSet().length == 1 ? Colors.green : Colors.orange,
                ),
            ],
          ),
        for (int i = 0; i < _events.length; i++)
          Card(
            child: ListTile(
              dense: true,
              title: Text(Interpret.domainName(SynthesisEngine.domain(_events[i].domainId))),
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
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _addEvent, icon: const Icon(Icons.add), label: Text(tr('Add a known event', 'ज्ञात घटना जोड़ें')))),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _range,
              decoration: InputDecoration(labelText: tr('Range ±', 'सीमा ±')),
              items: [for (final v in const [10, 30, 60, 120]) DropdownMenuItem(value: v, child: Text('$v ${tr('min', 'मिनट')}'))],
              onChanged: (v) => setState(() => _range = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _step,
              decoration: InputDecoration(labelText: tr('Step', 'अंतराल')),
              items: [for (final v in const [2, 5, 10, 15]) DropdownMenuItem(value: v, child: Text('$v ${tr('min', 'मिनट')}'))],
              onChanged: (v) => setState(() => _step = v!),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _events.isEmpty ? null : _run, child: Text(tr('Test events and candidate times', 'घटनाएँ और संभावित समय जाँचें'))),
        if (_backtests != null) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: tr('Backtest at the saved birth time', 'सहेजे गए जन्म समय पर बैकटेस्ट'),
            subtitle: tr('Natal rules are known before the event; only timing is evaluated at the event date.', 'जन्म के नियम घटना से पहले ज्ञात हैं; घटना की तिथि पर केवल समय आंका जाता है।'),
            children: [
              for (final b in _backtests!) ...[
                BulletLine(
                  '${Interpret.domainName(SynthesisEngine.domain(b.event.domainId))} (${b.event.date.year}-${b.event.date.month.toString().padLeft(2, '0')}): ${tr('Daśā', 'दशा')} ${b.periods.join(', ')} — '
                  '${b.expectedDomainActivated ? tr('domain activated by both MD and AD', 'महादशा और अंतर्दशा दोनों से क्षेत्र सक्रिय') : tr('not activated by both MD and AD', 'महादशा और अंतर्दशा दोनों से सक्रिय नहीं')}',
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
            title: tr('Candidate birth times', 'संभावित जन्म समय'),
            subtitle: tr('Consistency score: +1 MD, +1.5 AD, +0.5 PD lord activating the event\'s domain. A heuristic, not a classical rule.',
                'संगति अंक: घटना के क्षेत्र को सक्रिय करने वाले महादशा +1, अंतर्दशा +1.5, प्रत्यंतर्दशा +0.5। यह अनुमान है, शास्त्रीय नियम नहीं।'),
            children: [
              for (final c in _candidates!)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                      '${c.offsetMinutes == 0 ? tr('Saved time', 'सहेजा समय') : '${c.offsetMinutes > 0 ? '+' : ''}${c.offsetMinutes} ${tr('min', 'मिनट')}'} · ${tr('${VedicMath.rashis[c.chart.lagnaRashi].name} Lagna', '${L10n.sign(c.chart.lagnaRashi)} लग्न')}',
                      style: TextStyle(fontWeight: c.score == best ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text('${tr('Score', 'अंक')} ${c.score.toStringAsFixed(1)}${c.score == best ? tr(' (highest)', ' (सर्वाधिक)') : ''}', style: const TextStyle(fontSize: 12)),
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
  final String? name;
  const _AuditTab({required this.report, this.name});

  /// Reproducibility package (Volume 6 §140).
  Map<String, dynamic> _package() => {
        'audit': report.audit,
        'normalized_input': TimingMath.normalizedInput(report.chart, CalcConfig.defaults)..remove('config'),
        'input_flags': [for (final f in report.inputFlags) {'severity': f.severity, 'message': f.message}],
        if (report.sensitivity != null) 'birth_time_sensitivity': report.sensitivity!.toJson(),
        if (report.jaimini != null)
          'jaimini': {
            'scheme': report.jaimini!.scheme,
            'karakas': {for (final k in report.jaimini!.karakas) k.code: k.planet},
            'arudhas': {for (final a in report.jaimini!.arudhas) a.code: VedicMath.rashis[a.rashi].name},
          },
        'predictions': [
          for (final d in report.domains)
            {
              'event_domain': d.domain.v6Name,
              'code': d.domain.code,
              'target_bhavas': d.domain.bhavas,
              'status': d.v6Status.code,
              'confidence': d.confidence.code,
              'master_status': d.masterStatus,
              'evidence_states': d.statuses.map((s) => s.code).toList(),
              'dependencies': d.dependencies,
              'source_tier': d.tier.code,
              'evidence': [for (final e in d.evidence) {'id': e.id, 'layer': e.layer.level, 'polarity': e.polarity.name, 'rule': e.ruleId, 'class': e.tier.code, 'text': e.text}],
              'rule_trace': d.ruleTrace,
              'timing_windows': [for (final w in d.timingWindows) w.toJson()],
              'interpretation': d.interpretation,
            },
        ],
      };

  String _markdown() {
    final b = StringBuffer('# ${tr('Synthesis audit', 'संश्लेषण ऑडिट')}\n\n');
    for (final e in report.audit.entries) {
      b.writeln('- **${e.key.replaceAll('_', ' ')}:** ${e.value}');
    }
    if (report.sensitivity != null) {
      b.writeln('\n## ${tr('Birth-time sensitivity', 'जन्म-समय संवेदनशीलता')}\n');
      b.writeln('- ${tr('Stable', 'स्थिर')}: ${report.sensitivity!.stable.join(', ')}');
      b.writeln('- ${tr('Sensitive', 'संवेदनशील')}: ${report.sensitivity!.sensitive.isEmpty ? tr('none', 'कोई नहीं') : report.sensitivity!.sensitive.join(', ')}');
    }
    for (final d in report.domains) {
      b.writeln('\n## ${d.domain.code} ${Interpret.domainName(d.domain)}\n');
      b.writeln('```\n${d.report()}```');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        SectionCard(
          title: tr('Input quality', 'इनपुट गुणवत्ता'),
          children: [
            for (final f in report.inputFlags)
              BulletLine(f.message,
                  mark: f.severity == 'info' ? 'ℹ' : '⚠', color: f.severity == 'critical' ? scheme.error : (f.severity == 'warning' ? Colors.orange : scheme.secondary)),
          ],
        ),
        SectionCard(
          title: tr('Audit log', 'ऑडिट लॉग'),
          subtitle: tr('Everything needed to reproduce these results. The same input and versions give the same hashes.', 'इन परिणामों को दोहराने के लिए आवश्यक सब कुछ। समान इनपुट और संस्करण समान हैश देते हैं।'),
          children: [for (final e in report.audit.entries) KeyValueRow(e.key.replaceAll('_', ' '), e.value)],
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: Text(tr('Copy reproducibility package (JSON)', 'पुनरुत्पादन पैकेज कॉपी करें (JSON)')),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_package())));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Reproducibility package copied', 'पुनरुत्पादन पैकेज कॉपी हुआ'))));
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(tr('Share as PDF', 'PDF के रूप में साझा करें')),
            onPressed: () => PdfService().shareMarkdownReport(title: tr('Synthesis audit', 'संश्लेषण ऑडिट'), name: name ?? tr('Chart', 'कुंडली'), markdown: _markdown()),
          ),
        ]),
      ],
    );
  }
}

/// Jaimini Chara Karakas and Arudha Padas.
class _JaiminiCard extends StatelessWidget {
  final SynthesisReport report;
  const _JaiminiCard(this.report);

  @override
  Widget build(BuildContext context) {
    final j = report.jaimini!;
    String n(String p) => L10n.planet(p);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(tr('Jaimini karakas & Arudhas', 'जैमिनी कारक और आरूढ़'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('AK ${n(j.karakas.first.planet)} · AL ${L10n.sign(j.arudhaLagna.rashi)} · UL ${L10n.sign(j.upapada.rashi)}',
            style: const TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          SimpleMeaningCard([
            tr('In the Jaimini system the planet with the highest degree in its sign is your Ātmakāraka (soul significator): ${n(j.karakas.first.planet)}, which shows what your soul most wants to learn — ${_meaning(j.karakas.first.planet)}. '
                'The Arudha Lagna (${L10n.sign(j.arudhaLagna.rashi)}) shows how the world sees you; the Upapada (${L10n.sign(j.upapada.rashi)}) is used to judge marriage.',
                'जैमिनी पद्धति में अपनी राशि में सबसे अधिक अंश वाला ग्रह आपका आत्मकारक होता है: ${n(j.karakas.first.planet)}, जो दिखाता है कि आपकी आत्मा सबसे अधिक क्या सीखना चाहती है — ${_meaning(j.karakas.first.planet)}। '
                    'आरूढ़ लग्न (${L10n.sign(j.arudhaLagna.rashi)}) बताता है कि दुनिया आपको कैसे देखती है; उपपद (${L10n.sign(j.upapada.rashi)}) से विवाह देखा जाता है।'),
          ], card: false),
          Text(tr('${j.scheme}-karaka scheme (change in Settings → Style). Karakamsa: ${VedicMath.rashis[j.karakamsa].name}.',
              '${j.scheme}-कारक पद्धति (सेटिंग्स → शैली में बदलें)। कारकांश: ${L10n.sign(j.karakamsa)}।'), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          CompactTable(
            header: [tr('Karaka', 'कारक'), tr('Planet', 'ग्रह'), tr('Degree', 'अंश')],
            rows: [for (final k in j.karakas) ['${k.code} ${k.name}', n(k.planet), '${k.degree.toStringAsFixed(2)}°${k.planet == 'rahu' ? ' (30−d)' : ''}']],
          ),
          const SizedBox(height: 8),
          CompactTable(
            header: [tr('Pada', 'पद'), tr('Sign', 'राशि'), tr('House', 'भाव')],
            rows: [for (final a in j.arudhas) ['${a.code} ${a.name}', L10n.sign(a.rashi), '${a.fromLagna}${a.exception ? '*' : ''}']],
          ),
          const SizedBox(height: 4),
          Text(tr('* 10th-from exception applied (the count fell in the house or the 7th from it).', '* दसवें भाव का अपवाद लागू (गणना उसी भाव या उससे सातवें में पड़ी)।'), style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

/// All Daśā ∩ transit windows and the current Daśā chain down to Sūkṣma.
class _TimingTab extends StatelessWidget {
  final SynthesisReport report;
  const _TimingTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = report.chart;
    final now = Ephemeris.nowJd();
    final chain = DashaCalculations.compute(c.jd, c.planetLongitudes['moon']!, utcOffset: c.utcOffset, levels: 4).runningAt(now);
    final levels = L10n.hi ? const ['महादशा', 'अंतर्दशा', 'प्रत्यंतर्दशा', 'सूक्ष्मदशा'] : const ['Mahādaśā', 'Antardaśā', 'Pratyantardaśā', 'Sūkṣmadaśā'];
    final windows = [for (final d in report.domains) for (final w in d.timingWindows) (d, w)]..sort((a, b) => a.$2.startJd.compareTo(b.$2.startJd));
    final active = {for (final d in report.domains) for (final t in d.triggers) if (t.activeAt(now)) t.tag: t};
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        SectionCard(
          title: tr('Current Daśā chain', 'वर्तमान दशा क्रम'),
          children: [
            for (int i = 0; i < chain.length; i++) KeyValueRow(levels[i], '${L10n.planet(chain[i].lord)}  ${chain[i].startDate} – ${chain[i].endDate}'),
          ],
        ),
        SectionCard(
          title: tr('Transit triggers in orb now', 'अभी सक्रिय गोचर संकेत'),
          children: [
            if (active.isEmpty) BulletLine(tr('No degree-exact trigger is in orb today.', 'आज कोई अंश-सटीक गोचर सीमा में नहीं है।')),
            for (final t in active.values)
              BulletLine('${t.summary} — ${t.applyingAt(now) ? tr('applying', 'निकट आ रहा') : tr('separating', 'दूर जा रहा')}', mark: '◎', tag: Interpret.codeLabel(t.strength)),
          ],
        ),
        SectionCard(
          title: tr('Timing windows, all domains', 'समय-सीमाएँ, सभी क्षेत्र'),
          subtitle: tr('Daśā periods intersected with transit passes (next three years). Evidence states, not predictions of exact dates.',
              'दशा अवधियाँ और गोचर का मेल (अगले तीन वर्ष)। प्रमाण की स्थितियाँ, सटीक तिथियों की भविष्यवाणी नहीं।'),
          children: [
            if (windows.isEmpty) BulletLine(tr('No Daśā window coincides with a transit trigger in the next three years.', 'अगले तीन वर्षों में कोई दशा-सीमा गोचर से मेल नहीं खाती।')),
            for (final (d, w) in windows.take(40))
              BulletLine('${w.start} – ${w.end}  ${Interpret.domainName(d.domain)}: ${w.activation.map(Interpret.tag).join(', ')}',
                  mark: w.status == 'CONFIRMED_BY_TRANSIT' ? '◎' : '◇', color: w.status == 'CONFIRMED_BY_TRANSIT' ? Colors.green : scheme.primary),
          ],
        ),
        Text(tr('Transit orb ${report.audit['transit_trigger_orb'] ?? ''}; dates are in the chart\'s local time ($_offset).', 'गोचर सीमा ${report.audit['transit_trigger_orb'] ?? ''}; तिथियाँ कुंडली के स्थानीय समय ($_offset) में हैं।'),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ],
    );
  }

  String get _offset => 'UTC${report.chart.utcOffset >= 0 ? '+' : ''}${report.chart.utcOffset}';
}

String _meaning(String p) => Meanings.planet(p);
