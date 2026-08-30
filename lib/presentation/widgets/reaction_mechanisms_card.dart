import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../screens/reaction_mechanism_screen.dart';

class ReactionMechanismsCard extends StatelessWidget {
  const ReactionMechanismsCard({
    super.key,
    this.compact = false,
    this.highlightReaction,
    this.onNotifyTap,
  });

  final bool compact;
  final String? highlightReaction;
  final VoidCallback? onNotifyTap;

  static const _previewReactions = [
    'Aldol Condensation',
    'Cannizzaro Reaction',
    'Wittig Reaction',
    'Diels-Alder (4+2)',
    'Grignard Addition',
    'Benzoin Condensation',
    'Beckmann Rearrangement',
    'SN1 vs SN2',
  ];

  void _openMechanisms(BuildContext context, [String? reactionName]) {
    AppHaptics.tap();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ReactionMechanismsScreen(
          initialReactionId: reactionName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GlowCard(
        borderColor: AppColors.purple.withValues(alpha: 0.45),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('⚗️', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'REACTION MECHANISMS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                      color: AppColors.purpleBright,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'EXPLORE',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              highlightReaction != null
                ? 'Step-by-step electron movement & intermediates for "$highlightReaction".'
                : 'Explore verified reaction mechanisms with step-by-step visual explanations.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openMechanisms(context, highlightReaction),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: AppColors.purpleBright),
                    SizedBox(width: 6),
                    Text(
                      'View Mechanism →',
                      style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlowCard(
      borderColor: AppColors.purple.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.purple.withValues(alpha: 0.3),
                      AppColors.purpleBright.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                ),
                child: const Text('⚗️', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'REACTION MECHANISMS',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'LIVE ⚡',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Verified MSc Organic & Inorganic Mechanisms with Curved Arrows',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Explore verified reaction mechanisms with step-by-step visual explanations, curved electron arrows, and intermediate structures.',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _previewReactions.map((name) {
              final isTarget = highlightReaction != null &&
                  name.toLowerCase().contains(highlightReaction!.toLowerCase());
              return InkWell(
                onTap: () => _openMechanisms(context, name),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTarget
                        ? AppColors.purple.withValues(alpha: 0.25)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTarget
                          ? AppColors.purpleBright
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isTarget ? FontWeight.w700 : FontWeight.w600,
                      color: isTarget ? AppColors.purpleBright : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _openMechanisms(context),
              icon: const Icon(Icons.auto_stories_outlined, size: 18),
              label: const Text(
                'Explore All Reaction Mechanisms →',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

