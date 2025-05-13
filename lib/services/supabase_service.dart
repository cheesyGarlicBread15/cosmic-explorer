import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;
  static User? get currentUser => supabase.auth.currentUser;
  static Session? get currentSession => supabase.auth.currentSession;
  static bool get isSignedIn => currentUser != null;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
