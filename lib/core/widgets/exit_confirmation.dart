import 'expressive_motion.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass.dart';

/// Confirms Android root-back exits. Child routes keep their normal back action.
class ExitConfirmation extends StatefulWidget {
  const ExitConfirmation({
    super.key,
    required this.child,
    this.enabled,
    this.onExit,
  });
  final Widget child;
  final bool? enabled;
  final VoidCallback? onExit;
  @override
  State<ExitConfirmation> createState() => _ExitConfirmationState();
}

class _ExitConfirmationState extends State<ExitConfirmation> {
  bool _asking = false;
  Future<void> _confirm() async {
    if (_asking) {
      return;
    }
    _asking = true;
    try {
      final leave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: LiquidGlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Exit ChemBuddy?',
                  style: Theme.of(dialogContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                const Text('You can return to your study space anytime.'),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    SpringPress(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Stay'),
                      ),
                    ),
                    SpringPress(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Exit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (leave == true && mounted) {
        if (widget.onExit != null) {
          widget.onExit!();
        } else {
          await SystemNavigator.pop();
        }
      }
    } finally {
      _asking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        widget.enabled ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
    return PopScope<Object?>(
      canPop: !enabled,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && enabled) {
          _confirm();
        }
      },
      child: widget.child,
    );
  }
}
