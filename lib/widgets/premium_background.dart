import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Deep Emerald Base Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF06130C),
                  Color(0xFF091C12),
                  Color(0xFF0C2417),
                  Color(0xFF08170F),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Atmospheric Gold & Emerald Glows
        Positioned.fill(
          child: CustomPaint(
            painter: _RoyalAtmospherePainter(),
          ),
        ),

        // Intricate Botanical & Sacred Mandala Watermark
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RoyalMandalaWatermarkPainter(),
            ),
          ),
        ),

        // Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _RoyalAtmospherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-Center Golden Divine Sheen
    final topSheen = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.gold.withValues(alpha: 0.12),
          AppTheme.gold.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, 0),
          radius: 280,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.5, 0),
      280,
      topSheen,
    );

    // Deep Emerald Radiant Orb (Center-Right)
    final emeraldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1B4E36).withValues(alpha: 0.35),
          const Color(0xFF103323).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.9, size.height * 0.45),
          radius: 260,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.45),
      260,
      emeraldGlow,
    );

    // Subtle Amber Warmth (Bottom-Left)
    final bottomGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7A5813).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.85),
          radius: 240,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      240,
      bottomGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoyalMandalaWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gold = AppTheme.gold;

    // Ornate Gold Mandala in the background (Top Center)
    _drawMandala(
      canvas: canvas,
      center: Offset(size.width * 0.5, size.height * 0.14),
      radius: 180,
      color: gold.withValues(alpha: 0.05),
    );

    // Botanical watermark branches on sides
    _drawLeafBranch(
      canvas,
      Offset(size.width * 0.02, size.height * 0.35),
      70,
      gold.withValues(alpha: 0.035),
    );

    _drawLeafBranch(
      canvas,
      Offset(size.width * 0.98, size.height * 0.65),
      -75,
      gold.withValues(alpha: 0.035),
    );
  }

  void _drawMandala({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int ring = 0; ring < 4; ring++) {
      final ringRadius = radius * (0.35 + ring * 0.20);
      canvas.drawCircle(center, ringRadius, paint);
    }

    const petals = 16;
    for (int i = 0; i < petals; i++) {
      final angle = (2 * math.pi / petals) * i;
      final dx = math.cos(angle);
      final dy = math.sin(angle);

      final petalCenter = Offset(
        center.dx + dx * radius * 0.55,
        center.dy + dy * radius * 0.55,
      );

      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, -radius * 0.18)
        ..quadraticBezierTo(radius * 0.12, -radius * 0.03, 0, radius * 0.18)
        ..quadraticBezierTo(-radius * 0.12, -radius * 0.03, 0, -radius * 0.18);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _drawLeafBranch(
    Canvas canvas,
    Offset start,
    double direction,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        start.dx + direction * 0.45,
        start.dy + 38,
        start.dx + direction,
        start.dy + 78,
      );

    canvas.drawPath(path, paint);

    for (int i = 0; i < 4; i++) {
      final x = start.dx + direction * (0.20 + i * 0.18);
      final y = start.dy + 18 + i * 17;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 14,
          height: 7,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
