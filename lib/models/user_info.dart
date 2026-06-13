class UserInfo {
  final String username;
  final String name;
  final String? profileImageUrl;
  final int views;
  final int followers;
  final bool verified;

  UserInfo({
    required this.username,
    required this.name,
    this.profileImageUrl,
    required this.views,
    required this.followers,
    required this.verified,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['username'] ?? json['name'] ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      views: json['views'] ?? 0,
      followers: json['followers'] ?? 0,
      verified: json['verified'] ?? false,
    );
  }
}
