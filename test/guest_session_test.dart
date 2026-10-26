import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/data/models/models.dart';
import 'package:chem_buddy/data/remote/supabase_service.dart';
import 'package:chem_buddy/data/remote/notification_service.dart';
import 'package:chem_buddy/data/repositories/chem_repository.dart';
import 'package:chem_buddy/data/services/pending_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'guest study data survives logout and never mixes with an account',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chembuddy-guest-',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => directory.path,
          );
      await HiveBoxes.openAll();
      final store = LocalStore();
      final repo = ChemRepository(
        store: store,
        remote: SupabaseService.instance,
        notifications: NotificationService.instance,
      );
      try {
        await store.saveProfile(
          const UserProfile(
            university: 'Test university',
            semester: 3,
            onboarded: true,
          ).toJson(),
        );
        const subject = Subject(
          id: 'setup-subject',
          name: 'Organic',
          code: 'ORG',
        );
        await store.put(store.subjects, subject.id, subject.toJson());
        await repo.enterGuest();
        expect(repo.profile().isGuest, isTrue);
        expect(repo.profile().loggedIn, isTrue);
        expect(repo.profile().id, isNull);
        expect(repo.profile().university, 'Test university');
        expect(repo.subjects().single.code, 'ORG');
        final note = NoteItem(
          id: 'guest-note',
          title: 'Guest note',
          body: 'Private local note',
          updatedAt: DateTime(2026),
        );
        await repo.upsertNote(note);
        await PendingSyncService(store, SupabaseService.instance).upsert(
          'flashcards',
          {'id': 'guest-card', 'question': 'Local question'},
        );
        expect(store.pendingSync.isEmpty, isTrue);
        await repo.logout();
        await repo.loginLocal(registerNumber: 'account-b', name: 'Account B');
        expect(repo.profile().isGuest, isFalse);
        expect(repo.notes(), isEmpty);
        await repo.upsertNote(
          NoteItem(
            id: 'account-note',
            title: 'Account note',
            body: 'Account only',
            updatedAt: DateTime(2026),
          ),
        );
        await repo.logout();
        await repo.enterGuest();
        expect(HiveBoxes.activeAccount, 'guest:local');
        expect(repo.notes().map((n) => n.id), ['guest-note']);
        expect(repo.profile().university, 'Test university');
        expect(repo.profile().semester, 3);
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
