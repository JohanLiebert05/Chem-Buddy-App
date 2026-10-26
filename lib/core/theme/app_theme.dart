import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appearance.dart';
import '../widgets/expressive_motion.dart';

class AppTheme {
  static const scrollBehavior = ChemBuddyScrollBehavior();
  static const pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ExpressivePageTransitionsBuilder(),
      TargetPlatform.iOS: ExpressivePageTransitionsBuilder(),
      TargetPlatform.windows: ExpressivePageTransitionsBuilder(),
      TargetPlatform.macOS: ExpressivePageTransitionsBuilder(),
      TargetPlatform.linux: ExpressivePageTransitionsBuilder(),
    },
  );

  static ThemeData get dark => fromAppearance(const Appearance());

  static ColorScheme schemeFor(Color seed, Brightness brightness) {
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );
    if (brightness == Brightness.dark) {
      return generated;
    }
    return generated.copyWith(
      surface: const Color(0xFFF7F8FC),
      onSurface: const Color(0xFF17212F),
      onSurfaceVariant: const Color(0xFF475467),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFDFDFF),
      surfaceContainer: const Color(0xFFF0F2F8),
      surfaceContainerHigh: const Color(0xFFE9ECF4),
      surfaceContainerHighest: const Color(0xFFE0E5EF),
      outline: const Color(0xFF667085),
      outlineVariant: const Color(0xFFD7DDE8),
    );
  }

  static ThemeData fromAppearance(
    Appearance appearance, {
    bool useGoogleFonts = true,
    Brightness brightness = Brightness.dark,
  }) {
    final colors = schemeFor(appearance.seed, brightness);
    final base = ThemeData(useMaterial3: true, colorScheme: colors);
    final body = useGoogleFonts
        ? GoogleFonts.dmSansTextTheme(base.textTheme)
        : base.textTheme;
    final headings = useGoogleFonts
        ? GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        : base.textTheme;
    final text = body.copyWith(
      headlineLarge: headings.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      headlineMedium: headings.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
      ),
      headlineSmall: headings.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
      titleLarge: headings.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: headings.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: headings.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      textTheme: text,
      extensions: [
        GlassTokens.forStyle(appearance.glass, brightness: brightness),
      ],
      pageTransitionsTheme: pageTransitionsTheme,
      splashFactory: kIsWeb
          ? InkRipple.splashFactory
          : InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        shape: shape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainer,
        modalBackgroundColor: colors.surfaceContainer,
        showDragHandle: true,
        dragHandleColor: colors.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHigh,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainer,
        indicatorColor: colors.secondaryContainer,
        elevation: 0,
        height: 72,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorAnimation: TabIndicatorAnimation.elastic,
        dividerColor: Colors.transparent,
        labelColor: colors.onPrimaryContainer,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: .9),
              colors.primaryContainer.withValues(alpha: .65),
            ],
          ),
          border: Border.all(color: colors.primary.withValues(alpha: .15)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        selectedColor: colors.secondaryContainer,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: .5),
        thickness: .5,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.primary,
        textColor: colors.onSurface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
      ),
    );
  }
}

class ChemBuddyScrollBehavior extends MaterialScrollBehavior {
  const ChemBuddyScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
