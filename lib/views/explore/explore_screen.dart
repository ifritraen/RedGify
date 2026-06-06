import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/search_provider.dart';
import '../../config/theme.dart';
import '../widgets/video_card.dart';
import '../creator/creator_profile_screen.dart';
import '../player/tag_results_screen.dart';
import '../widgets/bulk_action_bar.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _gifScrollController = ScrollController();
  final ScrollController _imageScrollController = ScrollController();
  final ScrollController _creatorScrollController = ScrollController();
  final ScrollController _nicheScrollController = ScrollController();
  final TextEditingController _tagSearchController = TextEditingController();

  String _tagSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExploreProvider>(context, listen: false);
      provider.fetchNextGifsPage();
      provider.fetchNextImagesPage();
      provider.fetchNextCreatorsPage();
      provider.fetchNichesList().then((_) {
        if (provider.niches.isNotEmpty && provider.selectedNicheId == null) {
          provider.selectNiche(provider.niches.first.id);
        }
      });
      provider.fetchTrendingTags();
    });

    _gifScrollController.addListener(() {
      final provider = Provider.of<ExploreProvider>(context, listen: false);
      if (_gifScrollController.position.pixels >= _gifScrollController.position.maxScrollExtent - 200) {
        provider.fetchNextGifsPage();
      }
    });

    _imageScrollController.addListener(() {
      final provider = Provider.of<ExploreProvider>(context, listen: false);
      if (_imageScrollController.position.pixels >= _imageScrollController.position.maxScrollExtent - 200) {
        provider.fetchNextImagesPage();
      }
    });

    _creatorScrollController.addListener(() {
      final provider = Provider.of<ExploreProvider>(context, listen: false);
      if (_creatorScrollController.position.pixels >= _creatorScrollController.position.maxScrollExtent - 200) {
        provider.fetchNextCreatorsPage();
      }
    });

    _nicheScrollController.addListener(() {
      final provider = Provider.of<ExploreProvider>(context, listen: false);
      if (_nicheScrollController.position.pixels >= _nicheScrollController.position.maxScrollExtent - 200) {
        provider.fetchNextNicheGifsPage();
      }
    });

    _tagSearchController.addListener(() {
      setState(() {
        _tagSearchQuery = _tagSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gifScrollController.dispose();
    _imageScrollController.dispose();
    _creatorScrollController.dispose();
    _nicheScrollController.dispose();
    _tagSearchController.dispose();
    super.dispose();
  }

  // Helper to build Sort Chip
  Widget _buildFilterChip({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryNeon,
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryNeon : Colors.white.withAlpha(15),
        ),
      ),
      onSelected: (_) => onTap(),
    );
  }

  // Build standard media filter chips row (GIF, Images, Creator)
  Widget _buildMediaFilterRow({
    required String activeOrder,
    required String? activeTime,
    required Function(String order, String? time) onFilterChanged,
  }) {
    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            isSelected: activeOrder == 'trending',
            label: '🔥 Trending',
            onTap: () => onFilterChanged('trending', null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            isSelected: activeOrder == 'top' && activeTime == 'week',
            label: '⭐ Top Week',
            onTap: () => onFilterChanged('top', 'week'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            isSelected: activeOrder == 'top' && activeTime == 'month',
            label: '⭐ Top Month',
            onTap: () => onFilterChanged('top', 'month'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            isSelected: activeOrder == 'latest',
            label: '⚡ Latest',
            onTap: () => onFilterChanged('latest', null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExploreProvider>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // No main App bar text to save space
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryNeon,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Gif'),
            Tab(text: 'Images'),
            Tab(text: 'Creator'),
            Tab(text: 'Niche'),
            Tab(text: 'Tags'),
          ],
          onTap: (index) {
            Provider.of<SelectionProvider>(context, listen: false).exitSelectionMode();
          },
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildGifTab(provider),
              _buildImageTab(provider),
              _buildCreatorTab(provider),
              _buildNicheTab(provider),
              _buildTagsTab(provider),
            ],
          ),
          const BulkActionBar(),
        ],
      ),
    );
  }

  // --- GIF Tab UI ---
  Widget _buildGifTab(ExploreProvider provider) {
    return Column(
      children: [
        _buildMediaFilterRow(
          activeOrder: provider.gifOrder,
          activeTime: provider.gifTime,
          onFilterChanged: (order, time) => provider.setGifFilters(order: order, time: time),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshGifs,
            child: CustomScrollView(
              controller: _gifScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (provider.gifError != null && provider.gifs.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: Text('Error: ${provider.gifError}', style: const TextStyle(color: Colors.redAccent))),
                  )
                else if (provider.gifs.isEmpty && !provider.isLoadingGifs)
                  const SliverFillRemaining(
                    child: Center(child: Text('No GIFs found.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 0,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => VideoCard(
                          gif: provider.gifs[index],
                          siblings: provider.gifs,
                          index: index,
                        ),
                        childCount: provider.gifs.length,
                      ),
                    ),
                  ),
                  if (provider.isLoadingGifs)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
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

  // --- Image Tab UI ---
  Widget _buildImageTab(ExploreProvider provider) {
    return Column(
      children: [
        _buildMediaFilterRow(
          activeOrder: provider.imageOrder,
          activeTime: provider.imageTime,
          onFilterChanged: (order, time) => provider.setImageFilters(order: order, time: time),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshImages,
            child: CustomScrollView(
              controller: _imageScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (provider.imageError != null && provider.images.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: Text('Error: ${provider.imageError}', style: const TextStyle(color: Colors.redAccent))),
                  )
                else if (provider.images.isEmpty && !provider.isLoadingImages)
                  const SliverFillRemaining(
                    child: Center(child: Text('No images found.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 0,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => VideoCard(
                          gif: provider.images[index],
                          siblings: provider.images,
                          index: index,
                        ),
                        childCount: provider.images.length,
                      ),
                    ),
                  ),
                  if (provider.isLoadingImages)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
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

  // --- Creator Tab UI ---
  Widget _buildCreatorTab(ExploreProvider provider) {
    return Column(
      children: [
        _buildMediaFilterRow(
          activeOrder: provider.creatorOrder,
          activeTime: provider.creatorTime,
          onFilterChanged: (order, time) => provider.setCreatorFilters(order: order, time: time),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshCreators,
            child: CustomScrollView(
              controller: _creatorScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (provider.creatorError != null && provider.creators.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: Text('Error: ${provider.creatorError}', style: const TextStyle(color: Colors.redAccent))),
                  )
                else if (provider.creators.isEmpty && !provider.isLoadingCreators)
                  const SliverFillRemaining(
                    child: Center(child: Text('No creators found.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final creator = provider.creators[index];
                          return Card(
                            color: AppTheme.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withAlpha(15)),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryNeon,
                                backgroundImage: creator.profileImageUrl != null
                                    ? NetworkImage(creator.profileImageUrl!)
                                    : null,
                                child: creator.profileImageUrl == null
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      creator.name.isNotEmpty ? creator.name : creator.username,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (creator.verified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 14, color: AppTheme.accentNeon),
                                  ]
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '@${creator.username} • ${creator.followers} followers • ${creator.views} views',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreatorProfileScreen(username: creator.username),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: provider.creators.length,
                      ),
                    ),
                  ),
                  if (provider.isLoadingCreators)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
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

  // --- Niche Tab UI ---
  Widget _buildNicheTab(ExploreProvider provider) {
    return Column(
      children: [
        // Niche horizontal catalog row
        if (provider.isLoadingNiches && provider.niches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
          )
        else if (provider.nichesError != null && provider.niches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${provider.nichesError}', style: const TextStyle(color: Colors.redAccent)),
          )
        else
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.niches.length,
              itemBuilder: (context, index) {
                final niche = provider.niches[index];
                final isSelected = niche.id == provider.selectedNicheId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      niche.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryNeon,
                    backgroundColor: AppTheme.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? AppTheme.primaryNeon : Colors.white.withAlpha(15)),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        provider.selectNiche(niche.id);
                      }
                    },
                  ),
                );
              },
            ),
          ),

        // Niche sorting row (Hot, Latest, Top)
        Container(
          height: 32,
          margin: const EdgeInsets.only(bottom: 6),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip(
                isSelected: provider.nicheOrder == 'hot',
                label: '🔥 Hot',
                onTap: () => provider.setNicheOrder('hot'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                isSelected: provider.nicheOrder == 'latest',
                label: '⚡ Latest',
                onTap: () => provider.setNicheOrder('latest'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                isSelected: provider.nicheOrder == 'top',
                label: '⭐ Top',
                onTap: () => provider.setNicheOrder('top'),
              ),
            ],
          ),
        ),

        // Selected niche gifs grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshNicheGifs,
            child: CustomScrollView(
              controller: _nicheScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (provider.nicheGifsError != null && provider.nicheGifs.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: Text('Error: ${provider.nicheGifsError}', style: const TextStyle(color: Colors.redAccent))),
                  )
                else if (provider.nicheGifs.isEmpty && !provider.isLoadingNicheGifs)
                  const SliverFillRemaining(
                    child: Center(child: Text('No content found for this niche.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 0,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => VideoCard(
                          gif: provider.nicheGifs[index],
                          siblings: provider.nicheGifs,
                          index: index,
                        ),
                        childCount: provider.nicheGifs.length,
                      ),
                    ),
                  ),
                  if (provider.isLoadingNicheGifs)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
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

  // --- Tags Tab UI ---
  Widget _buildTagsTab(ExploreProvider provider) {
    // Filter tags client-side by query
    final filteredTags = provider.tags.where((tag) {
      final name = (tag['name'] as String? ?? '').toLowerCase();
      return name.contains(_tagSearchQuery);
    }).toList();

    return Column(
      children: [
        // Tag search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _tagSearchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Filter tags...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.filter_list, color: Colors.white54),
              suffixIcon: _tagSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () => _tagSearchController.clear(),
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchTrendingTags(bypassCache: true),
            child: provider.isLoadingTags && provider.tags.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
                : provider.tagsError != null && provider.tags.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height - 200,
                          alignment: Alignment.center,
                          child: Text('Error: ${provider.tagsError}', style: const TextStyle(color: Colors.redAccent)),
                        ),
                      )
                    : filteredTags.isEmpty
                        ? const SingleChildScrollView(
                            // physics: const AlwaysScrollableScrollPhysics(),
                            physics: AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No tags match filters.', style: TextStyle(color: AppTheme.textSecondary))),
                            ),
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: filteredTags.map((tag) {
                                  final name = tag['name'] as String? ?? '';
                                  final count = tag['count'] as int? ?? 0;
                                  return ActionChip(
                                    backgroundColor: AppTheme.cardBg,
                                    side: BorderSide(color: Colors.white.withAlpha(15)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    label: Text(
                                      '#$name ($count)',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChangeNotifierProvider(
                                            create: (_) => SearchProvider()..performSearch(name),
                                            child: TagResultsScreen(tag: name),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
          ),
        ),
      ],
    );
  }
}
