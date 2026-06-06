import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';
import '../../providers/feed_provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/library_provider.dart';
import '../../services/download_service.dart';
import '../player/viewer_screen.dart';
import '../creator/creator_profile_screen.dart';
import 'playlist_selector_sheet.dart';

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

  void _showContextSheet(BuildContext context, SelectionProvider selectionProvider, LibraryProvider libraryProvider) {
    final isFav = libraryProvider.isFavorited(gif.id);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '@${gif.userName}\'s video',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: AppTheme.primaryNeon),
                title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
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
                  color: isFav ? AppTheme.primaryNeon : Colors.white70,
                ),
                title: Text(
                  isFav ? 'Remove from Favorites' : 'Add to Favorites',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  libraryProvider.toggleFavorite(gif);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download, color: Colors.white70),
                title: const Text('Download', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting download...'), duration: Duration(seconds: 2)),
                  );
                  try {
                    final downloadUrl = gif.urls.hd.isNotEmpty ? gif.urls.hd : gif.urls.sd;
                    final path = await DownloadService().downloadVideo(downloadUrl, gif.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved to: $path'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.select_all, color: Colors.white70),
                title: const Text('Select Multiple', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  selectionProvider.enterSelectionMode(gif);
                },
              ),
            ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? AppTheme.primaryNeon 
              : Colors.white.withAlpha(20),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster/Thumbnail Image
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: gif.width / (gif.height > 0 ? gif.height : 1),
                    child: Image.network(
                      gif.urls.poster ?? gif.urls.thumbnail ?? '',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: const Color(0xFF1E1A2E),
                          highlightColor: const Color(0xFF2E264D),
                          child: Container(color: Colors.black),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1E1A2E),
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.white30),
                          ),
                        );
                      },
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
              // User and details info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
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
                        children: [
                          Expanded(
                            child: Text(
                              '@${gif.userName}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withAlpha(229),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (gif.verified)
                            const Icon(Icons.verified, size: 14, color: AppTheme.accentNeon),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Video duration tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${gif.duration.toStringAsFixed(1)}s',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                        // Views tag
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye, size: 12, color: Colors.white38),
                            const SizedBox(width: 3),
                            Text(
                              '${gif.views}',
                              style: const TextStyle(fontSize: 10, color: Colors.white54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
