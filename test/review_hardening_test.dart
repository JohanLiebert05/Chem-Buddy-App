import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/data/remote/supabase_service.dart';
import 'package:chem_buddy/data/services/gemini_orchestrator.dart';
import 'package:chem_buddy/data/services/pending_sync_service.dart';
import 'package:chem_buddy/data/services/rdkit_service.dart';
import 'package:chem_buddy/data/services/psychology_facts_service.dart';

class FakeRemote implements SupabaseService {
  String? uid = 'user-a';
  bool rejectWrites = false;
  final requests = <Map<String, dynamic>>[];
  @override
  bool get configured => true;
  @override
  String? get userId => uid;
  @override
  Future<dynamic> invokeFunction(
    String name,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 45),
    int maxRetries = 3,
  }) async {
    requests.add(body);
    return {'text': 'Test answer', 'model': 'test'};
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {
    if (rejectWrites) throw StateError('Rejected write');
  }

  @override
  Future<void> remove(String table, String id) async {
    if (rejectWrites) throw StateError('Rejected delete');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'AI forwards PDF context and separates document/mode/account caches',
    () async {
      final remote = FakeRemote();
      final ai = GeminiOrchestrator(remote: remote);
      await ai.ask(
        prompt: 'Explain this',
        documentContext: '[PAGE 2] Aldol.',
        mode: 'fromMyPdf',
      );
      expect(remote.requests.single['document_context'], contains('Aldol'));
      expect(remote.requests.single['mode'], 'fromMyPdf');
      await ai.ask(
        prompt: 'Explain this',
        documentContext: '[PAGE 2] Aldol.',
        mode: 'fromMyPdf',
      );
      expect(remote.requests.length, 1);
      await ai.ask(
        prompt: 'Explain this',
        documentContext: '[PAGE 8] Wittig.',
        mode: 'fromMyPdf',
      );
      await ai.ask(
        prompt: 'Explain this',
        documentContext: '[PAGE 8] Wittig.',
        mode: '10m',
      );
      remote.uid = 'user-b';
      await ai.ask(
        prompt: 'Explain this',
        documentContext: '[PAGE 8] Wittig.',
        mode: '10m',
      );
      expect(remote.requests.length, 4);
    },
  );

  test('unsupported descriptor structures are rejected', () async {
    for (final smiles in ['[Na+].[Cl-]', '[13CH4]', 'c1cc[nH]c1', '[Fe+2]']) {
      await expectLater(
        RdkitService.instance.calculateDescriptors(smiles),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('facts traverse the complete catalog across a year boundary', () {
    final service = PsychologyFactsService.instance;
    final count = service.getAllFacts().length;
    final start = DateTime(2026, 12, 1);
    final ids = List.generate(
      count,
      (i) => service.getFactForDay(start.add(Duration(days: i))).id,
    );
    expect(ids.toSet().length, count);
    expect(
      service.getFactForDay(start.add(Duration(days: count))).id,
      ids.first,
    );
  });

  group('Account isolation and durable synchronization', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('chembuddy_review_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => dir.path,
          );
      await HiveBoxes.openAll();
    });
    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test(
      'legacy records migrate only to owner and survive account switching',
      () async {
        final store = LocalStore();
        await store.saveProfile({'registerNumber': 'MSC001', 'loggedIn': true});
        await store.notes.put('private', {'title': 'A notes'});
        await HiveBoxes.switchAccount('user:b', registerNumber: 'MSC002');
        expect(store.notes.isEmpty, isTrue);
        await HiveBoxes.switchAccount('user:a', registerNumber: 'MSC001');
        expect(store.notes.get('private')['title'], 'A notes');
        await store.notes.put('new', {'title': 'More A notes'});
        await HiveBoxes.switchAccount('guest');
        expect(store.notes.isEmpty, isTrue);
        await HiveBoxes.switchAccount('user:b', registerNumber: 'MSC002');
        expect(store.notes.isEmpty, isTrue);
        await HiveBoxes.switchAccount('user:a', registerNumber: 'MSC001');
        expect(store.notes.length, 2);
      },
    );

    test('failed write stays queued until acknowledged by its owner', () async {
      await HiveBoxes.switchAccount('user:a', registerNumber: 'MSC001');
      final store = LocalStore();
      final remote = FakeRemote()..rejectWrites = true;
      final sync = PendingSyncService(store, remote);
      await sync.upsert('notes', {'id': 'n1', 'title': 'Unsynced'});
      expect(store.pendingSync.length, 1);
      await sync.flush();
      expect(store.pendingSync.length, 1);
      remote.uid = 'user-b';
      remote.rejectWrites = false;
      await sync.flush();
      expect(store.pendingSync.length, 1);
      remote.uid = 'user-a';
      await sync.flush();
      expect(store.pendingSync.isEmpty, isTrue);
    });
  });
}
