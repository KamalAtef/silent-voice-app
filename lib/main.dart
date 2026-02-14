import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load(); // ✅ لازم
  runApp(const MyApp());
}
