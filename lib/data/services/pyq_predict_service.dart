import 'package:uuid/uuid.dart';

import '../local/local_store.dart';
import '../models/pyq_predict_models.dart';
import '../remote/supabase_service.dart';
import 'pdf_text_extraction_service.dart';

class PyqPredictService {
  PyqPredictService({LocalStore? store, SupabaseService? remote})
      : _store = store ?? LocalStore(),
        _remote = remote ?? SupabaseService.instance;

  final LocalStore _store;
  final SupabaseService _remote;

  /// Extracts text from multiple PDF papers and calls the prediction engine.
  Future<ImportantQuestionsPrediction> analyzeAndPredict({
    required List<String> filePaths,
    required List<String> fileNames,
    required String subjectName,
    required String universityName,
    String yearRange = '',
    void Function(String status, double progress)? onProgress,
  }) async {
    if (filePaths.length < 3) {
      throw Exception('Please select at least 3 previous year question paper PDFs.');
    }

    final combinedBuffer = StringBuffer();
    final total = filePaths.length;

    for (var i = 0; i < total; i++) {
      final name = i < fileNames.length ? fileNames[i] : 'Paper ${i + 1}';
      onProgress?.call('Extracting text from $name (${i + 1}/$total)...', (i / total) * 0.4);

      try {
        final text = await PdfTextExtractionService.instance.extractFromPath(filePaths[i]);
        if (text.trim().isNotEmpty) {
          combinedBuffer.writeln('\n\n=== QUESTION PAPER ${i + 1}: $name ===\n');
          combinedBuffer.writeln(text.trim());
        }
      } catch (e) {
        // Continue with other files if one fails
      }
    }

    final combinedText = combinedBuffer.toString().trim();
    if (combinedText.length < 150) {
      throw Exception(
        'Could not extract sufficient text from the selected papers. Ensure they are digital PDFs or readable scans.',
      );
    }

    onProgress?.call('Analyzing pattern recurrence across $total papers...', 0.55);

    // Call Supabase Edge Function
    final sessionId = const Uuid().v4();
    final res = await _remote.invokeFunction(
      'predict-important-questions',
      {
        'combinedText': combinedText,
        'subjectName': subjectName.trim().isEmpty ? 'MSc Chemistry' : subjectName.trim(),
        'universityName': universityName.trim().isEmpty ? 'University' : universityName.trim(),
        'paperCount': total,
        'yearRange': yearRange,
        'sessionId': sessionId,
      },
      timeout: const Duration(seconds: 60),
    );

    onProgress?.call('Structuring predicted questions & marking rubrics...', 0.9);

    if (res is Map) {
      final map = Map<String, dynamic>.from(res);
      if (map['error'] != null) {
        throw Exception(map['message']?.toString() ?? map['error'].toString());
      }

      final prediction = ImportantQuestionsPrediction(
        id: sessionId,
        subjectName: subjectName.trim().isEmpty ? 'MSc Chemistry' : subjectName.trim(),
        universityName: universityName.trim().isEmpty ? 'University' : universityName.trim(),
        paperCount: total,
        createdAt: DateTime.now(),
        frequentlyAskedTopics: (map['frequently_asked_topics'] as List? ?? [])
            .map((e) => FrequentTopic.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        predictedQuestions: (map['predicted_questions'] as List? ?? [])
            .map((e) => PredictedQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        topicFrequencySummary: (map['topic_frequency_summary'] as List? ?? [])
            .map((e) => TopicFrequencySummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        examStrategy: map['exam_strategy']?.toString() ?? 'Focus on high-recurrence mechanisms and key formulas.',
        isCached: map['cached'] as bool? ?? false,
      );

      // Save to Hive
      await savePrediction(prediction);
      onProgress?.call('Prediction complete!', 1.0);
      return prediction;
    } else {
      throw Exception('Invalid response format from prediction service.');
    }
  }

  /// Saves prediction to local storage
  Future<void> savePrediction(ImportantQuestionsPrediction pred) async {
    await _store.put(_store.pyqPredictions, pred.id, pred.toJson());
  }

  /// Retrieves past predictions from local storage
  List<ImportantQuestionsPrediction> getPastPredictions() {
    final list = _store.all(_store.pyqPredictions);
    final predictions = list
        .map((j) => ImportantQuestionsPrediction.fromJson(j))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return predictions;
  }

  /// Deletes a saved prediction
  Future<void> deletePrediction(String id) async {
    await _store.delete(_store.pyqPredictions, id);
  }
}
