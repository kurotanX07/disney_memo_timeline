import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:intl/intl.dart';
import 'database.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  static BackupService get instance => _instance;

  BackupService._internal();

  Future<String> createBackup() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath =
          join(documentsDirectory.path, 'DisneyMemoAlbum', 'db.sqlite');
      final photosDir =
          join(documentsDirectory.path, 'DisneyMemoAlbum', 'Photos');

      // Create backup directory
      final backupDir =
          join(documentsDirectory.path, 'DisneyMemoAlbum', 'Backups');
      await Directory(backupDir).create(recursive: true);

      // Format date for the backup filename
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      final timestamp = dateFormat.format(DateTime.now());
      final backupName = 'disney_memo_backup_$timestamp.zip';
      final backupPath = join(backupDir, backupName);

      // Create temporary directory to store files to be zipped
      final tempDir =
          join(documentsDirectory.path, 'DisneyMemoAlbum', 'temp_backup');
      await Directory(tempDir).create(recursive: true);

      // Copy database file to temp directory
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy(join(tempDir, 'db.sqlite'));
      }

      // Create photos directory in temp backup
      final tempPhotosDir = join(tempDir, 'Photos');
      await Directory(tempPhotosDir).create(recursive: true);

      // Copy photos to temp directory
      final photosDirectory = Directory(photosDir);
      if (await photosDirectory.exists()) {
        await for (final photo in photosDirectory.list()) {
          if (photo is File) {
            final photoName = basename(photo.path);
            await photo.copy(join(tempPhotosDir, photoName));
          }
        }
      }

      // Create the zip file
      final zipFile = File(backupPath);
      await ZipFile.createFromDirectory(
        sourceDir: Directory(tempDir),
        zipFile: zipFile,
      );

      // Clean up temp directory
      await Directory(tempDir).delete(recursive: true);

      return backupPath;
    } catch (e) {
      print('Error creating backup: $e');
      rethrow;
    }
  }

  Future<bool> restoreBackup(String backupPath) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbDir = join(documentsDirectory.path, 'DisneyMemoAlbum');

      // Create restore directory
      final restoreDir =
          join(documentsDirectory.path, 'DisneyMemoAlbum', 'temp_restore');
      await Directory(restoreDir).create(recursive: true);

      // Extract zip file
      await ZipFile.extractToDirectory(
        zipFile: File(backupPath),
        destinationDir: Directory(restoreDir),
      );

      // Close database connection
      final db = await DatabaseService.instance.database;
      await db.close();

      // Remove existing database and photos
      final dbPath = join(dbDir, 'db.sqlite');
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      final photosDir = join(dbDir, 'Photos');
      final photosDirectory = Directory(photosDir);
      if (await photosDirectory.exists()) {
        await photosDirectory.delete(recursive: true);
      }

      // Create photos directory
      await Directory(photosDir).create(recursive: true);

      // Copy restored database to app directory
      final restoredDbFile = File(join(restoreDir, 'db.sqlite'));
      if (await restoredDbFile.exists()) {
        await restoredDbFile.copy(dbPath);
      }

      // Copy restored photos to app directory
      final restoredPhotosDir = join(restoreDir, 'Photos');
      final restoredPhotosDirectory = Directory(restoredPhotosDir);
      if (await restoredPhotosDirectory.exists()) {
        await for (final photo in restoredPhotosDirectory.list()) {
          if (photo is File) {
            final photoName = basename(photo.path);
            await photo.copy(join(photosDir, photoName));
          }
        }
      }

      // Clean up restore directory
      await Directory(restoreDir).delete(recursive: true);

      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  Future<List<File>> getBackupFiles() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final backupDir =
          join(documentsDirectory.path, 'DisneyMemoAlbum', 'Backups');

      final directory = Directory(backupDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        return [];
      }

      final List<File> backupFiles = [];
      await for (final file in directory.list()) {
        if (file is File && file.path.endsWith('.zip')) {
          backupFiles.add(file);
        }
      }

      // Sort by creation date (newest first)
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return backupFiles;
    } catch (e) {
      print('Error getting backup files: $e');
      return [];
    }
  }

  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }
}
