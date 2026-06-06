import 'package:flutter/material.dart';
import '../models/gif_info.dart';
import '../services/api_client.dart';

class SearchProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  final List<GifInfo> _searchResults = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentQuery = '';
  String? _errorMessage;

  List<GifInfo> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get currentQuery => _currentQuery;
  String? get errorMessage => _errorMessage;

  // Run a new search query
  Future<void> performSearch(String query) async {
    _currentQuery = query;
    _searchResults.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;

    if (query.trim().isEmpty) {
      notifyListeners();
      return;
    }

    await fetchNextSearchResults();
  }

  // Load next page of search results
  Future<void> fetchNextSearchResults() async {
    if (_isLoading || !_hasMore || _currentQuery.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.searchGifs(_currentQuery, page: _currentPage);
      final rawGifs = data['gifs'] as List? ?? [];

      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();

      if (newGifs.isEmpty) {
        _hasMore = false;
      } else {
        _searchResults.addAll(newGifs);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear query and results
  void clearSearch() {
    _currentQuery = '';
    _searchResults.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();
  }
}
