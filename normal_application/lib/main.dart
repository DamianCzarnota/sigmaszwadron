import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String email = 'testuser@sigmaszwadron.com';
  final String password = 'testuser';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Image Title App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<User?>(
        future: _signIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            if (snapshot.hasData) {
              return TitleListScreen();
            } else {
              return Scaffold(
                body: Center(child: Text('Nie udało się zalogować')),
              );
            }
          }
        },
      ),
    );
  }

  Future<User?> _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print('Błąd logowania: $e');
      return null;
    }
  }
}

class ImageItem {
  final String id;
  final String title;
  final String? userTitle;
  final String description;

  ImageItem({
    required this.id,
    required this.title,
    this.userTitle,
    required this.description,
  });

  String get displayTitle => userTitle ?? title;
}

class TitleListScreen extends StatefulWidget {
  @override
  _TitleListScreenState createState() => _TitleListScreenState();
}

class _TitleListScreenState extends State<TitleListScreen> {
  bool _isLoading = true;
  List<ImageItem> _imageItems = [];

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

        setState(() {
          _imageItems = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _imageItems = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Błąd pobierania danych z Realtime Database: $e');
      setState(() {
        _imageItems = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista Tytułów Obrazków'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _imageItems.isEmpty
          ? Center(child: Text('Brak obrazków'))
          : ListView.builder(
        itemCount: _imageItems.length,
        itemBuilder: (context, index) {
          final item = _imageItems[index];
          return ListTile(
            title: Text(item.displayTitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageDetailScreen(
                    imageItem: item,
                  ),
                ),
              ).then((_) {
                _fetchTitlesFromDatabase();
              });
            },
          );
        },
      ),
    );
  }
}

class ImageDetailScreen extends StatefulWidget {
  final ImageItem imageItem;

  ImageDetailScreen({required this.imageItem});

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late Future<String> _downloadUrlFuture;

  @override
  void initState() {
    super.initState();
    _downloadUrlFuture = _fetchDownloadUrl(widget.imageItem.title);
  }

  Future<String> _fetchDownloadUrl(String fileName) async {
    String sanitizedFileName = fileName.replaceAll(' ', '_');
    final storage = FirebaseStorage.instance;

    final listResult = await storage.ref().listAll();

    final matchingRef = listResult.items.firstWhere(
            (ref) => ref.name.startsWith(sanitizedFileName),
        orElse: () => throw Exception('Nie znaleziono pliku dla $sanitizedFileName')
    );

    return await matchingRef.getDownloadURL();
  }

  void _editData() async {
    final newUserTitleController = TextEditingController(text: widget.imageItem.userTitle ?? widget.imageItem.title);
    final newDescriptionController = TextEditingController(text: widget.imageItem.description);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edytuj'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newUserTitleController,
              decoration: InputDecoration(labelText: 'Nowy tytuł (userTitle)'),
            ),
            TextField(
              controller: newDescriptionController,
              decoration: InputDecoration(labelText: 'Opis'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Anuluj'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Zapisz'),
            onPressed: () async {
              final ref = FirebaseDatabase.instance.ref('images/${widget.imageItem.id}');
              await ref.update({
                'userTitle': newUserTitleController.text,
                'description': newDescriptionController.text,
              });
              Navigator.pop(ctx);
              setState(() {
              });
            },
          ),
        ],
      ),
    );
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final ref = FirebaseDatabase.instance.ref('images/${widget.imageItem.id}');
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;
      final userTitle = data['userTitle'] as String?;
      final description = data['description'] as String? ?? 'Brak opisu';

      final updatedItem = ImageItem(
        id: widget.imageItem.id,
        title: widget.imageItem.title,
        userTitle: userTitle,
        description: description,
      );

      setState(() {
        _imageItem = updatedItem;
      });
    }
  }

  late ImageItem _imageItem = widget.imageItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_imageItem.displayTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editData,
          )
        ],
      ),
      body: FutureBuilder<String>(
        future: _downloadUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Błąd wczytywania obrazka'),
            );
          } else {
            final imageUrl = snapshot.data!;
            return Center(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    _imageItem.displayTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: (context, url) =>
                          Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _imageItem.description,
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
