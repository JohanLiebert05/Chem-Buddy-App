import 'package:uuid/uuid.dart';
import '../models/study_models.dart';
import '../models/models.dart';
import '../models/smart_flashcard.dart';
import '../repositories/chem_repository.dart';
import '../../presentation/providers/app_providers.dart';
import '../local/local_store.dart';
import 'daily_focus_service.dart';

class StudySessionService {
  StudySessionService(this.store, this.focusService);
  final LocalStore store;
  final DailyFocusService focusService;

  StudyPlan? generatePlan(AppState state, ChemRepository repo, {int targetMinutes = 25}) {
    final now = DateTime.now();
    final steps = <StudyStep>[];
    int currentMinutes = 0;
    
    final upcomingTests = state.events.where((e) => 
      !e.completed && 
      e.type == EventType.test &&
      e.dueDate.difference(now).inDays <= 7 &&
      e.dueDate.isAfter(now.subtract(const Duration(days: 1)))
    ).toList();

    String? subjectFocus;

    if (upcomingTests.isNotEmpty) {
      upcomingTests.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final test = upcomingTests.first;
      subjectFocus = test.subjectId;
      
      final subject = state.subjects.cast<Subject?>().firstWhere((s) => s?.id == test.subjectId, orElse: () => null);
      
      steps.add(StudyStep(
        title: 'Review ${subject?.name ?? 'Subject'}',
        description: 'Prepare for upcoming test: ${test.title}',
        durationMinutes: 8,
        type: StudyStepType.revision,
      ));
      currentMinutes += 8;
    }

    final flashcardsDueCount = focusService.countDueFlashcards(state);
    final sets = store.all(store.smartSets).map((j) => SmartFlashcardSet.fromJson(j)).toList();
    
    if (flashcardsDueCount > 0 && currentMinutes < targetMinutes) {
      final sessions = store.all(store.studySessions).map((j) => StudySession.fromJson(j)).toList();
      String? setIdToReview;
      for (final set in sets) {
        final setSessions = sessions.where((s) => s.flashcardSetId == set.id).toList();
        setSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        if (setSessions.isEmpty || DateTime.now().difference(setSessions.first.startedAt).inHours >= 24) {
          setIdToReview = set.id;
          break;
        }
      }
      
      if (setIdToReview != null) {
        steps.add(StudyStep(
          title: 'Review Flashcards',
          description: 'Spaced repetition for pending cards',
          durationMinutes: 7,
          type: StudyStepType.flashcards,
          resourceId: setIdToReview,
        ));
        currentMinutes += 7;
      }
    }

    if (sets.isNotEmpty && currentMinutes < targetMinutes) {
      steps.add(StudyStep(
        title: 'Quick Quiz',
        description: 'Test your knowledge on recent topics',
        durationMinutes: 10,
        type: StudyStepType.quiz,
        resourceId: sets.first.id,
      ));
      currentMinutes += 10;
    }

    if (currentMinutes < targetMinutes && state.pdfs.isNotEmpty) {
      final remaining = targetMinutes - currentMinutes;
      steps.add(StudyStep(
        title: 'Read Material',
        description: 'Read ${state.pdfs.first.displayName}',
        durationMinutes: remaining,
        type: StudyStepType.reading,
        resourceId: state.pdfs.first.id,
      ));
      currentMinutes += remaining;
    }

    if (steps.isEmpty) return null;

    return StudyPlan(
      id: const Uuid().v4(),
      steps: steps,
      totalMinutes: currentMinutes,
      createdAt: now,
      subjectFocus: subjectFocus,
    );
  }
}
