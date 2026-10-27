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
  const ThemePalette(
    this.name,
    this.caption,
    this.seed, {
    this.swatches = const [],
    this.emblem,
  });
  final String name;
  final String caption;
  final List<Color> swatches;
  final IconData? emblem;
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

  static const blancosSeed = Color(0xFF202020);
  static const pellaraSeed = Color(0xFFFFD600);
  static const rcbSeed = Color(0xFFDA1736);

  static const fanCollection = [
    ThemePalette(
      'Blancos',
      'Real Madrid · black, white & silver',
      blancosSeed,
      swatches: [Colors.white, Color(0xFF171717), Color(0xFFC8C8CD)],
    ),
    ThemePalette(
      'Pellara',
      'Adidas Pellara · yellow & charcoal',
      pellaraSeed,
      swatches: [Color(0xFFFFD600), Color(0xFF242424), Color(0xFFFFF2A0)],
    ),
    ThemePalette(
      'RCB',
      'RCB · red, black & gold',
      rcbSeed,
      swatches: [Color(0xFFDA1736), Color(0xFF171717), Color(0xFFD4AF5A)],
    ),
    ThemePalette(
      'Papaya Grid',
      'Motorsport · orange & graphite',
      Color(0xFFF07C20),
      swatches: [Color(0xFFFF8A26), Color(0xFF282A30), Color(0xFF50C8DA)],
      emblem: Icons.sports_motorsports_rounded,
    ),
    ThemePalette(
      'Rosso',
      'Grand touring · scarlet & cream',
      Color(0xFFD93236),
      swatches: [Color(0xFFEE3745), Color(0xFFFFE4BE), Color(0xFF25232A)],
      emblem: Icons.flag_outlined,
    ),
    ThemePalette(
      'Centre Court',
      'Tennis · emerald & violet',
      Color(0xFF338768),
      swatches: [Color(0xFF2EBA87), Color(0xFF8655CD), Color(0xFFF7E8BE)],
      emblem: Icons.sports_tennis_rounded,
    ),
    ThemePalette(
      'Neon Arcade',
      'Gaming · cyan & electric rose',
      Color(0xFF00A9CE),
      swatches: [Color(0xFF2DD8E9), Color(0xFFEE5DBB), Color(0xFF7951E8)],
      emblem: Icons.sports_esports_outlined,
    ),
    ThemePalette(
      'Deep Orbit',
      'Space · cobalt & starlight',
      Color(0xFF5264D9),
      swatches: [Color(0xFF5F73EE), Color(0xFFB179E4), Color(0xFFFFCE71)],
      emblem: Icons.rocket_launch_outlined,
    ),
    ThemePalette(
      'Reef',
      'Ocean · turquoise & coral',
      Color(0xFF16A9A0),
      swatches: [Color(0xFF25C9B5), Color(0xFFFF887E), Color(0xFFF4CF69)],
      emblem: Icons.waves_rounded,
    ),
  ];

  static const gradientCollection = [
    ThemePalette(
      'Aurora',
      'Periwinkle · teal · lilac',
      Color(0xFF5969ED),
      swatches: [Color(0xFF5969ED), Color(0xFF2AC9B8), Color(0xFFC18BEE)],
    ),
    ThemePalette(
      'Solar drift',
      'Amber · coral · rose',
      Color(0xFFF3B42C),
      swatches: [Color(0xFFF3B42C), Color(0xFFFA826C), Color(0xFFD76B9D)],
    ),
    ThemePalette(
      'Tidal bloom',
      'Jade · blue · orchid',
      Color(0xFF13A5A0),
      swatches: [Color(0xFF13A5A0), Color(0xFF5E86ED), Color(0xFFCB81E8)],
    ),
    ThemePalette(
      'Velvet sky',
      'Violet · blush · apricot',
      Color(0xFF8759D8),
      swatches: [Color(0xFF8759D8), Color(0xFFDC83AB), Color(0xFFF1B88A)],
    ),
    ThemePalette(
      'Afterglow',
      'Crimson · gold · lavender',
      Color(0xFFEA596E),
      swatches: [Color(0xFFEA596E), Color(0xFFF4AC51), Color(0xFF9E71DE)],
    ),
    ThemePalette(
      'Polar lights',
      'Ice blue · pearl · iris',
      Color(0xFF4CB6C9),
      swatches: [Color(0xFF4CB6C9), Color(0xFFB7C2EE), Color(0xFF8271D1)],
    ),
  ];

  static bool isGradient(Color seed) =>
      gradientCollection.any((palette) => palette.seed == seed);
  static List<Color> gradientFor(Color seed) {
    for (final palette in gradientCollection) {
      if (palette.seed == seed) {
        return palette.swatches;
      }
    }
    return const [];
  }

  static bool isFan(Color seed) =>
      fanCollection.any((palette) => palette.seed == seed);

  static String nameFor(Color seed) {
    for (final palette in [...all, ...fanCollection, ...gradientCollection]) {
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

@immutable
class PrismTokens extends ThemeExtension<PrismTokens> {
  const PrismTokens(this.colors);
  final List<Color> colors;
  bool get enabled => colors.length == 3;
  static PrismTokens of(BuildContext context) =>
      Theme.of(context).extension<PrismTokens>() ?? const PrismTokens([]);
  @override
  PrismTokens copyWith({List<Color>? colors}) =>
      PrismTokens(colors ?? this.colors);
  @override
  PrismTokens lerp(covariant PrismTokens? other, double t) {
    if (other == null) {
      return this;
    }
    if (!enabled || !other.enabled) {
      return t < .5 ? this : other;
    }
    return PrismTokens(
      List.generate(3, (i) => Color.lerp(colors[i], other.colors[i], t)!),
    );
  }
}
