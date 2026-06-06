import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';

class ViewerScreen extends StatefulWidget {
  final GifInfo gif;

  const ViewerScreen({super.key, required this.gif});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // Resolve direct media file endpoint (HD preferred, falling back to SD)
    final mediaUrl = widget.gif.urls.hd.isNotEmpty ? widget.gif.urls.hd : widget.gif.urls.sd;
    _controller = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Fullscreen Video Player
          if (_initialized)
            GestureDetector(
              onTap: _togglePlay,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            ),

          // Play/Pause Overlay indicator
          if (!_isPlaying)
            const IgnorePointer(
              child: Icon(Icons.play_arrow, size: 80, color: Colors.white60),
            ),

          // Back Button & UI Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Immersive details overlay
          Positioned(
            bottom: 40,
            left: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '@${widget.gif.userName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.gif.verified)
                      const Icon(Icons.verified, size: 16, color: AppTheme.accentNeon),
                  ],
                ),
                const SizedBox(height: 8),
                // Tags
                if (widget.gif.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.gif.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Right-side interactions (likes, views)
          Positioned(
            bottom: 60,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InteractionButton(
                  icon: Icons.favorite,
                  label: '${widget.gif.likes}',
                  color: AppTheme.primaryNeon,
                ),
                const SizedBox(height: 20),
                _InteractionButton(
                  icon: Icons.remove_red_eye,
                  label: '${widget.gif.views}',
                  color: Colors.white70,
                ),
                const SizedBox(height: 20),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 30),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
