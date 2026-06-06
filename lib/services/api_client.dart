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

  // Fetch trending/popular GIFs feed
  Future<Map<String, dynamic>> getTrendingFeed({int limit = 20, int page = 1}) async {
    final url = '${ApiConstants.trendingGifsEndpoint}?limit=$limit&page=$page';
    final response = await get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load trending feed: ${response.statusCode}');
    }
  }
}
