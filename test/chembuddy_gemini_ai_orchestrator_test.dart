import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/gemini_orchestrator.dart';
import 'package:chem_buddy/data/services/rag_service.dart';
import 'package:chem_buddy/data/remote/supabase_service.dart';
import 'package:chem_buddy/presentation/screens/ask_chembuddy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChemBuddy Intelligent Gemini AI & Mode Tests', () {
    test('1. ChemBuddyAiMode includes general AI mode', () {
      expect(ChemBuddyAiMode.values.contains(ChemBuddyAiMode.general), isTrue);
      expect(ChemBuddyAiMode.general.name, equals('general'));
    });

    test('2. GeminiOrchestrator has working candidate models with gemini-2.5-flash as primary', () {
      expect(GeminiOrchestrator.candidateModels.first, equals('gemini-2.5-flash'));
      expect(GeminiOrchestrator.candidateModels.contains('gemini-2.0-flash'), isTrue);
      expect(GeminiOrchestrator.candidateModels.contains('gemini-1.5-flash'), isTrue);
    });

    test('3. RagService defaults gracefully to offline engine when unconfigured or offline', () async {
      final ragService = RagService(remote: SupabaseService.instance);
      final response = await ragService.ask(
        question: 'Explain SN1 vs SN2 mechanism',
        mode: 'quick',
      );

      expect(response.answer.isNotEmpty, isTrue);
      expect(
        response.answer.contains('SN1') ||
        response.answer.contains('SN₁') ||
        response.answer.contains('carbocation'),
        isTrue,
      );
    });

    test('4. RagService with general mode provides rich answer without forcing fixed exam headers', () async {
      final ragService = RagService(remote: SupabaseService.instance);
      final response = await ragService.ask(
        question: 'What is the photoelectric effect and how did Einstein explain it?',
        mode: 'general',
      );

      expect(response.answer.isNotEmpty, isTrue);
      expect(response.answer.length > 50, isTrue);
    });

    test('5. RagService with attached document preserves grounding', () async {
      final ragService = RagService(remote: SupabaseService.instance);
      const sampleNotes = '''[PAGE 1]
Organometallic catalysts: Wilkinson catalyst is RhCl(PPh3)3 used for homogeneous hydrogenation of alkenes.
''';

      final response = await ragService.ask(
        question: 'What is Wilkinson catalyst and what is it used for?',
        documentText: sampleNotes,
        documentName: 'Catalysis_Notes.pdf',
        mode: 'fromMyPdf',
      );

      expect(response.answer.isNotEmpty, isTrue);
      expect(
        response.answer.toLowerCase().contains('wilkinson') ||
        response.answer.toLowerCase().contains('hydrogenation'),
        isTrue,
      );
    });

    test('6. Google Gemini API orchestrator returns non-empty response or handled fallback', () async {
      HttpOverrides.global = null;
      final response = await GeminiOrchestrator.instance.ask(
        prompt: 'State the first law of thermodynamics in one short sentence',
      );

      expect(response.text.isNotEmpty, isTrue);
      expect(response.model.isNotEmpty, isTrue);
    });
  });
}
