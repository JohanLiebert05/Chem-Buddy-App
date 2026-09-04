import 'dart:convert';
import 'dart:io';

/// Structural validation for bundled ChemDraw-style mechanism SVGs.
/// Run: dart run tool/validate_mechanisms.dart
void main() {
  final root = Directory('assets/mechanisms');
  final report = File('assets/mechanisms/VALIDATION.md');
  final issues = <String>[];
  var svgCount = 0;
  var okCount = 0;

  if (!root.existsSync()) {
    stderr.writeln('Missing ${root.path}');
    exit(1);
  }

  final index = File('assets/mechanisms/index.json');
  if (!index.existsSync()) issues.add('Missing index.json');

  for (final file in root.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.svg')) continue;
    svgCount++;
    final text = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    final rel = file.path.replaceAll('\\', '/');
    final local = <String>[];

    if (!text.contains('<svg')) local.add('no <svg>');
    if (!text.contains('</svg>')) local.add('no closing </svg>');
    if (!text.contains('viewBox')) local.add('no viewBox');
    if (RegExp(r'<image[\s>]', caseSensitive: false).hasMatch(text)) {
      local.add('raster <image> not allowed');
    }
    if (RegExp(r'\.(png|jpg|jpeg|gif|webp)', caseSensitive: false).hasMatch(text)) {
      local.add('raster reference');
    }
    for (final bad in ['TODO', 'placeholder', 'insert molecule', 'draw structure here']) {
      if (text.toLowerCase().contains(bad.toLowerCase())) {
        local.add('placeholder text: $bad');
      }
    }
    if (!text.contains('id="reactants"') &&
        !text.contains('id="products"') &&
        !text.contains('id="intermediate-1"')) {
      local.add('missing reactants/products/intermediate group');
    }
    if (!text.contains('id="electron-arrows"')) local.add('missing electron-arrows group');
    if (!text.contains('id="electron-arrow"')) local.add('missing electron-arrow marker');
    if (!text.contains('<title>')) local.add('missing <title>');
    if (!text.contains('<desc>')) local.add('missing <desc>');
    if (text.contains('R–X') || text.contains('R-X')) {
      local.add('R-X used as primary structure');
    }

    if (local.isEmpty) {
      okCount++;
    } else {
      issues.add('$rel: ${local.join('; ')}');
    }
  }

  final sn2Meta = File('assets/mechanisms/substitution/sn2/sn2.json');
  if (!sn2Meta.existsSync()) {
    issues.add('Missing SN2 metadata JSON');
  } else {
    final meta = sn2Meta.readAsStringSync();
    if (!meta.contains('"id": "sn2"')) issues.add('SN2 metadata missing id');
    if (!meta.contains('representative_example')) issues.add('SN2 missing representative_example');
    if (!meta.contains('needs_review') && !meta.contains('"verified": true')) {
      issues.add('SN2 missing verification_status');
    }
  }

  final buf = StringBuffer()
    ..writeln('# Mechanism SVG validation')
    ..writeln()
    ..writeln('- SVGs scanned: $svgCount')
    ..writeln('- Structurally OK: $okCount')
    ..writeln('- Issues: ${issues.length}')
    ..writeln()
    ..writeln('## Notes')
    ..writeln()
    ..writeln('This script checks XML/SVG structure, not full chemical correctness.')
    ..writeln('Chemical review flags live in each mechanism JSON (`verification_status`).')
    ..writeln()
    ..writeln('## Issues')
    ..writeln();
  if (issues.isEmpty) {
    buf.writeln('None.');
  } else {
    for (final i in issues) {
      buf.writeln('- $i');
    }
  }
  report.writeAsStringSync(buf.toString());
  stdout.write(buf.toString());
  if (issues.isNotEmpty) exit(1);
}
