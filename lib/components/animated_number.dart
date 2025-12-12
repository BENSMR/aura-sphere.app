import 'package:flutter/material.dart';

class AnimatedNumber extends ImplicitlyAnimatedWidget {
  final num value;
  final TextStyle? style;

  const AnimatedNumber({
    Key? key,
    required this.value,
    this.style,
    Curve curve = Curves.easeOut,
    Duration duration = const Duration(milliseconds: 900),
  }) : super(key: key, curve: curve, duration: duration);

  @override
  _AnimatedNumberState createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends AnimatedWidgetBaseState<AnimatedNumber> {
  Tween<double>? _numberTween;

  @override
  Widget build(BuildContext context) {
    final value = (_numberTween?.evaluate(animation) ?? 0).toStringAsFixed(0);
    return Text(
      value,
      style: widget.style,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _numberTween = visitor(
      _numberTween,
      widget.value.toDouble(),
      (dynamic v) => Tween<double>(begin: v),
    ) as Tween<double>?;
  }
}
