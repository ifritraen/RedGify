import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/gif_info.dart';
import '../../config/theme.dart';
import '../player/viewer_screen.dart';

class VideoCard extends StatelessWidget {
  final GifInfo gif;

  const VideoCard({super.key, required this.gif});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewerScreen(gif: gif),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster/Thumbnail Image
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
              // User and details info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
