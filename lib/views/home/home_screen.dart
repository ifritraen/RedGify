import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/search_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../widgets/video_card.dart';
// import '../widgets/sidebar.dart';
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
  bool _isBottomBarVisible = true;

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
                await search.performSearch(search.currentQuery, bypassCache: true);
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
                    // padding: const EdgeInsets.all(16),
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
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
      // activeBody = const NichesScreen();
      activeBody = const SafeArea(child: NichesScreen());
    } else if (_currentBottomNavIndex == 2) {
      activeBody = const LibraryScreen();
    } else if (_currentBottomNavIndex == 3) {
      // activeBody = const AIScreen();
      activeBody = const SafeArea(child: AIScreen());
    } else if (_currentBottomNavIndex == 4) {
      // activeBody = Center(child: Text('Me Profile (Coming soon)', style: TextStyle(color: Colors.white.withAlpha(191))));
      activeBody = SafeArea(child: Center(child: Text('Me Profile (Coming soon)', style: TextStyle(color: Colors.white.withAlpha(191)))));
    } else {
      // activeBody = _buildHomeFeedBody(feed, search);
      activeBody = SafeArea(child: _buildHomeFeedBody(feed, search));
    }

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   title: ShaderMask(
      //     shaderCallback: (bounds) => const LinearGradient(
      //       colors: [AppTheme.primaryNeon, AppTheme.secondaryNeon],
      //     ).createShader(bounds),
      //     child: const Text(
      //       'RGIFY',
      //       style: TextStyle(
      //         fontWeight: FontWeight.bold,
      //         fontSize: 22,
      //         letterSpacing: 1.5,
      //         color: Colors.white,
      //       ),
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.notifications_outlined, color: Colors.white),
      //       onPressed: () {},
      //     ),
      //   ],
      // ),
      // drawer: const SidebarDrawer(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            final double scrollDelta = notification.scrollDelta ?? 0.0;
            if (scrollDelta > 2.0) {
              // Scrolling down - hide bottom bar
              if (_isBottomBarVisible) {
                setState(() {
                  _isBottomBarVisible = false;
                });
              }
            } else if (scrollDelta < -2.0) {
              // Scrolling up - show bottom bar
              if (!_isBottomBarVisible) {
                setState(() {
                  _isBottomBarVisible = true;
                });
              }
            }
          }
          return false;
        },
        child: Stack(
          children: [
            activeBody,
            const BulkActionBar(),
            // Custom floating frosted-glass bottom bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _isBottomBarVisible ? 20 : -80,
              left: 24,
              right: 24,
              height: 54,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(color: Colors.white.withAlpha(30), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                        _buildNavItem(1, Icons.explore_outlined, Icons.explore, 'Niches'),
                        _buildNavItem(2, Icons.bookmark_outline, Icons.bookmark, 'Library'),
                        _buildNavItem(3, Icons.psychology_outlined, Icons.psychology, 'AI Gen'),
                        _buildNavItem(4, Icons.person_outline, Icons.person, 'Me'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentBottomNavIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Provider.of<SelectionProvider>(context, listen: false).exitSelectionMode();
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? AppTheme.primaryNeon : AppTheme.textSecondary.withAlpha(180),
              size: 20,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    const BoxShadow(
                      color: AppTheme.primaryNeon,
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
