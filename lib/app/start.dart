import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/objectbox_store.dart';
import 'app.dart';

/// [startApplication] — bootstrap.
/// 1) Ensure Flutter binding.
/// 2) Load `.env` (holds the optional Gemini API key for Feature 11).
/// 3) Open SharedPreferences and ObjectBox once.
/// 4) Hand them to [Application] via constructor so every BlocProvider in
///    `app.dart` can build its repositories with the same instances.
Future<void> startApplication() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `.env` is optional — app boots without it, AI insights just stay empty.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env shipped or readable — that's fine.
  }

  final prefs = await SharedPreferences.getInstance();
  final store = await ObjectBoxStore.create();
  runApp(Application(prefs: prefs, store: store));
}
