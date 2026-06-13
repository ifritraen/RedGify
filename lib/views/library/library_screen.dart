import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/library_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../widgets/video_card.dart';
import '../widgets/bulk_action_bar.dart';
import '../widgets/glassy_container.dart';
import '../../providers/download_provider.dart';
import '../creator/creator_profile_screen.dart';
import '../home/home_screen.dart';
import '../../providers/playback_settings_provider.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  void _showCreateCategoryDialog(BuildContext context, LibraryProvider provider) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final hintColor = isDark ? Colors.white38 : AppTheme.textSecondary.withOpacity(0.6);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text('New Favorite Category', style: TextStyle(color: textColor)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Enter category name...',
              hintStyle: TextStyle(color: hintColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryNeon),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final hintColor = isDark ? Colors.white38 : AppTheme.textSecondary.withOpacity(0.6);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text('New Playlist', style: TextStyle(color: textColor)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Enter playlist name...',
              hintStyle: TextStyle(color: hintColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryNeon),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: HomeScreen.headerVisibility,
              builder: (context, isVisible, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isVisible ? 96 : 0,
                  child: isVisible
                      ? Column(
                          children: [
                            Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Text('My Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                                  const Spacer(),
                                  Consumer<PlaybackSettingsProvider>(
                                    builder: (context, settings, child) {
                                      final isOneCol = settings.gridColumns == 1;
                                      return IconButton(
                                        icon: Icon(
                                          isOneCol ? Icons.grid_view : Icons.view_stream,
                                          color: AppTheme.textPrimary,
                                        ),
                                        tooltip: isOneCol ? 'Switch to 2 columns' : 'Switch to 1 column',
                                        onPressed: () => settings.toggleGridColumns(),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.file_upload_outlined, color: AppTheme.textPrimary),
                                    tooltip: 'Import Backup',
                                    onPressed: () => provider.triggerImport(context),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.file_download_outlined, color: AppTheme.textPrimary),
                                    tooltip: 'Export Backup',
                                    onPressed: () => provider.triggerExport(context),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassBg,
                                    border: Border(
                                      bottom: BorderSide(color: AppTheme.border, width: 1.0),
                                    ),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    indicator: const UnderlineTabIndicator(
                                      borderSide: BorderSide(color: AppTheme.primaryNeon, width: 1.5),
                                      insets: EdgeInsets.symmetric(horizontal: 24),
                                    ),
                                    labelColor: AppTheme.textPrimary,
                                    unselectedLabelColor: AppTheme.textSecondary,
                                    labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                                    unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.normal),
                                    tabs: const [
                                      Tab(text: 'Favorites'),
                                      Tab(text: 'Playlists'),
                                      Tab(text: 'History'),
                                      Tab(text: 'Downloads'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
          // Favorites tab
          Builder(
            builder: (context) {
              final List<GifInfo> filteredFavorites;
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
              final subtitleColor = isDark ? Colors.white70 : AppTheme.textSecondary;

              if (_selectedFavoriteCategory == 'All') {
                filteredFavorites = provider.favorites;
              } else {
                final gifIds = provider.favoriteCategoryMappings[_selectedFavoriteCategory] ?? [];
                filteredFavorites = provider.favorites.where((g) => gifIds.contains(g.id)).toList();
              }

              return Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: HomeScreen.headerVisibility,
                    builder: (context, isVisible, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: isVisible ? 50 : 0,
                        margin: EdgeInsets.only(top: isVisible ? 8 : 0, bottom: isVisible ? 4 : 0),
                        child: isVisible
                            ? ListView(
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: _selectedFavoriteCategory == 'All' ? AppTheme.primaryNeon : AppTheme.borderLight,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        color: _selectedFavoriteCategory == 'All' ? Colors.white : AppTheme.textSecondary,
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
                                              title: Text('Delete Category "$cat"?', style: TextStyle(color: textColor)),
                                              content: Text('This will delete the category but keep your favorites.', style: TextStyle(color: subtitleColor)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: isSelected ? AppTheme.primaryNeon : AppTheme.borderLight,
                                            ),
                                          ),
                                          labelStyle: TextStyle(
                                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(color: AppTheme.borderLight),
                                      ),
                                      labelStyle: const TextStyle(
                                        color: AppTheme.primaryNeon,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                  // Grid view of favorites
                  Expanded(
                    child: filteredFavorites.isEmpty
                        ? Center(
                            child: Text(
                              _selectedFavoriteCategory == 'All'
                                  ? 'No favorites added yet.'
                                  : 'No items in this category.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
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
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
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
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 84),
                        itemCount: provider.playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = provider.playlists[index];
                          return GlassyContainer(
                            color: AppTheme.cardBg,
                            borderColor: AppTheme.border,
                            margin: const EdgeInsets.only(bottom: 12),
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
                                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${playlist.items.length} items',
                                style: TextStyle(color: AppTheme.textSecondary),
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
                    style: TextStyle(color: AppTheme.textSecondary),
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
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
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

          // Downloads Tab
          Consumer<DownloadProvider>(
            builder: (context, downloadProvider, child) {
              final active = downloadProvider.activeDownloads;
              final completed = downloadProvider.completedDownloads;

              if (active.isEmpty && completed.isEmpty) {
                return Center(
                  child: Text(
                    'No downloads yet.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'Downloading (${active.length})',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: active.length,
                      itemBuilder: (context, index) {
                        final gifId = active.keys.elementAt(index);
                        final progress = active[gifId] ?? 0.0;
                        return GlassyContainer(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppTheme.cardBg,
                          borderColor: AppTheme.border,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.downloading,
                                  color: AppTheme.primaryNeon,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Video ID: $gifId',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        backgroundColor: Colors.white10,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryNeon),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                progress > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : '...',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  if (completed.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'Finished (${completed.length})',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 0.70,
                        ),
                        itemCount: completed.length,
                        itemBuilder: (context, index) {
                          final completedGifs = completed.map((x) => x.gif).toList();
                          return VideoCard(
                            gif: completedGifs[index],
                            siblings: completedGifs,
                            index: index,
                          );
                        },
                      ),
                    ),
                  ] else
                    const Expanded(
                      child: SizedBox.shrink(),
                    ),
                ],
              );
            },
          ),
                ],
              ),
            ),
        ],
      ),
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
        title: Text(playlist.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Stack(
        children: [
          playlist.items.isEmpty
              ? Center(
                  child: Text(
                    'This playlist is empty.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 84),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Provider.of<PlaybackSettingsProvider>(context).gridColumns,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
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
