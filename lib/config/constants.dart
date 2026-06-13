class ApiConstants {
  static const String baseUrl = 'https://api.redgifs.com/v2';
  static const String authTemporaryEndpoint = '$baseUrl/auth/temporary';
  static const String searchEndpoint = '$baseUrl/gifs/search';
  static const String trendingGifsEndpoint = '$baseUrl/explore/trending-gifs';
  static const String nichesEndpoint = '$baseUrl/niches';
  static const String tagsEndpoint = '$baseUrl/tags';
  static const String trendingTagsEndpoint = '$baseUrl/tags/trending';
  static const String usersEndpoint = '$baseUrl/users';
  
  // Custom headers to bypass simple bot checks
  static const Map<String, String> baseHeaders = {
    'Accept': 'application/json',
    'Origin': 'https://www.redgifs.com',
    'Referer': 'https://www.redgifs.com/',
  };
  
  // Custom User Agent to satisfy JWT device binding
  static const String defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
}
