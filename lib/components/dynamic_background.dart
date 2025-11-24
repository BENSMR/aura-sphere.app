import 'package:flutter/material.dart';

class DynamicBackground extends StatelessWidget {
  final Widget child;

  const DynamicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade900,
            Colors.blue.shade900,
          ],
        ),
      ),
      child: child,
    );
  }
}
