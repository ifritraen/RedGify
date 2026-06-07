import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gif_info.dart';
import '../services/download_service.dart';
import '../services/video_cache_manager.dart';
import '../views/widgets/glassy_toast.dart';

class DownloadedItem {
  final GifInfo gif;
  final String localPath;
  final DateTime downloadedAt;

  DownloadedItem({
    required this.gif,
    required this.localPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'gif': gif.toJson(),
        'localPath': localPath,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadedItem.fromJson(Map<String, dynamic> json) => DownloadedItem(
        gif: GifInfo.fromJson(json['gif']),
        localPath: json['localPath'] ?? '',
        downloadedAt: DateTime.parse(json['downloadedAt'] ?? DateTime.now().toIso8601String()),
      );
}

class DownloadProvider extends ChangeNotifier {
  final Map<String, double> _activeDownloads = {};
  List<DownloadedItem> _completedDownloads = [];
  bool _isLoaded = false;

  Map<String, double> get activeDownloads => _activeDownloads;
  List<DownloadedItem> get completedDownloads => _completedDownloads;
  bool get isLoaded => _isLoaded;

  DownloadProvider() {
    _loadCompletedDownloads();
  }

  bool isDownloading(String id) => _activeDownloads.containsKey(id);
  double getProgress(String id) => _activeDownloads[id] ?? 0.0;

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/downloads.json');
  }

  Future<void> _loadCompletedDownloads() async {
    if (_isLoaded) return;
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List decoded = json.decode(content);
        _completedDownloads = decoded.map((x) => DownloadedItem.fromJson(x)).toList();
        // Sort by downloaded time descending
        _completedDownloads.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      }
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveCompletedDownloads() async {
    try {
      final file = await _localFile;
      final content = json.encode(_completedDownloads.map((x) => x.toJson()).toList());
      await file.writeAsString(content);
    } catch (_) {}
  }

  Future<void> startDownload(BuildContext context, GifInfo gif) async {
    if (isDownloading(gif.id)) return;

    _activeDownloads[gif.id] = 0.0;
    notifyListeners();

    try {
      final String path;
      if (VideoCacheManager.isCached(gif.id)) {
        final cachedPath = VideoCacheManager.getCachedPath(gif.id)!;
        final cachedFile = File(cachedPath);
        
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download/Rgify');
        } else {
          dir = await getDownloadsDirectory();
        }
        if (dir != null && !await dir.exists()) {
          await dir.create(recursive: true);
        }
        dir ??= await getApplicationDocumentsDirectory();
        
        final filename = gif.userName.trim().isNotEmpty
            ? '${gif.userName}_${gif.id}.mp4'
            : 'rgify_${gif.id}.mp4';
        path = '${dir.path}/$filename';
        
        // Copy the file instantly
        await cachedFile.copy(path);
      } else {
        final downloadUrl = gif.urls.hd.isNotEmpty ? gif.urls.hd : gif.urls.sd;
        path = await DownloadService().downloadVideo(
          downloadUrl,
          gif.id,
          creatorName: gif.userName,
          onProgress: (progress) {
            _activeDownloads[gif.id] = progress;
            notifyListeners();
          },
        );
      }

      _activeDownloads.remove(gif.id);
      
      // Add to completed list
      final item = DownloadedItem(
        gif: gif,
        localPath: path,
        downloadedAt: DateTime.now(),
      );
      // Remove any duplicate if already exists
      _completedDownloads.removeWhere((x) => x.gif.id == gif.id);
      _completedDownloads.insert(0, item);
      
      await _saveCompletedDownloads();
      notifyListeners();

      if (context.mounted) {
        GlassyToast.show(context, message: 'Download Successful');
      }
    } catch (e) {
      _activeDownloads.remove(gif.id);
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> removeCompletedDownload(String gifId) async {
    _completedDownloads.removeWhere((item) => item.gif.id == gifId);
    await _saveCompletedDownloads();
    notifyListeners();
  }
}
