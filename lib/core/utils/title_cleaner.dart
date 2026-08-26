/// Utility to clean file names and study material titles for professional UI display.
String cleanStudyMaterialTitle(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Chemistry Notes';

  var title = raw.trim();

  // 1. Remove file extensions (.pdf, .docx, .txt, .pptx, etc.)
  title = title.replaceAll(RegExp(r'\.[a-zA-Z0-9]{2,5}$', caseSensitive: false), '');

  // 2. Replace underscores and excessive punctuation with spaces
  title = title.replaceAll('_', ' ');

  // 3. Remove raw markdown/latex/special character tags
  title = title.replaceAll(RegExp(r'[\$#*`~|\\]'), ' ');

  // 4. Clean duplicated spaces
  title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (title.isEmpty) return 'Chemistry Notes';
  return title;
}
