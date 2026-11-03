import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/chemistry/spectroscopy_structure_svg.dart';
import '../../core/widgets/glow_card.dart';
import '../widgets/organic_study_background.dart';
import '../../data/services/curious_catalog.dart';
import '../../data/services/curious_explanation_service.dart';
import '../../data/services/organic_curriculum.dart';
import '../../data/services/organic_progress_repository.dart';
import '../widgets/organic_study_diagram.dart';
import 'study_mode_screen.dart';

class CuriousTopicScreen extends StatefulWidget {
  const CuriousTopicScreen({
    super.key,
    required this.topic,
    required this.repository,
    this.explanations,
    this.exploreOnOpen = false,
  });
  final CuriousTopic topic;
  final OrganicProgressRepository repository;
  final CuriousExplanationService? explanations;
  final bool exploreOnOpen;
  @override
  State<CuriousTopicScreen> createState() => _CuriousTopicScreenState();
}

class _CuriousTopicScreenState extends State<CuriousTopicScreen> {
  late final _service = widget.explanations ?? CuriousExplanationService();
  CuriousExplanation? _extra;
  bool _busy = false, _showAnswer = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    widget.repository.accountChanges?.addListener(_changed);
    if (widget.exploreOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _expand();
      });
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.repository.accountChanges?.removeListener(_changed);
    super.dispose();
  }

  Future<void> _expand() async {
    if (_busy || !widget.repository.currentAccount()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.expand(widget.topic);
      if (mounted && widget.repository.currentAccount()) {
        setState(() => _extra = result);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load a fresh explanation. Check your sign-in, connection or daily AI allowance, then try again. The explanation above is still available.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: GlowCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (!widget.repository.currentAccount()) {
      return const Scaffold(
        body: Center(child: Text('Account changed. Reopen Curious.')),
      );
    }
    final topic = widget.topic;
    final lesson = organicLessons[topic.level - 1];
    final colors = Theme.of(context).colorScheme;
    String hex(Color color) =>
        '#${color.toARGB32().toRadixString(16).substring(2)}';
    final drawing = SpectroscopyStructureSvg.depict(
      topic.molecule,
      foreground: hex(colors.onSurface),
      background: hex(colors.surfaceContainerLow),
    );
    return OrganicStudyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Curious')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(topic.theme, style: TextStyle(color: colors.primary)),
            const SizedBox(height: 8),
            Text(
              topic.question,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _section('Start here', Text(topic.answer)),
            _section(
              'See the idea',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrganicStudyDiagram(
                    diagram: topic.id == 'curious_1' || topic.id == 'curious_32'
                        ? 'aromatic_cloud'
                        : topic.diagram,
                  ),
                  if (topic.id == 'curious_1')
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'The ring lies in a plane. The pi cloud extends above and below it. Lobes and shading describe a model of electron density, not visible surfaces around a real molecule.',
                      ),
                    ),
                ],
              ),
            ),
            _section(
              'Reference structure',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${topic.molecule.commonName} · ${topic.molecule.formula}',
                  ),
                  const SizedBox(height: 12),
                  if (drawing.svg != null)
                    Semantics(
                      image: true,
                      label: '${topic.molecule.commonName} molecular structure',
                      child: AspectRatio(
                        aspectRatio: 1.65,
                        child: SvgPicture.string(
                          drawing.svg!,
                          excludeFromSemantics: true,
                        ),
                      ),
                    )
                  else
                    const Text('This structure cannot be drawn reliably.'),
                  const SizedBox(height: 8),
                  const Text(
                    'A structural reference or comparison for this question; the teaching diagram above explains the electron pattern or reaction.',
                  ),
                ],
              ),
            ),
            _section(
              'Connect it',
              Text('${lesson.reasoning}\n\nWorked example\n${lesson.example}'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy || _extra != null ? null : _expand,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(
                _busy
                    ? 'Exploring…'
                    : _extra == null
                    ? 'Explore further · new explanation'
                    : 'Further explanation loaded',
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Optional online explanation with this structure. Uses your AI allowance. Opening a question or choosing Surprise me uses no AI requests.',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: TextStyle(color: colors.error)),
              ),
            if (_extra case final extra?) ...[
              _section(
                'Explore further',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI-assisted explanation · check important details against your course notes.',
                    ),
                    const SizedBox(height: 12),
                    Text(extra.explanation),
                    const SizedBox(height: 16),
                    for (final (i, step) in extra.steps.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('${i + 1}. $step'),
                      ),
                    Text('Common mix-up\n${extra.mistake}'),
                  ],
                ),
              ),
              _section(
                'Try explaining it',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(extra.check),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showAnswer = !_showAnswer),
                      child: Text(
                        _showAnswer ? 'Hide explanation' : 'Reveal explanation',
                      ),
                    ),
                    if (_showAnswer) Text(extra.answer),
                  ],
                ),
              ),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.school_outlined),
              label: const Text('Study the related 10-minute lesson'),
              onPressed: () async {
                await openOrganicLesson(
                  context,
                  widget.repository,
                  widget.repository.load(),
                  lesson,
                  curious: true,
                );
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
