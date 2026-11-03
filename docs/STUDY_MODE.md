# Study Mode and Curious

ChemBuddy 3.5.8 by Prajwal A Kambar.

## Student experience

Home and Library offer two separate destinations:

- **Study Mode — Basics of Organic Chemistry:** 60 sequential levels in 12
  chapters. A suggested two-month plan introduces foundations and connects them
  to MSc reasoning. It does not promise complete MSc mastery in five hours.
- **Curious:** 12 question-led explorations. Students can explore advanced
  topics without course locks; discoveries do not unlock course levels or add
  course streaks.

Students choose 5, 10, 15 or 20 minutes. The 60:40 explanation/practice split gives
the requested three-minute/two-minute plan for five-minute sessions. Longer
sessions expose additional examples, advanced connections, writing and review.
Timeboxes pause at their boundary, allow extra time, and never auto-submit work.

Each level has original plain-language teaching, a vector illustration, reasoning,
a worked example, an advanced connection and three original multiple-choice
checks. Two correct checks unlock the next level. A replay retains the best score;
XP is derived from completed levels and best scores rather than repeatedly added.
Chapter completion and local-calendar streaks survive restarts. Opening the app
alone does not earn streak credit.

Practice presents one question at a time, retains checked options, explains the
answer and asks for optional confidence. Correct guesses and uncertain answers
remain in the review list. An optional **My reasoning** sheet holds the student's
first thought, supporting explanation and next-visit clue. Finished reasoning is
saved in a per-lesson journal and can be revisited or revised. Student writing is
self-checked, not falsely presented as automatically assessed.

## Content and diagrams

The curriculum moves through structure reading, electron movement, acid–base
reasoning, stereochemistry, substitution/elimination, additions, aromaticity,
carbonyls, enolates, rearrangements, orbital-controlled reactions and mechanistic
evidence. Further reading links to OpenStax and official NPTEL courses. Teaching
text, questions and SVG illustrations are original; no textbook passages or
figures are bundled. The final levels explicitly point students towards longer
syllabus problems and further instructor-reviewed study.

Electron-pair arrows have explicit arrowhead geometry because Flutter's SVG
renderer does not implement marker elements. Schematics are captioned and can be
zoomed. Orbital phases and electron-density drawings are distinguished from
physical charges and literal electron tracks. Illustrations are educational
models, not experimental spectra or calculated orbital-density surfaces.

## Storage and lifecycle

- Production uses the existing account-scoped Hive settings box. Versioned keys
  `organic_study_v1` and `organic_study_journal_v1` hold the small checkpoint and
  the journal. No new box is added to startup.
- The repository captures its account and box. Account changes hide the old
  lesson, stop its clock and reject stale writes.
- Checkpoints are queued in order, use stable snapshots and save periodically,
  on answers/stage changes, after editing, on backgrounding and on explicit exit.
  Results are committed before completion is awarded in memory.
- Journal records are written when changed rather than on every five-second
  checkpoint. Timer ticks rebuild only the small timer view. Static backgrounds
  and diagrams have repaint boundaries; no continuous decorative animation or
  per-card backdrop blur is added.
- A monotonic clock counts only active study. Returning from the background
  leaves a session paused until the student resumes it.
- Core teaching, grading, diagrams, progress and Curious work offline without an
  AI key, login to Google accounts, or provider quota. Existing AI features remain
  separate. No claim of cloud backup or cross-device progress sync is made.

## Verification

Focused tests exercise all 60 levels end to end, all question records, every SVG
in light and dark palettes, real Hive account switching, failed writes, streak
boundaries, resumable sessions, lifecycle timing, confidence, reasoning and narrow
layouts with enlarged text. The full app suite and release build are checked in
addition. Functional tests and desktop previews do not establish physical-phone
120 Hz frame performance or replace specialist review of educational content.

## Local preview

`flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8770 -t tool/study_mode_preview.dart`

The preview uses a separate browser-storage key and never opens production
accounts or calls AI. It is not the production app's saved course data.

## Release validation (3 November 2026)

- Flutter analysis: no issues.
- Full Flutter suite: 612 tests passed, including 75 Study Mode checks.
- Release split APKs built for ARM64, ARMv7 and x86_64.
- ARM64 APK: 55,903,758 bytes (about 53.3 MiB), approximately 0.38 MiB
  larger than the local 3.5.7 baseline. Download size is separate from Android's
  reported installed size.
- All 46 educational/web assets and five native feature libraries per ABI
  matched the packaging check; OCR and PDF support remain present.
