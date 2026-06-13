import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';
import '../../providers/feed_provider.dart';
import '../../providers/selection_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/search_provider.dart';
import '../../services/video_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/playback_settings_provider.dart';
import '../../providers/playback_queue_provider.dart';
import '../widgets/inactivity_monitor.dart';
import '../widgets/playlist_selector_sheet.dart';
import '../widgets/neon_vector_buttons.dart';
import '../creator/creator_profile_screen.dart';
import 'tag_results_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/subscribe_button.dart';
import '../widgets/favorite_category_selector_sheet.dart';


class ReelsPlayerItem extends StatefulWidget {
  final GifInfo gif;
  final bool isActive;
  final VoidCallback? onVideoFinished;

  const ReelsPlayerItem({
    super.key,
    required this.gif,
    required this.isActive,
    this.onVideoFinished,
  });

  @override
  State<ReelsPlayerItem> createState() => _ReelsPlayerItemState();
}

class _ReelsPlayerItemState extends State<ReelsPlayerItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _initError = false;
  // bool _isPlaying = false;
  // bool _showHud = true;
  bool _showHud = false;
  // bool _isDownloading = false;
  // double _downloadProgress = 0.0;
  int _currentPlayCount = 0;
  bool _isCompleted = false;

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

  // Volume control states
  double _volume = 1.0;
  double _dragStartVolume = 1.0;
  bool _isDraggingVolume = false;
  Timer? _volumeOverlayTimer;
  bool _showVolumeOverlay = false;

  // Swipe to seek states
  bool _isDraggingSeek = false;
  Duration _dragStartPos = Duration.zero;
  bool _showSeekOverlay = false;
  Duration? _dragCurrentPos;
  Timer? _seekOverlayTimer;

  @override
  void initState() {
    super.initState();
    // Defer player init to post-frame so DownloadProvider has time to load
    // its persisted completedDownloads before we check for offline files.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
      if (downloadProvider.isLoaded) {
        _initializePlayer();
      } else {
        // Wait for downloads to load, then init
        downloadProvider.addListener(_onDownloadsLoaded);
      }
    });
    
    // Add to history if active
    if (widget.isActive) {
      _addToHistory();
    }
  }

  void _onDownloadsLoaded() {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    if (downloadProvider.isLoaded) {
      downloadProvider.removeListener(_onDownloadsLoaded);
      if (mounted && _controller == null) {
        _initializePlayer();
      }
    }
  }

  bool get _isImg {
    final mediaUrl = widget.gif.urls.hd.isNotEmpty ? widget.gif.urls.hd : widget.gif.urls.sd;
    // Check by extension first
    if (mediaUrl.toLowerCase().endsWith('.jpg') ||
        mediaUrl.toLowerCase().endsWith('.jpeg') ||
        mediaUrl.toLowerCase().endsWith('.png')) {
      return true;
    }
    // duration == 0 is NOT a reliable signal for local files — local video files
    // also have duration 0 before initialization. Only treat as image if extension confirms it.
    return false;
  }

  /// Returns true if the mediaUrl points to a local filesystem path.
  bool _isLocalPath(String mediaUrl) {
    // Android/Linux absolute path
    if (mediaUrl.startsWith('/')) return true;
    // Windows absolute path (e.g. C:\... or C:/...)
    if (mediaUrl.length > 2 && mediaUrl[1] == ':') return true;
    // Not an http/https URL
    if (!mediaUrl.startsWith('http://') && !mediaUrl.startsWith('https://')) return true;
    return false;
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

    if (_isLocalPath(mediaUrl)) {
      // Direct local filesystem path (Local Reels or already-local URL)
      _controller = VideoPlayerController.file(File(mediaUrl));
    } else if (VideoCacheManager.isCached(widget.gif.id)) {
      final cachedPath = VideoCacheManager.getCachedPath(widget.gif.id)!;
      _controller = VideoPlayerController.file(File(cachedPath));
    } else {
      // Check if downloaded locally via DownloadProvider
      final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
      DownloadedItem? downloaded;
      try {
        downloaded = downloadProvider.completedDownloads.firstWhere(
          (x) => x.gif.id == widget.gif.id,
        );
      } catch (_) {
        downloaded = null;
      }

      if (downloaded != null && downloaded.localPath.isNotEmpty && File(downloaded.localPath).existsSync()) {
        _controller = VideoPlayerController.file(File(downloaded.localPath));
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(mediaUrl),
          httpHeaders: const {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://www.redgifs.com/',
          },
        );
      }
    }

    _controller!
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
          _initError = false;
          _durationMs = _controller!.value.duration.inMilliseconds.toDouble();
        });
        _controller!.setLooping(false);
        _controller!.addListener(_onControllerUpdate);
        
        if (widget.isActive) {
          _controller!.play();
          InactivityMonitor.isAnyVideoPlaying = true;
        }
      }).catchError((e) {
        if (!mounted) return;
        setState(() {
          _initError = true;
        });
      });
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    if (!_isUserDraggingSeekBar && value.isInitialized) {
      setState(() {
        _currentPositionMs = value.position.inMilliseconds.toDouble();
        _durationMs = value.duration.inMilliseconds.toDouble();
      });

      if (widget.isActive) {
        InactivityMonitor.isAnyVideoPlaying = value.isPlaying;
        if (value.isPlaying) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }
      }

      if (value.position >= value.duration && !value.isPlaying && !_isCompleted) {
        _isCompleted = true;
        _handleVideoFinished();
      } else if (value.position < value.duration) {
        _isCompleted = false;
      }
    }
  }

  void _disposePlayer() {
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void didUpdateWidget(covariant ReelsPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gif.id != oldWidget.gif.id) {
      _disposePlayer();
      _initialized = false;
      _initError = false;
      _currentPlayCount = 0;
      _isCompleted = false;
      _currentPositionMs = 0.0;
      _durationMs = 1.0;
      if (widget.isActive) {
        _initializePlayer();
        _addToHistory();
      }
    } else if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _currentPlayCount = 0;
        _isCompleted = false;
        _addToHistory();
        if (!_isImg && _controller != null && _initialized) {
          _controller!.play();
          InactivityMonitor.isAnyVideoPlaying = true;
        }
      } else {
        _stopLongPressActions();
        if (!_isImg && _controller != null && _initialized) {
          _controller!.pause();
        }
        WakelockPlus.disable();
      }
    }
  }

  @override
  void dispose() {
    _seekTimer?.cancel();
    _volumeOverlayTimer?.cancel();
    // Remove pending downloads-loaded listener if still registered
    try {
      Provider.of<DownloadProvider>(context, listen: false).removeListener(_onDownloadsLoaded);
    } catch (_) {}
    _disposePlayer();
    if (widget.isActive) {
      InactivityMonitor.isAnyVideoPlaying = false;
      WakelockPlus.disable();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isImg) return;
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        InactivityMonitor.isAnyVideoPlaying = false;
        _playPauseOverlayIcon = Icons.pause;
      } else {
        _controller!.play();
        InactivityMonitor.isAnyVideoPlaying = true;
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

  // Future<void> _startDownload() async {
  //   if (_isDownloading) return;
  //   setState(() {
  //     _isDownloading = true;
  //   });
  // }

  void _showPlaylistSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaylistSelectorSheet(gif: widget.gif),
    );
  }

  void _handleVideoFinished() {
    final settings = Provider.of<PlaybackSettingsProvider>(context, listen: false);
    _currentPlayCount++;

    if (settings.repeatSingle) {
      if (_currentPlayCount < settings.repeatLimit) {
        _replayVideo();
      } else {
        _pauseAndResetCount("Paused after ${settings.repeatLimit} loops");
      }
      return;
    }

    switch (settings.playbackAction) {
      case PlaybackAction.playOnceAndNext:
        if (settings.autoplayNext) {
          _triggerNextVideo();
        } else {
          _pauseAndResetCount(null);
        }
        break;
      case PlaybackAction.repeatXAndNext:
        if (_currentPlayCount < settings.repeatLimit) {
          _replayVideo();
        } else {
          if (settings.autoplayNext) {
            _triggerNextVideo();
          } else {
            _pauseAndResetCount(null);
          }
        }
        break;
      case PlaybackAction.repeatXAndPause:
        if (_currentPlayCount < settings.repeatLimit) {
          _replayVideo();
        } else {
          _pauseAndResetCount("Paused after ${settings.repeatLimit} loops (Sleep Mode)");
        }
        break;
    }
  }

  void _replayVideo() {
    if (_controller == null) return;
    _isCompleted = false;
    _controller!.seekTo(Duration.zero).then((_) {
      if (mounted && widget.isActive) {
        _controller!.play();
      }
    });
  }

  void _pauseAndResetCount(String? message) {
    _currentPlayCount = 0;
    _isCompleted = false;
    if (_controller != null) {
      _controller!.pause();
    }
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryNeon.withAlpha(200),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _triggerNextVideo() {
    _currentPlayCount = 0;
    _isCompleted = false;
    if (widget.onVideoFinished != null) {
      widget.onVideoFinished!();
    }
  }

  Widget _buildHUDIconButton({
    required IconData icon,
    // required String label,
    required bool isActive,
    required Color activeGlowColor,
    required VoidCallback onTap,
  }) {
    final double size = 16;
    final iconColor = isActive ? activeGlowColor : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: size + 12,
        // height: size + 12,
        width: size + 20,
        height: size + 20,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(90),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? activeGlowColor.withAlpha(150) : Colors.white.withAlpha(30), 
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive ? activeGlowColor.withAlpha(80) : Colors.transparent,
              blurRadius: 6,
              spreadRadius: 0.5,
            )
          ],
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: size),
        ),
      ),
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
              onHorizontalDragStart: (details) {
                final screenHeight = MediaQuery.of(context).size.height;
                if (details.localPosition.dy < screenHeight / 2) {
                  _isDraggingVolume = true;
                  _dragStartVolume = _volume;
                } else {
                  _isDraggingSeek = true;
                  if (_controller != null && _initialized) {
                    _dragStartPos = _controller!.value.position;
                    _dragCurrentPos = _dragStartPos;
                  }
                }
              },
              onHorizontalDragUpdate: (details) {
                if (_controller == null || !_initialized) return;
                final screenWidth = MediaQuery.of(context).size.width;
                final delta = details.primaryDelta ?? 0;

                if (_isDraggingVolume) {
                  final change = delta / (screenWidth * 0.5); // swipe half screen width for full 0 to 1 range
                  setState(() {
                    _volume = (_volume + change).clamp(0.0, 1.0);
                    _controller!.setVolume(_volume);
                    _showVolumeOverlay = true;
                  });
                  _volumeOverlayTimer?.cancel();
                  _volumeOverlayTimer = Timer(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        _showVolumeOverlay = false;
                      });
                    }
                  });
                } else if (_isDraggingSeek) {
                  final duration = _controller!.value.duration;
                  // Swipe full screen width to seek 60 seconds (or duration if video is shorter)
                  final maxSeekSec = duration.inSeconds > 60 ? 60.0 : duration.inSeconds.toDouble();
                  final changeMs = (delta / screenWidth) * maxSeekSec * 1000;
                  
                  setState(() {
                    if (_dragCurrentPos != null) {
                      final newMs = _dragCurrentPos!.inMilliseconds + changeMs.toInt();
                      _dragCurrentPos = Duration(
                        milliseconds: newMs.clamp(0, duration.inMilliseconds),
                      );
                      _showSeekOverlay = true;
                    }
                  });

                  _seekOverlayTimer?.cancel();
                  if (_dragCurrentPos != null) {
                    _controller!.seekTo(_dragCurrentPos!);
                  }
                }
              },
              onHorizontalDragEnd: (details) {
                _isDraggingVolume = false;
                if (_isDraggingSeek) {
                  _isDraggingSeek = false;
                  _seekOverlayTimer = Timer(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        _showSeekOverlay = false;
                      });
                    }
                  });
                }
              },
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else if (_initError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image, color: Colors.white30, size: 48),
                  const SizedBox(height: 8),
                  const Text('Failed to load video', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
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

          if (_showVolumeOverlay)
            Center(
              child: _buildVolumeIndicator(),
            ),
          if (_showSeekOverlay)
            Center(
              child: _buildSwipeSeekIndicator(),
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
                      onTap: (widget.gif.userName.isEmpty || widget.gif.userName.toLowerCase() == 'anonymous')
                          ? null
                          : () {
                              if (_controller != null) _controller!.pause();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatorProfileScreen(username: widget.gif.userName),
                                ),
                              );
                            },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
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
                              if (widget.gif.verified) ...[
                                const Icon(Icons.verified, size: 14, color: AppTheme.accentNeon),
                                const SizedBox(width: 6),
                              ],
                              if (widget.gif.userName.isNotEmpty && widget.gif.userName.toLowerCase() != 'anonymous') ...[
                                SubscribeButton(creatorId: widget.gif.userName),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.gif.title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    size: 16,
                    // label: '${widget.gif.likes}',
                    onTap: () => libraryProvider.toggleFavorite(widget.gif),
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => FavoriteCategorySelectorSheet(gif: widget.gif),
                      );
                    },
                  ),
                  // const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  // Playlist
                  NeonVectorIcon(
                    painter: PlaylistPainter(color: Colors.white70),
                    glowColor: AppTheme.secondaryNeon,
                    // size: 26,
                    size: 16,
                    // label: 'Save',
                    onTap: _showPlaylistSelector,
                  ),
                  // const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  // Download
                  Consumer<DownloadProvider>(
                    builder: (context, downloadProvider, child) {
                      final isDownloading = downloadProvider.isDownloading(widget.gif.id);
                      final progress = downloadProvider.getProgress(widget.gif.id);
                      
                      final mediaUrl = widget.gif.urls.hd.isNotEmpty ? widget.gif.urls.hd : widget.gif.urls.sd;
                      final isLocalFile = _isLocalPath(mediaUrl);
                      final isDownloadedLocal = isLocalFile || downloadProvider.completedDownloads.any((x) => x.gif.id == widget.gif.id && File(x.localPath).existsSync());

                      if (isDownloadedLocal) {
                        return NeonVectorIcon(
                          painter: DownloadPainter(color: AppTheme.accentNeon),
                          glowColor: AppTheme.accentNeon,
                          size: 16,
                          // label: 'Saved',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Video is saved locally')),
                            );
                          },
                        );
                      }

                      return isDownloading
                          ? Column(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: progress > 0 ? progress : null,
                                    strokeWidth: 2,
                                    color: AppTheme.primaryNeon,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  progress > 0
                                      ? '${(progress * 100).toStringAsFixed(0)}%'
                                      : '...',
                                  style: const TextStyle(color: Colors.white, fontSize: 8),
                                ),
                              ],
                            )
                          : NeonVectorIcon(
                              painter: DownloadPainter(color: Colors.white70),
                              glowColor: AppTheme.accentNeon,
                              size: 16,
                              // label: 'Get',
                              onTap: () => downloadProvider.startDownload(context, widget.gif),
                            );
                    },
                  ),
                  // const SizedBox(height: 16),
                  const SizedBox(height: 12),
                  // Share
                  NeonVectorIcon(
                    painter: SharePainter(color: Colors.white70),
                    glowColor: Colors.white60,
                    // size: 26,
                    size: 16,
                    // label: 'Share',
                    onTap: () {
                      final shareUrl = widget.gif.urls.html ?? 'https://www.redgifs.com/watch/${widget.gif.id}';
                      Share.share(shareUrl);
                    },
                  ),
                  const SizedBox(height: 12),
                   // Playback Settings Consumer for Shuffle, Repeat, Autoplay, Queue
                  Consumer2<PlaybackSettingsProvider, PlaybackQueueProvider>(
                    builder: (context, playbackSettings, queueProvider, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHUDIconButton(
                            icon: Icons.queue_play_next,
                            // label: 'Queue',
                            isActive: queueProvider.showQueueSidebar,
                            activeGlowColor: AppTheme.primaryNeon,
                            onTap: () => queueProvider.toggleQueueSidebar(),
                          ),
                          const SizedBox(height: 12),
                          _buildHUDIconButton(
                            icon: playbackSettings.shuffleEnabled ? Icons.shuffle : Icons.shuffle_outlined,
                            // label: 'Shuffle',
                            isActive: playbackSettings.shuffleEnabled,
                            activeGlowColor: AppTheme.secondaryNeon,
                            onTap: () => playbackSettings.setShuffleEnabled(!playbackSettings.shuffleEnabled),
                          ),
                          const SizedBox(height: 12),
                          _buildHUDIconButton(
                            icon: playbackSettings.repeatSingle ? Icons.repeat_one : Icons.repeat,
                            // label: 'Repeat',
                            isActive: playbackSettings.repeatSingle,
                            activeGlowColor: AppTheme.primaryNeon,
                            onTap: () => playbackSettings.setRepeatSingle(!playbackSettings.repeatSingle),
                          ),
                          const SizedBox(height: 12),
                          _buildHUDIconButton(
                            icon: playbackSettings.autoplayNext ? Icons.play_arrow : Icons.pause,
                            // label: 'Autoplay',
                            isActive: playbackSettings.autoplayNext,
                            activeGlowColor: AppTheme.accentNeon,
                            onTap: () => playbackSettings.setAutoplayNext(!playbackSettings.autoplayNext),
                          ),
                        ],
                      );
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

  Widget _buildVolumeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryNeon.withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryNeon.withAlpha(50),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _volume == 0
                ? Icons.volume_off
                : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
            color: AppTheme.secondaryNeon,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            'Volume: ${(_volume * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildSwipeSeekIndicator() {
    if (_dragCurrentPos == null || _controller == null) return const SizedBox.shrink();
    final duration = _controller!.value.duration;
    final progress = _dragCurrentPos!;
    final isForward = progress >= _dragStartPos;
    
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
          Icon(
            isForward ? Icons.fast_forward : Icons.fast_rewind,
            color: AppTheme.primaryNeon,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDuration(progress)} / ${_formatDuration(duration)}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
