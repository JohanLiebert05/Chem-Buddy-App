# ChemBuddy 3.5.5 — operating guide

Version 3.5.5 adds the reviewed fixes, new glass themes, local guest mode and a redesigned setup flow.

## Getting started

Choose your university, semester and subjects, then sign in or choose **Continue as guest**. Guest notes, attendance and tools stay on this device in a separate profile. Leave guest mode from Profile; your guest data remains available when you return. Cloud AI requires sign-in.

Use **Profile → Appearance** for Light, Dark or System mode, twelve palettes, Surprise me and glass finishes. Android Back at the root screen asks before closing the app. Back inside a page returns to the preceding page. Android Home, task switching and force closing remain controlled by the operating system.

## Navigation
Home shows attendance, next class, progress, streaks, daily content and shortcuts. Classes has presets, timetable OCR/review/editing and attendance. Ask AI has Quick Answer, General AI, Simple, 2/5/10-mark answers, MSc depth, viva, mechanisms and PDF questions. Library holds reactions, tools, PDFs, quizzes, notes and coursework. Profile has identity, subjects, notifications, exports and guides.

## Learning tools
Import a PDF, then open its reader or Study Hub for extraction/OCR, summaries, topics, document questions, quizzes and flashcards. Check formulas and source pages. New cloud AI content needs internet and authentication. Saved material can be studied offline.

Flashcards use Again/Hard/Good/Easy review scheduling and saved sessions, with AnkiDroid/TSV sharing. Exam tools offer blueprints, model answers, revision and past-paper question prediction.

## Accounts, privacy and sync
Academic boxes are separated by account. Legacy records are copied once to the matching register-number account; originals are retained. New PDF imports use an account-specific folder.

Hive and PDFs are app-local but **not encrypted by ChemBuddy**. Device encryption and app isolation are separate OS protections.

Signed-in changes to supported academic tables attempt cloud sync. Failed writes remain queued for retry while that account is active. A connection check does not prove a completed backup. PDF files and all study types do not automatically restore across devices. Keep originals and exported reports.

AI questions, attached document text and conversation context are sent to Supabase and its configured AI provider. Provider credentials are server secrets. Private fallback answers are no longer stored in the old shared academic cache. PDF fallbacks must not invent source pages.

## Attendance and notifications
Present and Absent count. **Postponed and Excused/OD are excluded from numerator and denominator.** OD does not count as Present. This applies to overall statistics, charts and exports. Confirm the institution's official rule before relying on the default 75% target.

Notifications use Asia/Kolkata. Briefing is 8:30 AM; psychology facts default to 8 PM. Enable notifications/alarms. Battery restrictions can affect delivery. Actions are bound to the scheduling account.

## Chemistry and exports
The toolkit covers solutions, units/stoichiometry, CFT, acid-base, thermo/kinetics, quantum, light, electrochemistry and analytical calculations.

The descriptor service is a limited educational estimator, **not an RDKit runtime**. Properties/screening results are approximate. Unsupported charges, isotopes, salts, metals and complex aromatic systems are rejected. Use validated chemistry tooling for research.

Reaction prediction combines finite offline rules with online AI. Saved predictions are not verified reactions. Spectroscopy/pericyclic references and visualizations are study aids rather than experimental proof.

Exports are PDF, UTF-8 CSV and standalone reaction SVG. CSV opens in Excel but is not XLSX. Reaction PDFs embed a rendered scheme at print resolution; the standalone SVG remains vector. Inspect pagination/notation before submission. Reports imply no institutional certification.

## Releases and limitations
Android is the CI build target; native features vary by platform. The existing APK download is approximately 136 MB; at least 500 MB free space is recommended. Future releases publish one version-matched APK. Older duplicate filenames are copies of one build.

Psychology facts cycle through the catalog before repeating. A dedicated GHS database, complete JSON backup/restore and encrypted local storage are not implemented. Older PDF/DOC manuals are historical; this guide supersedes them.
