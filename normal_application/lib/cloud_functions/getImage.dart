import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:normal_application/cloud_functions/utils.dart'; // Import IMAGE_EXTENSION
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

Future<ImageProvider> fetchImageForDesktop(String title) async {
  final sanitizedTitle = title.replaceAll(' ', '_') + IMAGE_EXTENSION;
  final ref = FirebaseStorage.instance.ref().child(sanitizedTitle);
  final downloadUrl = await ref.getDownloadURL();
  return CachedNetworkImageProvider(downloadUrl);
}

Future<ImageProvider> fetchImageForSmartphone(String title,
    [bool thumbnail = false]) async {
  final sanitizedTitle = title.replaceAll(' ', '_') + IMAGE_EXTENSION;

  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  Size size = view.physicalSize;
  double width = size.width;
  double height = size.height;

  late final Uri url;
  if (thumbnail) {
    url = Uri.parse(
      "$FIREBASE_FUNCTION_URL?fileName=${Uri.encodeComponent(sanitizedTitle)}&size=${DEFAULT_IMAGE_SIZE}",
    );
  } else {
    url = Uri.parse(
      "$FIREBASE_FUNCTION_URL?fileName=${Uri.encodeComponent(sanitizedTitle)}&sizex=${width}&sizey=${height}",
    );
  }
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in");
  }
  final idToken = await user.getIdToken();
  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $idToken",
    },
  );
  if (response.statusCode == 200) {
    return MemoryImage(response.bodyBytes);
  } else {
    throw Exception(
        "Cloud Function error: ${response.statusCode} ${response.reasonPhrase}");
  }
}

class PreviewWidget extends StatelessWidget {
  final String title;

  const PreviewWidget({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: FutureBuilder<ImageProvider>(
        future: fetchImageForSmartphone(title, true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 24,
                  color: Colors.grey[600],
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            // Wyświetlanie tytułu w przypadku błędu
            return Center(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.red),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }

          final imageProvider = snapshot.data!;
          return Image(
            image: imageProvider,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
