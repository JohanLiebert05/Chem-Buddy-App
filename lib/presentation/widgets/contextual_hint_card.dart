import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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
    if (!_visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowCard(
        borderColor: AppColors.purpleBright.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.purpleBright, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.message,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                  ),
                  if (widget.actionLabel != null && widget.onAction != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onAction,
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          color: AppColors.purpleBright,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
              onPressed: _dismiss,
            ),
          ],
        ),
      ),
    );
  }
}
