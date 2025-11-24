import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
