import 'package:cosmic_explorer/screens/main_nav/gallery_screen.dart';
import 'package:cosmic_explorer/screens/main_nav/home_screen.dart';
import 'package:cosmic_explorer/screens/main_nav/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavbar extends StatelessWidget {
  final Widget child;
  final String location;

  const ScaffoldWithNavbar({
    super.key,
    required this.child,
    required this.location,
  });

  int get _selectedIndex {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/gallery')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeScreen(),
          GalleryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/gallery');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
