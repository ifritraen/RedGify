import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'token_manager.dart';
import 'isar_service.dart';

class ApiClient {
  final TokenManager _tokenManager = TokenManager();
  final IsarService _isarService = IsarService();

  // Make authenticated GET requests with automatic token refreshing
  Future<http.Response> get(String url) async {
    final token = await _tokenManager.getValidToken();
    final userAgent = await _tokenManager.getUserAgent();

    final headers = {
      ...ApiConstants.baseHeaders,
      'User-Agent': userAgent,
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    // If unauthorized, token might be expired. Invalidate, refresh, and retry.
    if (response.statusCode == 401) {
      await _tokenManager.invalidateToken();
      final freshToken = await _tokenManager.getValidToken();
      
      final retryHeaders = {
        ...headers,
        'Authorization': 'Bearer $freshToken',
      };
      response = await http.get(Uri.parse(url), headers: retryHeaders);
    }

    return response;
  }

  // Fetch search results (cache for short periods e.g. 5 minutes)
  Future<Map<String, dynamic>> searchGifs(String query, {String type = 'g', int limit = 20, int page = 1, String order = 'score', bool bypassCache = false}) async {
    final cacheKey = 'search_${query}_type_${type}_order_${order}_page_${page}_limit_$limit';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(minutes: 5));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    final url = '${ApiConstants.searchEndpoint}?query=${Uri.encodeComponent(query)}&type=$type&count=$limit&page=$page&order=$order';
    final response = await get(url);

    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to query search: ${response.statusCode}');
    }
  }

  // Fetch real-time tag/search suggestions
  Future<List<dynamic>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    
    final url = '${ApiConstants.baseUrl}/search/suggest?query=${Uri.encodeComponent(query)}';
    final response = await get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('data')) {
        return data['data'] as List? ?? [];
      }
      return [];
    } else {
      throw Exception('Failed to get suggestions: ${response.statusCode}');
    }
  }

  // Fetch niches search results
  Future<Map<String, dynamic>> searchNiches(String query, {int limit = 20, int page = 1, bool bypassCache = false}) async {
    final cacheKey = 'search_niches_${query}_page_${page}_limit_$limit';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(minutes: 10));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    final url = '${ApiConstants.baseUrl}/niches/search?order=best_match&count=$limit&page=$page&query=${Uri.encodeComponent(query)}';
    final response = await get(url);

    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to search niches: ${response.statusCode}');
    }
  }

  // Fetch trending/popular/recent GIFs feed
  Future<Map<String, dynamic>> getTrendingFeed({int limit = 20, int page = 1, String order = 'trending', bool bypassCache = false}) async {
    // final cacheKey = 'feed_${order}_page_${page}_limit_${limit}';
    final cacheKey = 'feed_${order}_page_${page}_limit_$limit';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(minutes: 10));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    // final url = '${ApiConstants.trendingGifsEndpoint}?limit=$limit&page=$page&order=$order';
    final String url;
    if (order == 'new') {
      url = '${ApiConstants.searchEndpoint}?type=g&order=latest&count=$limit&page=$page&verified=y';
    } else {
      url = '${ApiConstants.baseUrl}/feeds/trending/popular?page=$page&count=$limit';
    }
    final response = await get(url);

    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load feed ($order): ${response.statusCode}');
    }
  }

  // Fetch all Niches list (cache longer e.g. 12 hours)
  Future<Map<String, dynamic>> getNiches({bool bypassCache = false}) async {
    final cacheKey = 'niches_list';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(hours: 12));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    const url = ApiConstants.nichesEndpoint;
    final response = await get(url);

    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch niches list: ${response.statusCode}');
    }
  }

  // Fetch Gifs for a specific niche
  Future<Map<String, dynamic>> getNicheGifs(String nicheId, {int limit = 20, int page = 1, String order = 'trending', bool bypassCache = false}) async {
    // final cacheKey = 'niche_${nicheId}_${order}_page_${page}_limit_${limit}';
    final cacheKey = 'niche_${nicheId}_${order}_page_${page}_limit_$limit';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(minutes: 10));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    // final url = '${ApiConstants.nichesEndpoint}/$nicheId/gifs?limit=$limit&page=$page&order=$order';
    final url = '${ApiConstants.nichesEndpoint}/$nicheId/gifs?count=$limit&page=$page&order=$order';
    final response = await get(url);

    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load niche gifs: ${response.statusCode}');
    }
  }

  // Fetch trending tags list
  Future<List<dynamic>> getTrendingTags({bool bypassCache = false}) async {
    final cacheKey = 'trending_tags';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(hours: 2));
      if (cached != null) {
        return jsonDecode(cached) as List<dynamic>;
      }
    }

    const url = ApiConstants.trendingTagsEndpoint;
    final response = await get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> tagsList = data['tags'] as List<dynamic>? ?? [];
      await _isarService.writeCache(cacheKey, jsonEncode(tagsList));
      return tagsList;
    } else {
      throw Exception('Failed to load trending tags: ${response.statusCode}');
    }
  }

  // Fetch user profile metadata
  Future<Map<String, dynamic>> getUserProfile(String username, {bool bypassCache = false}) async {
    final cleanUsername = username.trim().toLowerCase();
    // final cacheKey = 'user_profile_${username}';
    // final cacheKey = 'user_profile_$username';
    final cacheKey = 'user_profile_$cleanUsername';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(hours: 4));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    // final url = 'https://api.redgifs.com/v1/users/$username';
    final url = 'https://api.redgifs.com/v1/users/$cleanUsername';
    final response = await get(url);

    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // Fetch GIFs uploaded by a specific user (creator feed)
  Future<Map<String, dynamic>> getUserGifs(String username, {String type = 'g', int limit = 20, int page = 1, bool bypassCache = false}) async {
    final cleanUsername = username.trim().toLowerCase();
    // final cacheKey = 'user_gifs_${username}_type_${type}_page_${page}_limit_$limit';
    final cacheKey = 'user_gifs_${cleanUsername}_type_${type}_page_${page}_limit_$limit';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(minutes: 10));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    // final url = '${ApiConstants.usersEndpoint}/$username/search?count=$limit&page=$page&type=$type';
    final url = '${ApiConstants.usersEndpoint}/$cleanUsername/search?count=$limit&page=$page&type=$type';
    final response = await get(url);

    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user content: ${response.statusCode}');
    }
  }

  // Fetch explore feed (GIFs or Images)
  Future<Map<String, dynamic>> getExploreFeed({
    required String type, // 'g' for gifs, 'i' for images
    int limit = 20,
    int page = 1,
    String order = 'trending',
    String? time,
    bool bypassCache = false,
  }) async {
    // final cacheKey = 'explore_${type}_${order}_${time ?? "all"}_page_${page}_limit_${limit}';
    final cacheKey = 'explore_${type}_${order}_${time ?? "all"}_page_${page}_limit_$limit';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(minutes: 10));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    var url = '${ApiConstants.searchEndpoint}?type=$type&order=$order&count=$limit&page=$page&verified=y';
    if (time != null) {
      url += '&time=$time';
    }

    final response = await get(url);
    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load explore feed: ${response.statusCode}');
    }
  }

  // Fetch creator search results
  Future<Map<String, dynamic>> searchCreators({
    String? query,
    int limit = 20,
    int page = 1,
    String order = 'trending',
    String? time,
    bool bypassCache = false,
  }) async {
    final cacheKey = 'creators_${query ?? ""}_${order}_${time ?? "all"}_page_${page}_limit_$limit';
    if (!bypassCache) {
      final cached = await _isarService.readCache(cacheKey, maxAge: const Duration(minutes: 10));
      if (cached != null) {
        return jsonDecode(cached) as Map<String, dynamic>;
      }
    }

    var url = '${ApiConstants.baseUrl}/creators/search?order=$order&count=$limit&page=$page';
    if (query != null && query.isNotEmpty) {
      url += '&query=${Uri.encodeComponent(query)}';
    } else {
      url += '&verified=y';
    }
    if (time != null) {
      url += '&time=$time';
    }

    final response = await get(url);
    if (response.statusCode == 200) {
      await _isarService.writeCache(cacheKey, response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to search creators: ${response.statusCode}');
    }
  }
}
