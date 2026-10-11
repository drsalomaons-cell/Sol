import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart' as sol_app;

const solUrl = 'https://fjkhdokdwvpyidgunoes.supabase.co';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const key = String.fromEnvironment('SOL_SUPABASE_KEY');
  if (key.isNotEmpty) {
    await Supabase.initialize(url: solUrl, publishableKey: key);
  }
  runApp(const sol_app.SolApp());
}

