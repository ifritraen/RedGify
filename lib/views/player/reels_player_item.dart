import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';
import '../../providers/library_provider.dart';
import '../../providers/search_provider.dart';
import '../../services/download_service.dart';
import '../widgets/playlist_selector_sheet.dart';
import '../widgets/neon_vector_buttons.dart';
import '../creator/creator_profile_screen.dart';
import 'tag_results_screen.dart';

class ReelsPlayerItem extends StatefulWidget {
  final GifInfo gif;
  final bool isActive;

  const ReelsPlayerItem({
    super.key,
    required this.gif,
    required this.isActive,
  });

  @override
  State<ReelsPlayerItem> createState() => _ReelsPlayerItemState();
}

class _ReelsPlayerItemState extends State<ReelsPlayerItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  // bool _isPlaying = false;
  // bool _showHud = true;
  bool _showHud = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Custom seeking / speed states
  Timer? _seekTimer;
  bool _isSeekingForward = false;
  bool _isSeekingBackward = false;
  bool _isSpeedPlaying = false;

  // Double tap play/pause animation overlay
  bool _showPlayPauseOverlay = false;
  IconData _playPauseOverlayIcon = Icons.play_arrow;

  // Seekbar values
  bool _isUserDraggingSeekBar = false;
  double _currentPositionMs = 0.0;
  double _durationMs = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    
    // Add to history if active
    if (widget.isActive) {
      _addToHistory();
    }
  }

  bool get _isImg {
    final mediaUrl = widget.gif.urls.hd.isNotEmpty ? widget.gif.urls.hd : widget.gif.urls.sd;
    return mediaUrl.toLowerCase().endsWith('.jpg') ||
        mediaUrl.toLowerCase().endsWith('.jpeg') ||
        mediaUrl.toLowerCase().endsWith('.png') ||
        widget.gif.duration == 0.0;
  }

  void _addToHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LibraryProvider>(context, listen: false).addToHistory(widget.gif);
      }
    });
  }

  void _initializePlayer() {
    if (_isImg) {
      setState(() {
        _initialized = true;
      });
      return;
    }
    final mediaUrl = widget.gif.urls.hd.isNotEmpty ? widget.gif.urls.hd : widget.gif.urls.sd;
    _controller = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
          _durationMs = _controller!.value.duration.inMilliseconds.toDouble();
        });
        _controller!.setLooping(true);
        _controller!.addListener(_onControllerUpdate);
        
        if (widget.isActive) {
          _controller!.play();
          setState(() {
          // _isPlaying = true;
          });
        }
      });
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;
    if (!_isUserDraggingSeekBar && _controller!.value.isInitialized) {
      setState(() {
        _currentPositionMs = _controller!.value.position.inMilliseconds.toDouble();
        _durationMs = _controller!.value.duration.inMilliseconds.toDouble();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReelsPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _addToHistory();
        if (!_isImg && _controller != null && _initialized) {
          _controller!.play();
          setState(() {
            // _isPlaying = true;
          });
        }
      } else {
        _stopLongPressActions();
        if (!_isImg && _controller != null && _initialized) {
          _controller!.pause();
          setState(() {
            // _isPlaying = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _seekTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isImg) return;
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        // _isPlaying = false;
        _playPauseOverlayIcon = Icons.pause;
      } else {
        _controller!.play();
        // _isPlaying = true;
        _playPauseOverlayIcon = Icons.play_arrow;
      }
      _showPlayPauseOverlay = true;
    });

    Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showPlayPauseOverlay = false;
        });
      }
    });
  }

  void _toggleHud() {
    setState(() {
      _showHud = !_showHud;
    });
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (_controller == null || !_initialized) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final x = details.localPosition.dx;

    if (x < screenWidth * 0.33) {
      setState(() {
        _isSeekingBackward = true;
      });
      _startSeeking(forward: false);
    } else if (x > screenWidth * 0.66) {
      setState(() {
        _isSeekingForward = true;
      });
      _startSeeking(forward: true);
    } else {
      setState(() {
        _isSpeedPlaying = true;
      });
      _controller!.setPlaybackSpeed(2.0);
    }
  }

  void _startSeeking({required bool forward}) {
    _seekTimer?.cancel();
    _seekTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_controller == null || !_initialized) return;
      final currentPosition = _controller!.value.position;
      final duration = _controller!.value.duration;
      if (forward) {
        final newPos = currentPosition + const Duration(seconds: 1);
        _controller!.seekTo(newPos > duration ? duration : newPos);
      } else {
        final newPos = currentPosition - const Duration(seconds: 1);
        _controller!.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
      }
    });
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _stopLongPressActions();
  }

  void _stopLongPressActions() {
    _seekTimer?.cancel();
    _seekTimer = null;
    if (_controller != null && _initialized && _isSpeedPlaying) {
      _controller!.setPlaybackSpeed(1.0);
    }
    if (mounted) {
      setState(() {
        _isSeekingForward = false;
        _isSeekingBackward = false;
        _isSpeedPlaying = false;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final downloadUrl = widget.gif.urls.hd.isNotEmpty ? widget.gif.urls.hd : widget.gif.urls.sd;
      final path = await DownloadService().downloadVideo(
        downloadUrl,
        widget.gif.id,
        onProgress: (p) {
          setState(() {
            _downloadProgress = p;
          });
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded successfully to: $path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _showPlaylistSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaylistSelectorSheet(gif: widget.gif),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isFav = libraryProvider.isFavorited(widget.gif.id);

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Fullscreen Video Player with gestured center overlays
          if (_isImg)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleHud,
              onDoubleTap: _togglePlayPause,
              child: Center(
                child: Image.network(
                  widget.gif.urls.hd.isNotEmpty ? widget.gif.urls.hd : widget.gif.urls.sd,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white30, size: 64),
                  ),
                ),
              ),
            )
          else if (_controller != null && _initialized)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleHud,
              onDoubleTap: _togglePlayPause,
              onLongPressStart: _handleLongPressStart,
              onLongPressEnd: _handleLongPressEnd,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            ),

          // 2. Continuous Seek Overlay Indicators
          if (_isSeekingBackward)
            Positioned(
              left: 40,
              child: _buildSeekIndicator(icon: Icons.fast_rewind, label: 'Rewinding'),
            ),
          if (_isSeekingForward)
            Positioned(
              right: 40,
              child: _buildSeekIndicator(icon: Icons.fast_forward, label: 'Forwarding'),
            ),
          if (_isSpeedPlaying)
            Center(
              child: _buildSeekIndicator(icon: Icons.play_arrow_outlined, label: '2X Speed >>'),
            ),

          // 3. Double-tap Play/Pause Animation Overlay
          if (_showPlayPauseOverlay)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showPlayPauseOverlay ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(_playPauseOverlayIcon, size: 64, color: AppTheme.primaryNeon),
              ),
            ),

          // 4. Immersive dark gradient layer for readable details
          if (_showHud)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),

          // 5. Left-side Details Overlay (Title, User, Tags)
          if (_showHud)
            Positioned(
              bottom: 45,
              left: 12,
              right: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(130),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_controller != null) _controller!.pause();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatorProfileScreen(username: widget.gif.userName),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '@${widget.gif.userName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (widget.gif.verified)
                            const Icon(Icons.verified, size: 14, color: AppTheme.accentNeon),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tags
                    if (widget.gif.tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.gif.tags.take(3).map((tag) {
                          return GestureDetector(
                            onTap: () {
                              if (_controller != null) _controller!.pause();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChangeNotifierProvider(
                                    create: (_) => SearchProvider()..performSearch(tag),
                                    child: TagResultsScreen(tag: tag),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withAlpha(25)),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

          // 6. Right-side Columns of Neon Interaction Buttons
          if (_showHud)
            Positioned(
              bottom: 80,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorite
                  NeonVectorIcon(
                    painter: HeartPainter(filled: isFav, color: isFav ? AppTheme.primaryNeon : Colors.white70),
                    glowColor: AppTheme.primaryNeon,
                    // size: 26,
                    size: 20,
                    label: '${widget.gif.likes}',
                    onTap: () => libraryProvider.toggleFavorite(widget.gif),
                  ),
                  // const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  // Playlist
                  NeonVectorIcon(
                    painter: PlaylistPainter(color: Colors.white70),
                    glowColor: AppTheme.secondaryNeon,
                    // size: 26,
                    size: 20,
                    label: 'Save',
                    onTap: _showPlaylistSelector,
                  ),
                  // const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  // Download
                  _isDownloading
                      ? Column(
                          children: [
                            SizedBox(
                              // width: 32,
                              // height: 32,
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                value: _downloadProgress > 0 ? _downloadProgress : null,
                                strokeWidth: 2,
                                color: AppTheme.primaryNeon,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _downloadProgress > 0
                                  ? '${(_downloadProgress * 100).toStringAsFixed(0)}%'
                                  : '...',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ],
                        )
                      : NeonVectorIcon(
                          painter: DownloadPainter(color: Colors.white70),
                          glowColor: AppTheme.accentNeon,
                          // size: 26,
                          size: 20,
                          label: 'Get',
                          onTap: _startDownload,
                        ),
                  // const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  // Share
                  NeonVectorIcon(
                    painter: SharePainter(color: Colors.white70),
                    glowColor: Colors.white60,
                    // size: 26,
                    size: 20,
                    label: 'Share',
                    onTap: () {
                      // Custom copy link/share action
                    },
                  ),
                ],
              ),
            ),

          // 7. Bottom scrubbable Seekbar
          if (_showHud && !_isImg)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Text(
                    _formatDuration(Duration(milliseconds: _currentPositionMs.toInt())),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryNeon,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppTheme.primaryNeon,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      ),
                      child: Slider(
                        value: _currentPositionMs.clamp(0.0, _durationMs),
                        min: 0.0,
                        max: _durationMs,
                        onChanged: (value) {
                          // setState(() {
                          //   _isUserDraggingSeekBar = true;
                          //   _currentPositionMs = value;
                          // });
                          setState(() {
                            _isUserDraggingSeekBar = true;
                            _currentPositionMs = value;
                          });
                          if (_controller != null) {
                            _controller!.seekTo(Duration(milliseconds: value.toInt()));
                          }
                        },
                        onChangeEnd: (value) {
                          if (_controller != null) {
                            _controller!.seekTo(Duration(milliseconds: value.toInt())).then((_) {
                              setState(() {
                                _isUserDraggingSeekBar = false;
                              });
                            });
                          } else {
                            setState(() {
                              _isUserDraggingSeekBar = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(Duration(milliseconds: _durationMs.toInt())),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeekIndicator({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryNeon.withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withAlpha(50),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryNeon, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
