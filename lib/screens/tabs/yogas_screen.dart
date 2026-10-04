import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/chart_summary.dart';
import '../../core/ephemeris.dart';
import '../../core/l10n.dart';
import '../../core/plain/interpret.dart';
import '../../core/plain/yoga_meanings.dart';
import '../../core/yogas_math.dart';
import '../../widgets/analysis_widgets.dart';
import '../../widgets/ai_sheet.dart';
import '../../widgets/yoga_guide_view.dart';

/// Classical yogas of a chart: the ones that form, every rule that was
/// checked, and the bundled reference guide.
class YogasScreen extends ConsumerStatefulWidget {
  final ChartData chartData;
  final String? gender;
  final int? profileId;
  final String? name;

  const YogasScreen({super.key, required this.chartData, this.gender, this.profileId, this.name});

  @override
  ConsumerState<YogasScreen> createState() => _YogasScreenState();
}

class _YogasScreenState extends ConsumerState<YogasScreen> {
  String? _lang;
  late List<YogaResult> _cache;

  /// Recomputed when the app language changes (reasons and rules are bilingual).
  List<YogaResult> get _all {
    if (_lang != L10n.lang) {
      _lang = L10n.lang;
      _cache = YogasMath.forChart(widget.chartData, gender: widget.gender);
    }
    return _cache;
  }

  List<YogaResult> get _formed => _all.where((y) => y.formed).toList();

  void _askAi() {
    final formed = _formed;
    final list = formed
        .map((y) => '- ${y.name} [${y.category}; ${y.strength}${y.active ? '; active in the current Dasha' : ''}]: ${y.reasons.join(' ')}'
            '${y.modifiers.isEmpty ? '' : ' Factors: ${y.modifiers.join(' ')}'}')
        .join('\n');
    final prompt = 'Interpret the yogas of this Vedic birth chart. For each important yoga, explain what it means for this person, '
        'how strong it is (dignity, combustion, Navamsa, cancellations) and when it is likely to give results through the Vimshottari Dasha. '
        'Do not treat the number of yogas as a measure of the chart; synthesise them.\n\n'
        'Yogas found (calculated by the app with classical rules):\n$list\n\n'
        'Chart:\n${ChartSummary.describe(widget.chartData, name: widget.name)}';
    showAiSheet(context, ref, title: tr('Yoga Interpretation', 'योग विश्लेषण'), prompt: prompt, profileId: widget.profileId);
  }

  @override
  Widget build(BuildContext context) {
    final formed = _formed;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('Yogas', 'योग')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr('Found (${formed.length})', 'बने (${formed.length})')),
              Tab(text: tr('Checked', 'जाँचे गए')),
              Tab(text: tr('Guide', 'मार्गदर्शिका')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FormedList(yogas: formed, onAskAi: _askAi),
            _CheckedList(yogas: _all),
            const YogaGuideView(),
          ],
        ),
      ),
    );
  }
}

Map<String, List<YogaResult>> _byFamily(List<YogaResult> ys) {
  final map = <String, List<YogaResult>>{};
  for (final f in YogaFamilies.order) {
    final list = ys.where((y) => y.category == f).toList();
    if (list.isNotEmpty) map[f] = list;
  }
  for (final y in ys.where((y) => !YogaFamilies.order.contains(y.category))) {
    map.putIfAbsent(y.category, () => []).add(y);
  }
  return map;
}

class _FormedList extends StatelessWidget {
  final List<YogaResult> yogas;
  final VoidCallback onAskAi;
  const _FormedList({required this.yogas, required this.onAskAi});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = _byFamily(yogas);
    final active = yogas.where((y) => y.active).length;
    final favourable = yogas.where((y) => y.nature == YogaNature.benefic).length;
    final adverse = yogas.where((y) => y.nature == YogaNature.adverse).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('${yogas.length} yogas form in this chart', 'इस कुंडली में ${yogas.length} योग बनते हैं'),
                    style: TextStyle(color: scheme.secondary, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(tr('$favourable favourable • $adverse challenging • ${yogas.length - favourable - adverse} mixed', '$favourable शुभ • $adverse चुनौतीपूर्ण • ${yogas.length - favourable - adverse} मिश्रित')
                    + (active > 0 ? tr('\n$active involve the planets of your current Dasha', '\n$active में आपकी वर्तमान दशा के ग्रह शामिल हैं') : '')),
                const SizedBox(height: 8),
                SimpleMeaningCard([Interpret.yogaSummary(yogas)], card: false),
                Text(
                  tr('Tap a yoga to see what it means for you, the exact rule and how it forms here.', 'किसी योग पर टैप करें: आपके लिए उसका अर्थ, सटीक नियम और यहाँ वह कैसे बना।'),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onAskAi,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(tr('Ask AI to interpret my yogas', 'AI से मेरे योगों का विश्लेषण कराएँ')),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final e in groups.entries) ...[
          _FamilyHeader(e.key, e.value.length),
          for (final y in e.value) _YogaCard(y),
        ],
      ],
    );
  }
}

class _CheckedList extends StatelessWidget {
  final List<YogaResult> yogas;
  const _CheckedList({required this.yogas});

  @override
  Widget build(BuildContext context) {
    final groups = _byFamily(yogas);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            tr('Every yoga the app checks, with its formation rule and source. ${yogas.length} checks, ${yogas.where((y) => y.formed).length} formed.',
                'ऐप द्वारा जाँचे गए सभी योग, उनके नियम और स्रोत के साथ। ${yogas.length} जाँच, ${yogas.where((y) => y.formed).length} बने।'),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
        for (final e in groups.entries) ...[
          _FamilyHeader(e.key, e.value.where((y) => y.formed).length, total: e.value.length),
          for (final y in e.value) _YogaCard(y, compact: true),
        ],
      ],
    );
  }
}

class _FamilyHeader extends StatelessWidget {
  final String family;
  final int count;
  final int? total;
  const _FamilyHeader(this.family, this.count, {this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        total == null ? '${YogaMeanings.family(family)} ($count)' : tr('$family ($count of $total formed)', '${YogaMeanings.family(family)} ($total में से $count बने)'),
        style: TextStyle(color: scheme.primary, fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _YogaCard extends StatelessWidget {
  final YogaResult yoga;
  final bool compact;
  const _YogaCard(this.yoga, {this.compact = false});

  Color _natureColor(ColorScheme scheme) => switch (yoga.nature) {
        YogaNature.benefic => Colors.green,
        YogaNature.adverse => scheme.error,
        YogaNature.mixed => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final y = yoga;
    final color = y.formed ? _natureColor(scheme) : scheme.onSurfaceVariant;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Icon(
            y.formed ? (y.nature == YogaNature.adverse ? Icons.warning_amber_rounded : Icons.check_circle) : Icons.radio_button_unchecked,
            color: color,
          ),
          title: Text(L10n.hi ? y.hindi : y.name, style: TextStyle(fontWeight: FontWeight.bold, color: y.formed ? scheme.onSurface : scheme.onSurfaceVariant)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Tag(Interpret.yogaStrength(y.strength), color),
                if (y.active) _Tag(tr('Active in Dasha', 'दशा में सक्रिय'), scheme.primary),
                if (y.planets.isNotEmpty && y.formed && y.planets.length <= 4)
                  Text(y.planets.map(L10n.planet).join(', '),
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          children: [
            Text(L10n.hi ? y.name : y.hindi, style: TextStyle(color: scheme.secondary)),
            const SizedBox(height: 6),
            SimpleMeaningCard([Interpret.yoga(y)], card: false),
            if (!L10n.hi) _Section('Classical results', [y.description]),
            _Section(tr('In this chart', 'इस कुंडली में'), y.reasons),
            if (y.modifiers.isNotEmpty) _Section(tr('Strength factors', 'बल के कारक'), y.modifiers),
            _Section(tr('Rule', 'नियम'), [y.rule]),
            const SizedBox(height: 4),
            Text('${tr('Source', 'स्रोत')}: ${y.source}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _Section(this.title, this.lines);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(lines.length > 1 ? '• $l' : l, style: const TextStyle(fontSize: 13, height: 1.35)),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
