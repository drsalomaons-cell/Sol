import 'package:supabase_flutter/supabase_flutter.dart';

class SolAuthService {
  final SupabaseClient db;
  const SolAuthService(this.db);
  Stream<AuthState> get changes => db.auth.onAuthStateChange;
  User? get user => db.auth.currentUser;
  Future<void> signIn(String email,String password)=>db.auth.signInWithPassword(email:email,password:password);
  Future<void> signUp(String email,String password,String name)=>db.auth.signUp(email:email,password:password,data:{'display_name':name});
  Future<void> signOut()=>db.auth.signOut();
}

