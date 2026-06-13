import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  /// Downloads a video from [url] and saves it locally in the user's Downloads directory.
  /// Returns the absolute path of the saved file.
  Future<String> downloadVideo(String url, String filename, {Function(double)? onProgress}) async {
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
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download/Rgify');
      } else {
        // dir = await getDownloadsDirectory();
        dir = await getDownloadsDirectory();
      }
    } catch (_) {}
    
    if (dir != null) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (e) {
        dir = null;
      }
    }
    
    // Fallback to Documents directory
    // dir ??= await getApplicationDocumentsDirectory();
    dir ??= await getApplicationDocumentsDirectory();

    final filePath = '${dir.path}/$filename';
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
