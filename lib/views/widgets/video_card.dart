import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';
import '../../providers/feed_provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/download_provider.dart';
import '../player/viewer_screen.dart';
import '../creator/creator_profile_screen.dart';
import 'playlist_selector_sheet.dart';
import 'glassy_container.dart';

class VideoCard extends StatelessWidget {
  final GifInfo gif;
  final List<GifInfo>? siblings;
  final int? index;

  const VideoCard({
    super.key,
    required this.gif,
    this.siblings,
    this.index,
  });

  void _showCategorySelectionDialog(BuildContext context, LibraryProvider libraryProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white60 : AppTheme.textSecondary;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final categories = libraryProvider.favoriteCategories;
            final gifCategories = libraryProvider.getCategoriesForGif(gif.id);

            return AlertDialog(
              backgroundColor: AppTheme.background,
              title: Text('Manage Categories', style: TextStyle(color: textColor)),
              content: categories.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No categories created yet. Create some in the Favorites tab!',
                        style: TextStyle(color: subtitleColor),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: categories.map((catName) {
                          final belongs = gifCategories.contains(catName);
                          return CheckboxListTile(
                            activeColor: AppTheme.primaryNeon,
                            checkColor: Colors.black,
                            title: Text(catName, style: TextStyle(color: textColor)),
                            value: belongs,
                            onChanged: (val) async {
                              await libraryProvider.toggleGifInFavoriteCategory(catName, gif.id);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done', style: TextStyle(color: AppTheme.primaryNeon)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContextSheet(BuildContext context, SelectionProvider selectionProvider, LibraryProvider libraryProvider) {
    final isFav = libraryProvider.isFavorited(gif.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? Colors.black.withAlpha(200) : Colors.white.withAlpha(235);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final iconColor = isDark ? Colors.white70 : AppTheme.textSecondary;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(color: borderColor),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '@${gif.userName}\'s video',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Divider(color: borderColor, height: 1),
                    ListTile(
                      leading: const Icon(Icons.playlist_add, color: AppTheme.primaryNeon),
                      title: Text('Add to Playlist', style: TextStyle(color: textColor)),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => PlaylistSelectorSheet(gif: gif),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppTheme.primaryNeon : iconColor,
                      ),
                      title: Text(
                        isFav ? 'Remove from Favorites' : 'Add to Favorites',
                        style: TextStyle(color: textColor),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        libraryProvider.toggleFavorite(gif);
                      },
                    ),
                    if (isFav)
                      ListTile(
                        leading: Icon(Icons.category_outlined, color: iconColor),
                        title: Text('Manage Categories', style: TextStyle(color: textColor)),
                        onTap: () {
                          Navigator.pop(context);
                          _showCategorySelectionDialog(context, libraryProvider);
                        },
                      ),
                    ListTile(
                      leading: Icon(Icons.file_download, color: iconColor),
                      title: Text('Download', style: TextStyle(color: textColor)),
                      onTap: () {
                        Navigator.pop(context);
                        Provider.of<DownloadProvider>(context, listen: false).startDownload(context, gif);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.select_all, color: iconColor),
                      title: Text('Select Multiple', style: TextStyle(color: textColor)),
                      onTap: () {
                        Navigator.pop(context);
                        selectionProvider.enterSelectionMode(gif);
                      },
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

  @override
  Widget build(BuildContext context) {
    final selectionProvider = Provider.of<SelectionProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isSelected = selectionProvider.isSelected(gif.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBorderColor = isSelected 
        ? AppTheme.primaryNeon 
        : AppTheme.border;
    final shadowColor = isSelected
        ? AppTheme.primaryNeon.withOpacity(0.2)
        : (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04));

    return GlassyContainer(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardBg,
      borderColor: cardBorderColor,
      borderWidth: isSelected ? 2.0 : 1.0,
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 10,
          spreadRadius: isSelected ? 1.0 : 0.0,
          offset: const Offset(0, 4),
        )
      ],
      child: InkWell(
        onTap: () async {
          if (selectionProvider.isSelectionMode) {
            selectionProvider.toggleSelection(gif);
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewerScreen(
                  gifs: siblings ?? [gif],
                  initialIndex: index ?? 0,
                ),
              ),
            );
            if (context.mounted) {
              Provider.of<FeedProvider>(context, listen: false).filterWatchedGifs();
            }
          }
        },
        onLongPress: () {
          if (selectionProvider.isSelectionMode) {
            selectionProvider.toggleSelection(gif);
          } else {
            _showContextSheet(context, selectionProvider, libraryProvider);
          }
        },
        child: Stack(
          children: [
            // Poster/Thumbnail Image
            AspectRatio(
              aspectRatio: gif.width / (gif.height > 0 ? gif.height : 1),
              child: Image.network(
                gif.urls.poster ?? gif.urls.thumbnail ?? '',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Shimmer.fromColors(
                    baseColor: isDark ? const Color(0xFF1E1A2E) : const Color(0xFFE5E2F0),
                    highlightColor: isDark ? const Color(0xFF2E264D) : const Color(0xFFF3F1FA),
                    child: Container(color: Colors.black),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark ? const Color(0xFF1E1A2E) : const Color(0xFFE5E2F0),
                    child: Center(
                      child: Icon(Icons.broken_image, color: isDark ? Colors.white30 : Colors.black26),
                    ),
                  );
                },
              ),
            ),

            // Bottom overlay with black gradient shadow for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side: Username + Verified status
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (selectionProvider.isSelectionMode) {
                            selectionProvider.toggleSelection(gif);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreatorProfileScreen(username: gif.userName),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                '@${gif.userName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (gif.verified) ...[
                              const SizedBox(width: 2),
                              const Icon(Icons.verified, size: 12, color: AppTheme.accentNeon),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Right side: Views and duration tag
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_red_eye, size: 10, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 2),
                        Text(
                          '${gif.views}',
                          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.8)),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${gif.duration.toStringAsFixed(1)}s',
                            style: const TextStyle(fontSize: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (selectionProvider.isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppTheme.primaryNeon
                        : Colors.white70,
                    size: 26,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
