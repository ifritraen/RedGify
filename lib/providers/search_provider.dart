import 'package:flutter/material.dart';
import '../models/gif_info.dart';
import '../models/niche_info.dart';
import '../models/user_info.dart';
import '../services/api_client.dart';
import '../services/isar_service.dart';

class SearchProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // Suggestion list
  List<dynamic> _suggestions = [];
  bool _isLoadingSuggest = false;

  // Search query
  String _currentQuery = '';
  String? _errorMessage;

  // GIFs
  final List<GifInfo> _gifResults = [];
  bool _isLoadingGifs = false;
  int _gifsPage = 1;
  bool _hasMoreGifs = true;

  // Images
  final List<GifInfo> _imageResults = [];
  bool _isLoadingImages = false;
  int _imagesPage = 1;
  bool _hasMoreImages = true;

  // Niches
  final List<NicheInfo> _nicheResults = [];
  bool _isLoadingNiches = false;
  int _nichesPage = 1;
  bool _hasMoreNiches = true;

  // Creators
  final List<UserInfo> _creatorResults = [];
  bool _isLoadingCreators = false;
  int _creatorsPage = 1;
  bool _hasMoreCreators = true;

  // Getters
  List<dynamic> get suggestions => _suggestions;
  bool get isLoadingSuggest => _isLoadingSuggest;

  String get currentQuery => _currentQuery;
  String? get errorMessage => _errorMessage;

  List<GifInfo> get gifResults => _gifResults;
  bool get isLoadingGifs => _isLoadingGifs;
  bool get hasMoreGifs => _hasMoreGifs;

  List<GifInfo> get imageResults => _imageResults;
  bool get isLoadingImages => _isLoadingImages;
  bool get hasMoreImages => _hasMoreImages;

  List<NicheInfo> get nicheResults => _nicheResults;
  bool get isLoadingNiches => _isLoadingNiches;
  bool get hasMoreNiches => _hasMoreNiches;

  List<UserInfo> get creatorResults => _creatorResults;
  bool get isLoadingCreators => _isLoadingCreators;
  bool get hasMoreCreators => _hasMoreCreators;

  // For backward compatibility with home_screen.dart references
  List<GifInfo> get searchResults => _gifResults;
  bool get isLoading => _isLoadingGifs;
  bool get hasMore => _hasMoreGifs;

  // Load autocomplete suggestions
  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _isLoadingSuggest = true;
    notifyListeners();

    try {
      final results = await _apiClient.getSearchSuggestions(query);
      _suggestions = results;
    } catch (_) {
      _suggestions = [];
    } finally {
      _isLoadingSuggest = false;
      notifyListeners();
    }
  }

  // Clear suggestions specifically
  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  // Perform initial search for all categories
  Future<void> performSearch(String query, {bool bypassCache = false}) async {
    _currentQuery = query;
    _errorMessage = null;

    // Reset categories
    _gifResults.clear();
    _gifsPage = 1;
    _hasMoreGifs = true;

    _imageResults.clear();
    _imagesPage = 1;
    _hasMoreImages = true;

    _nicheResults.clear();
    _nichesPage = 1;
    _hasMoreNiches = true;

    _creatorResults.clear();
    _creatorsPage = 1;
    _hasMoreCreators = true;

    if (query.trim().isEmpty) {
      notifyListeners();
      return;
    }

    if (bypassCache) {
      await IsarService().clearCachePrefix('search_${query}_');
      await IsarService().clearCachePrefix('search_niches_${query}_');
      await IsarService().clearCachePrefix('creators_${query}_');
    }

    notifyListeners();

    // Fetch first page of ALL categories in parallel
    await Future.wait([
      fetchNextGifs(bypassCache: bypassCache),
      fetchNextImages(bypassCache: bypassCache),
      fetchNextNiches(bypassCache: bypassCache),
      fetchNextCreators(bypassCache: bypassCache),
    ]);
  }

  // Fetch next page of GIFs
  Future<void> fetchNextGifs({bool bypassCache = false}) async {
    if (_isLoadingGifs || !_hasMoreGifs || _currentQuery.isEmpty) return;

    _isLoadingGifs = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.searchGifs(_currentQuery, type: 'g', page: _gifsPage, bypassCache: bypassCache);
      final rawGifs = data['gifs'] as List? ?? [];
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();

      final existingIds = _gifResults.map((g) => g.id).toSet();
      final uniqueNewGifs = newGifs.where((g) => !existingIds.contains(g.id)).toList();

      if (newGifs.isEmpty) {
        _hasMoreGifs = false;
      } else {
        _gifResults.addAll(uniqueNewGifs);
        _gifsPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingGifs = false;
      notifyListeners();
    }
  }

  // Fetch next page of Images
  Future<void> fetchNextImages({bool bypassCache = false}) async {
    if (_isLoadingImages || !_hasMoreImages || _currentQuery.isEmpty) return;

    _isLoadingImages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.searchGifs(_currentQuery, type: 'i', page: _imagesPage, bypassCache: bypassCache);
      final rawGifs = data['gifs'] as List? ?? [];
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();

      final existingIds = _imageResults.map((g) => g.id).toSet();
      final uniqueNewGifs = newGifs.where((g) => !existingIds.contains(g.id)).toList();

      if (newGifs.isEmpty) {
        _hasMoreImages = false;
      } else {
        _imageResults.addAll(uniqueNewGifs);
        _imagesPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingImages = false;
      notifyListeners();
    }
  }

  // Fetch next page of Niches
  Future<void> fetchNextNiches({bool bypassCache = false}) async {
    if (_isLoadingNiches || !_hasMoreNiches || _currentQuery.isEmpty) return;

    _isLoadingNiches = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.searchNiches(_currentQuery, page: _nichesPage, bypassCache: bypassCache);
      final list = data['niches'] as List? ?? data['data']?['niches'] as List? ?? [];
      final newNiches = list.map((n) => NicheInfo.fromJson(n)).toList();

      final existingIds = _nicheResults.map((n) => n.id).toSet();
      final uniqueNewNiches = newNiches.where((n) => !existingIds.contains(n.id)).toList();

      if (newNiches.isEmpty) {
        _hasMoreNiches = false;
      } else {
        _nicheResults.addAll(uniqueNewNiches);
        _nichesPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingNiches = false;
      notifyListeners();
    }
  }

  // Fetch next page of Creators
  Future<void> fetchNextCreators({bool bypassCache = false}) async {
    if (_isLoadingCreators || !_hasMoreCreators || _currentQuery.isEmpty) return;

    _isLoadingCreators = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiClient.searchCreators(query: _currentQuery, page: _creatorsPage, bypassCache: bypassCache);
      final list = data['users'] as List? ?? data['items'] as List? ?? data['data']?['items'] as List? ?? [];
      final newCreators = list.map((u) => UserInfo.fromJson(u)).toList();

      final existingUsernames = _creatorResults.map((u) => u.username).toSet();
      final uniqueNewCreators = newCreators.where((u) => !existingUsernames.contains(u.username)).toList();

      if (newCreators.isEmpty) {
        _hasMoreCreators = false;
      } else {
        _creatorResults.addAll(uniqueNewCreators);
        _creatorsPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingCreators = false;
      notifyListeners();
    }
  }

  // Fetch next page of search results (backward compatibility alias)
  Future<void> fetchNextSearchResults({bool bypassCache = false}) async {
    await fetchNextGifs(bypassCache: bypassCache);
  }

  // Clear query and results
  void clearSearch() {
    _currentQuery = '';
    _errorMessage = null;

    _gifResults.clear();
    _gifsPage = 1;
    _hasMoreGifs = true;

    _imageResults.clear();
    _imagesPage = 1;
    _hasMoreImages = true;

    _nicheResults.clear();
    _nichesPage = 1;
    _hasMoreNiches = true;

    _creatorResults.clear();
    _creatorsPage = 1;
    _hasMoreCreators = true;

    _suggestions.clear();

    notifyListeners();
  }
}
