import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/chemistry/spectroscopy_structure_svg.dart';
import '../../core/chemistry/spectrum_svg_renderer.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../data/services/spectral_peak_input.dart';
import '../../data/services/spectroscopy_reference_service.dart';
import '../../data/services/spectroscopy_service.dart';
import '../../data/services/spectroscopy_teaching_service.dart';
import '../screens/chem_sketcher_screen.dart';
import '../screens/spectroscopy_prediction_screen.dart';

class SpectroscopySolverWorkspace extends StatefulWidget {
  const SpectroscopySolverWorkspace({super.key, this.initialFormula});
  final String? initialFormula;
  @override
  State<SpectroscopySolverWorkspace> createState() =>
      _SpectroscopySolverWorkspaceState();
}

class _SpectroscopySolverWorkspaceState
    extends State<SpectroscopySolverWorkspace> {
  final _formula = TextEditingController(text: 'C8H8O');
  final _ir = TextEditingController(text: '1685, 1600, 1450, 3050');
  final _proton = TextEditingController(text: '2.60, 7.50, 7.95');
  final _carbon = TextEditingController(
    text: '26.6, 128.3, 128.6, 133.1, 137.1, 198.1',
  );
  final _mass = TextEditingController(text: '120, 105, 77');
  SpectroscopyAnalysisResult? _result;
  Map<SpectrumTechnique, List<SpectrumSignal>> _observed = {};
  SpectroscopyCompoundEntry? _selectedReference;
  SpectrumTechnique _technique = SpectrumTechnique.proton;
  bool _explore = false;
  bool _showObserved = true;
  bool _showExpected = true;
  bool _structureShown = false;
  double _frequency = 400;
  final _structureResultKey = GlobalKey();

  void _deduceStructure() {
    setState(() => _structureShown = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _structureResultKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: .12,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
      );
    });
  }

  SpectroscopyCompoundEntry? get _reference =>
      _explore ? _selectedReference : _result?.supportedCompound;

  @override
  void initState() {
    super.initState();
    if (widget.initialFormula case final imported?) {
      _formula.text = imported;
      for (final controller in [_ir, _proton, _carbon, _mass]) {
        controller.clear();
      }
    }
    _analyze();
  }

  @override
  void dispose() {
    for (final controller in [_formula, _ir, _proton, _carbon, _mass]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _editing(String _) => setState(() {
    _result = null;
    _observed = {};
    _structureShown = false;
  });

  void _analyze() {
    final fields = [
      SpectralPeakInput.parse(_proton.text, '¹H NMR'),
      SpectralPeakInput.parse(_carbon.text, '¹³C NMR'),
      SpectralPeakInput.parse(_ir.text, 'FT-IR'),
      SpectralPeakInput.parse(_mass.text, 'MS'),
    ];
    final errors = fields.map((f) => f.error).whereType<String>().toList();
    setState(() {
      _structureShown = false;
      if (errors.isNotEmpty) {
        _observed = {};
        _result = SpectroscopyAnalysisResult(
          isValid: false,
          errorMessage: errors.join('\n'),
          formula: _formula.text,
          dbe: 0,
          molarMass: 0,
          steps: const [],
          markdownFull: '',
        );
        return;
      }
      _result = SpectroscopyService.analyzeSpectraStructured(
        formula: _formula.text,
        nmr1HPeaks: fields[0].values,
        nmr13CPeaks: fields[1].values,
        irPeaks: fields[2].values,
        msPeaks: fields[3].values,
      );
      _observed = {
        for (var i = 0; i < SpectrumTechnique.values.length; i++)
          SpectrumTechnique.values[i]: [
            for (final value in fields[i].values)
              SpectrumSignal(position: value),
          ],
      };
    });
  }

  void _preset(SpectroscopyCaseStudy study) {
    _formula.text = study.formula;
    _ir.text = SpectralPeakInput.fromAnnotated(
      study.irHighlights,
      'IR',
    ).join(', ');
    _proton.text = SpectralPeakInput.fromAnnotated(
      study.nmr1H.replaceAll(RegExp(r'\s+[–-]\s+'), '–'),
      'NMR',
    ).join(', ');
    _carbon.text = SpectralPeakInput.fromAnnotated(
      study.nmr13C,
      'NMR',
    ).join(', ');
    _mass.text = SpectralPeakInput.fromAnnotated(
      study.massSpec,
      'MS',
    ).join(', ');
    _explore = false;
    _selectedReference = null;
    _analyze();
  }

  void _selectCompound(SpectroscopyCompoundEntry compound) {
    setState(() {
      _explore = true;
      _selectedReference = compound;
      _formula.text = compound.formula
          .replaceAll('BR', 'Br')
          .replaceAll('CL', 'Cl');
      for (final controller in [_ir, _proton, _carbon, _mass]) {
        controller.clear();
      }
      _observed = {};
      _structureShown = false;
      _result = SpectroscopyService.analyzeSpectraStructured(
        formula: _formula.text,
      );
    });
  }

  void _mode(bool explore) {
    if (_explore == explore) return;
    setState(() {
      _explore = explore;
      _selectedReference = null;
      _result = null;
      _observed = {};
      _structureShown = false;
    });
  }

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2)}';

  String _spectrumSvg(bool compact) {
    final colors = Theme.of(context).colorScheme;
    return SpectrumSvgRenderer.render(
      technique: _technique,
      compact: compact,
      observed: _observed[_technique] ?? [],
      expected: _reference == null
          ? []
          : SpectroscopyReferenceService.signals(_reference!, _technique),
      showObserved: _showObserved,
      showExpected: _showExpected,
      frequencyMhz: _frequency,
      foreground: _hex(colors.onSurface),
      background: _hex(colors.surfaceContainerLowest),
      gridColor: _hex(colors.outlineVariant),
      observedColor: _hex(colors.primary),
      expectedColor: _hex(colors.tertiary),
    );
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildWorkspace(context, compact: constraints.maxWidth < 680),
    );
  }

  Widget _buildWorkspace(BuildContext context, {required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  backgroundColor: colors.primaryContainer.withValues(
                    alpha: .45,
                  ),
                  padding: const EdgeInsets.all(22),
                  borderRadius: 26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.graphic_eq_rounded, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SPECTRAL WORKBENCH',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'From signals to structure.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connect the formula, compare the spectra, then build a structural hypothesis.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Interpret peaks'),
                            selected: !_explore,
                            onSelected: (_) => _mode(false),
                            avatar: const Icon(
                              Icons.analytics_outlined,
                              size: 17,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Explore a compound'),
                            selected: _explore,
                            onSelected: (_) => _mode(true),
                            avatar: const Icon(
                              Icons.science_outlined,
                              size: 17,
                            ),
                          ),
                          ActionChip(
                            label: const Text('Predict with Gemini'),
                            avatar: const Icon(Icons.auto_awesome, size: 17),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const SpectroscopyPredictionScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (widget.initialFormula != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Formula imported from elemental analysis. Add IR/NMR peaks to deduce a structure; no sample spectra have been prefilled.',
                      style: TextStyle(color: colors.primary),
                    ),
                  ),
                if (_explore) _compoundPicker() else _inputs(),
                const SizedBox(height: 18),
                if (_result case final result?) ...[
                  if (!result.isValid)
                    _errorCard(
                      result.errorMessage ?? 'Check the entered values.',
                    )
                  else ...[
                    _summary(result),
                    const SizedBox(height: 18),
                    _spectrumCard(compact),
                    const SizedBox(height: 18),
                    if (_reference != null)
                      _expectedValues()
                    else
                      _referenceOptions(),
                    const SizedBox(height: 18),
                    _interpretation(result),
                    const SizedBox(height: 18),
                    _deduction(result),
                  ],
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _explore
                          ? 'Choose a compound to view its expected spectra and molecular structure.'
                          : 'Your inputs changed. Analyze spectra to update the plots and deduction.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heading(String number, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number / $title',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _inputs() => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          '01',
          'Enter the evidence',
          'Peak positions only, separated by commas. Leave techniques blank when unavailable.',
        ),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: [
            for (final study in SpectroscopyService.caseStudies)
              ActionChip(
                label: Text(
                  study.compoundName.contains('Benzocaine')
                      ? 'Benzocaine'
                      : study.compoundName.split(' (').first,
                  style: const TextStyle(fontSize: 11),
                ),
                onPressed: () => _preset(study),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _field(
          'Molecular Formula (e.g. C8H8O, C9H11NO2)',
          _formula,
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final h = _field(
              '¹H NMR Shifts in ppm (e.g. 2.60, 7.50, 7.95)',
              _proton,
              lines: 2,
            );
            final c = _field(
              '¹³C NMR Shifts in ppm (e.g. 26.6, 128.3, 198.1)',
              _carbon,
              lines: 2,
            );
            if (constraints.maxWidth < 720) {
              return Column(children: [h, const SizedBox(height: 14), c]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: h),
                const SizedBox(width: 14),
                Expanded(child: c),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _field('FT-IR Peaks in cm⁻¹ (e.g. 1685, 1600, 1450)', _ir),
        const SizedBox(height: 14),
        _field('Mass Spec m/z Peaks (e.g. 120, 105, 77)', _mass),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.auto_graph_rounded),
              label: const Text('Analyze spectra'),
            ),
            TextButton.icon(
              onPressed: () {
                for (final controller in [
                  _formula,
                  _ir,
                  _proton,
                  _carbon,
                  _mass,
                ]) {
                  controller.clear();
                }
                _editing('');
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Clear inputs'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    int lines = 1,
    IconData? icon,
  }) => TextField(
    controller: controller,
    onChanged: _editing,
    maxLines: lines,
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: lines > 1,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );

  Widget _compoundPicker() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          '01',
          'Choose a known compound',
          'View library NMR values and SVG spectra by name or formula. This previews a reference; it does not identify an unknown from its formula alone.',
        ),
        Autocomplete<SpectroscopyCompoundEntry>(
          displayStringForOption: (c) => c.commonName,
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            return SpectroscopyService.curatedCompoundDatabase.where(
              (c) =>
                  query.isEmpty ||
                  '${c.commonName} ${c.iupacName} ${c.formula}'
                      .toLowerCase()
                      .contains(query),
            );
          },
          onSelected: _selectCompound,
          fieldViewBuilder: (context, controller, focus, onSubmitted) =>
              TextField(
                controller: controller,
                focusNode: focus,
                onChanged: (_) => setState(() {
                  _selectedReference = null;
                  _result = null;
                  _structureShown = false;
                }),
                decoration: const InputDecoration(
                  labelText: 'Compound name or formula',
                  hintText: 'Try acetophenone, ethanol or C8H8O',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
        ),
        if (_selectedReference case final selected?)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              '${selected.commonName} · ${selected.formula.replaceAll('BR', 'Br').replaceAll('CL', 'Cl')}',
            ),
          ),
      ],
    ),
  );

  Widget _errorCard(String message) => AppCard(
    borderColor: Theme.of(context).colorScheme.error,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check Spectral Input',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(message),
      ],
    ),
  );

  Widget _summary(SpectroscopyAnalysisResult result) {
    final colors = Theme.of(context).colorScheme;
    final conflicting = result.sanityReport?.hasViolations ?? false;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(result.formula)),
              Chip(label: Text('DBE ${result.dbe.toStringAsFixed(1)}')),
              Chip(label: Text('${result.molarMass} g/mol')),
              Chip(
                label: Text(
                  _explore
                      ? 'Reference preview'
                      : conflicting
                      ? 'Conflicting evidence'
                      : _reference != null
                      ? 'Tentative match'
                      : 'More evidence needed',
                ),
                backgroundColor: conflicting
                    ? colors.errorContainer
                    : colors.secondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _reference?.commonName ??
                'A formula can describe several structures.',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _explore
                ? 'Expected values belong to the selected library compound.'
                : _reference != null
                ? 'The entered shifts support this reference. Confirm integration, splitting and connectivity before identifying the sample.'
                : 'Use the DBE and individual assignments below to narrow the possibilities. Exact reference NMR is available after a supported match or an explicit compound selection.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _spectrumCard(bool compact) {
    final svg = _spectrumSvg(compact);
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
            '02',
            'Compare the spectra',
            'Entered positions and expected reference signals share an SVG plot. NMR and IR axes run from high to low.',
          ),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              for (final technique in SpectrumTechnique.values)
                ChoiceChip(
                  label: Text(technique.label),
                  selected: _technique == technique,
                  onSelected: (_) => setState(() => _technique = technique),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Entered peaks'),
                avatar: Icon(Icons.show_chart, color: colors.primary, size: 16),
                selected: _showObserved,
                onSelected: (value) => setState(() => _showObserved = value),
              ),
              FilterChip(
                label: const Text('Expected reference'),
                avatar: Icon(
                  Icons.more_horiz,
                  color: colors.tertiary,
                  size: 16,
                ),
                selected: _showExpected,
                onSelected: (value) => setState(() => _showExpected = value),
              ),
              if (_technique == SpectrumTechnique.proton)
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<double>(
                    isExpanded: true,
                    initialValue: _frequency,
                    decoration: const InputDecoration(
                      labelText: '¹H frequency',
                      isDense: true,
                    ),
                    items: [
                      for (final frequency in [
                        300.0,
                        400.0,
                        500.0,
                        600.0,
                        800.0,
                      ])
                        DropdownMenuItem(
                          value: frequency,
                          child: Text('${frequency.toInt()} MHz'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _frequency = value);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Semantics(
              label:
                  '${_technique.label} SVG spectrum. Numerical values are in the assignments below.',
              child: AspectRatio(
                aspectRatio: (compact ? 600 : 800) / 340,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 6,
                  child: SvgPicture.string(
                    svg,
                    key: const ValueKey('solver-spectrum-svg'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _technique == SpectrumTechnique.proton
                ? 'First-order illustration at ${_frequency.toInt()} MHz. Splitting is drawn only when reference J values are available. Entered peaks have no supplied intensities or splitting.'
                : 'Peak positions are shown; line shapes and unspecified intensities are illustrative. This is not an experimental spectrum.',
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (_reference == null)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'No compound is assigned yet, so no expected trace is invented.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _copy(svg, 'Spectrum SVG copied'),
                icon: const Icon(Icons.copy_outlined, size: 17),
                label: const Text('Copy spectrum SVG'),
              ),
              TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => Dialog(
                    insetPadding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 1000,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Close spectrum',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                          AspectRatio(
                            aspectRatio: (compact ? 600 : 800) / 340,
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 6,
                              child: SvgPicture.string(svg),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Pinch to zoom · drag to inspect'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.open_in_full, size: 17),
                label: const Text('Expand spectrum'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _expectedValues() {
    final compound = _reference!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
            '03',
            'Expected NMR values',
            '${compound.commonName}. Reference shifts are approximate and vary with solvent, temperature and concentration.',
          ),
          for (final technique in [
            SpectrumTechnique.proton,
            SpectrumTechnique.carbon,
          ])
            ExpansionTile(
              key: PageStorageKey(
                'nmr-${compound.commonName}-${technique.name}',
              ),
              initiallyExpanded: technique == SpectrumTechnique.proton,
              tilePadding: EdgeInsets.zero,
              title: Text('${technique.label} assignments'),
              subtitle: Text(
                '${SpectroscopyReferenceService.signals(compound, technique).length} reference environments',
              ),
              children: [_assignmentTable(compound, technique)],
            ),
        ],
      ),
    );
  }

  Widget _assignmentTable(
    SpectroscopyCompoundEntry compound,
    SpectrumTechnique technique,
  ) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 680
        ? _mobileAssignments(compound, technique)
        : _desktopAssignmentTable(compound, technique),
  );

  Widget _mobileAssignments(
    SpectroscopyCompoundEntry compound,
    SpectrumTechnique technique,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Expected reference values. Nearby input positions are comparisons, not confirmed assignments.',
            style: TextStyle(fontSize: 11),
          ),
        ),
        for (final signal in SpectroscopyReferenceService.signals(
          compound,
          technique,
        ))
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'δ ${signal.position.toStringAsFixed(technique == SpectrumTechnique.proton ? 2 : 1)} ppm',
                      style: TextStyle(
                        color: colors.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ((_observed[technique] ?? []).any(
                      (s) =>
                          (s.position - signal.position).abs() <=
                          (technique == SpectrumTechnique.proton ? .3 : 3),
                    ))
                      Text(
                        'Nearby input: ${(_observed[technique]!.where((s) => (s.position - signal.position).abs() <= (technique == SpectrumTechnique.proton ? .3 : 3)).map((s) => s.position.toStringAsFixed(2))).join(', ')}',
                        style: TextStyle(color: colors.primary, fontSize: 12),
                      ),
                  ],
                ),
                if (technique == SpectrumTechnique.proton)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      [
                        if (signal.integration != null)
                          '${signal.integration}H',
                        if (signal.multiplicity.isNotEmpty) signal.multiplicity,
                        if (signal.couplingsHz.isNotEmpty)
                          'J ${signal.couplingsHz.join(', ')} Hz',
                      ].join(' · '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                Text(
                  signal.assignment.contains(':')
                      ? signal.assignment.split(':').skip(1).join(':').trim()
                      : signal.assignment,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _desktopAssignmentTable(
    SpectroscopyCompoundEntry compound,
    SpectrumTechnique technique,
  ) {
    final signals = SpectroscopyReferenceService.signals(compound, technique);
    final entered = _observed[technique] ?? <SpectrumSignal>[];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 18,
        horizontalMargin: 4,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 96,
        columns: [
          const DataColumn(label: Text('Expected δ')),
          const DataColumn(label: Text('Nearby entered δ')),
          if (technique == SpectrumTechnique.proton) ...[
            const DataColumn(label: Text('H')),
            const DataColumn(label: Text('Splitting')),
            const DataColumn(label: Text('J / Hz')),
          ],
          const DataColumn(label: Text('Reference assignment')),
        ],
        rows: [
          for (final signal in signals)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    signal.position.toStringAsFixed(
                      technique == SpectrumTechnique.proton ? 2 : 1,
                    ),
                  ),
                ),
                DataCell(
                  Text(() {
                    final matching =
                        entered
                            .where(
                              (s) =>
                                  (s.position - signal.position).abs() <=
                                  (technique == SpectrumTechnique.proton
                                      ? .30
                                      : 3),
                            )
                            .toList()
                          ..sort(
                            (a, b) =>
                                (a.position - signal.position).abs().compareTo(
                                  (b.position - signal.position).abs(),
                                ),
                          );
                    return matching.isEmpty
                        ? '—'
                        : matching.first.position.toStringAsFixed(
                            technique == SpectrumTechnique.proton ? 2 : 1,
                          );
                  }()),
                ),
                if (technique == SpectrumTechnique.proton) ...[
                  DataCell(Text(signal.integration?.toString() ?? '—')),
                  DataCell(
                    Text(
                      signal.multiplicity.isEmpty ? '—' : signal.multiplicity,
                    ),
                  ),
                  DataCell(
                    Text(
                      signal.couplingsHz.isEmpty
                          ? '—'
                          : signal.couplingsHz.join(', '),
                    ),
                  ),
                ],
                DataCell(
                  SizedBox(
                    width: 310,
                    child: Text(
                      signal.assignment
                              .split(':')
                              .skip(1)
                              .join(':')
                              .trim()
                              .isEmpty
                          ? signal.assignment
                          : signal.assignment
                                .split(':')
                                .skip(1)
                                .join(':')
                                .trim(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _referenceOptions() {
    final options = SpectroscopyReferenceService.formulaOptions(_formula.text);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            '03',
            'NMR assignments & possible references',
            'Read the observed-shift assignments in the deduction below. A molecular formula alone cannot supply unique NMR values.',
          ),
          if (options.isEmpty)
            const Text(
              'No formula-matched reference is in this library. Add more evidence to the interpretation, or explore a known compound by name.',
            )
          else ...[
            const Text(
              'These entries share the formula; they are not identified matches. Select one only to explore its reference spectra.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final compound in options)
                  ActionChip(
                    label: Text('Preview ${compound.commonName}'),
                    onPressed: () => _selectCompound(compound),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _interpretation(SpectroscopyAnalysisResult result) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      children: [
        if (!_explore)
          if (result.sanityReport case final sanity?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sanity.passedCount} sanity checks passed · ${sanity.warningCount} cautions · ${sanity.violationCount} conflicts',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (final item in sanity.items.where((item) => !item.passed))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${item.title}: ${item.message}',
                        style: TextStyle(
                          fontSize: 12,
                          color: item.severity == SanitySeverity.violation
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Step-by-step: formula to structure'),
          subtitle: Text(
            _explore
                ? 'Worked reference example · plain language + MSc checkpoints'
                : 'Explain every conclusion · plain language + MSc checkpoints',
          ),
          initiallyExpanded: true,
          children: [
            for (final lesson in SpectroscopyTeachingService.explain(
              result: result,
              observed: _observed,
              reference: _reference,
              workedReference: _explore,
            ).indexed)
              ExpansionTile(
                key: ValueKey('deduction-lesson-${lesson.$1}'),
                title: Text(
                  '${lesson.$1 + 1}. ${lesson.$2.title}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChemistryMarkdownView(text: lesson.$2.explanation),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MSc checkpoint',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(lesson.$2.mscCheckpoint),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ExpansionTile(
              title: const Text('Detailed peak-by-peak report'),
              children: [
                for (final step in result.steps)
                  ExpansionTile(
                    title: Text(
                      '${step.stepNumber}. ${step.title}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ChemistryMarkdownView(text: step.content),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _deduction(SpectroscopyAnalysisResult result) {
    final colors = Theme.of(context).colorScheme;
    final reference = _reference;
    final depiction = _structureShown && reference != null
        ? SpectroscopyStructureSvg.depict(
            reference,
            foreground: _hex(colors.onSurface),
            background: _hex(colors.surfaceContainerLowest),
          )
        : null;
    return AppCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: colors.secondaryContainer.withValues(alpha: .3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
            '04',
            'Deduce into Structure',
            _explore
                ? 'Reveal the selected reference compound’s molecular drawing.'
                : 'Bring DBE, IR, proton and carbon evidence together in one structural hypothesis.',
          ),
          FilledButton.icon(
            key: const ValueKey('deduce-structure-button'),
            onPressed: _deduceStructure,
            icon: const Icon(Icons.hub_outlined),
            label: const Text('Deduce into Structure'),
          ),
          if (_structureShown) ...[
            SizedBox(key: _structureResultKey, height: 18),
            if (reference == null) ...[
              Text(
                result.sanityReport?.hasViolations == true
                    ? 'Resolve the conflicting evidence first.'
                    : 'More evidence is needed to draw a specific structure.',
                key: const ValueKey('structure-needs-evidence'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'DBE constrains rings and multiple bonds, but does not determine connectivity. Add diagnostic NMR peaks or compare explicitly selected reference compounds.',
              ),
            ] else ...[
              Text(
                _explore
                    ? 'Selected reference structure'
                    : 'Tentative structure from the supplied evidence',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Text(
                reference.commonName,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                reference.iupacName,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (depiction?.svg case final svg?) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 600 / 290,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: SvgPicture.string(
                        svg,
                        key: const ValueKey('deduced-structure-svg'),
                        semanticsLabel:
                            'Molecular structure of ${reference.commonName}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Formula checked · ${result.formula} · DBE ${result.dbe.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  reference.structure,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'SMILES: ${reference.smiles}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copy(svg, 'Structure SVG copied'),
                      icon: const Icon(Icons.copy, size: 17),
                      label: const Text('Copy structure SVG'),
                    ),
                    TextButton.icon(
                      onPressed: () => _copy(reference.smiles, 'SMILES copied'),
                      icon: const Icon(Icons.content_copy, size: 17),
                      label: const Text('Copy SMILES'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChemSketcherScreen(
                            initialSmiles: reference.smiles,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.draw_outlined, size: 17),
                      label: const Text('Open in sketcher'),
                    ),
                  ],
                ),
              ] else
                Text(depiction?.error ?? 'The drawing is unavailable.'),
              if (!_explore) ...[
                const Divider(height: 26),
                const Text(
                  'Why this candidate?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Formula and DBE agree with ${reference.commonName}.\n• The supplied NMR shifts fit the reference comparison tolerances.\n• ${_result!.candidateMatches.isEmpty ? 'Review the individual evidence above.' : _result!.candidateMatches.first.evidence.join(' · ')}',
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a tentative library-supported structure. Confirm integration, multiplicities and 2D correlations to distinguish unlisted or closely related isomers.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
