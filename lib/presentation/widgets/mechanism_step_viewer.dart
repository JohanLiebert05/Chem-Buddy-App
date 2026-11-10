import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/haptics.dart';
import '../../core/widgets/expressive_motion.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../data/models/reaction_models.dart';
import 'electron_flow_diagram.dart';

/// Step-through viewer for the bundled representative reaction mechanisms.
class MechanismStepViewer extends StatefulWidget {
  const MechanismStepViewer({
    super.key,
    required this.mechanism,
    this.onSwitchTo3D,
    this.initialStepIndex = 0,
    this.lessonSteps,
    this.scopeLabel,
  });

  final ReactionMechanism mechanism;
  final VoidCallback? onSwitchTo3D;
  final int initialStepIndex;
  final List<ReactionStep>? lessonSteps;
  final String? scopeLabel;

  @override
  State<MechanismStepViewer> createState() => _MechanismStepViewerState();
}

class _MechanismStepViewerState extends State<MechanismStepViewer> {
  final _transform = TransformationController();
  late List<ReactionStep> _steps;
  late Future<List<String?>> _diagrams;
  int _step = 0;
  int _replay = 0;
  bool _showFlow = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MechanismStepViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mechanism.id != widget.mechanism.id) {
      _timer?.cancel();
      _timer = null;
      _step = 0;
      _transform.value = Matrix4.identity();
      _load();
    }
  }

  void _load() {
    _steps = widget.lessonSteps ?? widget.mechanism.steps;
    _step = widget.initialStepIndex.clamp(
      0,
      _steps.isEmpty ? 0 : _steps.length - 1,
    );
    _diagrams = Future.wait(
      _steps.map((step) async {
        if (step.svgContent case final svg? when svg.isNotEmpty) return svg;
        if (step.svgAsset == null) return null;
        try {
          return await rootBundle.loadString(step.svgAsset!);
        } on FlutterError {
          return null;
        }
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transform.dispose();
    super.dispose();
  }

  void _select(int index) {
    AppHaptics.selection();
    _timer?.cancel();
    _transform.value = Matrix4.identity();
    setState(() {
      _timer = null;
      _step = index;
    });
  }

  void _play() {
    if (_timer != null) {
      _select(_step);
      return;
    }
    AppHaptics.confirm();
    _transform.value = Matrix4.identity();
    setState(() {
      if (_step == _steps.length - 1) _step = 0;
      _replay++;
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_step == _steps.length - 1) {
          _timer?.cancel();
          setState(() => _timer = null);
          return;
        }
        _transform.value = Matrix4.identity();
        setState(() => _step++);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) return const SizedBox.shrink();
    final current = _steps[_step];
    final hasDiagram = current.svgContent != null || current.svgAsset != null;
    final canTrace =
        current.svgAsset != null ||
        (current.svgContent?.contains('id="electron-arrows"') ?? false);
    final theme = Theme.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 280);
    return LiquidGlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.mechanism.name, style: theme.textTheme.titleLarge),
          if (widget.scopeLabel case final scopeLabel?)
            Text(scopeLabel, style: theme.textTheme.labelMedium),
          if (widget.mechanism.representativeExample case final example?) ...[
            const SizedBox(height: 6),
            Text(example, style: theme.textTheme.bodyMedium),
          ],
          if (current.svgContent?.contains('Electron source') ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Reaction-center map',
                style: theme.textTheme.labelMedium,
              ),
            ),
          const SizedBox(height: 14),
          if (hasDiagram)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 820 / 360,
                child: ColoredBox(
                  color: Colors.white,
                  child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 8,
                    child: FutureBuilder<List<String?>>(
                      future: _diagrams,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final svg = snapshot.data![_step];
                        if (svg == null) {
                          return const Center(
                            child: Text(
                              'Diagram unavailable',
                              style: TextStyle(color: Colors.black87),
                            ),
                          );
                        }
                        return AnimatedSwitcher(
                          duration: duration,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: ElectronFlowDiagram(
                            key: ValueKey((_step, _replay)),
                            svg: svg,
                            label: current.title,
                            showFlow: _showFlow,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Step ${_step + 1} of ${_steps.length}',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: duration,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topLeft,
                children: [...previousChildren, ?currentChild],
              ),
              child: Column(
                key: ValueKey(_step),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(current.description),
                  if (_showFlow)
                    for (final (index, flow) in current.electronFlow.indexed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: ElectronFlowDiagram.arrowColor(index),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${flow.source} → ${flow.destination}',
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SpringPress(
                child: IconButton.filledTonal(
                  tooltip: 'Previous step',
                  onPressed: _step > 0 ? () => _select(_step - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
              ),
              SpringPress(
                child: FilledButton.icon(
                  onPressed: _play,
                  icon: Icon(
                    _timer == null
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(_timer == null ? 'Play steps' : 'Pause'),
                ),
              ),
              SpringPress(
                child: IconButton.filledTonal(
                  tooltip: 'Next step',
                  onPressed: _step + 1 < _steps.length
                      ? () => _select(_step + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
              if (canTrace)
                FilterChip(
                  label: const Text('Electron flow'),
                  selected: _showFlow,
                  onSelected: (value) => setState(() => _showFlow = value),
                ),
              if (_showFlow && canTrace)
                IconButton(
                  tooltip: 'Replay electron flow',
                  onPressed: () => setState(() => _replay++),
                  icon: const Icon(Icons.replay),
                ),
              IconButton(
                tooltip: 'Reset zoom',
                onPressed: () => _transform.value = Matrix4.identity(),
                icon: const Icon(Icons.center_focus_strong),
              ),
              if (widget.onSwitchTo3D != null)
                TextButton.icon(
                  onPressed: widget.onSwitchTo3D,
                  icon: const Icon(Icons.view_in_ar_rounded),
                  label: const Text('Explore in 3D'),
                ),
            ],
          ),
          if (_showFlow && canTrace)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Full head: electron pair · fishhook: one electron. Arrows in a concerted step move together.',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
