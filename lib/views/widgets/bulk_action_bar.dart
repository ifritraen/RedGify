import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/library_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../../providers/download_provider.dart';
import 'glassy_container.dart';

class BulkActionBar extends StatefulWidget {
  const BulkActionBar({super.key});

  @override
  State<BulkActionBar> createState() => _BulkActionBarState();
}

class _BulkActionBarState extends State<BulkActionBar> {
  bool _isDownloading = false;
  String _downloadStatus = '';

  Future<void> _bulkDownload(BuildContext context, List<GifInfo> gifs, SelectionProvider selection) async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = 'Starting download queue...';
    });

    int downloaded = 0;
    int failed = 0;

    for (int i = 0; i < gifs.length; i++) {
      if (!mounted) break;
      final gif = gifs[i];
      setState(() {
        _downloadStatus = 'Downloading ${i + 1}/${gifs.length}...';
      });

      try {
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
        await downloadProvider.startDownload(context, gif);
        final isCompleted = downloadProvider.completedDownloads.any((item) => item.gif.id == gif.id);
        if (isCompleted) {
          downloaded++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }

    if (context.mounted) {
      setState(() {
        _isDownloading = false;
        _downloadStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bulk download complete. Saved: $downloaded. Failed: $failed.'),
          backgroundColor: failed > 0 ? Colors.orangeAccent : Colors.green,
        ),
      );
      selection.exitSelectionMode();
    }
  }

  void _showCreatePlaylistDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final hintColor = isDark ? Colors.white38 : AppTheme.textSecondary.withOpacity(0.6);

    showDialog(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  library.createPlaylist(name);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Create', style: TextStyle(color: AppTheme.primaryNeon)),
            ),
          ],
        );
      },
    );
  }

  void _bulkAddToPlaylist(BuildContext context, List<GifInfo> gifs, LibraryProvider library, SelectionProvider selection) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? Colors.black.withAlpha(200) : Colors.white.withAlpha(235);
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white60 : AppTheme.textSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
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
                child: Consumer<LibraryProvider>(
                  builder: (context, libProvider, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Playlist for Bulk Add',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: AppTheme.primaryNeon),
                                onPressed: () => _showCreatePlaylistDialog(context, libProvider),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: borderColor, height: 1),
                        Flexible(
                          child: libProvider.playlists.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text('No playlists found.', style: TextStyle(color: subtitleColor)),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: libProvider.playlists.length,
                                  itemBuilder: (context, index) {
                                    final p = libProvider.playlists[index];
                                    return ListTile(
                                      leading: const Icon(Icons.playlist_play, color: AppTheme.primaryNeon),
                                      title: Text(p.name, style: TextStyle(color: textColor)),
                                      onTap: () async {
                                        Navigator.pop(bottomSheetContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Adding items to playlist...'), duration: Duration(seconds: 1)),
                                        );
                                        
                                        for (var gif in gifs) {
                                          await libProvider.addToPlaylist(p.id, gif);
                                        }
                                        
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Successfully added ${gifs.length} items to ${p.name}!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                        selection.exitSelectionMode();
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _bulkFavorite(BuildContext context, List<GifInfo> gifs, LibraryProvider library, SelectionProvider selection) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toggling favorites...'), duration: Duration(seconds: 1)),
    );
    for (var gif in gifs) {
      await library.toggleFavorite(gif);
    }
    selection.exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final selection = Provider.of<SelectionProvider>(context);
    final library = Provider.of<LibraryProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final iconColor = isDark ? Colors.white70 : AppTheme.textSecondary;

    if (!selection.isSelectionMode) return const SizedBox.shrink();

    final selectedGifs = selection.selectedGifs;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      height: 62,
      child: GlassyContainer(
        borderRadius: 31,
        color: AppTheme.glassBg,
        borderColor: AppTheme.primaryNeon.withOpacity(0.3),
        borderWidth: 1.0,
        boxShadow: AppTheme.cardGlow,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: _isDownloading
            ? Row(
                children: [
                  const SizedBox(width: 8),
                  const CircularProgressIndicator(color: AppTheme.primaryNeon, strokeWidth: 3),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _downloadStatus,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: iconColor),
                        onPressed: () => selection.exitSelectionMode(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${selection.selectedCount} selected',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.playlist_add, color: AppTheme.primaryNeon),
                        tooltip: 'Add all to Playlist',
                        onPressed: selectedGifs.isEmpty
                            ? null
                            : () => _bulkAddToPlaylist(context, selectedGifs, library, selection),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: AppTheme.primaryNeon),
                        tooltip: 'Toggle Favorites',
                        onPressed: selectedGifs.isEmpty
                            ? null
                            : () => _bulkFavorite(context, selectedGifs, library, selection),
                      ),
                      IconButton(
                        icon: Icon(Icons.download, color: isDark ? Colors.white : AppTheme.textPrimaryLight),
                        tooltip: 'Download All',
                        onPressed: selectedGifs.isEmpty
                            ? null
                            : () => _bulkDownload(context, selectedGifs, selection),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
