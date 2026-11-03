import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/organic_study.dart';
import '../../data/services/organic_curriculum.dart';
import '../../data/services/organic_progress_repository.dart';
import '../widgets/organic_study_diagram.dart';

class OrganicLessonScreen extends StatefulWidget {
  const OrganicLessonScreen({
    super.key,
    required this.repository,
    required this.progress,
    required this.session,
    required this.lesson,
    this.createStopwatch,
  });
  final OrganicProgressRepository repository;
  final OrganicProgress progress;
  final OrganicSession session;
  final OrganicLesson lesson;

  /// Injectable monotonic clock for lifecycle tests; production uses Stopwatch.
  final Stopwatch Function()? createStopwatch;
  @override
  State<OrganicLessonScreen> createState() => _OrganicLessonScreenState();
}

class _OrganicLessonScreenState extends State<OrganicLessonScreen>
    with WidgetsBindingObserver {
  late OrganicSession _session = widget.session;
  late final TextEditingController _reflection = TextEditingController(
    text: _session.reflection,
  );
  late final _prediction = TextEditingController(text: _session.prediction);
  late final _nextClue = TextEditingController(text: widget.progress.nextClue);
  Timer? _editTimer;
  final _clock = ValueNotifier<int>(0);
  late final _stopwatch = widget.createStopwatch?.call() ?? Stopwatch();
  final _selections = <int, int>{};
  final _questionAnchor = GlobalKey();
  Timer? _ticker;
  int _lastTick = 0;
  int _lastCheckpoint = 0;
  bool _running = false,
      _completed = false,
      _finishing = false,
      _allowExit = false,
      _exiting = false;
  int? _result;
  String? _error;
  Future<void> _writes = Future.value();
  bool get _sameAccount => widget.repository.currentAccount();
  int get _sections => _session.minutes == 5
      ? 3
      : _session.minutes == 10
      ? 4
      : 5;
  StudyLength get _length => StudyLength.decode(_session.minutes);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.repository.accountChanges?.addListener(_accountChanged);
    _session.section = _session.section.clamp(0, _sections - 1);
    _reflection.addListener(() {
      _session.reflection = _reflection.text;
      _updateCompletedReasoning();
      _saveDraftSoon();
    });
    _prediction.addListener(() {
      _session.prediction = _prediction.text;
      _updateCompletedReasoning();
      _saveDraftSoon();
    });
    _nextClue.addListener(() {
      widget.progress.nextClue = _nextClue.text;
      _saveDraftSoon();
    });
  }

  void _accountChanged() => _pause(save: false);
  void _updateCompletedReasoning() {
    if (!_completed) return;
    final key =
        '${_session.curious ? 'curious' : 'organic'}_${widget.lesson.number}';
    final previous = widget.progress.journal[key];
    if (previous != null) {
      widget.progress.journal[key] = {
        ...previous,
        'reflection': _session.reflection,
        'prediction': _session.prediction,
      };
    }
  }

  void _saveDraftSoon() {
    _editTimer?.cancel();
    _editTimer = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(_persist(allowCompleted: _completed)),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_running) {
        _pause();
      } else {
        unawaited(_persist(allowCompleted: _completed));
      }
    }
  }

  Future<void> _persist({bool allowCompleted = false}) {
    if ((_completed && !allowCompleted) || !_sameAccount) return Future.value();
    final snapshot = widget.progress.snapshot();
    _writes = _writes
        .catchError((Object _) {})
        .then((_) => widget.repository.save(snapshot));
    // Attach an error handler immediately, including on lifecycle/dispose saves.
    return _writes.then<void>(
      (_) {
        if (mounted && _error != null) setState(() => _error = null);
      },
      onError: (Object e) {
        if (mounted) {
          setState(
            () => _error =
                'Could not save progress. Your answers remain here; try again.',
          );
        }
      },
    );
  }

  void _start() {
    if (_completed || !_sameAccount || _running || _exiting) return;
    _lastTick = 0;
    _lastCheckpoint = 0;
    _stopwatch
      ..reset()
      ..start();
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_sameAccount) {
      _pause(save: false);
      return;
    }
    final elapsed = _stopwatch.elapsed.inSeconds;
    final delta = elapsed - _lastTick;
    if (delta <= 0) return;
    _lastTick = elapsed;
    final before = _session.phase == 0
        ? _session.learnSeconds
        : _session.practiceSeconds;
    if (_session.phase == 0) {
      _session.learnSeconds += delta;
    } else {
      _session.practiceSeconds += delta;
    }
    widget.progress.activeSeconds += delta;
    _clock.value++;
    final budget = _session.phase == 0
        ? _length.learnSeconds
        : _length.practiseSeconds;
    if (before < budget && before + delta >= budget) {
      _pause(); // A timebox ends with a choice; never auto-submit or erase content.
    } else if (elapsed - _lastCheckpoint >= 5) {
      _lastCheckpoint = elapsed;
      unawaited(_persist());
    }
  }

  void _pause({bool save = true}) {
    if (_running) _tickRemainder();
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
    if (mounted) setState(() => _running = false);
    if (save) unawaited(_persist());
  }

  void _tickRemainder() {
    final delta = _stopwatch.elapsed.inSeconds - _lastTick;
    if (delta <= 0 || !_sameAccount) return;
    if (_session.phase == 0) {
      _session.learnSeconds += delta;
    } else {
      _session.practiceSeconds += delta;
    }
    widget.progress.activeSeconds += delta;
    _lastTick += delta;
  }

  void _phase(int phase) {
    _pause(save: false);
    setState(() => _session.phase = phase);
    unawaited(_persist());
  }

  Future<void> _finish() async {
    if (_finishing || _completed || _exiting) return;
    _pause(save: false);
    _editTimer?.cancel();
    setState(() => _finishing = true);
    try {
      await _writes.catchError((Object _) {});
      final result = await widget.repository.finish(
        widget.progress,
        _session,
        widget.lesson,
        DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _completed = true;
        _result = result;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save your result. Keep this screen open and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _exit() async {
    if (_exiting || _finishing) return;
    _exiting = true;
    _editTimer?.cancel();
    _pause(save: false);
    if (_sameAccount) {
      await _persist(allowCompleted: true);
      if (_error != null) {
        _exiting = false;
        return;
      }
    }
    if (!mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _retry() async {
    final next = OrganicSession(
      lesson: _session.lesson,
      minutes: _session.minutes,
      curious: _session.curious,
    );
    final previous = widget.progress.session;
    widget.progress.session = next;
    try {
      await widget.repository.save(widget.progress);
    } catch (_) {
      widget.progress.session = previous;
      if (mounted) {
        setState(
          () => _error = 'Could not start another attempt. Please try again.',
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _session = next;
      _completed = false;
      _result = null;
      _selections.clear();
      _reflection.clear();
      _prediction.clear();
      _error = null;
    });
  }

  Future<void> _questionStep(int delta) async {
    final target = _questionAnchor.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        alignment: .05,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(
      () =>
          _session.questionIndex = (_session.questionIndex + delta).clamp(0, 2),
    );
    unawaited(_persist());
  }

  Future<void> _showReasoning() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My reasoning',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'Keep a thought, connect it to evidence, and leave a question for your next visit.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _prediction,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'My first thought',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reflection,
                minLines: 3,
                maxLines: 7,
                maxLength: 4000,
                decoration: const InputDecoration(
                  labelText: 'What supports it?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nextClue,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'A question for next time',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your words are saved on this device. Compare them with the lesson; they are not automatically graded.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await _persist(allowCompleted: _completed);
                  if (!ctx.mounted) return;
                  if (_error == null) {
                    Navigator.pop(ctx);
                  } else {
                    await showDialog<void>(
                      context: ctx,
                      builder: (dialog) => AlertDialog(
                        title: const Text('Could not save'),
                        content: Text(_error!),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialog),
                            child: const Text('Back to my notes'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text('Save and close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.repository.accountChanges?.removeListener(_accountChanged);
    _tickRemainder();
    _editTimer?.cancel();
    _ticker?.cancel();
    _stopwatch.stop();
    if (!_allowExit) unawaited(_persist(allowCompleted: _completed));
    _reflection.dispose();
    _prediction.dispose();
    _nextClue.dispose();
    _clock.dispose();
    super.dispose();
  }

  Widget _timer(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: _clock,
    builder: (context, _, child) {
      final elapsed = _session.phase == 0
          ? _session.learnSeconds
          : _session.practiceSeconds;
      final budget = _session.phase == 0
          ? _length.learnSeconds
          : _length.practiseSeconds;
      final extra = elapsed > budget;
      final time = extra
          ? elapsed - budget
          : (budget - elapsed).clamp(0, budget);
      return GlowCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_session.phase == 0 ? 'Learn' : 'Practise'} · ${extra ? 'extra time ' : ''}${time ~/ 60}:${(time % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: _running ? 'Pause' : 'Start / resume',
                  onPressed: _running ? () => _pause() : _start,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (elapsed / budget).clamp(0, 1),
              minHeight: 3,
              borderRadius: BorderRadius.circular(4),
            ),
            if (!_running && elapsed >= budget)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Timebox complete. Continue at your pace or change stage.',
                ),
              ),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_exit());
      },
      child: HexBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: 'My reasoning',
                onPressed: _showReasoning,
                icon: const Icon(Icons.edit_note_rounded),
              ),
            ],
            leading: IconButton(
              tooltip: 'Save and exit',
              onPressed: _exit,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              _session.curious
                  ? 'Curious'
                  : 'Level ${widget.lesson.number} of 60',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: !_sameAccount
              ? const Center(
                  child: Text(
                    'Account changed. Close this session and reopen it for your current account.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                  children: [
                    Text(
                      widget.lesson.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.lesson.hook,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 18),
                    if (!_completed) ...[
                      _timer(context),
                      const SizedBox(height: 16),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('Learn'),
                            icon: Icon(Icons.menu_book_outlined),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text('Practise'),
                            icon: Icon(Icons.quiz_outlined),
                          ),
                        ],
                        selected: {_session.phase},
                        onSelectionChanged: (v) => _phase(v.first),
                      ),
                      const SizedBox(height: 18),
                      if (_session.phase == 0)
                        ..._learning(context)
                      else
                        ..._practice(context),
                    ] else
                      ..._resultWidgets(context),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          _error!,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    const SizedBox(height: 22),
                    ExpansionTile(
                      title: const Text('Further reading & course scope'),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Original lesson text and vector teaching diagrams. The 60 levels provide a foundation and a bridge into MSc reasoning, not a complete university syllabus or a promise of exam mastery. Timeboxes are suggestions. Your course progress is saved on this device, separately for each account.',
                          ),
                        ),
                        for (final source in organicReading)
                          ListTile(
                            title: Text(source.$1),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () async {
                              _pause();
                              final success = await launchUrl(
                                Uri.parse(source.$2),
                                mode: LaunchMode.externalApplication,
                              ).catchError((Object _) => false);
                              if (!success && mounted) {
                                setState(
                                  () => _error = 'Could not open the reading link. Your offline lesson is still available.',
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _learning(BuildContext context) {
    final lesson = widget.lesson;
    final section = _session.section;
    final previous = widget
        .progress
        .journal['${_session.curious ? 'curious' : 'organic'}_${lesson.number}'];
    final titles = [
      'The idea',
      'The diagram',
      'Why it happens',
      'A little deeper',
      'Your explanation',
    ];
    return [
      Text(
        'Part ${section + 1} of $_sections',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      GlowCard(
        borderRadius: 26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[section],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (section == 0) ...[
              ExpansionTile(
                title: const Text('What do you think so far?'),
                children: [
                  TextField(
                    controller: _prediction,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'My first thought',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
              if (previous != null &&
                  '${previous['reflection']}${previous['prediction']}'
                      .isNotEmpty)
                ExpansionTile(
                  title: const Text('Your reasoning last time'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        studyText(previous['reflection']).isNotEmpty
                            ? studyText(previous['reflection'])
                            : studyText(previous['prediction']),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Would you keep this explanation or change it? Your new thought is saved separately until you finish.',
                      ),
                    ),
                  ],
                ),
              Text(
                lesson.simple,
                style: const TextStyle(fontSize: 17, height: 1.65),
              ),
            ],
            if (section == 1) ...[
              OrganicStudyDiagram(diagram: lesson.diagram),
              if (lesson.number == 31)
                ExpansionTile(
                  title: const Text('Where are the pi electrons?'),
                  children: const [
                    OrganicStudyDiagram(diagram: 'aromatic_cloud'),
                  ],
                ),
            ],
            if (section == 2) ...[
              Text(
                lesson.reasoning,
                style: const TextStyle(fontSize: 17, height: 1.65),
              ),
              const SizedBox(height: 18),
              const Text(
                'Worked example',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.example,
                style: const TextStyle(fontSize: 17, height: 1.65),
              ),
            ],
            if (section == 3) ...[
              Text(
                lesson.advanced,
                style: const TextStyle(fontSize: 17, height: 1.65),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect it back: which part of the diagram helps explain this more advanced idea?',
              ),
            ],
            if (section == 4) ...[
              Text(
                'Using ${lesson.title.toLowerCase()}, explain the worked example to a friend. Name the evidence, the electron source and destination where relevant, and one limitation of your explanation.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reflection,
                minLines: 4,
                maxLines: 10,
                maxLength: 4000,
                decoration: const InputDecoration(
                  labelText: 'My explanation',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const Text(
                'Self-check: compare your explanation with the worked example and MSc connection. This writing is saved, not automatically graded.',
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (section > 0)
            OutlinedButton(
              onPressed: () {
                setState(() => _session.section--);
                unawaited(_persist());
              },
              child: const Text('Previous part'),
            ),
          FilledButton.icon(
            icon: Icon(
              section == _sections - 1
                  ? Icons.quiz_outlined
                  : Icons.arrow_forward,
            ),
            label: Text(
              section == _sections - 1 ? 'Ready to practise' : 'Next part',
            ),
            onPressed: () {
              if (section == _sections - 1) {
                _phase(1);
              } else {
                setState(() => _session.section++);
                unawaited(_persist());
              }
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _practice(BuildContext context) => [
    Text(
      _session.curious
          ? 'Try the idea for yourself.'
          : 'Two of three correct checks unlock the next level.',
    ),
    const SizedBox(height: 14),
    KeyedSubtree(
      key: _questionAnchor,
      child: _question(context, _session.questionIndex),
    ),
    const SizedBox(height: 16),
    Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        if (_session.questionIndex > 0)
          TextButton(
            onPressed: () => _questionStep(-1),
            child: const Text('Previous question'),
          ),
        if (_session.questionIndex < 2)
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _session.answers.containsKey(_session.questionIndex)
                ? () => _questionStep(1)
                : null,
            label: const Text('Next question'),
          ),
        if (_session.questionIndex == 2)
          FilledButton.icon(
            icon: const Icon(Icons.flag_outlined),
            onPressed: _session.answers.length == 3 && !_finishing
                ? _finish
                : null,
            label: Text(
              _finishing
                  ? 'Saving result…'
                  : _session.curious
                  ? 'Finish discovery'
                  : 'Finish level',
            ),
          ),
      ],
    ),
    const SizedBox(height: 20),
    ExpansionTile(
      initiallyExpanded: _session.minutes >= 15,
      title: Text(
        _session.minutes == 20
            ? 'Defend your explanation'
            : 'Explain it in your own words',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.lesson.example),
              const SizedBox(height: 12),
              TextField(
                controller: _reflection,
                minLines: 3,
                maxLines: 10,
                maxLength: 4000,
                decoration: const InputDecoration(
                  labelText: 'My reasoning',
                  border: OutlineInputBorder(),
                ),
              ),
              const Text(
                'Saved for your next visit. Compare it with the lesson; writing is self-checked.',
              ),
              if (_session.minutes >= 10)
                ExpansionTile(
                  title: const Text('Compare with the explanation'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${widget.lesson.reasoning}\n\n${widget.lesson.advanced}',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
    if (_session.minutes == 20 &&
        widget.progress.mistakes.entries.any(
          (e) => e.value.isNotEmpty && e.key != '${widget.lesson.number}',
        )) ...[
      const SizedBox(height: 16),
      Text(
        'Worth another look',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      for (final entry
          in widget.progress.mistakes.entries
              .where(
                (e) => e.value.isNotEmpty && e.key != '${widget.lesson.number}',
              )
              .take(2))
        ExpansionTile(
          title: Text(
            organicLessons[int.parse(entry.key) - 1]
                .questions[entry.value.first]
                .prompt,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                organicLessons[int.parse(entry.key) - 1]
                    .questions[entry.value.first]
                    .explanation,
              ),
            ),
          ],
        ),
    ],
  ];
  Widget _question(BuildContext context, int index) {
    final q = widget.lesson.questions[index];
    final submitted = _session.answers[index];
    final correct = submitted == q.answer;
    return GlowCard(
      key: ValueKey('organic-question-$index'),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHECK ${index + 1} / 3',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          RadioGroup<int>(
            groupValue: submitted ?? _selections[index],
            onChanged: (value) {
              if (value != null && submitted == null) {
                setState(() => _selections[index] = value);
              }
            },
            child: Column(
              children: [
                for (var option = 0; option < q.options.length; option++)
                  RadioListTile<int>(
                    enabled: submitted == null,
                    contentPadding: EdgeInsets.zero,
                    value: option,
                    title: Text(q.options[option]),
                    secondary: submitted != null && option == q.answer
                        ? Icon(
                            Icons.check_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
              ],
            ),
          ),
          if (submitted == null) ...[
            const SizedBox(height: 8),
            Text(
              'How sure are you?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final choice in const [
                  (2, 'Sure'),
                  (1, 'Unsure'),
                  (0, 'Guessing'),
                ])
                  ChoiceChip(
                    label: Text(choice.$2),
                    selected: _session.confidence[index] == choice.$1,
                    onSelected: (_) {
                      setState(() => _session.confidence[index] = choice.$1);
                      unawaited(_persist());
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: _selections.containsKey(index)
                  ? () {
                      setState(
                        () => _session.answers[index] = _selections[index]!,
                      );
                      unawaited(_persist());
                    }
                  : null,
              child: const Text('Check answer'),
            ),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                correct ? Icons.check_circle : Icons.lightbulb_outline,
              ),
              title: Text(
                correct
                    ? (_session.confidence[index] != null &&
                              _session.confidence[index]! < 2
                          ? 'Correct. Worth revisiting.'
                          : 'Correct')
                    : 'Let’s look at why',
              ),
              subtitle: Text('Your answer: ${q.options[submitted]}'),
            ),
            if (!correct)
              Text(
                'Answer: ${q.options[q.answer]}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 8),
            Text(q.explanation),
          ],
        ],
      ),
    );
  }

  List<Widget> _resultWidgets(BuildContext context) {
    final passed = _result! >= 2;
    return [
      GlowCard(
        borderRadius: 30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              passed ? Icons.celebration_outlined : Icons.school_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              passed
                  ? (_session.curious ? 'Discovery complete' : 'Level complete')
                  : 'Keep building your understanding',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '$_result / 3 correct',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _session.curious
                  ? 'Your discovery is saved separately from the course.'
                  : passed
                  ? 'Your best score and study day are saved. ${widget.lesson.number == 60 ? 'You completed the bridge. Keep practising with your syllabus.' : 'Level ${widget.lesson.number + 1} is now available.'}'
                  : 'Read the explanations and try again. Completed levels and previous best scores stay with you.',
            ),
            const SizedBox(height: 14),
            Text('Saved on this device • ${widget.progress.xp} course XP'),
          ],
        ),
      ),
      const SizedBox(height: 18),
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lesson.questions[i].prompt,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(widget.lesson.questions[i].explanation),
              ],
            ),
          ),
        ),
      ExpansionTile(
        title: const Text('Leave yourself a clue'),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: _nextClue,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'A note for next time',
                hintText: 'Next time, check…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      FilledButton(
        onPressed: _exit,
        child: Text(_session.curious ? 'Back to Curious' : 'Back to journey'),
      ),
      TextButton(
        onPressed: _retry,
        child: const Text('Practise this level again'),
      ),
    ];
  }
}
