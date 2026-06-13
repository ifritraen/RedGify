import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/gif_info.dart';

class VideoCacheManager {
  static final Map<String, String> _cacheMap = {};
  static bool _clearedOnStartup = false;

  static bool isCached(String id) => _cacheMap.containsKey(id);
  static String? getCachedPath(String id) => _cacheMap[id];

  static Future<void> clearCacheOnStartup() async {
    if (_clearedOnStartup) return;
    try {
      final cacheDir = await getTemporaryDirectory();
      final dir = Directory('${cacheDir.path}/video_cache');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    _clearedOnStartup = true;
  }

  static Future<String> getCacheFilePath(String id) async {
    final cacheDir = await getTemporaryDirectory();
    final dir = Directory('${cacheDir.path}/video_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '${dir.path}/$id.mp4';
  }

  // Caches a video asynchronously in the background
  static final Set<String> _activePreloads = {};

  static Future<void> preloadVideo(GifInfo gif) async {
    final id = gif.id;
    if (isCached(id) || _activePreloads.contains(id)) return;
    
    // Bypass images
    final mediaUrl = gif.urls.hd.isNotEmpty ? gif.urls.hd : gif.urls.sd;
    if (mediaUrl.isEmpty ||
        mediaUrl.toLowerCase().endsWith('.jpg') ||
        mediaUrl.toLowerCase().endsWith('.jpeg') ||
        mediaUrl.toLowerCase().endsWith('.png') ||
        gif.duration == 0.0) {
      return;
    }

    _activePreloads.add(id);

    try {
      final cachePath = await getCacheFilePath(id);
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(mediaUrl));
      request.headers.addAll({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.redgifs.com/',
      });
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final file = File(cachePath);
        final sink = file.openWrite();
        await for (var chunk in response.stream) {
          sink.add(chunk);
        }
        await sink.close();
        _cacheMap[id] = cachePath;
      }
      client.close();
    } catch (_) {
      // Fail silently for preloads
    } finally {
      _activePreloads.remove(id);
    }
  }
}
