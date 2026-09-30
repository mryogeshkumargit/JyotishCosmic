import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ephemeris.dart';
import '../core/vedic_math.dart';
import '../providers/settings_provider.dart';

/// Builds per-house planet labels ("Su 12°", "Sa 3°ᴿ") for [KundliChart].
Map<int, List<String>> buildHouseLabels(
  Map<String, double> longitudes,
  int lagnaRashi, {
  Map<String, double> speeds = const {},
  Map<String, int>? signOverride,
  bool showDegrees = true,
}) {
  final Map<int, List<String>> houses = {for (int i = 1; i <= 12; i++) i: []};
  for (final planet in Ephemeris.planetOrder) {
    final sid = longitudes[planet];
    if (sid == null) continue;
    final sign = signOverride?[planet] ?? VedicMath.rashiIndex(sid);
    final house = VedicMath.houseOf(sign, lagnaRashi);
    final retro = planet != 'rahu' && planet != 'ketu' && (speeds[planet] ?? 0) < 0;
    final deg = showDegrees ? ' ${VedicMath.degInRashi(sid).floor()}°' : '';
    houses[house]!.add('${Ephemeris.planetAbbreviations[planet]}$deg${retro ? 'ᴿ' : ''}');
  }
  return houses;
}

/// Labels for a [ChartData] (degrees + retrograde markers).
Map<int, List<String>> chartLabels(ChartData chart) =>
    buildHouseLabels(chart.planetLongitudes, chart.lagnaRashi, speeds: chart.planetSpeeds);

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
  final Map<int, List<String>> housePlanets;
  final int? selectedHouse;
  final int ascendantSign; // 1-based (1 = Aries)
  final String style;
  final ColorScheme colors;

  KundliChartPainter(this.housePlanets, this.selectedHouse, this.ascendantSign, this.style, this.colors);

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
      final label = style == 'North' ? '${sign + 1}' : (house == 1 ? 'Asc' : '');
      if (label.isNotEmpty) {
        final numPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.w600),
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
            text: planets.join('\n'),
            style: TextStyle(color: colors.onSurface, fontSize: fontSize, fontWeight: FontWeight.bold, height: 1.1),
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
        old.colors != colors;
  }
}

/// Birth chart drawn in the North, South or East Indian style (from Settings).
class KundliChart extends ConsumerStatefulWidget {
  /// Planet labels per house (1-12, counted from the ascendant).
  final Map<int, List<String>> housePlanets;
  final void Function(int house) onHouseTapped;

  /// Ascendant sign, 1-based (1 = Aries).
  final int? ascendantSign;

  /// Overrides the chart style from Settings ('North', 'South', 'East').
  final String? style;

  const KundliChart({
    super.key,
    required this.housePlanets,
    required this.onHouseTapped,
    this.ascendantSign,
    this.style,
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
    return AspectRatio(
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
                painter: KundliChartPainter(
                    widget.housePlanets, _selectedHouse, asc, style, Theme.of(context).colorScheme),
              ),
            );
          },
        ),
      ),
    );
  }
}
