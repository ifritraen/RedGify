import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Downloads a video from [url] and saves it locally in the user's Downloads directory.
  /// Returns the absolute path of the saved file.
  Future<String> downloadVideo(String url, String id, {Function(double)? onProgress}) async {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception('HTTP Error ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;

    // Resolve downloads directory natively
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {}
    
    // Fallback to Documents directory
    dir ??= await getApplicationDocumentsDirectory();

    final filePath = '${dir.path}/rgify_$id.mp4';
    final file = File(filePath);
    final sink = file.openWrite();

    await for (var chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(receivedBytes / totalBytes);
      }
    }

    await sink.close();
    client.close();
    return filePath;
  }
}
