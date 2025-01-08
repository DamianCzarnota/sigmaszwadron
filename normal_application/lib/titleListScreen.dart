import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:normal_application/imageDetailScreen.dart';
import 'package:normal_application/cloud_functions/getImage.dart';
import 'package:normal_application/imageItem.dart';
import 'package:normal_application/cloud_functions/utils.dart';

class TitleListScreen extends StatefulWidget {
  @override
  _TitleListScreenState createState() => _TitleListScreenState();
}

class _TitleListScreenState extends State<TitleListScreen> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('images');
  List<ImageItem> _allImageItems = [];
  List<ImageItem> _filteredImageItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final int _itemsPerPage = MAX_IMAGES_PER_PAGE;
  int _currentPage = 1;
  int _totalPages = 1;
  List<ImageItem> _currentPageItems = [];

  @override
  void initState() {
    super.initState();
    _fetchTitlesFromDatabase();
  }

  Future<void> _fetchTitlesFromDatabase() async {
    try {
      final snapshot = await _databaseRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<ImageItem> imageItems = [];
        data.forEach((key, value) {
          imageItems.add(ImageItem.fromMap(value, key));
        });

        setState(() {
          _allImageItems = imageItems;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() {
          _allImageItems = [];
          _filteredImageItems = [];
          _currentPageItems = [];
          _totalPages = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredImageItems = List.from(_allImageItems);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredImageItems = _allImageItems.where((item) {
        final searchTarget =
            item.userTitle?.toLowerCase() ?? item.title.toLowerCase();
        return searchTarget.contains(query);
      }).toList();
    }
    _setupPagination();
  }

  void _setupPagination() {
    _totalPages = (_filteredImageItems.length / _itemsPerPage).ceil();
    _currentPage = 1;
    _updateCurrentPageItems();
  }

  void _updateCurrentPageItems() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    setState(() {
      _currentPageItems = _filteredImageItems.sublist(
        startIndex,
        endIndex > _filteredImageItems.length
            ? _filteredImageItems.length
            : endIndex,
      );
    });
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _updateCurrentPageItems();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _updateCurrentPageItems();
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of images'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search titles',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredImageItems.isEmpty
                    ? const Center(child: Text('No images'))
                    : ListView.builder(
                        itemCount: _currentPageItems.length,
                        itemBuilder: (context, index) {
                          final item = _currentPageItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Card(
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ListTile(
                                title: Text(
                                  item.displayTitle,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                                leading: PreviewWidget(title: item.title),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ImageDetailScreen(imageItem: item),
                                    ),
                                  ).then((_) {
                                    _fetchTitlesFromDatabase();
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_totalPages > 1)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                    child: const Text('Previous'),
                  ),
                  Text('Page $_currentPage out of $_totalPages'),
                  ElevatedButton(
                    onPressed:
                        _currentPage < _totalPages ? _goToNextPage : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
