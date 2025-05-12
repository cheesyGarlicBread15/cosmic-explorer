import 'package:cosmic_explorer/screens/main_nav/gallery_screen.dart';
import 'package:cosmic_explorer/screens/main_nav/home_screen.dart';
import 'package:cosmic_explorer/screens/main_nav/profile_screen.dart';
import 'package:cosmic_explorer/screens/sign_in_screen.dart';
import 'package:cosmic_explorer/screens/sign_up_screen.dart';
import 'package:cosmic_explorer/screens/splash_screen.dart';
import 'package:cosmic_explorer/services/supabase_service.dart';
import 'package:cosmic_explorer/widgets/scaffold_with_navbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Define the routes
    routes: [
      // Splash route
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication routes
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavbar(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Gallery tab
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const GalleryScreen(),
          ),

          // Profile tab
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],

    // Redirect based on authentication state
    redirect: (context, state) {
      // Get the current path
      final currentPath = state.matchedLocation;

      // Splash screen is accessible regardless of authentication
      if (currentPath == '/') {
        return null;
      }

      // Check if user is signed in
      final isSignedIn = SupabaseService.isSignedIn;

      // Auth routes
      final isAuthRoute = currentPath == '/signin' || currentPath == '/signup';

      // If not signed in and not on an auth route, redirect to sign in
      if (!isSignedIn && !isAuthRoute) {
        return '/signin';
      }

      // If signed in and on an auth route, redirect to home
      if (isSignedIn && isAuthRoute) {
        return '/home';
      }

      // No redirect needed
      return null;
    },

    // Error builder
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    ),
  );
}
