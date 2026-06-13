class NicheInfo {
  final String id;
  final String name;
  final String description;
  final String? cover;
  final int subscribers;

  NicheInfo({
    required this.id,
    required this.name,
    required this.description,
    this.cover,
    required this.subscribers,
  });

  factory NicheInfo.fromJson(Map<String, dynamic> json) {
    return NicheInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cover: json['cover'],
      subscribers: json['subscribers'] ?? 0,
    );
  }
}
