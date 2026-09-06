import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_provider.dart';

/// On-Device ML Kit OCR Provider for mobile devices.
class MlKitOcrProvider implements OcrProvider {
  MlKitOcrProvider({this.script = TextRecognitionScript.latin});

  final TextRecognitionScript script;
  TextRecognizer? _recognizer;

  @override
  String get name => 'google_mlkit_${script.name}';

  @override
  Future<bool> get isAvailable async {
    return Platform.isAndroid || Platform.isIOS;
  }

  TextRecognizer _getRecognizer() {
    _recognizer ??= TextRecognizer(script: script);
    return _recognizer!;
  }

  @override
  Future<String> recognizeImage(File imageFile) async {
    if (!await imageFile.exists()) {
      return '';
    }

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognized = await _getRecognizer().processImage(inputImage);
      return recognized.text;
    } catch (e) {
      return '';
    }
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
