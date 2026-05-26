import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/objectbox_store.dart';
import 'app.dart';

/// [startApplication] — bootstrap.
/// 1) Ensure Flutter binding.
/// 2) Open SharedPreferences and ObjectBox once.
/// 3) Hand them to [Application] via constructor so every BlocProvider in
///    `app.dart` can build its repositories with the same instances.
Future<void> startApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = await ObjectBoxStore.create();
  runApp(Application(prefs: prefs, store: store));
}
