import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

//Place for global functions
const String IMAGE_EXTENSION = ".jpg";
const String FIREBASE_FUNCTION_URL =
    "https://us-central1-sigmaszwadron.cloudfunctions.net/generate_preview";
const int DEFAULT_IMAGE_SIZE = 400;

const String phoneType = "smartphone";
const String desktopType = "desktop";

String getSmartPhoneOrTablet() {
  if (kIsWeb) {
    return desktopType;
  }
  if (Platform.isAndroid || Platform.isIOS) return phoneType;

  return desktopType;
}
