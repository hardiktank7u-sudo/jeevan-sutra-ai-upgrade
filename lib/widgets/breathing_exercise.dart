// Interactive Pranayama Breathing Exercise for Flutter
import 'dart:async';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';
import 'package:flutter/material.dart';

class BreathingExerciseWidget extends StatefulWidget {
  final VoidCallback? onCompleteSession;

  const BreathingExerciseWidget({super.key, this.onCompleteSession});

  @override
  State<BreathingExerciseWidget> createState() =>
      _BreathingExerciseWidgetState();
}

class _BreathingExerciseWidgetState extends State<BreathingExerciseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  Timer? _phaseTimer;
  String _currentPhase = "Inhale";
  int _secondsLeft = 4;
  bool _isRunning = false;
  int _completedCycles = 0;

  // 4-4-4 Sama Vritti Breathwork
  final int _inhaleDuration = 4;
  final int _holdDuration = 4;
  final int _exhaleDuration = 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _scaleAnimation = TweenSequence<double>([
      // Inhale: expand 1.0 -> 1.45
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.45,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 33.3,
      ),
      // Hold: maintain 1.45
      TweenSequenceItem(tween: ConstantTween<double>(1.45), weight: 33.3),
      // Exhale: contract 1.45 -> 1.0
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.45,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 33.4,
      ),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.2,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 33.3,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.8), weight: 33.3),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.8,
          end: 0.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 33.4,
      ),
    ]).animate(_controller);
  }

  void _startBreathing() {
    setState(() {
      _isRunning = true;
      _currentPhase = "Inhale";
      _secondsLeft = _inhaleDuration;
    });

    _controller.repeat();
    _startTimer();
  }

  void _pauseBreathing() {
    _controller.stop();
    _phaseTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetBreathing() {
    _controller.reset();
    _phaseTimer?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = "Inhale";
      _secondsLeft = _inhaleDuration;
      _completedCycles = 0;
    });
  }

  void _startTimer() {
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          // Transition phase
          if (_currentPhase == "Inhale") {
            _currentPhase = "Hold";
            _secondsLeft = _holdDuration;
          } else if (_currentPhase == "Hold") {
            _currentPhase = "Exhale";
            _secondsLeft = _exhaleDuration;
          } else {
            _currentPhase = "Inhale";
            _secondsLeft = _inhaleDuration;
            _completedCycles++;
            if (widget.onCompleteSession != null && _completedCycles % 3 == 0) {
              widget.onCompleteSession!();
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;
    final goldColor = JeevanSutraColors.mutedGold;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? JeevanSutraColors.darkSurface
            : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? JeevanSutraColors.darkBorder
              : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sama Vritti Pranayama",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? JeevanSutraColors.darkTextPrimary
                          : JeevanSutraColors.forestGreen,
                    ),
                  ),
                  Text(
                    "4-4-4 Harmonizing Breath Rhythm",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? JeevanSutraColors.darkTextSecondary
                          : JeevanSutraColors.secondaryText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? JeevanSutraColors.darkCanvas
                      : JeevanSutraColors.softSage,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Cycles: $_completedCycles",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Breathing Mandala Circles
          SizedBox(
            height: 200,
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Outer Pulse Glow
                      Container(
                        width: 140 * _scaleAnimation.value,
                        height: 140 * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(
                            alpha: 0.08 * _glowAnimation.value,
                          ),
                          border: Border.all(
                            color: goldColor.withValues(
                              alpha: 0.25 * _glowAnimation.value,
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                      // Mid Concentric Ring
                      Container(
                        width: 110 * _scaleAnimation.value,
                        height: 110 * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (isDark
                                      ? JeevanSutraColors.freshLeaf
                                      : JeevanSutraColors.softSage)
                                  .withValues(
                                    alpha: 0.2 * _glowAnimation.value,
                                  ),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Core Breathing Circle with Phase & Counter
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPhase,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                "$_secondsLeft s",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Audio-Visual Phase Indicator Guidance
          Text(
            _isRunning
                ? (_currentPhase == "Inhale"
                      ? "Expand lungs gently through the nostrils..."
                      : _currentPhase == "Hold"
                      ? "Retain prana at stillness, relax shoulders..."
                      : "Smoothly surrender breath, release tension...")
                : "Tap Start to harmonize your autonomic nervous system.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? JeevanSutraColors.darkTextSecondary
                  : JeevanSutraColors.secondaryText,
            ),
          ),

          const SizedBox(height: 20),

          // Interactive Controls (Start / Pause / Reset)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isRunning ? _pauseBreathing : _startBreathing,
                icon: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(_isRunning ? "Pause" : "Start"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark
                      ? JeevanSutraColors.darkCanvas
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _resetBreathing,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Reset"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? JeevanSutraColors.darkTextPrimary
                      : JeevanSutraColors.mainText,
                  side: BorderSide(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
