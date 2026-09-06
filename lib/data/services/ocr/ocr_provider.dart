import 'dart:io';

/// Pluggable OCR Provider interface for ChemBuddy.
/// Allows substituting or mocking OCR engines without altering the pipeline.
abstract class OcrProvider {
  /// Unique identifier of the engine (e.g., 'google_mlkit', 'tesseract', 'cloud_vision')
  String get name;

  /// Whether the OCR engine is available and supported on the current device/platform.
  Future<bool> get isAvailable;

  /// Processes an image file and extracts recognized text.
  Future<String> recognizeImage(File imageFile);

  /// Releases native and memory resources.
  Future<void> dispose();
}
