# Chem Buddy

Dark-themed Flutter app for MSc Chemistry students: attendance, tests & assignments, and day-to-day notes.

## Run

```bash
flutter pub get
flutter run
```

Works fully offline with Hive. To enable cloud sync, copy `.env.example` to `.env` (or fill `.env.example`) with your Supabase URL and anon key, then run `supabase/schema.sql` in the SQL editor.

## Stack

- Flutter + Riverpod
- Hive (offline)
- supabase_flutter (optional sync)
- fl_chart, google_fonts, flutter_local_notifications
