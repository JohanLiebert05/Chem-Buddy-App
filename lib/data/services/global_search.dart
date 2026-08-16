import '../../presentation/providers/app_providers.dart';

class SearchHit {
  const SearchHit({required this.kind, required this.title, required this.subtitle, this.id});
  final String kind;
  final String title;
  final String subtitle;
  final String? id;
}

class GlobalSearch {
  static List<SearchHit> query(AppState state, String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool has(String? v) => (v ?? '').toLowerCase().contains(q);
    final hits = <SearchHit>[];

    for (final s in state.subjects) {
      if (has(s.name) || has(s.code) || has(s.teacher)) {
        hits.add(SearchHit(kind: 'Subject', title: s.name, subtitle: s.code, id: s.id));
      }
    }
    for (final p in state.pdfs) {
      if (has(p.displayName) || has(p.filename)) {
        hits.add(SearchHit(kind: 'PDF', title: p.displayName, subtitle: p.filename, id: p.id));
      }
    }
    for (final n in state.notes) {
      if (has(n.title) || has(n.body)) {
        hits.add(SearchHit(kind: 'Note', title: n.title, subtitle: n.body, id: n.id));
      }
    }
    for (final e in state.entries) {
      if (has(e.displayName) || has(e.subjectCode) || has(e.room) || has(e.teacherName)) {
        hits.add(SearchHit(kind: 'Timetable', title: e.displayName, subtitle: '${e.dayOfWeek} ${e.startTime}', id: e.id));
      }
    }
    for (final r in state.reminders) {
      if (has(r.title) || has(r.kind) || has(r.notes)) {
        hits.add(SearchHit(kind: 'Reminder', title: r.title, subtitle: r.kind, id: r.id));
      }
    }
    for (final e in state.events) {
      if (has(e.title) || has(e.description)) {
        hits.add(SearchHit(kind: 'Deadline', title: e.title, subtitle: e.type.name, id: e.id));
      }
    }
    for (final c in state.flashcards) {
      if (has(c.question) || has(c.answer) || c.tags.any(has)) {
        hits.add(SearchHit(kind: 'Flashcard', title: c.question, subtitle: c.answer, id: c.id));
      }
    }
    return hits;
  }
}
