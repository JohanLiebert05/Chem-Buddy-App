/// Web / unsupported platforms: ML Kit is Android & iOS only.
Future<String> recognizeTimetableText(String path) async {
  throw UnsupportedError(
    'Timetable OCR works on Android and iOS. Pick a photo on your phone, or add classes manually in the review sheet.',
  );
}
