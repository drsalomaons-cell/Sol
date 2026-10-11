import 'package:supabase_flutter/supabase_flutter.dart';

class SolRoomBackend {
  final SupabaseClient db;
  const SolRoomBackend(this.db);

  Future<List<Map<String, dynamic>>> rooms() async =>
      List<Map<String, dynamic>>.from(
        await db
            .from('room_sessions')
            .select('id,room_key,title,status,seats,video_enabled,chat_enabled,created_at')
            .eq('status', 'live')
            .order('created_at', ascending: false)
            .limit(50),
      );

  Future<List<Map<String, dynamic>>> participants(String roomId) async =>
      List<Map<String, dynamic>>.from(
        await db
            .from('room_participants')
            .select('member_id,seat_no,mic_enabled,camera_enabled,joined_at,left_at')
            .eq('room_id', roomId)
            .isFilter('left_at', null)
            .order('seat_no'),
      );

  Future<List<Map<String, dynamic>>> wallet() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return [];
    return List<Map<String, dynamic>>.from(
      await db.from('user_wallets').select('user_id,balance,updated_at').eq('user_id', userId).limit(1),
    );
  }

  Future<List<Map<String, dynamic>>> ledger() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return [];
    return List<Map<String, dynamic>>.from(
      await db
          .from('wallet_ledger')
          .select('event_type,amount,balance_after,created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100),
    );
  }
}
