import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class TokenManager {
  final _secureStorage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'redgifs_jwt_token';
  static const String _uaKey = 'redgifs_user_agent';

  // Retrieve cached token
  Future<String?> getCachedToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Retrieve the cached or default User-Agent
  Future<String> getUserAgent() async {
    final cachedUa = await _secureStorage.read(key: _uaKey);
    return cachedUa ?? ApiConstants.defaultUserAgent;
  }

  // Fetch a new temporary token
  Future<String> fetchNewToken() async {
    final userAgent = ApiConstants.defaultUserAgent; // Keep it static to ensure alignment
    final headers = {
      ...ApiConstants.baseHeaders,
      'User-Agent': userAgent,
    };

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.authTemporaryEndpoint),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        final token = payload['token'] as String;

        // Cache both User-Agent and JWT securely
        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _uaKey, value: userAgent);
        return token;
      } else {
        throw Exception('Failed to get temporary token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to request temporary token from server: $e');
    }
  }

  // Get valid token (cached or fresh)
  Future<String> getValidToken() async {
    final cached = await getCachedToken();
    if (cached != null) {
      return cached;
    }
    return await fetchNewToken();
  }

  // Clear cached token if expired (forcing refresh)
  Future<void> invalidateToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
