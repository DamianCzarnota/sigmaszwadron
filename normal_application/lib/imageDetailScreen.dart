import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:normal_application/cloud_functions/getImage.dart';
import 'package:normal_application/imageItem.dart';
import 'package:normal_application/cloud_functions/utils.dart';


class ImageDetailScreen extends StatefulWidget {
  final ImageItem imageItem;

  const ImageDetailScreen({Key? key, required this.imageItem})
      : super(key: key);

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late Future<ImageProvider> _imageProviderFuture;
  late ImageItem _imageItem;

  @override
  void initState() {
    super.initState();
    _imageItem = widget.imageItem;
    _imageProviderFuture = _fetchImageProvider(_imageItem.title);
  }

  Future<ImageProvider> _fetchImageProvider(String title) async {
    if (getSmartPhoneOrTablet() != desktopType) {
      return fetchImageForSmartphone(title);
    } else {
      return fetchImageForDesktop(title);
    }
  }

  void _editData() async {
    final newUserTitleController =
        TextEditingController(text: _imageItem.userTitle ?? _imageItem.title);
    final newDescriptionController =
        TextEditingController(text: _imageItem.description);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edytuj'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newUserTitleController,
              decoration:
                  const InputDecoration(labelText: 'Nowy tytuł (userTitle)'),
            ),
            TextField(
              controller: newDescriptionController,
              decoration: const InputDecoration(labelText: 'Opis'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Anuluj'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Zapisz'),
            onPressed: () async {
              final ref =
                  FirebaseDatabase.instance.ref('images/${_imageItem.id}');
              await ref.update({
                'userTitle': newUserTitleController.text.isEmpty
                    ? null
                    : newUserTitleController.text,
                'description': newDescriptionController.text,
              });
              Navigator.pop(ctx);
              await _refreshData();
            },
          ),
        ],
      ),
    );
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final ref = FirebaseDatabase.instance.ref('images/${_imageItem.id}');
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;
      final userTitle = data['userTitle'] as String?;
      final description = data['description'] as String? ?? 'Brak opisu';

      final updatedItem = ImageItem(
        id: _imageItem.id,
        title: _imageItem.title,
        userTitle: userTitle,
        description: description,
      );

      setState(() {
        _imageItem = updatedItem;
        _imageProviderFuture = _fetchImageProvider(_imageItem.title);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_imageItem.displayTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editData,
          )
        ],
      ),
      body: FutureBuilder<ImageProvider>(
        future: _imageProviderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            print(snapshot.error);
            return const Center(child: Text("Błąd wczytywania obrazu:"));
          } else {
            final imageProvider = snapshot.data!;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      _imageItem.displayTitle,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Image(
                      image: imageProvider,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 20),
                    Text(
                      _imageItem.description,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
