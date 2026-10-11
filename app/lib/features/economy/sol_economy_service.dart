import 'package:supabase_flutter/supabase_flutter.dart';

class SolEconomyService {
  final SupabaseClient db;
  const SolEconomyService(this.db);
  Future<List<Map<String,dynamic>>> wallet() async => List<Map<String,dynamic>>.from(await db.from('user_wallets').select().limit(1));
  Future<List<Map<String,dynamic>>> ledger() async => List<Map<String,dynamic>>.from(await db.from('wallet_ledger').select().order('created_at',ascending:false).limit(100));
  Future<List<Map<String,dynamic>>> gifts() async => List<Map<String,dynamic>>.from(await db.from('gifts').select().limit(100));
  Future<List<Map<String,dynamic>>> games() async => List<Map<String,dynamic>>.from(await db.from('games').select().limit(100));
}

