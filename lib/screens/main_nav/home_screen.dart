// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/services/nasa_service.dart';
import 'package:cosmic_explorer/services/viewing_history_service.dart';
import 'package:cosmic_explorer/widgets/media_card.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NasaMediaItem> _mediaItems = [];
  bool _isLoading = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 1;
  
  // Search and filter states
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';
  String? _selectedMediaType;
  final List<String> _mediaTypes = ['All', 'Image', 'Video', 'Audio'];

  @override
  void initState() {
    super.initState();
    _loadInitialMedia();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMoreMedia();
    }
  }

  Future<void> _loadInitialMedia() async {
    if (_isLoading) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
      });

      final mediaTypes = _selectedMediaType == null || _selectedMediaType == 'All' 
          ? null 
          : [_selectedMediaType!.toLowerCase()];

      final collection = await NasaService.searchMedia(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        mediaTypes: mediaTypes,
        page: _currentPage,
        pageSize: 20,
      );
      
      setState(() {
        _mediaItems = collection.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMedia() async {
    if (_isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final mediaTypes = _selectedMediaType == null || _selectedMediaType == 'All' 
          ? null 
          : [_selectedMediaType!.toLowerCase()];

      final collection = await NasaService.searchMedia(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        mediaTypes: mediaTypes,
        page: _currentPage + 1,
        pageSize: 20,
      );
      
      setState(() {
        _mediaItems.addAll(collection.items);
        _isLoadingMore = false;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more content: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearch() {
    setState(() {
      _currentQuery = _searchController.text.trim();
    });
    _loadInitialMedia();
  }

  void _onMediaTypeChanged(String? mediaType) {
    setState(() {
      _selectedMediaType = mediaType;
    });
    _loadInitialMedia();
  }

  Future<void> _navigateToDetails(NasaMediaItem mediaItem) async {
    // Add to viewing history
    await ViewingHistoryService.addToHistory(mediaItem);
    
    if (mounted) {
      context.push('/gallery/image/${mediaItem.nasaId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmic Explorer'),
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        centerTitle: !isMobile,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getMaxContentWidth(context),
          ),
          child: Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getContentPadding(context);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getSearchBarMaxWidth(context),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search NASA media...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _currentQuery = '';
                            });
                            _loadInitialMedia();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _onSearch(),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          // Filter and search button row
          if (isMobile)
            _buildMobileFilterRow()
          else
            _buildDesktopFilterRow(),
        ],
      ),
    );
  }

  Widget _buildMobileFilterRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedMediaType ?? 'All',
            decoration: InputDecoration(
              labelText: 'Media Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            items: _mediaTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: _onMediaTypeChanged,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _onSearch,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Search'),
        ),
      ],
    );
  }

  Widget _buildDesktopFilterRow() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.getSearchBarMaxWidth(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _selectedMediaType ?? 'All',
                decoration: InputDecoration(
                  labelText: 'Media Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                items: _mediaTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: _onMediaTypeChanged,
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton(
              onPressed: _onSearch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _mediaItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching the cosmos...'),
          ],
        ),
      );
    }

    if (_error != null && _mediaItems.isEmpty) {
      return Center(
        child: Padding(
          padding: ResponsiveUtils.getContentPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load content',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadInitialMedia,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Try a different search term or filter'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialMedia,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: ResponsiveUtils.getScreenPadding(context),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < _mediaItems.length) {
                    return MediaCard(
                      mediaItem: _mediaItems[index],
                      onTap: () => _navigateToDetails(_mediaItems[index]),
                    );
                  }
                  return null;
                },
                childCount: _mediaItems.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
                childAspectRatio: ResponsiveUtils.getGridChildAspectRatio(context),
                crossAxisSpacing: ResponsiveUtils.getGridSpacing(context),
                mainAxisSpacing: ResponsiveUtils.getGridSpacing(context),
              ),
            ),
          ),
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}