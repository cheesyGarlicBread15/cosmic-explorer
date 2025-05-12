import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Get instance of Supabase client
  static final supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => supabase.auth.currentUser;

  // Get current session
  static Session? get currentSession => supabase.auth.currentSession;

  // Check if user is signed in
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
