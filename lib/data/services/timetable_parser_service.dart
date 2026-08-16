import 'package:uuid/uuid.dart';

import '../models/timetable_entry.dart';

/// Turns raw OCR text from a timetable photo into [TimetableEntry] rows.
class TimetableParserService {
  TimetableParserService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static final _dayPattern = RegExp(
    r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun)\b',
    caseSensitive: false,
  );

  static final _timeRange = RegExp(
    r'(\d{1,2}[:.]\d{2}\s*(?:AM|PM)?|\d{1,2}\s*(?:AM|PM))\s*(?:-|–|—|to)\s*(\d{1,2}[:.]\d{2}\s*(?:AM|PM)?|\d{1,2}\s*(?:AM|PM))',
    caseSensitive: false,
  );

  static final _subjectCode = RegExp(
    r'\b([A-Z]{1,4}\s?\d{3}[A-Z]{0,3}|CH\s?\d{3}\s?[A-Z]{0,2}|OCH\d{3}|ICH\d{3})\b',
    caseSensitive: false,
  );

  static final _teacher = RegExp(
    r'\b((?:Dr|Prof|Mrs|Mr|Ms)\.?\s+[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)?)',
  );

  List<TimetableEntry> parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    var currentDay = 'Monday';
    final entries = <TimetableEntry>[];

    for (final line in lines) {
      final dayMatch = _dayPattern.firstMatch(line);
      if (dayMatch != null) {
        currentDay = _canonicalDay(dayMatch.group(1)!);
      }

      final timeMatch = _timeRange.firstMatch(line);
      if (timeMatch == null) continue;

      final codeMatch = _subjectCode.firstMatch(line) ??
          (lines.indexOf(line) + 1 < lines.length
              ? _subjectCode.firstMatch(lines[lines.indexOf(line) + 1])
              : null);
      final teacherMatch = _teacher.firstMatch(line);

      entries.add(
        TimetableEntry(
          id: _uuid.v4(),
          dayOfWeek: currentDay,
          startTime: _normalizeTime(timeMatch.group(1)!),
          endTime: _normalizeTime(timeMatch.group(2)!),
          subjectCode: (codeMatch?.group(1) ?? '').replaceAll(RegExp(r'\s+'), ' ').toUpperCase(),
          teacherName: teacherMatch?.group(1)?.trim() ?? '',
        ),
      );
    }

    if (entries.isEmpty) {
      entries.add(
        TimetableEntry(
          id: _uuid.v4(),
          dayOfWeek: 'Monday',
          startTime: '10:00 AM',
          endTime: '11:00 AM',
          subjectCode: '',
          teacherName: '',
        ),
      );
    }

    return entries;
  }

  String _canonicalDay(String token) {
    switch (token.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
      case 'tues':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
      case 'thur':
      case 'thurs':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      default:
        final lower = token.toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
    }
  }

  String _normalizeTime(String raw) {
    final text = raw.trim().toUpperCase().replaceAll('.', ':');
    final match = RegExp(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)?').firstMatch(text);
    if (match == null) return raw.trim();
    final hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '00') ?? 0;
    var period = match.group(3);
    if (period == null) {
      period = hour >= 12 || hour < 8 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : hour;
      return '${displayHour == 0 ? 12 : displayHour}:${minute.toString().padLeft(2, '0')} $period';
    }
    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }
}
