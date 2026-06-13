class GifUrls {
  final String? silent;
  final String? html;
  final String? poster;
  final String? thumbnail;
  final String hd;
  final String sd;

  GifUrls({
    this.silent,
    this.html,
    this.poster,
    this.thumbnail,
    required this.hd,
    required this.sd,
  });

  factory GifUrls.fromJson(Map<String, dynamic> json) {
    return GifUrls(
      silent: json['silent'],
      html: json['html'],
      poster: json['poster'],
      thumbnail: json['thumbnail'],
      hd: json['hd'] ?? '',
      sd: json['sd'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'silent': silent,
      'html': html,
      'poster': poster,
      'thumbnail': thumbnail,
      'hd': hd,
      'sd': sd,
    };
  }
}

class GifInfo {
  final String id;
  final double duration;
  final int width;
  final int height;
  final int views;
  final int likes;
  final List<String> tags;
  final GifUrls urls;
  final String userName;
  final bool verified;

  GifInfo({
    required this.id,
    required this.duration,
    required this.width,
    required this.height,
    required this.views,
    required this.likes,
    required this.tags,
    required this.urls,
    required this.userName,
    required this.verified,
  });

  factory GifInfo.fromJson(Map<String, dynamic> json) {
    return GifInfo(
      id: json['id'] ?? '',
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      urls: GifUrls.fromJson(json['urls'] ?? {}),
      userName: json['userName'] ?? json['username'] ?? '',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'duration': duration,
      'width': width,
      'height': height,
      'views': views,
      'likes': likes,
      'tags': tags,
      'urls': urls.toJson(),
      'userName': userName,
      'verified': verified,
    };
  }

  String get title {
    if (tags.isNotEmpty) {
      final tagsStr = tags.join(' ');
      return '$tagsStr Porn GIF by $userName';
    }
    // Fallback if tags are empty
    final capitalizedId = id.isEmpty ? '' : '${id[0].toUpperCase()}${id.substring(1)}';
    return '$capitalizedId by $userName';
  }

  String get downloadFileName {
    // Replace characters that are invalid in Windows/Android filesystems: \/:*?"<>|
    final cleanTitle = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(' ', '_')
        .replaceAll('__', '_');
    // Truncate to avoid file path length limit issues (e.g. max 100 characters for title prefix)
    final titlePrefix = cleanTitle.length > 100 ? cleanTitle.substring(0, 100) : cleanTitle;
    return '${titlePrefix}_${id}.mp4';
  }
}
