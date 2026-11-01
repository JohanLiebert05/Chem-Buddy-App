import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/appearance.dart';
import '../../core/widgets/liquid_glass.dart';
import '../providers/appearance_provider.dart';

/// Theme editing lives directly in Profile, including mode and surface finish.
class ProfileAppearanceCard extends ConsumerStatefulWidget {
  const ProfileAppearanceCard({super.key});
  @override
  ConsumerState<ProfileAppearanceCard> createState() =>
      _ProfileAppearanceCardState();
}

class _ProfileAppearanceCardState extends ConsumerState<ProfileAppearanceCard> {
  final _random = Random();
  int? _collection;
  bool _saving = false;
  Appearance? _previous;
  Future<void> _apply(Appearance next, {bool undo = false}) async {
    if (_saving) {
      return;
    }
    final before = ref.read(appearanceProvider);
    setState(() => _saving = true);
    try {
      await ref.read(appearanceProvider.notifier).apply(next);
      if (mounted) {
        setState(() => _previous = undo ? null : before);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your look could not be saved. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _choice({
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
    Widget? leading,
    Key? choiceKey,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          key: choiceKey,
          borderRadius: BorderRadius.circular(14),
          onTap: _saving ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: selected
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: selected ? colors.primary : colors.outline,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);
    final colors = Theme.of(context).colorScheme;
    final active =
        _collection ??
        (ThemePalette.isGradient(appearance.seed)
            ? 2
            : ThemePalette.isFan(appearance.seed)
            ? 1
            : 0);
    final palettes = [
      ThemePalette.all,
      ThemePalette.fanCollection,
      ThemePalette.gradientCollection,
    ][active];
    const collections = ['Classic', 'Fan collection', 'Gradients'];
    String modeName(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'Auto',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
    String finishName(GlassStyle finish) => switch (finish) {
      GlassStyle.soft => 'Soft glass',
      GlassStyle.crystal => 'Crystal',
      GlassStyle.solid => 'Solid',
    };
    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 12,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your look',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_saving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ThemePalette.nameFor(appearance.seed),
            key: const Key('profile-theme-name'),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Display mode'),
            subtitle: Text(modeName(appearance.mode)),
            children: [
              for (final mode in ThemeMode.values)
                _choice(
                  title: modeName(mode),
                  selected: appearance.mode == mode,
                  subtitle: mode == ThemeMode.system
                      ? 'Follow your device'
                      : null,
                  leading: Icon(switch (mode) {
                    ThemeMode.system => Icons.brightness_auto_outlined,
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                  }),
                  onTap: () => _apply(appearance.copyWith(mode: mode)),
                ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: false,
            title: const Text('Colour collection'),
            subtitle: Text(collections[active]),
            children: [
              for (var i = 0; i < collections.length; i++)
                _choice(
                  title: collections[i],
                  selected: active == i,
                  onTap: () => setState(() => _collection = i),
                ),
              const SizedBox(height: 8),
              for (final palette in palettes)
                _choice(
                  choiceKey: ValueKey(palette.name),
                  title: palette.name,
                  subtitle: palette.caption,
                  selected: appearance.seed == palette.seed,
                  onTap: () => _apply(appearance.copyWith(seed: palette.seed)),
                  leading: Container(
                    width: 48,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: palette.swatches.isNotEmpty
                            ? palette.swatches
                            : [
                                palette.seed,
                                Color.lerp(palette.seed, colors.surface, .4)!,
                              ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Surface finish'),
            subtitle: Text(finishName(appearance.glass)),
            children: [
              for (final finish in GlassStyle.values)
                _choice(
                  title: finishName(finish),
                  selected: appearance.glass == finish,
                  onTap: () => _apply(appearance.copyWith(glass: finish)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving
                ? null
                : () {
                    final options = palettes
                        .where((p) => p.seed != appearance.seed)
                        .toList();
                    _apply(
                      active == 0
                          ? appearance.surprise(_random)
                          : appearance.copyWith(
                              seed:
                                  options[_random.nextInt(options.length)].seed,
                            ),
                    );
                  },
            icon: const Icon(Icons.auto_awesome_rounded, size: 17),
            label: const Text('Surprise me'),
          ),
          TextButton(
            onPressed: _saving || _previous == null
                ? null
                : () {
                    setState(() => _collection = null);
                    _apply(_previous!, undo: true);
                  },
            child: const Text('Undo'),
          ),
        ],
      ),
    );
  }
}
