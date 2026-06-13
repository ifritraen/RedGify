import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../models/gif_info.dart';
import '../services/isar_service.dart';
import '../models/isar_schemas.dart';
import 'playback_settings_provider.dart';
import 'theme_provider.dart';
import 'download_provider.dart';

class Playlist {
  final String id;
  final String name;
  final List<GifInfo> items;

  Playlist({
    required this.id,
    required this.name,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => {
        'id': i.id,
        'duration': i.duration,
        'width': i.width,
        'height': i.height,
        'views': i.views,
        'likes': i.likes,
        'tags': i.tags,
        'urls': {
          'silent': i.urls.silent,
          'html': i.urls.html,
          'poster': i.urls.poster,
          'thumbnail': i.urls.thumbnail,
          'hd': i.urls.hd,
          'sd': i.urls.sd,
        },
        'userName': i.userName,
        'verified': i.verified,
      }).toList(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      items: rawItems.map((item) => GifInfo.fromJson(item)).toList(),
    );
  }
}

class LibraryProvider with ChangeNotifier {
  final IsarService _isarService = IsarService();
  final _secureStorage = const FlutterSecureStorage();

  List<GifInfo> _favorites = [];
  List<Playlist> _playlists = [];
  List<GifInfo> _history = [];
  List<String> _subscribedCreators = [];
  Map<String, List<String>> _favoriteCategoryMappings = {};
  bool _isInitialized = false;

  List<GifInfo> get favorites => _favorites;
  List<Playlist> get playlists => _playlists;
  List<GifInfo> get history => _history;
  List<String> get subscribedCreators => _subscribedCreators;
  Map<String, List<String>> get favoriteCategoryMappings => _favoriteCategoryMappings;
  List<String> get favoriteCategories => _favoriteCategoryMappings.keys.toList();
  bool get isInitialized => _isInitialized;

  LibraryProvider() {
    loadLibrary();
  }

  // Load favorites, playlists and history from Isar
  Future<void> loadLibrary() async {
    try {
      _favorites = await _isarService.getFavorites();

      // Load favorite categories
      final catStr = await _secureStorage.read(key: 'favorite_categories');
      if (catStr != null) {
        final decoded = jsonDecode(catStr) as Map<String, dynamic>;
        _favoriteCategoryMappings = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
      } else {
        _favoriteCategoryMappings = {};
      }

      // Load subscribed creators
      final subStr = await _secureStorage.read(key: 'subscribed_creators');
      if (subStr != null) {
        final decoded = jsonDecode(subStr) as List;
        _subscribedCreators = decoded.map((v) => v.toString()).toList();
      } else {
        _subscribedCreators = [];
      }

      final rawPlaylists = await _isarService.getPlaylists();
      _playlists = [];
      for (var rp in rawPlaylists) {
        await rp.items.load();
        _playlists.add(Playlist(
          id: rp.playlistId,
          name: rp.name,
          items: rp.items.map((item) => _isarService.mapIsarToGif(item)).toList(),
        ));
      }

      _history = await _isarService.getHistory();
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  // Creator Subscriptions
  bool isSubscribed(String username) {
    return _subscribedCreators.contains(username.trim().toLowerCase());
  }

  Future<void> subscribeCreator(String username) async {
    final name = username.trim().toLowerCase();
    if (name.isNotEmpty && !_subscribedCreators.contains(name)) {
      _subscribedCreators.add(name);
      await _secureStorage.write(key: 'subscribed_creators', value: jsonEncode(_subscribedCreators));
      notifyListeners();
    }
  }

  Future<void> unsubscribeCreator(String username) async {
    final name = username.trim().toLowerCase();
    if (_subscribedCreators.contains(name)) {
      _subscribedCreators.remove(name);
      await _secureStorage.write(key: 'subscribed_creators', value: jsonEncode(_subscribedCreators));
      notifyListeners();
    }
  }

  // Check if a Gif is favorited
  bool isFavorited(String gifId) {
    return _favorites.any((g) => g.id == gifId);
  }

  // Toggle Favorite status
  Future<void> toggleFavorite(GifInfo gif) async {
    await _isarService.toggleFavorite(gif);
    await loadLibrary();
  }

  // Create a new playlist
  Future<void> createPlaylist(String name) async {
    await _isarService.createPlaylist(name);
    await loadLibrary();
  }

  // Add Gif to Playlist
  Future<void> addToPlaylist(String playlistId, GifInfo gif) async {
    await _isarService.addToPlaylist(playlistId, gif);
    await loadLibrary();
  }

  // Remove Gif from Playlist
  Future<void> removeFromPlaylist(String playlistId, String gifId) async {
    await _isarService.removeFromPlaylist(playlistId, gifId);
    await loadLibrary();
  }

  // Delete an entire playlist
  Future<void> deletePlaylist(String playlistId) async {
    await _isarService.deletePlaylist(playlistId);
    await loadLibrary();
  }

  // History operations
  Future<void> addToHistory(GifInfo gif) async {
    await _isarService.addToHistory(gif);
    await loadLibrary();
  }

  Future<void> clearHistory() async {
    await _isarService.clearHistory();
    await loadLibrary();
  }

  // Favorite categories operations
  List<String> getCategoriesForGif(String gifId) {
    final List<String> cats = [];
    _favoriteCategoryMappings.forEach((catName, ids) {
      if (ids.contains(gifId)) {
        cats.add(catName);
      }
    });
    return cats;
  }

  Future<void> _saveCategories() async {
    await _secureStorage.write(key: 'favorite_categories', value: jsonEncode(_favoriteCategoryMappings));
    notifyListeners();
  }

  Future<void> createFavoriteCategory(String categoryName) async {
    if (!_favoriteCategoryMappings.containsKey(categoryName)) {
      _favoriteCategoryMappings[categoryName] = [];
      await _saveCategories();
    }
  }

  Future<void> deleteFavoriteCategory(String categoryName) async {
    if (_favoriteCategoryMappings.containsKey(categoryName)) {
      _favoriteCategoryMappings.remove(categoryName);
      await _saveCategories();
    }
  }

  Future<void> toggleGifInFavoriteCategory(String categoryName, String gifId) async {
    if (_favoriteCategoryMappings.containsKey(categoryName)) {
      final list = _favoriteCategoryMappings[categoryName]!;
      if (list.contains(gifId)) {
        list.remove(gifId);
      } else {
        list.add(gifId);
      }
      await _saveCategories();
    }
  }

  // --- Import / Export ---
  Future<String> exportBackup() async {
    final displayName = await _secureStorage.read(key: 'user_display_name');
    final autoplayNext = await _secureStorage.read(key: 'play_autoplay_next');
    final shuffleEnabled = await _secureStorage.read(key: 'play_shuffle_enabled');
    final repeatSingle = await _secureStorage.read(key: 'play_repeat_single');
    final repeatLimit = await _secureStorage.read(key: 'play_repeat_limit');
    final playbackAction = await _secureStorage.read(key: 'play_playback_action');
    final gridColumns = await _secureStorage.read(key: 'play_grid_columns');
    final themeMode = await _secureStorage.read(key: 'theme_mode');

    List<dynamic> downloadsData = [];
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsFile = File('${docsDir.path}/downloads.json');
      if (await downloadsFile.exists()) {
        final content = await downloadsFile.readAsString();
        downloadsData = jsonDecode(content) as List? ?? [];
      }
    } catch (_) {}

    final Map<String, dynamic> backup = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'favorites': _favorites.map((i) => i.toJson()).toList(),
      'playlists': _playlists.map((p) => p.toJson()).toList(),
      'history': _history.map((h) => h.toJson()).toList(),
      'favorite_categories': _favoriteCategoryMappings,
      'subscribed_creators': _subscribedCreators,
      'downloads': downloadsData,
      'user_display_name': displayName,
      'play_autoplay_next': autoplayNext,
      'play_shuffle_enabled': shuffleEnabled,
      'play_repeat_single': repeatSingle,
      'play_repeat_limit': repeatLimit,
      'play_playback_action': playbackAction,
      'play_grid_columns': gridColumns,
      'theme_mode': themeMode,
    };
    return jsonEncode(backup);
  }

  // Trigger export UI flow
  Future<void> triggerExport(BuildContext context) async {
    try {
      final jsonStr = await exportBackup();
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/redgify_backup.json');
      await backupFile.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'RedGify Local Backup',
        text: 'RedGify offline backup containing playlists, favorites, subscriptions, downloads, statistics, and settings.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Trigger import UI flow
  Future<void> triggerImport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['version'] == null) {
        throw const FormatException('Invalid backup file format');
      }

      final isar = await _isarService.db;
      await isar.writeTxn(() async {
        // Clear existing library data
        await isar.isarGifInfos.clear();
        await isar.isarPlaylists.clear();
        await isar.isarHistoryItems.clear();

        // Restore favorites
        final rawFavs = data['favorites'] as List? ?? [];
        for (var raw in rawFavs) {
          final gif = GifInfo.fromJson(raw);
          final isarGif = _isarService.mapGifToIsar(gif, isFavorite: true);
          await isar.isarGifInfos.put(isarGif);
        }

        // Restore playlists
        final rawPlaylists = data['playlists'] as List? ?? [];
        for (var rawP in rawPlaylists) {
          final p = Playlist.fromJson(rawP);
          final isarP = IsarPlaylist()
            ..playlistId = p.id
            ..name = p.name;
          await isar.isarPlaylists.put(isarP);

          for (var item in p.items) {
            final isarGif = _isarService.mapGifToIsar(item);
            var existing = await isar.isarGifInfos.get(isarGif.fastHash);
            if (existing == null) {
              await isar.isarGifInfos.put(isarGif);
              existing = isarGif;
            }
            isarP.items.add(existing);
          }
          await isarP.items.save();
        }

        // Restore history
        final rawHistory = data['history'] as List? ?? [];
        for (var rawH in rawHistory) {
          final gif = GifInfo.fromJson(rawH);
          final isarGif = _isarService.mapGifToIsar(gif);
          var existing = await isar.isarGifInfos.get(isarGif.fastHash);
          if (existing == null) {
            await isar.isarGifInfos.put(isarGif);
            existing = isarGif;
          }

          final h = IsarHistoryItem()
            ..gifId = gif.id
            ..viewedAt = DateTime.now();
          h.gifInfo.value = existing;
          await isar.isarHistoryItems.put(h);
          await h.gifInfo.save();
        }
      });

      // Restore favorite categories
      final rawCats = data['favorite_categories'] as Map<String, dynamic>?;
      if (rawCats != null) {
        final mapped = rawCats.map((key, value) => MapEntry(key, List<String>.from(value)));
        await _secureStorage.write(key: 'favorite_categories', value: jsonEncode(mapped));
      } else {
        await _secureStorage.delete(key: 'favorite_categories');
      }

      // Restore subscribed creators
      final rawSubs = data['subscribed_creators'] as List? ?? [];
      final subList = rawSubs.map((v) => v.toString()).toList();
      await _secureStorage.write(key: 'subscribed_creators', value: jsonEncode(subList));

      // Restore user display name
      final rawName = data['user_display_name'] as String?;
      if (rawName != null) {
        await _secureStorage.write(key: 'user_display_name', value: rawName);
      } else {
        await _secureStorage.delete(key: 'user_display_name');
      }

      // Restore settings
      for (final key in [
        'play_autoplay_next',
        'play_shuffle_enabled',
        'play_repeat_single',
        'play_repeat_limit',
        'play_playback_action',
        'play_grid_columns',
        'theme_mode',
      ]) {
        final val = data[key] as String?;
        if (val != null) {
          await _secureStorage.write(key: key, value: val);
        } else {
          await _secureStorage.delete(key: key);
        }
      }

      // Restore downloads history file
      final rawDownloads = data['downloads'] as List?;
      if (rawDownloads != null) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final downloadsFile = File('${docsDir.path}/downloads.json');
          await downloadsFile.writeAsString(jsonEncode(rawDownloads));
        } catch (_) {}
      }

      // Reload Library state
      await loadLibrary();

      // Programmatically reload dependent settings providers
      try {
        if (context.mounted) {
          Provider.of<PlaybackSettingsProvider>(context, listen: false).loadSettings();
          Provider.of<ThemeProvider>(context, listen: false).loadTheme();
          Provider.of<DownloadProvider>(context, listen: false).loadCompletedDownloads(force: true);
        }
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import backup: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
