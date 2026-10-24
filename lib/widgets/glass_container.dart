import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final BoxBorder? customBorder;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool glowing;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 22,
    this.blur = 16,
    this.color,
    this.gradient,
    this.border,
    this.customBorder,
    this.boxShadow,
    this.onTap,
    this.glowing = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = glowColor ?? AppTheme.emerald.withValues(alpha: 0.25);

    final List<BoxShadow> effectiveShadows = boxShadow ?? [
      if (glowing)
        BoxShadow(
          color: effectiveGlowColor,
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        )
      else
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
    ];

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppTheme.glassFill,
        gradient: gradient ??
            LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: customBorder ??
            border ??
            Border.all(
              color: glowing
                  ? (glowColor ?? AppTheme.emerald).withValues(alpha: 0.5)
                  : AppTheme.glassBorder,
              width: 1,
            ),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: effectiveShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}
