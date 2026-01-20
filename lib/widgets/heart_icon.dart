import 'package:flutter/material.dart';
import '../models/heart_style.dart';

/// A reusable widget that renders a heart icon based on a HeartStyle
///
/// Supports three rendering modes:
/// - Solid: Single color heart using Icons.favorite
/// - Gradient2: Two-color diagonal gradient (topLeft to bottomRight)
/// - Gradient3: Three-color diagonal gradient (topLeft to bottomRight)
class HeartIcon extends StatelessWidget {
  final HeartStyle style;
  final double size;

  const HeartIcon({
    super.key,
    required this.style,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // For solid hearts, render a simple icon with single color
    if (style.type == HeartStyleType.solid) {
      return Icon(
        Icons.favorite,
        color: style.colors[0],
        size: size,
      );
    }

    // For gradient hearts, use ShaderMask to apply gradient
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ).createShader(bounds);
      },
      child: Icon(
        Icons.favorite,
        size: size,
        color: Colors.white, // Base color for ShaderMask to apply gradient to
      ),
    );
  }
}
