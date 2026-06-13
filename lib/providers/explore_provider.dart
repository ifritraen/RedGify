import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gif_info.dart';
import '../models/user_info.dart';
import '../models/niche_info.dart';
import '../services/api_client.dart';
import '../services/isar_service.dart';

class ExploreProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  ExploreProvider() {
    loadCachedTags();
  }

  // --- GIFs State ---
  final List<GifInfo> _gifs = [];
  bool _isLoadingGifs = false;
  int _gifPage = 1;
  bool _hasMoreGifs = true;
  String? _gifError;
  String _gifOrder = 'trending'; // trending, top, latest
  String? _gifTime; // week, month, null (all)

  List<GifInfo> get gifs => _gifs;
  bool get isLoadingGifs => _isLoadingGifs;
  bool get hasMoreGifs => _hasMoreGifs;
  String? get gifError => _gifError;
  String get gifOrder => _gifOrder;
  String? get gifTime => _gifTime;

  // --- Images State ---
  final List<GifInfo> _images = [];
  bool _isLoadingImages = false;
  int _imagePage = 1;
  bool _hasMoreImages = true;
  String? _imageError;
  String _imageOrder = 'trending'; // trending, top, latest
  String? _imageTime; // week, month, null (all)

  List<GifInfo> get images => _images;
  bool get isLoadingImages => _isLoadingImages;
  bool get hasMoreImages => _hasMoreImages;
  String? get imageError => _imageError;
  String get imageOrder => _imageOrder;
  String? get imageTime => _imageTime;

  // --- Creators State ---
  final List<UserInfo> _creators = [];
  bool _isLoadingCreators = false;
  int _creatorPage = 1;
  bool _hasMoreCreators = true;
  String? _creatorError;
  String _creatorOrder = 'trending'; // trending, top, latest
  String? _creatorTime; // week, month, null (all)

  List<UserInfo> get creators => _creators;
  bool get isLoadingCreators => _isLoadingCreators;
  bool get hasMoreCreators => _hasMoreCreators;
  String? get creatorError => _creatorError;
  String get creatorOrder => _creatorOrder;
  String? get creatorTime => _creatorTime;

  // --- Niches State ---
  List<NicheInfo> _niches = [];
  bool _isLoadingNiches = false;
  String? _nichesError;
  String? _selectedNicheId;
  final List<GifInfo> _nicheGifs = [];
  bool _isLoadingNicheGifs = false;
  int _nicheGifsPage = 1;
  bool _hasMoreNicheGifs = true;
  String? _nicheGifsError;
  String _nicheOrder = 'hot'; // hot, latest, top

  List<NicheInfo> get niches => _niches;
  bool get isLoadingNiches => _isLoadingNiches;
  String? get nichesError => _nichesError;
  String? get selectedNicheId => _selectedNicheId;
  List<GifInfo> get nicheGifs => _nicheGifs;
  bool get isLoadingNicheGifs => _isLoadingNicheGifs;
  bool get hasMoreNicheGifs => _hasMoreNicheGifs;
  String? get nicheGifsError => _nicheGifsError;
  String get nicheOrder => _nicheOrder;

  // --- Tags State ---
  List<dynamic> _tags = [];
  bool _isLoadingTags = false;
  String? _tagsError;

  List<dynamic> get tags => _tags;
  bool get isLoadingTags => _isLoadingTags;
  String? get tagsError => _tagsError;

  // ==========================================
  // 1. GIFs Actions
  // ==========================================
  Future<void> fetchNextGifsPage({bool bypassCache = false}) async {
    if (_isLoadingGifs || !_hasMoreGifs) return;
    _isLoadingGifs = true;
    _gifError = null;
    notifyListeners();

    try {
      final data = await _apiClient.getExploreFeed(
        type: 'g',
        page: _gifPage,
        order: _gifOrder,
        time: _gifTime,
        bypassCache: bypassCache,
      );
      final raw = data['gifs'] as List? ?? [];
      final list = raw.map((x) => GifInfo.fromJson(x)).toList();

      final existingIds = _gifs.map((g) => g.id).toSet();
      final uniqueList = list.where((g) => !existingIds.contains(g.id)).toList();

      if (list.isEmpty) {
        _hasMoreGifs = false;
      } else {
        _gifs.addAll(uniqueList);
        collectTagsFromGifs(uniqueList);
        _gifPage++;
      }
    } catch (e) {
      _gifError = e.toString();
    } finally {
      _isLoadingGifs = false;
      notifyListeners();
    }
  }

  Future<void> setGifFilters({required String order, String? time}) async {
    if (_gifOrder == order && _gifTime == time) return;
    _gifOrder = order;
    _gifTime = time;
    _gifs.clear();
    _gifPage = 1;
    _hasMoreGifs = true;
    _gifError = null;
    notifyListeners();
    await fetchNextGifsPage();
  }

  Future<void> refreshGifs() async {
    await IsarService().clearCachePrefix('explore_g_${_gifOrder}_${_gifTime ?? "all"}_page_');
    _gifs.clear();
    _gifPage = 1;
    _hasMoreGifs = true;
    _gifError = null;
    notifyListeners();
    await fetchNextGifsPage(bypassCache: true);
  }

  // ==========================================
  // 2. Images Actions
  // ==========================================
  Future<void> fetchNextImagesPage({bool bypassCache = false}) async {
    if (_isLoadingImages || !_hasMoreImages) return;
    _isLoadingImages = true;
    _imageError = null;
    notifyListeners();

    try {
      final data = await _apiClient.getExploreFeed(
        type: 'i',
        page: _imagePage,
        order: _imageOrder,
        time: _imageTime,
        bypassCache: bypassCache,
      );
      final raw = data['gifs'] as List? ?? [];
      final list = raw.map((x) => GifInfo.fromJson(x)).toList();

      final existingIds = _images.map((g) => g.id).toSet();
      final uniqueList = list.where((g) => !existingIds.contains(g.id)).toList();

      if (list.isEmpty) {
        _hasMoreImages = false;
      } else {
        _images.addAll(uniqueList);
        collectTagsFromGifs(uniqueList);
        _imagePage++;
      }
    } catch (e) {
      _imageError = e.toString();
    } finally {
      _isLoadingImages = false;
      notifyListeners();
    }
  }

  Future<void> setImageFilters({required String order, String? time}) async {
    if (_imageOrder == order && _imageTime == time) return;
    _imageOrder = order;
    _imageTime = time;
    _images.clear();
    _imagePage = 1;
    _hasMoreImages = true;
    _imageError = null;
    notifyListeners();
    await fetchNextImagesPage();
  }

  Future<void> refreshImages() async {
    await IsarService().clearCachePrefix('explore_i_${_imageOrder}_${_imageTime ?? "all"}_page_');
    _images.clear();
    _imagePage = 1;
    _hasMoreImages = true;
    _imageError = null;
    notifyListeners();
    await fetchNextImagesPage(bypassCache: true);
  }

  // ==========================================
  // 3. Creators Actions
  // ==========================================
  Future<void> fetchNextCreatorsPage({bool bypassCache = false}) async {
    if (_isLoadingCreators || !_hasMoreCreators) return;
    _isLoadingCreators = true;
    _creatorError = null;
    notifyListeners();

    try {
      final data = await _apiClient.searchCreators(
        page: _creatorPage,
        order: _creatorOrder,
        time: _creatorTime,
        bypassCache: bypassCache,
      );
      final raw = data['items'] as List? ?? [];
      final list = raw.map((x) => UserInfo.fromJson(x)).toList();

      final existingUsernames = _creators.map((c) => c.username).toSet();
      final uniqueList = list.where((c) => !existingUsernames.contains(c.username)).toList();

      if (list.isEmpty) {
        _hasMoreCreators = false;
      } else {
        _creators.addAll(uniqueList);
        _creatorPage++;
      }
    } catch (e) {
      _creatorError = e.toString();
    } finally {
      _isLoadingCreators = false;
      notifyListeners();
    }
  }

  Future<void> setCreatorFilters({required String order, String? time}) async {
    if (_creatorOrder == order && _creatorTime == time) return;
    _creatorOrder = order;
    _creatorTime = time;
    _creators.clear();
    _creatorPage = 1;
    _hasMoreCreators = true;
    _creatorError = null;
    notifyListeners();
    await fetchNextCreatorsPage();
  }

  Future<void> refreshCreators() async {
    await IsarService().clearCachePrefix('creators_${_creatorOrder}_${_creatorTime ?? "all"}_page_');
    _creators.clear();
    _creatorPage = 1;
    _hasMoreCreators = true;
    _creatorError = null;
    notifyListeners();
    await fetchNextCreatorsPage(bypassCache: true);
  }

  // ==========================================
  // 4. Niches Actions
  // ==========================================
  Future<void> fetchNichesList() async {
    if (_niches.isNotEmpty) return;
    _isLoadingNiches = true;
    _nichesError = null;
    notifyListeners();

    try {
      final data = await _apiClient.getNiches();
      final raw = data['niches'] as List? ?? [];
      _niches = raw.map((x) => NicheInfo.fromJson(x)).toList();
    } catch (e) {
      _nichesError = e.toString();
    } finally {
      _isLoadingNiches = false;
      notifyListeners();
    }
  }

  Future<void> selectNiche(String nicheId) async {
    _selectedNicheId = nicheId;
    _nicheGifs.clear();
    _nicheGifsPage = 1;
    _hasMoreNicheGifs = true;
    _nicheGifsError = null;
    notifyListeners();
    await fetchNextNicheGifsPage();
  }

  Future<void> setNicheOrder(String order) async {
    if (_nicheOrder == order) return;
    _nicheOrder = order;
    if (_selectedNicheId != null) {
      _nicheGifs.clear();
      _nicheGifsPage = 1;
      _hasMoreNicheGifs = true;
      _nicheGifsError = null;
      notifyListeners();
      await fetchNextNicheGifsPage();
    }
  }

  Future<void> fetchNextNicheGifsPage({bool bypassCache = false}) async {
    if (_selectedNicheId == null || _isLoadingNicheGifs || !_hasMoreNicheGifs) return;
    _isLoadingNicheGifs = true;
    _nicheGifsError = null;
    notifyListeners();

    try {
      final data = await _apiClient.getNicheGifs(
        _selectedNicheId!,
        page: _nicheGifsPage,
        order: _nicheOrder,
        bypassCache: bypassCache,
      );
      final raw = data['gifs'] as List? ?? [];
      final list = raw.map((x) => GifInfo.fromJson(x)).toList();

      final existingIds = _nicheGifs.map((g) => g.id).toSet();
      final uniqueList = list.where((g) => !existingIds.contains(g.id)).toList();

      if (list.isEmpty) {
        _hasMoreNicheGifs = false;
      } else {
        _nicheGifs.addAll(uniqueList);
        collectTagsFromGifs(uniqueList);
        _nicheGifsPage++;
      }
    } catch (e) {
      _nicheGifsError = e.toString();
    } finally {
      _isLoadingNicheGifs = false;
      notifyListeners();
    }
  }

  Future<void> refreshNicheGifs() async {
    if (_selectedNicheId == null) return;
    await IsarService().clearCachePrefix('niche_${_selectedNicheId}_${_nicheOrder}_page_');
    _nicheGifs.clear();
    _nicheGifsPage = 1;
    _hasMoreNicheGifs = true;
    _nicheGifsError = null;
    notifyListeners();
    await fetchNextNicheGifsPage(bypassCache: true);
  }

  Future<File> get _localTagsFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tags_cache.json');
  }

  Future<void> loadCachedTags() async {
    try {
      final file = await _localTagsFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List decoded = json.decode(content);
        _tags = List<dynamic>.from(decoded);
        _sortTags();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> saveCachedTags() async {
    try {
      final file = await _localTagsFile;
      final content = json.encode(_tags);
      await file.writeAsString(content);
    } catch (_) {}
  }

  void _sortTags() {
    _tags.sort((a, b) {
      final aName = (a['name'] as String? ?? '').toLowerCase();
      final bName = (b['name'] as String? ?? '').toLowerCase();
      return aName.compareTo(bName);
    });
  }

  void mergeTags(List<dynamic> newTags) {
    final Map<String, dynamic> merged = {};
    for (var tag in _tags) {
      final name = tag['name'] as String? ?? '';
      if (name.isNotEmpty) {
        merged[name.toLowerCase()] = tag;
      }
    }
    
    for (var tag in newTags) {
      final name = tag['name'] as String? ?? '';
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (merged.containsKey(key)) {
        final currentCount = merged[key]['count'] as int? ?? 0;
        final newCount = tag['count'] as int? ?? 0;
        if (newCount > currentCount) {
          merged[key]['count'] = newCount;
        }
      } else {
        merged[key] = {
          'name': name,
          'count': tag['count'] ?? 0,
        };
      }
    }
    
    _tags = merged.values.toList();
    _sortTags();
    saveCachedTags();
  }

  static Future<void> collectAndSaveTags(List<GifInfo> gifs) async {
    if (gifs.isEmpty) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tags_cache.json');
      List<dynamic> cached = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        cached = List<dynamic>.from(json.decode(content));
      }
      
      final Map<String, dynamic> merged = {};
      for (var tag in cached) {
        final name = tag['name'] as String? ?? '';
        if (name.isNotEmpty) {
          merged[name.toLowerCase()] = tag;
        }
      }
      
      for (var gif in gifs) {
        for (var tagName in gif.tags) {
          if (tagName.isEmpty) continue;
          final key = tagName.toLowerCase();
          if (!merged.containsKey(key)) {
            merged[key] = {
              'name': tagName,
              'count': 0,
            };
          }
        }
      }
      
      final list = merged.values.toList();
      list.sort((a, b) {
        final aName = (a['name'] as String? ?? '').toLowerCase();
        final bName = (b['name'] as String? ?? '').toLowerCase();
        return aName.compareTo(bName);
      });
      
      await file.writeAsString(json.encode(list));
    } catch (_) {}
  }

  Future<void> collectTagsFromGifs(List<GifInfo> gifs) async {
    await collectAndSaveTags(gifs);
    await loadCachedTags();
  }

  Map<String, List<Map<String, dynamic>>> get groupedTags {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (var char in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      groups[char] = [];
    }
    groups['#'] = [];
    
    for (var tag in _tags) {
      final name = tag['name'] as String? ?? '';
      if (name.isEmpty) continue;
      final firstChar = name[0].toUpperCase();
      if (groups.containsKey(firstChar)) {
        groups[firstChar]!.add(Map<String, dynamic>.from(tag));
      } else {
        groups['#']!.add(Map<String, dynamic>.from(tag));
      }
    }
    
    groups.removeWhere((key, list) => list.isEmpty);
    return groups;
  }

  Future<void> fetchTrendingTags({bool bypassCache = false}) async {
    _isLoadingTags = true;
    _tagsError = null;
    notifyListeners();

    try {
      await loadCachedTags();
      final newTags = await _apiClient.getTrendingTags(bypassCache: bypassCache);
      mergeTags(newTags);
    } catch (e) {
      _tagsError = e.toString();
    } finally {
      _isLoadingTags = false;
      notifyListeners();
    }
  }
}
