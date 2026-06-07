import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/search_provider.dart';
import '../../config/theme.dart';
import '../widgets/video_card.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/glassy_container.dart';
import '../creator/creator_profile_screen.dart';
import '../player/tag_results_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String initialTab;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.initialTab,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ScrollController _gifScrollController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();
  final ScrollController _nicheScrollController = ScrollController();
  final ScrollController _creatorScrollController = ScrollController();

  final List<String> _tabs = ['All', 'GIFs', 'Images', 'Niches', 'Creators'];

  @override
  void initState() {
    super.initState();
    
    // Trigger initial search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false)
          .performSearch(widget.query, bypassCache: false);
    });

    // Pagination Listeners
    _gifScrollController.addListener(() {
      if (_gifScrollController.position.pixels >= _gifScrollController.position.maxScrollExtent - 200) {
        Provider.of<SearchProvider>(context, listen: false).fetchNextGifs();
      }
    });

    _imageScrollController.addListener(() {
      if (_imageScrollController.position.pixels >= _imageScrollController.position.maxScrollExtent - 200) {
        Provider.of<SearchProvider>(context, listen: false).fetchNextImages();
      }
    });

    _nicheScrollController.addListener(() {
      if (_nicheScrollController.position.pixels >= _nicheScrollController.position.maxScrollExtent - 200) {
        Provider.of<SearchProvider>(context, listen: false).fetchNextNiches();
      }
    });

    _creatorScrollController.addListener(() {
      if (_creatorScrollController.position.pixels >= _creatorScrollController.position.maxScrollExtent - 200) {
        Provider.of<SearchProvider>(context, listen: false).fetchNextCreators();
      }
    });
  }

  @override
  void dispose() {
    _gifScrollController.dispose();
    _imageScrollController.dispose();
    _nicheScrollController.dispose();
    _creatorScrollController.dispose();
    super.dispose();
  }

  int _getInitialTabIndex() {
    final idx = _tabs.indexOf(widget.initialTab);
    return idx != -1 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final search = Provider.of<SearchProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final tabIndex = _getInitialTabIndex();

    return DefaultTabController(
      length: _tabs.length,
      initialIndex: tabIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.query,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 20,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg.withOpacity(0.4),
                    border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    indicatorColor: AppTheme.primaryNeon,
                    indicatorWeight: 2,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildAllTab(search),
                _buildGifsTab(search),
                _buildImagesTab(search),
                _buildNichesTab(search),
                _buildCreatorsTab(search),
              ],
            ),
            const BulkActionBar(),
          ],
        ),
      ),
    );
  }

  // --- ALL Tab View ---
  Widget _buildAllTab(SearchProvider search) {
    if (search.isLoadingGifs && search.gifResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;

    return RefreshIndicator(
      onRefresh: () => search.performSearch(widget.query, bypassCache: true),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Niches Row
          if (search.nicheResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Niches',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: search.nicheResults.length,
                itemBuilder: (context, index) {
                  final niche = search.nicheResults[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TagResultsScreen(tag: niche.name),
                          ),
                        );
                      },
                      child: GlassyContainer(
                        borderRadius: 16,
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              niche.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${niche.subscribers} subs',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Creators Row
          if (search.creatorResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Creators',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: search.creatorResults.length,
                itemBuilder: (context, index) {
                  final creator = search.creatorResults[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatorProfileScreen(username: creator.username),
                          ),
                        );
                      },
                      child: GlassyContainer(
                        borderRadius: 16,
                        width: 100,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.borderLight,
                              backgroundImage: creator.profileImageUrl != null
                                  ? NetworkImage(creator.profileImageUrl!)
                                  : null,
                              child: creator.profileImageUrl == null
                                  ? const Icon(Icons.person, color: Colors.white54)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              creator.name.isNotEmpty ? creator.name : creator.username,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${creator.followers} fans',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // GIFs Grid Header
          if (search.gifResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'GIFs & Videos',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.70,
              ),
              itemCount: search.gifResults.take(4).length,
              itemBuilder: (context, index) {
                return VideoCard(
                  gif: search.gifResults[index],
                  siblings: search.gifResults,
                  index: index,
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Images Grid Header
          if (search.imageResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Static Images',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.70,
              ),
              itemCount: search.imageResults.take(4).length,
              itemBuilder: (context, index) {
                return VideoCard(
                  gif: search.imageResults[index],
                  siblings: search.imageResults,
                  index: index,
                );
              },
            ),
          ],
          
          if (search.gifResults.isEmpty && search.imageResults.isEmpty && search.nicheResults.isEmpty && search.creatorResults.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Text('No results found for "${widget.query}"', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
        ],
      ),
    );
  }

  // --- GIFs Tab View ---
  Widget _buildGifsTab(SearchProvider search) {
    if (search.isLoadingGifs && search.gifResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
    }

    if (search.gifResults.isEmpty) {
      return Center(child: Text('No GIFs found', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return RefreshIndicator(
      onRefresh: () => search.fetchNextGifs(bypassCache: true),
      child: CustomScrollView(
        controller: _gifScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return VideoCard(
                    gif: search.gifResults[index],
                    siblings: search.gifResults,
                    index: index,
                  );
                },
                childCount: search.gifResults.length,
              ),
            ),
          ),
          if (search.isLoadingGifs)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
              ),
            ),
        ],
      ),
    );
  }

  // --- Images Tab View ---
  Widget _buildImagesTab(SearchProvider search) {
    if (search.isLoadingImages && search.imageResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
    }

    if (search.imageResults.isEmpty) {
      return Center(child: Text('No images found', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return RefreshIndicator(
      onRefresh: () => search.fetchNextImages(bypassCache: true),
      child: CustomScrollView(
        controller: _imageScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return VideoCard(
                    gif: search.imageResults[index],
                    siblings: search.imageResults,
                    index: index,
                  );
                },
                childCount: search.imageResults.length,
              ),
            ),
          ),
          if (search.isLoadingImages)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
              ),
            ),
        ],
      ),
    );
  }

  // --- Niches Tab View ---
  Widget _buildNichesTab(SearchProvider search) {
    if (search.isLoadingNiches && search.nicheResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
    }

    if (search.nicheResults.isEmpty) {
      return Center(child: Text('No niches found', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return RefreshIndicator(
      onRefresh: () => search.fetchNextNiches(bypassCache: true),
      child: CustomScrollView(
        controller: _nicheScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final niche = search.nicheResults[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TagResultsScreen(tag: niche.name),
                        ),
                      );
                    },
                    child: GlassyContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            niche.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${niche.subscribers} subscribers',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: search.nicheResults.length,
              ),
            ),
          ),
          if (search.isLoadingNiches)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
              ),
            ),
        ],
      ),
    );
  }

  // --- Creators Tab View ---
  Widget _buildCreatorsTab(SearchProvider search) {
    if (search.isLoadingCreators && search.creatorResults.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
    }

    if (search.creatorResults.isEmpty) {
      return Center(child: Text('No creators found', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return RefreshIndicator(
      onRefresh: () => search.fetchNextCreators(bypassCache: true),
      child: CustomScrollView(
        controller: _creatorScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final creator = search.creatorResults[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatorProfileScreen(username: creator.username),
                        ),
                      );
                    },
                    child: GlassyContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.borderLight,
                            backgroundImage: creator.profileImageUrl != null
                                ? NetworkImage(creator.profileImageUrl!)
                                : null,
                            child: creator.profileImageUrl == null
                                ? const Icon(Icons.person, size: 30, color: Colors.white54)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            creator.name.isNotEmpty ? creator.name : creator.username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${creator.followers} followers',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: search.creatorResults.length,
              ),
            ),
          ),
          if (search.isLoadingCreators)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
              ),
            ),
        ],
      ),
    );
  }
}
