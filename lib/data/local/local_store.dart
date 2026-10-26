import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/pdf_ocr_models.dart';

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
  static const pdfOcrBundles = 'pdf_ocr_bundles';

  static const accountControl = 'account_control';
  static String? _activeAccount;
  static String? get activeAccount => _activeAccount;
  static const _names = [
    profile,
    subjects,
    attendance,
    timetable,
    timetableEntries,
    events,
    notes,
    pdfs,
    flashcards,
    smartSets,
    smartCards,
    flashcardAttempts,
    studySessions,
    pendingSync,
    reminders,
    settings,
    aiConversations,
    aiMessages,
    pdfSummaries,
    pdfTopics,
    pdfQuizzes,
    quizResults,
    appTutorialState,
    pyqPredictions,
    pdfOcrBundles,
  ];
  static String _name(String name, String? account) => account == null
      ? name
      : 'account_${sha256.convert(utf8.encode(account))}_$name';
  static Box box(String name) => Hive.box(_name(name, _activeAccount));
  static Future<void> openAll() async {
    await Hive.initFlutter();
    await Hive.openBox(accountControl);
    _activeAccount = Hive.box(accountControl).get('active') as String?;
    await Future.wait(
      _names.map((name) => Hive.openBox(_name(name, _activeAccount))),
    );
  }

  /// Copy legacy records once, only to the matching account (or the initial onboarding account).
  /// Legacy files are retained, so migration never destroys the original data.
  static Future<void> switchAccount(
    String account, {
    String registerNumber = '',
  }) async {
    if (account == _activeAccount) {
      return;
    }
    if (!Hive.isBoxOpen(accountControl)) {
      await Hive.openBox(accountControl);
    }
    final control = Hive.box(accountControl);
    final next = <String, Box>{};
    for (final name in _names) {
      next[name] = await Hive.openBox(_name(name, account));
    }
    if (account != 'guest' &&
        control.get('legacyOwner') == null &&
        next[profile]!.get('current') == null) {
      final legacyProfile = await Hive.openBox(profile);
      final raw = legacyProfile.get('current');
      final old = raw is Map ? raw : const {};
      String normalize(String value) =>
          value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final oldRegister = normalize(old['registerNumber'] as String? ?? '');
      final matches =
          oldRegister.isNotEmpty && oldRegister == normalize(registerNumber);
      final initialSetup = oldRegister.isEmpty && old['loggedIn'] != true;
      if (matches || initialSetup) {
        for (final name in _names) {
          final legacy = await Hive.openBox(name);
          await next[name]!.putAll(legacy.toMap());
        }
        await control.put('legacyOwner', account);
      }
    }
    await control.put('active', account);
    _activeAccount = account;
  }
}

class LocalStore {
  Box get _profile => HiveBoxes.box(HiveBoxes.profile);
  Box get subjects => HiveBoxes.box(HiveBoxes.subjects);
  Box get attendance => HiveBoxes.box(HiveBoxes.attendance);
  Box get timetable => HiveBoxes.box(HiveBoxes.timetable);
  Box get timetableEntries => HiveBoxes.box(HiveBoxes.timetableEntries);
  Box get events => HiveBoxes.box(HiveBoxes.events);
  Box get notes => HiveBoxes.box(HiveBoxes.notes);
  Box get pdfs => HiveBoxes.box(HiveBoxes.pdfs);
  Box get flashcards => HiveBoxes.box(HiveBoxes.flashcards);
  Box get smartSets => HiveBoxes.box(HiveBoxes.smartSets);
  Box get smartCards => HiveBoxes.box(HiveBoxes.smartCards);
  Box get flashcardAttempts => HiveBoxes.box(HiveBoxes.flashcardAttempts);
  Box get studySessions => HiveBoxes.box(HiveBoxes.studySessions);
  Box get pendingSync => HiveBoxes.box(HiveBoxes.pendingSync);
  Box get reminders => HiveBoxes.box(HiveBoxes.reminders);
  Box get settings => HiveBoxes.box(HiveBoxes.settings);
  Box get aiConversations => HiveBoxes.box(HiveBoxes.aiConversations);
  Box get aiMessages => HiveBoxes.box(HiveBoxes.aiMessages);
  Box get pdfSummaries => HiveBoxes.box(HiveBoxes.pdfSummaries);
  Box get pdfTopics => HiveBoxes.box(HiveBoxes.pdfTopics);
  Box get pdfQuizzes => HiveBoxes.box(HiveBoxes.pdfQuizzes);
  Box get quizResults => HiveBoxes.box(HiveBoxes.quizResults);
  Box get appTutorialState => HiveBoxes.box(HiveBoxes.appTutorialState);
  Box get pyqPredictions => HiveBoxes.box(HiveBoxes.pyqPredictions);
  Box get pdfOcrBundles => HiveBoxes.box(HiveBoxes.pdfOcrBundles);

  Map<String, dynamic>? getProfile() {
    final raw = _profile.get('current');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  Future<void> saveProfile(Map<String, dynamic> json) =>
      _profile.put('current', json);

  DocumentOcrBundle? getDocumentOcrBundle(String docId) {
    try {
      final raw = pdfOcrBundles.get(docId);
      if (raw is Map) {
        return DocumentOcrBundle.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveDocumentOcrBundle(DocumentOcrBundle bundle) =>
      pdfOcrBundles.put(bundle.docId, bundle.toJson());

  Future<void> deleteDocumentOcrBundle(String docId) =>
      pdfOcrBundles.delete(docId);

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
      pdfOcrBundles.clear(),
    ]);
  }

  List<Map<String, dynamic>> all(Box box) {
    return box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> put(Box box, String id, Map<String, dynamic> json) =>
      box.put(id, json);

  Future<void> delete(Box box, String id) => box.delete(id);
}
