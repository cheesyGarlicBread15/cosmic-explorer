import 'package:cosmic_explorer/screens/auth/sign_in_screen.dart';
import 'package:cosmic_explorer/screens/auth/sign_up_screen.dart';
import 'package:cosmic_explorer/screens/image_details_screen.dart';
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
              routes: [
                GoRoute(
                  path: 'image/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final imageId = state.pathParameters['id'] ?? '0';
                    return ImageDetailsScreen(imageId: imageId);
                  },
                )
              ]),
          GoRoute(
            path: '/profile',
            builder: (context, state) => Container(),
          ),
        ],
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
