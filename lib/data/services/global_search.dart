import '../../presentation/providers/app_providers.dart';
import 'reaction_mechanism_service.dart';

class SearchHit {
  const SearchHit({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.id,
    this.route,
  });

  final String kind;
  final String title;
  final String subtitle;
  final String? id;
  final String? route;
}

class GlobalSearch {
  static List<SearchHit> query(AppState state, String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool has(String? v) => (v ?? '').toLowerCase().contains(q);
    final hits = <SearchHit>[];

    // 1. Chemistry Reaction Mechanisms
    for (final m in ReactionMechanismService.curatedMechanisms) {
      if (has(m.name) || has(m.summary) || has(m.reactants) || has(m.products) || m.aliases.any(has)) {
        hits.add(SearchHit(
          kind: 'Mechanism',
          title: m.name,
          subtitle: m.summary,
          id: m.id,
          route: 'mechanism',
        ));
      }
    }

    // 2. Chemistry Toolkit Calculators
    final calculators = [
      ('Molar Mass Formula Parser', 'Calculate molecular weight of compounds (e.g. H2SO4, KMnO4)', 'toolkit_molarmass'),
      ('Molarity & Normality Calculator', 'Solution concentrations, moles, and equivalents (M = n/V, N = M × n)', 'toolkit_molarity'),
      ('Dilution Law Calculator', 'C1V1 = C2V2 dilution calculations', 'toolkit_dilution'),
      ('pH & pOH Calculator', 'Hydrogen ion concentrations and logarithmic pH scales', 'toolkit_ph'),
      ('Henderson-Hasselbalch Buffer', 'Buffer system pH from pKa and conjugate pair ratios', 'toolkit_buffer'),
      ('Gibbs Free Energy & Spontaneity', 'ΔG = ΔH - TΔS thermodynamic calculations', 'toolkit_gibbs'),
      ('Arrhenius Reaction Kinetics', 'Rate constant k from activation energy Ea and frequency factor A', 'toolkit_arrhenius'),
      ('Beer-Lambert UV-Vis Law', 'Absorbance A = ε·c·l and percent transmittance %T', 'toolkit_beerlambert'),
      ('Nernst Equation & Cell Potential', 'Non-standard electrode potentials and cell voltages', 'toolkit_nernst'),
    ];
    for (final calc in calculators) {
      if (has(calc.$1) || has(calc.$2)) {
        hits.add(SearchHit(
          kind: 'Calculator',
          title: calc.$1,
          subtitle: calc.$2,
          id: calc.$3,
          route: 'toolkit',
        ));
      }
    }

    // 3. PDFs & Study Material
    for (final p in state.pdfs) {
      if (has(p.displayName) || has(p.filename)) {
        hits.add(SearchHit(kind: 'PDF', title: p.displayName, subtitle: p.filename, id: p.id, route: 'pdf'));
      }
    }

    // 4. Notes
    for (final n in state.notes) {
      if (has(n.title) || has(n.body)) {
        hits.add(SearchHit(kind: 'Note', title: n.title, subtitle: n.body, id: n.id, route: 'note'));
      }
    }

    // 5. Subjects
    for (final s in state.subjects) {
      if (has(s.name) || has(s.code) || has(s.teacher)) {
        hits.add(SearchHit(kind: 'Subject', title: s.name, subtitle: s.code, id: s.id, route: 'subject'));
      }
    }

    // 6. Timetable
    for (final e in state.entries) {
      if (has(e.displayName) || has(e.subjectCode) || has(e.room) || has(e.teacherName)) {
        hits.add(SearchHit(kind: 'Timetable', title: e.displayName, subtitle: '${e.dayOfWeek} ${e.startTime}', id: e.id, route: 'timetable'));
      }
    }

    // 7. Flashcards
    for (final c in state.flashcards) {
      if (has(c.question) || has(c.answer) || c.tags.any(has)) {
        hits.add(SearchHit(kind: 'Flashcard', title: c.question, subtitle: c.answer, id: c.id, route: 'flashcard'));
      }
    }

    // 8. Reminders
    for (final r in state.reminders) {
      if (has(r.title) || has(r.kind) || has(r.notes)) {
        hits.add(SearchHit(kind: 'Reminder', title: r.title, subtitle: r.kind, id: r.id, route: 'reminder'));
      }
    }

    // 9. Deadlines / Academic Events
    for (final e in state.events) {
      if (has(e.title) || has(e.description)) {
        hits.add(SearchHit(kind: 'Deadline', title: e.title, subtitle: e.type.name, id: e.id, route: 'event'));
      }
    }

    return hits;
  }
}
