import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memo_provider.dart';
import '../services/map_service.dart';
import '../widgets/memo_card.dart';
import 'memo_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedArea;
  bool _todoOnly = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    // Set initial filters from memo provider
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    _selectedArea = memoProvider.areaFilter;
    _todoOnly = memoProvider.todoOnly;
    _startDate = memoProvider.startDate;
    _endDate = memoProvider.endDate;

    // Apply the search text if there's one already
    if (memoProvider.searchQuery != null &&
        memoProvider.searchQuery!.isNotEmpty) {
      _searchController.text = memoProvider.searchQuery!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoProvider = Provider.of<MemoProvider>(context);
    final memos = memoProvider.memos;
    final areas = MapService.instance.getAreas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Memos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSheet(context, areas);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search memos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    memoProvider.setSearchQuery('');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                memoProvider.setSearchQuery(value);
              },
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // View mode chip
                Chip(
                  label: Text(
                    memoProvider.viewMode == ViewMode.past ? 'Past' : 'Plan',
                  ),
                  deleteIcon: const Icon(Icons.swap_horiz, size: 16),
                  onDeleted: () {
                    memoProvider.toggleViewMode();
                  },
                ),
                const SizedBox(width: 8),

                // Area filter chip
                if (_selectedArea != null)
                  Chip(
                    label: Text('Area: $_selectedArea'),
                    deleteIcon: const Icon(Icons.clear, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedArea = null;
                      });
                      memoProvider.setAreaFilter(null);
                    },
                  ),

                // Todo filter chip
                if (_todoOnly)
                  Chip(
                    label: const Text('TODO only'),
                    deleteIcon: const Icon(Icons.clear, size: 16),
                    onDeleted: () {
                      setState(() {
                        _todoOnly = false;
                      });
                      memoProvider.setTodoOnly(false);
                    },
                  ),

                // Date range chip
                if (_startDate != null && _endDate != null)
                  Chip(
                    label: Text(
                      'Date: ${_formatDateShort(_startDate!)} - ${_formatDateShort(_endDate!)}',
                    ),
                    deleteIcon: const Icon(Icons.clear, size: 16),
                    onDeleted: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      memoProvider.setDateRange(null, null);
                    },
                  ),
              ],
            ),
          ),

          const Divider(),

          // Results
          Expanded(
            child: memos.isEmpty
                ? const Center(
                    child: Text('No memos found'),
                  )
                : ListView.builder(
                    itemCount: memos.length,
                    itemBuilder: (ctx, i) {
                      return MemoCard(
                        memo: memos[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MemoDetailScreen(memo: memos[i]),
                            ),
                          ).then((_) {
                            // Refresh search results
                            memoProvider.applyFilters();
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _showFilterSheet(BuildContext context, List<String> areas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Options',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),

                  // Area filter
                  Text(
                    'Area',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    value: _selectedArea,
                    hint: const Text('All Areas'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Areas'),
                      ),
                      ...areas.map((area) {
                        return DropdownMenuItem<String?>(
                          value: area,
                          child: Text(area),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        _selectedArea = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Todo filter
                  SwitchListTile(
                    title: const Text('TODO Items Only'),
                    value: _todoOnly,
                    onChanged: (value) {
                      setSheetState(() {
                        _todoOnly = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date range filter
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await _selectDate(context, _startDate);
                            if (date != null) {
                              setSheetState(() {
                                _startDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _startDate != null
                                  ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                                  : 'Start Date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await _selectDate(context, _endDate);
                            if (date != null) {
                              setSheetState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _endDate != null
                                  ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                                  : 'End Date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final memoProvider =
                            Provider.of<MemoProvider>(context, listen: false);
                        memoProvider.setAreaFilter(_selectedArea);
                        memoProvider.setTodoOnly(_todoOnly);
                        memoProvider.setDateRange(_startDate, _endDate);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Clear button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedArea = null;
                          _todoOnly = false;
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      child: const Text('Clear All Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _selectDate(
      BuildContext context, DateTime? initialDate) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
