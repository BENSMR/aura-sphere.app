import 'package:flutter/material.dart';

class AuraLogo extends StatelessWidget {
  final double size;

  const AuraLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.blue],
        ),
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
