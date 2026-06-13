import 'package:flutter/material.dart';
import '../models/gif_info.dart';

class PlaybackQueueProvider with ChangeNotifier {
  List<GifInfo> _queue = [];
  int _currentIndex = 0;
  bool _showQueueSidebar = false;

  List<GifInfo> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get showQueueSidebar => _showQueueSidebar;

  void setQueue(List<GifInfo> list, int index) {
    _queue = List.from(list);
    _currentIndex = index.clamp(0, _queue.isNotEmpty ? _queue.length - 1 : 0);
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void toggleQueueSidebar() {
    _showQueueSidebar = !_showQueueSidebar;
    notifyListeners();
  }

  void setQueueSidebarVisible(bool visible) {
    _showQueueSidebar = visible;
    notifyListeners();
  }

  void removeVideo(int index, BuildContext context) {
    if (index < 0 || index >= _queue.length) return;

    if (_queue.length == 1) {
      _queue.clear();
      _currentIndex = 0;
      _showQueueSidebar = false;
      notifyListeners();
      Navigator.of(context).pop();
      return;
    }

    _queue.removeAt(index);

    if (_currentIndex == index) {
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
    notifyListeners();
  }

  void reorderVideos(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final GifInfo item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);

    // Maintain current index reference
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex -= 1;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex += 1;
    }
    notifyListeners();
  }
}
