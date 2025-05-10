import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_maplibre_gl/maplibre_gl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/memo_provider.dart';
import '../widgets/memo_card.dart';
import '../widgets/timeline_panel.dart';
import '../models/memo.dart';
import '../services/map_service.dart';
import 'memo_detail_screen.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MaplibreMapController? _mapController; // Mapboxから変更
  bool _isCameraMode = false;
  String? _selectedMemoId;

  // Tokyo Disney Resort coordinates
  static const LatLng _center = LatLng(35.6329, 139.8804);
  static const double _initialZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await MapService.instance.loadLocations();
    await Provider.of<MemoProvider>(context, listen: false).loadMemos();
  }

  @override
  Widget build(BuildContext context) {
    final memoProvider = Provider.of<MemoProvider>(context);
    final viewMode = memoProvider.viewMode;
    final memos = memoProvider.memos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disney Memo Timeline'),
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(viewMode == ViewMode.past
                ? Icons.history
                : Icons.calendar_today),
            onPressed: () {
              memoProvider.toggleViewMode();
              // Disable camera mode when switching to Past view
              if (memoProvider.viewMode == ViewMode.past && _isCameraMode) {
                setState(() {
                  _isCameraMode = false;
                });
              }
            },
            tooltip: viewMode == ViewMode.past
                ? 'Currently in Past view'
                : 'Currently in Plan view',
          ),
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map - MapLibre版に変更
          MaplibreMap(
            // accessTokenは不要なので削除
            styleString:
                'https://demotiles.maplibre.org/style.json', // オープンな地図スタイル
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: _initialZoom,
            ),
            onMapCreated: _onMapCreated,
            onMapClick: _onMapClick,
            minMaxZoomPreference: const MinMaxZoomPreference(10, 19),
          ),

          // Timeline panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TimelinePanel(
              memos: memos,
              onMemoSelected: _selectMemoOnMap,
            ),
          ),

          // Camera mode indicator
          if (_isCameraMode)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Quick Camera Mode - Tap on map to take photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildActionButton(memoProvider),
    );
  }

  Widget _buildActionButton(MemoProvider memoProvider) {
    // In Past view, only show the add memo button
    if (memoProvider.viewMode == ViewMode.past) {
      return FloatingActionButton(
        onPressed: () => _showAddMemoModal(null),
        child: const Icon(Icons.add),
        tooltip: 'Add Memo',
      );
    }

    // In Plan view, show camera toggle or add button
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick camera button - only in Plan view
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _isCameraMode = !_isCameraMode;
            });
          },
          heroTag: 'cameraBtn',
          backgroundColor: _isCameraMode ? Colors.red : null,
          child: Icon(
              _isCameraMode ? Icons.camera_alt : Icons.camera_alt_outlined),
          tooltip: _isCameraMode ? 'Exit Camera Mode' : 'Quick Camera Mode',
        ),
        const SizedBox(height: 16),
        // Add memo button
        FloatingActionButton(
          onPressed: () => _showAddMemoModal(null),
          heroTag: 'addBtn',
          child: const Icon(Icons.add),
          tooltip: 'Add Memo',
        ),
      ],
    );
  }

  void _onMapCreated(MaplibreMapController controller) {
    // Mapboxから変更
    _mapController = controller;

    // Add symbols for locations from MapService
    _addLocationMarkers();

    // Add existing memos to the map
    _updateMemoMarkers();
  }

  void _addLocationMarkers() async {
    if (_mapController == null) return;

    final locations = MapService.instance.locations;

    for (final location in locations) {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(location.latitude, location.longitude),
          iconImage: _getIconForLocationType(location.type),
          iconSize: 0.5,
          textField: location.name,
          textOffset: const Offset(0, 1.5),
          textSize: 12,
        ),
      );
    }
  }

  String _getIconForLocationType(String type) {
    // MapLibreでも使用可能な標準アイコン
    switch (type) {
      case 'attraction':
        return 'amusement-park-15';
      case 'restaurant':
        return 'restaurant-15';
      case 'shop':
        return 'shop-15';
      case 'hotel':
        return 'lodging-15';
      case 'station':
        return 'rail-15';
      default:
        return 'marker-15';
    }
  }

  Future<void> _updateMemoMarkers() async {
    if (_mapController == null) return;

    // Clear existing memo symbols
    final symbols = await _mapController!.symbols;
    for (final symbol in symbols) {
      if (symbol.data != null && symbol.data['type'] == 'memo') {
        await _mapController!.removeSymbol(symbol);
      }
    }

    // Add memo symbols
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    final memos = memoProvider.memos;

    for (final memo in memos) {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(memo.latitude, memo.longitude),
          iconImage: memo.isTodo ? 'marker-15' : 'circle-15',
          iconColor: memo.isTodo ? '#FF0000' : '#0000FF',
          iconSize: 1.2,
          textField: memo.title,
          textOffset: const Offset(0, 1.5),
          textSize: 12,
          textColor: '#000000',
        ),
        {
          'type': 'memo',
          'id': memo.id,
        },
      );
    }
  }

  void _onMapClick(Point<double> point, LatLng coordinates) async {
    // In camera mode, take a photo
    if (_isCameraMode) {
      _takeQuickPhoto(coordinates);
      return;
    }

    // Check if a memo was clicked
    final features =
        await _mapController?.queryRenderedFeatures(point, ['symbols'], null);

    if (features != null && features.isNotEmpty) {
      for (final feature in features) {
        if (feature.properties != null &&
            feature.properties!['type'] == 'memo' &&
            feature.properties!['id'] != null) {
          final memoId = feature.properties!['id'];
          _openMemoDetail(memoId);
          return;
        }
      }
    }

    // If no memo was clicked, show add memo modal
    _showAddMemoModal(coordinates);
  }

  void _takeQuickPhoto(LatLng coordinates) async {
    final imagePicker = ImagePicker();
    final imageFile = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (imageFile != null) {
      final memoProvider = Provider.of<MemoProvider>(context, listen: false);
      final memo = await memoProvider.quickCapture(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        imageFile: imageFile,
      );

      if (memo != null) {
        _updateMemoMarkers();

        // Show a confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quick capture saved: ${memo.title}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                _openMemoDetail(memo.id);
              },
            ),
          ),
        );
      }
    }
  }

  void _selectMemoOnMap(String memoId) async {
    if (_mapController == null) return;

    setState(() {
      _selectedMemoId = memoId;
    });

    // Find the memo
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    final memos = memoProvider.memos;
    final memo = memos.firstWhere((m) => m.id == memoId);

    // Fly to the memo location
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(memo.latitude, memo.longitude),
        16.0,
      ),
    );

    // Highlight the symbol
    final symbols = await _mapController!.symbols;
    for (final symbol in symbols) {
      if (symbol.data != null &&
          symbol.data['type'] == 'memo' &&
          symbol.data['id'] == memoId) {
        await _mapController!.updateSymbol(
          symbol,
          SymbolOptions(
            iconSize: 1.5,
            iconColor: '#FF9500',
          ),
        );
      } else if (symbol.data != null && symbol.data['type'] == 'memo') {
        // Reset other memo symbols
        final memo = memos.firstWhere((m) => m.id == symbol.data['id']);
        await _mapController!.updateSymbol(
          symbol,
          SymbolOptions(
            iconSize: 1.2,
            iconColor: memo.isTodo ? '#FF0000' : '#0000FF',
          ),
        );
      }
    }
  }

  void _openMemoDetail(String memoId) async {
    // Find the memo
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    final memos = memoProvider.memos;
    final memo = memos.firstWhere((m) => m.id == memoId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoDetailScreen(memo: memo),
      ),
    );

    // Update markers in case the memo was modified
    _updateMemoMarkers();
  }

  void _showAddMemoModal(LatLng? coordinates) {
    if (coordinates == null && _mapController != null) {
      // If no coordinates provided, use the center of the map
      coordinates = _mapController!.cameraPosition!.target;
    }

    if (coordinates == null) return;

    // Find nearest location name
    final location = MapService.instance
        .getNearestLocation(coordinates.latitude, coordinates.longitude);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _NewMemoForm(
          latitude: coordinates!.latitude,
          longitude: coordinates.longitude,
          initialArea: location?.area,
          onMemoAdded: () {
            _updateMemoMarkers();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _NewMemoForm extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? initialArea;
  final VoidCallback onMemoAdded;

  const _NewMemoForm({
    required this.latitude,
    required this.longitude,
    this.initialArea,
    required this.onMemoAdded,
  });

  @override
  _NewMemoFormState createState() => _NewMemoFormState();
}

class _NewMemoFormState extends State<_NewMemoForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late DateTime _selectedDate;
  bool _isTodo = false;
  List<XFile> _selectedImages = [];
  final _tagController = TextEditingController();
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final memoProvider = Provider.of<MemoProvider>(context);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Memo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Date: ${_formatDate(_selectedDate)}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Location: ${widget.initialArea ?? 'Unknown'}'),
                  const Spacer(),
                  Text(
                      '(${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)})'),
                ],
              ),
              const SizedBox(height: 16),
              // Tags input
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add tag',
                        hintText: 'Enter tag name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_tagController.text.isNotEmpty) {
                        setState(() {
                          _tags.add(_tagController.text);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tags display
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.clear, size: 16),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              // TODO toggle
              SwitchListTile(
                title: const Text('Mark as TODO'),
                value: _isTodo,
                onChanged: (value) {
                  setState(() {
                    _isTodo = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Image picker
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Take Photo'),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from Gallery'),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Image preview
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (ctx, i) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_selectedImages[i].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(i);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveMemo(memoProvider),
                  child: const Text('Save Memo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    if (source == ImageSource.camera) {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } else {
      final images = await picker.pickMultiImage(
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // Now pick the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedDate.hour,
            _selectedDate.minute,
          );
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveMemo(MemoProvider memoProvider) async {
    if (_formKey.currentState!.validate()) {
      // Add memo
      final memo = await memoProvider.addMemo(
        title: _titleController.text,
        content: _contentController.text,
        tags: _tags,
        dateTime: _selectedDate,
        latitude: widget.latitude,
        longitude: widget.longitude,
        areaName: widget.initialArea,
        isTodo: _isTodo,
      );

      // Add photos
      for (var image in _selectedImages) {
        await memoProvider.addPhotoToMemo(
          memoId: memo.id,
          imageFile: image,
        );
      }

      // Notify parent and close
      widget.onMemoAdded();
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}
