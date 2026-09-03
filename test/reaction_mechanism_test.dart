import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/reaction_models.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';

void main() {
  group('ReactionMechanismService Tests', () {
    final service = ReactionMechanismService.instance;

    test('Loads curated verified MSc reaction mechanisms', () {
      expect(service.mechanisms.length, greaterThanOrEqualTo(8));
      
      final names = service.mechanisms.map((m) => m.name).toList();
      expect(names, contains('Cannizzaro Reaction'));
      expect(names, contains('Aldol Condensation'));
      expect(names, contains('Wittig Reaction'));
      expect(names, contains('Diels-Alder [4+2] Cycloaddition'));
      expect(names, contains('Beckmann Rearrangement'));
      expect(names, contains('Benzoin Condensation'));
      expect(names, contains('SN1 Nucleophilic Substitution'));
      expect(names, contains('SN2 Nucleophilic Substitution'));
    });


    test('Search by query finds matching mechanism by name or description', () {
      final results = service.search('aldol');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Aldol Condensation');

      final wittig = service.search('ylide');
      expect(wittig, isNotEmpty);
      expect(wittig.first.name, 'Wittig Reaction');
    });

    test('Filter by category returns categorized reactions', () {
      final rearrangements = service.search('', category: ReactionCategory.rearrangements);
      expect(rearrangements, isNotEmpty);
      expect(rearrangements.any((r) => r.name.contains('Beckmann')), isTrue);

      final pericyclic = service.search('', category: ReactionCategory.pericyclic);
      expect(pericyclic, isNotEmpty);
      expect(pericyclic.any((r) => r.name.contains('Diels-Alder')), isTrue);
    });

    test('Mechanism contains valid steps and electron movement curved arrows', () {
      final cannizzaro = service.find('Cannizzaro Reaction');
      expect(cannizzaro, isNotNull);
      expect(cannizzaro!.steps, isNotEmpty);
      expect(cannizzaro.steps.first.curvedArrowNotes, isNotNull);
      expect(cannizzaro.steps.any((s) => s.intermediate != null), isTrue);
    });
  });
}
