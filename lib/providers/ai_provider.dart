import 'package:flutter/material.dart';
import '../models/gif_info.dart';
import '../services/api_client.dart';
import '../services/isar_service.dart';

class AIProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  final List<GifInfo> _gifs = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;

  List<GifInfo> get gifs => _gifs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // Load initial AI generated feed stream
  Future<void> fetchInitialFeed() async {
    if (_gifs.isNotEmpty) return;
    _currentPage = 1;
    _gifs.clear();
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage();
  }

  // Load subsequent pages of AI generated stream
  Future<void> fetchNextPage({bool bypassCache = false}) async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // The RedGIFs AI section is powered by query searches for 'ai' tags
      final data = await _apiClient.searchGifs('ai', page: _currentPage, bypassCache: bypassCache);
      final rawGifs = data['gifs'] as List? ?? [];
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();

      // Filter out duplicate GIF IDs
      final existingIds = _gifs.map((g) => g.id).toSet();
      final uniqueNewGifs = newGifs.where((g) => !existingIds.contains(g.id)).toList();

      if (newGifs.isEmpty) {
        _hasMore = false;
      } else {
        _gifs.addAll(uniqueNewGifs);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh AI feed
  Future<void> refreshFeed() async {
    await IsarService().clearCachePrefix('search_ai_page_');
    _gifs.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage(bypassCache: true);
  }
}
