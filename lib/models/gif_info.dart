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
      userName: json['userName'] ?? '',
      verified: json['verified'] ?? false,
    );
  }
}
