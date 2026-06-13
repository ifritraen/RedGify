import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GlassyContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassyContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 15,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppTheme.glassBg;
    final themeBorderColor = borderColor ?? AppTheme.border;
    final themeBoxShadow = boxShadow ?? AppTheme.cardGlow;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: themeBoxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: themeBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
