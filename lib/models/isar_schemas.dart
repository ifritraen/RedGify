import 'package:isar/isar.dart';

part 'isar_schemas.g.dart';

@collection
class IsarGifInfo {
  Id? isarId; // Set to fastHash(id)

  @Index(unique: true, replace: true)
  late String id;

  late double duration;
  late int width;
  late int height;
  late int views;
  late int likes;
  late List<String> tags;
  late IsarGifUrls urls;
  late String userName;
  late bool verified;
  bool isFavorite = false;

  // Compute a fast 64-bit integer hash from the RedGIFs string ID
  int get fastHash {
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < id.length) {
      final codeUnit = id.codeUnitAt(i++);
      hash ^= codeUnit;
      hash *= 0x100000001b3;
    }
    return hash;
  }
}

@embedded
class IsarGifUrls {
  String? silent;
  String? html;
  String? poster;
  String? thumbnail;
  String? hd;
  String? sd;
}

@collection
class IsarPlaylist {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String playlistId;

  late String name;
  
  // Relation link to GIF info
  final items = IsarLinks<IsarGifInfo>();
}

@collection
class IsarHistoryItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String gifId;

  late DateTime viewedAt;
  
  // Link to the GIF model
  final gifInfo = IsarLink<IsarGifInfo>();

  int watchCount = 1;
}

@collection
class IsarFeedCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cacheKey;

  late String jsonPayload;
  late DateTime cachedAt;
}
