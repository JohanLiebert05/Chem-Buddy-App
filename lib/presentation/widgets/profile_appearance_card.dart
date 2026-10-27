import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/appearance.dart';
import '../../core/widgets/expressive_motion.dart';
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

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 12,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Your look', style: text.titleLarge)),
              if (_saving)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            ThemePalette.nameFor(appearance.seed),
            key: const Key('profile-theme-name'),
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final mode in ThemeMode.values)
                SpringPress(
                  child: ChoiceChip(
                    selected: appearance.mode == mode,
                    label: Text(switch (mode) {
                      ThemeMode.system => 'Auto',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    }),
                    avatar: Icon(switch (mode) {
                      ThemeMode.system => Icons.brightness_auto_outlined,
                      ThemeMode.light => Icons.light_mode_outlined,
                      ThemeMode.dark => Icons.dark_mode_outlined,
                    }, size: 17),
                    onSelected: _saving
                        ? null
                        : (_) => _apply(appearance.copyWith(mode: mode)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: SpringPress(
                      child: ChoiceChip(
                        selected: active == i,
                        label: Text(
                          ['Classic', 'Fan collection', 'Gradients'][i],
                        ),
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _collection = i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height:
                116.0 +
                (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 32),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: palettes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final palette = palettes[index];
                final selected = appearance.seed == palette.seed;
                final swatches = palette.swatches.isNotEmpty
                    ? palette.swatches
                    : [
                        palette.seed,
                        Color.lerp(palette.seed, colors.surface, .35)!,
                        Color.lerp(palette.seed, colors.tertiary, .4)!,
                      ];
                return SizedBox(
                  width: 146,
                  child: Semantics(
                    selected: selected,
                    button: true,
                    child: SpringPress(
                      child: Material(
                        color: selected
                            ? colors.primaryContainer.withValues(alpha: .6)
                            : colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey(palette.name),
                          onTap: _saving
                              ? null
                              : () => _apply(
                                  appearance.copyWith(seed: palette.seed),
                                ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 39,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: swatches,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colors.outlineVariant.withValues(
                                        alpha: .5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        palette.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.labelLarge,
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: colors.primary,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final finish in GlassStyle.values)
                SpringPress(
                  child: ChoiceChip(
                    selected: appearance.glass == finish,
                    label: Text(switch (finish) {
                      GlassStyle.soft => 'Soft glass',
                      GlassStyle.crystal => 'Crystal',
                      GlassStyle.solid => 'Solid',
                    }),
                    onSelected: _saving
                        ? null
                        : (_) => _apply(appearance.copyWith(glass: finish)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SpringPress(
                  child: FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : () {
                            final options = palettes
                                .where(
                                  (palette) => palette.seed != appearance.seed,
                                )
                                .toList();
                            _apply(
                              active == 0
                                  ? appearance.surprise(_random)
                                  : appearance.copyWith(
                                      seed:
                                          options[_random.nextInt(
                                                options.length,
                                              )]
                                              .seed,
                                    ),
                            );
                          },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                    label: const Text('Surprise me'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SpringPress(
                child: TextButton(
                  onPressed: _saving || _previous == null
                      ? null
                      : () {
                          setState(() => _collection = null);
                          _apply(_previous!, undo: true);
                        },
                  child: const Text('Undo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
