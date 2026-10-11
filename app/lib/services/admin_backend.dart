import 'package:supabase_flutter/supabase_flutter.dart';

class SolAdminBackend {
  final SupabaseClient db;
  const SolAdminBackend(this.db);
  Future<List<Map<String,dynamic>>> query(String table) async => List<Map<String,dynamic>>.from(await db.from(table).select().limit(100));
}

