import '../../core/widgets/expressive_motion.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/appearance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hex_background.dart';
import '../../core/widgets/liquid_glass.dart';
import '../providers/appearance_provider.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});
  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen> {
  final _random = Random();
  bool _saving = false;
  Appearance? _previous;

  Future<void> _apply(Appearance next, {bool undo = false}) async {
    if (_saving) {
      return;
    }
    final old = ref.read(appearanceProvider);
    setState(() => _saving = true);
    try {
      await ref.read(appearanceProvider.notifier).apply(next);
      if (mounted) {
        setState(() => _previous = undo ? null : old);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this theme. Please try again.'),
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
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Appearance'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text('A little more you.', style: text.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Quiet depth. Beautiful color. Your own study space.',
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text('Display mode', style: text.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ThemeMode.values)
                    SpringPress(
                      child: ChoiceChip(
                        key: ValueKey('mode-${mode.name}'),
                        avatar: Icon(switch (mode) {
                          ThemeMode.light => Icons.light_mode_outlined,
                          ThemeMode.dark => Icons.dark_mode_outlined,
                          ThemeMode.system => Icons.brightness_auto_outlined,
                        }, size: 18),
                        label: Text(switch (mode) {
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                          ThemeMode.system => 'System',
                        }),
                        selected: appearance.mode == mode,
                        onSelected: _saving
                            ? null
                            : (_) => _apply(appearance.copyWith(mode: mode)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                appearance.mode == ThemeMode.system
                    ? 'Follows your device. Your palette stays with you.'
                    : 'The same palette, beautifully tuned for ${appearance.mode.name} mode.',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              _ThemePreview(name: ThemePalette.nameFor(appearance.seed)),
              const SizedBox(height: 18),
              SpringPress(
                child: FilledButton.icon(
                  key: const Key('surprise-theme'),
                  onPressed: _saving
                      ? null
                      : () => _apply(appearance.surprise(_random)),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(_saving ? 'Saving your look…' : 'Surprise me'),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'A fresh, coordinated palette every time.',
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SpringPress(
                    child: TextButton(
                      onPressed: _saving || _previous == null
                          ? null
                          : () => _apply(_previous!, undo: true),
                      child: const Text('Undo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Fan collection', style: text.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Your teams. Your colours.',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              for (final palette in ThemePalette.fanCollection)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FanPaletteTile(
                    key: ValueKey('fan-theme-${palette.name}'),
                    palette: palette,
                    selected: palette.seed == appearance.seed,
                    onTap: _saving
                        ? null
                        : () => _apply(appearance.copyWith(seed: palette.seed)),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Color collection', style: text.titleLarge),
              const SizedBox(height: 6),
              Text(
                '12 curated palettes · unlimited discoveries',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 650
                      ? 3
                      : constraints.maxWidth >= 290 &&
                            MediaQuery.textScalerOf(context).scale(1) < 1.6
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - 12 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final palette in ThemePalette.all)
                        SizedBox(
                          width: width,
                          child: _PaletteTile(
                            palette: palette,
                            selected: palette.seed == appearance.seed,
                            onTap: _saving
                                ? null
                                : () => _apply(
                                    appearance.copyWith(seed: palette.seed),
                                  ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Text('Surface finish', style: text.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Choose the amount of depth that feels right.',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final style in GlassStyle.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FinishTile(
                    style: style,
                    selected: appearance.glass == style,
                    onTap: _saving
                        ? null
                        : () => _apply(appearance.copyWith(glass: style)),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Saved on this device. Solid removes blur and transparency for a calmer, lighter experience.',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SpringPress(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _apply(const Appearance()),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Restore original look'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bubble_chart_rounded, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CHEMBUDDY',
                  style: text.labelMedium?.copyWith(letterSpacing: 2),
                ),
              ),
              Icon(Icons.check_circle_rounded, color: colors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          Text(name, style: text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Make room for your next discovery.',
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in [
                (colors.primaryContainer, colors.onPrimaryContainer, 'Focus'),
                (
                  colors.secondaryContainer,
                  colors.onSecondaryContainer,
                  'Explore',
                ),
                (
                  colors.tertiaryContainer,
                  colors.onTertiaryContainer,
                  'Discover',
                ),
              ])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: entry.$1,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.$3,
                    style: text.labelLarge?.copyWith(color: entry.$2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(value: .72, minHeight: 5),
          ),
          const SizedBox(height: 8),
          Text(
            'Live preview',
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    this.onTap,
  });
  final ThemePalette palette;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scheme = AppTheme.schemeFor(
      palette.seed,
      Theme.of(context).brightness,
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? colors.secondaryContainer.withValues(alpha: .65)
            : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: .5),
            width: selected ? 1.5 : .7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SpringPress(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (final color in [
                        scheme.primary,
                        scheme.secondary,
                        scheme.tertiary,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: colors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    palette.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    palette.caption,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishTile extends StatelessWidget {
  const _FinishTile({required this.style, required this.selected, this.onTap});
  final GlassStyle style;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (title, subtitle, icon) = switch (style) {
      GlassStyle.soft => (
        'Soft glass',
        'Subtle frost, balanced depth',
        Icons.blur_on_rounded,
      ),
      GlassStyle.crystal => (
        'Crystal',
        'More light, richer translucency',
        Icons.diamond_outlined,
      ),
      GlassStyle.solid => (
        'Solid',
        'Clear surfaces, no blur',
        Icons.layers_outlined,
      ),
    };
    return Semantics(
      selected: selected,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: SpringPress(
          child: ListTile(
            enabled: onTap != null,
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colors.primary : colors.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _FanPaletteTile extends StatelessWidget {
  const _FanPaletteTile({
    super.key,
    required this.palette,
    required this.selected,
    this.onTap,
  });
  final ThemePalette palette;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: SpringPress(
        child: LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 12,
          borderColor: selected ? colors.primary : colors.outlineVariant,
          borderWidth: selected ? 1.5 : .8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: palette.name == 'Pellara'
                              ? [palette.swatches.first, palette.swatches.last]
                              : palette.swatches,
                        ),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Icon(
                        palette.name == 'Blancos'
                            ? Icons.sports_soccer_rounded
                            : Icons.sports_cricket_rounded,
                        color: palette.name == 'Pellara'
                            ? const Color(0xFF242424)
                            : Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            palette.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            palette.caption,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected ? colors.primary : colors.outline,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
