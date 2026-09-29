import 'package:flutter/material.dart';

class KundliChartPainter extends CustomPainter {
  final Map<int, List<String>> housePlanets; 
  final int? selectedHouse;
  final int? ascendantSign;
  final BuildContext context;

  KundliChartPainter(this.housePlanets, this.selectedHouse, this.ascendantSign, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Theme.of(context).colorScheme.secondary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    // Highlight selected house
    if (selectedHouse != null && selectedHouse! >= 1 && selectedHouse! <= 12) {
      final Paint highlightPaint = Paint()
        ..color = Theme.of(context).colorScheme.secondary.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawPath(KundliChart.getHousePath(selectedHouse!, w, h), highlightPaint);
    }

    // Draw the main square
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);
    
    // Draw the inner diagonals (X)
    canvas.drawLine(const Offset(0, 0), Offset(w, h), linePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), linePaint);

    // Draw the inner diamonds
    canvas.drawLine(Offset(w/2, 0), Offset(w, h/2), linePaint);
    canvas.drawLine(Offset(w, h/2), Offset(w/2, h), linePaint);
    canvas.drawLine(Offset(w/2, h), Offset(0, h/2), linePaint);
    canvas.drawLine(Offset(0, h/2), Offset(w/2, 0), linePaint);

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < 12; i++) {
      int houseNum = i + 1;
      List<String>? planets = housePlanets[houseNum];
      Offset center = KundliChart.getHouseCenter(houseNum, w, h);
      
      if (planets != null && planets.isNotEmpty) {
        textPainter.text = TextSpan(
          text: planets.join(' '),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        
        Offset textOffset = Offset(center.dx - textPainter.width/2, center.dy - textPainter.height/2);
        textPainter.paint(canvas, textOffset);
      }
      
      // Draw sign numbers (small) if ascendantSign is provided, otherwise house number
      int signNumToDraw = houseNum;
      if (ascendantSign != null) {
        signNumToDraw = ((ascendantSign! + houseNum - 2) % 12) + 1;
      }
      
      final TextPainter numPainter = TextPainter(
        text: TextSpan(
          text: '$signNumToDraw',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      numPainter.layout();
      numPainter.paint(canvas, Offset(center.dx, center.dy - 20));
    }
  }

  @override
  bool shouldRepaint(covariant KundliChartPainter oldDelegate) {
    return oldDelegate.housePlanets != housePlanets || oldDelegate.selectedHouse != selectedHouse || oldDelegate.ascendantSign != ascendantSign;
  }
}

class KundliChart extends StatefulWidget {
  final Map<int, List<String>> housePlanets;
  final Function(int) onHouseTapped;
  final int? ascendantSign;
  
  const KundliChart({super.key, required this.housePlanets, required this.onHouseTapped, this.ascendantSign});

  // Helper functions for math geometry
  static Path getHousePath(int house, double w, double h) {
    Path p = Path();
    switch (house) {
      case 1: p.moveTo(w/2, 0); p.lineTo(3*w/4, h/4); p.lineTo(w/2, h/2); p.lineTo(w/4, h/4); break;
      case 2: p.moveTo(0, 0); p.lineTo(w/2, 0); p.lineTo(w/4, h/4); break;
      case 3: p.moveTo(0, 0); p.lineTo(w/4, h/4); p.lineTo(0, h/2); break;
      case 4: p.moveTo(0, h/2); p.lineTo(w/4, h/4); p.lineTo(w/2, h/2); p.lineTo(w/4, 3*h/4); break;
      case 5: p.moveTo(0, h); p.lineTo(0, h/2); p.lineTo(w/4, 3*h/4); break;
      case 6: p.moveTo(0, h); p.lineTo(w/4, 3*h/4); p.lineTo(w/2, h); break;
      case 7: p.moveTo(w/2, h); p.lineTo(w/4, 3*h/4); p.lineTo(w/2, h/2); p.lineTo(3*w/4, 3*h/4); break;
      case 8: p.moveTo(w, h); p.lineTo(w/2, h); p.lineTo(3*w/4, 3*h/4); break;
      case 9: p.moveTo(w, h); p.lineTo(3*w/4, 3*h/4); p.lineTo(w, h/2); break;
      case 10: p.moveTo(w, h/2); p.lineTo(3*w/4, 3*h/4); p.lineTo(w/2, h/2); p.lineTo(3*w/4, h/4); break;
      case 11: p.moveTo(w, 0); p.lineTo(w, h/2); p.lineTo(3*w/4, h/4); break;
      case 12: p.moveTo(w, 0); p.lineTo(3*w/4, h/4); p.lineTo(w/2, 0); break;
    }
    p.close();
    return p;
  }

  static Offset getHouseCenter(int house, double w, double h) {
    switch (house) {
      case 1: return Offset(w/2, h/4);
      case 2: return Offset(w/4, h/8);
      case 3: return Offset(w/8, h/4);
      case 4: return Offset(w/4, h/2);
      case 5: return Offset(w/8, 3*h/4);
      case 6: return Offset(w/4, 7*h/8);
      case 7: return Offset(w/2, 3*h/4);
      case 8: return Offset(3*w/4, 7*h/8);
      case 9: return Offset(7*w/8, 3*h/4);
      case 10: return Offset(3*w/4, h/2);
      case 11: return Offset(7*w/8, h/4);
      case 12: return Offset(3*w/4, h/8);
      default: return Offset.zero;
    }
  }

  @override
  State<KundliChart> createState() => _KundliChartState();
}

class _KundliChartState extends State<KundliChart> {
  int? _selectedHouse;

  void _handleTap(TapUpDetails details, Size size) {
    final position = details.localPosition;
    for (int i = 1; i <= 12; i++) {
      if (KundliChart.getHousePath(i, size.width, size.height).contains(position)) {
        setState(() => _selectedHouse = i);
        widget.onHouseTapped(i);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onTapUp: (details) => _handleTap(details, size),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: CustomPaint(
                painter: KundliChartPainter(widget.housePlanets, _selectedHouse, widget.ascendantSign, context),
              ),
            ),
          );
        }
      ),
    );
  }
}
