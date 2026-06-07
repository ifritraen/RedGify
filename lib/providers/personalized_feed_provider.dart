import 'package:flutter/material.dart';
import '../models/gif_info.dart';
import '../services/api_client.dart';
import '../services/isar_service.dart';
import 'explore_provider.dart';

class PersonalizedFeedProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final IsarService _isarService = IsarService();

  final List<GifInfo> _gifs = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;

  List<GifInfo> get gifs => _gifs;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  // Initialize and load the feed
  Future<void> fetchInitialFeed(List<String> subscribedCreators) async {
    if (_gifs.isNotEmpty) return;
    _gifs.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage(subscribedCreators);
  }

  // Load next page
  Future<void> fetchNextPage(List<String> subscribedCreators, {bool bypassCache = false}) async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final historyItems = await _isarService.getRawHistory();

      // If no history and no subscribed creators, fallback to trending feed
      if (historyItems.isEmpty && subscribedCreators.isEmpty) {
        final data = await _apiClient.getTrendingFeed(
          page: _currentPage,
          bypassCache: bypassCache,
        );
        final rawGifs = data['gifs'] as List? ?? [];
        final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();
        _appendGifs(newGifs);
        return;
      }

      // 1. Extract Top Tags
      final Map<String, int> tagCounts = {};
      final Map<String, int> creatorCounts = {};

      // Need explore provider for niche references if empty
      // But we can approximate niche mapping or check if exploreProvider niches list has elements.
      // If we don't have niche objects, we'll rely on tags and creators which are most personalized.
      for (var item in historyItems) {
        final gif = item.gifInfo.value;
        if (gif == null) continue;
        final count = item.watchCount > 0 ? item.watchCount : 1;

        final creator = gif.userName;
        if (creator.isNotEmpty) {
          creatorCounts[creator] = (creatorCounts[creator] ?? 0) + count;
        }

        for (var tag in gif.tags) {
          final lowerTag = tag.trim().toLowerCase();
          if (lowerTag.isNotEmpty) {
            tagCounts[lowerTag] = (tagCounts[lowerTag] ?? 0) + count;
          }
        }
      }

      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedCreators = creatorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 2. Build list of sources to query for this page
      final List<Future<List<GifInfo>>> fetchFutures = [];

      // Add Subscribed creators (highest priority)
      final Set<String> creatorSources = {};
      for (var sub in subscribedCreators) {
        creatorSources.add(sub.trim().toLowerCase());
      }
      // Add top watched creators (up to 3)
      for (var entry in sortedCreators.take(3)) {
        creatorSources.add(entry.key.trim().toLowerCase());
      }

      // Query creators (take up to 3 creators to avoid overloading API)
      final List<String> creatorsToQuery = creatorSources.toList()..shuffle();
      for (var creator in creatorsToQuery.take(3)) {
        fetchFutures.add(() async {
          try {
            final res = await _apiClient.getUserGifs(creator, page: _currentPage, limit: 10, bypassCache: bypassCache);
            final gifsList = res['gifs'] as List? ?? [];
            return gifsList.map((g) => GifInfo.fromJson(g)).toList();
          } catch (_) {
            return <GifInfo>[];
          }
        }());
      }

      // Query top tags (up to 3)
      final List<String> tagsToQuery = sortedTags.map((e) => e.key).take(3).toList();
      for (var tag in tagsToQuery) {
        fetchFutures.add(() async {
          try {
            final res = await _apiClient.searchGifs(tag, page: _currentPage, limit: 10, bypassCache: bypassCache);
            final gifsList = res['gifs'] as List? ?? [];
            return gifsList.map((g) => GifInfo.fromJson(g)).toList();
          } catch (_) {
            return <GifInfo>[];
          }
        }());
      }

      // If we don't have enough futures, fetch trending to mix in
      if (fetchFutures.length < 2) {
        fetchFutures.add(() async {
          try {
            final res = await _apiClient.getTrendingFeed(page: _currentPage, limit: 15, bypassCache: bypassCache);
            final gifsList = res['gifs'] as List? ?? [];
            return gifsList.map((g) => GifInfo.fromJson(g)).toList();
          } catch (_) {
            return <GifInfo>[];
          }
        }());
      }

      // Wait for all fetches in parallel
      final results = await Future.wait(fetchFutures);

      // Interleave results
      final List<GifInfo> combinedList = [];
      int maxLen = 0;
      for (var list in results) {
        if (list.length > maxLen) maxLen = list.length;
      }

      for (int i = 0; i < maxLen; i++) {
        for (var list in results) {
          if (i < list.length) {
            combinedList.add(list[i]);
          }
        }
      }

      // De-duplicate within the retrieved list
      final Map<String, GifInfo> uniqueCombined = {};
      for (var gif in combinedList) {
        uniqueCombined[gif.id] = gif;
      }

      final uniqueGifs = uniqueCombined.values.toList();
      _appendGifs(uniqueGifs);

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _appendGifs(List<GifInfo> newGifs) async {
    final watchedIds = await _isarService.getWatchedGifIds();
    final existingIds = _gifs.map((g) => g.id).toSet();
    final filteredGifs = newGifs.where((g) => !existingIds.contains(g.id) && !watchedIds.contains(g.id)).toList();

    if (newGifs.isEmpty) {
      _hasMore = false;
    } else {
      _gifs.addAll(filteredGifs);
      ExploreProvider.collectAndSaveTags(filteredGifs);
      _currentPage++;
    }
  }

  // Refresh feed
  Future<void> refreshFeed(List<String> subscribedCreators) async {
    _gifs.clear();
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    await fetchNextPage(subscribedCreators, bypassCache: true);
  }
}
