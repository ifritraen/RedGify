import 'package:flutter/material.dart';
import '../models/niche_info.dart';
import '../models/gif_info.dart';
import '../services/api_client.dart';

class NichesProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NicheInfo> _niches = [];
  bool _isLoadingNiches = false;
  String? _nichesError;

  // Selected niche feed state
  String? _selectedNicheId;
  String _activeOrder = 'trending';
  final List<GifInfo> _nicheGifs = [];
  bool _isLoadingGifs = false;
  int _currentGifsPage = 1;
  bool _hasMoreGifs = true;
  String? _gifsError;

  List<NicheInfo> get niches => _niches;
  bool get isLoadingNiches => _isLoadingNiches;
  String? get nichesError => _nichesError;

  String? get selectedNicheId => _selectedNicheId;
  String get activeOrder => _activeOrder;
  List<GifInfo> get nicheGifs => _nicheGifs;
  bool get isLoadingGifs => _isLoadingGifs;
  bool get hasMoreGifs => _hasMoreGifs;
  String? get gifsError => _gifsError;

  // Set sorting order
  void setOrder(String order) {
    if (_activeOrder == order) return;
    _activeOrder = order;
    if (_selectedNicheId != null) {
      _nicheGifs.clear();
      _currentGifsPage = 1;
      _hasMoreGifs = true;
      _gifsError = null;
      notifyListeners();
      fetchNextNicheGifsPage();
    }
  }

  // Fetch list of niches
  Future<void> fetchNichesList() async {
    if (_niches.isNotEmpty) return;
    _isLoadingNiches = true;
    _nichesError = null;
    notifyListeners();

    try {
      final data = await _apiClient.getNiches();
      final rawNiches = data['niches'] as List? ?? [];
      _niches = rawNiches.map((n) => NicheInfo.fromJson(n)).toList();
    } catch (e) {
      _nichesError = e.toString();
    } finally {
      _isLoadingNiches = false;
      notifyListeners();
    }
  }

  // Set active niche and fetch initial gifs
  Future<void> selectNiche(String nicheId) async {
    _selectedNicheId = nicheId;
    _nicheGifs.clear();
    _currentGifsPage = 1;
    _hasMoreGifs = true;
    _gifsError = null;
    notifyListeners();

    await fetchNextNicheGifsPage();
  }

  // Load next page of selected niche gifs
  Future<void> fetchNextNicheGifsPage() async {
    if (_selectedNicheId == null || _isLoadingGifs || !_hasMoreGifs) return;

    _isLoadingGifs = true;
    _gifsError = null;
    notifyListeners();

    try {
      final data = await _apiClient.getNicheGifs(
        _selectedNicheId!,
        page: _currentGifsPage,
        order: _activeOrder,
      );
      final rawGifs = data['gifs'] as List? ?? [];
      final newGifs = rawGifs.map((g) => GifInfo.fromJson(g)).toList();

      if (newGifs.isEmpty) {
        _hasMoreGifs = false;
      } else {
        _nicheGifs.addAll(newGifs);
        _currentGifsPage++;
      }
    } catch (e) {
      _gifsError = e.toString();
    } finally {
      _isLoadingGifs = false;
      notifyListeners();
    }
  }

  // Refresh current niche feed
  Future<void> refreshSelectedNiche() async {
    if (_selectedNicheId == null) return;
    _nicheGifs.clear();
    _currentGifsPage = 1;
    _hasMoreGifs = true;
    _gifsError = null;
    await fetchNextNicheGifsPage();
  }
}
