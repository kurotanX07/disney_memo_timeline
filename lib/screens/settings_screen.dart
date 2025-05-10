import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/theme_provider.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<File> _backupFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    final files = await BackupService.instance.getBackupFiles();

    setState(() {
      _backupFiles = files;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme section
          ListTile(
            title: const Text('App Theme'),
            subtitle: const Text('Choose between light and dark mode'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleDarkMode();
              },
            ),
          ),

          // Font size section
          ListTile(
            title: const Text('Font Size'),
            subtitle: const Text('Adjust text size in the app'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: themeProvider.fontSize,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                label: _getFontSizeLabel(themeProvider.fontSize),
                onChanged: (value) {
                  themeProvider.setFontSize(value);
                },
              ),
            ),
          ),

          const Divider(),

          // Backup section
          ListTile(
            title: const Text('Backup & Restore'),
            subtitle: const Text('Manage your data backups'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createBackup,
              tooltip: 'Create backup',
            ),
          ),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_backupFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No backups found.'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _backupFiles.length,
              itemBuilder: (ctx, i) {
                final file = _backupFiles[i];
                final filename = basename(file.path);
                final fileSize = (file.lengthSync() / 1024).toStringAsFixed(1);
                final lastModified = file.lastModifiedSync();

                return ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(filename),
                  subtitle: Text(
                    'Size: ${fileSize}KB • ${_formatDate(lastModified)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore),
                        onPressed: () => _restoreBackup(file),
                        tooltip: 'Restore',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _shareBackup(file),
                        tooltip: 'Share',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteBackup(file),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                );
              },
            ),

          const Divider(),

          // Import backup section
          ListTile(
            title: const Text('Import Backup'),
            subtitle: const Text('Import a backup file'),
            onTap: _importBackup,
            trailing: const Icon(Icons.file_upload),
          ),

          const Divider(),

          // About section
          ListTile(
            title: const Text('About'),
            onTap: () => _showAboutDialog(context),
            trailing: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  String _getFontSizeLabel(double size) {
    if (size <= 0.8) return 'XS';
    if (size <= 0.9) return 'S';
    if (size <= 1.0) return 'M';
    if (size <= 1.1) return 'L';
    if (size <= 1.2) return 'XL';
    if (size <= 1.3) return '2XL';
    return '3XL';
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await BackupService.instance.createBackup();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create backup: $e')),
      );
    }

    await _loadBackupFiles();
  }

  void _restoreBackup(File backupFile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Text(
          'Are you sure you want to restore this backup? This will replace all current data with the data from the backup.\n\nBackup: ${basename(backupFile.path)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _isLoading = true;
              });

              try {
                final success =
                    await BackupService.instance.restoreBackup(backupFile.path);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Backup restored successfully. Please restart the app.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to restore backup')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error restoring backup: $e')),
                );
              }

              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _shareBackup(File backupFile) async {
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      text: 'Tokyo Disney Resort Memo & Photo Timeline Backup',
    );
  }

  void _deleteBackup(File backupFile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text(
            'Are you sure you want to delete this backup?\n\n${basename(backupFile.path)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final success =
                    await BackupService.instance.deleteBackup(backupFile.path);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup deleted')),
                  );
                  _loadBackupFiles();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete backup')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting backup: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        setState(() {
          _isLoading = true;
        });

        try {
          final success = await BackupService.instance.restoreBackup(file.path);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Backup imported and restored successfully. Please restart the app.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to import backup')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing backup: $e')),
          );
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting backup file: $e')),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AboutDialog(
        applicationName: 'Disney Memo Timeline',
        applicationVersion: '1.0.0',
        applicationIcon: Image.asset(
          'assets/icons/app_icon.png',
          width: 48,
          height: 48,
        ),
        children: [
          const SizedBox(height: 16),
          const Text(
            'A simple app to record and organize your Tokyo Disney Resort experiences by location and time.',
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2025 Your Name',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
