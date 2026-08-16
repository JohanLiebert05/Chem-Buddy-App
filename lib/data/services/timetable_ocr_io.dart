import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR via Google ML Kit (no network required).
Future<String> recognizeTimetableText(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    return result.text;
  } finally {
    await recognizer.close();
  }
}
