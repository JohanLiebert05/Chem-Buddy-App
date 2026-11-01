import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../data/services/elemental_composition_service.dart';

class ElementalCompositionWorkspace extends StatefulWidget {
  const ElementalCompositionWorkspace({super.key, required this.onUseFormula});
  final ValueChanged<String> onUseFormula;
  @override
  State<ElementalCompositionWorkspace> createState() =>
      _ElementalCompositionWorkspaceState();
}

class _ElementalCompositionWorkspaceState
    extends State<ElementalCompositionWorkspace> {
  final _percent = {
    for (final element in ElementalCompositionService.atomicWeights.keys)
      element: TextEditingController(
        text: {'C': '40.00', 'H': '6.71', 'O': '53.29'}[element] ?? '',
      ),
  };
  final _mass = TextEditingController(text: '180.16');
  final _question = TextEditingController();
  double _tolerance = .20;
  bool _oxygenByDifference = false;
  ElementalCompositionResult? _result;
  String? _error;
  final _resultKey = GlobalKey();

  @override
  void dispose() {
    for (final controller in [..._percent.values, _mass, _question]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed(String _) => setState(() {
    _result = null;
    _error = null;
  });

  void _readQuestion() {
    final input = ElementalCompositionService.parseQuestion(_question.text);
    if (input.error != null) {
      setState(() {
        _error = input.error;
        _result = null;
      });
      return;
    }
    for (final e in _percent.entries) {
      e.value.text = input.percentages[e.key]?.toString() ?? '';
    }
    _mass.text = input.molarMass?.toString() ?? '';
    setState(() {
      _result = null;
      _error = null;
      _oxygenByDifference = false;
    });
  }

  void _calculate() {
    final values = <String, double>{};
    for (final e in _percent.entries) {
      if (e.value.text.trim().isEmpty) continue;
      final number = double.tryParse(e.value.text.trim());
      if (number == null) {
        setState(() {
          _error = '${e.key}: enter a numeric mass percentage.';
          _result = null;
        });
        return;
      }
      values[e.key] = number;
    }
    final massText = _mass.text.trim();
    final molarMass = massText.isEmpty ? null : double.tryParse(massText);
    if (massText.isNotEmpty && molarMass == null) {
      setState(() {
        _error = 'Enter a numeric molar mass in g/mol, or leave it blank.';
        _result = null;
      });
      return;
    }
    setState(() {
      _error = null;
      _result = ElementalCompositionService.solve(
        percentages: values,
        molarMass: molarMass,
        percentTolerance: _tolerance,
        oxygenByDifference: _oxygenByDifference,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _resultKey.currentContext == null) return;
      Scrollable.ensureVisible(
        _resultKey.currentContext!,
        alignment: .12,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
      );
    });
  }

  void _preset(String name) {
    final values = switch (name) {
      'Ethanol' => ({'C': 52.14, 'H': 13.13, 'O': 34.73}, '46.07'),
      'Benzene' => ({'C': 92.26, 'H': 7.74}, '78.11'),
      'Acetic acid' => ({'C': 40.00, 'H': 6.71, 'O': 53.29}, '60.05'),
      _ => ({'C': 40.00, 'H': 6.71, 'O': 53.29}, '180.16'),
    };
    for (final e in _percent.entries) {
      e.value.text = values.$1[e.key]?.toString() ?? '';
    }
    _mass.text = values.$2;
    _question.clear();
    _oxygenByDifference = false;
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  backgroundColor: colors.primaryContainer.withValues(
                    alpha: .4,
                  ),
                  padding: const EdgeInsets.all(22),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELEMENTAL ANALYSIS',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'From percentages to a formula.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Find the simplest atom ratio, check a molecular formula against molar mass, then continue to the spectral workbench.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '01 / Enter the composition',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final name in [
                            'Glucose',
                            'Ethanol',
                            'Benzene',
                            'Acetic acid',
                          ])
                            ActionChip(
                              label: Text(name),
                              onPressed: () => _preset(name),
                            ),
                        ],
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Paste a percentage question'),
                        subtitle: const Text(
                          'For example: 40% carbon, 6.71% hydrogen, 53.29% oxygen',
                        ),
                        children: [
                          TextField(
                            controller: _question,
                            onChanged: _changed,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Percentage question',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _readQuestion,
                              icon: const Icon(Icons.manage_search),
                              label: const Text('Read percentages'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          spacing: 12,
                          runSpacing: 14,
                          children: [
                            for (final element in ['C', 'H', 'O', 'N'])
                              SizedBox(
                                width: constraints.maxWidth < 500
                                    ? (constraints.maxWidth - 12) / 2
                                    : (constraints.maxWidth - 36) / 4,
                                child: _percentageField(element),
                              ),
                          ],
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Other elements'),
                        subtitle: const Text('S, P, F, Cl, Br, I'),
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) => Wrap(
                              spacing: 12,
                              runSpacing: 14,
                              children: [
                                for (final element in [
                                  'S',
                                  'P',
                                  'F',
                                  'Cl',
                                  'Br',
                                  'I',
                                ])
                                  SizedBox(
                                    width: (constraints.maxWidth - 12) / 2,
                                    child: _percentageField(element),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Oxygen by difference'),
                        subtitle: const Text(
                          'Use only when the question says all remaining mass is oxygen. Leave O blank.',
                        ),
                        value: _oxygenByDifference,
                        onChanged: (value) => setState(() {
                          _oxygenByDifference = value;
                          _result = null;
                          _error = null;
                        }),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _mass,
                        onChanged: _changed,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Molar mass / g mol⁻¹ (optional)',
                          helperText: 'Use molar mass, not an ion m/z. Allowed mass error ±0.50 g/mol.',
                          helperMaxLines: 3,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Allowed error per element (percentage points)',
                        style: TextStyle(fontSize: 12),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final tolerance in [.10, .20, .50])
                            ChoiceChip(
                              label: Text('±${tolerance.toStringAsFixed(2)}'),
                              selected: _tolerance == tolerance,
                              onSelected: (_) => setState(() {
                                _tolerance = tolerance;
                                _result = null;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_outlined),
                        label: const Text('Calculate formula'),
                      ),
                    ],
                  ),
                ),
                if (_error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _message(error, error: true),
                  ),
                if (_result case final result?) ...[
                  SizedBox(key: _resultKey, height: 16),
                  _message(result.message, error: !result.isValid),
                  if (result.empiricalCandidates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _results(result),
                  ],
                  if (result.molesPer100g.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _working(result),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _percentageField(String element) => TextField(
    controller: _percent[element],
    onChanged: _changed,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: '$element mass %',
      suffixText: '%',
      border: const OutlineInputBorder(),
    ),
  );

  Widget _message(String message, {bool error = false}) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      borderColor: error ? colors.error : colors.outlineVariant,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.info_outline : Icons.fact_check_outlined,
            color: error ? colors.error : colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, key: const ValueKey('composition-message')),
          ),
        ],
      ),
    );
  }

  Widget _results(ElementalCompositionResult result) {
    final empirical = result.empiricalCandidates.first;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '02 / Formula result',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text('Smallest compatible empirical ratio'),
          SelectableText(
            empirical.formula,
            key: const ValueKey('empirical-formula'),
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            'Empirical formula mass ${empirical.molarMass.toStringAsFixed(3)} g/mol',
          ),
          if (result.empiricalCandidates.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Other compatible ratios in the bounded search: ${result.empiricalCandidates.skip(1).map((c) => c.formula).join(', ')}. Rounded percentages need not specify a unique ratio.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          const Divider(height: 28),
          if (result.molecularCandidates.isEmpty)
            const Text(
              'Add or correct molar mass to determine a molecular formula. An empirical ratio alone is not sent to the structure solver as a molecule.',
            )
          else ...[
            Text(
              result.molecularCandidates.length == 1
                  ? 'Molecular formula'
                  : 'Compatible molecular formulas',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final candidate in result.molecularCandidates.take(10))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectableText(
                      candidate.formula,
                      key: ValueKey('molecular-${candidate.formula}'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Calculated mass ${candidate.molarMass.toStringAsFixed(3)} g/mol · ${candidate.dbe == null ? 'DBE model not applied to S/P' : 'DBE ${candidate.dbe!.toStringAsFixed(1)}'}',
                    ),
                    Text(
                      'Largest percentage error ${candidate.maxPercentError.toStringAsFixed(3)} points',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      onPressed: result.isValid
                          ? () => widget.onUseFormula(candidate.formula)
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        result.molecularCandidates.length == 1
                            ? 'Use formula in Structure Solver'
                            : 'Use ${candidate.formula} in Structure Solver',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'The formula does not identify an isomer. Continue with IR/NMR data to compare spectra and deduce a supported structure.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _working(ElementalCompositionResult result) {
    final candidate =
        result.molecularCandidates.firstOrNull ??
        result.empiricalCandidates.firstOrNull;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '03 / Check the working',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Assume 100 g. Divide each element’s mass by its atomic weight, then divide by the smallest mole value. Total: ${result.total.toStringAsFixed(2)}%.',
          ),
          if (result.oxygenByDifference)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Oxygen was explicitly calculated as 100% minus the supplied elements.',
              ),
            ),
          for (final entry in result.percentages.entries)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key} · ${entry.value.toStringAsFixed(3)} g in 100 g',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(3)} ÷ ${ElementalCompositionService.atomicWeights[entry.key]} = ${result.molesPer100g[entry.key]!.toStringAsFixed(5)} mol',
                      ),
                      Text(
                        'Relative mole ratio ${result.ratios[entry.key]!.toStringAsFixed(4)}',
                      ),
                      if (candidate != null)
                        Text(
                          '${candidate.formula} predicts ${candidate.percentages[entry.key]!.toStringAsFixed(3)}% (error ${(candidate.percentages[entry.key]! - entry.value).abs().toStringAsFixed(3)} points)',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
