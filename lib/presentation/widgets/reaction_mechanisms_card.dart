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
    'SN1 Substitution',
    'SN2 Inversion',
    'E1 Elimination',
    'E2 Anti-Periplanar',
    'Cannizzaro Redox',
    'Wittig Olefination',
    'Diels-Alder (4+2)',
    'Grignard Addition',
    'Beckmann Rearrangement',
    'Benzoin Condensation',
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
        borderColor: AppColors.purple.withValues(alpha: 0.35),
        padding: const EdgeInsets.all(14),
        onTap: () => _openMechanisms(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.15),
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
                      color: AppColors.brandBright,
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
                    'MSc VERIFIED',
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
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.polyline_rounded, size: 13, color: AppColors.purpleBright),
                      SizedBox(width: 6),
                      Text(
                        '10+ Diagrams Active ➔',
                        style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 11.5),
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
      borderColor: AppColors.purple.withValues(alpha: 0.35),
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
                      AppColors.brandPrimary.withValues(alpha: 0.25),
                      AppColors.brandBright.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.25)),
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
                            'UNLOCKED 🧪',
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
                      'Curated MSc Organic Mechanisms with Vector Diagrams & Curved Arrows',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Explore 10+ core MSc reaction mechanisms complete with curved electron arrows, transition states, pinch-to-zoom vector diagrams, and synthetic applications.',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _previewReactions.map((name) {
              return InkWell(
                onTap: () => _openMechanisms(context, name),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 12, color: AppColors.accentGold),
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
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 2,
              ),
              onPressed: () => _openMechanisms(context),
              icon: const Icon(Icons.hub_rounded, size: 18),
              label: const Text(
                'Explore Reaction Mechanisms ⚗️',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



