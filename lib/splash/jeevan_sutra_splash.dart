import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JeevanSutraSplash extends StatefulWidget {
  final VoidCallback onComplete;

  const JeevanSutraSplash({
    super.key,
    required this.onComplete,
  });

  @override
  State<JeevanSutraSplash> createState() => _JeevanSutraSplashState();
}

class _JeevanSutraSplashState extends State<JeevanSutraSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  List<_LogoParticle> _particles = const [];
  bool _ready = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });

    _prepareParticleTargets();
  }

  Future<void> _prepareParticleTargets() async {
    try {
      final List<_LogoParticle> particles = [];

      await _loadParticleTargets(
        particles: particles,
        asset: 'assets/branding/logo_emblem.png',
        stage: _LogoStage.emblem,
        maximumParticles: 520,
        seed: 7142,
      );

      await _loadParticleTargets(
        particles: particles,
        asset: 'assets/branding/logo_wordmark.png',
        stage: _LogoStage.wordmark,
        maximumParticles: 300,
        seed: 1928,
      );

      await _loadParticleTargets(
        particles: particles,
        asset: 'assets/branding/logo_tagline.png',
        stage: _LogoStage.tagline,
        maximumParticles: 150,
        seed: 4581,
      );

      _assignOrigins(
        particles,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _particles = particles;
        _ready = true;
      });

      _controller.forward();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _ready = true;
      });

      _controller.forward();
    }
  }

  Future<void> _loadParticleTargets({
    required List<_LogoParticle> particles,
    required String asset,
    required _LogoStage stage,
    required int maximumParticles,
    required int seed,
  }) async {
    final ByteData data = await rootBundle.load(asset);

    final ui.Codec codec = await ui.instantiateImageCodec(
      Uint8List.sublistView(data),
      targetWidth: 260,
      targetHeight: 260,
    );

    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    final ByteData? pixels = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    codec.dispose();

    if (pixels == null) {
      return;
    }

    final Uint8List bytes = pixels.buffer.asUint8List();

    final List<_TargetPoint> candidates = [];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int index =
            (y * image.width + x) * 4;

        final int alpha = bytes[index + 3];

        if (alpha < 60) {
          continue;
        }

        candidates.add(
          _TargetPoint(
            x: (x + 0.5) / image.width,
            y: (y + 0.5) / image.height,
          ),
        );
      }
    }

    final math.Random random = math.Random(seed);

    candidates.shuffle(random);

    final int amount = math.min(
      maximumParticles,
      candidates.length,
    );

    for (int i = 0; i < amount; i++) {
      final _TargetPoint target = candidates[i];

      particles.add(
        _LogoParticle(
          targetX: target.x,
          targetY: target.y,
          stage: stage,
          seed: random.nextDouble(),
          phase: random.nextDouble() * math.pi * 2,
          speed: 0.7 + random.nextDouble() * 0.7,
        ),
      );
    }
  }

  void _assignOrigins(
    List<_LogoParticle> particles,
  ) {
    final math.Random random = math.Random(81374);

    for (final _LogoParticle particle in particles) {
      final int origin = random.nextInt(8);

      final double distance =
          0.12 + random.nextDouble() * 0.24;

      switch (origin) {
        case 0:
          particle.startX =
              -distance - random.nextDouble() * 0.25;
          particle.startY =
              random.nextDouble();
          break;

        case 1:
          particle.startX =
              1.0 + distance + random.nextDouble() * 0.25;
          particle.startY =
              random.nextDouble();
          break;

        case 2:
          particle.startX =
              random.nextDouble();
          particle.startY =
              -distance - random.nextDouble() * 0.25;
          break;

        case 3:
          particle.startX =
              random.nextDouble();
          particle.startY =
              1.0 + distance + random.nextDouble() * 0.25;
          break;

        case 4:
          particle.startX = -distance;
          particle.startY = -distance;
          break;

        case 5:
          particle.startX = 1.0 + distance;
          particle.startY = -distance;
          break;

        case 6:
          particle.startX = -distance;
          particle.startY = 1.0 + distance;
          break;

        default:
          particle.startX = 1.0 + distance;
          particle.startY = 1.0 + distance;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06160D),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _JeevanSutraSplashScene(
            progress: _controller.value,
            particles: _particles,
            ready: _ready,
          );
        },
      ),
    );
  }
}

class _JeevanSutraSplashScene extends StatelessWidget {
  final double progress;
  final List<_LogoParticle> particles;
  final bool ready;

  const _JeevanSutraSplashScene({
    required this.progress,
    required this.particles,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);

    final double logoSize = math.min(
      screen.width * 0.88,
      screen.height * 0.72,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        _CinematicBackground(
          progress: progress,
        ),

        if (ready)
          _ParticleLayer(
            progress: progress,
            particles: particles,
          ),

        _GoldenRing(
          progress: progress,
        ),

        _EnergyCore(
          progress: progress,
        ),

        _LogoRevealLayers(
          progress: progress,
          logoSize: logoSize,
        ),

        _HeroSweep(
          progress: progress,
        ),

        _PortalTransition(
          progress: progress,
        ),
      ],
    );
  }
}

// =============================================================================
// BACKGROUND
// =============================================================================

class _CinematicBackground extends StatelessWidget {
  final double progress;

  const _CinematicBackground({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CinematicBackgroundPainter(
        progress: progress,
      ),
    );
  }
}

class _CinematicBackgroundPainter extends CustomPainter {
  final double progress;

  _CinematicBackgroundPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(
      size.width / 2,
      size.height * 0.47,
    );

    final double breathe =
        0.5 +
        0.5 *
            math.sin(
              progress * math.pi * 2.0,
            );

    final Paint background = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          0.0,
          -0.14 + breathe * 0.02,
        ),
        radius: 1.30,
        colors: const [
          Color(0xFF315E46),
          Color(0xFF244B37),
          Color(0xFF153324),
          Color(0xFF081B11),
          Color(0xFF020A06),
        ],
        stops: const [
          0.0,
          0.32,
          0.58,
          0.82,
          1.0,
        ],
      ).createShader(
        Offset.zero & size,
      );

    canvas.drawRect(
      Offset.zero & size,
      background,
    );

    final double glowRadius =
        size.shortestSide * 0.50;

    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x24CDAE62),
          Color(0x0DB89452),
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.45,
          1.0,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: glowRadius,
        ),
      );

    canvas.drawCircle(
      center,
      glowRadius,
      glow,
    );

    final Paint vignette = Paint()
      ..shader = RadialGradient(
        colors: const [
          Colors.transparent,
          Colors.transparent,
          Color(0xD9000000),
        ],
        stops: const [
          0.0,
          0.58,
          1.0,
        ],
      ).createShader(
        Offset.zero & size,
      );

    canvas.drawRect(
      Offset.zero & size,
      vignette,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CinematicBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// PARTICLES
// =============================================================================

class _ParticleLayer extends StatelessWidget {
  final double progress;
  final List<_LogoParticle> particles;

  const _ParticleLayer({
    required this.progress,
    required this.particles,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(
          progress: progress,
          particles: particles,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_LogoParticle> particles;

  _ParticlePainter({
    required this.progress,
    required this.particles,
  });

  // The stage timings overlap deliberately.
  double _particleProgress(
    _LogoStage stage,
  ) {
    switch (stage) {
      case _LogoStage.emblem:
        return Curves.easeInOutCubic.transform(
          ((progress - 0.10) / 0.50)
              .clamp(0.0, 1.0),
        );

      case _LogoStage.wordmark:
        return Curves.easeInOutCubic.transform(
          ((progress - 0.43) / 0.28)
              .clamp(0.0, 1.0),
        );

      case _LogoStage.tagline:
        return Curves.easeInOutCubic.transform(
          ((progress - 0.61) / 0.23)
              .clamp(0.0, 1.0),
        );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double vanish =
        progress < 0.83
            ? 1.0
            : 1.0 -
                Curves.easeIn.transform(
                  ((progress - 0.83) / 0.10)
                      .clamp(0.0, 1.0),
                );

    final Offset center = Offset(
      size.width / 2,
      size.height * 0.47,
    );

    final double logoSize = math.min(
      size.width * 0.88,
      size.height * 0.72,
    );

    final double logoLeft =
        (size.width - logoSize) / 2;

    final double logoTop =
        size.height * 0.47 -
        logoSize / 2;

    for (final _LogoParticle particle in particles) {
      final double local =
          _particleProgress(particle.stage);

      if (local <= 0) {
        continue;
      }

      final double curve =
          math.sin(local * math.pi);

      Offset target = Offset(
        logoLeft +
            particle.targetX *
                logoSize,
        logoTop +
            particle.targetY *
                logoSize,
      );

      final Offset start = Offset(
        particle.startX * size.width,
        particle.startY * size.height,
      );

      double x = _lerp(
        start.dx,
        target.dx,
        local,
      );

      double y = _lerp(
        start.dy,
        target.dy,
        local,
      );

      // Curved travel.
      final double side =
          particle.seed > 0.5 ? 1.0 : -1.0;

      x +=
          math.sin(
                particle.phase +
                    local * math.pi,
              ) *
              size.shortestSide *
              0.10 *
              curve *
              side;

      y +=
          math.cos(
                particle.phase +
                    local * math.pi * 0.8,
              ) *
              size.shortestSide *
              0.075 *
              curve;

      // Final spiral as particles tighten around their destination.
      final double dx =
          x - center.dx;

      final double dy =
          y - center.dy;

      final double distance =
          math.sqrt(
            dx * dx + dy * dy,
          );

      if (distance > 1) {
        final double angle =
            math.atan2(dy, dx);

        final double swirl =
            math.sin(local * math.pi) *
                0.18 *
                (1.0 - local);

        x =
            center.dx +
                math.cos(
                  angle + swirl,
                ) *
                distance;

        y =
            center.dy +
                math.sin(
                  angle + swirl,
                ) *
                distance;
      }

      final double twinkle =
          0.72 +
              0.28 *
                  math.sin(
                    particle.phase +
                        progress *
                            math.pi *
                            8.0,
                  );

      final double fade = local < 0.76
          ? 1.0
          : 1.0 -
              Curves.easeIn.transform(
                ((local - 0.76) / 0.24)
                    .clamp(0.0, 1.0),
              );

      final double alpha =
          0.75 *
          twinkle *
          fade *
          vanish;

      final double radius =
          0.7 +
              particle.speed * 1.15;

      final Paint paint = Paint()
        ..color =
            const Color(0xFFD8BD74)
                .withValues(
          alpha: alpha,
        );

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );

      // Small luminous tail.
      if (local > 0.15 &&
          local < 0.82 &&
          particle.seed > 0.72) {
        final Offset previous = Offset(
          x -
              (x - start.dx) * 0.025,
          y -
              (y - start.dy) * 0.025,
        );

        canvas.drawLine(
          previous,
          Offset(x, y),
          Paint()
            ..color =
                const Color(0x66D8BD74)
                    .withValues(
              alpha: alpha * 0.32,
            )
            ..strokeWidth = 1.0
            ..strokeCap =
                StrokeCap.round,
        );
      }
    }
  }

  double _lerp(
    double a,
    double b,
    double t,
  ) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(
    covariant _ParticlePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles;
  }
}

enum _LogoStage {
  emblem,
  wordmark,
  tagline,
}

class _LogoParticle {
  double startX = 0;
  double startY = 0;

  final double targetX;
  final double targetY;
  final _LogoStage stage;
  final double seed;
  final double phase;
  final double speed;

  _LogoParticle({
    required this.targetX,
    required this.targetY,
    required this.stage,
    required this.seed,
    required this.phase,
    required this.speed,
  });
}

class _TargetPoint {
  final double x;
  final double y;

  const _TargetPoint({
    required this.x,
    required this.y,
  });
}

// =============================================================================
// GOLDEN RING
// =============================================================================

class _GoldenRing extends StatelessWidget {
  final double progress;

  const _GoldenRing({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GoldenRingPainter(
          progress: progress,
        ),
      ),
    );
  }
}

class _GoldenRingPainter extends CustomPainter {
  final double progress;

  _GoldenRingPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(
      size.width / 2,
      size.height * 0.47,
    );

    final double intro =
        Curves.easeOutCubic.transform(
      (progress / 0.18)
          .clamp(0.0, 1.0),
    );

    final double rotation =
        progress * math.pi * 1.25;

    final double radius =
        size.shortestSide * 0.315;

    final Rect rect =
        Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(rotation);

    canvas.translate(
      -center.dx,
      -center.dy,
    );

    final Paint glow = Paint()
      ..color =
          const Color(0x42D9BC72)
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter =
          const MaskFilter.blur(
        BlurStyle.normal,
        9,
      );

    final Paint ring = Paint()
      ..color =
          const Color(0xFFD2B26A)
          .withValues(alpha: intro)
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap =
          StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi * 0.94,
      math.pi * 1.55 * intro,
      false,
      glow,
    );

    canvas.drawArc(
      rect,
      -math.pi * 0.94,
      math.pi * 1.55 * intro,
      false,
      ring,
    );

    // Bright travelling point.
    if (intro > 0.01) {
      final double angle =
          -math.pi * 0.94 +
              math.pi * 1.55 * intro;

      final Offset point = Offset(
        center.dx +
            radius * math.cos(angle),
        center.dy +
            radius * math.sin(angle),
      );

      canvas.drawCircle(
        point,
        7.5,
        Paint()
          ..color =
              const Color(0x74E6CA83)
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            10,
          ),
      );

      canvas.drawCircle(
        point,
        2.4,
        Paint()
          ..color =
              const Color(0xFFF8F5EC),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _GoldenRingPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// ENERGY CORE
// =============================================================================

class _EnergyCore extends StatelessWidget {
  final double progress;

  const _EnergyCore({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _EnergyCorePainter(
          progress: progress,
        ),
      ),
    );
  }
}

class _EnergyCorePainter
    extends CustomPainter {
  final double progress;

  _EnergyCorePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double reveal =
        Curves.easeOutCubic.transform(
      ((progress - 0.30) / 0.34)
          .clamp(0.0, 1.0),
    );

    if (reveal <= 0) {
      return;
    }

    final Offset center = Offset(
      size.width / 2,
      size.height * 0.47,
    );

    final double pulse =
        0.90 +
            0.10 *
                math.sin(
                  progress * math.pi * 10,
                );

    final Paint glow = Paint()
      ..shader =
          RadialGradient(
        colors: [
          const Color(0x38E3C987)
              .withValues(
            alpha: reveal,
          ),
          const Color(0x12B89452)
              .withValues(
            alpha: reveal,
          ),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: 145 * pulse,
        ),
      );

    canvas.drawCircle(
      center,
      145 * pulse,
      glow,
    );

    // Fine energy rays.
    final double burst =
        Curves.easeOut.transform(
      ((progress - 0.48) / 0.17)
          .clamp(0.0, 1.0),
    );

    final Paint ray = Paint()
      ..color =
          const Color(0x44D9BC72)
              .withValues(
        alpha:
            (1 - burst) * 0.65,
      )
      ..strokeWidth = 1.0;

    for (int i = 0; i < 24; i++) {
      final double angle =
          i * math.pi * 2 / 24;

      final double inner =
          20 + burst * 8;

      final double outer =
          42 + burst * 70;

      canvas.drawLine(
        Offset(
          center.dx +
              math.cos(angle) *
                  inner,
          center.dy +
              math.sin(angle) *
                  inner,
        ),
        Offset(
          center.dx +
              math.cos(angle) *
                  outer,
          center.dy +
              math.sin(angle) *
                  outer,
        ),
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _EnergyCorePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// LOGO LAYERS
// =============================================================================

class _LogoRevealLayers extends StatelessWidget {
  final double progress;
  final double logoSize;

  const _LogoRevealLayers({
    required this.progress,
    required this.logoSize,
  });

  double _curve(
    double start,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    if (progress <= start) {
      return 0;
    }

    if (progress >= end) {
      return 1;
    }

    return curve.transform(
      ((progress - start) / (end - start))
          .clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double panel =
        _curve(0.34, 0.57);

    final double emblem =
        _curve(
          0.23,
          0.50,
          curve: Curves.easeOutCubic,
        );

    final double wordmark =
        _curve(
          0.44,
          0.67,
          curve: Curves.easeOutCubic,
        );

    final double tagline =
        _curve(
          0.61,
          0.79,
          curve: Curves.easeOut,
        );

    return Center(
      child: SizedBox(
        width: logoSize,
        height: logoSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _CreamPanel(
              progress: panel,
              size: logoSize,
            ),

            // Exact transparent emblem artwork.
            _LogoImageLayer(
              asset:
                  'assets/branding/logo_emblem.png',
              progress: emblem,
              logoSize: logoSize,
              scale: 0.96 +
                  0.04 * emblem,
              mode:
                  _LogoImageReveal.center,
            ),

            // Exact transparent wordmark artwork.
            _LogoImageLayer(
              asset:
                  'assets/branding/logo_wordmark.png',
              progress: wordmark,
              logoSize: logoSize,
              scale: 0.985 +
                  0.015 * wordmark,
              mode:
                  _LogoImageReveal.center,
            ),

            // Exact transparent tagline artwork.
            _LogoImageLayer(
              asset:
                  'assets/branding/logo_tagline.png',
              progress: tagline,
              logoSize: logoSize,
              scale: 1.0,
              mode:
                  _LogoImageReveal.fade,
            ),

            // Code-drawn premium border.
            _PremiumBorder(
              progress: panel,
              size: logoSize,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CREAM PANEL
// =============================================================================

class _CreamPanel extends StatelessWidget {
  final double progress;
  final double size;

  const _CreamPanel({
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: progress * 0.985,
      child: Container(
        margin: EdgeInsets.all(
          size * 0.035,
        ),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            size * 0.075,
          ),
          gradient:
              const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFEFDF8),
              Color(0xFFF8F5EC),
              Color(0xFFF0EBDD),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0x32B89452),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ARTWORK LAYER
// =============================================================================

enum _LogoImageReveal {
  center,
  fade,
}

class _LogoImageLayer extends StatelessWidget {
  final String asset;
  final double progress;
  final double logoSize;
  final double scale;
  final _LogoImageReveal mode;

  const _LogoImageLayer({
    required this.asset,
    required this.progress,
    required this.logoSize,
    required this.scale,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) {
      return const SizedBox.shrink();
    }

    final double opacity =
        Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0),
    );

    Widget image = Image.asset(
      asset,
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );

    image = Transform.scale(
      scale: scale,
      child: image,
    );

    if (mode == _LogoImageReveal.fade) {
      return Opacity(
        opacity: opacity,
        child: image,
      );
    }

    return Opacity(
      opacity: opacity,
      child: ClipRect(
        clipper:
            _CenterRevealClipper(
          progress: progress,
        ),
        child: image,
      ),
    );
  }
}

class _CenterRevealClipper
    extends CustomClipper<Rect> {
  final double progress;

  _CenterRevealClipper({
    required this.progress,
  });

  @override
  Rect getClip(Size size) {
    final double width =
        size.width *
            Curves.easeInOutCubic
                .transform(
              progress,
            );

    final double left =
        (size.width - width) / 2;

    return Rect.fromLTWH(
      left,
      0,
      width,
      size.height,
    );
  }

  @override
  bool shouldReclip(
    covariant _CenterRevealClipper oldClipper,
  ) {
    return oldClipper.progress != progress;
  }
}

// =============================================================================
// PREMIUM CODE-DRAWN BORDER
// =============================================================================

class _PremiumBorder extends StatelessWidget {
  final double progress;
  final double size;

  const _PremiumBorder({
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter:
            _PremiumBorderPainter(
          progress: progress,
        ),
      ),
    );
  }
}

class _PremiumBorderPainter
    extends CustomPainter {
  final double progress;

  _PremiumBorderPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    final double reveal =
        Curves.easeInOutCubic.transform(
      progress.clamp(0.0, 1.0),
    );

    final Rect rect =
        Rect.fromLTRB(
      size.width * 0.035,
      size.height * 0.035,
      size.width * 0.965,
      size.height * 0.965,
    );

    final RRect rrect =
        RRect.fromRectAndRadius(
      rect,
      Radius.circular(
        size.width * 0.075,
      ),
    );

    final Paint outer =
        Paint()
          ..color =
              const Color(0xFFB89452)
                  .withValues(
            alpha: 0.90 * reveal,
          )
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 2.8;

    final Paint inner =
        Paint()
          ..color =
              const Color(0xFFB89452)
                  .withValues(
            alpha: 0.28 * reveal,
          )
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 0.9;

    canvas.drawRRect(
      rrect,
      outer,
    );

    canvas.drawRRect(
      rrect.deflate(7),
      inner,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PremiumBorderPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// HERO LIGHT SWEEP
// =============================================================================

class _HeroSweep extends StatelessWidget {
  final double progress;

  const _HeroSweep({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HeroSweepPainter(
          progress: progress,
        ),
      ),
    );
  }
}

class _HeroSweepPainter
    extends CustomPainter {
  final double progress;

  _HeroSweepPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double reveal =
        Curves.easeInOutCubic.transform(
      ((progress - 0.81) / 0.11)
          .clamp(0.0, 1.0),
    );

    if (reveal <= 0) {
      return;
    }

    final double x =
        -size.width * 0.28 +
            size.width *
                1.56 *
                reveal;

    final Rect rect =
        Rect.fromLTWH(
      x - 105,
      size.height * 0.14,
      210,
      size.height * 0.70,
    );

    final Paint paint =
        Paint()
          ..shader =
              const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0x06FFFFFF),
          Color(0x79FFF1C7),
          Color(0x06FFFFFF),
          Colors.transparent,
        ],
        stops: [
          0.0,
          0.30,
          0.50,
          0.70,
          1.0,
        ],
      ).createShader(rect);

    canvas.drawRect(
      rect,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _HeroSweepPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// =============================================================================
// GOLDEN PORTAL
// =============================================================================

class _PortalTransition extends StatelessWidget {
  final double progress;

  const _PortalTransition({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PortalPainter(
          progress: progress,
        ),
      ),
    );
  }
}

class _PortalPainter
    extends CustomPainter {
  final double progress;

  _PortalPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double reveal =
        Curves.easeInOutCubic.transform(
      ((progress - 0.94) / 0.06)
          .clamp(0.0, 1.0),
    );

    if (reveal <= 0) {
      return;
    }

    final Offset center =
        Offset(
      size.width / 2,
      size.height * 0.47,
    );

    final double maxRadius =
        math.sqrt(
          size.width *
                  size.width +
              size.height *
                  size.height,
        );

    final double radius =
        maxRadius * reveal;

    // Gold outer portal.
    final double goldReveal =
        Curves.easeOutCubic.transform(
      (reveal * 1.18)
          .clamp(0.0, 1.0),
    );

    canvas.drawCircle(
      center,
      radius *
          goldReveal,
      Paint()
        ..color =
            const Color(0xFFD4B36A)
                .withValues(
          alpha: 0.32 *
              (1 -
                  reveal),
        ),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color =
            const Color(0xFFF8F5EC)
                .withValues(
          alpha: 0.98 *
              reveal,
        ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _PortalPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
