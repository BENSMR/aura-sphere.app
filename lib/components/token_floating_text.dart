import 'package:flutter/material.dart';

class TokenFloatingText extends StatefulWidget {
  final int amount;
  final VoidCallback onFinish;

  const TokenFloatingText({
    Key? key,
    required this.amount,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<TokenFloatingText> createState() => _TokenFloatingTextState();
}

class _TokenFloatingTextState extends State<TokenFloatingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUp;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _moveUp = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) => widget.onFinish());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Opacity(
          opacity: _fadeOut.value,
          child: Transform.translate(
            offset: Offset(0, _moveUp.value),
            child: Text(
              "+${widget.amount} AURA",
              style: TextStyle(
                color: Colors.greenAccent.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                shadows: [
                  Shadow(color: Colors.greenAccent.shade700, blurRadius: 8)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
