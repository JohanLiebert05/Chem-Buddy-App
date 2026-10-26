import '../../core/widgets/expressive_motion.dart';

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
    this.hasStudyData = true,
  });

  final bool hasStudyData;
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
                  color:
                      (weakTopics.isNotEmpty
                              ? AppColors.adaptive(
                                  context,
                                  AppColors.statusDanger,
                                )
                              : Theme.of(context).colorScheme.primary)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  weakTopics.isNotEmpty
                      ? Icons.warning_amber_rounded
                      : Icons.task_alt_rounded,
                  color: weakTopics.isNotEmpty
                      ? AppColors.adaptive(context, AppColors.statusDanger)
                      : AppColors.adaptive(context, AppColors.statusSuccess),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Priorities',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      weakTopics.isNotEmpty
                          ? '${weakTopics.length} topic${weakTopics.length == 1 ? "" : "s"} need reinforcement'
                          : (hasPriorities
                                ? 'Reinforce moderate topics'
                                : (hasStudyData
                                      ? 'Your progress, at a glance'
                                      : 'Ready when you are')),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.adaptive(context, AppColors.statusSuccess),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasStudyData
                          ? 'Keep building on your progress with a short review.'
                          : 'Start with a note, a class, or a short study session.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...weakTopics
                .take(3)
                .map(
                  (w) => _buildTopicRow(
                    context,
                    w.topic,
                    '${w.accuracy.toStringAsFixed(0)}% accuracy',
                    AppColors.adaptive(context, AppColors.statusDanger),
                    'NEEDS FOCUS',
                  ),
                ),
            ...moderateTopics
                .take(2)
                .map(
                  (m) => _buildTopicRow(
                    context,
                    m.topic,
                    '${m.accuracy.toStringAsFixed(0)}% accuracy',
                    AppColors.adaptive(context, AppColors.statusWarning),
                    'REVIEW',
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicRow(
    BuildContext context,
    String topic,
    String subtitle,
    Color color,
    String badge,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
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
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.readableText(context, color),
                letterSpacing: 0.3,
              ),
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
    final subInfo =
        '${university.isNotEmpty ? university : "MSc Chemistry"} · Semester $semester';

    return Row(
      children: [
        SpringPress(
          child: GestureDetector(
            onTap: onAvatarTap,
            child: const AtomLogo(size: 46),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $displayName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
