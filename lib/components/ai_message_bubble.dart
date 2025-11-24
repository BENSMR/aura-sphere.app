import 'package:flutter/material.dart';

class AIMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const AIMessageBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
