import 'dart:math' as math;

import 'package:flutter/material.dart';

class JeevanSutraLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final double progress;

  const JeevanSutraLogo({
    super.key,
    this.size = 420,
    this.showTagline = true,
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _JeevanSutraLogoPainter(
          progress: progress.clamp(0.0, 1.0),
          showTagline: showTagline,
        ),
      ),
    );
  }
}

class _JeevanSutraLogoPainter extends CustomPainter {
  final double progress;
  final bool showTagline;

  static const Color deepGreen = Color(0xFF183B2A);
  static const Color gold = Color(0xFFB89452);
  static const Color lightGold = Color(0xFFD9BC74);
  static const Color cream = Color(0xFFF8F5EC);

  _JeevanSutraLogoPainter({
    required this.progress,
    required this.showTagline,
  });

  double _segment(
    double start,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    if (progress <= start) {
      return 0.0;
    }

    if (progress >= end) {
      return 1.0;
    }

    return curve.transform(
      ((progress - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = math.min(
          size.width,
          size.height,
        ) /
        1000.0;

    canvas.save();

    canvas.translate(
      size.width / 2,
      size.height / 2,
    );

    canvas.scale(scale);

    _drawBackground(canvas);
    _drawSubtleMandala(canvas);
    _drawBorder(canvas);
    _drawEmblem(canvas);
    _drawBrandName(canvas);
    _drawTagline(canvas);

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND
  // ---------------------------------------------------------------------------

  void _drawBackground(Canvas canvas) {
    final Paint background = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.25),
        radius: 1.05,
        colors: [
          Color(0xFFFFFFFF),
          cream,
          Color(0xFFF0EADD),
        ],
        stops: [
          0.0,
          0.70,
          1.0,
        ],
      ).createShader(
        const Rect.fromLTWH(
          -500,
          -500,
          1000,
          1000,
        ),
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(
          -470,
          -470,
          470,
          470,
        ),
        const Radius.circular(92),
      ),
      background,
    );
  }

  // ---------------------------------------------------------------------------
  // SUBTLE MANDALA
  // ---------------------------------------------------------------------------

  void _drawSubtleMandala(Canvas canvas) {
    final double reveal = _segment(
      0.0,
      0.35,
      curve: Curves.easeOut,
    );

    if (reveal <= 0) {
      return;
    }

    final Paint line = Paint()
      ..color = gold.withValues(
        alpha: 0.045 * reveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double radius = 345;

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset.zero,
        radius - (i * 32),
        line,
      );
    }

    const int petalCount = 24;

    for (int i = 0; i < petalCount; i++) {
      final double angle =
          i * math.pi * 2 / petalCount;

      final double x =
          math.cos(angle) * radius * 0.85;

      final double y =
          math.sin(angle) * radius * 0.85;

      canvas.save();

      canvas.translate(x, y);
      canvas.rotate(angle);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 28,
          height: 82,
        ),
        line,
      );

      canvas.restore();
    }
  }

  // ---------------------------------------------------------------------------
  // DOUBLE BORDER
  // ---------------------------------------------------------------------------

  void _drawBorder(Canvas canvas) {
    final double reveal = _segment(
      0.05,
      0.45,
      curve: Curves.easeInOutCubic,
    );

    if (reveal <= 0) {
      return;
    }

    final Rect outerRect = Rect.fromLTRB(
      -448,
      -448,
      448,
      448,
    );

    final Rect innerRect = Rect.fromLTRB(
      -433,
      -433,
      433,
      433,
    );

    final Paint outerPaint = Paint()
      ..color = gold.withValues(
        alpha: 0.92 * reveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;

    final Paint innerPaint = Paint()
      ..color = deepGreen.withValues(
        alpha: 0.20 * reveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        outerRect,
        const Radius.circular(86),
      ),
      outerPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect,
        const Radius.circular(76),
      ),
      innerPaint,
    );

    _drawCornerOrnaments(
      canvas,
      reveal,
    );
  }

  void _drawCornerOrnaments(
    Canvas canvas,
    double reveal,
  ) {
    final Paint paint = Paint()
      ..color = gold.withValues(
        alpha: 0.55 * reveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const double left = -394;
    const double right = 394;
    const double top = -394;
    const double bottom = 394;
    const double length = 24;

    final Path topLeft = Path()
      ..moveTo(
        left,
        top + length,
      )
      ..quadraticBezierTo(
        left,
        top,
        left + length,
        top,
      );

    final Path topRight = Path()
      ..moveTo(
        right - length,
        top,
      )
      ..quadraticBezierTo(
        right,
        top,
        right,
        top + length,
      );

    final Path bottomLeft = Path()
      ..moveTo(
        left,
        bottom - length,
      )
      ..quadraticBezierTo(
        left,
        bottom,
        left + length,
        bottom,
      );

    final Path bottomRight = Path()
      ..moveTo(
        right - length,
        bottom,
      )
      ..quadraticBezierTo(
        right,
        bottom,
        right,
        bottom - length,
      );

    canvas.drawPath(topLeft, paint);
    canvas.drawPath(topRight, paint);
    canvas.drawPath(bottomLeft, paint);
    canvas.drawPath(bottomRight, paint);
  }

  // ---------------------------------------------------------------------------
  // MAIN EMBLEM
  // ---------------------------------------------------------------------------

  void _drawEmblem(Canvas canvas) {
    final double reveal = _segment(
      0.18,
      0.68,
      curve: Curves.easeOutBack,
    );

    if (reveal <= 0) {
      return;
    }

    canvas.save();

    final double scale =
        0.84 + (0.16 * reveal);

    canvas.scale(scale);

    _drawMainJ(canvas, reveal);
    _drawInnerLeaf(canvas, reveal);
    _drawRightLeaves(canvas, reveal);
    _drawMeditationSymbol(canvas, reveal);
    _drawTopBotanicalSymbol(canvas, reveal);
    _drawOuterGoldenArc(canvas, reveal);

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // MAIN J
  // ---------------------------------------------------------------------------

  void _drawMainJ(
    Canvas canvas,
    double reveal,
  ) {
    final Path j = Path();

    j.moveTo(25, -305);
    j.lineTo(130, -305);
    j.lineTo(130, 95);

    j.cubicTo(
      130,
      210,
      75,
      275,
      -30,
      275,
    );

    j.cubicTo(
      -135,
      275,
      -218,
      208,
      -218,
      100,
    );

    j.cubicTo(
      -218,
      40,
      -190,
      -15,
      -142,
      -42,
    );

    j.lineTo(
      -87,
      36,
    );

    j.cubicTo(
      -116,
      53,
      -130,
      76,
      -130,
      105,
    );

    j.cubicTo(
      -130,
      161,
      -90,
      191,
      -36,
      191,
    );

    j.cubicTo(
      22,
      191,
      25,
      148,
      25,
      89,
    );

    j.close();

    final Paint fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF326D52),
          Color(0xFF1E4734),
          Color(0xFF123021),
        ],
        stops: [
          0.0,
          0.58,
          1.0,
        ],
      ).createShader(
        const Rect.fromLTRB(
          -250,
          -320,
          160,
          290,
        ),
      );

    fill.color = Color.lerp(
      Colors.transparent,
      deepGreen,
      reveal,
    )!;

    canvas.drawPath(
      j,
      fill,
    );

    final Paint edgeGlow = Paint()
      ..color = gold.withValues(
        alpha: 0.26 * reveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawPath(
      j,
      edgeGlow,
    );

    final Paint edge = Paint()
      ..color = gold.withValues(
        alpha: reveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      j,
      edge,
    );

    final Paint highlight = Paint()
      ..color = lightGold.withValues(
        alpha: 0.80 * reveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Path flowingHighlight = Path()
      ..moveTo(65, -255)
      ..cubicTo(
        55,
        -135,
        63,
        -10,
        54,
        85,
      )
      ..cubicTo(
        49,
        142,
        25,
        183,
        -24,
        195,
      );

    canvas.drawPath(
      flowingHighlight,
      highlight,
    );
  }

  // ---------------------------------------------------------------------------
  // INNER LEAF
  // ---------------------------------------------------------------------------

  void _drawInnerLeaf(
    Canvas canvas,
    double reveal,
  ) {
    final double leafReveal = _segment(
      0.30,
      0.63,
      curve: Curves.easeOutBack,
    );

    if (leafReveal <= 0) {
      return;
    }

    final Path leaf = Path()
      ..moveTo(38, 55)
      ..cubicTo(
        78,
        12,
        122,
        8,
        151,
        33,
      )
      ..cubicTo(
        129,
        76,
        90,
        100,
        48,
        82,
      )
      ..close();

    final Paint fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF93C96D),
          Color(0xFF3E7D4D),
          Color(0xFF245238),
        ],
      ).createShader(
        const Rect.fromLTRB(
          35,
          5,
          160,
          105,
        ),
      );

    canvas.drawPath(
      leaf,
      fill,
    );

    final Paint outline = Paint()
      ..color = gold.withValues(
        alpha: 0.82 * leafReveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(
      leaf,
      outline,
    );

    final Paint vein = Paint()
      ..color = lightGold.withValues(
        alpha: 0.72 * leafReveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      const Offset(46, 77),
      const Offset(130, 31),
      vein,
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT LEAVES
  // ---------------------------------------------------------------------------

  void _drawRightLeaves(
    Canvas canvas,
    double reveal,
  ) {
    final double leafReveal = _segment(
      0.37,
      0.70,
      curve: Curves.easeOutBack,
    );

    if (leafReveal <= 0) {
      return;
    }

    _drawLeaf(
      canvas: canvas,
      center: const Offset(160, 50),
      width: 100,
      height: 190,
      rotation: -0.56,
      progress: leafReveal,
      light: true,
    );

    _drawLeaf(
      canvas: canvas,
      center: const Offset(205, 135),
      width: 92,
      height: 175,
      rotation: -0.18,
      progress: leafReveal,
      light: false,
    );

    _drawLeaf(
      canvas: canvas,
      center: const Offset(176, 220),
      width: 100,
      height: 175,
      rotation: 0.32,
      progress: leafReveal,
      light: true,
    );
  }

  void _drawLeaf({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required double rotation,
    required double progress,
    required bool light,
  }) {
    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(rotation);

    canvas.scale(
      progress,
      progress,
    );

    final Path leaf = Path()
      ..moveTo(
        0,
        -height / 2,
      )
      ..cubicTo(
        width / 2,
        -height * 0.30,
        width / 2,
        height * 0.26,
        0,
        height / 2,
      )
      ..cubicTo(
        -width / 2,
        height * 0.26,
        -width / 2,
        -height * 0.30,
        0,
        -height / 2,
      )
      ..close();

    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: light
            ? const [
                Color(0xFF9ACD72),
                Color(0xFF4D9550),
                Color(0xFF245538),
              ]
            : const [
                Color(0xFF67A65B),
                Color(0xFF2F7048),
                Color(0xFF19422E),
              ],
      ).createShader(
        Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        ),
      );

    canvas.drawPath(
      leaf,
      fill,
    );

    final Paint outline = Paint()
      ..color = gold.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    canvas.drawPath(
      leaf,
      outline,
    );

    final Paint vein = Paint()
      ..color = cream.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, -height * 0.40),
      Offset(0, height * 0.39),
      vein,
    );

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // MEDITATION / LOTUS SYMBOL
  // ---------------------------------------------------------------------------

  void _drawMeditationSymbol(
    Canvas canvas,
    double reveal,
  ) {
    final double symbolReveal = _segment(
      0.42,
      0.72,
      curve: Curves.easeOutBack,
    );

    if (symbolReveal <= 0) {
      return;
    }

    final Paint symbol = Paint()
      ..color = cream.withValues(
        alpha: symbolReveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint head = Paint()
      ..color = cream.withValues(
        alpha: symbolReveal,
      );

    canvas.drawCircle(
      const Offset(0, 122),
      17,
      head,
    );

    final Path body = Path()
      ..moveTo(0, 140)
      ..cubicTo(
        -5,
        169,
        -18,
        189,
        -45,
        207,
      )
      ..moveTo(0, 140)
      ..cubicTo(
        5,
        169,
        18,
        189,
        45,
        207,
      );

    canvas.drawPath(
      body,
      symbol,
    );

    final Path arms = Path()
      ..moveTo(-7, 163)
      ..quadraticBezierTo(
        -50,
        170,
        -69,
        198,
      )
      ..moveTo(7, 163)
      ..quadraticBezierTo(
        50,
        170,
        69,
        198,
      );

    canvas.drawPath(
      arms,
      symbol,
    );

    final Path lotus = Path()
      ..moveTo(-78, 211)
      ..quadraticBezierTo(
        -48,
        204,
        0,
        228,
      )
      ..quadraticBezierTo(
        48,
        204,
        78,
        211,
      )
      ..quadraticBezierTo(
        45,
        260,
        0,
        263,
      )
      ..quadraticBezierTo(
        -45,
        260,
        -78,
        211,
      );

    canvas.drawPath(
      lotus,
      symbol,
    );

    final Path diamond = Path()
      ..moveTo(0, 209)
      ..lineTo(17, 230)
      ..lineTo(0, 249)
      ..lineTo(-17, 230)
      ..close();

    final Paint diamondPaint = Paint()
      ..color = gold.withValues(
        alpha: 0.96 * symbolReveal,
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      diamond,
      diamondPaint,
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BOTANICAL SYMBOL
  // ---------------------------------------------------------------------------

  void _drawTopBotanicalSymbol(
    Canvas canvas,
    double reveal,
  ) {
    final double topReveal = _segment(
      0.50,
      0.78,
      curve: Curves.easeOutBack,
    );

    if (topReveal <= 0) {
      return;
    }

    canvas.save();

    canvas.translate(
      0,
      -352,
    );

    canvas.scale(
      topReveal,
      topReveal,
    );

    _drawSmallTopLeaf(
      canvas,
      const Offset(-50, 0),
      -0.55,
    );

    _drawSmallTopLeaf(
      canvas,
      const Offset(50, 0),
      0.55,
    );

    final Path centerLeaf = Path()
      ..moveTo(0, -12)
      ..cubicTo(
        30,
        22,
        25,
        60,
        0,
        84,
      )
      ..cubicTo(
        -25,
        60,
        -30,
        22,
        0,
        -12,
      )
      ..close();

    final Paint fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE1C47E),
          Color(0xFFB89452),
        ],
      ).createShader(
        const Rect.fromLTRB(
          -35,
          -15,
          35,
          90,
        ),
      );

    canvas.drawPath(
      centerLeaf,
      fill,
    );

    final Paint opening = Paint()
      ..color = cream;

    final Path inner = Path()
      ..moveTo(0, 14)
      ..cubicTo(
        12,
        33,
        12,
        48,
        0,
        60,
      )
      ..cubicTo(
        -12,
        48,
        -12,
        33,
        0,
        14,
      )
      ..close();

    canvas.drawPath(
      inner,
      opening,
    );

    canvas.restore();
  }

  void _drawSmallTopLeaf(
    Canvas canvas,
    Offset center,
    double rotation,
  ) {
    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(rotation);

    final Path leaf = Path()
      ..moveTo(0, -8)
      ..cubicTo(
        31,
        -31,
        49,
        -23,
        56,
        -8,
      )
      ..cubicTo(
        36,
        5,
        17,
        10,
        0,
        -8,
      )
      ..close();

    final Paint fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7CAF63),
          Color(0xFF2F6B4F),
        ],
      ).createShader(
        const Rect.fromLTRB(
          -5,
          -35,
          65,
          15,
        ),
      );

    canvas.drawPath(
      leaf,
      fill,
    );

    final Paint outline = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(
      leaf,
      outline,
    );

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // OUTER GOLD ARC
  // ---------------------------------------------------------------------------

  void _drawOuterGoldenArc(
    Canvas canvas,
    double reveal,
  ) {
    final double arcReveal = _segment(
      0.30,
      0.76,
      curve: Curves.easeInOutCubic,
    );

    if (arcReveal <= 0) {
      return;
    }

    final Rect rect = Rect.fromCircle(
      center: Offset.zero,
      radius: 335,
    );

    final Paint glow = Paint()
      ..color = gold.withValues(
        alpha: 0.16 * arcReveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        12,
      );

    final Paint line = Paint()
      ..color = gold.withValues(
        alpha: 0.95 * arcReveal,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double start = -1.18;
    const double sweep = 4.65;

    canvas.drawArc(
      rect,
      start,
      sweep * arcReveal,
      false,
      glow,
    );

    canvas.drawArc(
      rect,
      start,
      sweep * arcReveal,
      false,
      line,
    );
  }

  // ---------------------------------------------------------------------------
  // BRAND NAME
  // ---------------------------------------------------------------------------

  void _drawBrandName(Canvas canvas) {
    final double reveal = _segment(
      0.60,
      0.84,
      curve: Curves.easeOutCubic,
    );

    if (reveal <= 0) {
      return;
    }

    final double y = 285;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: 'JEEVAN SUTRA',
        style: TextStyle(
          color: deepGreen.withValues(
            alpha: reveal,
          ),
          fontSize: 54,
          fontWeight: FontWeight.w700,
          letterSpacing: 6.2,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double x =
        -painter.width / 2;

    final TextPainter shadowPainter = TextPainter(
      text: TextSpan(
        text: 'JEEVAN SUTRA',
        style: TextStyle(
          color: gold.withValues(
            alpha: 0.14 * reveal,
          ),
          fontSize: 54,
          fontWeight: FontWeight.w700,
          letterSpacing: 6.2,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    shadowPainter.paint(
      canvas,
      Offset(
        x + 1,
        y + 2,
      ),
    );

    painter.paint(
      canvas,
      Offset(
        x,
        y,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAGLINE
  // ---------------------------------------------------------------------------

  void _drawTagline(Canvas canvas) {
    if (!showTagline) {
      return;
    }

    final double reveal = _segment(
      0.72,
      0.90,
      curve: Curves.easeOut,
    );

    if (reveal <= 0) {
      return;
    }

    const double y = 365;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: 'Ancient wisdom. Modern living.',
        style: TextStyle(
          color: deepGreen.withValues(
            alpha: reveal,
          ),
          fontSize: 25,
          fontWeight: FontWeight.w400,
          letterSpacing: 2.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        -painter.width / 2,
        y,
      ),
    );

    final Paint divider = Paint()
      ..color = gold.withValues(
        alpha: 0.82 * reveal,
      )
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(-240, 421),
      const Offset(-55, 421),
      divider,
    );

    canvas.drawLine(
      const Offset(55, 421),
      const Offset(240, 421),
      divider,
    );

    _drawTinyLotus(
      canvas,
      reveal,
    );
  }

  void _drawTinyLotus(
    Canvas canvas,
    double reveal,
  ) {
    final Paint paint = Paint()
      ..color = gold.withValues(
        alpha: 0.92 * reveal,
      )
      ..style = PaintingStyle.fill;

    final Path lotus = Path()
      ..moveTo(0, 400)
      ..cubicTo(
        -15,
        382,
        -24,
        384,
        -27,
        396,
      )
      ..cubicTo(
        -20,
        412,
        -10,
        417,
        0,
        421,
      )
      ..cubicTo(
        10,
        417,
        20,
        412,
        27,
        396,
      )
      ..cubicTo(
        24,
        384,
        15,
        382,
        0,
        400,
      )
      ..close();

    canvas.drawPath(
      lotus,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _JeevanSutraLogoPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.showTagline != showTagline;
  }
}
