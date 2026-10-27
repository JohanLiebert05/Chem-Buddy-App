import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/appearance_provider.dart';
import '../utils/haptics.dart';
import 'expressive_motion.dart';
import 'liquid_glass.dart';

const curiositySecrets = {
  'curious': (
    'Curious mind',
    'You found the nucleus.',
    'Good chemistry starts with a second look. Keep asking the questions that do not fit in the margin.',
  ),
  'molybdenum': (
    'A Mo-ment of discovery',
    '42 belongs to molybdenum.',
    'Mo is element 42. A small reminder that even an ordinary number can hide a little chemistry.',
  ),
  'aromatic': (
    'Aromatic club',
    'Six electrons. One very good ring.',
    'Benzene has six π electrons: 4n + 2 with n = 1. Your curiosity has excellent orbital symmetry.',
  ),
};
final curiosityProvider = NotifierProvider<CuriosityController, Set<String>>(
  CuriosityController.new,
);

class CuriosityController extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      (ref
                  .watch(appearanceStorageProvider)
                  ?.getStringList('curiosity.discoveries.v1') ??
              [])
          .where(curiositySecrets.containsKey)
          .toSet();
  Future<void> discover(String id) async {
    if (!curiositySecrets.containsKey(id) || state.contains(id)) {
      return;
    }
    final next = {...state, id};
    final storage = ref.read(appearanceStorageProvider);
    if (storage != null &&
        !await storage.setStringList(
          'curiosity.discoveries.v1',
          next.toList(),
        )) {
      return;
    }
    state = next;
  }
}

Future<void> revealCuriosity(BuildContext context, String id) async {
  final secret = curiositySecrets[id];
  if (secret == null) {
    return;
  }
  FocusManager.instance.primaryFocus?.unfocus();
  try {
    await ProviderScope.containerOf(
      context,
      listen: false,
    ).read(curiosityProvider.notifier).discover(id);
  } catch (_) {
    /* Optional discovery storage must not interrupt studying. */
  }
  if (!context.mounted) {
    return;
  }
  AppHaptics.success();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _SecretDialog(secret: secret),
  );
}

class _SecretDialog extends StatefulWidget {
  const _SecretDialog({required this.secret});
  final (String, String, String) secret;
  @override
  State<_SecretDialog> createState() => _SecretDialogState();
}

class _SecretDialogState extends State<_SecretDialog> {
  double _turns = 0;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: LiquidGlassContainer(
        borderRadius: 32,
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _turns,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              child: SpringPress(
                child: IconButton.filledTonal(
                  tooltip: 'Spin the atom',
                  iconSize: 42,
                  onPressed: () => setState(() => _turns += 1),
                  icon: const Icon(Icons.bubble_chart_rounded),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.secret.$1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              widget.secret.$2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: colors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              widget.secret.$3,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 22),
            SpringPress(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to the lab'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CuriosityTrigger extends StatefulWidget {
  const CuriosityTrigger({super.key, required this.child});
  final Widget child;
  @override
  State<CuriosityTrigger> createState() => _CuriosityTriggerState();
}

class _CuriosityTriggerState extends State<CuriosityTrigger> {
  int _taps = 0;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: 'ChemBuddy mark',
    child: SpringPress(
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          _taps++;
          if (_taps == 7) {
            _taps = 0;
            revealCuriosity(context, 'curious');
          }
        },
        child: widget.child,
      ),
    ),
  );
}

class CuriosityCabinet extends ConsumerWidget {
  const CuriosityCabinet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = ref.watch(curiosityProvider);
    return LiquidGlassContainer(
      enableBlur: false,
      borderRadius: 24,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.auto_awesome_outlined),
        title: const Text('Curiosity cabinet'),
        subtitle: Text(
          found.isEmpty
              ? 'A few things reward a closer look.'
              : 'Your little discoveries, collected here.',
        ),
        trailing: Text('${found.length} / 3'),
        children: [
          for (final entry in curiositySecrets.entries)
            ListTile(
              leading: Icon(
                found.contains(entry.key)
                    ? Icons.verified_rounded
                    : Icons.lock_outline_rounded,
              ),
              title: Text(
                found.contains(entry.key) ? entry.value.$1 : 'Undiscovered',
              ),
              subtitle: Text(
                found.contains(entry.key)
                    ? entry.value.$2
                    : switch (entry.key) {
                        'curious' =>
                          'The mark in your profile has a playful side.',
                        'molybdenum' =>
                          'A familiar answer is hiding in the toolkit search.',
                        _ => 'Some orbitals reward a longer look.',
                      },
              ),
              onTap: found.contains(entry.key)
                  ? () => revealCuriosity(context, entry.key)
                  : null,
            ),
        ],
      ),
    );
  }
}
