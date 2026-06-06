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

  final List<GifInfo> _creatorGifs = [];
  bool _isLoadingGifs = false;
  int _currentGifsPage = 1;
  bool _hasMoreGifs = true;
  String? _gifsError;

  UserInfo? get userInfo => _userInfo;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  List<GifInfo> get creatorGifs => _creatorGifs;
  bool get isLoadingGifs => _isLoadingGifs;
  bool get hasMoreGifs => _hasMoreGifs;
  String? get gifsError => _gifsError;

  // Load creator profile data and reset video list
  Future<void> loadCreatorProfile(String username, {bool bypassCache = false}) async {
    _userInfo = null;
    _profileError = null;
    _isLoadingProfile = true;

    _creatorGifs.clear();
    _currentGifsPage = 1;
    _hasMoreGifs = true;
    _gifsError = null;
    notifyListeners();

    try {
      if (bypassCache) {
        await IsarService().clearCachePrefix('user_gifs_${username}_page_');
        // await IsarService().clearCachePrefix('user_profile_${username}');
        await IsarService().clearCachePrefix('user_profile_$username');
      }

      final data = await _apiClient.getUserProfile(username, bypassCache: bypassCache);
      // Backend may return user details directly inside user block
      final rawUser = data['user'] as Map<String, dynamic>? ?? data;
      _userInfo = UserInfo.fromJson(rawUser);
      _isLoadingProfile = false;
      notifyListeners();

      // Trigger initial video load
      await fetchNextCreatorGifsPage(username, bypassCache: bypassCache);
    } catch (e) {
      _profileError = e.toString();
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  // Load next page of videos uploaded by the creator
  Future<void> fetchNextCreatorGifsPage(String username, {bool bypassCache = false}) async {
    if (_isLoadingGifs || !_hasMoreGifs) return;

    _isLoadingGifs = true;
    _gifsError = null;
    notifyListeners();

    try {
      final data = await _apiClient.getUserGifs(username, page: _currentGifsPage, bypassCache: bypassCache);
      final rawGifs = data['gifs'] as List? ?? [];
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();

      // Filter out duplicate GIF IDs
      final existingIds = _creatorGifs.map((g) => g.id).toSet();
      final uniqueNewGifs = newGifs.where((g) => !existingIds.contains(g.id)).toList();

      if (newGifs.isEmpty) {
        _hasMoreGifs = false;
      } else {
        _creatorGifs.addAll(uniqueNewGifs);
        _currentGifsPage++;
      }
    } catch (e) {
      _gifsError = e.toString();
    } finally {
      _isLoadingGifs = false;
      notifyListeners();
    }
  }
}
