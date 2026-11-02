# Android performance and package size

Version 3.5.7 by Prajwal A Kambar targets startup and rendering work rather than
assuming a smaller download alone increases frame rate.

- The native launch window and Android 12+ splash share a pale branded background.
  Flutter paints a small startup screen before starting initialization. Storage,
  preferences and cloud setup start together; notifications wait for local storage.
  Local storage failure offers retry without opening an unsafe account session.
- Only the selected main tab mounts initially. Previously visited tabs retain
  their state, while hidden pages stop tickers and cannot receive focus.
- Main tab motion uses a 200 ms translation instead of full-screen opacity and
  scale. The navigation indicator moves at paint time rather than relaying out
  the bar each frame. Anchored navigation no longer samples a redundant backdrop.
- The static ambient background is a separate repaint boundary. Its hex mesh is
  drawn as one path and cached for repeated paints at the same size.
- The logo uses one pulse ticker, a cached static image/glow layer, and a bitmap
  decode sized for its display dimensions. It stops for hidden tabs/reduced motion.
- App routing watches only login, role, onboarding and account identity. Changes
  to notes, attendance or AI messages no longer rebuild the entire MaterialApp.
- Refresh-rate selection preserves the display resolution. On Android 14+, a
  refresh-rate preference lets Android choose the display mode. Device power and
  display policies still apply.

## Packaging

Build with `flutter build apk --release --split-per-abi`. ARM64 is the default
release download, with separate ARMv7 and x86_64 assets. OCR, PDF native libraries,
the sketcher and all bundled educational assets remain included for each target.
Resource/code shrinking remains unchanged to avoid unverified native reflection
regressions. No local user data or feature is removed.

APK download bytes and installed storage are different measurements. Installed
storage also includes extracted files, user PDFs, notes, databases and caches.

## Validation limits

Startup tests hold initialization pending for four simulated seconds and verify
that the first frame remains branded, then test storage recovery. Navigation
tests switch 30 times with 8,333 microsecond pumps and verify retained AI state.
These are functional regressions, not measurements of physical-device FPS.

No Android phone was connected during this change. To certify 120 Hz on a Poco,
run a **profile** build on that phone, record cold startup and the scrolling/tab
switch scenario in Flutter DevTools, and inspect UI/raster frame distributions
against the 8.33 ms frame budget. Repeat with populated attendance, large notes,
PDFs and spectra. A release build should then be checked under the same device
refresh-rate and power settings. Do not claim a sustained 120 FPS result from
desktop widget tests or an emulator.

Android refresh-rate reference:
https://developer.android.com/reference/android/view/WindowManager.LayoutParams#preferredRefreshRate
