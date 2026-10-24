// Immersive Animated Breathwork Session Screen for Flutter
import 'dart:async';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';
import 'package:flutter/material.dart';

class BreathPattern {
  final String id;
  final String name;
  final String sanskrit;
  final int inhale;
  final int holdAfterInhale;
  final int exhale;
  final int holdAfterExhale;

  const BreathPattern({
    required this.id,
    required this.name,
    required this.sanskrit,
    required this.inhale,
    required this.holdAfterInhale,
    required this.exhale,
    required this.holdAfterExhale,
  });
}

class BreathworkSessionScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const BreathworkSessionScreen({super.key, this.onBack});

  @override
  State<BreathworkSessionScreen> createState() =>
      _BreathworkSessionScreenState();
}

class _BreathworkSessionScreenState extends State<BreathworkSessionScreen>
    with SingleTickerProviderStateMixin {
  final List<BreathPattern> _patterns = const [
    BreathPattern(
      id: 'sama_vritti',
      name: 'Sama Vritti (Box 4-4-4-4)',
      sanskrit: 'समवृत्ति प्राणायाम',
      inhale: 4,
      holdAfterInhale: 4,
      exhale: 4,
      holdAfterExhale: 4,
    ),
    BreathPattern(
      id: 'pranayama_478',
      name: 'Vagal Reset (4-7-8)',
      sanskrit: 'विराम प्राणायाम',
      inhale: 4,
      holdAfterInhale: 7,
      exhale: 8,
      holdAfterExhale: 0,
    ),
    BreathPattern(
      id: 'harmonizing',
      name: 'Harmonizing (4-4-4)',
      sanskrit: 'नाड़ी शोधन ताल',
      inhale: 4,
      holdAfterInhale: 4,
      exhale: 4,
      holdAfterExhale: 0,
    ),
  ];

  late BreathPattern _selectedPattern;
  bool _isActive = false;
  String _currentPhase = "Inhale";
  int _secondsLeft = 4;
  int _completedCycles = 0;
  int _elapsedSeconds = 0;
  Timer? _sessionTimer;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedPattern = _patterns[0];
    _secondsLeft = _selectedPattern.inhale;

    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _selectedPattern.inhale),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void _startBreathwork() {
    setState(() {
      _isActive = true;
    });

    _animController.duration = Duration(seconds: _selectedPattern.inhale);
    _animController.forward(from: 0.0);

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _elapsedSeconds++;

        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          // Phase transition
          if (_currentPhase == "Inhale") {
            if (_selectedPattern.holdAfterInhale > 0) {
              _currentPhase = "Hold";
              _secondsLeft = _selectedPattern.holdAfterInhale;
            } else {
              _currentPhase = "Exhale";
              _secondsLeft = _selectedPattern.exhale;
              _animController.duration = Duration(
                seconds: _selectedPattern.exhale,
              );
              _animController.reverse(from: 1.0);
            }
          } else if (_currentPhase == "Hold") {
            _currentPhase = "Exhale";
            _secondsLeft = _selectedPattern.exhale;
            _animController.duration = Duration(
              seconds: _selectedPattern.exhale,
            );
            _animController.reverse(from: 1.0);
          } else if (_currentPhase == "Exhale") {
            if (_selectedPattern.holdAfterExhale > 0) {
              _currentPhase = "Pause";
              _secondsLeft = _selectedPattern.holdAfterExhale;
            } else {
              _completedCycles++;
              _currentPhase = "Inhale";
              _secondsLeft = _selectedPattern.inhale;
              _animController.duration = Duration(
                seconds: _selectedPattern.inhale,
              );
              _animController.forward(from: 0.0);
            }
          } else {
            _completedCycles++;
            _currentPhase = "Inhale";
            _secondsLeft = _selectedPattern.inhale;
            _animController.duration = Duration(
              seconds: _selectedPattern.inhale,
            );
            _animController.forward(from: 0.0);
          }
        }
      });
    });
  }

  void _pauseBreathwork() {
    setState(() {
      _isActive = false;
    });
    _animController.stop();
    _sessionTimer?.cancel();
  }

  void _resetBreathwork() {
    setState(() {
      _isActive = false;
      _currentPhase = "Inhale";
      _secondsLeft = _selectedPattern.inhale;
      _elapsedSeconds = 0;
      _completedCycles = 0;
    });
    _animController.reset();
    _sessionTimer?.cancel();
  }

  String _formatTime(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  void dispose() {
    _animController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;
    final goldColor = JeevanSutraColors.mutedGold;

    return Scaffold(
      backgroundColor: isDark
          ? JeevanSutraColors.darkCanvas
          : JeevanSutraColors.warmIvory,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Pranayama Sanctuary",
          style: TextStyle(
            color: isDark
                ? JeevanSutraColors.darkTextPrimary
                : JeevanSutraColors.forestGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Pattern Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _patterns.map((pat) {
                    final isSelected = _selectedPattern.id == pat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(pat.name.split('(')[0]),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val && !_isActive) {
                            setState(() {
                              _selectedPattern = pat;
                              _secondsLeft = pat.inhale;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // Animated Breathing Rings
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Outer Expanding Circle
                      Container(
                        width: 140 * _scaleAnimation.value,
                        height: 140 * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.08),
                          border: Border.all(
                            color: goldColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                      ),

                      // Middle Sacred Ring
                      Container(
                        width: 110 * _scaleAnimation.value,
                        height: 110 * _scaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (isDark
                                      ? JeevanSutraColors.freshLeaf
                                      : JeevanSutraColors.softSage)
                                  .withValues(alpha: 0.2),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                      ),

                      // Center Core Bubble with Phase & Countdown
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isActive ? "$_secondsLeft s" : "Start",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentPhase.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
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

              const SizedBox(height: 32),

              // Phase Sanskrit Title & Instruction
              Text(
                _currentPhase == "Inhale"
                    ? "Expand lower belly and lateral ribs..."
                    : _currentPhase == "Hold"
                    ? "Rest in tranquil stillness, relax shoulders..."
                    : "Surrender breath, release all somatic tension...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? JeevanSutraColors.darkTextSecondary
                      : JeevanSutraColors.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const Spacer(),

              // Telemetry Bar (Duration, Cycles, Calm Score)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? JeevanSutraColors.darkSurface
                      : JeevanSutraColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? JeevanSutraColors.darkBorder
                        : JeevanSutraColors.subtleBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "DURATION",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTime(_elapsedSeconds),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "CYCLES",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$_completedCycles",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "CALM INDEX",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${(75 + _completedCycles * 3).clamp(75, 99)}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Controls (Play / Pause / Reset)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isActive
                          ? _pauseBreathwork
                          : _startBreathwork,
                      icon: Icon(
                        _isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        _isActive
                            ? "Pause"
                            : (_elapsedSeconds > 0
                                  ? "Resume"
                                  : "Begin Breathwork"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _resetBreathwork,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: "Reset Session",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
