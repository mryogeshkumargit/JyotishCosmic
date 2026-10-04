import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jyotish/core/ashtakavarga_math.dart';
import 'package:mobile_jyotish/core/conjunction_db.dart';
import 'package:mobile_jyotish/core/doshas_math.dart';
import 'package:mobile_jyotish/core/ephemeris.dart';
import 'package:mobile_jyotish/core/l10n.dart';
import 'package:mobile_jyotish/core/plain/interpret.dart';
import 'package:mobile_jyotish/core/plain/meanings.dart';
import 'package:mobile_jyotish/core/plain/yoga_meanings.dart';
import 'package:mobile_jyotish/core/shadbala_math.dart';
import 'package:mobile_jyotish/core/synthesis_engine.dart';
import 'package:mobile_jyotish/core/vedic_math.dart';
import 'package:mobile_jyotish/core/yogas_math.dart';
import 'package:mobile_jyotish/services/pdf_service.dart';
import 'package:mobile_jyotish/widgets/kundli_chart.dart';
import 'package:pdf/widgets.dart' as pw;

import 'helpers/sweph_test_helper.dart';

final _devanagari = RegExp(r'[ऀ-ॿ]');

/// Runs [body] with the app language set to [lang].
T inLanguage<T>(String lang, T Function() body) {
  final old = L10n.lang;
  L10n.lang = lang;
  try {
    return body();
  } finally {
    L10n.lang = old;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initEphemerisForTests);
  tearDown(() => L10n.lang = 'en');
  final skip = swephSkipReason();

  group('L10n', () {
    test('tr and the name helpers follow the language', () {
      expect(inLanguage('en', () => tr('House', 'भाव')), 'House');
      expect(inLanguage('hi', () => tr('House', 'भाव')), 'भाव');
      expect(inLanguage('en', () => L10n.planet('jupiter')), 'Jupiter');
      expect(inLanguage('hi', () => L10n.planet('jupiter')), 'गुरु');
      expect(inLanguage('hi', () => L10n.sign(9)), 'मकर');
      expect(inLanguage('en', () => L10n.ordinal(10)), '10th');
      expect(inLanguage('hi', () => L10n.inHouse(10)), '10वें भाव में');
      expect(inLanguage('hi', () => L10n.dignity('Great Friend')), 'अधिमित्र राशि');
      expect(inLanguage('hi', () => L10n.join(['क', 'ख', 'ग'])), 'क, ख और ग');
      expect(inLanguage('hi', () => L10n.month(6)), 'जून');
      expect(inLanguage('hi', () => L10n.planetAbbr('saturn')), 'श');
    });

    test('plain meanings exist in both languages for every planet, house and sign', () {
      for (final lang in ['en', 'hi']) {
        inLanguage(lang, () {
          for (final p in Ephemeris.planetOrder) {
            expect(Meanings.planet(p), isNotEmpty, reason: '$lang $p');
          }
          for (int h = 1; h <= 12; h++) {
            expect(Meanings.house(h), isNotEmpty, reason: '$lang house $h');
          }
          for (int r = 0; r < 12; r++) {
            expect(Meanings.sign(r), isNotEmpty, reason: '$lang sign $r');
          }
          if (lang == 'hi') expect(Meanings.house(7), matches(_devanagari));
        });
      }
    });
  });

  group('chart markers', () {
    test('1990 Mumbai chart: Saturn retrograde and vargottama, nothing combust', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      final labels = chartLabels(c).values.expand((l) => l).toList();
      ChartLabel of(String p) => labels.firstWhere((l) => l.planet == p);
      final saturn = of('saturn');
      expect(saturn.retrograde, isTrue);
      expect(saturn.vargottama, isTrue, reason: 'Saturn at 0°18\' Capricorn is in Capricorn navamsa');
      expect(saturn.markers, contains(ChartLabel.retroMark));
      expect(saturn.markers, contains(ChartLabel.vargottamaMark));
      expect(of('sun').combust, isFalse);
      expect(of('mercury').combust, isFalse, reason: 'Mercury is about 18.5° from the Sun');
      for (final p in ['rahu', 'ketu']) {
        expect(of(p).exalted || of(p).debilitated, isFalse, reason: 'no dignity marks for the nodes');
      }
      expect(labels.where((l) => l.planet == 'lagna'), hasLength(1));
    }, skip: skip);

    test('exaltation, debilitation and combustion flags', () {
      // Sun exalted in Aries, Moon debilitated in Scorpio, Mercury 3° from the Sun.
      final labels = buildHouseLabels({'sun': 10, 'moon': 215, 'mercury': 13}, 0, speeds: const {'mercury': 1.2});
      final all = labels.values.expand((l) => l).toList();
      ChartLabel of(String p) => all.firstWhere((l) => l.planet == p);
      expect(of('sun').exalted, isTrue);
      expect(of('sun').markers, contains(ChartLabel.exaltedMark));
      expect(of('moon').debilitated, isTrue);
      expect(of('moon').markers, contains(ChartLabel.debilitatedMark));
      expect(of('mercury').combust, isTrue);
      expect(of('mercury').markers, contains(ChartLabel.combustMark));
      expect(of('mercury').retrograde, isFalse);
    });
  });

  group('yogas', () {
    final charts = [
      for (int i = 0; i < 24; i++) () => Ephemeris.computeChart(1950 + i * 3, 1 + i % 12, 1 + (i * 7) % 27, (i * 5) % 24, 15, 28.6, 77.2, 5.5),
    ];

    test('every yoga has a plain-language meaning and the same verdict in both languages', () {
      final missing = <String>{};
      for (final make in charts) {
        final c = make();
        final en = inLanguage('en', () => YogasMath.forChart(c, atJd: 2461000));
        final hi = inLanguage('hi', () => YogasMath.forChart(c, atJd: 2461000));
        expect(hi.length, en.length);
        for (int i = 0; i < en.length; i++) {
          final e = en[i], h = hi[i];
          expect(h.name, e.name, reason: 'yoga names are language-independent keys');
          expect(h.formed, e.formed, reason: e.name);
          expect(h.strength, e.strength, reason: e.name);
          if (!YogaMeanings.byName.containsKey(YogaMeanings.keyOf(e.name))) missing.add(e.name);
          for (final line in [h.rule, ...h.reasons, ...h.modifiers]) {
            expect(line, matches(_devanagari), reason: '${e.name}: "$line" is not in Hindi');
          }
          expect(inLanguage('hi', () => Interpret.yoga(h)), matches(_devanagari), reason: e.name);
          expect(inLanguage('en', () => Interpret.yoga(e)), isNotEmpty, reason: e.name);
          expect(inLanguage('hi', () => Interpret.yogaStrength(h.strength)), isNot(matches(RegExp('[A-Za-z]{3,}'))), reason: h.strength);
        }
      }
      expect(missing, isEmpty, reason: 'yogas without a plain meaning: $missing');
    }, skip: skip);
  });

  group('plain interpretations', () {
    test('doshas, strength, ashtakavarga, conjunctions and synthesis read in both languages', () {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      for (final lang in ['en', 'hi']) {
        inLanguage(lang, () {
          final check = lang == 'hi' ? matches(_devanagari) : isNotEmpty;
          final doshas = [
            DoshasMath.computeManglik(c.planetLongitudes, c.lagnaRashi),
            DoshasMath.computeKaalSarp(c.planetLongitudes, c.lagnaRashi),
            DoshasMath.computeSadesati(VedicMath.rashiIndex(c.planetLongitudes['moon']!), VedicMath.rashiIndex(c.planetLongitudes['saturn']!)),
            DoshasMath.computePitruDosha(c.planetLongitudes, c.lagnaRashi),
            DoshasMath.computeGrahanDosha(c.planetLongitudes),
            DoshasMath.computeGuruChandalDosha(c.planetLongitudes),
            DoshasMath.computeKemadrumaDosha(c.planetLongitudes),
          ].whereType<DoshaResult>();
          for (final d in doshas) {
            expect(d.title, check, reason: d.id);
            expect(d.simple, isNotEmpty, reason: d.id);
            for (final s in d.simple) {
              expect(s, check, reason: d.id);
            }
          }
          final sb = ShadbalaMath.compute(c);
          for (final s in [...Interpret.shadbala(sb), ...Interpret.bhavaBala(sb), ...Interpret.ashtakavarga(AshtakavargaMath.compute(c))]) {
            expect(s, check);
          }
          for (final cj in ConjunctionDb.find(c)) {
            final lines = Interpret.conjunction(cj);
            expect(lines, isNotEmpty);
            for (final s in lines) {
              expect(s, check);
            }
          }
          final report = SynthesisEngine.analyse(c, atJd: Ephemeris.julianDay(2026, 10, 3));
          for (final d in report.domains) {
            expect(Interpret.domainName(d.domain), check);
            expect(Interpret.domainHeadline(d), check);
            for (final s in Interpret.domain(d, now: Ephemeris.julianDay(2026, 10, 3))) {
              expect(s, check, reason: d.domain.id);
            }
          }
        });
      }
    }, skip: skip);
  });

  group('PDF export', () {
    setUpAll(() async {
      final loader = FontLoader('NotoSansDevanagari')
        ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf'));
      await loader.load();
    });

    test('Devanagari is laid out by Flutter (shaped) and Latin text stays text', () async {
      expect(await PdfService.text('Planetary Positions'), isA<pw.Text>());
      expect(await PdfService.text('ग्रह स्थिति'), isA<pw.Image>());
    });

    test('reports build in both languages', () async {
      final c = Ephemeris.computeChart(1990, 6, 15, 14, 30, 19.07, 72.88, 5.5);
      for (final lang in ['en', 'hi']) {
        L10n.lang = lang;
        final chart = await PdfService().buildAstrologicalReport(c, 'Asha', birthLabel: '1990-06-15 14:30', place: 'Mumbai');
        expect((await chart.save()).length, greaterThan(1000));
        final md = await PdfService().buildMarkdownReport(
          title: tr('Vedic Life Report', 'वैदिक जीवन रिपोर्ट'),
          name: 'Asha',
          markdown: '# ${tr('Career', 'करियर')}\n${'${tr('A long paragraph.', 'एक लंबा अनुच्छेद।')} ' * 120}\n- ${tr('Point', 'बिंदु')}',
        );
        expect((await md.save()).length, greaterThan(1000));
      }
      L10n.lang = 'en';
    }, skip: skip);
  });
}
