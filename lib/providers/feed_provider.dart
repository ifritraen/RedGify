import 'package:flutter/material.dart';
import '../models/gif_info.dart';
import '../services/api_client.dart';
import '../services/isar_service.dart';
import 'explore_provider.dart';

class FeedProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  final List<GifInfo> _gifs = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;
  String _activeOrder = 'trending'; // Can be 'trending', 'new', 'top'

  List<GifInfo> get gifs => _gifs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get activeOrder => _activeOrder;

  // Load initial feed
  Future<void> fetchInitialFeed() async {
    if (_gifs.isNotEmpty) return;
    _currentPage = 1;
    _gifs.clear();
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage();
  }

  // Set new feed ordering order and refetch
  Future<void> setOrder(String order) async {
    if (_activeOrder == order) return;
    _activeOrder = order;
    _gifs.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
    await fetchNextPage();
  }

  // Load subsequent pages (for infinite scroll)
  Future<void> fetchNextPage({bool bypassCache = false}) async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.getTrendingFeed(
        page: _currentPage,
        order: _activeOrder,
        bypassCache: bypassCache,
      );
      final rawGifs = data['gifs'] as List? ?? [];
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();
      
      // Filter out watched and duplicate GIFs
      final watchedIds = await IsarService().getWatchedGifIds();
      final existingIds = _gifs.map((g) => g.id).toSet();
      final filteredGifs = newGifs.where((g) => !existingIds.contains(g.id) && !watchedIds.contains(g.id)).toList();
      
      if (newGifs.isEmpty) {
        _hasMore = false;
      } else {
        _gifs.addAll(filteredGifs);
        ExploreProvider.collectAndSaveTags(filteredGifs);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove watched gifs dynamically from the current feed view
  Future<void> filterWatchedGifs() async {
    try {
      final watchedIds = await IsarService().getWatchedGifIds();
      final originalLength = _gifs.length;
      _gifs.removeWhere((g) => watchedIds.contains(g.id));
      if (_gifs.length != originalLength) {
        notifyListeners();
      }
    } catch (_) {}
  }

  // Refresh feed from page 1
  Future<void> refreshFeed() async {
    await IsarService().clearCachePrefix('feed_${_activeOrder}_page_');
    _gifs.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage(bypassCache: true);
  }
}
