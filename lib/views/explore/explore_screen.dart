import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/explore_provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/playback_settings_provider.dart';
import '../../config/theme.dart';
import '../widgets/video_card.dart';
import '../creator/creator_profile_screen.dart';
import '../player/tag_results_screen.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/glassy_container.dart';
import '../home/home_screen.dart';
import '../widgets/subscribe_button.dart';

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

  final Map<String, GlobalKey> _sectionKeys = {};
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
          color: isSelected ? AppTheme.primaryNeon : AppTheme.borderLight,
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
    return ValueListenableBuilder<bool>(
      valueListenable: HomeScreen.headerVisibility,
      builder: (context, isVisible, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isVisible ? 34 : 0,
          margin: EdgeInsets.symmetric(vertical: isVisible ? 8 : 0),
          child: isVisible
              ? ListView(
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
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExploreProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: HomeScreen.headerVisibility,
              builder: (context, isVisible, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isVisible ? 40 : 0,
                  child: isVisible
                      ? ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.glassBg,
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.border, width: 1.0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TabBar(
                                      controller: _tabController,
                                      indicator: const UnderlineTabIndicator(
                                        borderSide: BorderSide(color: AppTheme.primaryNeon, width: 1.5),
                                        insets: EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                      labelColor: AppTheme.textPrimary,
                                      unselectedLabelColor: AppTheme.textSecondary,
                                      labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                                      unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.normal),
                                      isScrollable: false,
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
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
            Expanded(
              child: Stack(
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
            ),
          ],
        ),
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
                  SliverFillRemaining(
                    child: Center(child: Text('No GIFs found.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    // padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
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
                  SliverFillRemaining(
                    child: Center(child: Text('No images found.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    // padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
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
                  SliverFillRemaining(
                    child: Center(child: Text('No creators found.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final creator = provider.creators[index];
                          return GlassyContainer(
                            color: AppTheme.cardBg,
                            borderColor: AppTheme.border,
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
                                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
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
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
                              trailing: SubscribeButton(creatorId: creator.username, compact: true),
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
        ValueListenableBuilder<bool>(
          valueListenable: HomeScreen.headerVisibility,
          builder: (context, isVisible, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isVisible ? 44 : 0,
              margin: EdgeInsets.symmetric(vertical: isVisible ? 6 : 0),
              child: isVisible
                  ? (provider.isLoadingNiches && provider.niches.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
                      : (provider.nichesError != null && provider.niches.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error: ${provider.nichesError}', style: const TextStyle(color: Colors.redAccent)),
                            )
                          : ListView.builder(
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
                                      side: BorderSide(color: isSelected ? AppTheme.primaryNeon : AppTheme.borderLight),
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        provider.selectNiche(niche.id);
                                      }
                                    },
                                  ),
                                );
                              },
                            )))
                  : const SizedBox.shrink(),
            );
          },
        ),

        // Niche sorting row (Hot, Latest, Top)
        ValueListenableBuilder<bool>(
          valueListenable: HomeScreen.headerVisibility,
          builder: (context, isVisible, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isVisible ? 32 : 0,
              margin: EdgeInsets.only(bottom: isVisible ? 6 : 0),
              child: isVisible
                  ? ListView(
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
                    )
                  : const SizedBox.shrink(),
            );
          },
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
                  SliverFillRemaining(
                    child: Center(child: Text('No content found for this niche.', style: TextStyle(color: AppTheme.textSecondary))),
                  )
                else ...[
                  SliverPadding(
                    // padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 84),
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

    // Group filtered tags by their uppercase starting letter
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tag in filteredTags) {
      final name = tag['name'] as String? ?? '';
      if (name.isEmpty) continue;
      final char = name[0].toUpperCase();
      final key = RegExp(r'^[A-Z]$').hasMatch(char) ? char : '#';
      grouped.putIfAbsent(key, () => []).add(Map<String, dynamic>.from(tag));
    }

    // Sort sections from A to Z, placing '#' at the end
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    // Make sure GlobalKeys exist for each section
    for (var key in sortedKeys) {
      _sectionKeys.putIfAbsent(key, () => GlobalKey());
    }

    return Column(
      children: [
        // Tag search bar
        ValueListenableBuilder<bool>(
          valueListenable: HomeScreen.headerVisibility,
          builder: (context, isVisible, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isVisible ? 48 : 0, // 32 of TextField height + 16 of padding
              margin: EdgeInsets.symmetric(vertical: isVisible ? 8 : 0),
              child: isVisible
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _tagSearchController,
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Filter tags...',
                          hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
                          prefixIcon: Icon(Icons.filter_list, color: AppTheme.textSecondary.withOpacity(0.8)),
                          suffixIcon: _tagSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: AppTheme.textSecondary.withOpacity(0.8)),
                                  onPressed: () => _tagSearchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.cardBg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: AppTheme.primaryNeon),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),

        // A-Z Quick Selector
        ValueListenableBuilder<bool>(
          valueListenable: HomeScreen.headerVisibility,
          builder: (context, isVisible, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isVisible && sortedKeys.isNotEmpty ? 38 : 0,
              margin: EdgeInsets.only(bottom: isVisible && sortedKeys.isNotEmpty ? 8 : 0),
              child: isVisible && sortedKeys.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final key = sortedKeys[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            backgroundColor: AppTheme.cardBg,
                            side: BorderSide(color: AppTheme.borderLight),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            label: Text(
                              key,
                              style: const TextStyle(
                                color: AppTheme.primaryNeon,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () {
                              final targetKey = _sectionKeys[key];
                              if (targetKey != null && targetKey.currentContext != null) {
                                Scrollable.ensureVisible(
                                  targetKey.currentContext!,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            );
          },
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
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No tags match filters.', style: TextStyle(color: AppTheme.textSecondary))),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 84),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedKeys.map((sectionKey) {
                                final sectionTags = grouped[sectionKey] ?? [];

                                return Column(
                                  key: _sectionKeys[sectionKey],
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Alphabet Section Header
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            sectionKey,
                                            style: GoogleFonts.outfit(
                                              color: AppTheme.primaryNeon,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Divider(
                                              color: AppTheme.primaryNeon.withOpacity(0.3),
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Tags Wrap
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: sectionTags.map((tag) {
                                        final name = tag['name'] as String? ?? '';
                                        final count = tag['count'] as int? ?? 0;
                                        return ActionChip(
                                          backgroundColor: AppTheme.cardBg,
                                          side: BorderSide(color: AppTheme.borderLight),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          label: Text(
                                            '#$name ($count)',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary.withOpacity(0.9),
                                              fontSize: 11,
                                            ),
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
                                );
                              }).toList(),
                            ),
                          ),
          ),
        ),
      ],
    );
  }
}
