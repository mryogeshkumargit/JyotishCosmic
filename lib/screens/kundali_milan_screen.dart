import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database.dart';
import '../core/doshas_math.dart';
import '../core/ephemeris.dart';
import '../core/milan_math.dart';
import '../core/profile_chart.dart';
import '../core/vedic_math.dart';
import '../providers/profile_provider.dart';
import '../widgets/ai_sheet.dart';
import '../widgets/analysis_widgets.dart';
import '../core/l10n.dart';

class KundaliMilanScreen extends ConsumerStatefulWidget {
  const KundaliMilanScreen({super.key});

  @override
  ConsumerState<KundaliMilanScreen> createState() => _KundaliMilanScreenState();
}

class _KundaliMilanScreenState extends ConsumerState<KundaliMilanScreen> {
  int? _boyId;
  int? _girlId;
  MilanResult? _milanResult;
  ChartData? _boyChart;
  ChartData? _girlChart;
  Profile? _boy;
  Profile? _girl;

  void _analyzeCompatibility(List<Profile> profiles) {
    Profile? find(int? id) {
      for (final p in profiles) {
        if (p.id == id) return p;
      }
      return null;
    }

    final boy = find(_boyId);
    final girl = find(_girlId);
    if (boy == null || girl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Please select both profiles', 'कृपया दोनों प्रोफ़ाइल चुनें'))));
      return;
    }

    final boyChart = boy.computeChart();
    final girlChart = girl.computeChart();
    setState(() {
      _boy = boy;
      _girl = girl;
      _boyChart = boyChart;
      _girlChart = girlChart;
      _milanResult = MilanMath.calculateMilan(boyChart.planetLongitudes['moon']!, girlChart.planetLongitudes['moon']!);
    });
  }

  String _moonLabel(ChartData c) {
    final m = c.planetLongitudes['moon']!;
    return '${L10n.sign(VedicMath.rashiIndex(m))}, ${L10n.nakshatra(VedicMath.nakshatraIndex(m))} ${tr('pada', 'पद')} ${VedicMath.pada(m)}';
  }

  DoshaResult? _manglik(ChartData c) => DoshasMath.computeManglik(c.planetLongitudes, c.lagnaRashi);

  static String verdict(double total) {
    if (total < 18) return tr('Not recommended (below 18)', 'अनुशंसित नहीं (18 से कम)');
    if (total <= 24) return tr('Average match', 'औसत मिलान');
    if (total <= 32) return tr('Very good match', 'बहुत अच्छा मिलान');
    return tr('Excellent match', 'उत्तम मिलान');
  }

  void _askAi() {
    final r = _milanResult!;
    final bm = _manglik(_boyChart!);
    final gm = _manglik(_girlChart!);
    final prompt = 'Ashtakoot Guna Milan for ${_boy!.name} (boy) and ${_girl!.name} (girl), computed with the Swiss Ephemeris.\n'
        'Boy Moon: ${_moonLabel(_boyChart!)}. Girl Moon: ${_moonLabel(_girlChart!)}.\n'
        'Total: ${r.total} / 36\n'
        '1. Varna: ${r.varna} / 1\n2. Vashya: ${r.vashya} / 2\n3. Tara: ${r.tara} / 3\n4. Yoni: ${r.yoni} / 4\n'
        '5. Graha Maitri: ${r.maitri} / 5\n6. Gana: ${r.gana} / 6\n7. Bhakoot: ${r.bhakoot} / 7\n8. Nadi: ${r.nadi} / 8\n'
        'Boy Manglik: ${bm?.present == true ? 'Yes (${bm!.severity})' : 'No'}. Girl Manglik: ${gm?.present == true ? 'Yes (${gm!.severity})' : 'No'}.\n\n'
        'As an expert Vedic astrologer, interpret these scores, explain any Nadi, Bhakoot or Manglik dosha and '
        'possible cancellations, and give a final recommendation with remedies if needed.';
    showAiSheet(context, ref, title: tr('Compatibility Analysis', 'अनुकूलता विश्लेषण'), prompt: prompt);
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profileListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Kundali Milan', 'कुंडली मिलान'))),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.length < 2) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(tr('Please create at least two profiles to use matchmaking.', 'मिलान के लिए कम से कम दो प्रोफ़ाइल बनाएँ।'), textAlign: TextAlign.center),
              ),
            );
          }
          final boys = profiles.where((p) => p.gender != 'Female').toList();
          final girls = profiles.where((p) => p.gender != 'Male').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileSelector(tr('Select Boy Profile', 'वर की प्रोफ़ाइल चुनें'), _boyId, boys, (id) => setState(() => _boyId = id)),
              const SizedBox(height: 16),
              _buildProfileSelector(tr('Select Girl Profile', 'वधू की प्रोफ़ाइल चुनें'), _girlId, girls, (id) => setState(() => _girlId = id)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _analyzeCompatibility(profiles),
                icon: const Icon(Icons.people_alt),
                label: Text(tr('Analyze Compatibility', 'अनुकूलता जाँचें')),
              ),
              const SizedBox(height: 24),
              if (_milanResult != null) ...[
                _buildScoreCard(scheme),
                const SizedBox(height: 16),
                SimpleMeaningCard(_plain(_milanResult!)),
                const SizedBox(height: 16),
                _buildManglikCard(scheme),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _askAi,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(tr('Ask AI for a detailed interpretation', 'AI से विस्तृत विश्लेषण कराएँ')),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${tr('Error', 'त्रुटि')}: $err')),
      ),
    );
  }

  /// Plain-language reading of the Ashtakoot result.
  List<String> _plain(MilanResult r) {
    final t = r.total;
    final weak = <String>[
      if (r.gana <= 1) tr('temperaments (Gana) differ', 'स्वभाव (गण) अलग है'),
      if (r.maitri <= 1) tr('the Moon-sign lords are not friendly (Graha Maitri)', 'चन्द्र राशि के स्वामी मित्र नहीं हैं (ग्रह मैत्री)'),
      if (r.yoni <= 1) tr('physical and instinctive match is low (Yoni)', 'शारीरिक और सहज मेल कम है (योनि)'),
      if (r.tara < 1.5) tr('the birth stars are not supportive (Tara)', 'जन्म नक्षत्र सहायक नहीं हैं (तारा)'),
    ];
    return [
      tr('Ashtakoot compares only the two Moon signs and birth stars across eight factors, worth 36 points. It shows how naturally the two minds and temperaments fit.',
          'अष्टकूट मिलान केवल दोनों की चन्द्र राशि और जन्म नक्षत्र को आठ कूटों पर तौलता है, कुल 36 गुण। यह बताता है कि दोनों के मन और स्वभाव कितनी सहजता से मेल खाते हैं।'),
      t >= 28
          ? tr('${t.toStringAsFixed(1)} points is an excellent match by this method.', '${t.toStringAsFixed(1)} गुण इस पद्धति से उत्तम मिलान है।')
          : t >= 18
              ? tr('${t.toStringAsFixed(1)} points is acceptable: tradition treats 18 or more as suitable for marriage.', '${t.toStringAsFixed(1)} गुण स्वीकार्य हैं: परंपरा में 18 या अधिक गुण विवाह के लिए उपयुक्त माने जाते हैं।')
              : tr('${t.toStringAsFixed(1)} points is below the traditional minimum of 18, so astrologers usually look more carefully before advising.',
                  '${t.toStringAsFixed(1)} गुण परंपरागत न्यूनतम 18 से कम हैं, इसलिए ज्योतिषी सलाह देने से पहले अधिक ध्यान से देखते हैं।'),
      if (r.hasNadiDosha)
        tr('Nadi Dosha (both have the same Nadi) is treated as the most serious mismatch, traditionally linked to health and children. Classical exceptions exist, such as the same Moon sign with different stars, so get it checked rather than deciding on it alone.',
            'नाड़ी दोष (दोनों की एक ही नाड़ी) सबसे गंभीर दोष माना जाता है, जिसे परंपरा में स्वास्थ्य और संतान से जोड़ा जाता है। इसके शास्त्रीय अपवाद भी हैं, जैसे एक ही चन्द्र राशि पर अलग नक्षत्र, इसलिए केवल इसी पर निर्णय न लें, जाँच करवाएँ।'),
      if (r.hasBhakootDosha)
        tr('Bhakoot Dosha means the Moon signs sit in a difficult 6-8, 5-9 or 2-12 relation, traditionally read as friction over money, health or family. It is cancelled when both signs share a lord or the lords are friends.',
            'भकूट दोष का अर्थ है कि चन्द्र राशियाँ कठिन 6-8, 5-9 या 2-12 संबंध में हैं, जिसे परंपरा में धन, स्वास्थ्य या परिवार से जुड़े तनाव के रूप में देखा जाता है। दोनों राशियों का स्वामी एक हो या स्वामी मित्र हों तो यह भंग हो जाता है।'),
      if (weak.isNotEmpty) tr('Areas to work on: ${L10n.join(weak)}.', 'ध्यान देने योग्य बातें: ${L10n.join(weak)}।'),
      tr('Points are only a first filter. Mutual understanding, the 7th house of both charts, Manglik status and running Dashas matter more than the number.',
          'गुण केवल पहली छलनी हैं। आपसी समझ, दोनों कुंडलियों का सप्तम भाव, मांगलिक स्थिति और चल रही दशाएँ इस संख्या से अधिक महत्वपूर्ण हैं।'),
    ];
  }

  Widget _buildScoreCard(ColorScheme scheme) {
    final r = _milanResult!;
    String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(tr('Ashtakoot Score', 'अष्टकूट गुण'), style: TextStyle(color: scheme.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${fmt(r.total)} / 36', style: TextStyle(color: scheme.onSurface, fontSize: 36, fontWeight: FontWeight.bold)),
            Text(verdict(r.total), style: TextStyle(color: r.total < 18 ? scheme.error : Colors.green)),
            const SizedBox(height: 8),
            Text('${tr('Boy Moon', 'वर का चन्द्र')}: ${_moonLabel(_boyChart!)}\n${tr('Girl Moon', 'वधू का चन्द्र')}: ${_moonLabel(_girlChart!)}',
                textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            const Divider(height: 32),
            _buildScoreRow(tr('Varna (Work/Ego)', 'वर्ण (कर्म/अहं)'), r.varna, 1, fmt),
            _buildScoreRow(tr('Vashya (Attraction)', 'वश्य (आकर्षण)'), r.vashya, 2, fmt),
            _buildScoreRow(tr('Tara (Destiny)', 'तारा (भाग्य)'), r.tara, 3, fmt),
            _buildScoreRow(tr('Yoni (Intimacy)', 'योनि (अंतरंगता)'), r.yoni, 4, fmt),
            _buildScoreRow(tr('Graha Maitri (Friendship)', 'ग्रह मैत्री (मित्रता)'), r.maitri, 5, fmt),
            _buildScoreRow(tr('Gana (Temperament)', 'गण (स्वभाव)'), r.gana, 6, fmt),
            _buildScoreRow(tr('Bhakoot (Health/Wealth)', 'भकूट (स्वास्थ्य/धन)'), r.bhakoot, 7, fmt),
            _buildScoreRow(tr('Nadi (Genetics)', 'नाड़ी (आनुवंशिक)'), r.nadi, 8, fmt),
            if (r.hasNadiDosha || r.hasBhakootDosha) ...[
              const SizedBox(height: 12),
              Text(
                [if (r.hasNadiDosha) tr('Nadi Dosha present', 'नाड़ी दोष उपस्थित'), if (r.hasBhakootDosha) tr('Bhakoot Dosha present', 'भकूट दोष उपस्थित')].join(' • '),
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManglikCard(ColorScheme scheme) {
    String status(DoshaResult? d) {
      if (d == null) return tr('Unknown', 'अज्ञात');
      if (d.present) return '${tr('Manglik', 'मांगलिक')} (${d.severityLabel})';
      if (d.exceptions.isNotEmpty) return '${tr('Cancelled', 'भंग')}: ${d.exceptions.join(', ')}';
      return tr('Not Manglik', 'मांगलिक नहीं');
    }

    final b = _manglik(_boyChart!);
    final g = _manglik(_girlChart!);
    final bothOrNeither = (b?.present ?? false) == (g?.present ?? false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('Manglik Dosha', 'मांगलिक दोष'), style: TextStyle(color: scheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${_boy!.name}: ${status(b)}'),
            Text('${_girl!.name}: ${status(g)}'),
            const SizedBox(height: 8),
            Text(
              bothOrNeither ? tr('Manglik status is balanced.', 'मांगलिक स्थिति संतुलित है।') : tr('Only one partner is Manglik — consider remedies.', 'केवल एक साथी मांगलिक है — उपायों पर विचार करें।'),
              style: TextStyle(color: bothOrNeither ? Colors.green : scheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, double max, String Function(double) fmt) {
    final Color barColor = score == 0 ? Colors.redAccent : (score == max ? Colors.green : Colors.orange);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
              const SizedBox(width: 8),
              Text('${fmt(score)} / ${fmt(max)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score / max,
            color: barColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(String hint, int? selected, List<Profile> options, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(labelText: hint),
      initialValue: options.any((p) => p.id == selected) ? selected : null,
      isExpanded: true,
      items: options.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
      onChanged: onChanged,
    );
  }
}
