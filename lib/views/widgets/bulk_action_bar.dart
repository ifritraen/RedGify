import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/library_provider.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../../services/download_service.dart';

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
        final url = gif.urls.hd.isNotEmpty ? gif.urls.hd : gif.urls.sd;
        await DownloadService().downloadVideo(url, gif.id);
        downloaded++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
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
    showDialog(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Consumer<LibraryProvider>(
            builder: (context, libProvider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // const Padding(
                  //   padding: EdgeInsets.symmetric(vertical: 16),
                  //   child: Text(
                  //     'Select Playlist for Bulk Add',
                  //     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Playlist for Bulk Add',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: AppTheme.primaryNeon),
                          onPressed: () => _showCreatePlaylistDialog(context, libProvider),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Flexible(
                    // child: library.playlists.isEmpty
                    child: libProvider.playlists.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('No playlists found.', style: TextStyle(color: Colors.white60)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            // itemCount: library.playlists.length,
                            itemCount: libProvider.playlists.length,
                            itemBuilder: (context, index) {
                              // final p = library.playlists[index];
                              final p = libProvider.playlists[index];
                              return ListTile(
                                leading: const Icon(Icons.playlist_play, color: AppTheme.primaryNeon),
                                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                                onTap: () async {
                                  Navigator.pop(bottomSheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Adding items to playlist...'), duration: Duration(seconds: 1)),
                                  );
                                  
                                  for (var gif in gifs) {
                                    // await library.addToPlaylist(p.id, gif);
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

    if (!selection.isSelectionMode) return const SizedBox.shrink();

    final selectedGifs = selection.selectedGifs;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Material(
        elevation: 10,
        color: AppTheme.background.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
          ),
          child: _isDownloading
              ? Row(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryNeon, strokeWidth: 3),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _downloadStatus,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => selection.exitSelectionMode(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selection.selectedCount} selected',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                          icon: const Icon(Icons.download, color: Colors.white),
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
      ),
    );
  }
}
