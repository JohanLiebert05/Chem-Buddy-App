import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/library_models.dart';

/// AnkiDroid integration.
///
/// Primary path: OpenIntents `CREATE_FLASHCARD` action, which AnkiDroid still
/// documents as the public way to add a note without touching its collection DB.
/// See: https://github.com/ankidroid/Anki-Android/wiki/AnkiDroid-API
///
/// Fallback: share a UTF-8 TSV (Front, Back, Tags) that Anki/AnkiDroid can import.
/// We never write into AnkiDroid's private files.
class AnkiService {
  AnkiService._();
  static final instance = AnkiService._();

  static const playStore = 'https://play.google.com/store/apps/details?id=com.ichi2.anki';

  Future<AnkiResult> sendCard(FlashcardDraft card) async {
    final front = card.question.trim();
    final back = [
      card.answer.trim(),
      if (card.equation.trim().isNotEmpty) 'Equation: ${card.equation.trim()}',
    ].join('\n\n');
    if (front.isEmpty || back.trim().isEmpty) {
      return AnkiResult.error('Question and answer are required.');
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final probe = AndroidIntent(action: 'org.openintents.action.CREATE_FLASHCARD');
        final resolvable = await probe.canResolveActivity() ?? false;
        if (!resolvable) {
          return AnkiResult.notInstalled();
        }
        final intent = AndroidIntent(
          action: 'org.openintents.action.CREATE_FLASHCARD',
          arguments: <String, dynamic>{
            'SOURCE': 'Chem Buddy',
            'FRONT': front,
            'BACK': back,
            'TAGS': card.tags.join(' '),
          },
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return AnkiResult.opened();
      } on PlatformException {
        return AnkiResult.notInstalled();
      } catch (_) {
        return AnkiResult.notInstalled();
      }
    }

    return shareImportFile(card);
  }

  Future<AnkiResult> shareImportFile(FlashcardDraft card) async {
    final front = card.question.trim();
    final back = [
      card.answer.trim(),
      if (card.equation.trim().isNotEmpty) 'Equation: ${card.equation.trim()}',
    ].join('\n\n');
    try {
      await Share.share(
        '$front\t$back\t${card.tags.join(' ')}\n',
        subject: 'Chem Buddy Anki import',
      );
      return AnkiResult.shared();
    } catch (e) {
      return AnkiResult.error('Could not send the card: $e');
    }
  }

  Future<void> openInstallPage() async {
    final uri = Uri.parse(playStore);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class AnkiResult {
  const AnkiResult._(this.kind, this.message);
  final String kind;
  final String message;
  factory AnkiResult.opened() => const AnkiResult._('opened', 'Opening AnkiDroid…');
  factory AnkiResult.shared() =>
      const AnkiResult._('shared', 'Shared an Anki import file. Open it with AnkiDroid if prompted.');
  factory AnkiResult.notInstalled() => const AnkiResult._('missing', 'AnkiDroid is not installed.');
  factory AnkiResult.error(String message) => AnkiResult._('error', message);
  bool get isError => kind == 'error';
  bool get needsInstall => kind == 'missing';
}
