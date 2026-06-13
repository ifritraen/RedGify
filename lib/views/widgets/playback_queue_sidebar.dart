import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../../providers/playback_queue_provider.dart';

class PlaybackQueueSidebar extends StatelessWidget {
  final PageController pageController;

  const PlaybackQueueSidebar({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<PlaybackQueueProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width * 0.75;
    final sidebarBg = isDark ? Colors.black.withAlpha(180) : Colors.white.withAlpha(210);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white60 : AppTheme.textSecondary;
    final borderColor = isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20);

    if (!queueProvider.showQueueSidebar) return const SizedBox.shrink();

    return Stack(
      children: [
        // Semi-transparent dismissible backdrop
        GestureDetector(
          onTap: () => queueProvider.setQueueSidebarVisible(false),
          child: Container(
            color: Colors.black45,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Frosted Glass Sidebar aligned to the right
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: width,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: sidebarBg,
                  border: Border(left: BorderSide(color: borderColor, width: 1)),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PLAYBACK QUEUE',
                              style: GoogleFonts.outfit(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: textColor),
                              onPressed: () => queueProvider.setQueueSidebarVisible(false),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                        child: Text(
                          'Hold & drag to reorder • Swipe either side to remove',
                          style: TextStyle(
                            color: subtitleColor.withOpacity(0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      // Reorderable Queue List
                      Expanded(
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: true, // hold and drag to reorder
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: queueProvider.queue.length,
                          onReorder: (oldIndex, newIndex) {
                            queueProvider.reorderVideos(oldIndex, newIndex);
                            // If index shifted, scroll page controller to correct page
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              pageController.jumpToPage(queueProvider.currentIndex);
                            });
                          },
                          itemBuilder: (context, index) {
                            final gif = queueProvider.queue[index];
                            final isActive = queueProvider.currentIndex == index;
                            
                            return _buildQueueItem(
                              key: ValueKey(gif.id + '_' + index.toString()),
                              context: context,
                              gif: gif,
                              index: index,
                              isActive: isActive,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              queueProvider: queueProvider,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem({
    required Key key,
    required BuildContext context,
    required GifInfo gif,
    required int index,
    required bool isActive,
    required Color textColor,
    required Color subtitleColor,
    required PlaybackQueueProvider queueProvider,
  }) {
    final itemBg = isActive ? AppTheme.primaryNeon.withAlpha(35) : Colors.transparent;
    final titleStyle = TextStyle(
      color: isActive ? AppTheme.primaryNeon : textColor,
      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
      fontSize: 13,
    );

    // Commented out the old ListTile implementation for protocol compliance
    /*
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.primaryNeon.withAlpha(80) : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle, color: Colors.white54, size: 20),
              ),
            ),
            const SizedBox(width: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.network(
                  (gif.urls.thumbnail ?? '').isNotEmpty ? gif.urls.thumbnail! : (gif.urls.poster ?? ''),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          '@${gif.userName} - ${gif.id}',
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${gif.duration.toStringAsFixed(1)}s • ${gif.views} views',
          style: TextStyle(color: subtitleColor, fontSize: 11),
        ),
        onTap: () {
          queueProvider.setCurrentIndex(index);
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () {
            queueProvider.removeVideo(index, context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (queueProvider.queue.isNotEmpty) {
                pageController.jumpToPage(queueProvider.currentIndex);
              }
            });
          },
        ),
      ),
    );
    */

    return Dismissible(
      key: key,
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        queueProvider.removeVideo(index, context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (queueProvider.queue.isNotEmpty) {
            pageController.jumpToPage(queueProvider.currentIndex);
          }
        });
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryNeon.withAlpha(80) : Colors.white.withAlpha(15),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              queueProvider.setCurrentIndex(index);
              pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Thumbnail: big and fits the card width perfectly
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        (gif.urls.thumbnail ?? '').isNotEmpty ? gif.urls.thumbnail! : (gif.urls.poster ?? ''),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Text info placed below the thumbnail
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gif.title,
                          style: titleStyle.copyWith(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${gif.duration.toStringAsFixed(1)}s • ${gif.views} views',
                          style: TextStyle(color: subtitleColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
