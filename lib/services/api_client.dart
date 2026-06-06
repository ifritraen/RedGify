import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'token_manager.dart';

class ApiClient {
  final TokenManager _tokenManager = TokenManager();

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

  // Fetch search results
  Future<Map<String, dynamic>> searchGifs(String query, {int limit = 20, int page = 1}) async {
    final url = '${ApiConstants.searchEndpoint}?search_text=${Uri.encodeComponent(query)}&limit=$limit&page=$page';
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to query search: ${response.statusCode}');
    }
  }

  // Fetch trending/popular/recent GIFs feed
  Future<Map<String, dynamic>> getTrendingFeed({int limit = 20, int page = 1, String order = 'trending'}) async {
    final url = '${ApiConstants.trendingGifsEndpoint}?limit=$limit&page=$page&order=$order';
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load feed ($order): ${response.statusCode}');
    }
  }

  // Fetch all Niches list
  Future<Map<String, dynamic>> getNiches() async {
    const url = ApiConstants.nichesEndpoint;
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch niches list: ${response.statusCode}');
    }
  }

  // Fetch Gifs for a specific niche
  Future<Map<String, dynamic>> getNicheGifs(String nicheId, {int limit = 20, int page = 1, String order = 'trending'}) async {
    final url = '${ApiConstants.nichesEndpoint}/$nicheId/gifs?limit=$limit&page=$page&order=$order';
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load niche gifs: ${response.statusCode}');
    }
  }

  // Fetch trending tags list
  Future<List<dynamic>> getTrendingTags() async {
    const url = ApiConstants.trendingTagsEndpoint;
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load trending tags: ${response.statusCode}');
    }
  }
  // Fetch user profile metadata
  Future<Map<String, dynamic>> getUserProfile(String username) async {
    final url = '${ApiConstants.usersEndpoint}/$username';
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  // Fetch GIFs uploaded by a specific user (creator feed)
  Future<Map<String, dynamic>> getUserGifs(String username, {int limit = 20, int page = 1}) async {
    final url = '${ApiConstants.usersEndpoint}/$username/search?limit=$limit&page=$page';
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user content: ${response.statusCode}');
    }
  }
}
