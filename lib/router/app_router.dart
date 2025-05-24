// lib/router/app_router.dart
import 'package:cosmic_explorer/screens/auth/sign_in_screen.dart';
import 'package:cosmic_explorer/screens/auth/sign_up_screen.dart';
import 'package:cosmic_explorer/screens/gallery_detail_screen.dart';
import 'package:cosmic_explorer/screens/media_details_screen.dart';
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

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavbar(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                Container(), // Empty container as the real widgets are in IndexedStack
          ),
          GoRoute(
            path: '/gallery',
            builder: (context, state) => Container(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => Container(),
          ),
        ],
      ),

      // Media detail routes (more specific, should come first)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/gallery/:galleryId/media/:nasaId',
        builder: (context, state) {
          final encodedGalleryId = state.pathParameters['galleryId'] ?? '';
          final encodedNasaId = state.pathParameters['nasaId'] ?? '';
          final galleryId = Uri.decodeComponent(encodedGalleryId);
          final nasaId = Uri.decodeComponent(encodedNasaId);
          
          print('Router: Media detail route - galleryId: $galleryId, nasaId: $nasaId');
          print('Router: Raw path parameters - galleryId: $encodedGalleryId, nasaId: $encodedNasaId');
          print('Router: Full location: ${state.uri}');
          
          return MediaDetailsScreen(nasaId: nasaId);
        },
      ),

      // Gallery detail routes (less specific, should come after)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/gallery/:galleryId',
        builder: (context, state) {
          final encodedGalleryId = state.pathParameters['galleryId'] ?? '';
          final galleryId = Uri.decodeComponent(encodedGalleryId);
          print('Router: Gallery detail route with ID: $galleryId'); // Debug
          return GalleryDetailScreen(galleryId: galleryId);
        },
      ),

      // Fallback route for direct media access (redirect to recently viewed)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/gallery/media/:nasaId',
        redirect: (context, state) {
          final nasaId = state.pathParameters['nasaId'] ?? '';
          return '/gallery/recently_viewed/media/$nasaId';
        },
      ),
    ],

    redirect: (context, state) {
      final currentPath = state.uri.path;

      // Allow splash screen for everyone
      if (currentPath == '/') {
        return null;
      }

      final isSignedIn = SupabaseService.isSignedIn;
      final isAuthRoute = currentPath == '/signin' || currentPath == '/signup';

      // if not signed in and the path is not auth route (like home, gallery and profile)
      if (!isSignedIn && !isAuthRoute) {
        return '/signin';
      }

      // if is signed in and path is sign up, return null since user will sign up another account
      // sign in is detected after sign up due to supabase active session
      if (isSignedIn && currentPath == 'signup') {
        return null;
      }

      if (isSignedIn && currentPath == '/signin') {
        return '/home';
      }

      return null;
    },

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text(
          'Error: ${state.error?.toString() ?? "Unknown error"}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    ),
  );
}