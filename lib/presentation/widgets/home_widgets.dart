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
                  color: (weakTopics.isNotEmpty ? AppColors.danger : AppColors.brandPrimary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  weakTopics.isNotEmpty ? Icons.warning_amber_rounded : Icons.task_alt_rounded,
                  color: weakTopics.isNotEmpty ? AppColors.danger : AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today’s Study Priorities', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      weakTopics.isNotEmpty
                          ? '${weakTopics.length} topic(s) need immediate reinforcement'
                          : (hasPriorities ? 'Reinforce moderate topics' : 'Mastery looking great'),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
                color: AppColors.bg0,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All tested chemistry topics are in strong mastery! Keep your study streak going with flashcard reviews.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...weakTopics.take(3).map((w) => _buildTopicRow(w.topic, '${w.accuracy.toStringAsFixed(0)}% accuracy', AppColors.danger, 'WEAK')),
            ...moderateTopics.take(2).map((m) => _buildTopicRow(m.topic, '${m.accuracy.toStringAsFixed(0)}% accuracy', AppColors.warning, 'REVIEW')),
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
        color: AppColors.bg0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
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
                'Hello, $displayName 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
