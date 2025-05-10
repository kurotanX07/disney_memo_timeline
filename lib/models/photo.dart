import 'package:uuid/uuid.dart';

class Photo {
  final String id;
  final String path;
  final DateTime dateTime;
  final String memoId;

  Photo({
    String? id,
    required this.path,
    required this.dateTime,
    required this.memoId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'dateTime': dateTime.toIso8601String(),
      'memoId': memoId,
    };
  }

  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      path: map['path'],
      dateTime: DateTime.parse(map['dateTime']),
      memoId: map['memoId'],
    );
  }
}
