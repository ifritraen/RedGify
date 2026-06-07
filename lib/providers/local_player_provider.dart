import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class LocalPlayerProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  static const String _storageKey = 'local_storage_root_path';

  String? _rootPath;
  String? _currentPath;
  final List<FileSystemEntity> _subFolders = [];
  final List<FileSystemEntity> _videoFiles = [];
  bool _isLoading = false;

  String? get rootPath => _rootPath;
  String? get currentPath => _currentPath;
  List<FileSystemEntity> get subFolders => _subFolders;
  List<FileSystemEntity> get videoFiles => _videoFiles;
  bool get isLoading => _isLoading;

  LocalPlayerProvider() {
    _loadStoredRoot();
  }

  Future<void> _loadStoredRoot() async {
    _isLoading = true;
    notifyListeners();

    try {
      _rootPath = await _storage.read(key: _storageKey);
      if (_rootPath != null && Directory(_rootPath!).existsSync()) {
        _currentPath = _rootPath;
        await _scanCurrentDirectory();
      } else {
        _rootPath = null;
        _currentPath = null;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectStorageRoot() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        _rootPath = selectedDirectory;
        _currentPath = selectedDirectory;
        await _storage.write(key: _storageKey, value: selectedDirectory);
        await _scanCurrentDirectory();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearStorageRoot() async {
    _rootPath = null;
    _currentPath = null;
    _subFolders.clear();
    _videoFiles.clear();
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }

  Future<void> navigateTo(String path) async {
    if (Directory(path).existsSync()) {
      _currentPath = path;
      _isLoading = true;
      notifyListeners();
      await _scanCurrentDirectory();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> navigateBack() async {
    if (_currentPath == null || _rootPath == null || _currentPath == _rootPath) return;
    final parentDir = Directory(_currentPath!).parent;
    if (parentDir.path != _currentPath) {
      await navigateTo(parentDir.path);
    }
  }

  bool get canNavigateBack {
    if (_currentPath == null || _rootPath == null) return false;
    // Normalize paths to compare accurately
    final current = p.canonicalize(_currentPath!);
    final root = p.canonicalize(_rootPath!);
    return current != root;
  }

  Future<void> _scanCurrentDirectory() async {
    if (_currentPath == null) return;
    _subFolders.clear();
    _videoFiles.clear();

    try {
      final dir = Directory(_currentPath!);
      final list = await dir.list().toList();

      for (var entity in list) {
        if (entity is Directory) {
          // Skip hidden directories (starting with '.')
          if (!p.basename(entity.path).startsWith('.')) {
            _subFolders.add(entity);
          }
        } else if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.mp4' || 
              ext == '.mkv' || 
              ext == '.mov' || 
              ext == '.webm' || 
              ext == '.3gp' || 
              ext == '.avi' || 
              ext == '.gif') {
            _videoFiles.add(entity);
          }
        }
      }

      // Sort alphabetically
      _subFolders.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
      _videoFiles.sort((a, b) => p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
    } catch (_) {}
  }
}
