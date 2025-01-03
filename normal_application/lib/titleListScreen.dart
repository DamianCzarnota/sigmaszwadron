import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:normal_application/imageDetailScreen.dart';
import 'package:normal_application/cloud_functions/getImage.dart';
import 'package:normal_application/imageItem.dart';

class TitleListScreen extends StatefulWidget {
  const TitleListScreen({Key? key}) : super(key: key);

  @override
  _TitleListScreenState createState() => _TitleListScreenState();
}

class _TitleListScreenState extends State<TitleListScreen> {
  bool _isLoading = true;
  List<ImageItem> _imageItems = [];

  // Paginacja
  static const int itemsPerPage = 10;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchTitlesFromDatabase();
  }

  Future<void> _fetchTitlesFromDatabase() async {
    try {
      final ref = FirebaseDatabase.instance.ref("images");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        List<ImageItem> items = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            final title = value['title'] as String? ?? 'Brak tytułu';
            final userTitle = value['userTitle'] as String?;
            final description = value['description'] as String? ?? 'Brak opisu';
            items.add(ImageItem(
              id: key,
              title: title,
              userTitle: userTitle,
              description: description,
            ));
          }
        });

        _totalPages = (items.length / itemsPerPage).ceil();

        setState(() {
          _imageItems = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _imageItems = [];
          _isLoading = false;
          _totalPages = 1;
        });
      }
    } catch (e) {
      print('Błąd pobierania danych z Realtime Database: $e');
      setState(() {
        _imageItems = [];
        _isLoading = false;
        _totalPages = 1;
      });
    }
  }

  List<ImageItem> get _currentPageItems {
    int startIndex = (_currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > _imageItems.length) {
      endIndex = _imageItems.length;
    }
    return _imageItems.sublist(startIndex, endIndex);
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage += 1;
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage -= 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista Tytułów Obrazków'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _imageItems.isEmpty
              ? const Center(child: Text('Brak obrazków'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
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
                                leading: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: PreviewWidget(title: item.title),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ImageDetailScreen(imageItem: item),
                                    ),
                                  ).then((_) {
                                    // Po powrocie z ekranu szczegółów odśwież listę
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 32.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  _currentPage > 1 ? _goToPreviousPage : null,
                              child: const Text('Poprzednia'),
                            ),
                            Text('Strona $_currentPage z $_totalPages'),
                            ElevatedButton(
                              onPressed: _currentPage < _totalPages
                                  ? _goToNextPage
                                  : null,
                              child: const Text('Następna'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
