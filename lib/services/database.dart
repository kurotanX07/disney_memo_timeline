import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/memo.dart';
import '../models/photo.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'DisneyMemoAlbum', 'db.sqlite');

    // Create directory if it doesn't exist
    await Directory(dirname(path)).create(recursive: true);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create memos table
    await db.execute('''
      CREATE TABLE memos(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        tags TEXT,
        dateTime TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        areaName TEXT NOT NULL,
        isTodo INTEGER DEFAULT 0,
        photoIds TEXT
      )
    ''');

    // Create photos table
    await db.execute('''
      CREATE TABLE photos(
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        memoId TEXT NOT NULL,
        FOREIGN KEY (memoId) REFERENCES memos (id) ON DELETE CASCADE
      )
    ''');
  }

  // Memo CRUD operations
  Future<String> insertMemo(Memo memo) async {
    final db = await database;
    await db.insert('memos', memo.toMap());
    return memo.id;
  }

  Future<Memo?> getMemo(String id) async {
    final db = await database;
    final maps = await db.query(
      'memos',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Memo.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Memo>> getAllMemos() async {
    final db = await database;
    final maps = await db.query('memos', orderBy: 'dateTime DESC');

    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> getMemosByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'memos',
      where: 'dateTime BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'dateTime ASC',
    );

    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> getPastMemos() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'memos',
      where: 'dateTime < ?',
      whereArgs: [now],
      orderBy: 'dateTime DESC',
    );

    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> getPlanMemos() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'memos',
      where: 'dateTime >= ?',
      whereArgs: [now],
      orderBy: 'dateTime ASC',
    );

    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> getTodoMemos() async {
    final db = await database;
    final maps = await db.query(
      'memos',
      where: 'isTodo = ?',
      whereArgs: [1],
      orderBy: 'dateTime ASC',
    );

    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> searchMemos(String query) async {
    final db = await database;
    final maps = await db.query(
      'memos',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'dateTime DESC',
    );

    return maps.map((map) => Memo.fromMap(map)).toList();
  }

  Future<int> updateMemo(Memo memo) async {
    final db = await database;
    return await db.update(
      'memos',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  Future<int> deleteMemo(String id) async {
    final db = await database;

    // First delete associated photos
    final photos = await getPhotosByMemoId(id);
    for (var photo in photos) {
      await deletePhoto(photo.id);

      // Delete file from storage
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Then delete the memo
    return await db.delete(
      'memos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Photo CRUD operations
  Future<String> insertPhoto(Photo photo) async {
    final db = await database;
    await db.insert('photos', photo.toMap());

    // Update the memo's photoIds list
    final memo = await getMemo(photo.memoId);
    if (memo != null) {
      final photoIds = [...memo.photoIds, photo.id];
      final updatedMemo = memo.copyWith(photoIds: photoIds);
      await updateMemo(updatedMemo);
    }

    return photo.id;
  }

  Future<Photo?> getPhoto(String id) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Photo.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Photo>> getPhotosByMemoId(String memoId) async {
    final db = await database;
    final maps = await db.query(
      'photos',
      where: 'memoId = ?',
      whereArgs: [memoId],
      orderBy: 'dateTime ASC',
    );

    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<int> deletePhoto(String id) async {
    final db = await database;

    // Get photo to know which memo to update
    final photo = await getPhoto(id);
    if (photo != null) {
      // Update the memo's photoIds list
      final memo = await getMemo(photo.memoId);
      if (memo != null) {
        final photoIds =
            memo.photoIds.where((photoId) => photoId != id).toList();
        final updatedMemo = memo.copyWith(photoIds: photoIds);
        await updateMemo(updatedMemo);
      }

      // Delete file from storage
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    return await db.delete(
      'photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
