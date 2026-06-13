import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/isar_schemas.dart';
import '../models/gif_info.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _isar;

  Future<Isar> get db async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [IsarGifInfoSchema, IsarPlaylistSchema, IsarHistoryItemSchema, IsarFeedCacheSchema],
      directory: dir.path,
    );
    return _isar!;
  }

  // --- Mappings ---
  IsarGifInfo mapGifToIsar(GifInfo gif, {bool isFavorite = false}) {
    final isarGif = IsarGifInfo()
      ..id = gif.id
      ..duration = gif.duration
      ..width = gif.width
      ..height = gif.height
      ..views = gif.views
      ..likes = gif.likes
      ..tags = gif.tags
      ..userName = gif.userName
      ..verified = gif.verified
      ..isFavorite = isFavorite
      ..urls = (IsarGifUrls()
        ..silent = gif.urls.silent
        ..html = gif.urls.html
        ..poster = gif.urls.poster
        ..thumbnail = gif.urls.thumbnail
        ..hd = gif.urls.hd
        ..sd = gif.urls.sd);
    isarGif.isarId = isarGif.fastHash;
    return isarGif;
  }

  GifInfo mapIsarToGif(IsarGifInfo isar) {
    return GifInfo(
      id: isar.id,
      duration: isar.duration,
      width: isar.width,
      height: isar.height,
      views: isar.views,
      likes: isar.likes,
      tags: isar.tags,
      userName: isar.userName,
      verified: isar.verified,
      urls: GifUrls(
        silent: isar.urls.silent,
        html: isar.urls.html,
        poster: isar.urls.poster,
        thumbnail: isar.urls.thumbnail,
        hd: isar.urls.hd ?? '',
        sd: isar.urls.sd ?? '',
      ),
    );
  }

  // --- Favorites ---
  Future<List<GifInfo>> getFavorites() async {
    final isar = await db;
    final list = await isar.isarGifInfos.filter().isFavoriteEqualTo(true).findAll();
    return list.map((item) => mapIsarToGif(item)).toList();
  }

  Future<bool> isFavorited(String gifId) async {
    final isar = await db;
    final gif = IsarGifInfo()..id = gifId;
    final existing = await isar.isarGifInfos.get(gif.fastHash);
    return existing?.isFavorite ?? false;
  }

  Future<void> toggleFavorite(GifInfo gif) async {
    final isar = await db;
    final temp = IsarGifInfo()..id = gif.id;
    final hashId = temp.fastHash;
    
    await isar.writeTxn(() async {
      final existing = await isar.isarGifInfos.get(hashId);
      if (existing != null) {
        existing.isFavorite = !existing.isFavorite;
        await isar.isarGifInfos.put(existing);
      } else {
        final newIsarGif = mapGifToIsar(gif, isFavorite: true);
        await isar.isarGifInfos.put(newIsarGif);
      }
    });
  }

  // --- Playlists ---
  Future<List<IsarPlaylist>> getPlaylists() async {
    final isar = await db;
    return isar.isarPlaylists.where().findAll();
  }

  Future<void> createPlaylist(String name) async {
    final isar = await db;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final p = IsarPlaylist()
      ..playlistId = id
      ..name = name;
    await isar.writeTxn(() async {
      await isar.isarPlaylists.put(p);
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.isarPlaylists.filter().playlistIdEqualTo(playlistId).deleteFirst();
    });
  }

  Future<void> addToPlaylist(String playlistId, GifInfo gif) async {
    final isar = await db;
    final p = await isar.isarPlaylists.filter().playlistIdEqualTo(playlistId).findFirst();
    if (p == null) return;

    final gifIsar = mapGifToIsar(gif);
    final hashId = gifIsar.fastHash;

    await isar.writeTxn(() async {
      // First ensure the gif exists in IsarGifInfo
      var existing = await isar.isarGifInfos.get(hashId);
      if (existing == null) {
        await isar.isarGifInfos.put(gifIsar);
        existing = gifIsar;
      }
      
      // Load link relations
      await p.items.load();
      if (!p.items.any((item) => item.id == gif.id)) {
        p.items.add(existing);
        await p.items.save();
      }
    });
  }

  Future<void> removeFromPlaylist(String playlistId, String gifId) async {
    final isar = await db;
    final p = await isar.isarPlaylists.filter().playlistIdEqualTo(playlistId).findFirst();
    if (p == null) return;

    await isar.writeTxn(() async {
      await p.items.load();
      p.items.removeWhere((item) => item.id == gifId);
      await p.items.save();
    });
  }

  // --- Local History ---
  Future<void> addToHistory(GifInfo gif) async {
    final isar = await db;
    final gifIsar = mapGifToIsar(gif);
    final hashId = gifIsar.fastHash;

    await isar.writeTxn(() async {
      // Ensure the gif info exists
      var existingGif = await isar.isarGifInfos.get(hashId);
      if (existingGif == null) {
        await isar.isarGifInfos.put(gifIsar);
        existingGif = gifIsar;
      }

      // Check if this gif is already in history, if so update timestamp, otherwise insert
      var historyItem = await isar.isarHistoryItems.filter().gifIdEqualTo(gif.id).findFirst();
      if (historyItem != null) {
        // historyItem.viewedAt = DateTime.now();
        // await isar.isarHistoryItems.put(historyItem);
        historyItem.viewedAt = DateTime.now();
        historyItem.watchCount = historyItem.watchCount + 1;
        await isar.isarHistoryItems.put(historyItem);
      } else {
        // final newHistory = IsarHistoryItem()
        //   ..gifId = gif.id
        //   ..viewedAt = DateTime.now();
        // newHistory.gifInfo.value = existingGif;
        // await isar.isarHistoryItems.put(newHistory);
        // await newHistory.gifInfo.save();
        final newHistory = IsarHistoryItem()
          ..gifId = gif.id
          ..viewedAt = DateTime.now()
          ..watchCount = 1;
        newHistory.gifInfo.value = existingGif;
        await isar.isarHistoryItems.put(newHistory);
        await newHistory.gifInfo.save();
      }
    });
  }

  Future<List<GifInfo>> getHistory({int limit = 50}) async {
    final isar = await db;
    final items = await isar.isarHistoryItems
        .where()
        .sortByViewedAtDesc()
        .limit(limit)
        .findAll();

    final List<GifInfo> list = [];
    for (var item in items) {
      await item.gifInfo.load();
      if (item.gifInfo.value != null) {
        list.add(mapIsarToGif(item.gifInfo.value!));
      }
    }
    return list;
  }

  Future<List<IsarHistoryItem>> getRawHistory() async {
    final isar = await db;
    final items = await isar.isarHistoryItems.where().sortByViewedAtDesc().findAll();
    for (var item in items) {
      await item.gifInfo.load();
    }
    return items;
  }

  Future<void> clearHistory() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.isarHistoryItems.clear();
    });
  }

  Future<Set<String>> getWatchedGifIds() async {
    final isar = await db;
    final items = await isar.isarHistoryItems.where().findAll();
    return items.map((item) => item.gifId).toSet();
  }

  // --- Caching Layer for API Response Rates reduction ---
  Future<String?> readCache(String key, {Duration maxAge = const Duration(minutes: 10)}) async {
    try {
      final isar = await db;
      final cached = await isar.isarFeedCaches.filter().cacheKeyEqualTo(key).findFirst();
      if (cached == null) return null;
      
      final age = DateTime.now().difference(cached.cachedAt);
      if (age > maxAge) {
        // Cache expired, delete it in background
        await isar.writeTxn(() async {
          await isar.isarFeedCaches.delete(cached.id);
        });
        return null;
      }
      return cached.jsonPayload;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeCache(String key, String jsonPayload) async {
    try {
      final isar = await db;
      final existing = await isar.isarFeedCaches.filter().cacheKeyEqualTo(key).findFirst();
      
      final cacheItem = existing ?? IsarFeedCache();
      cacheItem.cacheKey = key;
      cacheItem.jsonPayload = jsonPayload;
      cacheItem.cachedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.isarFeedCaches.put(cacheItem);
      });
    } catch (_) {}
  }

  Future<void> clearCachePrefix(String prefix) async {
    try {
      final isar = await db;
      await isar.writeTxn(() async {
        await isar.isarFeedCaches.filter().cacheKeyStartsWith(prefix).deleteAll();
      });
    } catch (_) {}
  }

  Future<void> clearAllCache() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.isarFeedCaches.clear();
    });
  }
}
