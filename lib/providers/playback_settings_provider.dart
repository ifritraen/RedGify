import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum PlaybackAction {
  playOnceAndNext,    // Play once and autoplay next (if autoplay next is on)
  repeatXAndNext,     // Repeat X times and autoplay next (if autoplay next is on)
  repeatXAndPause,    // Repeat X times and pause
}

class PlaybackSettingsProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();

  bool _autoplayNext = true;
  bool _shuffleEnabled = false;
  bool _repeatSingle = false;
  int _repeatLimit = 10;
  PlaybackAction _playbackAction = PlaybackAction.playOnceAndNext;
  int _gridColumns = 2;

  bool get autoplayNext => _autoplayNext;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get repeatSingle => _repeatSingle;
  int get repeatLimit => _repeatLimit;
  PlaybackAction get playbackAction => _playbackAction;
  int get gridColumns => _gridColumns;

  PlaybackSettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final autoplayStr = await _secureStorage.read(key: 'play_autoplay_next');
      final shuffleStr = await _secureStorage.read(key: 'play_shuffle_enabled');
      final repeatSingleStr = await _secureStorage.read(key: 'play_repeat_single');
      final limitStr = await _secureStorage.read(key: 'play_repeat_limit');
      final actionStr = await _secureStorage.read(key: 'play_playback_action');
      final columnsStr = await _secureStorage.read(key: 'play_grid_columns');

      if (autoplayStr != null) _autoplayNext = autoplayStr == 'true';
      if (shuffleStr != null) _shuffleEnabled = shuffleStr == 'true';
      if (repeatSingleStr != null) _repeatSingle = repeatSingleStr == 'true';
      if (limitStr != null) _repeatLimit = int.tryParse(limitStr) ?? 10;
      if (actionStr != null) {
        final index = int.tryParse(actionStr) ?? 0;
        _playbackAction = PlaybackAction.values[index.clamp(0, PlaybackAction.values.length - 1)];
      }
      if (columnsStr != null) _gridColumns = int.tryParse(columnsStr) ?? 2;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setAutoplayNext(bool value) async {
    _autoplayNext = value;
    notifyListeners();
    try {
      await _secureStorage.write(key: 'play_autoplay_next', value: value.toString());
    } catch (_) {}
  }

  Future<void> setShuffleEnabled(bool value) async {
    _shuffleEnabled = value;
    notifyListeners();
    try {
      await _secureStorage.write(key: 'play_shuffle_enabled', value: value.toString());
    } catch (_) {}
  }

  Future<void> setRepeatSingle(bool value) async {
    _repeatSingle = value;
    notifyListeners();
    try {
      await _secureStorage.write(key: 'play_repeat_single', value: value.toString());
    } catch (_) {}
  }

  Future<void> setRepeatLimit(int value) async {
    _repeatLimit = value.clamp(1, 10);
    notifyListeners();
    try {
      await _secureStorage.write(key: 'play_repeat_limit', value: _repeatLimit.toString());
    } catch (_) {}
  }

  Future<void> setPlaybackAction(PlaybackAction value) async {
    _playbackAction = value;
    notifyListeners();
    try {
      await _secureStorage.write(key: 'play_playback_action', value: value.index.toString());
    } catch (_) {}
  }

  Future<void> toggleGridColumns() async {
    _gridColumns = _gridColumns == 2 ? 1 : 2;
    notifyListeners();
    try {
      await _secureStorage.write(key: 'play_grid_columns', value: _gridColumns.toString());
    } catch (_) {}
  }
}
