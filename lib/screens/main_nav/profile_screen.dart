import 'package:cosmic_explorer/services/supabase_service.dart';
import 'package:cosmic_explorer/services/gallery_service.dart';
import 'package:cosmic_explorer/models/gallery.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Gallery> _galleries = [];
  bool _isLoading = true;
  int _totalMediaViewed = 0;
  int _totalGalleries = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final galleries = await GalleryService.getAllGalleries();
      final recentlyViewedGallery = galleries.firstWhere(
        (g) => g.isRecentlyViewed,
        orElse: () => Gallery(
          id: '',
          name: '',
          mediaIds: [],
          dateCreated: DateTime.now(),
          lastModified: DateTime.now(),
          isRecentlyViewed: false,
        ),
      );

      setState(() {
        _galleries = galleries.where((g) => !g.isRecentlyViewed).toList();
        _totalMediaViewed = recentlyViewedGallery.mediaCount;
        _totalGalleries = _galleries.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await SupabaseService.signOut();
      if (context.mounted) {
        context.go('/signin');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = SupabaseService.currentUser?.email;
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenPadding = ResponsiveUtils.getScreenPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600,
                ),
                padding: screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: isMobile ? 60 : 80,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        Icons.person,
                        size: isMobile ? 60 : 80,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 32),

                    // User Email
                    Text(
                      userEmail ?? 'Unknown user',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 20 : 24,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 32 : 48),

                    // Simple Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          label: 'Viewed',
                          value: '$_totalMediaViewed',
                          isMobile: isMobile,
                        ),
                        _buildStatItem(
                          label: 'Galleries',
                          value: '$_totalGalleries',
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 48 : 64),

                    // Sign Out Button
                    SizedBox(
                      width: isMobile ? double.infinity : 300,
                      child: ElevatedButton.icon(
                        onPressed: () => _signOut(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 16 : 20,
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required bool isMobile,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}