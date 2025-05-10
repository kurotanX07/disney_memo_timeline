import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/memo.dart';
import '../models/photo.dart';
import '../services/database.dart';
import '../services/map_service.dart';

enum ViewMode { past, plan }

class MemoProvider with ChangeNotifier {
  List<Memo> _memos = [];
  List<Memo> _filteredMemos = [];
  ViewMode _viewMode = ViewMode.past;
  String? _searchQuery;
  String? _areaFilter;
  bool _todoOnly = false;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Memo> get memos => _filteredMemos;
  ViewMode get viewMode => _viewMode;
  String? get searchQuery => _searchQuery;
  String? get areaFilter => _areaFilter;
  bool get todoOnly => _todoOnly;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  MemoProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await loadMemos();
    applyFilters();
  }

  Future<void> loadMemos() async {
    _memos = await DatabaseService.instance.getAllMemos();
    applyFilters();
  }

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    applyFilters();
    notifyListeners();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.past ? ViewMode.plan : ViewMode.past;
    applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    applyFilters();
    notifyListeners();
  }

  void setAreaFilter(String? area) {
    _areaFilter = area;
    applyFilters();
    notifyListeners();
  }

  void setTodoOnly(bool value) {
    _todoOnly = value;
    applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    applyFilters();
    notifyListeners();
  }

  void applyFilters() {
    // Start with all memos
    _filteredMemos = List.from(_memos);

    // Filter by view mode
    if (_viewMode == ViewMode.past) {
      _filteredMemos = _filteredMemos.where((memo) => memo.isPast()).toList();
    } else {
      _filteredMemos = _filteredMemos.where((memo) => memo.isPlan()).toList();
    }

    // Filter by date range if specified
    if (_startDate != null && _endDate != null) {
      _filteredMemos = _filteredMemos.where((memo) {
        return (memo.dateTime.isAfter(_startDate!) ||
                memo.dateTime.isAtSameMomentAs(_startDate!)) &&
            (memo.dateTime.isBefore(_endDate!) ||
                memo.dateTime.isAtSameMomentAs(_endDate!));
      }).toList();
    }

    // Filter by area if specified
    if (_areaFilter != null && _areaFilter!.isNotEmpty) {
      _filteredMemos =
          _filteredMemos.where((memo) => memo.areaName == _areaFilter).toList();
    }

    // Filter by todo flag if enabled
    if (_todoOnly) {
      _filteredMemos = _filteredMemos.where((memo) => memo.isTodo).toList();
    }

    // Filter by search query if specified
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      _filteredMemos = _filteredMemos.where((memo) {
        return memo.title.toLowerCase().contains(query) ||
            memo.content.toLowerCase().contains(query) ||
            memo.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Sort by date
    if (_viewMode == ViewMode.past) {
      _filteredMemos.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } else {
      _filteredMemos.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }
  }

  Future<Memo> addMemo({
    required String title,
    String content = '',
    List<String> tags = const [],
    required DateTime dateTime,
    required double latitude,
    required double longitude,
    String? areaName,
    bool isTodo = false,
  }) async {
    // If area name is not provided, find the nearest location
    final String area = areaName ??
        MapService.instance.getNearestLocation(latitude, longitude)?.area ??
        'Unknown';

    final memo = Memo(
      title: title,
      content: content,
      tags: tags,
      dateTime: dateTime,
      latitude: latitude,
      longitude: longitude,
      areaName: area,
      isTodo: isTodo,
    );

    await DatabaseService.instance.insertMemo(memo);
    await loadMemos();
    return memo;
  }

  Future<void> updateMemo(Memo memo) async {
    await DatabaseService.instance.updateMemo(memo);
    await loadMemos();
  }

  Future<void> deleteMemo(String id) async {
    await DatabaseService.instance.deleteMemo(id);
    await loadMemos();
  }

  Future<Photo> addPhotoToMemo({
    required String memoId,
    required XFile imageFile,
    DateTime? dateTime,
  }) async {
    // Create photos directory if it doesn't exist
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(appDir.path, 'DisneyMemoAlbum', 'Photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'photo_${memoId}_$timestamp.jpg';
    final savedImagePath = join(photosDir.path, fileName);

    // Copy image file to app's photos directory
    final imageBytes = await imageFile.readAsBytes();
    await File(savedImagePath).writeAsBytes(imageBytes);

    // Create photo object
    final photo = Photo(
      path: savedImagePath,
      dateTime: dateTime ?? DateTime.now(),
      memoId: memoId,
    );

    // Save to database
    await DatabaseService.instance.insertPhoto(photo);
    await loadMemos();

    return photo;
  }

  Future<void> deletePhoto(String photoId) async {
    await DatabaseService.instance.deletePhoto(photoId);
    await loadMemos();
  }

  Future<List<Photo>> getPhotosForMemo(String memoId) async {
    return await DatabaseService.instance.getPhotosByMemoId(memoId);
  }

  // Quick camera functionality for Plan view
  Future<Memo?> quickCapture({
    required double latitude,
    required double longitude,
    required XFile imageFile,
  }) async {
    try {
      // Find nearest location
      final location =
          MapService.instance.getNearestLocation(latitude, longitude);
      if (location == null) return null;

      // Create memo with location info
      final memo = await addMemo(
        title: '${location.name} Quick Capture',
        dateTime: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        areaName: location.area,
      );

      // Add photo to memo
      await addPhotoToMemo(
        memoId: memo.id,
        imageFile: imageFile,
      );

      return memo;
    } catch (e) {
      print('Error in quick capture: $e');
      return null;
    }
  }
}
