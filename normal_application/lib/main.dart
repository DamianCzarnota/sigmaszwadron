import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:normal_application/titleListScreen.dart';

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
