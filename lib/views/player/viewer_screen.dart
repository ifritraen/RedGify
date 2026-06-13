import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gif_info.dart';
import '../../services/video_cache_manager.dart';
import '../../providers/playback_settings_provider.dart';
import '../../providers/playback_queue_provider.dart';
import 'reels_player_item.dart';
import '../widgets/playback_queue_sidebar.dart';

class ViewerScreen extends StatefulWidget {
  final List<GifInfo> gifs;
  final int initialIndex;

  const ViewerScreen({
    super.key,
    required this.gifs,
    required this.initialIndex,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _pageController;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Initialize active playback queue provider on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlaybackQueueProvider>(context, listen: false)
          .setQueue(widget.gifs, widget.initialIndex);

      if (widget.initialIndex + 1 < widget.gifs.length) {
        VideoCacheManager.preloadVideo(widget.gifs[widget.initialIndex + 1]);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleVideoFinished() {
    final queueProvider = Provider.of<PlaybackQueueProvider>(context, listen: false);
    final gifsList = queueProvider.queue.isNotEmpty ? queueProvider.queue : widget.gifs;
    final activeIndex = queueProvider.queue.isNotEmpty ? queueProvider.currentIndex : _currentPageIndex;
    final settings = Provider.of<PlaybackSettingsProvider>(context, listen: false);
    
    if (!settings.autoplayNext) return;

    int nextIndex = activeIndex + 1;
    if (settings.shuffleEnabled && gifsList.length > 1) {
      final rand = Random();
      do {
        nextIndex = rand.nextInt(gifsList.length);
      } while (nextIndex == activeIndex);
    }

    if (nextIndex < gifsList.length) {
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<PlaybackQueueProvider>(context);
    final gifsList = queueProvider.queue.isNotEmpty ? queueProvider.queue : widget.gifs;
    final activeIndex = queueProvider.queue.isNotEmpty ? queueProvider.currentIndex : _currentPageIndex;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical PageView for Reels Player
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (index) {
              queueProvider.setCurrentIndex(index);
              setState(() {
                _currentPageIndex = index;
              });
              // Preload next video
              if (index + 1 < gifsList.length) {
                VideoCacheManager.preloadVideo(gifsList[index + 1]);
              }
            },
            itemCount: gifsList.length,
            itemBuilder: (context, index) {
              return ReelsPlayerItem(
                gif: gifsList[index],
                isActive: index == activeIndex,
                onVideoFinished: _handleVideoFinished,
              );
            },
          ),

          // Floating Back Button on Top-Left
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Sliding Frosted Glass Playback Queue Sidebar
          PlaybackQueueSidebar(pageController: _pageController),
        ],
      ),
    );
  }
}
