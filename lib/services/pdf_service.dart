import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/ephemeris.dart';
import '../core/planetary_dignity.dart';
import '../core/vedic_math.dart';

class PdfService {
  static pw.ThemeData? _theme;

  /// Embedded Unicode fonts (Inter + Noto Sans Devanagari for Hindi text).
  static Future<pw.ThemeData> _loadTheme() async {
    if (_theme != null) return _theme!;
    Future<pw.Font> font(String path) async => pw.Font.ttf(await rootBundle.load(path));
    final devanagari = await font('assets/fonts/NotoSansDevanagari-Regular.ttf');
    final devanagariBold = await font('assets/fonts/NotoSansDevanagari-Bold.ttf');
    _theme = pw.ThemeData.withFont(
      base: await font('assets/google_fonts/Inter-Regular.ttf'),
      bold: await font('assets/google_fonts/Inter-Bold.ttf'),
      fontFallback: [devanagari, devanagariBold],
    );
    return _theme!;
  }

  String _fileName(String name, String suffix) =>
      '${name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$suffix.pdf';

  pw.Widget _header(String title) => pw.Header(
        level: 0,
        child: pw.Center(
          child: pw.Text(title,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple800)),
        ),
      );

  pw.Widget _footer() => pw.Center(
        child: pw.Text('Generated offline by Jyotish Cosmic (Swiss Ephemeris, Lahiri ayanamsa)',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      );

  /// Birth chart report with planetary positions; opens the share dialog.
  Future<void> generateAndShareAstrologicalReport(ChartData chartData, String name,
      {required String birthLabel, String? place}) async {
    final pdf = pw.Document(theme: await _loadTheme());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header('Jyotish Cosmic Report'),
          pw.SizedBox(height: 12),
          pw.Text('Name: $name', style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Birth: $birthLabel', style: const pw.TextStyle(fontSize: 12)),
          if (place != null) pw.Text('Place: $place', style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
              'Coordinates: ${chartData.lat.toStringAsFixed(4)}, ${chartData.lon.toStringAsFixed(4)}  •  '
              'Ayanamsa (Lahiri): ${chartData.ayanamsa.toStringAsFixed(4)}°',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          pw.Text('Planetary Positions',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple600)),
          pw.SizedBox(height: 8),
          _buildPlanetsTable(chartData),
          pw.SizedBox(height: 24),
          _footer(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: _fileName(name, 'Jyotish_Report'));
  }

  pw.Widget _buildPlanetsTable(ChartData chart) {
    final rashis = {for (final e in chart.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)};
    List<String> row(String label, double sid, {String dignity = '-', bool retro = false}) {
      final r = VedicMath.rashiIndex(sid);
      return [
        '$label${retro ? ' (R)' : ''}',
        '${VedicMath.rashis[r].name} ${VedicMath.formatDegree(sid)}',
        '${VedicMath.nakshatras[VedicMath.nakshatraIndex(sid)].name} ${VedicMath.pada(sid)}',
        '${VedicMath.houseOf(r, chart.lagnaRashi)}',
        dignity,
      ];
    }

    final data = <List<String>>[
      row('Ascendant', chart.ascendantSidereal),
      for (final p in Ephemeris.planetOrder)
        if (chart.planetLongitudes.containsKey(p))
          row(VedicMath.planets[p]!.name, chart.planetLongitudes[p]!,
              dignity: PlanetaryDignity.getAdvancedDignity(p, rashis[p]!, rashis), retro: chart.isRetrograde(p)),
    ];

    return pw.TableHelper.fromTextArray(
      headers: ['Planet', 'Sign / Degree', 'Nakshatra / Pada', 'House', 'Dignity'],
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellHeight: 24,
    );
  }

  /// Exports an AI-generated Markdown text as a PDF and opens the share dialog.
  Future<void> shareMarkdownReport({required String title, required String name, required String markdown}) async {
    final pdf = pw.Document(theme: await _loadTheme());
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(title),
          pw.Text('Prepared for $name', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 12),
          ..._markdownToWidgets(markdown),
          pw.SizedBox(height: 24),
          _footer(),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: _fileName(name, 'Life_Report'));
  }

  /// Minimal Markdown rendering: headings, bullet lists, rules and paragraphs.
  List<pw.Widget> _markdownToWidgets(String markdown) {
    String clean(String s) => s.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '');
    final widgets = <pw.Widget>[];
    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }
      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line.trim());
      if (heading != null) {
        final level = heading.group(1)!.length;
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
          child: pw.Text(clean(heading.group(2)!),
              style: pw.TextStyle(
                  fontSize: level == 1 ? 18 : (level == 2 ? 15 : 13),
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple700)),
        ));
      } else if (RegExp(r'^\s*([-*+]|\d+\.)\s+').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^\s*([-*+]|\d+\.)\s+'), '');
        widgets.add(pw.Bullet(text: clean(text), style: const pw.TextStyle(fontSize: 11)));
      } else if (RegExp(r'^\s*(-{3,}|\*{3,})\s*$').hasMatch(line)) {
        widgets.add(pw.Divider());
      } else {
        widgets.add(pw.Paragraph(text: clean(line), style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)));
      }
    }
    return widgets;
  }
}
