import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';

class PlaylistSelectorSheet extends StatefulWidget {
  final GifInfo gif;

  const PlaylistSelectorSheet({super.key, required this.gif});

  @override
  State<PlaylistSelectorSheet> createState() => _PlaylistSelectorSheetState();
}

class _PlaylistSelectorSheetState extends State<PlaylistSelectorSheet> {
  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text('New Playlist', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: _playlistNameController,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter playlist name...',
              hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
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
                final name = _playlistNameController.text.trim();
                if (name.isNotEmpty) {
                  Provider.of<LibraryProvider>(context, listen: false).createPlaylist(name);
                  _playlistNameController.clear();
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Save to Playlist',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryNeon),
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No playlists created yet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = provider.playlists[index];
                  final containsGif = playlist.items.any((g) => g.id == widget.gif.id);

                  return ListTile(
                    leading: Icon(
                      containsGif ? Icons.playlist_add_check : Icons.playlist_play,
                      color: containsGif ? AppTheme.primaryNeon : AppTheme.textSecondary,
                    ),
                    title: Text(
                      playlist.name,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      '${playlist.items.length} items',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: containsGif
                        ? const Icon(Icons.check, color: AppTheme.primaryNeon)
                        : null,
                    onTap: () {
                      if (!containsGif) {
                        provider.addToPlaylist(playlist.id, widget.gif);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${playlist.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        provider.removeFromPlaylist(playlist.id, widget.gif.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed from ${playlist.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
