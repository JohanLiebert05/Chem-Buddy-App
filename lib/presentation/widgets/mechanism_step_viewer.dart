import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/reaction_models.dart';

/// Step-through ChemDraw-style SVG viewer. Zoom/pan stay vector-sharp.
class MechanismStepViewer extends StatefulWidget {
  const MechanismStepViewer({super.key, required this.mechanism});

  final ReactionMechanism mechanism;

  @override
  State<MechanismStepViewer> createState() => _MechanismStepViewerState();
}

class _MechanismStepViewerState extends State<MechanismStepViewer> {
  final TransformationController _transform = TransformationController();
  int _stepIndex = 0;
  bool _showElectronFlow = true;
  bool _playing = false;
  Timer? _playTimer;
  String? _svg;
  String? _loadError;

  List<ReactionStep> get _steps =>
      widget.mechanism.steps.where((s) => s.svgAsset != null && s.svgAsset!.isNotEmpty).toList();

  ReactionStep get _current => _steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _transform.dispose();
    super.dispose();
  }

  Future<void> _loadSvg() async {
    setState(() {
      _svg = null;
      _loadError = null;
    });
    try {
      var raw = await rootBundle.loadString(_current.svgAsset!);
      if (!_showElectronFlow) {
        raw = raw.replaceFirst(
          'id="electron-arrows"',
          'id="electron-arrows" display="none"',
        );
      }
      if (mounted) setState(() => _svg = raw);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  void _goTo(int index) {
    AppHaptics.selection();
    setState(() => _stepIndex = index.clamp(0, _steps.length - 1));
    _loadSvg();
  }

  void _play() {
    if (_steps.isEmpty) return;
    AppHaptics.confirm();
    _playTimer?.cancel();
    setState(() {
      _playing = true;
      _stepIndex = 0;
    });
    _loadSvg();
    _playTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_stepIndex >= _steps.length - 1) {
        t.cancel();
        setState(() => _playing = false);
        return;
      }
      setState(() => _stepIndex++);
      _loadSvg();
    });
  }

  void _replay() {
    _playTimer?.cancel();
    setState(() {
      _playing = false;
      _stepIndex = 0;
    });
    _transform.value = Matrix4.identity();
    _loadSvg();
    _play();
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.mechanism.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
        ),
        if (widget.mechanism.representativeExample != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.mechanism.representativeExample!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 820 / 360,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 0.6,
              maxScale: 8,
              panEnabled: true,
              child: _svg == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _loadError == null
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : Text(_loadError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    )
                  : SvgPicture.string(
                      _svg!,
                      fit: BoxFit.contain,
                      allowDrawingOutsideViewBox: true,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _current.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          _current.description,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _CtrlButton(
              label: 'Previous',
              icon: Icons.chevron_left,
              onPressed: _stepIndex == 0 ? null : () => _goTo(_stepIndex - 1),
            ),
            Expanded(
              child: Text(
                'Step ${_stepIndex + 1} of ${_steps.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
              ),
            ),
            _CtrlButton(
              label: 'Next',
              icon: Icons.chevron_right,
              trailing: true,
              onPressed: _stepIndex >= _steps.length - 1 ? null : () => _goTo(_stepIndex + 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _playing ? null : _play,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(_playing ? 'Playing…' : 'Play Mechanism'),
            ),
            OutlinedButton.icon(
              onPressed: _replay,
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Replay'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _showElectronFlow = !_showElectronFlow);
                _loadSvg();
              },
              icon: Icon(_showElectronFlow ? Icons.visibility : Icons.visibility_off, size: 18),
              label: Text(_showElectronFlow ? 'Hide Electron Flow' : 'Show Electron Flow'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                AppHaptics.selection();
                _transform.value = Matrix4.identity();
              },
              icon: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('Reset view'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.trailing = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13));
    return TextButton.icon(
      onPressed: onPressed,
      icon: trailing ? child : Icon(icon),
      label: trailing ? Icon(icon) : child,
    );
  }
}
