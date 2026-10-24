// Flutter Implementation of Jeevan Sutra Authentication Screen
// Login & Sign-up at first interaction with Prakriti (Dosha) onboarding
import 'package:flutter/material.dart';

import 'package:jeevan_sutra/theme/jeevan_sutra_ui_theme.dart';

import '../models/wellness_models.dart';

import '../widgets/botanical_background.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<UserProfile> onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _nameController = TextEditingController(
    text: "Hardik",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "hardik@jeevansutra.org",
  );
  final TextEditingController _passwordController = TextEditingController(
    text: "ayurveda108",
  );

  // Selected Dosha for new registrations
  String _selectedPrakriti = "Pitta-Vata";
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final profile = UserProfile(
        name: _isSignUp
            ? _nameController.text.trim()
            : (_nameController.text.isNotEmpty
                  ? _nameController.text.trim()
                  : "Hardik"),
        ageGroup: "25–34",
        dominantPrakriti: _selectedPrakriti,
        goals: ["Circadian Alignment", "Agni Balance", "Stress Reduction"],
        dietaryPreference: "Sattvic & Fresh",
        preferredLanguage: "English (with Sanskrit)",
      );

      widget.onAuthenticated(profile);
    }
  }

  void _handleQuickDemoLogin() {
    final demoProfile = UserProfile(
      name: "Hardik",
      ageGroup: "25–34",
      dominantPrakriti: "Pitta-Vata",
      goals: [
        "Circadian Alignment",
        "Digestive Agni Balance",
        "Stress Reduction via Pranayama",
        "Herbal Adaptogens",
      ],
      dietaryPreference: "Sattvic & Plant-Forward",
      preferredLanguage: "English (with Sanskrit terms)",
    );
    widget.onAuthenticated(demoProfile);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? JeevanSutraColors.freshLeaf
        : JeevanSutraColors.forestGreen;

    return Scaffold(
      body: BotanicalBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon & Header
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? JeevanSutraColors.darkSurfaceElevated
                            : JeevanSutraColors.softSage,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.spa_rounded,
                          size: 38,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "JEEVAN SUTRA",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: isDark
                            ? JeevanSutraColors.darkTextPrimary
                            : JeevanSutraColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ancient Wisdom · Living Intelligence",
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Auth Card Container
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? JeevanSutraColors.darkSurface
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? JeevanSutraColors.darkBorder
                              : JeevanSutraColors.subtleBorder,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Sign In / Sign Up Segment Toggle
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? JeevanSutraColors.darkCanvas
                                    : JeevanSutraColors.warmIvory,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isSignUp = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isSignUp
                                              ? (isDark
                                                    ? JeevanSutraColors
                                                          .darkSurfaceElevated
                                                    : Colors.white)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: !_isSignUp
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.05,
                                                        ),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Sign In",
                                            style: TextStyle(
                                              fontWeight: !_isSignUp
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 14,
                                              color: !_isSignUp
                                                  ? primaryColor
                                                  : (isDark
                                                        ? Colors.white60
                                                        : Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _isSignUp = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isSignUp
                                              ? (isDark
                                                    ? JeevanSutraColors
                                                          .darkSurfaceElevated
                                                    : Colors.white)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: _isSignUp
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.05,
                                                        ),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Create Account",
                                            style: TextStyle(
                                              fontWeight: _isSignUp
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 14,
                                              color: _isSignUp
                                                  ? primaryColor
                                                  : (isDark
                                                        ? Colors.white60
                                                        : Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Full Name (Sign Up only)
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: "Full Name",
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (val) {
                                  if (_isSignUp &&
                                      (val == null || val.trim().isEmpty)) {
                                    return "Please enter your name";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email or Phone",
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Please enter your email";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                            ),

                            // Prakriti Selection (Sign Up only)
                            if (_isSignUp) ...[
                              const SizedBox(height: 18),
                              Text(
                                "Known Prakriti / Constitution (Optional):",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? JeevanSutraColors.darkTextSecondary
                                      : JeevanSutraColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    [
                                      "Pitta-Vata",
                                      "Vata-Kapha",
                                      "Pitta-Kapha",
                                      "Tridoshic",
                                      "Not Sure Yet",
                                    ].map((dosha) {
                                      final isSelected =
                                          _selectedPrakriti == dosha;
                                      return ChoiceChip(
                                        label: Text(dosha),
                                        selected: isSelected,
                                        selectedColor:
                                            JeevanSutraColors.softSage,
                                        labelStyle: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? JeevanSutraColors.forestGreen
                                              : null,
                                        ),
                                        onSelected: (selected) {
                                          if (selected)
                                            setState(
                                              () => _selectedPrakriti = dosha,
                                            );
                                        },
                                      );
                                    }).toList(),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Action Button
                            ElevatedButton(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: JeevanSutraColors.forestGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                _isSignUp
                                    ? "Begin My Holistic Journey"
                                    : "Enter Sanctuary",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Demo / Guest Access
                    OutlinedButton.icon(
                      onPressed: _handleQuickDemoLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        side: BorderSide(
                          color: isDark
                              ? JeevanSutraColors.darkBorder
                              : JeevanSutraColors.forestGreen.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.flash_on_rounded,
                        size: 18,
                        color: JeevanSutraColors.mutedGold,
                      ),
                      label: Text(
                        "Instant Guest Demo Access",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? JeevanSutraColors.darkTextPrimary
                              : JeevanSutraColors.forestGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Local mock authentication for privacy & immediate access",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? JeevanSutraColors.darkTextSecondary
                            : JeevanSutraColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
