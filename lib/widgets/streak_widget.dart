import 'package:flutter/material.dart';

class StreakWidget extends StatelessWidget {
  final int streak;
  const StreakWidget({Key? key, required this.streak}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) {
      return Row(children: [Icon(Icons.calendar_today), SizedBox(width:6), Text('No streak yet')]);
    }

    return Row(
      children: [
        Icon(Icons.local_fire_department, color: Colors.orangeAccent),
        SizedBox(width: 8),
        Text('$streak day streak', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
