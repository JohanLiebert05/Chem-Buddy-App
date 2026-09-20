import 'package:flutter_test/flutter_test.dart';

import 'package:chem_buddy/data/models/library_models.dart';
import 'package:chem_buddy/data/services/psychology_facts_service.dart';

void main() {
  group('PsychologyFactsService & Model Tests', () {
    test('1. PsychologyFactsService contains at least 120 curated facts with full metadata', () {
      final service = PsychologyFactsService.instance;
      final facts = service.getAllFacts();
      expect(facts.length, greaterThanOrEqualTo(120));

      for (final f in facts) {
        expect(f.id, greaterThan(0));
        expect(f.title.trim().isNotEmpty, isTrue, reason: 'Fact ${f.id} has empty title');
        expect(f.category.trim().isNotEmpty, isTrue, reason: 'Fact ${f.id} has empty category');
        expect(f.fact.trim().isNotEmpty, isTrue, reason: 'Fact ${f.id} has empty fact content');
        expect(f.takeaway.trim().isNotEmpty, isTrue, reason: 'Fact ${f.id} has empty takeaway');
        expect(f.emoji.trim().isNotEmpty, isTrue, reason: 'Fact ${f.id} has empty emoji');
      }
    });

    test('2. getFactForDay rotates deterministically and consecutive days differ', () {
      final service = PsychologyFactsService.instance;
      final day1 = DateTime(2026, 9, 20);
      final day2 = DateTime(2026, 9, 21);
      final day3 = DateTime(2026, 9, 22);

      final fact1 = service.getFactForDay(day1);
      final fact2 = service.getFactForDay(day2);
      final fact3 = service.getFactForDay(day3);

      // Deterministic check
      expect(service.getFactForDay(day1).id, equals(fact1.id));
      expect(service.getFactForDay(day2).id, equals(fact2.id));

      // Uniqueness check for consecutive days
      expect(fact1.id, isNot(equals(fact2.id)));
      expect(fact2.id, isNot(equals(fact3.id)));
      expect(fact1.id, isNot(equals(fact3.id)));
    });

    test('3. Day-of-year rotation across a month produces high variety', () {
      final service = PsychologyFactsService.instance;
      final Set<int> seenIds = {};
      final startDate = DateTime(2026, 9, 1);

      for (int i = 0; i < 30; i++) {
        final date = startDate.add(Duration(days: i));
        final fact = service.getFactForDay(date);
        seenIds.add(fact.id);
      }

      // Over 30 consecutive days, we expect at least 25 unique facts
      expect(seenIds.length, greaterThanOrEqualTo(25));
    });

    test('4. PsychologyFact JSON serialization and deserialization', () {
      const fact = PsychologyFact(
        id: 42,
        title: 'The Peak-End Rule',
        category: 'Emotional Intelligence',
        emoji: '🏔️',
        fact: 'People judge an experience by its peak and end.',
        takeaway: 'End study sessions on a rewarding high note.',
      );

      final json = fact.toJson();
      expect(json['id'], equals(42));
      expect(json['title'], equals('The Peak-End Rule'));
      expect(json['category'], equals('Emotional Intelligence'));

      final fromJson = PsychologyFact.fromJson(json);
      expect(fromJson.id, equals(42));
      expect(fromJson.title, equals(fact.title));
      expect(fromJson.category, equals(fact.category));
      expect(fromJson.fact, equals(fact.fact));
      expect(fromJson.takeaway, equals(fact.takeaway));
      expect(fromJson.emoji, equals(fact.emoji));
    });

    test('5. Category filtering and badge colors', () {
      final service = PsychologyFactsService.instance;
      final biasFacts = service.getFactsByCategory('Cognitive Biases');
      expect(biasFacts.isNotEmpty, isTrue);

      final color1 = PsychologyFactsService.getCategoryColor('Cognitive Biases');
      final color2 = PsychologyFactsService.getCategoryColor('Emotional Intelligence');
      expect(color1, isNot(equals(color2)));
    });

    test('6. NotificationPrefs includes dailyPsychologyFact and serializes properly', () {
      const prefs = NotificationPrefs();
      expect(prefs.dailyPsychologyFact, isTrue);
      expect(prefs.psychologyFactHour, equals(20));
      expect(prefs.psychologyFactMinute, equals(0));

      final toggled = prefs.copyWith(dailyPsychologyFact: false, psychologyFactHour: 19);
      expect(toggled.dailyPsychologyFact, isFalse);
      expect(toggled.psychologyFactHour, equals(19));

      final json = toggled.toJson();
      expect(json['dailyPsychologyFact'], isFalse);
      expect(json['psychologyFactHour'], equals(19));

      final restored = NotificationPrefs.fromJson(json);
      expect(restored.dailyPsychologyFact, isFalse);
      expect(restored.psychologyFactHour, equals(19));
    });
  });
}
