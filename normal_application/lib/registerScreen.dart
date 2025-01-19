import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:normal_application/titleListScreen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  bool _isLoading = false;

  // Metoda rejestracji za pomocą email i hasła
  Future<void> _registerWithEmailPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TitleListScreen()),
        );
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(e.message ?? 'Sign up error');
      } catch (e) {
        _showErrorDialog('Sign up error');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Metoda wyświetlania dialogu błędu
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Użycie gradientu jako tła
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.purple.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 48.0),
                child: Column(
                  children: [
                    SizedBox(height: 80.0),
                    // Tytuł aplikacji
                    Text(
                      'Sign up',
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.0),
                    // Formularz rejestracji
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Pole email
                          TextFormField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email),
                              labelText: 'Email',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains('@')) {
                                return 'Pass correct email';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _email = value;
                              });
                            },
                          ),
                          SizedBox(height: 16.0),
                          // Pole hasła
                          TextFormField(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock),
                              labelText: 'Password',
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must contain at least 6 characters';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _password = value;
                              });
                            },
                          ),
                          SizedBox(height: 24.0),
                          // Przycisk rejestracji
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.purple.shade700,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            onPressed: _registerWithEmailPassword,
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.0),
                    // Separator
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.7),
                            thickness: 1.0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Or',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.7),
                            thickness: 1.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.0),
                    // Link do logowania
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Have an acoount? ',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Log in',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 16.0,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
