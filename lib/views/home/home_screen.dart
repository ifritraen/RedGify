import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/personalized_feed_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/playback_settings_provider.dart';
import '../../providers/local_player_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../widgets/video_card.dart';
// import '../widgets/sidebar.dart';
import '../explore/explore_screen.dart';
import '../library/library_screen.dart';
// import '../ai/ai_screen.dart';
import '../profile/me_profile_screen.dart';
import '../local/local_player_screen.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/glassy_container.dart';
import '../search/search_results_screen.dart';
import 'package:flutter/services.dart';
import '../../providers/selection_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final ValueNotifier<bool> headerVisibility = ValueNotifier<bool>(true);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _currentBottomNavIndex = 0;
  bool _isBottomBarVisible = true;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final search = Provider.of<SearchProvider>(context, listen: false);

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (search.currentQuery.isNotEmpty) {
          search.fetchNextSearchResults();
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

  // void _onSearchSubmit(String query) {
  //   if (query.trim().isNotEmpty) {
  //     Provider.of<SearchProvider>(context, listen: false).performSearch(query);
  //   }
  // }

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

    if (isSearching) {
      final List gifs = search.searchResults;
      final bool isLoading = search.isLoading;
      final String? error = search.errorMessage;

      return Column(
        children: [
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await search.performSearch(search.currentQuery, bypassCache: true);
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
                    SliverPadding(
                      // padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
                      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          // crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          // crossAxisSpacing: 16,
                          // mainAxisSpacing: 0,
                          // childAspectRatio: 0.70,
                          crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 0.70,
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

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: HomeScreen.headerVisibility,
            builder: (context, isVisible, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isVisible ? 48 : 0,
                child: isVisible
                    ? Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              indicatorColor: AppTheme.primaryNeon,
                              indicatorSize: TabBarIndicatorSize.label,
                              labelColor: Colors.white,
                              unselectedLabelColor: AppTheme.textSecondary,
                              tabs: const [
                                Tab(text: 'Feed'),
                                Tab(text: 'Trending'),
                              ],
                            ),
                          ),
                          Consumer<PlaybackSettingsProvider>(
                            builder: (context, settings, child) {
                              final isOneCol = settings.gridColumns == 1;
                              return IconButton(
                                icon: Icon(
                                  isOneCol ? Icons.grid_view : Icons.view_stream,
                                  color: AppTheme.textPrimary,
                                  size: 20,
                                ),
                                tooltip: isOneCol ? 'Switch to 2 columns' : 'Switch to 1 column',
                                onPressed: () => settings.toggleGridColumns(),
                              );
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              children: [
                PersonalizedFeedView(),
                TrendingFeedView(),
              ],
            ),
          ),
        ],
      ),
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
      activeBody = const LocalPlayerScreen();
    } else if (_currentBottomNavIndex == 3) {
      activeBody = const LibraryScreen();
    } else if (_currentBottomNavIndex == 4) {
      activeBody = const MeProfileScreen();
    } else {
      // activeBody = _buildHomeFeedBody(feed, search);
      activeBody = SafeArea(child: _buildHomeFeedBody(feed, search));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If on Local Folder tab (index 2) and inside a subfolder, navigate up to parent folder
        if (_currentBottomNavIndex == 2) {
          final localProvider = Provider.of<LocalPlayerProvider>(context, listen: false);
          if (localProvider.canNavigateBack) {
            await localProvider.navigateBack();
            return;
          }
        }

        // 1. If not on Home tab, go to Home tab first
        if (_currentBottomNavIndex != 0) {
          setState(() {
            _currentBottomNavIndex = 0;
          });
          return;
        }

        // 2. On Home tab, require double back press to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Press back again to exit',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.cardBg.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          return;
        }

        // Exit the app
        await SystemNavigator.pop();
      },
      child: Scaffold(
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
        body: Listener(
          onPointerMove: (PointerMoveEvent event) {
            final double dy = event.delta.dy;
            if (dy < -3.0) {
              // User dragged finger up -> scrolling down -> hide bottom/top bars
              if (_isBottomBarVisible) {
                setState(() {
                  _isBottomBarVisible = false;
                });
                HomeScreen.headerVisibility.value = false;
              }
            } else if (dy > 3.0) {
              // User dragged finger down -> scrolling up -> show bottom/top bars
              if (!_isBottomBarVisible) {
                setState(() {
                  _isBottomBarVisible = true;
                });
                HomeScreen.headerVisibility.value = true;
              }
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollUpdateNotification) {
                final double scrollDelta = notification.scrollDelta ?? 0.0;
                if (scrollDelta > 2.0) {
                  // Scrolling down - hide bottom bar
                  if (_isBottomBarVisible) {
                    setState(() {
                      _isBottomBarVisible = false;
                    });
                    HomeScreen.headerVisibility.value = false;
                  }
                } else if (scrollDelta < -2.0) {
                  // Scrolling up - show bottom bar
                  if (!_isBottomBarVisible) {
                    setState(() {
                      _isBottomBarVisible = true;
                    });
                    HomeScreen.headerVisibility.value = true;
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
                        _buildNavItem(2, Icons.folder_open_outlined, Icons.folder_open, 'Local'),
                        _buildNavItem(3, Icons.bookmark_outline, Icons.bookmark, 'Library'),
                        // _buildNavItem(3, Icons.psychology_outlined, Icons.psychology, 'AI Gen'),
                        _buildNavItem(4, Icons.person_outline, Icons.person, 'Me'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? Colors.black.withAlpha(220) : Colors.white.withAlpha(235);
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final hintColor = isDark ? Colors.white38 : AppTheme.textSecondary;
    final fillColor = isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10);
    final scrollbarColor = isDark ? Colors.white24 : Colors.black12;

    Provider.of<SearchProvider>(context, listen: false).clearSuggestions();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final localSearchController = TextEditingController(text: _searchController.text);
        String selectedFilter = 'All';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer<SearchProvider>(
              builder: (context, searchProvider, child) {
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: scrollbarColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Horizontal Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['All', 'GIFs', 'Images', 'Niches', 'Creators'].map((filter) {
                                  final isSelected = selectedFilter == filter;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0, bottom: 12.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          selectedFilter = filter;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? AppTheme.primaryNeon.withOpacity(0.15) 
                                              : AppTheme.cardBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected 
                                                ? AppTheme.primaryNeon 
                                                : AppTheme.border
                                          ),
                                        ),
                                        child: Text(
                                          filter,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            TextField(
                              controller: localSearchController,
                              style: TextStyle(color: textColor),
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search RedGify...',
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
                              onChanged: (val) {
                                searchProvider.fetchSuggestions(val);
                              },
                              onSubmitted: (query) {
                                if (query.trim().isNotEmpty) {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchResultsScreen(
                                        query: query.trim(),
                                        initialTab: selectedFilter,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),

                            // Real-time suggestions list
                            if (searchProvider.suggestions.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 220),
                                decoration: BoxDecoration(
                                  color: fillColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(8),
                                  itemCount: searchProvider.suggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = searchProvider.suggestions[index];
                                    final text = suggestion['text'] ?? '';
                                    final count = suggestion['gifs'] ?? 0;

                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      leading: const Icon(Icons.search_outlined, color: AppTheme.primaryNeon, size: 16),
                                      title: Text(
                                        text,
                                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                      trailing: count > 0
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.borderLight,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${count >= 1000 ? (count / 1000).toStringAsFixed(1) + "K" : count} posts',
                                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SearchResultsScreen(
                                              query: text,
                                              initialTab: 'All',
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  final query = localSearchController.text.trim();
                                  if (query.isNotEmpty) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SearchResultsScreen(
                                          query: query,
                                          initialTab: selectedFilter,
                                        ),
                                      ),
                                    );
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
          },
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

class PersonalizedFeedView extends StatefulWidget {
  const PersonalizedFeedView({super.key});

  @override
  State<PersonalizedFeedView> createState() => _PersonalizedFeedViewState();
}

class _PersonalizedFeedViewState extends State<PersonalizedFeedView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lib = Provider.of<LibraryProvider>(context, listen: false);
      Provider.of<PersonalizedFeedProvider>(context, listen: false)
          .fetchInitialFeed(lib.subscribedCreators);
    });

    _scrollController.addListener(() {
      final lib = Provider.of<LibraryProvider>(context, listen: false);
      final feed = Provider.of<PersonalizedFeedProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        feed.fetchNextPage(lib.subscribedCreators);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = Provider.of<PersonalizedFeedProvider>(context);
    final lib = Provider.of<LibraryProvider>(context);
    
    return RefreshIndicator(
      onRefresh: () async {
        await feed.refreshFeed(lib.subscribedCreators);
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (feed.errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error loading feed: ${feed.errorMessage}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (feed.gifs.isEmpty && !feed.isLoading)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Your feed is empty. Watch videos and subscribe to creators to personalize your feed!',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            SliverPadding(
              // padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
              padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  // crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  // crossAxisSpacing: 16,
                  // mainAxisSpacing: 0,
                  // childAspectRatio: 0.70,
                  crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.70,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return VideoCard(
                      gif: feed.gifs[index],
                      siblings: feed.gifs,
                      index: index,
                    );
                  },
                  childCount: feed.gifs.length,
                ),
              ),
            ),
            if (feed.isLoading)
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
    );
  }
}

class TrendingFeedView extends StatefulWidget {
  const TrendingFeedView({super.key});

  @override
  State<TrendingFeedView> createState() => _TrendingFeedViewState();
}

class _TrendingFeedViewState extends State<TrendingFeedView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedProvider>(context, listen: false).fetchInitialFeed();
    });

    _scrollController.addListener(() {
      final feed = Provider.of<FeedProvider>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        feed.fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final feed = Provider.of<FeedProvider>(context);

    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: HomeScreen.headerVisibility,
          builder: (context, isVisible, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isVisible ? 44 : 0,
              child: isVisible
                  ? Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          height: 36,
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
                      ],
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await feed.refreshFeed();
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (feed.errorMessage != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error loading content: ${feed.errorMessage}',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (feed.gifs.isEmpty && !feed.isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No content found.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    // padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        // crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        // crossAxisSpacing: 16,
                        // mainAxisSpacing: 0,
                        // childAspectRatio: 0.70,
                        crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return VideoCard(
                            gif: feed.gifs[index],
                            siblings: feed.gifs,
                            index: index,
                          );
                        },
                        childCount: feed.gifs.length,
                      ),
                    ),
                  ),
                  if (feed.isLoading)
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
}
