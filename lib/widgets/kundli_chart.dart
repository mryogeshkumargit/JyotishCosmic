import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/calc_config.dart';
import '../core/ephemeris.dart';
import '../core/l10n.dart';
import '../core/precision_math.dart';
import '../core/vedic_math.dart';
import '../providers/settings_provider.dart';

/// One planet (or the Lagna) drawn in a chart cell, with its state markers.
class ChartLabel {
  /// Planet key ('sun'...) or 'lagna'.
  final String planet;
  final int? degree;
  final bool retrograde;
  final bool combust;
  final bool exalted;
  final bool debilitated;
  final bool vargottama;
  const ChartLabel(this.planet,
      {this.degree, this.retrograde = false, this.combust = false, this.exalted = false, this.debilitated = false, this.vargottama = false});

  String get abbreviation => planet == 'lagna' ? tr('La', 'ल') : L10n.planetAbbr(planet);

  /// Marker string in the order used by the legend.
  String get markers => '${retrograde ? retroMark : ''}${combust ? combustMark : ''}${exalted ? exaltedMark : ''}'
      '${debilitated ? debilitatedMark : ''}${vargottama ? vargottamaMark : ''}';

  static const String retroMark = '*';
  static const String combustMark = '^';
  static const String exaltedMark = '↑';
  static const String debilitatedMark = '↓';
  static const String vargottamaMark = '□';

  static const List<String> _sup = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
  static String superscript(int n) => n.toString().padLeft(2, '0').split('').map((d) => _sup[int.parse(d)]).join();

  /// Plain text form, e.g. "Sa¹²*↑".
  String get text => '$abbreviation${degree == null ? '' : superscript(degree!)}$markers';

  @override
  String toString() => text;
}

/// Builds per-house planet labels for [KundliChart], with retrograde (*),
/// combust (^), exalted (↑), debilitated (↓) and vargottama (□) markers.
///
/// [signOverride] places planets by a divisional chart's signs; exaltation and
/// debilitation are then judged in that sign, and vargottama is only marked on
/// the Rasi chart. Rahu and Ketu get no dignity mark because traditions differ.
Map<int, List<ChartLabel>> buildHouseLabels(
  Map<String, double> longitudes,
  int lagnaRashi, {
  Map<String, double> speeds = const {},
  Map<String, int>? signOverride,
  bool showDegrees = true,
  double? ascendant,
}) {
  final Map<int, List<ChartLabel>> houses = {for (int i = 1; i <= 12; i++) i: []};
  final sun = longitudes['sun'];
  if (ascendant != null) {
    houses[1]!.add(ChartLabel('lagna',
        degree: showDegrees ? VedicMath.degInRashi(ascendant).floor() : null,
        vargottama: signOverride == null && VedicMath.rashiIndex(ascendant) == VedicMath.vargaRashi(ascendant, 'D9', 9)));
  }
  for (final planet in Ephemeris.planetOrder) {
    final sid = longitudes[planet];
    if (sid == null) continue;
    final sign = signOverride?[planet] ?? VedicMath.rashiIndex(sid);
    final house = VedicMath.houseOf(sign, lagnaRashi);
    final node = planet == 'rahu' || planet == 'ketu';
    final speed = speeds[planet] ?? 0;
    final data = VedicMath.planets[planet]!;
    var combust = false;
    if (!node && planet != 'sun' && sun != null) {
      final orb = speed < 0 ? (CalcConfig.retrogradeCombustionOrbs[planet] ?? CalcConfig.combustionOrbs[planet]) : CalcConfig.combustionOrbs[planet];
      combust = orb != null && PrecisionMath.separation(sid, sun) < orb;
    }
    houses[house]!.add(ChartLabel(
      planet,
      degree: showDegrees ? VedicMath.degInRashi(sid).floor() : null,
      retrograde: speed < 0,
      combust: combust,
      exalted: !node && data.exalt == sign,
      debilitated: !node && data.debi == sign,
      vargottama: signOverride == null && VedicMath.rashiIndex(sid) == VedicMath.vargaRashi(sid, 'D9', 9),
    ));
  }
  return houses;
}

/// Labels for a [ChartData] (Lagna, degrees and markers).
Map<int, List<ChartLabel>> chartLabels(ChartData chart) =>
    buildHouseLabels(chart.planetLongitudes, chart.lagnaRashi, speeds: chart.planetSpeeds, ascendant: chart.ascendantSidereal);

/// Planet colour adjusted for contrast with the theme background.
Color planetColor(String planet, Brightness brightness, Color fallback) {
  if (planet == 'lagna') return brightness == Brightness.dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
  final c = VedicMath.planets[planet]?.color;
  if (c == null) return fallback;
  final hsl = HSLColor.fromColor(c);
  return brightness == Brightness.dark
      ? hsl.withLightness(hsl.lightness.clamp(0.6, 0.8)).toColor()
      : hsl.withLightness(hsl.lightness.clamp(0.2, 0.38)).withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0)).toColor();
}

/// Key to the chart markers.
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(String mark, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Text(mark, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary, fontSize: 14)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(spacing: 14, runSpacing: 6, alignment: WrapAlignment.center, children: [
        item(ChartLabel.retroMark, tr('Retrograde', 'वक्री')),
        item(ChartLabel.combustMark, tr('Combust', 'अस्त')),
        item(ChartLabel.vargottamaMark, tr('Vargottama', 'वर्गोत्तम')),
        item(ChartLabel.exaltedMark, tr('Exalted', 'उच्च')),
        item(ChartLabel.debilitatedMark, tr('Debilitated', 'नीच')),
        Text(tr('Small numbers: degree in sign', 'छोटे अंक: राशि में अंश'), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _Cell {
  final Path path;
  final Offset center;
  final Offset numberPos;
  final int? house; // North Indian: cells are houses
  final int? sign; // South/East Indian: cells are fixed signs (0 = Aries)
  _Cell(this.path, this.center, this.numberPos, {this.house, this.sign});
}

List<_Cell> _northCells(double w, double h) {
  Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);
  final c = Offset(w / 2, h / 2);
  final tl = Offset(w / 4, h / 4), tr = Offset(3 * w / 4, h / 4);
  final bl = Offset(w / 4, 3 * h / 4), br = Offset(3 * w / 4, 3 * h / 4);
  final shapes = <int, (List<Offset>, Offset)>{
    1: ([Offset(w / 2, 0), tr, c, tl], c),
    2: ([const Offset(0, 0), Offset(w / 2, 0), tl], tl),
    3: ([const Offset(0, 0), tl, Offset(0, h / 2)], tl),
    4: ([Offset(0, h / 2), tl, c, bl], c),
    5: ([Offset(0, h), Offset(0, h / 2), bl], bl),
    6: ([Offset(0, h), bl, Offset(w / 2, h)], bl),
    7: ([Offset(w / 2, h), bl, c, br], c),
    8: ([Offset(w, h), Offset(w / 2, h), br], br),
    9: ([Offset(w, h), br, Offset(w, h / 2)], br),
    10: ([Offset(w, h / 2), br, c, tr], c),
    11: ([Offset(w, 0), Offset(w, h / 2), tr], tr),
    12: ([Offset(w, 0), tr, Offset(w / 2, 0)], tr),
  };
  return [
    for (final e in shapes.entries)
      () {
        final pts = e.value.$1;
        final centroid = pts.reduce((a, b) => a + b) / pts.length.toDouble();
        return _Cell(poly(pts), centroid, Offset.lerp(centroid, e.value.$2, 0.72)!, house: e.key);
      }()
  ];
}

List<_Cell> _southCells(double w, double h) {
  final cw = w / 4, ch = h / 4;
  // (row, col) of each sign, Pisces in the top-left corner, running clockwise.
  const pos = {
    11: (0, 0), 0: (0, 1), 1: (0, 2), 2: (0, 3),
    3: (1, 3), 4: (2, 3), 5: (3, 3), 6: (3, 2),
    7: (3, 1), 8: (3, 0), 9: (2, 0), 10: (1, 0),
  };
  return [
    for (final e in pos.entries)
      _Cell(
        Path()..addRect(Rect.fromLTWH(e.value.$2 * cw, e.value.$1 * ch, cw, ch)),
        Offset(e.value.$2 * cw + cw / 2, e.value.$1 * ch + ch / 2 + 6),
        Offset(e.value.$2 * cw + cw - 10, e.value.$1 * ch + 9),
        sign: e.key,
      )
  ];
}

List<_Cell> _eastCells(double w, double h) {
  final a = w / 3, b = h / 3;
  Path rect(double x, double y) => Path()..addRect(Rect.fromLTWH(x, y, a, b));
  Path tri(List<Offset> pts) => Path()..addPolygon(pts, true);
  Offset centroid(List<Offset> pts) => pts.reduce((p, q) => p + q) / pts.length.toDouble();
  _Cell t(int sign, List<Offset> pts) {
    final c = centroid(pts);
    return _Cell(tri(pts), c, c + const Offset(0, -12), sign: sign);
  }

  _Cell r(int sign, double x, double y) =>
      _Cell(rect(x, y), Offset(x + a / 2, y + b / 2 + 6), Offset(x + a - 10, y + 9), sign: sign);
  // Aries at top-centre, then counter-clockwise; corner squares split along the diagonal.
  return [
    r(0, a, 0),
    t(1, [const Offset(0, 0), Offset(a, 0), Offset(a, b)]),
    t(2, [const Offset(0, 0), Offset(a, b), Offset(0, b)]),
    r(3, 0, b),
    t(4, [Offset(0, 2 * b), Offset(a, 2 * b), Offset(0, h)]),
    t(5, [Offset(0, h), Offset(a, 2 * b), Offset(a, h)]),
    r(6, a, 2 * b),
    t(7, [Offset(2 * a, 2 * b), Offset(w, h), Offset(2 * a, h)]),
    t(8, [Offset(2 * a, 2 * b), Offset(w, 2 * b), Offset(w, h)]),
    r(9, 2 * a, b),
    t(10, [Offset(2 * a, b), Offset(w, 0), Offset(w, b)]),
    t(11, [Offset(2 * a, 0), Offset(w, 0), Offset(2 * a, b)]),
  ];
}

List<_Cell> _cellsFor(String style, Size size) {
  switch (style) {
    case 'South':
      return _southCells(size.width, size.height);
    case 'East':
      return _eastCells(size.width, size.height);
    default:
      return _northCells(size.width, size.height);
  }
}

class KundliChartPainter extends CustomPainter {
  final Map<int, List<ChartLabel>> housePlanets;
  final int? selectedHouse;
  final int ascendantSign; // 1-based (1 = Aries)
  final String style;
  final ColorScheme colors;

  /// Body font of the theme (Inter), which has superscript digits.
  final String? fontFamily;

  KundliChartPainter(this.housePlanets, this.selectedHouse, this.ascendantSign, this.style, this.colors, {this.fontFamily});

  int _houseOf(_Cell cell) => cell.house ?? ((cell.sign! - (ascendantSign - 1) + 12) % 12 + 1);
  int _signOf(_Cell cell) => cell.sign ?? ((ascendantSign - 1 + cell.house! - 1) % 12);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colors.secondary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final cells = _cellsFor(style, size);

    for (final cell in cells) {
      final house = _houseOf(cell);
      if (house == selectedHouse) {
        canvas.drawPath(cell.path, Paint()..color = colors.secondary.withValues(alpha: 0.25));
      }
      if (house == 1 && style != 'North') {
        canvas.drawPath(cell.path, Paint()..color = colors.primary.withValues(alpha: 0.12));
      }
      canvas.drawPath(cell.path, linePaint);
    }

    final double cellScale = style == 'North' ? size.width / 5.5 : size.width / (style == 'South' ? 4.4 : 3.6);

    for (final cell in cells) {
      final house = _houseOf(cell);
      final sign = _signOf(cell);

      // Sign number (North) or "Asc" marker in the Lagna cell (South/East).
      final label = style == 'North' ? '${sign + 1}' : (house == 1 ? tr('Asc', 'लग्न') : '');
      if (label.isNotEmpty) {
        final numPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: fontFamily, fontFamilyFallback: const ['NotoSansDevanagari']),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        numPainter.paint(canvas, cell.numberPos - Offset(numPainter.width / 2, numPainter.height / 2));
      }

      final planets = housePlanets[house];
      if (planets == null || planets.isEmpty) continue;

      // Shrink the font until all labels fit inside the cell.
      double fontSize = 13;
      late TextPainter tp;
      while (true) {
        tp = TextPainter(
          text: TextSpan(
            style: TextStyle(color: colors.onSurface, fontSize: fontSize, fontWeight: FontWeight.bold, height: 1.15, fontFamily: fontFamily, fontFamilyFallback: const ['NotoSansDevanagari']),
            children: [
              for (int i = 0; i < planets.length; i++) ...[
                if (i > 0) const TextSpan(text: '\n'),
                TextSpan(text: planets[i].abbreviation, style: TextStyle(color: planetColor(planets[i].planet, colors.brightness, colors.onSurface))),
                if (planets[i].degree != null)
                  TextSpan(text: ChartLabel.superscript(planets[i].degree!), style: TextStyle(color: colors.onSurface.withValues(alpha: 0.75), fontSize: fontSize * 0.9)),
                if (planets[i].markers.isNotEmpty) TextSpan(text: planets[i].markers, style: TextStyle(color: colors.primary)),
              ],
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: cellScale);
        if (tp.height <= cellScale * 0.8 || fontSize <= 7) break;
        fontSize -= 1;
      }
      tp.paint(canvas, cell.center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant KundliChartPainter old) {
    return old.housePlanets != housePlanets ||
        old.selectedHouse != selectedHouse ||
        old.ascendantSign != ascendantSign ||
        old.style != style ||
        old.colors != colors ||
        old.fontFamily != fontFamily;
  }
}

/// Birth chart drawn in the North, South or East Indian style (from Settings).
class KundliChart extends ConsumerStatefulWidget {
  /// Planet labels per house (1-12, counted from the ascendant).
  final Map<int, List<ChartLabel>> housePlanets;
  final void Function(int house) onHouseTapped;

  /// Ascendant sign, 1-based (1 = Aries).
  final int? ascendantSign;

  /// Overrides the chart style from Settings ('North', 'South', 'East').
  final String? style;

  /// Shows the marker key below the chart.
  final bool showLegend;

  const KundliChart({
    super.key,
    required this.housePlanets,
    required this.onHouseTapped,
    this.ascendantSign,
    this.style,
    this.showLegend = false,
  });

  @override
  ConsumerState<KundliChart> createState() => _KundliChartState();
}

class _KundliChartState extends ConsumerState<KundliChart> {
  int? _selectedHouse;

  @override
  Widget build(BuildContext context) {
    final String style = widget.style ?? ref.watch(settingsProvider).chartStyle;
    final asc = widget.ascendantSign ?? 1;
    final chart = AspectRatio(
      aspectRatio: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onTapUp: (details) {
                for (final cell in _cellsFor(style, size)) {
                  if (cell.path.contains(details.localPosition)) {
                    final house = cell.house ?? ((cell.sign! - (asc - 1) + 12) % 12 + 1);
                    setState(() => _selectedHouse = house);
                    widget.onHouseTapped(house);
                    break;
                  }
                }
              },
              child: CustomPaint(
                size: size,
                painter: KundliChartPainter(widget.housePlanets, _selectedHouse, asc, style, Theme.of(context).colorScheme,
                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily),
              ),
            );
          },
        ),
      ),
    );
    if (!widget.showLegend) return chart;
    return Column(mainAxisSize: MainAxisSize.min, children: [chart, const ChartLegend()]);
  }
}
