import 'package:flutter/material.dart';

class AppStyles {
  // Text styles
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
  
  // Button styles
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 12,
  );
  
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(8));
  
  // Card styles
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));
  
  // Input styles
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(8));
  
  // Shadow styles
  static const BoxShadow softShadow = BoxShadow(
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
    color: Color(0x1A000000),
  );
  
  static const BoxShadow mediumShadow = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
    color: Color(0x1A000000),
  );
  
  static const BoxShadow strongShadow = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
    color: Color(0x1A000000),
  );
}