import 'package:cosmic_explorer/screens/main_nav/gallery_screen.dart';
import 'package:cosmic_explorer/screens/main_nav/home_screen.dart';
import 'package:cosmic_explorer/screens/main_nav/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavbar extends StatefulWidget {
  final Widget child;
  final String location;

  const ScaffoldWithNavbar(
      {super.key, required this.child, required this.location});

  @override
  State<ScaffoldWithNavbar> createState() => _ScaffoldWithNavbarState();
}

class _ScaffoldWithNavbarState extends State<ScaffoldWithNavbar> {
  int _currentIndex = 0;

  // Create instances of all screens to preserve their state
  final List<Widget> _screens = [
    const HomeScreen(),
    const GalleryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Set initial index based on the initial location
    _updateIndexFromLocation(widget.location);
  }

  @override
  void didUpdateWidget(ScaffoldWithNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update index when location changes
    if (widget.location != oldWidget.location) {
      _updateIndexFromLocation(widget.location);
    }
  }

  void _updateIndexFromLocation(String location) {
    int index = 0;

    if (location.startsWith('/home')) {
      index = 0;
    } else if (location.startsWith('/gallery')) {
      index = 1;
    } else if (location.startsWith('/profile')) {
      index = 2;
    }

    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    // Avoid unnecessary navigation if already on the tab
    if (index == _currentIndex) return;

    String location;
    switch (index) {
      case 0:
        location = '/home';
        break;
      case 1:
        location = '/gallery';
        break;
      case 2:
        location = '/profile';
        break;
      default:
        location = '/home';
    }

    if (context.mounted) {
      context.go(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
