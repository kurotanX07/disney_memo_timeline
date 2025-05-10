import 'dart:convert';
import 'package:uuid/uuid.dart';

class Memo {
  final String id;
  String title;
  String content;
  List<String> tags;
  DateTime dateTime;
  double latitude;
  double longitude;
  String areaName;
  bool isTodo;
  List<String> photoIds;

  Memo({
    String? id,
    required this.title,
    this.content = '',
    this.tags = const [],
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.areaName,
    this.isTodo = false,
    this.photoIds = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': jsonEncode(tags),
      'dateTime': dateTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'areaName': areaName,
      'isTodo': isTodo ? 1 : 0,
      'photoIds': jsonEncode(photoIds),
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'],
      title: map['title'],
      content: map['content'] ?? '',
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      dateTime: DateTime.parse(map['dateTime']),
      latitude: map['latitude'],
      longitude: map['longitude'],
      areaName: map['areaName'],
      isTodo: map['isTodo'] == 1,
      photoIds: List<String>.from(jsonDecode(map['photoIds'] ?? '[]')),
    );
  }

  bool isPast() {
    final now = DateTime.now();
    return dateTime.isBefore(now);
  }

  bool isPlan() {
    final now = DateTime.now();
    return dateTime.isAfter(now) || dateTime.isAtSameMomentAs(now);
  }

  Memo copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DateTime? dateTime,
    double? latitude,
    double? longitude,
    String? areaName,
    bool? isTodo,
    List<String>? photoIds,
  }) {
    return Memo(
      id: this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      dateTime: dateTime ?? this.dateTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      areaName: areaName ?? this.areaName,
      isTodo: isTodo ?? this.isTodo,
      photoIds: photoIds ?? this.photoIds,
    );
  }
}
