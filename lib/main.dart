import 'package:flutter/material.dart';
import 'bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(); // initializes Firebase and other services
  runApp(const AuraSphereApp());
}
