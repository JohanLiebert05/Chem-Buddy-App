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
    ('sn2', 'SN2 Inversion'),
    ('sn1', 'SN1 Substitution'),
    ('e2', 'E2 Anti-Periplanar'),
    ('e1', 'E1 Elimination'),
    ('cannizzaro', 'Cannizzaro Redox'),
    ('wittig', 'Wittig Olefination'),
    ('diels_alder', 'Diels-Alder (4+2)'),
    ('grignard', 'Grignard Addition'),
    ('beckmann', 'Beckmann Rearrangement'),
    ('benzoin', 'Benzoin Condensation'),
  ];

  void _openMechanisms(BuildContext context, [String? query]) {
    AppHaptics.selection();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReactionMechanismsScreen(initialReactionId: query ?? highlightReaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GlowCard(
        borderColor: AppColors.borderSubtle,
        padding: const EdgeInsets.all(14),
        onTap: () => _openMechanisms(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.science_rounded, size: 16, color: AppColors.brandBright),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'REACTION MECHANISMS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: AppColors.brandBright,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: AppColors.statusSuccess,
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Step-by-step electron arrow movements, transition states, and interactive vector diagrams.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_tree_outlined, size: 13, color: AppColors.brandBright),
                      SizedBox(width: 6),
                      Text(
                        '10+ Diagrams Active',
                        style: TextStyle(color: AppColors.brandBright, fontWeight: FontWeight.w600, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return GlowCard(
      borderColor: AppColors.borderSubtle,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science_rounded, size: 24, color: AppColors.brandBright),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REACTION MECHANISMS',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Curated organic mechanisms with vector diagrams and arrow pushing',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore 10+ core MSc reaction mechanisms complete with curved electron arrows, transition states, vector diagrams, and synthetic applications.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _previewReactions.map((entry) {
              final id = entry.$1;
              final name = entry.$2;
              return InkWell(
                onTap: () => _openMechanisms(context, id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_outward_rounded, size: 12, color: AppColors.accentCyan),
                      const SizedBox(width: 5),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _openMechanisms(context),
              icon: const Icon(Icons.hub_rounded, size: 18),
              label: const Text(
                'Explore Reaction Mechanisms',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
