import 'package:flutter/material.dart';

class RiskGauge extends StatelessWidget {
  final double value; // 0..100
  final double size;
  const RiskGauge({Key? key, required this.value, this.size = 120})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0, 100);
    Color color;
    if (normalized > 60) {
      color = Colors.redAccent;
    } else if (normalized > 30) {
      color = Colors.orangeAccent;
    } else {
      color = Colors.green;
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: normalized / 100,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                normalized.toStringAsFixed(0),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Risk',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            ],
          )
        ],
      ),
    );
  }
}
