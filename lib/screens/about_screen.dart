// Google AI Studio - Jeevan Sutra About Screen
// Heritage, philosophy & living intelligence credits
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/botanical_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About Jeevan Sutra'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              children: [
                _buildHeroCard(isDark),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.spa_rounded,
                  title: 'Living Intelligence Philosophy',
                  text: 'Jeevan Sutra connects authentic Indian Knowledge Systems (Ayurveda, Dinacharya, Ritucharya, Yoga, Dravyaguna) with cutting-edge mobile UI design, chronobiology, and multimodal AI.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Multimodal AI & Botanical Scanner',
                  text: 'Powered by Google Gemini 2.5 Flash and Firebase services for real-time botanical identification, personalized Dinacharya guidance, and Ayurvedic Prakriti health assessments.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.verified_user_rounded,
                  title: 'Production Security & Firebase App Check',
                  text: 'App Check token attestation safeguards backend Gemini endpoints against unauthorized abuse, securing users with Play Integrity on Android and App Attest on iOS.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.info_outline_rounded,
                  title: 'Educational Disclaimer',
                  text: 'Traditional knowledge presented in Jeevan Sutra is for wellness education and cultural discovery. It is not intended to diagnose, treat, or replace professional clinical care.',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                Text(
                  "Jeevan Sutra • Version 1.0.0+1\nCrafted with Google AI Studio & Flutter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [JeevanSutraColors.darkSurfaceElevated, JeevanSutraColors.darkCanvas]
              : [JeevanSutraColors.forestGreen, JeevanSutraColors.deepBotanical],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: JeevanSutraColors.forestGreen.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_rounded, size: 36, color: JeevanSutraColors.freshLeaf),
          ),
          const SizedBox(height: 14),
          const Text(
            "Jeevan Sutra",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Ancient Wisdom. Living Science.",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: JeevanSutraColors.mutedGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? JeevanSutraColors.darkSurface : JeevanSutraColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? JeevanSutraColors.darkBorder : JeevanSutraColors.subtleBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? JeevanSutraColors.darkCanvas : JeevanSutraColors.softSage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: JeevanSutraColors.forestGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? JeevanSutraColors.darkTextPrimary : JeevanSutraColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: isDark ? JeevanSutraColors.darkTextSecondary : JeevanSutraColors.mainText,
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
