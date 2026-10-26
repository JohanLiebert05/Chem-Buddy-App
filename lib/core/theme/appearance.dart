import 'dart:math';

import 'package:flutter/material.dart';

enum GlassStyle { soft, crystal, solid }

@immutable
class Appearance {
  const Appearance({
    this.seed = const Color(0xFF9474F5),
    this.glass = GlassStyle.soft,
    this.mode = ThemeMode.system,
  });
  final Color seed;
  final GlassStyle glass;
  final ThemeMode mode;

  Appearance copyWith({Color? seed, GlassStyle? glass, ThemeMode? mode}) =>
      Appearance(
        seed: seed ?? this.seed,
        glass: glass ?? this.glass,
        mode: mode ?? this.mode,
      );

  static Appearance decode(Object? seed, Object? glass, [Object? mode]) {
    final value = seed is int && seed >= 0 && seed <= 0xffffffff
        ? Color(seed).withAlpha(255)
        : const Color(0xFF9474F5);
    return Appearance(
      seed: value,
      mode: ThemeMode.values.firstWhere(
        (value) => value.name == mode,
        orElse: () => ThemeMode.system,
      ),
      glass: GlassStyle.values.firstWhere(
        (style) => style.name == glass,
        orElse: () => GlassStyle.soft,
      ),
    );
  }

  Appearance surprise(Random random) {
    // A deliberate hue rotation guarantees a visibly different palette.
    final hue =
        (HSLColor.fromColor(seed).hue + 45 + random.nextDouble() * 270) % 360;
    return copyWith(
      seed: HSLColor.fromAHSL(
        1,
        hue,
        .48 + random.nextDouble() * .30,
        .48 + random.nextDouble() * .14,
      ).toColor(),
    );
  }
}

class ThemePalette {
  const ThemePalette(this.name, this.caption, this.seed);
  final String name;
  final String caption;
  final Color seed;

  static const all = [
    ThemePalette('Amethyst', 'Violet · luminous', Color(0xFF9474F5)),
    ThemePalette('Lagoon', 'Teal · tranquil', Color(0xFF26A69A)),
    ThemePalette('Cobalt', 'Blue · focused', Color(0xFF527DEA)),
    ThemePalette('Rose quartz', 'Rose · delicate', Color(0xFFD5749D)),
    ThemePalette('Matcha', 'Green · grounded', Color(0xFF829B52)),
    ThemePalette('Amber', 'Gold · warm', Color(0xFFC78F38)),
    ThemePalette('Glacier', 'Cyan · crisp', Color(0xFF44B5D2)),
    ThemePalette('Terracotta', 'Clay · earthy', Color(0xFFCC775F)),
    ThemePalette('Orchid', 'Mauve · expressive', Color(0xFFBA70D4)),
    ThemePalette('Midnight', 'Indigo · serene', Color(0xFF6971BC)),
    ThemePalette('Cherry', 'Red · confident', Color(0xFFD86470)),
    ThemePalette('Graphite', 'Slate · minimal', Color(0xFF78858E)),
  ];

  static String nameFor(Color seed) {
    for (final palette in all) {
      if (palette.seed == seed) {
        return palette.name;
      }
    }
    return 'Your discovery';
  }
}

@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.opacity,
    required this.blur,
    required this.glow,
  });
  final double opacity;
  final double blur;
  final double glow;

  factory GlassTokens.forStyle(
    GlassStyle style, {
    Brightness brightness = Brightness.dark,
  }) => switch (style) {
    GlassStyle.soft => GlassTokens(
      opacity: brightness == Brightness.light ? .80 : .88,
      blur: 12,
      glow: brightness == Brightness.light ? .13 : .10,
    ),
    GlassStyle.crystal => GlassTokens(
      opacity: brightness == Brightness.light ? .66 : .76,
      blur: 20,
      glow: brightness == Brightness.light ? .21 : .17,
    ),
    GlassStyle.solid => const GlassTokens(opacity: 1, blur: 0, glow: .04),
  };

  @override
  GlassTokens copyWith({double? opacity, double? blur, double? glow}) =>
      GlassTokens(
        opacity: opacity ?? this.opacity,
        blur: blur ?? this.blur,
        glow: glow ?? this.glow,
      );

  @override
  GlassTokens lerp(covariant GlassTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return GlassTokens(
      opacity: opacity + (other.opacity - opacity) * t,
      blur: blur + (other.blur - blur) * t,
      glow: glow + (other.glow - glow) * t,
    );
  }

  static GlassTokens of(BuildContext context) =>
      Theme.of(context).extension<GlassTokens>() ??
      GlassTokens.forStyle(GlassStyle.soft);
}
