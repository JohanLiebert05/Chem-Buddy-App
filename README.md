# Chem Buddy

Dark-themed Flutter app for MSc Chemistry students. Version 2 keeps Version 1 attendance, tests, notes, and onboarding, and adds a smart timetable, local notifications, a PDF library with an in-app reader, flashcards, and AnkiDroid integration.

Made by Prajwal A Kambar.

## Run

```bash
flutter pub get
flutter run
```

Works fully offline with Hive. To enable optional cloud sync, copy `.env.example` to `.env` with your Supabase URL and anon key, then run `supabase/schema.sql`.

OCR timetable scanning and the PDF reader target Android (and iOS for OCR). Chrome can still open the rest of the app.

## Version 2 modules

- **Smart timetable:** camera/gallery → ML Kit OCR → review sheet → Hive. Never saved without review.
- **Notifications:** local class reminders, optional 7:30 AM daily timetable, deadline and custom reminders. Settings live under Profile → Notifications.
- **PDF library:** import via the system document picker into app documents (`ChemBuddy/PDFs/<subjectId>/`). Metadata (name, subject, last page, favorite) is stored in Hive, separate from the file.
- **PDF reader:** `flutter_pdfview` in-app (pages, pinch-zoom, night mode, share, last page). Text search/selection is not claimed — create flashcards from a PDF with a manual form.
- **AnkiDroid:** OpenIntents `org.openintents.action.CREATE_FLASHCARD` (see [AnkiDroid API wiki](https://github.com/ankidroid/Anki-Android/wiki/AnkiDroid-API)). Chem Buddy never writes Anki’s collection. If AnkiDroid is missing, the app shows Install / Share / Cancel. Fallback is a shared TSV import.
- **Search:** offline across PDFs, subjects, timetable, notes, reminders, flashcards.

## Permissions

Only what the features need:

- `CAMERA` — timetable scan
- `POST_NOTIFICATIONS` — reminders
- `RECEIVE_BOOT_COMPLETED` / `SCHEDULE_EXACT_ALARM` / `VIBRATE` — reschedule after reboot (plugin-supported)
- Document access via Storage Access Framework (`file_picker`), not `MANAGE_EXTERNAL_STORAGE`

## Stack

- Flutter + Riverpod
- Hive (offline)
- supabase_flutter (optional)
- google_mlkit_text_recognition, flutter_local_notifications, flutter_pdfview, file_picker, android_intent_plus
