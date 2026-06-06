import 'package:flutter/material.dart';
import '../models/gif_info.dart';

class SelectionProvider with ChangeNotifier {
  bool _isSelectionMode = false;
  final Set<GifInfo> _selectedGifs = {};

  bool get isSelectionMode => _isSelectionMode;
  List<GifInfo> get selectedGifs => _selectedGifs.toList();
  int get selectedCount => _selectedGifs.length;

  bool isSelected(String gifId) {
    return _selectedGifs.any((g) => g.id == gifId);
  }

  void enterSelectionMode(GifInfo initialGif) {
    _isSelectionMode = true;
    _selectedGifs.add(initialGif);
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedGifs.clear();
    notifyListeners();
  }

  void toggleSelection(GifInfo gif) {
    final existing = _selectedGifs.any((g) => g.id == gif.id);
    if (existing) {
      _selectedGifs.removeWhere((g) => g.id == gif.id);
      if (_selectedGifs.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedGifs.add(gif);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedGifs.clear();
    notifyListeners();
  }
}
