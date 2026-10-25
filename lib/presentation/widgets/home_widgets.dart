import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/services/study_analytics_service.dart';

class StudyPrioritiesCard extends StatelessWidget {
  const StudyPrioritiesCard({
    super.key,
    required this.weakTopics,
    required this.moderateTopics,
    this.onTopicTap,
  });

  final List<TopicMastery> weakTopics;
  final List<TopicMastery> moderateTopics;
  final void Function(String topic)? onTopicTap;

  @override
  Widget build(BuildContext context) {
    final hasPriorities = weakTopics.isNotEmpty || moderateTopics.isNotEmpty;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (weakTopics.isNotEmpty ? AppColors.statusDanger : AppColors.brandPrimary).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  weakTopics.isNotEmpty ? Icons.warning_amber_rounded : Icons.task_alt_rounded,
                  color: weakTopics.isNotEmpty ? AppColors.statusDanger : AppColors.statusSuccess,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Priorities',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      weakTopics.isNotEmpty
                          ? '${weakTopics.length} topic${weakTopics.length == 1 ? "" : "s"} need reinforcement'
                          : (hasPriorities ? 'Reinforce moderate topics' : 'Mastery looking strong'),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasPriorities) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.statusSuccess, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All tested chemistry topics are in strong mastery. Keep your momentum with flashcard reviews.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...weakTopics.take(3).map((w) => _buildTopicRow(w.topic, '${w.accuracy.toStringAsFixed(0)}% accuracy', AppColors.statusDanger, 'NEEDS FOCUS')),
            ...moderateTopics.take(2).map((m) => _buildTopicRow(m.topic, '${m.accuracy.toStringAsFixed(0)}% accuracy', AppColors.statusWarning, 'REVIEW')),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicRow(String topic, String subtitle, Color color, String badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    super.key,
    required this.name,
    required this.university,
    required this.semester,
    this.onAvatarTap,
  });

  final String name;
  final String university;
  final int semester;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'MSc Chemist' : name.trim();
    final subInfo = '${university.isNotEmpty ? university : "MSc Chemistry"} · Semester $semester';

    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: const AtomLogo(size: 46),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $displayName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subInfo,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
