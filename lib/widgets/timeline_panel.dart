import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/memo.dart';
import 'memo_card.dart';
import '../screens/memo_detail_screen.dart';

class TimelinePanel extends StatefulWidget {
  final List<Memo> memos;
  final Function(String memoId) onMemoSelected;

  const TimelinePanel({
    Key? key,
    required this.memos,
    required this.onMemoSelected,
  }) : super(key: key);

  @override
  _TimelinePanelState createState() => _TimelinePanelState();
}

class _TimelinePanelState extends State<TimelinePanel> {
  bool _isExpanded = false;
  ScrollController _scrollController = ScrollController();
  String? _selectedMemoId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -10 && !_isExpanded) {
          setState(() {
            _isExpanded = true;
          });
        } else if (details.primaryDelta! > 10 && _isExpanded) {
          setState(() {
            _isExpanded = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isExpanded ? MediaQuery.of(context).size.height * 0.7 : 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Timeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${widget.memos.length} memos',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  IconButton(
                    icon: Icon(_isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Timeline content
            Expanded(
              child: widget.memos.isEmpty
                  ? const Center(
                      child: Text('No memos found'),
                    )
                  : _isExpanded
                      ? _buildExpandedTimeline()
                      : _buildCollapsedTimeline(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedTimeline() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.memos.length,
      itemBuilder: (context, index) {
        final memo = widget.memos[index];
        final dateFormat = DateFormat('MM/dd\nHH:mm');
        final isSelected = memo.id == _selectedMemoId;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMemoId = memo.id;
            });
            widget.onMemoSelected(memo.id);
          },
          child: Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8, bottom: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (memo.isTodo)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
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
                Text(
                  dateFormat.format(memo.dateTime),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    memo.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memo.areaName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedTimeline() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: widget.memos.length,
      itemBuilder: (context, index) {
        final memo = widget.memos[index];
        final isSelected = memo.id == _selectedMemoId;

        // Group by date
        final bool showDateHeader = index == 0 ||
            !_isSameDay(widget.memos[index - 1].dateTime, memo.dateTime);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _formatDate(memo.dateTime),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

            // Memo card
            InkWell(
              onTap: () {
                setState(() {
                  _selectedMemoId = memo.id;
                });
                widget.onMemoSelected(memo.id);

                // Open memo details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemoDetailScreen(memo: memo),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MemoCard(memo: memo),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else if (_isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    }

    return DateFormat('yyyy/MM/dd (E)').format(date);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
