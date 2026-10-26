# Chem Buddy by Prajwal A Kambar

Flutter study companion for MSc Chemistry students (3.5.4): attendance, AI/PDF study, quizzes, flashcards, reactions, drawing, spectroscopy, calculators and exports.

See [USER_MANUAL.md](USER_MANUAL.md) and [deployment requirements](docs/REVIEW_FIXES.md). Old PDF/DOC manuals are historical.

Made by Prajwal A Kambar.

## Version 3.5.4

Material 3 Expressive light/dark themes, refined glass surfaces, a new setup flow, local guest mode, and Android Back exit confirmation. See [appearance and preview notes](docs/APPEARANCE.md). GitHub Releases provides the current APK; a separately labeled Preview APK is used when production signing is not configured.

## Run

```bash
flutter pub get
flutter run
```

Core saved/local features work offline in unencrypted Hive storage. Signed-in changes attempt cloud sync; AI sends questions and attached text to the backend/provider. To configure Supabase, copy `.env.example` to `.env` with your Supabase URL and anon key, then run `supabase/schema.sql`.

OCR timetable scanning and the PDF reader target Android (and iOS for OCR). Chrome can still open the rest of the app.

## Core modules

- **Smart timetable:** camera/gallery → ML Kit OCR → review sheet → Hive. Never saved without review.
- **Notifications:** local class reminders, 8:30 AM IST daily timetable, deadline and custom reminders. Settings live under Profile → Notifications.
- **PDF library:** import via the system document picker into app documents (`ChemBuddy/PDFs/<subjectId>/`). Metadata (name, subject, last page, favorite) is stored in Hive, separate from the file.
- **PDF reader:** `flutter_pdfview` in-app (pages, pinch-zoom, night mode, share, last page). Text search/selection is not claimed — create flashcards from a PDF with a manual form.
- **AnkiDroid:** OpenIntents `org.openintents.action.CREATE_FLASHCARD` (see [AnkiDroid API wiki](https://github.com/ankidroid/Anki-Android/wiki/AnkiDroid-API)). Chem Buddy never writes Anki’s collection. If AnkiDroid is missing, the app shows Install / Share / Cancel. Fallback is a shared TSV import.
- **Smart Flashcards:** PDF → text extract → Supabase Edge Function → Gemini → Hive cache. Study offline after generation. Gemini keys never ship in the app.
- **Search:** offline across PDFs, subjects, timetable, notes, reminders, flashcards.

## Smart Flashcards (Gemini)

1. Run `supabase/schema.sql` in the SQL editor (includes RLS).
2. Deploy the Edge Function:

```bash
supabase functions deploy generate-flashcards
supabase secrets set GEMINI_API_KEY=your_gemini_key
```

3. Put only `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env` (copy from `.env.example`). Never put `GEMINI_API_KEY` in the Flutter app.

Generate requires internet and a signed-in Supabase user. Studying saved sets works offline.

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
