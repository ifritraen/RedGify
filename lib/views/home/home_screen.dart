import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/search_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../widgets/video_card.dart';
// import '../widgets/sidebar.dart';
import '../explore/explore_screen.dart';
import '../library/library_screen.dart';
// import '../ai/ai_screen.dart';
import '../profile/me_profile_screen.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/glassy_container.dart';
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
          color: isSelected ? AppTheme.primaryNeon : AppTheme.borderLight,
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
        // Elegant Search Bar (Commented out - now in bottom bar search button)
        /*
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
        */

        if (isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppTheme.primaryNeon, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'Search results for ',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            children: [
                              TextSpan(
                                text: '"${search.currentQuery}"',
                                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.borderLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: AppTheme.textSecondary, size: 14),
                        ),
                      ),
                    ],
                  ),
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
                  SliverFillRemaining(
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
      // activeBody = const ExploreScreen();
      activeBody = const SafeArea(child: ExploreScreen());
    } else if (_currentBottomNavIndex == 2) {
      activeBody = const LibraryScreen();
    } else if (_currentBottomNavIndex == 3) {
      activeBody = const MeProfileScreen();
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
              child: GlassyContainer(
                borderRadius: 27,
                color: AppTheme.glassBg,
                borderColor: AppTheme.border,
                borderWidth: 1.0,
                boxShadow: AppTheme.cardGlow,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                    _buildNavItem(1, Icons.explore_outlined, Icons.explore, 'Explore'),
                    _buildNavItem(-1, Icons.search_outlined, Icons.search, 'Search', onTapOverride: _showSearchBottomSheet),
                    _buildNavItem(2, Icons.bookmark_outline, Icons.bookmark, 'Library'),
                    // _buildNavItem(3, Icons.psychology_outlined, Icons.psychology, 'AI Gen'),
                    _buildNavItem(3, Icons.person_outline, Icons.person, 'Me'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? Colors.black.withAlpha(200) : Colors.white.withAlpha(235);
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final hintColor = isDark ? Colors.white38 : AppTheme.textSecondary;
    final fillColor = isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10);
    final scrollbarColor = isDark ? Colors.white24 : Colors.black12;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final localSearchController = TextEditingController(text: _searchController.text);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scrollbarColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: localSearchController,
                      style: TextStyle(color: textColor),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search Gifs & Niches...',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryNeon),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: AppTheme.primaryNeon),
                        ),
                      ),
                      onSubmitted: (query) {
                        Navigator.pop(context);
                        if (query.trim().isNotEmpty) {
                          _searchController.text = query;
                          _onSearchSubmit(query);
                          setState(() {
                            _currentBottomNavIndex = 0; // Switch to Home tab to show results
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (localSearchController.text.trim().isNotEmpty) {
                            _searchController.text = localSearchController.text;
                            _onSearchSubmit(localSearchController.text);
                            setState(() {
                              _currentBottomNavIndex = 0; // Switch to Home tab to show results
                            });
                          }
                        },
                        child: const Text(
                          'Search',
                          style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, {VoidCallback? onTapOverride}) {
    // If tap override is set, it is never selected based on the current page index
    final isSelected = onTapOverride == null && _currentBottomNavIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Provider.of<SelectionProvider>(context, listen: false).exitSelectionMode();
        if (onTapOverride != null) {
          onTapOverride();
        } else {
          setState(() {
            _currentBottomNavIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
