import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/conjunction_db.dart';
import '../core/database.dart';
import '../core/ephemeris.dart';
import '../core/profile_chart.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/analysis_widgets.dart';
import '../core/l10n.dart';

class ResearchHit {
  final Profile profile;
  final ChartConjunction conjunction;
  final List<String> repetition;
  const ResearchHit(this.profile, this.conjunction, this.repetition);
}

/// Conjunction research across saved charts (Volume 6 §141-142). Counts are
/// descriptive only; they are not a statistical validation.
class ResearchScreen extends ConsumerStatefulWidget {
  const ResearchScreen({super.key});

  @override
  ConsumerState<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends ConsumerState<ResearchScreen> {
  final Set<String> _planets = {'mars', 'mercury'};
  bool _exact = false;
  int? _house;
  int? _sign;
  bool _activeNow = false;
  bool _d9 = false;
  List<ResearchHit>? _hits;
  int _searched = 0;

  static List<ResearchHit> query(
    List<Profile> profiles,
    Set<String> planets, {
    bool exact = false,
    int? house,
    int? sign,
    bool activeNow = false,
    bool d9 = false,
    ChartConjunctionFinder? finder,
  }) {
    final out = <ResearchHit>[];
    for (final p in profiles) {
      final c = p.computeChart();
      for (final cj in (finder ?? ConjunctionDb.find)(c)) {
        final ps = cj.record.planets.toSet();
        if (exact ? !(ps.length == planets.length && ps.containsAll(planets)) : !ps.containsAll(planets)) continue;
        if (house != null && cj.record.bhava != house) continue;
        if (sign != null && cj.record.rashi != sign) continue;
        if (activeNow && cj.activeNow.isEmpty) continue;
        final rep = ConjunctionDb.vargaRepetition(c, planets.toList(), const ['D9', 'D10']);
        if (d9 && !rep.contains('D9')) continue;
        out.add(ResearchHit(p, cj, rep));
      }
    }
    return out;
  }

  void _run(List<Profile> profiles) {
    final cfg = ref.read(settingsProvider).calc;
    setState(() {
      _searched = profiles.length;
      _hits = query(profiles, _planets,
          exact: _exact, house: _house, sign: _sign, activeNow: _activeNow, d9: _d9, finder: (c) => ConjunctionDb.find(c, cfg: cfg));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profiles = ref.watch(profileListProvider).value ?? const <Profile>[];
    final hits = _hits;
    final byHouse = <int, int>{};
    final bySign = <int, int>{};
    for (final h in hits ?? const <ResearchHit>[]) {
      byHouse[h.conjunction.record.bhava] = (byHouse[h.conjunction.record.bhava] ?? 0) + 1;
      bySign[h.conjunction.record.rashi] = (bySign[h.conjunction.record.rashi] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr('Research', 'शोध'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          Text(
            tr('Find a conjunction across your ${profiles.length} saved chart${profiles.length == 1 ? '' : 's'}. '
                'Counts describe this sample only; they are not statistical evidence.',
                'अपनी ${profiles.length} सहेजी गई कुंडलियों में युति खोजें। गिनती केवल इसी नमूने का वर्णन करती है; यह सांख्यिकीय प्रमाण नहीं है।'),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final p in ConjunctionDb.classical)
              FilterChip(
                label: Text(L10n.planet(p)),
                selected: _planets.contains(p),
                onSelected: (v) => setState(() {
                  v ? _planets.add(p) : _planets.remove(p);
                  _hits = null;
                }),
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _house,
                decoration: InputDecoration(labelText: tr('House', 'भाव')),
                items: [
                  DropdownMenuItem(value: null, child: Text(tr('Any', 'कोई भी'))),
                  for (int h = 1; h <= 12; h++) DropdownMenuItem(value: h, child: Text(L10n.ordinal(h))),
                ],
                onChanged: (v) => setState(() => _house = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: _sign,
                decoration: InputDecoration(labelText: tr('Sign', 'राशि')),
                items: [
                  DropdownMenuItem(value: null, child: Text(tr('Any', 'कोई भी'))),
                  for (int r = 0; r < 12; r++) DropdownMenuItem(value: r, child: Text(L10n.sign(r), overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _sign = v),
              ),
            ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Exactly these planets', 'केवल यही ग्रह')),
            subtitle: Text(tr('Off: any cluster that contains them', 'बंद: कोई भी समूह जिसमें ये ग्रह हों')),
            value: _exact,
            onChanged: (v) => setState(() => _exact = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Activated by the current Daśā', 'वर्तमान दशा से सक्रिय')),
            value: _activeNow,
            onChanged: (v) => setState(() => _activeNow = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('Repeated in the Navāṃśa (D9)', 'नवांश (D9) में दोहराई गई')),
            value: _d9,
            onChanged: (v) => setState(() => _d9 = v),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: Text(tr('Search saved charts', 'सहेजी गई कुंडलियाँ खोजें')),
            onPressed: _planets.length < 2 || profiles.isEmpty ? null : () => _run(profiles),
          ),
          if (_planets.length < 2) Text(tr('Choose at least two planets.', 'कम से कम दो ग्रह चुनें।'), style: TextStyle(fontSize: 12, color: scheme.error)),
          if (hits != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: tr('${hits.length} match${hits.length == 1 ? '' : 'es'} in $_searched chart${_searched == 1 ? '' : 's'}',
                  '$_searched कुंडलियों में ${hits.length} परिणाम'),
              subtitle: ConjunctionDb.clusterIdOf(_planets) + (_exact ? tr(' (exact)', ' (केवल यही)') : tr(' (contained)', ' (शामिल)')),
              children: [
                if (byHouse.isNotEmpty) KeyValueRow(tr('By house', 'भाव अनुसार'), (byHouse.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}: ${e.value}').join(', ')),
                if (bySign.isNotEmpty)
                  KeyValueRow(tr('By sign', 'राशि अनुसार'), (bySign.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${L10n.sign(e.key)}: ${e.value}').join(', ')),
                for (final h in hits)
                  BulletLine(
                    '${h.profile.name}: ${h.conjunction.record.recordId} · ${h.conjunction.record.clusterLabel} · '
                    '${tr('span', 'फैलाव')} ${h.conjunction.diagnostics.degreeSpan.toStringAsFixed(1)}°'
                    '${h.repetition.isEmpty ? '' : ' · ${tr('repeated in', 'दोहराई गई')} ${h.repetition.join(', ')}'}'
                    '${h.conjunction.activeNow.isEmpty ? '' : ' · ${tr('active now', 'अभी सक्रिय')}'}',
                    mark: '◆',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

typedef ChartConjunctionFinder = List<ChartConjunction> Function(ChartData c);
