import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Stałe dane uwierzytelniające
  final String email = 'testuser@sigmaszwadron.com';
  final String password = 'testuser'; //

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Image App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<User?>(
        future: _signIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Pokazuj spinner podczas logowania
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            if (snapshot.hasData) {
              // Jeśli zalogowano, przejdź do ekranu głównego
              return ImageListScreen();
            } else {
              // Jeśli logowanie się nie powiodło
              return Scaffold(
                body: Center(child: Text('Nie udało się zalogować')),
              );
            }
          }
        },
      ),
    );
  }

  // Funkcja logowania
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

class ImageListScreen extends StatefulWidget {
  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  List<Reference> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  // Funkcja pobierająca listę zdjęć z Firebase Storage
  Future<void> _fetchImages() async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      ListResult result = await storage.ref().listAll();
      setState(() {
        _images = result.items;
        _isLoading = false;
      });
    } catch (e) {
      print('Błąd pobierania zdjęć: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Funkcja pobierająca URL dla zdjęcia
  Future<String> _getImageUrl(Reference ref) async {
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galeria Zdjęć'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? Center(child: Text('Brak zdjęć'))
              : GridView.builder(
                  padding: EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Liczba kolumn
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    Reference imageRef = _images[index];
                    return FutureBuilder<String>(
                      future: _getImageUrl(imageRef),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            color: Colors.grey[300],
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return Container(
                            color: Colors.grey[300],
                            child: Center(child: Icon(Icons.error)),
                          );
                        } else {
                          String imageUrl = snapshot.data!;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageDetailScreen(
                                    imageUrl: imageUrl,
                                    imageName: imageRef.name,
                                  ),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class ImageDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String imageName;

  ImageDetailScreen({required this.imageUrl, required this.imageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(imageName),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              imageName,
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
          ],
        ),
      ),
    );
  }
}
