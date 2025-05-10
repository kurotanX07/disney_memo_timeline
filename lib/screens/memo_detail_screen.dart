import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/memo.dart';
import '../models/photo.dart';
import '../providers/memo_provider.dart';
import '../widgets/photo_gallery.dart';

class MemoDetailScreen extends StatefulWidget {
  final Memo memo;

  const MemoDetailScreen({Key? key, required this.memo}) : super(key: key);

  @override
  _MemoDetailScreenState createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _selectedDate;
  late bool _isTodo;
  late String _areaName;
  late List<String> _tags;
  late String _tagInput;
  List<Photo> _photos = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memo.title);
    _contentController = TextEditingController(text: widget.memo.content);
    _selectedDate = widget.memo.dateTime;
    _isTodo = widget.memo.isTodo;
    _areaName = widget.memo.areaName;
    _tags = List.from(widget.memo.tags);
    _tagInput = '';

    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    final photos = await memoProvider.getPhotosForMemo(widget.memo.id);

    setState(() {
      _photos = photos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Memo' : 'Memo Details'),
        actions: [
          // Toggle edit mode
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveMemo();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMemo,
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo gallery
            if (_photos.isNotEmpty)
              SizedBox(
                height: 200,
                child: PhotoGallery(
                  photos: _photos,
                  onPhotoDeleted: _isEditing ? _deletePhoto : null,
                ),
              ),

            // Title
            const SizedBox(height: 16),
            if (_isEditing)
              TextFormField(
                controller: _titleController,
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Text(
                widget.memo.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),

            // Date
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                if (_isEditing)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(dateFormat.format(_selectedDate)),
                      ),
                    ),
                  )
                else
                  Text(dateFormat.format(widget.memo.dateTime)),
              ],
            ),

            // Location info
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_areaName),
                ),
                Text(
                  '(${widget.memo.latitude.toStringAsFixed(4)}, ${widget.memo.longitude.toStringAsFixed(4)})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            // TODO toggle
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'TODO',
                style: TextStyle(
                  fontWeight: _isTodo ? FontWeight.bold : FontWeight.normal,
                  color: _isTodo ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              value: _isTodo,
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _isTodo = value;
                      });
                    }
                  : null,
            ),

            // Tags
            const SizedBox(height: 16),
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Add tag',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _tagInput = value;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_tagInput.isNotEmpty) {
                        setState(() {
                          _tags.add(_tagInput);
                          _tagInput = '';
                        });
                      }
                    },
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon:
                      _isEditing ? const Icon(Icons.clear, size: 16) : null,
                  onDeleted: _isEditing
                      ? () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        }
                      : null,
                );
              }).toList(),
            ),

            // Content
            const SizedBox(height: 16),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              TextFormField(
                controller: _contentController,
                minLines: 3,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.memo.content.isEmpty
                      ? 'No notes added.'
                      : widget.memo.content,
                  style: widget.memo.content.isEmpty
                      ? TextStyle(color: Theme.of(context).disabledColor)
                      : null,
                ),
              ),
          ],
        ),
      ),
      // Add photo button (only in edit mode)
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _pickPhoto,
              child: const Icon(Icons.add_a_photo),
            )
          : null,
    );
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

  Future<void> _pickPhoto() async {
    final imagePicker = ImagePicker();
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Photo'),
        content: const Text('Choose the source:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final XFile? image = await imagePicker.pickImage(
      source: result,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (image != null) {
      final memoProvider = Provider.of<MemoProvider>(context, listen: false);
      await memoProvider.addPhotoToMemo(
        memoId: widget.memo.id,
        imageFile: image,
      );
      _loadPhotos();
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    await memoProvider.deletePhoto(photoId);
    _loadPhotos();
  }

  void _saveMemo() async {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);

    final updatedMemo = widget.memo.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      dateTime: _selectedDate,
      isTodo: _isTodo,
      tags: _tags,
    );

    await memoProvider.updateMemo(updatedMemo);

    setState(() {
      // Update the widget.memo reference to reflect changes
      widget.memo.title = updatedMemo.title;
      widget.memo.content = updatedMemo.content;
      widget.memo.dateTime = updatedMemo.dateTime;
      widget.memo.isTodo = updatedMemo.isTodo;
      widget.memo.tags = updatedMemo.tags;
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Memo'),
        content: const Text(
            'Are you sure you want to delete this memo? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMemo();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteMemo() async {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    await memoProvider.deleteMemo(widget.memo.id);
    Navigator.pop(context);
  }

  void _shareMemo() async {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    String shareText = '''
${widget.memo.title}
Date: ${dateFormat.format(widget.memo.dateTime)}
Location: ${widget.memo.areaName}
${widget.memo.tags.isNotEmpty ? 'Tags: ${widget.memo.tags.join(', ')}' : ''}
${_isTodo ? 'TODO item' : ''}

${widget.memo.content}
''';

    // If there are photos, share the first one
    if (_photos.isNotEmpty) {
      await Share.shareXFiles(
        [XFile(_photos.first.path)],
        text: shareText,
      );
    } else {
      await Share.share(shareText);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
