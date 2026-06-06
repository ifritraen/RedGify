import 'package:flutter/material.dart';
import '../models/gif_info.dart';
import '../services/api_client.dart';

class FeedProvider with ChangeNotifier {
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

  // Load initial feed
  Future<void> fetchInitialFeed() async {
    if (_gifs.isNotEmpty) return;
    _currentPage = 1;
    _gifs.clear();
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage();
  }

  // Load subsequent pages (for infinite scroll)
  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.getTrendingFeed(page: _currentPage);
      final rawGifs = data['gifs'] as List? ?? [];
      
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();
      
      if (newGifs.isEmpty) {
        _hasMore = false;
      } else {
        _gifs.addAll(newGifs);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh feed from page 1
  Future<void> refreshFeed() async {
    _gifs.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage();
  }
}
