import 'package:flutter/material.dart';
import '../core/l10n.dart';

/// Card with a title used by the analysis screens.
class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? trailing;
  const SectionCard({super.key, required this.title, this.subtitle, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: scheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// "Label ........ value" row that wraps instead of overflowing.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  const KeyValueRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Bulleted line with an optional leading mark (✓ ✗ △).
class BulletLine extends StatelessWidget {
  final String text;
  final String mark;
  final Color? color;
  final String? tag;
  const BulletLine(this.text, {super.key, this.mark = '•', this.color, this.tag});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Text(mark, style: TextStyle(color: color ?? scheme.secondary, fontWeight: FontWeight.bold))),
          Expanded(
            child: Text.rich(TextSpan(children: [
              if (tag != null) TextSpan(text: '$tag  ', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
              TextSpan(text: text, style: const TextStyle(fontSize: 13, height: 1.35)),
            ])),
          ),
        ],
      ),
    );
  }
}

/// Small pill label.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

/// Compact table that scrolls sideways on narrow screens instead of overflowing.
class CompactTable extends StatelessWidget {
  final List<String> header;
  final List<List<String>> rows;
  final double minColumnWidth;
  const CompactTable({super.key, required this.header, required this.rows, this.minColumnWidth = 56});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
          decoration: head ? BoxDecoration(color: scheme.primary.withValues(alpha: 0.12)) : null,
          children: [
            for (final c in cells)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Text(c, style: TextStyle(fontSize: 12, fontWeight: head ? FontWeight.bold : FontWeight.normal)),
              ),
          ],
        );
    return LayoutBuilder(builder: (context, constraints) {
      final width = header.length * minColumnWidth;
      final table = Table(
        border: TableBorder.all(color: scheme.outline.withValues(alpha: 0.4)),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [row(header, head: true), for (final r in rows) row(r)],
      );
      if (width <= constraints.maxWidth) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Table(
            border: TableBorder.all(color: scheme.outline.withValues(alpha: 0.4)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [row(header, head: true), for (final r in rows) row(r)],
          ),
        );
      }
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
    });
  }
}

/// Horizontal strength bar with a marker at 1.0 (the minimum requirement).
class RatioBar extends StatelessWidget {
  final double ratio;
  final double max;
  const RatioBar(this.ratio, {super.key, this.max = 2});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = ratio >= 1 ? Colors.green : scheme.error;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return SizedBox(
        height: 12,
        child: Stack(children: [
          Container(decoration: BoxDecoration(color: scheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6))),
          Container(
            width: (ratio / max).clamp(0, 1) * w,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          ),
          Positioned(left: w / max - 1, top: 0, bottom: 0, child: Container(width: 2, color: scheme.onSurface)),
        ]),
      );
    });
  }
}

/// "In simple words" box with a plain-language explanation.
class SimpleMeaningCard extends StatelessWidget {
  final List<String> paragraphs;
  final String? title;
  final bool card;
  const SimpleMeaningCard(this.paragraphs, {super.key, this.title, this.card = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.lightbulb_outline, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(title ?? tr('In simple words', 'आसान भाषा में'),
              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ]),
      const SizedBox(height: 6),
      for (final p in paragraphs)
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(p, style: const TextStyle(fontSize: 13.5, height: 1.45))),
    ]);
    if (!card) return body;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: body,
    );
  }
}
