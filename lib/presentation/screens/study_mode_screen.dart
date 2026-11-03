import 'package:flutter/material.dart';

import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../data/models/organic_study.dart';
import '../../data/services/organic_curriculum.dart';
import '../../data/services/organic_progress_repository.dart';
import 'organic_lesson_screen.dart';

/// Home and Library share these entry points; each opens its own destination.
class OrganicStudyEntrypoints extends StatefulWidget {
  const OrganicStudyEntrypoints({super.key, this.onlyCurious, this.repository});
  final bool? onlyCurious;
  final OrganicProgressRepository? repository;
  @override
  State<OrganicStudyEntrypoints> createState() =>
      _OrganicStudyEntrypointsState();
}

class _OrganicStudyEntrypointsState extends State<OrganicStudyEntrypoints> {
  late final OrganicProgressRepository _repo =
      widget.repository ?? OrganicProgressRepository.hive();
  late OrganicProgress _progress = _repo.load();
  @override
  void initState() {
    super.initState();
    OrganicProgressRepository.completions.addListener(_reload);
  }

  void _reload() {
    if (mounted) setState(() => _progress = _repo.load());
  }

  @override
  void dispose() {
    OrganicProgressRepository.completions.removeListener(_reload);
    super.dispose();
  }

  Future<void> _open(bool curious) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => curious
            ? CuriousScreen(repository: _repo)
            : StudyModeScreen(repository: _repo),
      ),
    );
    if (mounted) setState(() => _progress = _repo.load());
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.onlyCurious != true)
        GlowCard(
          borderRadius: 28,
          onTap: () => _open(false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'STUDY MODE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Basics of Organic Chemistry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Short lessons, worked examples and a place to start again.',
              ),
              const SizedBox(height: 12),
              Text(
                '${_progress.completed}/60 levels · ${_progress.streak(DateTime.now())} day streak',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '5–20 min · offline',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      if (widget.onlyCurious == null) const SizedBox(height: 12),
      if (widget.onlyCurious != false)
        GlowCard(
          borderRadius: 24,
          onTap: () => _open(true),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curious',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'One intriguing question. Explore the chemistry behind it.',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
    ],
  );
}

class StudyModeScreen extends StatefulWidget {
  const StudyModeScreen({super.key, this.repository});
  final OrganicProgressRepository? repository;
  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  late final OrganicProgressRepository _repo =
      widget.repository ?? OrganicProgressRepository.hive();
  late OrganicProgress _progress = _repo.load();
  String? _error;
  @override
  void initState() {
    super.initState();
    _repo.accountChanges?.addListener(_accountChanged);
  }

  void _accountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.accountChanges?.removeListener(_accountChanged);
    super.dispose();
  }

  Future<void> _open(int number, {bool curious = false}) async {
    await openOrganicLesson(
      context,
      _repo,
      _progress,
      organicLessons[number - 1],
      curious: curious,
    );
    if (mounted) setState(() => _progress = _repo.load());
  }

  void _about() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A small daily practice',
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              '60 levels, grouped into 12 chapters. Aim for one level a day over two months, or move at your own pace.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Five minutes gives you three minutes to learn and two to practise. Longer sessions add worked examples, advanced connections and time to explain your reasoning.',
            ),
            const SizedBox(height: 12),
            const Text(
              'This is a foundation-to-MSc bridge. Continue with your university syllabus and longer problems; finishing a short course does not guarantee exam mastery.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Lessons and diagrams work offline. Progress is saved on this device, separately for each account. Two of three correct checks unlock the next level. Replays improve your best score without repeatedly awarding XP.',
            ),
            const SizedBox(height: 20),
            Text(
              '${_progress.xp} XP · ${_progress.activeSeconds ~/ 60} active minutes',
            ),
          ],
        ),
      ),
    ),
  );
  Widget _chapter(int chapter) {
    final lessons = organicLessons.skip(chapter * 5).take(5);
    final done = lessons
        .where((l) => _progress.scores.containsKey(l.number))
        .length;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlowCard(
        padding: EdgeInsets.zero,
        borderRadius: 24,
        child: ExpansionTile(
          key: PageStorageKey('organic-chapter-$chapter'),
          initiallyExpanded: (_progress.nextLevel - 1) ~/ 5 == chapter,
          leading: CircleAvatar(
            child: done == 5 ? const Icon(Icons.check) : Text('${chapter + 1}'),
          ),
          title: Text(
            organicChapters[chapter],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Levels ${chapter * 5 + 1}–${chapter * 5 + 5} · $done/5',
          ),
          children: [
            for (final lesson in lessons)
              ListTile(
                key: ValueKey('level-${lesson.number}'),
                leading: Icon(
                  _progress.scores.containsKey(lesson.number)
                      ? Icons.check_circle_rounded
                      : _progress.unlocked(lesson.number)
                      ? Icons.play_circle_fill_rounded
                      : Icons.lock_outline_rounded,
                  color: _progress.scores.containsKey(lesson.number)
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                title: Text('${lesson.number}. ${lesson.title}'),
                subtitle: Text(
                  _progress.scores.containsKey(lesson.number)
                      ? 'Best: ${_progress.scores[lesson.number]}/3'
                      : _progress.unlocked(lesson.number)
                      ? 'Ready'
                      : 'Complete level ${lesson.number - 1}',
                ),
                onTap: _progress.unlocked(lesson.number)
                    ? () => _open(lesson.number)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_repo.currentAccount()) {
      return const Scaffold(
        body: Center(child: Text('Account changed. Reopen Study Mode.')),
      );
    }
    final resume = _progress.session != null && !_progress.session!.curious;
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Study Mode'),
          actions: [
            IconButton(
              tooltip: 'About this course',
              onPressed: _about,
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            LiquidGlassContainer(
              enableBlur: false,
              borderRadius: 28,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basics of Organic Chemistry',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('From the first bond to advanced reasoning.'),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: _progress.completed / 60,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      Text('${_progress.completed}/60 levels'),
                      _Stat(
                        Icons.local_fire_department_outlined,
                        '${_progress.streak(DateTime.now())} day streak',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Today’s session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final length in StudyLength.values)
                  ChoiceChip(
                    label: Text('${length.minutes} min'),
                    selected: _progress.preferredMinutes == length.minutes,
                    onSelected: (_) async {
                      final old = _progress.preferredMinutes;
                      setState(
                        () => _progress.preferredMinutes = length.minutes,
                      );
                      try {
                        await _repo.save(_progress);
                      } catch (_) {
                        if (mounted) {
                          setState(() {
                            _progress.preferredMinutes = old;
                            _error = 'Could not save your session preference. Try again.';
                          });
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress.preferredMinutes * .6).round()} min explanation + ${(_progress.preferredMinutes * .4).round()} min practice',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_progress.nextClue.isNotEmpty) ...[
              const SizedBox(height: 20),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A note from last time',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(_progress.nextClue),
                  ],
                ),
              ),
            ],
            if (_progress.session?.curious == true)
              TextButton.icon(
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Continue saved discovery'),
                onPressed: () =>
                    _open(_progress.session!.lesson, curious: true),
              ),
            const SizedBox(height: 26),
            Text('Your journey', style: Theme.of(context).textTheme.titleLarge),
            for (var chapter = 0; chapter < 12; chapter++) _chapter(chapter),
            if (_progress.mistakes.values.any((v) => v.isNotEmpty)) ...[
              const SizedBox(height: 26),
              Text(
                'Worth another look',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final e in _progress.mistakes.entries.where(
                (e) => e.value.isNotEmpty,
              ))
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(organicLessons[int.parse(e.key) - 1].title),
                  subtitle: Text(
                    '${e.value.length} check${e.value.length == 1 ? '' : 's'} to revisit',
                  ),
                  onTap: () => _open(int.parse(e.key)),
                ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                resume
                    ? 'Continue level ${_progress.session!.lesson}'
                    : _progress.completed == 60
                    ? 'Revisit the final level'
                    : 'Start level ${_progress.nextLevel}',
              ),
              onPressed: () => _open(
                resume ? _progress.session!.lesson : _progress.nextLevel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 5),
      Flexible(child: Text(label)),
    ],
  );
}

const curiousLevels = [31, 8, 32, 30, 33, 20, 17, 43, 48, 52, 53, 58];

class CuriousScreen extends StatefulWidget {
  const CuriousScreen({super.key, this.repository});
  final OrganicProgressRepository? repository;
  @override
  State<CuriousScreen> createState() => _CuriousScreenState();
}

class _CuriousScreenState extends State<CuriousScreen> {
  late final OrganicProgressRepository _repo =
      widget.repository ?? OrganicProgressRepository.hive();
  late OrganicProgress _progress = _repo.load();
  @override
  void initState() {
    super.initState();
    _repo.accountChanges?.addListener(_accountChanged);
  }

  void _accountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.accountChanges?.removeListener(_accountChanged);
    super.dispose();
  }

  Future<void> _open(OrganicLesson lesson) async {
    await openOrganicLesson(context, _repo, _progress, lesson, curious: true);
    if (mounted) setState(() => _progress = _repo.load());
  }

  @override
  Widget build(BuildContext context) {
    if (!_repo.currentAccount()) {
      return const Scaffold(
        body: Center(child: Text('Account changed. Reopen Curious.')),
      );
    }
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Curious')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pick a question.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Explore the chemistry behind it, with a diagram and a worked example. About ten minutes each.',
            ),
            const SizedBox(height: 12),
            Text(
              '${_progress.discoveries.length} discoveries completed · separate from your course levels',
            ),
            if (_progress.session?.curious == true)
              TextButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume discovery'),
                onPressed: () =>
                    _open(organicLessons[_progress.session!.lesson - 1]),
              ),
            for (final number in curiousLevels)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GlowCard(
                  borderRadius: 28,
                  onTap: () => _open(organicLessons[number - 1]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _progress.discoveries.contains(number)
                                ? Icons.check_circle
                                : Icons.lightbulb_outline,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          const Text('10 min'),
                          const Spacer(),
                          const Icon(Icons.arrow_outward_rounded, size: 18),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        organicLessons[number - 1].hook,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(organicLessons[number - 1].title),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> openOrganicLesson(
  BuildContext context,
  OrganicProgressRepository repository,
  OrganicProgress progress,
  OrganicLesson lesson, {
  bool curious = false,
}) async {
  if (!repository.currentAccount()) return;
  var session = progress.session;
  if (session != null &&
      (session.lesson != lesson.number || session.curious != curious)) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('A session is already saved'),
        content: const Text(
          'Starting this lesson replaces the unfinished session. Completed levels, streaks and best scores are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep saved session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start this lesson'),
          ),
        ],
      ),
    );
    if (replace != true || !context.mounted) return;
    session = null;
  }
  if (!curious && !progress.unlocked(lesson.number)) return;
  final previous = progress.session;
  session ??= OrganicSession(
    lesson: lesson.number,
    minutes: curious ? 10 : progress.preferredMinutes,
    curious: curious,
  );
  progress.session = session;
  try {
    await repository.save(progress);
  } catch (_) {
    progress.session = previous;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
    return;
  }
  if (!context.mounted) return;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => OrganicLessonScreen(
        repository: repository,
        progress: progress,
        session: session!,
        lesson: lesson,
      ),
    ),
  );
}
