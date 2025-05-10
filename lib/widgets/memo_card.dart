import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memo.dart';
import '../providers/memo_provider.dart';
import 'package:provider/provider.dart';

class MemoCard extends StatelessWidget {
  final Memo memo;
  final VoidCallback? onTap;

  const MemoCard({
    Key? key,
    required this.memo,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and date
              Row(
                children: [
                  if (memo.isTodo)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TODO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      memo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: memo.isTodo ? FontWeight.bold : null,
                          ),
                    ),
                  ),
                  Text(
                    dateFormat.format(memo.dateTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    memo.areaName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

              // Show content preview if available
              if (memo.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  memo.content.length > 100
                      ? '${memo.content.substring(0, 100)}...'
                      : memo.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Tags
              if (memo.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: memo.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Photo preview if available
              if (memo.photoIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                FutureBuilder(
                  future: _loadFirstPhoto(memoProvider),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      final photoPath = snapshot.data as String;
                      return Container(
                        height: 100,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          File(photoPath),
                          fit: BoxFit.cover,
                        ),
                      );
                    }

                    return const SizedBox();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _loadFirstPhoto(MemoProvider memoProvider) async {
    if (memo.photoIds.isEmpty) return null;

    final photos = await memoProvider.getPhotosForMemo(memo.id);
    if (photos.isEmpty) return null;

    return photos.first.path;
  }
}
