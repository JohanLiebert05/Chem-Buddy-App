import '../../core/widgets/expressive_motion.dart';

import 'package:flutter/material.dart';

import '../../core/widgets/glow_card.dart';

class ContextualHintCard extends StatefulWidget {
  const ContextualHintCard({
    super.key,
    required this.hintKey,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String hintKey;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<ContextualHintCard> createState() => _ContextualHintCardState();
}

class _ContextualHintCardState extends State<ContextualHintCard> {
  static final Set<String> _dismissedKeys = <String>{};
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (_dismissedKeys.contains(widget.hintKey)) {
      _visible = false;
    }
  }

  void _dismiss() {
    setState(() {
      _visible = false;
      _dismissedKeys.add(widget.hintKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowCard(
        borderColor: Theme.of(context).colorScheme.primary
            .withValues(alpha: 0.35),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(height: 6),
                    SpringPress(
                      child: GestureDetector(
                        onTap: widget.onAction,
                        child: Text(
                          widget.actionLabel!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SpringPress(
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
                onPressed: _dismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
