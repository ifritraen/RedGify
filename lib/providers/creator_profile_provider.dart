import 'package:flutter/material.dart';
import '../models/user_info.dart';
import '../models/gif_info.dart';
import '../services/api_client.dart';
import '../services/isar_service.dart';

class CreatorProfileProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserInfo? _userInfo;
  bool _isLoadingProfile = false;
  String? _profileError;

  String _activeTab = 'g'; // 'g' for gifs, 'i' for images
  bool _isLoadingGifs = false;
  String? _gifsError;

  // Separate page and item tracking for both tabs
  final List<GifInfo> _gifsList = [];
  int _gifsPage = 1;
  bool _hasMoreGifs = true;

  final List<GifInfo> _imagesList = [];
  int _imagesPage = 1;
  bool _hasMoreImages = true;

  UserInfo? get userInfo => _userInfo;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  String get activeTab => _activeTab;
  bool get isLoadingGifs => _isLoadingGifs;
  String? get gifsError => _gifsError;

  List<GifInfo> get activeMedia => _activeTab == 'g' ? _gifsList : _imagesList;
  bool get hasMoreActive => _activeTab == 'g' ? _hasMoreGifs : _hasMoreImages;

  // For backward compatibility / template reference
  List<GifInfo> get creatorGifs => activeMedia;

  // Switch between Gifs and Images tabs
  Future<void> selectTab(String tab, String username, {bool bypassCache = false}) async {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();

    // Fetch initial page if tab list is empty
    if (activeMedia.isEmpty) {
      await fetchNextPage(username, bypassCache: bypassCache);
    }
  }

  // Load creator profile data and reset both tabs
  Future<void> loadCreatorProfile(String username, {bool bypassCache = false}) async {
    var cleanUsername = username.trim();
    if (cleanUsername.startsWith('@')) {
      cleanUsername = cleanUsername.substring(1);
    }

    _userInfo = null;
    _profileError = null;
    _isLoadingProfile = true;

    _activeTab = 'g';
    _gifsError = null;

    _gifsList.clear();
    _gifsPage = 1;
    _hasMoreGifs = true;

    _imagesList.clear();
    _imagesPage = 1;
    _hasMoreImages = true;

    notifyListeners();

    try {
      if (bypassCache) {
        await IsarService().clearCachePrefix('user_gifs_${cleanUsername}_type_');
        await IsarService().clearCachePrefix('user_profile_$cleanUsername');
      }

      final data = await _apiClient.getUserProfile(cleanUsername, bypassCache: bypassCache);
      // final rawUser = data['user'] as Map<String, dynamic>? ?? data;
      final Map<String, dynamic> rawUser;
      if (data.containsKey('user')) {
        rawUser = data['user'] as Map<String, dynamic>;
      } else if (data.containsKey('users') && data['users'] is List && (data['users'] as List).isNotEmpty) {
        rawUser = data['users'][0] as Map<String, dynamic>;
      } else {
        rawUser = data;
      }
      _userInfo = UserInfo.fromJson(rawUser);
      _isLoadingProfile = false;
      notifyListeners();

      // Trigger initial page load for active tab (gifs)
      await fetchNextPage(cleanUsername, bypassCache: bypassCache);
    } catch (e) {
      _profileError = e.toString();
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // Fetch next page of content for the active tab
  Future<void> fetchNextPage(String username, {bool bypassCache = false}) async {
    var cleanUsername = username.trim();
    if (cleanUsername.startsWith('@')) {
      cleanUsername = cleanUsername.substring(1);
    }

    final isGifs = _activeTab == 'g';
    final hasMore = isGifs ? _hasMoreGifs : _hasMoreImages;
    if (_isLoadingGifs || !hasMore) return;

    _isLoadingGifs = true;
    _gifsError = null;
    notifyListeners();

    try {
      final page = isGifs ? _gifsPage : _imagesPage;
      final data = await _apiClient.getUserGifs(cleanUsername, type: _activeTab, page: page, bypassCache: bypassCache);
      final rawGifs = data['gifs'] as List? ?? [];
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();

      final list = isGifs ? _gifsList : _imagesList;
      final existingIds = list.map((g) => g.id).toSet();
      final uniqueNewGifs = newGifs.where((g) => !existingIds.contains(g.id)).toList();

      if (newGifs.isEmpty) {
        if (isGifs) {
          _hasMoreGifs = false;
        } else {
          _hasMoreImages = false;
        }
      } else {
        list.addAll(uniqueNewGifs);
        if (isGifs) {
          _gifsPage++;
        } else {
          _imagesPage++;
        }
      }
    } catch (e) {
      _gifsError = e.toString();
    } finally {
      _isLoadingGifs = false;
      notifyListeners();
    }
  }

  // Deprecated backward compatibility hook
  Future<void> fetchNextCreatorGifsPage(String username, {bool bypassCache = false}) async {
    await fetchNextPage(username, bypassCache: bypassCache);
  }
}
