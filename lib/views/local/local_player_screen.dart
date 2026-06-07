import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../providers/local_player_provider.dart';
import '../../models/gif_info.dart';
import '../player/viewer_screen.dart';
import '../widgets/glassy_container.dart';

class LocalPlayerScreen extends StatelessWidget {
  const LocalPlayerScreen({super.key});

  List<GifInfo> _convertToGifInfos(List<FileSystemEntity> files) {
    return files.map((file) {
      return GifInfo(
        id: file.path,
        // Use -1.0 as sentinel so _isImg (which checks duration==0.0) does NOT
        // misidentify local video files as static images. The actual duration
        // will be read from the video controller after initialization.
        duration: -1.0,
        width: 0,
        height: 0,
        views: 0,
        likes: 0,
        tags: [],
        urls: GifUrls(
          hd: file.path,
          sd: file.path,
        ),
        userName: 'Local Video',
        verified: false,
      );
    }).toList();
  }

  void _playAll(BuildContext context, List<FileSystemEntity> files, int startIndex) {
    if (files.isEmpty) return;
    final gifs = _convertToGifInfos(files);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewerScreen(
          gifs: gifs,
          initialIndex: startIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocalPlayerProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !provider.canNavigateBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        provider.navigateBack();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Local Reels',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: provider.canNavigateBack
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => provider.navigateBack(),
              )
            : null,
        actions: [
          if (provider.rootPath != null)
            IconButton(
              icon: const Icon(Icons.folder_off, color: Colors.redAccent),
              tooltip: 'Change root directory',
              onPressed: () => provider.clearStorageRoot(),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : provider.rootPath == null
              ? _buildSetupView(context)
              : provider.scanError != null
                  ? _buildErrorView(context, provider.scanError!)
                  : _buildFolderExplorer(context, provider, isDark),
      floatingActionButton: provider.rootPath != null && provider.videoFiles.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryNeon,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                'Play All Folder',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              elevation: 8,
              onPressed: () => _playAll(context, provider.videoFiles, 0),
            )
          : null,
      ),
    );
  }

  Widget _buildSetupView(BuildContext context) {
    final provider = Provider.of<LocalPlayerProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: GlassyContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(32),
          color: AppTheme.cardBg,
          borderColor: AppTheme.border,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.folder_special,
                  size: 40,
                  color: AppTheme.primaryNeon,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Local Reels Player',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a main storage directory. You can organize files inside nested sub-folders and play them sequentially in the reels viewer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => provider.selectStorageRoot(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryNeon, AppTheme.secondaryNeon],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Select Main Folder',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    final provider = Provider.of<LocalPlayerProvider>(context, listen: false);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 52, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => provider.selectStorageRoot(),
              icon: const Icon(Icons.folder_open, size: 18),
              label: Text('Re-select Folder', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => provider.clearStorageRoot(),
              child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderExplorer(BuildContext context, LocalPlayerProvider provider, bool isDark) {
    // Relative path to display in header
    String relativePath = '';
    if (provider.currentPath != null && provider.rootPath != null) {
      if (provider.currentPath == provider.rootPath) {
        relativePath = 'Main Storage';
      } else {
        relativePath = p.basename(provider.currentPath!);
      }
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Path Breadcrumb Header Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.secondaryNeon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      relativePath,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Subfolders Header
        if (provider.subFolders.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 16, top: 16, bottom: 8),
              child: Text(
                'Folders',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

        // Subfolders Grid List
        if (provider.subFolders.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final dir = provider.subFolders[index];
                  final folderName = p.basename(dir.path);
                  return GestureDetector(
                    onTap: () => provider.navigateTo(dir.path),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder, size: 28, color: AppTheme.primaryNeon),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              folderName,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: provider.subFolders.length,
              ),
            ),
          ),

        // Video Files Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 16, top: 24, bottom: 12),
            child: Text(
              provider.videoFiles.isEmpty ? 'No Videos in this Folder' : 'Videos',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),

        // Video Files Grid Layout
        if (provider.videoFiles.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final file = provider.videoFiles[index];
                  final name = p.basename(file.path);
                  final fileStat = file.statSync();
                  final sizeMb = fileStat.size / (1024 * 1024);

                  return GestureDetector(
                    onTap: () => _playAll(context, provider.videoFiles, index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Fallback Thumbnail visual
                            Container(
                              color: isDark ? const Color(0xFF1E1A2E) : const Color(0xFFE5E2F0),
                              child: Center(
                                child: Icon(
                                  Icons.video_library_outlined,
                                  size: 40,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                ),
                              ),
                            ),
                            // Black overlay at the bottom for readability
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.85),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${sizeMb.toStringAsFixed(1)} MB',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: provider.videoFiles.length,
              ),
            ),
          ),
      ],
    );
  }
}
