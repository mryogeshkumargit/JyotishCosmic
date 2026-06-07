import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ephemeris.dart';
import '../../core/vedic_math.dart';
import '../../widgets/kundli_chart.dart';
import '../../services/ai_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/profile_provider.dart';

class VargaScreen extends ConsumerWidget {
  final ChartData chartData;
  final int? profileId;

  const VargaScreen({super.key, required this.chartData, this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shodashvarga (Vargas)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: VedicMath.vargaDefs.length,
        itemBuilder: (context, index) {
          final def = VedicMath.vargaDefs[index];
          return _buildVargaCard(context, ref, def);
        },
      ),
    );
  }

  Widget _buildVargaCard(BuildContext context, WidgetRef ref, VargaDef def) {
    // Generate planet house mappings for this Varga
    Map<int, List<String>> vargaHouses = {for (var i = 1; i <= 12; i++) i: []};
    
    // Lagna for this Varga
    int lagnaVargaRashi = VedicMath.vargaRashi(chartData.ascendantSidereal, def.key, def.div);
    int lagnaSign = lagnaVargaRashi + 1;

    final Map<String, String> planetDisplayNames = {
      'sun': 'Su', 'moon': 'Mo', 'mars': 'Ma', 'mercury': 'Me',
      'jupiter': 'Ju', 'venus': 'Ve', 'saturn': 'Sa',
      'rahu': 'Ra', 'ketu': 'Ke'
    };

    chartData.planetLongitudes.forEach((pName, sidereal) {
      if (!planetDisplayNames.containsKey(pName)) return;
      int vRashi = VedicMath.vargaRashi(sidereal, def.key, def.div);
      int pSign = vRashi + 1;
      int house = (pSign - lagnaSign + 12) % 12 + 1;
      vargaHouses[house]!.add(planetDisplayNames[pName]!);
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${def.key} - ${def.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text(def.hindi, style: const TextStyle(fontSize: 18, color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(def.purpose, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                  onPressed: () => _analyzeWholeVargaChart(context, ref, def, vargaHouses, lagnaSign),
                  tooltip: 'Analyze Holistic Chart',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300, // Increased height for the KundliChart
              child: KundliChart(
                housePlanets: vargaHouses,
                ascendantSign: lagnaSign,
                onHouseTapped: (house) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _analyzeWholeVargaChart(
    BuildContext context, 
    WidgetRef ref, 
    VargaDef def, 
    Map<int, List<String>> vargaHouses, 
    int vargaLagnaSign
  ) {
    // 1. D1 (Rasi Chart) Foundation
    int d1LagnaSign = (chartData.ascendantSidereal / 30).floor() + 1;
    String d1LagnaSignName = VedicMath.rashis[d1LagnaSign - 1].name;
    String d1LagnaLord = VedicMath.rashis[d1LagnaSign - 1].lord;
    
    // Find D1 Lagna Lord position in D1
    int d1LagnaLordD1House = -1;
    if (chartData.planetLongitudes.containsKey(d1LagnaLord)) {
      int d1LagnaLordD1Sign = (chartData.planetLongitudes[d1LagnaLord]! / 30).floor() + 1;
      d1LagnaLordD1House = (d1LagnaLordD1Sign - d1LagnaSign + 12) % 12 + 1;
    }

    // 2. Varga Details
    String vargaLagnaSignName = VedicMath.rashis[vargaLagnaSign - 1].name;
    String vargaLagnaLord = VedicMath.rashis[vargaLagnaSign - 1].lord;
    
    // Find Varga Lagna Lord position in Varga
    int vargaLagnaLordVargaHouse = -1;
    int d1LagnaLordVargaHouse = -1;
    
    // Map of display names to full names
    final Map<String, String> planetFullNames = {
      'Su': 'sun', 'Mo': 'moon', 'Ma': 'mars', 'Me': 'mercury',
      'Ju': 'jupiter', 'Ve': 'venus', 'Sa': 'saturn',
      'Ra': 'rahu', 'Ke': 'ketu'
    };

    vargaHouses.forEach((house, planets) {
      for (String p in planets) {
        String fullP = planetFullNames[p] ?? '';
        if (fullP == vargaLagnaLord) vargaLagnaLordVargaHouse = house;
        if (fullP == d1LagnaLord) d1LagnaLordVargaHouse = house;
      }
    });

    // Find Vargottama planets
    List<String> vargottamaPlanets = [];
    chartData.planetLongitudes.forEach((pName, sidereal) {
      int d1Sign = (sidereal / 30).floor() + 1;
      int vSign = VedicMath.vargaRashi(sidereal, def.key, def.div) + 1;
      if (d1Sign == vSign) {
        vargottamaPlanets.add(pName[0].toUpperCase() + pName.substring(1));
      }
    });

    // Map of Varga Karakas
    final Map<String, String> vargaKarakas = {
      'D2': 'Jupiter (Wealth)',
      'D3': 'Mars (Siblings)',
      'D4': 'Moon (Property)',
      'D7': 'Jupiter (Children)',
      'D9': 'Venus (Marriage)',
      'D10': 'Mercury, Jupiter, Sun (Career)',
      'D12': 'Sun (Father), Moon (Mother)',
      'D16': 'Venus (Vehicles/Luxury)',
      'D20': 'Jupiter (Spirituality)',
      'D24': 'Mercury (Education)',
      'D27': 'Mars (Strength)',
      'D30': 'Saturn (Misfortunes)',
    };
    
    String karakaText = '';
    if (vargaKarakas.containsKey(def.key)) {
      karakaText = '\n- Primary Karaka(s) for this Varga: ${vargaKarakas[def.key]}';
    }

    // Format all placements
    List<String> placementsList = [];
    for (int i = 1; i <= 12; i++) {
      if (vargaHouses[i] != null && vargaHouses[i]!.isNotEmpty) {
        int signNum = (vargaLagnaSign + i - 2) % 12 + 1;
        String sName = VedicMath.rashis[signNum - 1].name;
        placementsList.add('- House $i ($sName): ${vargaHouses[i]!.join(', ')}');
      }
    }

    String prompt = '''
Perform a holistic Vedic astrological analysis of the ${def.name} (${def.key}) chart.
This specific divisional chart is analyzed for the purpose of: "${def.purpose}".

**1. D1 (Rasi Chart) Foundation:**
- D1 Ascendant: $d1LagnaSignName
- D1 Lagna Lord: ${d1LagnaLord.toUpperCase()} placed in House $d1LagnaLordD1House of D1.

**2. ${def.name} Chart Details:**
- Varga Ascendant: $vargaLagnaSignName
- Varga Lagna Lord: ${vargaLagnaLord.toUpperCase()} placed in House ${vargaLagnaLordVargaHouse > 0 ? vargaLagnaLordVargaHouse : 'Unknown'} of this Varga chart.
- D1 Lagna Lord in Varga: Placed in House ${d1LagnaLordVargaHouse > 0 ? d1LagnaLordVargaHouse : 'Unknown'}.
- Vargottama Planets (Same sign in D1 and Varga): ${vargottamaPlanets.isEmpty ? 'None' : vargottamaPlanets.join(', ')}.$karakaText

**3. Planetary Placements in ${def.name}:**
${placementsList.join('\n')}

Provide a comprehensive reading of how these placements specifically affect the native's "${def.purpose}". Focus heavily on the interaction between the D1 Lagna Lord and the Varga Lagna Lord, the impact of Vargottama planets, the Karaka's position if applicable, and the overall Varga Ascendant condition. Do not provide a general life reading.
''';

    _showAIModal(context, ref, '${def.key} - ${def.name} Analysis', prompt);
  }

  void _showAIModal(BuildContext context, WidgetRef ref, String title, String prompt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<String>(
                  future: AiService.interpret(ref.read(settingsProvider), prompt),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                    }
                    
                    final text = snapshot.data ?? 'No response';
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, height: 1.5),
                          ),
                          if (profileId != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                              onPressed: () async {
                                try {
                                  // We need to import profileProvider here or in the file
                                  // Wait, profileNotifierProvider is in providers/profile_provider.dart
                                  // I will import it at the top.
                                  // But I don't know the exact import path here. It's likely '../../providers/profile_provider.dart'.
                                  // I'll add the import and the save logic.
                                  await ref.read(profileNotifierProvider.notifier).saveInterpretation(profileId!, text);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interpretation Saved')));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
                                  }
                                }
                              },
                              icon: const Icon(Icons.save),
                              label: const Text("Save Interpretation to Profile"),
                            )
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
