// Flutter Implementation of Consistency Milestone Celebration Dialog
// Displays confetti / sparkle effect and Ayurvedic tribute on hitting 7-day or 30-day streaks
import 'dart:math' as math;

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';
import 'package:flutter/material.dart';

class MilestoneCelebrationDialog extends StatefulWidget {
  final int milestoneDays;
  final VoidCallback onDismiss;

  const MilestoneCelebrationDialog({
    super.key,
    required this.milestoneDays,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, int days) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MilestoneCelebrationDialog(
        milestoneDays: days,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final is30Day = widget.milestoneDays >= 30;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Animated Sparkle Particles
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _SparklePainter(progress: _sparkleController.value),
                size: const Size(320, 360),
              );
            },
          ),

          // Main Card
          Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? JeevanSutraColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? JeevanSutraColors.darkBorder
                    : JeevanSutraColors.mutedGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (is30Day
                              ? JeevanSutraColors.mutedGold
                              : JeevanSutraColors.freshLeaf)
                          .withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: is30Day
                          ? [
                              const Color(0xFFE8C872),
                              JeevanSutraColors.mutedGold,
                            ]
                          : [
                              JeevanSutraColors.freshLeaf,
                              JeevanSutraColors.forestGreen,
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (is30Day
                                    ? JeevanSutraColors.mutedGold
                                    : JeevanSutraColors.forestGreen)
                                .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      is30Day
                          ? Icons.military_tech_rounded
                          : Icons.local_fire_department_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  is30Day
                      ? "30-DAY TAPASYA MILESTONE"
                      : "7-DAY AGNI CONSISTENCY",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: is30Day
                        ? JeevanSutraColors.mutedGold
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  is30Day ? "Master of Dinacharya" : "Vitality Awakened",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? JeevanSutraColors.darkTextPrimary
                        : JeevanSutraColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  is30Day
                      ? "A full lunar cycle of disciplined living. Your cellular biological clock has re-synchronized with cosmic natural law."
                      : "Seven consecutive days of circadian rhythm and Dinacharya practices. Your digestive Agni and mental sattva are blooming.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? JeevanSutraColors.darkTextSecondary
                        : JeevanSutraColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 22),

                // Sanskrit tribute badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? JeevanSutraColors.darkCanvas
                        : JeevanSutraColors.softSage,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    is30Day
                        ? "धृतिः क्षमा दमोऽस्तेयं शौचमिन्द्रियनिग्रहः"
                        : "तपसो हि परं नास्ति",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.forestGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JeevanSutraColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Continue My Practice",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;

  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final center = Offset(size.width / 2, size.height / 2);

    final colors = [
      JeevanSutraColors.mutedGold,
      JeevanSutraColors.freshLeaf,
      Colors.amber,
      const Color(0xFFE27D60),
    ];

    for (int i = 0; i < 24; i++) {
      final angle = (i * (2 * math.pi / 24)) + (progress * 0.5);
      final baseDistance = 80.0 + (random.nextDouble() * 70.0);
      final distance =
          baseDistance + (math.sin(progress * 2 * math.pi + i) * 15.0);

      final x = center.dx + (math.cos(angle) * distance);
      final y = center.dy + (math.sin(angle) * distance);

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: 0.6 + 0.4 * math.sin(progress * math.pi * 2 + i),
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 2.5 + (random.nextDouble() * 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}
