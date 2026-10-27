import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/expressive_motion.dart';
import '../../core/widgets/liquid_glass.dart';
import '../providers/app_providers.dart';

class BeginnerTutorialDialog extends ConsumerStatefulWidget {
  const BeginnerTutorialDialog({super.key, this.onFinished});
  final VoidCallback? onFinished;
  static Future<void> show(BuildContext context, {VoidCallback? onFinished}) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BeginnerTutorialDialog(onFinished: onFinished),
      );
  @override
  ConsumerState<BeginnerTutorialDialog> createState() =>
      _BeginnerTutorialDialogState();
}

class _BeginnerTutorialDialogState
    extends ConsumerState<BeginnerTutorialDialog> {
  final _controller = PageController();
  int _step = 0;
  bool _finishing = false;
  static const _slides = [
    _TourSlide(
      'Welcome to ChemBuddy',
      'A quick map of your study space. Take the tour now, or replay it later from Profile.',
      Icons.science_outlined,
      [
        (
          'Keep your week together',
          'Classes, attendance, deadlines and course notes have a home here.',
        ),
        (
          'Start at your own pace',
          'Guest mode keeps local study data on this device. Sign in when you need cloud AI.',
        ),
      ],
    ),
    _TourSlide(
      'Draw your ideas.',
      'Open ChemDraw Canvas when a structure is easier to show than describe.',
      Icons.draw_outlined,
      [
        (
          'Build a structure',
          'Use ring templates, bonds and functional groups, then adjust your sketch.',
        ),
        (
          'Connect the next step',
          'Explore the available reaction and structure tools. Check chemical assumptions as you work.',
        ),
      ],
    ),
    _TourSlide(
      'Ask with context.',
      'Ask ChemBuddy can help explain a topic or work with the notes you attach.',
      Icons.auto_awesome_outlined,
      [
        (
          'Choose the kind of answer',
          'Switch between short explanations, exam answers and deeper study modes.',
        ),
        (
          'Know what needs a connection',
          'Cloud AI requires a signed-in account and internet. Review generated answers against your course material.',
        ),
      ],
    ),
    _TourSlide(
      'Turn notes into practice.',
      'Keep PDFs organised, then move from reading to recall.',
      Icons.auto_stories_outlined,
      [
        (
          'Keep the source close',
          'Add course PDFs to your library and return to them while revising.',
        ),
        (
          'Practise deliberately',
          'Use available flashcard and quiz tools. Review the source when a generated question is unclear.',
        ),
      ],
    ),
    _TourSlide(
      'Keep attendance in view.',
      'Record what happened, then use the percentage and safe-skip estimate as a guide.',
      Icons.fact_check_outlined,
      [
        (
          'Mark classes carefully',
          'Keep present, absent, postponed and excused entries distinct.',
        ),
        (
          'Check your university rules',
          'Attendance estimates depend on your records and cutoff settings; your institution makes the final decision.',
        ),
      ],
    ),
    _TourSlide(
      'Explore one workspace at a time.',
      'The chemistry hubs now start with a clear overview instead of a wall of controls.',
      Icons.dashboard_customize_outlined,
      [
        (
          'Find the right tool',
          'Search the toolkit by calculator or concept, then choose a workspace.',
        ),
        (
          'See the chemistry',
          'Use the spectroscopy hub and pericyclic studio to connect signals, structures and orbital ideas.',
        ),
      ],
    ),
    _TourSlide(
      'Make it your space.',
      'Your look is now part of Profile. Change it whenever you want.',
      Icons.palette_outlined,
      [
        (
          'Choose your colours',
          'Pick Classic, Fan or three-colour Prism gradients, then tune light/dark mode and the glass finish.',
        ),
        (
          'Leave room for curiosity',
          'A few small chemistry discoveries are tucked away in the app. Your Curiosity cabinet keeps them together.',
        ),
      ],
    ),
  ];
  void _move(int index) {
    if (_finishing) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    if (_finishing) {
      return;
    }
    setState(() => _finishing = true);
    try {
      await ref.read(appControllerProvider.notifier).setTutorialCompleted(true);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onFinished?.call();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save tour progress. Please try again.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: LiquidGlassContainer(
          borderRadius: 32,
          blurSigma: 16,
          backgroundColor: colors.surfaceContainerLow,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 12, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'QUICK TOUR',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.onSurfaceVariant,
                              letterSpacing: 1.5,
                            ),
                      ),
                    ),

                    SpringPress(
                      child: TextButton(
                        onPressed: _finishing ? null : _finish,
                        child: const Text('Skip'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: (_step + 1) / _slides.length),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        builder: (context, value, child) =>
                            LinearProgressIndicator(
                              value: value,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(4),
                              color: colors.primary,
                              backgroundColor: colors.surfaceContainerHighest,
                              semanticsLabel: 'Walkthrough progress',
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_step + 1} / ${_slides.length}',
                      key: const Key('tour-step'),
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _step = index),
                  children: [
                    for (final slide in _slides) _TourSlideView(slide: slide),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      SpringPress(
                        child: OutlinedButton(
                          onPressed: _finishing ? null : () => _move(_step - 1),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: SpringPress(
                        child: FilledButton.icon(
                          onPressed: _finishing
                              ? null
                              : () => _step == _slides.length - 1
                                    ? _finish()
                                    : _move(_step + 1),
                          icon: Icon(
                            _step == _slides.length - 1
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                          label: Text(
                            _finishing
                                ? 'Saving…'
                                : _step == _slides.length - 1
                                ? "Let's go"
                                : 'Next',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourSlide {
  const _TourSlide(this.title, this.summary, this.icon, this.details);
  final String title;
  final String summary;
  final IconData icon;
  final List<(String, String)> details;
}

class _TourSlideView extends StatelessWidget {
  const _TourSlideView({required this.slide});
  final _TourSlide slide;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Icon(slide.icon, color: colors.onPrimaryContainer, size: 34),
          ),
          const SizedBox(height: 22),
          Text(
            slide.title,
            style: text.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.summary,
            style: text.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          for (final detail in slide.details)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.$1,
                      style: text.titleSmall?.copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      detail.$2,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
