import 'dart:ui' as ui;
import 'package:flutter/painting.dart' as fp;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/ephemeris.dart';
import '../core/l10n.dart';
import '../core/planetary_dignity.dart';
import '../core/vedic_math.dart';

class PdfService {
  static pw.ThemeData? _theme;

  /// A4 width minus the 32 pt margins.
  static const double _contentWidth = 595.28 - 64;

  static final RegExp _devanagari = RegExp(r'[ऀ-ॿ]');

  /// Embedded Unicode fonts (Inter + Noto Sans Devanagari).
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

  String _fileName(String name, String suffix) {
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return '${safe.replaceAll('_', '').isEmpty ? 'Jyotish' : safe}_$suffix.pdf';
  }

  /// Text widget for the PDF. The pdf package does not apply OpenType shaping,
  /// so Devanagari (matras, conjuncts) would come out in the wrong order. Such
  /// text is laid out by Flutter's text engine and embedded as an image.
  static Future<pw.Widget> text(
    String value, {
    double size = 11,
    bool bold = false,
    PdfColor color = PdfColors.black,
    double width = _contentWidth,
    pw.TextAlign align = pw.TextAlign.left,
  }) async {
    if (!_devanagari.hasMatch(value)) {
      return pw.Text(value,
          textAlign: align, style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : null, color: color, lineSpacing: 2));
    }
    const scale = 3.0;
    final painter = fp.TextPainter(
      text: fp.TextSpan(
        text: value,
        style: fp.TextStyle(
          fontFamily: 'NotoSansDevanagari',
          fontSize: size,
          height: 1.35,
          fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
          color: ui.Color.fromARGB(255, (color.red * 255).round(), (color.green * 255).round(), (color.blue * 255).round()),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: align == pw.TextAlign.center ? ui.TextAlign.center : ui.TextAlign.left,
    )..layout(minWidth: align == pw.TextAlign.center ? width : 0, maxWidth: width);
    final w = align == pw.TextAlign.center ? width : painter.width;
    final h = painter.height;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(scale);
    painter.paint(canvas, ui.Offset.zero);
    final image = await recorder.endRecording().toImage((w * scale).ceil().clamp(1, 100000), (h * scale).ceil().clamp(1, 100000));
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    painter.dispose();
    return pw.Image(pw.MemoryImage(bytes!.buffer.asUint8List()), width: w, height: h);
  }

  Future<pw.Widget> _header(String title) async => pw.Header(
        level: 0,
        child: pw.Center(child: await text(title, size: 22, bold: true, color: PdfColors.deepPurple800, align: pw.TextAlign.center)),
      );

  Future<pw.Widget> _footer() async => pw.Center(
        child: await text(
            tr('Generated offline by Jyotish Cosmic (Swiss Ephemeris, Lahiri ayanamsa)', 'ज्योतिष कॉस्मिक द्वारा ऑफ़लाइन तैयार (स्विस एफेमेरिस, लाहिरी अयनांश)'),
            size: 9,
            color: PdfColors.grey,
            align: pw.TextAlign.center),
      );

  /// Birth chart report with planetary positions; opens the share dialog.
  Future<void> generateAndShareAstrologicalReport(ChartData chartData, String name, {required String birthLabel, String? place}) async {
    final pdf = await buildAstrologicalReport(chartData, name, birthLabel: birthLabel, place: place);
    await Printing.sharePdf(bytes: await pdf.save(), filename: _fileName(name, 'Jyotish_Report'));
  }

  Future<pw.Document> buildAstrologicalReport(ChartData chartData, String name, {required String birthLabel, String? place}) async {
    final pdf = pw.Document(theme: await _loadTheme());
    final body = <pw.Widget>[
      await _header(tr('Jyotish Cosmic Report', 'ज्योतिष कॉस्मिक रिपोर्ट')),
      pw.SizedBox(height: 12),
      await text('${tr('Name', 'नाम')}: $name', size: 14),
      await text('${tr('Birth', 'जन्म')}: $birthLabel', size: 12),
      if (place != null) await text('${tr('Place', 'स्थान')}: $place', size: 12),
      await text(
          '${tr('Coordinates', 'निर्देशांक')}: ${chartData.lat.toStringAsFixed(4)}, ${chartData.lon.toStringAsFixed(4)}  •  '
          '${tr('Ayanamsa (Lahiri)', 'अयनांश (लाहिरी)')}: ${chartData.ayanamsa.toStringAsFixed(4)}°',
          size: 10,
          color: PdfColors.grey700),
      pw.SizedBox(height: 16),
      await text(tr('Planetary Positions', 'ग्रह स्थिति'), size: 18, bold: true, color: PdfColors.deepPurple600),
      pw.SizedBox(height: 8),
      await _buildPlanetsTable(chartData),
      pw.SizedBox(height: 24),
      await _footer(),
    ];
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32), build: (context) => body));
    return pdf;
  }

  Future<pw.Widget> _buildPlanetsTable(ChartData chart) async {
    final rashis = {for (final e in chart.planetLongitudes.entries) e.key: VedicMath.rashiIndex(e.value)};
    List<String> row(String label, double sid, {String dignity = '-', bool retro = false}) {
      final r = VedicMath.rashiIndex(sid);
      return [
        '$label${retro ? tr(' (R)', ' (व)') : ''}',
        '${L10n.sign(r)} ${VedicMath.formatDegree(sid)}',
        '${L10n.nakshatra(VedicMath.nakshatraIndex(sid))} ${VedicMath.pada(sid)}',
        '${VedicMath.houseOf(r, chart.lagnaRashi)}',
        L10n.dignity(dignity),
      ];
    }

    final headers = [tr('Planet', 'ग्रह'), tr('Sign / Degree', 'राशि / अंश'), tr('Nakshatra / Pada', 'नक्षत्र / पाद'), tr('House', 'भाव'), tr('Dignity', 'गरिमा')];
    final data = <List<String>>[
      row(tr('Ascendant', 'लग्न'), chart.ascendantSidereal),
      for (final p in Ephemeris.planetOrder)
        if (chart.planetLongitudes.containsKey(p))
          row(L10n.planet(p), chart.planetLongitudes[p]!,
              dignity: PlanetaryDignity.getAdvancedDignity(p, rashis[p]!, rashis, degree: VedicMath.degInRashi(chart.planetLongitudes[p]!)),
              retro: chart.isRetrograde(p)),
    ];

    const flex = [1.0, 1.3, 1.4, 0.6, 1.2];
    final total = flex.reduce((a, b) => a + b);
    double cellWidth(int i) => _contentWidth * flex[i] / total - 10;
    Future<pw.Widget> cell(String s, int i, {bool header = false}) async => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: await text(s, size: 10, bold: header, color: header ? PdfColors.white : PdfColors.black, width: cellWidth(i)),
        );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {for (int i = 0; i < flex.length; i++) i: pw.FlexColumnWidth(flex[i])},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
          children: [for (int i = 0; i < headers.length; i++) await cell(headers[i], i, header: true)],
        ),
        for (final r in data) pw.TableRow(children: [for (int i = 0; i < r.length; i++) await cell(r[i], i)]),
      ],
    );
  }

  /// Exports an AI-generated Markdown text as a PDF and opens the share dialog.
  Future<void> shareMarkdownReport({required String title, required String name, required String markdown}) async {
    final pdf = await buildMarkdownReport(title: title, name: name, markdown: markdown);
    await Printing.sharePdf(bytes: await pdf.save(), filename: _fileName(name, 'Life_Report'));
  }

  Future<pw.Document> buildMarkdownReport({required String title, required String name, required String markdown}) async {
    final pdf = pw.Document(theme: await _loadTheme());
    final body = <pw.Widget>[
      await _header(title),
      await text(tr('Prepared for $name', '$name के लिए तैयार'), size: 12, color: PdfColors.grey700),
      pw.SizedBox(height: 12),
      ...await _markdownToWidgets(markdown),
      pw.SizedBox(height: 24),
      await _footer(),
    ];
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32), build: (context) => body));
    return pdf;
  }

  /// Splits a long paragraph so each image stays well under a page height.
  static List<String> _chunks(String s, {int max = 900}) {
    if (s.length <= max) return [s];
    final out = <String>[];
    var rest = s;
    while (rest.length > max) {
      var cut = rest.lastIndexOf(RegExp(r'[।.!?]\s'), max);
      if (cut < max ~/ 3) cut = rest.lastIndexOf(' ', max);
      if (cut <= 0) cut = max;
      out.add(rest.substring(0, cut + 1).trim());
      rest = rest.substring(cut + 1);
    }
    if (rest.trim().isNotEmpty) out.add(rest.trim());
    return out;
  }

  /// Minimal Markdown rendering: headings, bullet lists, rules and paragraphs.
  Future<List<pw.Widget>> _markdownToWidgets(String markdown) async {
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
          child: await text(clean(heading.group(2)!), size: level == 1 ? 18 : (level == 2 ? 15 : 13), bold: true, color: PdfColors.deepPurple700),
        ));
      } else if (RegExp(r'^\s*([-*+]|\d+\.)\s+').hasMatch(line)) {
        final item = clean(line.replaceFirst(RegExp(r'^\s*([-*+]|\d+\.)\s+'), ''));
        if (!_devanagari.hasMatch(item)) {
          widgets.add(pw.Bullet(text: item, style: const pw.TextStyle(fontSize: 11)));
          continue;
        }
        for (final (i, part) in _chunks(item).indexed) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(
                width: 14,
                height: 14,
                alignment: pw.Alignment.centerLeft,
                padding: const pw.EdgeInsets.only(left: 3),
                child: i == 0 ? pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle)) : null,
              ),
              await text(part, width: _contentWidth - 24),
            ]),
          ));
        }
      } else if (RegExp(r'^\s*(-{3,}|\*{3,})\s*$').hasMatch(line)) {
        widgets.add(pw.Divider());
      } else if (!_devanagari.hasMatch(line)) {
        widgets.add(pw.Paragraph(text: clean(line), style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)));
      } else {
        for (final part in _chunks(clean(line))) {
          widgets.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: await text(part)));
        }
      }
    }
    return widgets;
  }
}
