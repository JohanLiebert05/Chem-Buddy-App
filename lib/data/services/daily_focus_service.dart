import '../models/models.dart';
import '../models/study_models.dart';
import '../models/smart_flashcard.dart';
import '../repositories/chem_repository.dart';
import '../../presentation/providers/app_providers.dart';
import '../local/local_store.dart';

class DailyFocusService {
  DailyFocusService(this.store);
  final LocalStore store;

  int countDueFlashcards(AppState state) {
    int count = 0;
    final sessions = store.all(store.studySessions).map((json) => StudySession.fromJson(json)).toList();
    for (final setJson in store.all(store.smartSets)) {
      final set = SmartFlashcardSet.fromJson(setJson);
      final setSessions = sessions.where((s) => s.flashcardSetId == set.id).toList();
      setSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      if (setSessions.isEmpty) {
        count++;
      } else {
        final last = setSessions.first;
        if (DateTime.now().difference(last.startedAt).inHours >= 24) {
          count++;
        }
      }
    }
    return count;
  }

  DailyFocus? computeFocus(AppState state, ChemRepository repo) {
    final now = DateTime.now();
    final flashcardsDue = countDueFlashcards(state);

    // 1. Check events for tests/assignments within 3 days
    final upcomingEvents = state.events.where((e) => 
      !e.completed && 
      e.dueDate.difference(now).inDays <= 3 && 
      e.dueDate.isAfter(now.subtract(const Duration(days: 1)))
    ).toList();
    
    if (upcomingEvents.isNotEmpty) {
      upcomingEvents.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final event = upcomingEvents.first;
      final subject = state.subjects.cast<Subject?>().firstWhere((s) => s?.id == event.subjectId, orElse: () => null);
      
      return DailyFocus(
        subjectName: subject?.name ?? 'Subject',
        subjectId: event.subjectId,
        reason: 'Upcoming ${event.type.name} in ${event.dueDate.difference(now).inDays} days',
        recommendedMinutes: 45,
        flashcardsDue: flashcardsDue,
        upcomingTestTitle: event.title,
        upcomingTestDate: event.dueDate,
      );
    }

    // 2. Check flashcard sets with >40% difficult cards
    final cards = store.all(store.smartCards).map((j) => SmartFlashcard.fromJson(j)).toList();
    final sets = store.all(store.smartSets).map((j) => SmartFlashcardSet.fromJson(j)).toList();
    
    for (final set in sets) {
      final setCards = cards.where((c) => c.setId == set.id).toList();
      if (setCards.isNotEmpty) {
        final difficult = setCards.where((c) => c.status == FlashcardUiState.difficult).length;
        if (difficult / setCards.length > 0.4) {
          return DailyFocus(
            subjectName: set.topic.isNotEmpty ? set.topic : 'Flashcards',
            reason: 'High number of difficult cards',
            recommendedMinutes: 25,
            flashcardsDue: flashcardsDue,
          );
        }
      }
    }

    // 3. Check flashcard sets with pending review (>24h)
    if (flashcardsDue > 0) {
      return DailyFocus(
        subjectName: 'Review Flashcards',
        reason: '$flashcardsDue sets pending review',
        recommendedMinutes: 20,
        flashcardsDue: flashcardsDue,
      );
    }

    // 4. Check today's timetable entries
    final todaySlots = repo.slotsFor(now);
    if (todaySlots.isNotEmpty) {
      final firstSlot = todaySlots.first;
      final subject = state.subjects.cast<Subject?>().firstWhere((s) => s?.id == firstSlot.subjectId, orElse: () => null);
      if (subject != null) {
        return DailyFocus(
          subjectName: subject.name,
          subjectId: subject.id,
          reason: 'Prep for upcoming class',
          recommendedMinutes: 15,
          flashcardsDue: flashcardsDue,
        );
      }
    }

    // 5. Subject with lowest attendance %
    if (state.subjects.isNotEmpty) {
      Subject? lowestSubject;
      double lowestPercent = 100.0;
      for (final subject in state.subjects) {
        final stats = repo.statsFor(subject.id);
        if (stats.total > 0 && stats.percent < lowestPercent) {
          lowestPercent = stats.percent;
          lowestSubject = subject;
        }
      }
      if (lowestSubject != null && lowestPercent < 75.0) {
        return DailyFocus(
          subjectName: lowestSubject.name,
          subjectId: lowestSubject.id,
          reason: 'Catch up on missed topics',
          recommendedMinutes: 30,
          flashcardsDue: flashcardsDue,
        );
      }
    }

    // 6. General revision for most recent subject
    if (state.subjects.isNotEmpty) {
      return DailyFocus(
        subjectName: state.subjects.last.name,
        subjectId: state.subjects.last.id,
        reason: 'General Revision',
        recommendedMinutes: 20,
        flashcardsDue: flashcardsDue,
      );
    }

    return null;
  }
}
