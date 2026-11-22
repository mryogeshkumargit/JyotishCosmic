import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/l10n.dart';
import '../core/rashifal/rashifal_models.dart';
import 'pdf_service.dart';

/// A4 PDF of a daily Rashifal: cover band with the day's score, the life
/// areas with score bars, the outlook, remedies and the full planetary
/// analysis with its tables. Hindi text is shaped by Flutter (see
/// [PdfService.text]).
class RashifalPdf {
  static const double _margin = 32;
  static const double _width = 595.28 - 2 * _margin;
  static const PdfColor _accent = PdfColor.fromInt(0xFF4527A0);
  static const PdfColor _soft = PdfColor.fromInt(0xFFF3EFFC);

  static PdfColor ratingColor(DayRating? r) => switch (r) {
    DayRating.good => const PdfColor.fromInt(0xFF2E7D32),
    DayRating.average => const PdfColor.fromInt(0xFFB26A00),
    DayRating.bad => const PdfColor.fromInt(0xFFC62828),
    null => _accent,
  };

  static Future<void> share(DailyRashifalReport r) async {
    final bytes = await build(r);
    final safe = r.profileName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: '${safe.replaceAll('_', '').isEmpty ? 'Jyotish' : safe}_Rashifal_${r.dateKey}.pdf');
  }

  /// Text for the PDF. Devanagari comes back as an image of fixed width; it
  /// may scale down slightly to fit a narrower flexible slot.
  static Future<pw.Widget> _t(String s, {double size = 10.5, bool bold = false, PdfColor color = PdfColors.black, double width = _width, pw.TextAlign align = pw.TextAlign.left}) async {
    final w = await PdfService.text(s, size: size, bold: bold, color: color, width: width - 2, align: align);
    if (w is! pw.Image || w.width == null || w.height == null) return w;
    return pw.LayoutBuilder(
      builder: (_, c) {
        if (c == null || !c.hasBoundedWidth || c.maxWidth >= w.width!) return w;
        return pw.Image(w.image, width: c.maxWidth, height: w.height! * c.maxWidth / w.width!);
      },
    );
  }

  static pw.Widget _bar(int score, PdfColor color, double width) => pw.Container(
    width: width,
    height: 5,
    decoration: pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.circular(3)),
    alignment: pw.Alignment.centerLeft,
    child: pw.Container(
      width: width * score.clamp(0, 100) / 100,
      height: 5,
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(3)),
    ),
  );

  static Future<pw.Widget> _chip(String s, PdfColor color) async => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
    child: await _t(s, size: 8.5, bold: true, color: PdfColors.white, width: 140),
  );

  static Future<pw.Widget> _heading(String s) async => pw.Container(
    margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
    padding: const pw.EdgeInsets.only(bottom: 3),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.2)),
    ),
    child: await _t(s, size: 14, bold: true, color: _accent),
  );

  static Future<pw.Widget> _bullets(List<String> items, {String mark = '•', PdfColor color = _accent, double width = _width, double size = 9.5}) async => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final s in items)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 12,
                child: pw.Text(
                  mark,
                  style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: size),
                ),
              ),
              pw.Expanded(
                child: await _t(s, size: size, width: width - 12),
              ),
            ],
          ),
        ),
    ],
  );

  /// A boxed section: title, optional rating chip and score bar, text, factors.
  static Future<pw.Widget> _section(RashifalSection s, {bool showFactors = true}) async {
    final color = ratingColor(s.rating);
    const inner = _width - 20;
    return pw.Inseparable(
      child: pw.Container(
        width: _width,
        margin: const pw.EdgeInsets.only(bottom: 7),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border(
            left: pw.BorderSide(color: color, width: 3),
            top: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            right: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

              children: [
                pw.Flexible(child: await _t(s.title, size: 11.5, bold: true, width: inner - 160)),
                if (s.rating != null) await _chip('${s.rating!.label}${s.score == null ? '' : '  ${s.score}/100'}', color),
              ],
            ),
            if (s.score != null) ...[pw.SizedBox(height: 4), _bar(s.score!, color, inner)],
            pw.SizedBox(height: 4),
            await _t(s.text, size: 10, width: inner),
            if (showFactors && s.factors.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              for (final f in s.factors)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 12,
                      child: pw.Text(
                        f.startsWith('+') ? '+' : '-',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: f.startsWith('+') ? ratingColor(DayRating.good) : ratingColor(DayRating.bad)),
                      ),
                    ),
                    pw.Expanded(
                      child: await _t(f.substring(1).trim(), size: 8.5, color: PdfColors.grey800, width: inner - 12),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<pw.Widget> _table(List<List<String>> table, {double size = 8.5}) async {
    final cols = table.first.length;
    final longest = List<int>.generate(cols, (i) => table.map((r) => i < r.length ? r[i].length : 0).reduce((a, b) => a > b ? a : b).clamp(4, 60));
    final total = longest.reduce((a, b) => a + b);
    double w(int i) => _width * longest[i] / total - 8;
    Future<pw.Widget> cell(String s, int i, bool head) async => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: await _t(s, size: size, bold: head, color: head ? PdfColors.white : PdfColors.black, width: w(i)),
    );
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      columnWidths: {for (int i = 0; i < cols; i++) i: pw.FlexColumnWidth(longest[i].toDouble())},
      children: [
        for (final (ri, r) in table.indexed)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: ri == 0 ? _accent : (ri.isEven ? _soft : PdfColors.white)),
            children: [for (int i = 0; i < cols; i++) await cell(i < r.length ? r[i] : '', i, ri == 0)],
          ),
      ],
    );
  }

  static Future<Uint8List> build(DailyRashifalReport r) async {
    final doc = pw.Document(theme: await PdfService.loadTheme(), title: 'Daily Rashifal ${r.profileName} ${r.dateKey}', creator: 'Jyotish Cosmic');
    final color = ratingColor(r.rating);
    final d = r.date;
    final dateLabel = '${L10n.weekday(d.weekday)}, ${d.day} ${L10n.month(d.month)} ${d.year}';

    final cover = pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: _accent, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                await _t(tr('Daily Rashifal', 'दैनिक राशिफल'), size: 22, bold: true, color: PdfColors.white, width: _width - 140),
                pw.SizedBox(height: 4),
                await _t(r.profileName, size: 13, bold: true, color: PdfColors.white, width: _width - 140),
                await _t('$dateLabel · ${r.placeName}', size: 10, color: PdfColors.grey200, width: _width - 140),
                pw.SizedBox(height: 8),
                await _t(r.notificationLine1, size: 10, color: PdfColors.white, width: _width - 140),
                await _t(r.notificationLine2, size: 9, color: PdfColors.grey200, width: _width - 140),
              ],
            ),
          ),
          pw.Container(
            width: 92,
            height: 92,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: color, width: 5),
            ),
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  '${r.score}',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: color),
                ),
                await _t(r.rating.label, size: 9, bold: true, color: color, width: 80, align: pw.TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );

    final body = <pw.Widget>[
      cover,
      pw.SizedBox(height: 10),
      await _t(r.headline, size: 11, bold: true),
      if (r.aiSummary != null) ...[await _heading(tr('AI overview', 'AI सारांश')), await _t(r.aiSummary!, size: 10)],
      await _heading(tr('Your day', 'आपका दिन')),
      for (final s in r.areas) await _section(s),
      await _heading(tr('Also today', 'आज यह भी')),
    ];

    for (final s in r.outlook) {
      if (s.key != 'muhurat') {
        body.add(await _section(s));
        continue;
      }
      body.add(
        pw.Inseparable(
          child: pw.Container(
            width: _width,
            margin: const pw.EdgeInsets.only(bottom: 7),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                await _t(s.title, size: 11.5, bold: true),
                pw.SizedBox(height: 4),
                await _t(s.text, size: 10, width: _width - 20),
                pw.SizedBox(height: 4),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: await _bullets(s.items, mark: '+', color: ratingColor(DayRating.good), width: (_width - 30) / 2, size: 8.5),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: await _bullets(s.items2, mark: 'x', color: ratingColor(DayRating.bad), width: (_width - 30) / 2, size: 8.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    body.add(await _heading(tr('Remedies & guidance', 'उपाय और मार्गदर्शन')));
    for (final s in r.remedies) {
      final inner = <pw.Widget>[await _t(s.title, size: 11.5, bold: true), pw.SizedBox(height: 3)];
      switch (s.key) {
        case 'mantra':
          if (s.extra['devanagari'] != null) {
            inner.add(
              pw.Container(
                width: _width - 20,
                padding: const pw.EdgeInsets.all(6),
                margin: const pw.EdgeInsets.only(bottom: 4),
                decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(
                  children: [
                    await _t(s.extra['devanagari']!, size: 14, bold: true, color: _accent, width: _width - 32, align: pw.TextAlign.center),
                    await _t(s.extra['transliteration'] ?? '', size: 9, color: PdfColors.grey800, width: _width - 32, align: pw.TextAlign.center),
                  ],
                ),
              ),
            );
          }
          inner.add(await _t(s.text, size: 10, width: _width - 20));
          inner.add(await _bullets(s.items.skip(s.extra['devanagari'] != null ? 2 : 0).toList(), width: _width - 20));
        case 'colour':
          final hex = int.tryParse((s.extra['hex'] ?? '#888888').substring(1), radix: 16) ?? 0x888888;
          inner.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 26,
                  height: 26,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF000000 | hex),
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.grey500),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: await _t(s.text, size: 10, width: _width - 54)),
              ],
            ),
          );
        case 'dosDonts':
          const half = (_width - 30) / 2;
          inner.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      await _t(tr('Do', 'करें'), size: 10, bold: true, color: ratingColor(DayRating.good), width: half),
                      await _bullets(s.items, mark: '+', color: ratingColor(DayRating.good), width: half, size: 9),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      await _t(tr('Don\'t', 'न करें'), size: 10, bold: true, color: ratingColor(DayRating.bad), width: half),
                      await _bullets(s.items2, mark: 'x', color: ratingColor(DayRating.bad), width: half, size: 9),
                    ],
                  ),
                ),
              ],
            ),
          );
        default:
          inner.add(await _t(s.text, size: 10, width: _width - 20));
          if (s.items.isNotEmpty) inner.add(await _bullets(s.items, width: _width - 20));
      }
      body.add(
        pw.Inseparable(
          child: pw.Container(
            width: _width,
            margin: const pw.EdgeInsets.only(bottom: 7),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: inner),
          ),
        ),
      );
    }

    body.add(pw.NewPage());
    body.add(await _heading(tr('Daily planetary & astrological analysis', 'दैनिक ग्रह और ज्योतिषीय विश्लेषण')));
    for (final (i, a) in r.analysis.indexed) {
      body.add(
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8, bottom: 3),
                child: await _t('${i + 1}. ${a.title}', size: 12, bold: true, color: _accent),
              ),
              await _t(a.summary, size: 10),
            ],
          ),
        ),
      );
      if (a.table.length > 1) {
        body.add(pw.SizedBox(height: 4));
        body.add(await _table(a.table, size: a.table.first.length > 5 ? 7.5 : 8.5));
      }
      if (a.points.isNotEmpty) {
        body.add(pw.SizedBox(height: 3));
        for (final p in a.points) {
          body.add(await _bullets([p], size: 9));
        }
      }
    }
    body.add(pw.SizedBox(height: 14));
    body.add(
      await _t(
        tr(
          'Calculated offline by Jyotish Cosmic with the Swiss Ephemeris (sidereal). Scores weigh classical factors with a transparent heuristic; muhurats, remedies and colours follow common tradition.${r.hasAi ? ' Texts interpreted by AI (${r.aiModel}).' : ''}',
          'ज्योतिष कॉस्मिक द्वारा स्विस एफ़ेमेरिस (निरयण) से ऑफ़लाइन गणना। अंक शास्त्रीय कारकों को पारदर्शी पद्धति से तौलते हैं; मुहूर्त, उपाय और रंग प्रचलित परंपरा पर आधारित हैं।${r.hasAi ? ' पाठ की व्याख्या AI (${r.aiModel}) द्वारा।' : ''}',
        ),
        size: 8,
        color: PdfColors.grey600,
      ),
    );

    final runningHeader = await _t('${tr('Daily Rashifal', 'दैनिक राशिफल')} · ${r.profileName} · $dateLabel', size: 8, color: PdfColors.grey600);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margin),
        maxPages: 60,
        header: (ctx) => ctx.pageNumber == 1 ? pw.SizedBox() : pw.Padding(padding: const pw.EdgeInsets.only(bottom: 8), child: runningHeader),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        build: (_) => body,
      ),
    );
    return doc.save();
  }
}
