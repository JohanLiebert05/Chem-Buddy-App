import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/chemistry/spectrum_svg_renderer.dart';
import '../../core/widgets/app_card.dart';
import '../../data/services/spectroscopy_prediction_service.dart';

class SpectroscopyPredictionScreen extends StatefulWidget {
  const SpectroscopyPredictionScreen({super.key, this.service});
  final SpectroscopyPredictionService? service;
  @override
  State<SpectroscopyPredictionScreen> createState() =>
      _SpectroscopyPredictionScreenState();
}

class _SpectroscopyPredictionScreenState
    extends State<SpectroscopyPredictionScreen> {
  final _compound = TextEditingController(),
      _solvent = TextEditingController(text: 'CDCl3'),
      _temperature = TextEditingController(text: '298'),
      _frequency = TextEditingController(text: '400');
  CompoundInputKind _kind = CompoundInputKind.name;
  SpectroscopyPrediction? _result;
  String? _error;
  bool _busy = false, _proton = true;
  int _generation = 0;

  @override
  void dispose() {
    _generation++;
    for (final c in [_compound, _solvent, _temperature, _frequency]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed(String _) => setState(() {
    _result = null;
    _error = null;
  });

  Future<void> _predict() async {
    final generation = ++_generation;
    final request = SpectroscopyPredictionRequest(
      compound: _compound.text,
      kind: _kind,
      solvent: _solvent.text,
      temperatureKelvin: double.tryParse(_temperature.text) ?? double.nan,
      frequencyMhz: double.tryParse(_frequency.text) ?? double.nan,
    );
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await (widget.service ?? SpectroscopyPredictionService())
          .predict(request);
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        _busy = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _busy = false;
        _error = error is FormatException
            ? error.message
            : error is StateError
            ? error.message.toString()
            : 'Cloud prediction could not finish. Check your connection and retry.';
      });
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('drawing copied')));
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    String? hint,
  }) => TextField(
    controller: controller,
    enabled: !_busy,
    onChanged: _changed,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    minLines: 1,
    maxLines: numeric ? 1 : 3,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Predict NMR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compound → predicted spectra',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter a specific organic compound name or SMILES. AI proposes ¹H / ¹³C NMR data; the app checks consistency and draws spectra and a molecular structure.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Predictions are estimates, not experimental spectra. Solvent, temperature, stereochemistry and sample conditions can change the result.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final kind in CompoundInputKind.values)
                              ChoiceChip(
                                label: Text(
                                  kind == CompoundInputKind.name
                                      ? 'Compound name'
                                      : 'SMILES',
                                ),
                                selected: _kind == kind,
                                onSelected: _busy
                                    ? null
                                    : (_) => setState(() {
                                        _kind = kind;
                                        _result = null;
                                        _error = null;
                                      }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _compound,
                          _kind == CompoundInputKind.name
                              ? 'Specific compound name'
                              : 'SMILES',
                          hint: _kind == CompoundInputKind.name
                              ? 'e.g. ethyl acetate'
                              : 'e.g. CCOC(=O)C',
                        ),
                        const SizedBox(height: 12),
                        _field(_solvent, 'Solvent'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                _temperature,
                                'Temperature / K',
                                numeric: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                _frequency,
                                '¹H frequency / MHz',
                                numeric: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.icon(
                              key: const ValueKey('predict-gemini'),
                              onPressed: _busy ? null : _predict,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(
                                _busy
                                    ? 'Predicting and checking…'
                                    : 'Predict NMR, spectrum & structure',
                              ),
                            ),
                            if (_busy)
                              TextButton(
                                onPressed: () => setState(() {
                                  _generation++;
                                  _busy = false;
                                }),
                                child: const Text('Cancel'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uses the app’s existing AI cloud connection. Sign-in and internet are required. A failed consistency check may trigger one correction attempt.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      backgroundColor: colors.errorContainer,
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          key: const ValueKey('prediction-error'),
                        ),
                      ),
                    ),
                  ],
                  if (_result case final result?) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.compound.commonName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${result.compound.formula} • DBE ${result.compound.dbe.toStringAsFixed(1)} • AI-assisted estimate',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.request.kind == CompoundInputKind.name
                                ? 'Identity proposed by AI from the name. Verify the name-to-structure match below before using these estimates.'
                                : 'The returned SMILES matches your input. Formula, valence and assignment inventories passed local checks.',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Checks establish internal consistency, not experimental accuracy. Shift ranges are heuristic estimates, not statistical confidence intervals.',
                          ),
                          Text(
                            '${result.request.solvent} • ${result.request.temperatureKelvin} K • ${result.request.frequencyMhz} MHz (¹H)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _spectrum(result),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Structure of the predicted compound',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          AspectRatio(
                            aspectRatio: 600 / 290,
                            child: SvgPicture.string(result.depiction.svg!),
                          ),
                          SelectableText(result.compound.smiles),
                          const Text(
                            'Constitutional connectivity only. This view does not establish stereochemistry.',
                          ),
                          TextButton.icon(
                            onPressed: () => _copy(result.depiction.svg!),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy structure'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How the prediction was assembled',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1. Formula ${result.compound.formula} gives DBE ${result.compound.dbe.toStringAsFixed(1)}. The drawn structure and all assigned atom inventories agree with that formula.',
                          ),
                          for (final entry in result.explanation.indexed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('${entry.$1 + 2}. ${entry.$2}'),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Uncertainty and verification',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          for (final warning in result.uncertainties)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('• $warning'),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Confirm with measured NMR and suitable reference data; use HSQC/HMBC/COSY where assignments are ambiguous. Molecular formula alone cannot specify one structure.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spectrum(SpectroscopyPrediction result) => LayoutBuilder(
    builder: (context, constraints) {
      final signals = _proton ? result.proton : result.carbon;
      final technique = _proton
          ? SpectrumTechnique.proton
          : SpectrumTechnique.carbon;
      final svg = SpectrumSvgRenderer.render(
        technique: technique,
        expected: signals.map((s) => s.signal).toList(),
        showObserved: false,
        compact: constraints.maxWidth < 680,
        frequencyMhz: result.request.frequencyMhz,
      );
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-predicted NMR',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('¹H NMR'),
                  selected: _proton,
                  onSelected: (_) => setState(() => _proton = true),
                ),
                ChoiceChip(
                  label: const Text('¹³C NMR'),
                  selected: !_proton,
                  onSelected: (_) => setState(() => _proton = false),
                ),
              ],
            ),
            const Text(
              'Schematic trace from predicted centres. Splitting uses estimated J only where supplied; unresolved multiplets are shown as single envelopes. ¹³C intensities do not measure carbon counts.',
            ),
            AspectRatio(
              aspectRatio: (constraints.maxWidth < 680 ? 600 : 800) / 340,
              child: SvgPicture.string(svg),
            ),
            TextButton.icon(
              onPressed: () => _copy(svg),
              icon: const Icon(Icons.copy),
              label: const Text('Copy predicted spectrum'),
            ),
            for (final value in signals)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'δ ${value.signal.position.toStringAsFixed(2)} ppm  (${value.minimum.toStringAsFixed(2)}–${value.maximum.toStringAsFixed(2)})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(value.signal.assignment),
                    Text(
                      _proton
                          ? '${value.signal.integration} H • ${value.signal.multiplicity}${value.signal.couplingsHz.isEmpty ? '' : ' • estimated J ${value.signal.couplingsHz.join(', ')} Hz'}'
                          : '${value.atoms.length} carbon atom(s) in this environment',
                    ),
                    Text(
                      'SMILES atom indices: ${value.atoms.join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
