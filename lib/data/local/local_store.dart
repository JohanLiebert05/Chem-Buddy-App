import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const profile = 'profile';
  static const subjects = 'subjects';
  static const attendance = 'attendance';
  static const timetable = 'timetable';
  static const timetableEntries = 'timetable_entries';
  static const events = 'events';
  static const notes = 'notes';
  static const pdfs = 'pdfs';
  static const flashcards = 'flashcards';
  static const smartSets = 'smart_flashcard_sets';
  static const smartCards = 'smart_flashcards';
  static const flashcardAttempts = 'flashcard_attempts';
  static const studySessions = 'study_sessions';
  static const pendingSync = 'pending_sync';
  static const reminders = 'reminders';
  static const settings = 'settings';
  static const aiConversations = 'ai_conversations';
  static const aiMessages = 'ai_messages';
  static const pdfSummaries = 'pdf_summaries';
  static const pdfTopics = 'pdf_topics';
  static const pdfQuizzes = 'pdf_quizzes';
  static const quizResults = 'quiz_results';
  static const appTutorialState = 'app_tutorial_state';
  static const pyqPredictions = 'pyq_predictions';

  static Future<void> openAll() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(profile),
      Hive.openBox(subjects),
      Hive.openBox(attendance),
      Hive.openBox(timetable),
      Hive.openBox(timetableEntries),
      Hive.openBox(events),
      Hive.openBox(notes),
      Hive.openBox(pdfs),
      Hive.openBox(flashcards),
      Hive.openBox(smartSets),
      Hive.openBox(smartCards),
      Hive.openBox(flashcardAttempts),
      Hive.openBox(studySessions),
      Hive.openBox(pendingSync),
      Hive.openBox(reminders),
      Hive.openBox(settings),
      Hive.openBox(aiConversations),
      Hive.openBox(aiMessages),
      Hive.openBox(pdfSummaries),
      Hive.openBox(pdfTopics),
      Hive.openBox(pdfQuizzes),
      Hive.openBox(quizResults),
      Hive.openBox(appTutorialState),
      Hive.openBox(pyqPredictions),
    ]);
  }
}

class LocalStore {
  Box get _profile => Hive.box(HiveBoxes.profile);
  Box get subjects => Hive.box(HiveBoxes.subjects);
  Box get attendance => Hive.box(HiveBoxes.attendance);
  Box get timetable => Hive.box(HiveBoxes.timetable);
  Box get timetableEntries => Hive.box(HiveBoxes.timetableEntries);
  Box get events => Hive.box(HiveBoxes.events);
  Box get notes => Hive.box(HiveBoxes.notes);
  Box get pdfs => Hive.box(HiveBoxes.pdfs);
  Box get flashcards => Hive.box(HiveBoxes.flashcards);
  Box get smartSets => Hive.box(HiveBoxes.smartSets);
  Box get smartCards => Hive.box(HiveBoxes.smartCards);
  Box get flashcardAttempts => Hive.box(HiveBoxes.flashcardAttempts);
  Box get studySessions => Hive.box(HiveBoxes.studySessions);
  Box get pendingSync => Hive.box(HiveBoxes.pendingSync);
  Box get reminders => Hive.box(HiveBoxes.reminders);
  Box get settings => Hive.box(HiveBoxes.settings);
  Box get aiConversations => Hive.box(HiveBoxes.aiConversations);
  Box get aiMessages => Hive.box(HiveBoxes.aiMessages);
  Box get pdfSummaries => Hive.box(HiveBoxes.pdfSummaries);
  Box get pdfTopics => Hive.box(HiveBoxes.pdfTopics);
  Box get pdfQuizzes => Hive.box(HiveBoxes.pdfQuizzes);
  Box get quizResults => Hive.box(HiveBoxes.quizResults);
  Box get appTutorialState => Hive.box(HiveBoxes.appTutorialState);
  Box get pyqPredictions => Hive.box(HiveBoxes.pyqPredictions);

  Map<String, dynamic>? getProfile() {
    final raw = _profile.get('current');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> saveProfile(Map<String, dynamic> json) => _profile.put('current', json);

  Future<void> clearAll() async {
    await Future.wait([
      _profile.clear(),
      subjects.clear(),
      attendance.clear(),
      timetable.clear(),
      timetableEntries.clear(),
      events.clear(),
      notes.clear(),
      pdfs.clear(),
      flashcards.clear(),
      smartSets.clear(),
      smartCards.clear(),
      flashcardAttempts.clear(),
      studySessions.clear(),
      pendingSync.clear(),
      reminders.clear(),
      settings.clear(),
      aiConversations.clear(),
      aiMessages.clear(),
      pdfSummaries.clear(),
      pdfTopics.clear(),
      pdfQuizzes.clear(),
      quizResults.clear(),
      appTutorialState.clear(),
      pyqPredictions.clear(),
    ]);
  }

  List<Map<String, dynamic>> all(Box box) {
    return box.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> put(Box box, String id, Map<String, dynamic> json) => box.put(id, json);

  Future<void> delete(Box box, String id) => box.delete(id);
}
