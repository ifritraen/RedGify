import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/search_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../widgets/video_card.dart';
import '../widgets/sidebar.dart';
import '../niches/niches_screen.dart';
import '../library/library_screen.dart';
import '../ai/ai_screen.dart';
import '../widgets/bulk_action_bar.dart';
import '../../providers/selection_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedProvider>(context, listen: false).fetchInitialFeed();
    });

    _scrollController.addListener(() {
      final feed = Provider.of<FeedProvider>(context, listen: false);
      final search = Provider.of<SearchProvider>(context, listen: false);

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (search.currentQuery.isNotEmpty) {
          search.fetchNextSearchResults();
        } else {
          feed.fetchNextPage();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query) {
    if (query.trim().isNotEmpty) {
      Provider.of<SearchProvider>(context, listen: false).performSearch(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    Provider.of<SearchProvider>(context, listen: false).clearSearch();
  }

  Widget _buildSortChip(FeedProvider feed, String orderValue, String label) {
    final isSelected = feed.activeOrder == orderValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryNeon,
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryNeon : Colors.white.withAlpha(15),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          feed.setOrder(orderValue);
        }
      },
    );
  }

  Widget _buildHomeFeedBody(FeedProvider feed, SearchProvider search) {
    final isSearching = search.currentQuery.isNotEmpty;
    final List gifs = isSearching ? search.searchResults : feed.gifs;
    final bool isLoading = isSearching ? search.isLoading : feed.isLoading;
    final String? error = isSearching ? search.errorMessage : feed.errorMessage;

    return Column(
      children: [
        // Elegant Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearchSubmit,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Gifs & Niches...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppTheme.primaryNeon),
              ),
            ),
          ),
        ),

        // Sorting/Stream Tabs selector (only visible when not searching)
        if (!isSearching)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSortChip(feed, 'trending', '🔥 Trending'),
                const SizedBox(width: 8),
                _buildSortChip(feed, 'new', '⚡ Newest'),
                const SizedBox(width: 8),
                _buildSortChip(feed, 'top', '⭐ Best / Popular'),
              ],
            ),
          ),
        
        // Main dynamic feed content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (isSearching) {
                await search.performSearch(search.currentQuery);
              } else {
                await feed.refreshFeed();
              }
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error loading content: $error',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (gifs.isEmpty && !isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No content found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else ...[
                  // Responsive Grid Layout
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 0,
                        childAspectRatio: 0.70, // Optimized aspect ratio
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return VideoCard(
                            gif: gifs[index],
                            siblings: gifs.cast<GifInfo>(),
                            index: index,
                          );
                        },
                        childCount: gifs.length,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = Provider.of<FeedProvider>(context);
    final search = Provider.of<SearchProvider>(context);

    Widget activeBody;
    if (_currentBottomNavIndex == 1) {
      activeBody = const NichesScreen();
    } else if (_currentBottomNavIndex == 2) {
      activeBody = const LibraryScreen();
    } else if (_currentBottomNavIndex == 3) {
      activeBody = const AIScreen();
    } else if (_currentBottomNavIndex == 4) {
      activeBody = Center(child: Text('Me Profile (Coming soon)', style: TextStyle(color: Colors.white.withAlpha(191))));
    } else {
      activeBody = _buildHomeFeedBody(feed, search);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppTheme.primaryNeon, AppTheme.secondaryNeon],
          ).createShader(bounds),
          child: const Text(
            'RGIFY',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const SidebarDrawer(),
      body: Stack(
        children: [
          activeBody,
          const BulkActionBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          Provider.of<SelectionProvider>(context, listen: false).exitSelectionMode();
          setState(() {
            _currentBottomNavIndex = index;
          });
        },
        backgroundColor: AppTheme.background,
        selectedItemColor: AppTheme.primaryNeon,
        unselectedItemColor: AppTheme.textSecondary.withAlpha(153),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Niches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            activeIcon: Icon(Icons.psychology),
            label: 'AI Gen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
