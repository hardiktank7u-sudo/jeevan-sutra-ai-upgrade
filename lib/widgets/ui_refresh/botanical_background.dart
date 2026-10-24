// Reusable Botanical Background CustomPainter for Flutter
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/jeevan_sutra_ui_theme.dart';


class BotanicalBackground extends StatelessWidget {
  final Widget child;
  final bool showFloatingNodes;
  final double opacity;

  const BotanicalBackground({
    super.key,
    required this.child,
    this.showFloatingNodes = true,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? JeevanSutraColors.freshLeaf : JeevanSutraColors.forestGreen;
    final goldColor = JeevanSutraColors.mutedGold;

    return Stack(
      children: [
        // Opaque routes need their own canvas beneath the translucent artwork.
        Positioned.fill(
          child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        // Subtle ambient radial gradients
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  goldColor.withValues(alpha: isDark ? 0.08 : 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Custom Painted botanical leaf veins & sacred mandala geometry
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BotanicalMotifPainter(
                color: primaryColor.withValues(alpha: opacity),
                accentColor: goldColor.withValues(alpha: opacity * 0.9),
                showNodes: showFloatingNodes,
              ),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}

class _BotanicalMotifPainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final bool showNodes;

  _BotanicalMotifPainter({
    required this.color,
    required this.accentColor,
    required this.showNodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final paintAccent = Paint()
      ..color = accentColor
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Top Right Botanical Leaf Silhouette
    final leafPath = Path();
    leafPath.moveTo(size.width * 0.75, 0);
    leafPath.cubicTo(
      size.width * 0.95, size.height * 0.08,
      size.width, size.height * 0.22,
      size.width * 0.85, size.height * 0.32,
    );
    leafPath.cubicTo(
      size.width * 0.65, size.height * 0.22,
      size.width * 0.68, size.height * 0.06,
      size.width * 0.75, 0,
    );
    canvas.drawPath(leafPath, paintLine);

    // Leaf Central Rib & Veins
    final veinRib = Path();
    veinRib.moveTo(size.width * 0.75, 0);
    veinRib.quadraticBezierTo(
      size.width * 0.82, size.height * 0.16,
      size.width * 0.85, size.height * 0.32,
    );
    canvas.drawPath(veinRib, paintLine);

    // Fine organic lateral branch lines
    for (int i = 1; i <= 4; i++) {
      double t = i * 0.18;
      canvas.drawLine(
        Offset(size.width * (0.75 + t * 0.08), size.height * (t * 0.3)),
        Offset(size.width * (0.88 - t * 0.02), size.height * (t * 0.26)),
        paintAccent,
      );
    }

    // Sacred Geometry Mandala Accent in Bottom-Left
    final center = Offset(size.width * 0.15, size.height * 0.82);
    const radius = 64.0;
    canvas.drawCircle(center, radius, paintAccent);
    canvas.drawCircle(center, radius * 0.6, paintLine);

    // 8-petal delicate geometry
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final p1 = Offset(
        center.dx + radius * 0.6 * math.cos(angle),
        center.dy + radius * 0.6 * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle + math.pi / 8),
        center.dy + radius * math.sin(angle + math.pi / 8),
      );
      canvas.drawLine(center, p1, paintLine);
      canvas.drawLine(p1, p2, paintAccent);
    }

    // Molecular / Herbal Node Connections
    if (showNodes) {
      final nodes = [
        Offset(size.width * 0.1, size.height * 0.28),
        Offset(size.width * 0.22, size.height * 0.24),
        Offset(size.width * 0.28, size.height * 0.35),
        Offset(size.width * 0.88, size.height * 0.65),
        Offset(size.width * 0.78, size.height * 0.72),
      ];

      for (int i = 0; i < nodes.length - 1; i++) {
        if (i != 2) {
          canvas.drawLine(nodes[i], nodes[i + 1], paintAccent);
        }
      }

      for (final node in nodes) {
        canvas.drawCircle(node, 2.5, paintDot);
        canvas.drawCircle(node, 6.0, paintAccent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BotanicalMotifPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.accentColor != accentColor;
  }
}



