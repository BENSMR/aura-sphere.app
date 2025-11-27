import 'package:flutter/material.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(); // initializes Firebase and other services
  runApp(const AuraSphereApp());
}
