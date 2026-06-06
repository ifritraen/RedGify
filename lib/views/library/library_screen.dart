import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../widgets/video_card.dart';
import '../widgets/bulk_action_bar.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFavoriteCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _showCreateCategoryDialog(BuildContext context, LibraryProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text('New Favorite Category', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter category name...',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withAlpha(50)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryNeon),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  provider.createFavoriteCategory(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create', style: TextStyle(color: AppTheme.primaryNeon)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter playlist name...',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withAlpha(50)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryNeon),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Provider.of<LibraryProvider>(context, listen: false).createPlaylist(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create', style: TextStyle(color: AppTheme.primaryNeon)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LibraryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
            tooltip: 'Import Backup',
            onPressed: () => provider.triggerImport(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            tooltip: 'Export Backup',
            onPressed: () => provider.triggerExport(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryNeon,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Favorites'),
              Tab(text: 'Playlists'),
              Tab(text: 'History'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Favorites tab
          Builder(
            builder: (context) {
              final List<GifInfo> filteredFavorites;
              if (_selectedFavoriteCategory == 'All') {
                filteredFavorites = provider.favorites;
              } else {
                final gifIds = provider.favoriteCategoryMappings[_selectedFavoriteCategory] ?? [];
                filteredFavorites = provider.favorites.where((g) => gifIds.contains(g.id)).toList();
              }

              return Column(
                children: [
                  // Categories filter bar
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedFavoriteCategory == 'All',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFavoriteCategory = 'All';
                                });
                              }
                            },
                            backgroundColor: AppTheme.cardBg,
                            selectedColor: AppTheme.primaryNeon,
                            labelStyle: TextStyle(
                              color: _selectedFavoriteCategory == 'All' ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Custom categories
                        ...provider.favoriteCategories.map((cat) {
                          final isSelected = _selectedFavoriteCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppTheme.background,
                                    title: Text('Delete Category "$cat"?'),
                                    content: const Text('This will delete the category but keep your favorites.', style: TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          provider.deleteFavoriteCategory(cat);
                                          if (_selectedFavoriteCategory == cat) {
                                            setState(() {
                                              _selectedFavoriteCategory = 'All';
                                            });
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedFavoriteCategory = cat;
                                    });
                                  }
                                },
                                backgroundColor: AppTheme.cardBg,
                                selectedColor: AppTheme.primaryNeon,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                        // Add category chip button
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InputChip(
                            label: const Text('+ Add Category'),
                            onPressed: () => _showCreateCategoryDialog(context, provider),
                            backgroundColor: AppTheme.cardBg,
                            labelStyle: const TextStyle(
                              color: AppTheme.primaryNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Grid view of favorites
                  Expanded(
                    child: filteredFavorites.isEmpty
                        ? Center(
                            child: Text(
                              _selectedFavoriteCategory == 'All'
                                  ? 'No favorites added yet.'
                                  : 'No items in this category.',
                              style: TextStyle(color: Colors.white.withAlpha(100)),
                            ),
                          )
                        : GridView.builder(
                            // padding: const EdgeInsets.all(16),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 0,
                              childAspectRatio: 0.70,
                            ),
                            itemCount: filteredFavorites.length,
                            itemBuilder: (context, index) {
                              return VideoCard(
                                gif: filteredFavorites[index],
                                siblings: filteredFavorites,
                                index: index,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),

          // Playlists tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Playlists (${provider.playlists.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNeon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _showCreatePlaylistDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.playlists.isEmpty
                    ? Center(
                        child: Text(
                          'No playlists created yet.',
                          style: TextStyle(color: Colors.white.withAlpha(100)),
                        ),
                      )
                    : ListView.builder(
                        // padding: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 84),
                        itemCount: provider.playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = provider.playlists[index];
                          return Card(
                            color: AppTheme.cardBg,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withAlpha(15)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.playlist_play, color: AppTheme.primaryNeon),
                              ),
                              title: Text(
                                playlist.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${playlist.items.length} items',
                                style: TextStyle(color: Colors.white.withAlpha(120)),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => provider.deletePlaylist(playlist.id),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaylistDetailScreen(playlist: playlist),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // History Tab
          provider.history.isEmpty
              ? Center(
                  child: Text(
                    'No local history recorded.',
                    style: TextStyle(color: Colors.white.withAlpha(100)),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recently Viewed (${provider.history.length})',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                            onPressed: () => provider.clearHistory(),
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear History'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        // padding: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 0,
                          childAspectRatio: 0.70,
                        ),
                        itemCount: provider.history.length,
                        itemBuilder: (context, index) {
                          return VideoCard(
                            gif: provider.history[index],
                            siblings: provider.history,
                            index: index,
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// Sub-screen to view videos inside a playlist
class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          playlist.items.isEmpty
              ? Center(
                  child: Text(
                    'This playlist is empty.',
                    style: TextStyle(color: Colors.white.withAlpha(100)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 0,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: playlist.items.length,
                  itemBuilder: (context, index) {
                    return VideoCard(
                      gif: playlist.items[index],
                      siblings: playlist.items,
                      index: index,
                    );
                  },
                ),
          const BulkActionBar(),
        ],
      ),
    );
  }
}
