# Appearance and full-app preview

Open **Profile → Appearance** to choose **Light**, **Dark**, or **System**, a palette, and a surface finish.

- Twelve palettes work in both brightness modes. Material 3's vibrant scheme creates coordinated primary, secondary, tertiary, text and surface roles from each seed.
- Light mode uses brighter color accents, pearly translucent surfaces, subtle colored shadows, and soft specular highlights. Dark mode retains deeper tinted glass.
- Soft glass, Crystal, and Solid control opacity and blur. System high contrast forces opaque glass surfaces. Shared scrolling cards avoid separate backdrop filters.
- Surprise me preserves the chosen display mode and finish. Undo restores the preceding appearance. Restore original look returns to Amethyst, Soft glass, and System mode.
- One versioned local preference saves the palette, finish and display mode together. Existing v1 preferences retain their dark appearance until changed. Invalid modes fall back to System. A failed save leaves the current appearance unchanged.
- Text, equations, selection controls and semantic accents were adapted for light backgrounds. Chemistry diagrams and subject hues retain their meaning.
- Browser interactions use Material's ripple effect; native builds retain InkSparkle.

## Previews

Run `flutter run -d chrome -t tool/app_preview.dart` for the full app using its real Home, Classes, AI, Library and Profile screens with isolated local sample data. The preview toolbar provides quick mode switching and access to Appearance. The browser-only entry point does not initialize the cloud connection or a real account.

Run `flutter run -d chrome -t tool/appearance_preview.dart` for just the Appearance screen. Browser preferences are separate from an installed phone app.

## Validation

- The full app preview compiled successfully with the installed Flutter web SDK.
- Browser runtime checks passed 896 text/background contrast checks across 12 curated and 100 generated palettes in both light and dark modes.
- Checks passed for generated colors preserving mode/finish, preference restoration, legacy dark-mode migration, invalid mode fallback and failed-storage handling.
- Main navigation and display-mode selection were exercised in the actual browser preview. Light-mode text corrections were checked on the dashboard, attendance, library and profile surfaces.
- Focused static analysis of the theme, appearance provider/screen, app wiring, preview entry point and appearance tests reported no issues.

The installed Windows Flutter launcher previously exited with code -1073741816 before running the automated widget suite. Run `flutter test test/appearance_test.dart` and the wider suite in a working Flutter environment or CI before release. Native file sharing, notifications and Android performance still need device verification.
