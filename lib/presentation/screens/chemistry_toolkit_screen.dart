import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/chemical_name_database.dart';

class ChemistryToolkitScreen extends StatefulWidget {
  const ChemistryToolkitScreen({super.key, this.initialCategory = 0});
  final int initialCategory;

  @override
  State<ChemistryToolkitScreen> createState() => _ChemistryToolkitScreenState();
}

class _ChemistryToolkitScreenState extends State<ChemistryToolkitScreen> {
  late int _selectedCategory;

  final _categories = [
    'Solutions',
    'Stoichiometry & Units',
    'Inorganic & CFT',
    'Acid-Base',
    'Thermo & Kinetics',
    'Quantum Chemistry',
    'Spectroscopy & AAS',
    'Electrochem',
    'Analytical & Error',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory.clamp(0, _categories.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('MSc Chemistry Toolkit ⚗️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final title = entry.value;
                  final isSel = _selectedCategory == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(title, style: TextStyle(color: isSel ? Colors.white : AppColors.textSecondary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      selected: isSel,
                      selectedColor: AppColors.brandPrimary,
                      backgroundColor: AppColors.bg2,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedCategory = idx);
                          AppHaptics.selection();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedCategory == 0) ...[
              _MolarMassCalculator(
                onSelectTool: (tool) {
                  if (tool == 'Molarity' || tool == 'Normality' || tool == 'Dilution') {
                    setState(() => _selectedCategory = 0);
                  }
                },
              ),
              const SizedBox(height: 16),
              const _MolarityCalculator(),
              const SizedBox(height: 16),
              const _DilutionCalculator(),
            ] else if (_selectedCategory == 1) ...[
              const _StoichiometryCalculator(),
              const SizedBox(height: 16),
              const _UnitConversionCalculator(),
            ] else if (_selectedCategory == 2) ...[
              const _CrystalFieldCalculator(),
            ] else if (_selectedCategory == 3) ...[
              const _PhCalculator(),
              const SizedBox(height: 16),
              const _HendersonHasselbalchCalculator(),
            ] else if (_selectedCategory == 4) ...[
              const _GibbsFreeEnergyCalculator(),
              const SizedBox(height: 16),
              const _ArrheniusCalculator(),
              const SizedBox(height: 16),
              const _IntegratedRateLawCalculator(),
            ] else if (_selectedCategory == 5) ...[
              const _QuantumChemistryCalculator(),
            ] else if (_selectedCategory == 6) ...[
              const _BeerLambertCalculator(),
              const SizedBox(height: 16),
              const _PhotonEnergyCalculator(),
            ] else if (_selectedCategory == 7) ...[
              const _NernstCalculator(),
              const SizedBox(height: 16),
              const _CellPotentialCalculator(),
            ] else if (_selectedCategory == 8) ...[
              const _AnalyticalErrorCalculator(),
              const SizedBox(height: 16),
              const _VanDeemterCalculator(),
              const SizedBox(height: 16),
              const _HplcCalibrationCurveCalculator(),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. MOLAR MASS CALCULATOR
// ==========================================
class _MolarMassCalculator extends StatefulWidget {
  const _MolarMassCalculator({this.onSelectTool});
  final ValueChanged<String>? onSelectTool;

  @override
  State<_MolarMassCalculator> createState() => _MolarMassCalculatorState();
}

class _MolarMassCalculatorState extends State<_MolarMassCalculator> {
  final _controller = TextEditingController(text: 'benzoic acid');
  ChemicalParseResult? _parsedResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculate() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _parsedResult = null;
        _error = 'Please enter a chemical formula or chemical name';
      });
      return;
    }

    try {
      final res = ChemicalNameDatabase.resolve(query);
      setState(() {
        _parsedResult = res;
        _error = null;
      });
      AppHaptics.confirm();
    } catch (e) {
      setState(() {
        _parsedResult = null;
        _error = e is FormatException
            ? e.message
            : 'Could not parse chemical input. Try e.g. "benzoic acid", "C6H6", "CuSO4·5H2O", or "sodium chloride".';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: AppColors.purpleBright, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Molar Mass Calculator',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter formula or chemical name (e.g. benzoic acid, ethanol, CuSO4·5H2O, C6H6, sodium chloride):',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter formula or chemical name',
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_parsedResult != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_parsedResult!.compoundName != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _parsedResult!.compoundName!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _parsedResult!.isPolymerOrBiomolecule
                                ? AppColors.accentCyan.withValues(alpha: 0.2)
                                : AppColors.purple.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _parsedResult!.isPolymerOrBiomolecule
                                ? (_parsedResult!.polymerCategory ?? 'Biopolymer / Polymer')
                                : 'Verified Compound',
                            style: TextStyle(
                              color: _parsedResult!.isPolymerOrBiomolecule ? AppColors.accentCyan : AppColors.purpleBright,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_parsedResult!.iupacName != null && _parsedResult!.iupacName != _parsedResult!.compoundName) ...[
                      const SizedBox(height: 2),
                      Text(
                        'IUPAC: ${_parsedResult!.iupacName}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                    const Divider(color: AppColors.borderSubtle, height: 16),
                  ],

                  if (_parsedResult!.isPolymerOrBiomolecule) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ℹ️', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No single molecular formula — ${_parsedResult!.compoundName ?? "this compound"} is a macromolecule/polymer with variable chain length (degree of polymerization n).',
                              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _parsedResult!.isPolymerOrBiomolecule ? 'Repeating Unit Formula:' : 'Molecular Formula:',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _parsedResult!.formattedFormula,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.purpleBright,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _parsedResult!.isPolymerOrBiomolecule ? 'Repeat Unit Mass:' : 'Molar Mass:',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_parsedResult!.molarMass.toStringAsFixed(2)} g/mol',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                          if (_parsedResult!.isPolymerOrBiomolecule)
                            const Text('(per repeat unit n)', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),

                  if (_parsedResult!.typicalMolecularWeightRange != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Typical Average MW Range: ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        Text(_parsedResult!.typicalMolecularWeightRange!, style: const TextStyle(fontSize: 11.5, color: AppColors.accentGold, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],

                  if (_parsedResult!.polymerExplanation != null) ...[
                    const SizedBox(height: 10),
                    ChemistryMarkdownView(
                      text: _parsedResult!.polymerExplanation!,
                      textStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                      selectable: false,
                    ),
                  ],

                  if (_parsedResult!.elementBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Elemental Composition:',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _parsedResult!.elementBreakdown.entries.map((entry) {
                        final pct = _parsedResult!.elementPercentages[entry.key] ?? 0.0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            '${entry.key} × ${entry.value} (${pct.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Related Tool Suggestions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Related Tools:',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w700),
                      ),
                      if (_parsedResult!.isPolymerOrBiomolecule)
                        const Text(
                          '(Uses repeat unit mass)',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.purpleBright),
                        label: const Text('Molarity Calculator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.surfaceElevated,
                        onPressed: () => widget.onSelectTool?.call('Molarity'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.science_outlined, size: 14, color: AppColors.purpleBright),
                        label: const Text('Normality Calculator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.surfaceElevated,
                        onPressed: () => widget.onSelectTool?.call('Normality'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.opacity, size: 14, color: AppColors.purpleBright),
                        label: const Text('Dilution Calculator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.surfaceElevated,
                        onPressed: () => widget.onSelectTool?.call('Dilution'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 2. MOLARITY & NORMALITY CALCULATOR
// ==========================================
class _MolarityCalculator extends StatefulWidget {
  const _MolarityCalculator();

  @override
  State<_MolarityCalculator> createState() => _MolarityCalculatorState();
}

class _MolarityCalculatorState extends State<_MolarityCalculator> {
  final _mass = TextEditingController(text: '4.0');
  final _molarMass = TextEditingController(text: '40.0'); // NaOH
  final _volume = TextEditingController(text: '500'); // mL
  final _nFactor = TextEditingController(text: '1');

  double? _molarity = 0.2;
  double? _normality = 0.2;
  String? _error;

  @override
  void dispose() {
    _mass.dispose();
    _molarMass.dispose();
    _volume.dispose();
    _nFactor.dispose();
    super.dispose();
  }

  void _calculate() {
    final m = double.tryParse(_mass.text.trim());
    final mm = double.tryParse(_molarMass.text.trim());
    final vMl = double.tryParse(_volume.text.trim());
    final nf = double.tryParse(_nFactor.text.trim()) ?? 1.0;

    if (m == null || m < 0) {
      setState(() {
        _error = 'Please enter a valid non-negative mass (g).';
        _molarity = null;
        _normality = null;
      });
      AppHaptics.error();
      return;
    }
    if (mm == null || mm <= 0) {
      setState(() {
        _error = 'Molar mass must be strictly greater than 0 g/mol.';
        _molarity = null;
        _normality = null;
      });
      AppHaptics.error();
      return;
    }
    if (vMl == null || vMl <= 0) {
      setState(() {
        _error = 'Volume must be strictly positive (> 0 mL).';
        _molarity = null;
        _normality = null;
      });
      AppHaptics.error();
      return;
    }
    if (nf <= 0) {
      setState(() {
        _error = 'n-Factor must be strictly greater than 0.';
        _molarity = null;
        _normality = null;
      });
      AppHaptics.error();
      return;
    }

    final vL = vMl / 1000.0;
    final moles = m / mm;
    final molarity = moles / vL;
    final normality = molarity * nf;

    setState(() {
      _molarity = molarity;
      _normality = normality;
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(r'Molarity & Normality (M = n/V)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _mass, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Mass (g)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _molarMass, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Molar Mass (g/mol)'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _volume, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Volume (mL)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _nFactor, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'n-Factor (Acidity/Basicity)'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Compute M & N')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_molarity != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('MOLARITY (M)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text('${_molarity!.toStringAsFixed(4)} M', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.purpleBright)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('NORMALITY (N)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      Text('${_normality!.toStringAsFixed(4)} N', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 3. DILUTION CALCULATOR
// ==========================================
class _DilutionCalculator extends StatefulWidget {
  const _DilutionCalculator();

  @override
  State<_DilutionCalculator> createState() => _DilutionCalculatorState();
}

class _DilutionCalculatorState extends State<_DilutionCalculator> {
  final _c1 = TextEditingController(text: '12.0'); // e.g. conc HCl
  final _v1 = TextEditingController(text: '10.0');
  final _v2 = TextEditingController(text: '100.0');
  double? _c2 = 1.2;
  String? _error;

  @override
  void dispose() {
    _c1.dispose();
    _v1.dispose();
    _v2.dispose();
    super.dispose();
  }

  void _calculate() {
    final c1 = double.tryParse(_c1.text.trim());
    final v1 = double.tryParse(_v1.text.trim());
    final v2 = double.tryParse(_v2.text.trim());

    if (c1 == null || c1 < 0) {
      setState(() {
        _error = 'Initial concentration C₁ must be non-negative.';
        _c2 = null;
      });
      AppHaptics.error();
      return;
    }
    if (v1 == null || v1 <= 0) {
      setState(() {
        _error = 'Initial volume V₁ must be strictly positive (> 0 mL).';
        _c2 = null;
      });
      AppHaptics.error();
      return;
    }
    if (v2 == null || v2 <= 0) {
      setState(() {
        _error = 'Final volume V₂ must be strictly positive (> 0 mL).';
        _c2 = null;
      });
      AppHaptics.error();
      return;
    }

    setState(() {
      _c2 = (c1 * v1) / v2;
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(r'Dilution Law (C1·V1 = C2·V2)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _c1, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Initial C1 (M)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _v1, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Initial V1 (mL)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _v2, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Final V2 (mL)'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate Final Conc C2')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_c2 != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Text('Final Concentration C2 = ${_c2!.toStringAsFixed(4)} M', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success)),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 4. pH & pOH CALCULATOR
// ==========================================
class _PhCalculator extends StatefulWidget {
  const _PhCalculator();

  @override
  State<_PhCalculator> createState() => _PhCalculatorState();
}

class _PhCalculatorState extends State<_PhCalculator> {
  final _hConc = TextEditingController(text: '0.001');
  double? _ph = 3.0;
  double? _poh = 11.0;
  String? _error;

  @override
  void dispose() {
    _hConc.dispose();
    super.dispose();
  }

  void _calculate() {
    final h = double.tryParse(_hConc.text.trim());
    if (h == null || h <= 0) {
      setState(() {
        _error = '[H⁺] ion concentration must be strictly positive (> 0 mol/L).';
        _ph = null;
        _poh = null;
      });
      AppHaptics.error();
      return;
    }
    final ph = -log(h) / ln10;
    final poh = 14.0 - ph;
    setState(() {
      _ph = ph;
      _poh = poh;
      _error = null;
    });
    AppHaptics.confirm();
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('pH & pOH Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$\text{pH} = -\log[\text{H}^+], \quad \text{pOH} = 14 - \text{pH}$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hConc,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '[H+] Ion Concentration (mol/L)'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate pH')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_ph != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('pH: ${_ph!.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ph! < 7 ? AppColors.danger : (_ph! > 7 ? AppColors.blue : AppColors.success))),
                  Text('pOH: ${_poh!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 5. HENDERSON-HASSELBALCH BUFFER & FORMULATION ASSISTANT
// ==========================================
class _BufferPreset {
  final String name;
  final double pKa;
  final String acidName;
  final double acidMw;
  final bool acidIsLiquid;
  final double? acidDensity; // g/mL
  final String baseName;
  final double baseMw;
  final String notes;

  const _BufferPreset({
    required this.name,
    required this.pKa,
    required this.acidName,
    required this.acidMw,
    this.acidIsLiquid = false,
    this.acidDensity,
    required this.baseName,
    required this.baseMw,
    required this.notes,
  });
}

class _HendersonHasselbalchCalculator extends StatefulWidget {
  const _HendersonHasselbalchCalculator();

  @override
  State<_HendersonHasselbalchCalculator> createState() => _HendersonHasselbalchCalculatorState();
}

class _HendersonHasselbalchCalculatorState extends State<_HendersonHasselbalchCalculator> {
  // Mode: 0 = Buffer pH & Ratio, 1 = Lab Formulation Assistant
  int _activeMode = 0;

  // Controllers for Mode 0 (pH from concentrations)
  final _pKa = TextEditingController(text: '4.76'); // Acetic acid
  final _salt = TextEditingController(text: '0.1'); // [A-]
  final _acid = TextEditingController(text: '0.1'); // [HA]
  double? _ph = 4.76;
  double? _ratio = 1.0;
  double? _alphaBase = 0.5;
  double? _alphaAcid = 0.5;
  double? _bufferCapacity = 0.115;
  String? _error;

  // Presets for Mode 1 (Formulation from target pH)
  static const List<_BufferPreset> _presets = [
    _BufferPreset(
      name: 'Acetic Acid / Sodium Acetate',
      pKa: 4.76,
      acidName: 'Glacial Acetic Acid (CH₃COOH)',
      acidMw: 60.05,
      acidIsLiquid: true,
      acidDensity: 1.05,
      baseName: 'Sodium Acetate Trihydrate (CH₃COONa·3H₂O)',
      baseMw: 136.08,
      notes: 'Optimal range pH 3.76–5.76. Common in DNA extraction & enzymatic assays.',
    ),
    _BufferPreset(
      name: 'Sodium Phosphate (NaH₂PO₄ / Na₂HPO₄)',
      pKa: 7.20,
      acidName: 'Sodium Dihydrogen Phosphate Monohydrate (NaH₂PO₄·H₂O)',
      acidMw: 137.99,
      baseName: 'Disodium Hydrogen Phosphate (Na₂HPO₄)',
      baseMw: 141.96,
      notes: 'Optimal range pH 6.20–8.20. Primary physiological buffer for biochemical research.',
    ),
    _BufferPreset(
      name: 'Tris / Tris-HCl',
      pKa: 8.06,
      acidName: 'Tris Hydrochloride (Tris-HCl, C₄H₁₁NO₃·HCl)',
      acidMw: 157.60,
      baseName: 'Tris Base (C₄H₁₁NO₃)',
      baseMw: 121.14,
      notes: 'Optimal range pH 7.10–9.10. Standard buffer in biochemistry and electrophoresis.',
    ),
    _BufferPreset(
      name: 'Ammonium Chloride / Ammonia',
      pKa: 9.25,
      acidName: 'Ammonium Chloride (NH₄Cl)',
      acidMw: 53.49,
      baseName: 'Ammonia Solution (NH₃, 25% w/w)',
      baseMw: 17.03,
      notes: 'Optimal range pH 8.25–10.25. Classic analytical buffer for EDTA titrations.',
    ),
    _BufferPreset(
      name: 'Citric Acid / Sodium Citrate',
      pKa: 4.76,
      acidName: 'Citric Acid Monohydrate (C₆H₈O₇·H₂O)',
      acidMw: 210.14,
      baseName: 'Trisodium Citrate Dihydrate (Na₃C₆H₅O₇·2H₂O)',
      baseMw: 294.10,
      notes: 'Optimal range pH 3.0–6.2. Widely utilized in antigen retrieval and food biochemistry.',
    ),
  ];

  int _selectedPresetIdx = 0;
  final _formTargetPhCtrl = TextEditingController(text: '4.76');
  final _formConcCtrl = TextEditingController(text: '0.1'); // M
  final _formVolCtrl = TextEditingController(text: '500'); // mL
  final _customPkaCtrl = TextEditingController(text: '4.76');
  final _customAcidMwCtrl = TextEditingController(text: '60.05');
  final _customBaseMwCtrl = TextEditingController(text: '136.08');

  // Formulation result state
  Map<String, dynamic>? _formulationResult;
  String? _formError;

  @override
  void dispose() {
    _pKa.dispose();
    _salt.dispose();
    _acid.dispose();
    _formTargetPhCtrl.dispose();
    _formConcCtrl.dispose();
    _formVolCtrl.dispose();
    _customPkaCtrl.dispose();
    _customAcidMwCtrl.dispose();
    _customBaseMwCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final pka = double.tryParse(_pKa.text.trim());
    final a = double.tryParse(_salt.text.trim());
    final ha = double.tryParse(_acid.text.trim());

    if (pka == null) {
      setState(() {
        _error = 'Please enter a valid pKa value.';
        _ph = null;
      });
      AppHaptics.error();
      return;
    }
    if (a == null || a <= 0) {
      setState(() {
        _error = 'Conjugate base concentration [A⁻] must be strictly positive (> 0).';
        _ph = null;
      });
      AppHaptics.error();
      return;
    }
    if (ha == null || ha <= 0) {
      setState(() {
        _error = 'Weak acid concentration [HA] must be strictly positive (> 0).';
        _ph = null;
      });
      AppHaptics.error();
      return;
    }

    final ratio = a / ha;
    final ph = pka + (log(ratio) / ln10);
    final alphaA = a / (a + ha);
    final alphaHa = ha / (a + ha);
    final totalC = a + ha;
    final beta = 2.303 * totalC * alphaA * alphaHa;

    setState(() {
      _ph = ph;
      _ratio = ratio;
      _alphaBase = alphaA;
      _alphaAcid = alphaHa;
      _bufferCapacity = beta;
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _calculateFormulation() {
    final targetPh = double.tryParse(_formTargetPhCtrl.text.trim());
    final conc = double.tryParse(_formConcCtrl.text.trim());
    final volMl = double.tryParse(_formVolCtrl.text.trim());

    if (targetPh == null || targetPh < 0 || targetPh > 14) {
      setState(() {
        _formError = 'Please enter a valid target pH between 0 and 14.';
        _formulationResult = null;
      });
      AppHaptics.error();
      return;
    }
    if (conc == null || conc <= 0) {
      setState(() {
        _formError = 'Total buffer concentration must be strictly positive (> 0 M).';
        _formulationResult = null;
      });
      AppHaptics.error();
      return;
    }
    if (volMl == null || volMl <= 0) {
      setState(() {
        _formError = 'Desired volume must be strictly positive (> 0 mL).';
        _formulationResult = null;
      });
      AppHaptics.error();
      return;
    }

    final isCustom = _selectedPresetIdx >= _presets.length;
    final double pKa = isCustom
        ? (double.tryParse(_customPkaCtrl.text.trim()) ?? 4.76)
        : _presets[_selectedPresetIdx].pKa;
    final double acidMw = isCustom
        ? (double.tryParse(_customAcidMwCtrl.text.trim()) ?? 60.05)
        : _presets[_selectedPresetIdx].acidMw;
    final double baseMw = isCustom
        ? (double.tryParse(_customBaseMwCtrl.text.trim()) ?? 136.08)
        : _presets[_selectedPresetIdx].baseMw;
    final bool acidIsLiquid = isCustom ? false : _presets[_selectedPresetIdx].acidIsLiquid;
    final double? acidDensity = isCustom ? null : _presets[_selectedPresetIdx].acidDensity;
    final String acidName = isCustom ? 'Weak Acid (HA)' : _presets[_selectedPresetIdx].acidName;
    final String baseName = isCustom ? 'Conjugate Base (A⁻)' : _presets[_selectedPresetIdx].baseName;

    final ratio = pow(10.0, targetPh - pKa).toDouble();
    final alphaBase = ratio / (1.0 + ratio);
    final alphaAcid = 1.0 / (1.0 + ratio);

    final concBase = conc * alphaBase;
    final concAcid = conc * alphaAcid;

    final volL = volMl / 1000.0;
    final molesBase = concBase * volL;
    final molesAcid = concAcid * volL;

    final massBaseG = molesBase * baseMw;
    final massAcidG = molesAcid * acidMw;
    final double? volAcidMl = (acidIsLiquid && acidDensity != null && acidDensity > 0)
        ? (massAcidG / acidDensity)
        : null;

    final beta = 2.303 * conc * alphaAcid * alphaBase;
    final deltaPka = (targetPh - pKa).abs();
    final isOptimal = deltaPka <= 1.0;

    setState(() {
      _formulationResult = {
        'targetPh': targetPh,
        'pKa': pKa,
        'conc': conc,
        'volMl': volMl,
        'acidName': acidName,
        'baseName': baseName,
        'massBaseG': massBaseG,
        'massAcidG': massAcidG,
        'volAcidMl': volAcidMl,
        'ratio': ratio,
        'alphaBase': alphaBase,
        'alphaAcid': alphaAcid,
        'concBase': concBase,
        'concAcid': concAcid,
        'beta': beta,
        'isOptimal': isOptimal,
      };
      _formError = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, color: AppColors.purpleBright, size: 20),
                  SizedBox(width: 8),
                  Text('Henderson-Hasselbalch Buffer Assistant', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Acid-Base', style: TextStyle(color: AppColors.purpleBright, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Mode Toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('pH & Molar Ratio', style: TextStyle(fontSize: 12)),
                  selected: _activeMode == 0,
                  selectedColor: AppColors.purple.withValues(alpha: 0.35),
                  backgroundColor: AppColors.bg0,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _activeMode = 0);
                      AppHaptics.selection();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Formulation Recipe (g)', style: TextStyle(fontSize: 12)),
                  selected: _activeMode == 1,
                  selectedColor: AppColors.purple.withValues(alpha: 0.35),
                  backgroundColor: AppColors.bg0,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _activeMode = 1;
                        if (_formulationResult == null) _calculateFormulation();
                      });
                      AppHaptics.selection();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activeMode == 0) ...[
            const ChemistryMarkdownView(
              text: r'$$\text{pH} = \text{p}K_a + \log\frac{[\text{A}^-]}{[\text{HA}]}, \quad \beta = 2.303 \, C_{\text{total}} \, \alpha_{\text{HA}} \, \alpha_{\text{A}^-}$$',
              textStyle: TextStyle(fontSize: 12, color: AppColors.purpleBright),
              selectable: false,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _pKa, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'pKa'), onChanged: (_) => _onFieldChanged())),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _salt, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '[Conjugate Base]'), onChanged: (_) => _onFieldChanged())),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _acid, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '[Weak Acid]'), onChanged: (_) => _onFieldChanged())),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _calculate, child: const Text('Compute Buffer pH')),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            if (_ph != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Buffer pH = ${_ph!.toStringAsFixed(3)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.purpleBright)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (_ph! >= 6.5 && _ph! <= 7.5 ? AppColors.success : AppColors.brandPrimary).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_ph! < 7.0 ? 'Acidic Buffer' : (_ph! > 7.0 ? 'Basic Buffer' : 'Neutral Buffer'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Molar Ratio [A⁻]/[HA]:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('${_ratio?.toStringAsFixed(3)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fractions (α_base / α_acid):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('${((_alphaBase ?? 0) * 100).toStringAsFixed(1)}% / ${((_alphaAcid ?? 0) * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 12.5)),
                      ],
                    ),
                    if (_bufferCapacity != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Buffer Capacity (β):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('${_bufferCapacity!.toStringAsFixed(4)} mol/(L·pH)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold, fontSize: 12.5)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ] else ...[
            // Mode 1: Formulation Assistant
            const Text(
              'Select Standard Buffer System:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedPresetIdx,
                  isExpanded: true,
                  dropdownColor: AppColors.bg1,
                  items: [
                    ..._presets.asMap().entries.map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value.name, style: const TextStyle(fontSize: 13, color: Colors.white)),
                    )),
                    const DropdownMenuItem(
                      value: 999,
                      child: Text('Custom Acid-Base Conjugate Pair', style: TextStyle(fontSize: 13, color: AppColors.accentCyan)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPresetIdx = val;
                        if (val < _presets.length) {
                          _formTargetPhCtrl.text = _presets[val].pKa.toStringAsFixed(2);
                        }
                      });
                      _calculateFormulation();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_selectedPresetIdx >= _presets.length) ...[
              Row(
                children: [
                  Expanded(child: TextField(controller: _customPkaCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Custom pKa'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _customAcidMwCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Acid MW (g/mol)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _customBaseMwCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Base MW (g/mol)'))),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(child: TextField(controller: _formTargetPhCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target pH'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _formConcCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Total Conc (M)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _formVolCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Volume (mL)'))),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _calculateFormulation,
              icon: const Icon(Icons.calculate_outlined, size: 16),
              label: const Text('Calculate Formulation Recipe'),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(_formError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            if (_formulationResult != null) ...[
              const SizedBox(height: 12),
              _buildFormulationReportCard(_formulationResult!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFormulationReportCard(Map<String, dynamic> r) {
    final bool isOptimal = r['isOptimal'] as bool;
    final double targetPh = r['targetPh'] as double;
    final double massBaseG = r['massBaseG'] as double;
    final double massAcidG = r['massAcidG'] as double;
    final double? volAcidMl = r['volAcidMl'] as double?;
    final double volMl = r['volMl'] as double;
    final String baseName = r['baseName'] as String;
    final String acidName = r['acidName'] as String;
    final double beta = r['beta'] as double;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOptimal ? AppColors.success.withValues(alpha: 0.5) : AppColors.accentGold.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOptimal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: isOptimal ? AppColors.success : AppColors.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Formulation for pH ${targetPh.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: (isOptimal ? AppColors.success : AppColors.accentGold).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOptimal ? 'Optimal Range (pKa ± 1)' : 'Sub-optimal Range',
                  style: TextStyle(
                    color: isOptimal ? AppColors.success : AppColors.accentGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Masses to weigh
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('1. Weigh $baseName:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    Text('${massBaseG.toStringAsFixed(3)} g', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 13)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        volAcidMl != null ? '2. Pipette $acidName:' : '2. Weigh $acidName:',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    Text(
                      volAcidMl != null
                          ? '${volAcidMl.toStringAsFixed(2)} mL (${massAcidG.toStringAsFixed(3)} g)'
                          : '${massAcidG.toStringAsFixed(3)} g',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandBright, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Buffer Capacity (β):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('${beta.toStringAsFixed(4)} mol/(L·pH)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Laboratory Protocol 🧪:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text(
            '1. Dissolve ${massBaseG.toStringAsFixed(3)} g of $baseName and ${volAcidMl != null ? "${volAcidMl.toStringAsFixed(2)} mL" : "${massAcidG.toStringAsFixed(3)} g"} of $acidName in ${(volMl * 0.8).round()} mL of deionized water.\n'
            '2. Stir thoroughly until completely dissolved.\n'
            '3. Calibrate pH meter and verify pH = ${targetPh.toStringAsFixed(2)} (adjust dropwise with 1M HCl or 1M NaOH if needed).\n'
            '4. Quantitatively dilute with deionized water to final volume of ${volMl.round()} mL in a volumetric flask.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. GIBBS FREE ENERGY
// ==========================================
class _GibbsFreeEnergyCalculator extends StatefulWidget {
  const _GibbsFreeEnergyCalculator();

  @override
  State<_GibbsFreeEnergyCalculator> createState() => _GibbsFreeEnergyCalculatorState();
}

class _GibbsFreeEnergyCalculatorState extends State<_GibbsFreeEnergyCalculator> {
  final _deltaH = TextEditingController(text: '-890.0'); // kJ/mol
  final _temp = TextEditingController(text: '298.15'); // K
  final _deltaS = TextEditingController(text: '-242.0'); // J/mol·K
  double? _deltaG = -817.85;
  String? _error;

  @override
  void dispose() {
    _deltaH.dispose();
    _temp.dispose();
    _deltaS.dispose();
    super.dispose();
  }

  void _calculate() {
    final dh = double.tryParse(_deltaH.text.trim());
    final t = double.tryParse(_temp.text.trim());
    final ds = double.tryParse(_deltaS.text.trim());

    if (dh == null) {
      setState(() {
        _error = 'Please enter a valid ΔH value (kJ/mol).';
        _deltaG = null;
      });
      AppHaptics.error();
      return;
    }
    if (t == null || t < 0) {
      setState(() {
        _error = 'Absolute temperature T must be non-negative (≥ 0 K).';
        _deltaG = null;
      });
      AppHaptics.error();
      return;
    }
    if (ds == null) {
      setState(() {
        _error = 'Please enter a valid ΔS value (J/mol·K).';
        _deltaG = null;
      });
      AppHaptics.error();
      return;
    }

    final dg = dh - (t * (ds / 1000.0));
    setState(() {
      _deltaG = dg;
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gibbs Free Energy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$\Delta G = \Delta H - T\Delta S$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _deltaH, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'ΔH (kJ/mol)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _temp, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Temp T (K)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _deltaS, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'ΔS (J/mol·K)'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate ΔG')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_deltaG != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ΔG = ${_deltaG!.toStringAsFixed(2)} kJ/mol', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _deltaG! < 0 ? AppColors.success : AppColors.danger)),
                  const SizedBox(height: 4),
                  Text(_deltaG! < 0 ? '✓ Spontaneous Reaction at this temperature' : '✗ Non-Spontaneous (requires energy input)', style: TextStyle(fontSize: 12, color: _deltaG! < 0 ? AppColors.success : AppColors.danger)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 7. ARRHENIUS RATE EQUATION
// ==========================================
class _ArrheniusCalculator extends StatefulWidget {
  const _ArrheniusCalculator();

  @override
  State<_ArrheniusCalculator> createState() => _ArrheniusCalculatorState();
}

class _ArrheniusCalculatorState extends State<_ArrheniusCalculator> {
  final _aFactor = TextEditingController(text: '1.0e13');
  final _ea = TextEditingController(text: '75.0'); // kJ/mol
  final _temp = TextEditingController(text: '298.15'); // K
  double? _k;
  String? _error;

  @override
  void dispose() {
    _aFactor.dispose();
    _ea.dispose();
    _temp.dispose();
    super.dispose();
  }

  void _calculate() {
    final a = double.tryParse(_aFactor.text.trim());
    final ea = double.tryParse(_ea.text.trim());
    final t = double.tryParse(_temp.text.trim());

    if (a == null || a <= 0) {
      setState(() {
        _error = 'Pre-exponential factor A must be strictly positive (> 0).';
        _k = null;
      });
      AppHaptics.error();
      return;
    }
    if (ea == null || ea < 0) {
      setState(() {
        _error = 'Activation energy Eₐ cannot be negative.';
        _k = null;
      });
      AppHaptics.error();
      return;
    }
    if (t == null || t <= 0) {
      setState(() {
        _error = 'Absolute temperature T must be strictly positive (> 0 K).';
        _k = null;
      });
      AppHaptics.error();
      return;
    }

    const r = 8.314; // J/mol·K
    final eaJoules = ea * 1000.0;
    final k = a * exp(-eaJoules / (r * t));
    setState(() {
      _k = k;
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Arrhenius Equation (Rate Constant k)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$k = A \exp\left(-\frac{E_a}{RT}\right)$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _aFactor, decoration: const InputDecoration(labelText: 'A (Frequency Factor)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _ea, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Ea (kJ/mol)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _temp, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Temp (K)'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Compute Rate Constant k')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_k != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Text('k = ${_k!.toStringAsExponential(4)} s⁻¹', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 8. BEER-LAMBERT ABSORBANCE
// ==========================================
class _BeerLambertCalculator extends StatefulWidget {
  const _BeerLambertCalculator();

  @override
  State<_BeerLambertCalculator> createState() => _BeerLambertCalculatorState();
}

class _BeerLambertCalculatorState extends State<_BeerLambertCalculator> {
  final _molarAbs = TextEditingController(text: '8400'); // M-1 cm-1
  final _pathLength = TextEditingController(text: '1.0'); // cm
  final _conc = TextEditingController(text: '1.5e-4'); // M
  double? _absorbance = 1.26;
  double? _transmittance = 5.50;
  String? _error;

  @override
  void dispose() {
    _molarAbs.dispose();
    _pathLength.dispose();
    _conc.dispose();
    super.dispose();
  }

  void _calculate() {
    final e = double.tryParse(_molarAbs.text.trim());
    final l = double.tryParse(_pathLength.text.trim());
    final c = double.tryParse(_conc.text.trim());

    if (e == null || e < 0) {
      setState(() {
        _error = 'Molar absorptivity ε must be non-negative.';
        _absorbance = null;
        _transmittance = null;
      });
      AppHaptics.error();
      return;
    }
    if (l == null || l <= 0) {
      setState(() {
        _error = 'Path length l must be strictly positive (> 0 cm).';
        _absorbance = null;
        _transmittance = null;
      });
      AppHaptics.error();
      return;
    }
    if (c == null || c < 0) {
      setState(() {
        _error = 'Concentration c must be non-negative.';
        _absorbance = null;
        _transmittance = null;
      });
      AppHaptics.error();
      return;
    }

    final a = e * c * l;
    final t = pow(10, -a) * 100.0;
    setState(() {
      _absorbance = a;
      _transmittance = t.toDouble();
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Beer-Lambert Law (UV-Vis Absorbance)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$A = \varepsilon \cdot c \cdot l$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _molarAbs, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'ε (M⁻¹cm⁻¹)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _pathLength, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Path l (cm)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _conc, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Conc c (mol/L)'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Compute Absorbance A')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_absorbance != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Absorbance A: ${_absorbance!.toStringAsFixed(3)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.purpleBright)),
                  if (_transmittance != null)
                    Text('%T: ${_transmittance!.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 9. WAVELENGTH & PHOTON ENERGY
// ==========================================
class _PhotonEnergyCalculator extends StatefulWidget {
  const _PhotonEnergyCalculator();

  @override
  State<_PhotonEnergyCalculator> createState() => _PhotonEnergyCalculatorState();
}

class _PhotonEnergyCalculatorState extends State<_PhotonEnergyCalculator> {
  final _wavelength = TextEditingController(text: '500'); // nm
  double? _joules;
  double? _ev;
  double? _frequency;
  String? _error;

  @override
  void dispose() {
    _wavelength.dispose();
    super.dispose();
  }

  void _calculate() {
    final wlNm = double.tryParse(_wavelength.text.trim());
    if (wlNm == null || wlNm <= 0) {
      setState(() {
        _error = 'Wavelength λ must be strictly positive (> 0 nm).';
        _frequency = null;
        _joules = null;
        _ev = null;
      });
      AppHaptics.error();
      return;
    }

    final wlM = wlNm * 1e-9;
    const c = 2.99792458e8; // m/s
    const h = 6.62607015e-34; // J·s
    const evJ = 1.602176634e-19; // J per eV

    final freq = c / wlM;
    final eJ = h * freq;
    final eEv = eJ / evJ;

    setState(() {
      _frequency = freq;
      _joules = eJ;
      _ev = eEv;
      _error = null;
    });
    AppHaptics.confirm();
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photon Energy & Frequency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$E = h\nu = \frac{hc}{\lambda}$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _wavelength,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Wavelength λ (nm)'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Convert to Energy & Frequency')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_ev != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('${_ev!.toStringAsFixed(3)} eV', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.purpleBright)),
                      Text('${_frequency!.toStringAsExponential(3)} Hz', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Energy per mole: ${((_joules! * 6.02214076e23) / 1000).toStringAsFixed(1)} kJ/mol', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 10. NERNST EQUATION CALCULATOR
// ==========================================
class _NernstCalculator extends StatefulWidget {
  const _NernstCalculator();

  @override
  State<_NernstCalculator> createState() => _NernstCalculatorState();
}

class _NernstCalculatorState extends State<_NernstCalculator> {
  final _eStd = TextEditingController(text: '1.10'); // Zn-Cu Daniell cell
  final _nElectrons = TextEditingController(text: '2');
  final _qRatio = TextEditingController(text: '0.01'); // [Zn2+]/[Cu2+]
  double? _eCell;
  String? _error;

  @override
  void dispose() {
    _eStd.dispose();
    _nElectrons.dispose();
    _qRatio.dispose();
    super.dispose();
  }

  void _calculate() {
    final e0 = double.tryParse(_eStd.text.trim());
    final n = double.tryParse(_nElectrons.text.trim());
    final q = double.tryParse(_qRatio.text.trim());

    if (e0 == null) {
      setState(() {
        _error = 'Please enter a valid standard potential E°cell (V).';
        _eCell = null;
      });
      AppHaptics.error();
      return;
    }
    if (n == null || n <= 0) {
      setState(() {
        _error = 'Number of transferred electrons n must be strictly positive (≥ 1).';
        _eCell = null;
      });
      AppHaptics.error();
      return;
    }
    if (q == null || q <= 0) {
      setState(() {
        _error = 'Reaction quotient Q must be strictly positive (> 0).';
        _eCell = null;
      });
      AppHaptics.error();
      return;
    }

    // E = E0 - (0.0592 / n) * log10(Q)
    final e = e0 - (0.0592 / n) * (log(q) / ln10);
    setState(() {
      _eCell = e;
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nernst Equation at 298 K', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$E = E^\circ - \frac{0.0592}{n} \log Q$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _eStd, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'E°cell (V)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _nElectrons, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'n (electrons)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _qRatio, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Quotient Q'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate Non-Standard E_cell')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_eCell != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Text('Cell Potential E = ${_eCell!.toStringAsFixed(4)} V', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 11. CELL POTENTIAL & ΔG°
// ==========================================
class _CellPotentialCalculator extends StatefulWidget {
  const _CellPotentialCalculator();

  @override
  State<_CellPotentialCalculator> createState() => _CellPotentialCalculatorState();
}

class _CellPotentialCalculatorState extends State<_CellPotentialCalculator> {
  final _eCathode = TextEditingController(text: '0.34'); // Cu2+/Cu
  final _eAnode = TextEditingController(text: '-0.76'); // Zn2+/Zn
  final _nElectrons = TextEditingController(text: '2');
  double? _eCell = 1.10;
  double? _deltaGZero;
  String? _error;

  @override
  void dispose() {
    _eCathode.dispose();
    _eAnode.dispose();
    _nElectrons.dispose();
    super.dispose();
  }

  void _calculate() {
    final ec = double.tryParse(_eCathode.text.trim());
    final ea = double.tryParse(_eAnode.text.trim());
    final n = double.tryParse(_nElectrons.text.trim()) ?? 2.0;

    if (ec == null || ea == null) {
      setState(() {
        _error = 'Please enter valid standard electrode potentials (V).';
        _eCell = null;
        _deltaGZero = null;
      });
      AppHaptics.error();
      return;
    }
    if (n <= 0) {
      setState(() {
        _error = 'Number of transferred electrons n must be strictly positive (≥ 1).';
        _eCell = null;
        _deltaGZero = null;
      });
      AppHaptics.error();
      return;
    }

    final eCell = ec - ea;
    const f = 96485.33; // C/mol
    final dgJ = -n * f * eCell;
    final dgKj = dgJ / 1000.0;

    setState(() {
      _eCell = eCell;
      _deltaGZero = dgKj;
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _onFieldChanged() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Standard Cell Potential & ΔG°', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$E^\circ_{\text{cell}} = E^\circ_{\text{cathode}} - E^\circ_{\text{anode}}, \quad \Delta G^\circ = -nFE^\circ_{\text{cell}}$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _eCathode, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'E°cathode (V)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _eAnode, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'E°anode (V)'), onChanged: (_) => _onFieldChanged())),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _nElectrons, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'n (e-)'), onChanged: (_) => _onFieldChanged())),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate E°cell & ΔG°')),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          if (_eCell != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('E°cell: ${_eCell!.toStringAsFixed(3)} V', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                  if (_deltaGZero != null)
                    Text('ΔG°: ${_deltaGZero!.toStringAsFixed(1)} kJ/mol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _deltaGZero! < 0 ? AppColors.success : AppColors.danger)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 6. STOICHIOMETRY & YIELD CALCULATOR
// ==========================================
class _StoichiometryCalculator extends StatefulWidget {
  const _StoichiometryCalculator();

  @override
  State<_StoichiometryCalculator> createState() => _StoichiometryCalculatorState();
}

class _StoichiometryCalculatorState extends State<_StoichiometryCalculator> {
  final _massController = TextEditingController(text: '10.0');
  final _molarMassController = TextEditingController(text: '180.16'); // Glucose
  final _actualYieldController = TextEditingController(text: '8.5');

  double? _moles;
  double? _molecules;
  double? _gasStpLitres;
  double? _percentYield;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void dispose() {
    _massController.dispose();
    _molarMassController.dispose();
    _actualYieldController.dispose();
    super.dispose();
  }

  void _compute() {
    final mass = double.tryParse(_massController.text.trim());
    final mw = double.tryParse(_molarMassController.text.trim());
    final actual = double.tryParse(_actualYieldController.text.trim());

    if (mass == null || mw == null || mw <= 0) {
      setState(() {
        _moles = null;
        _molecules = null;
        _gasStpLitres = null;
        _percentYield = null;
      });
      return;
    }

    final n = mass / mw;
    setState(() {
      _moles = n;
      _molecules = n * 6.02214076e23;
      _gasStpLitres = n * 22.414;
      if (actual != null && mass > 0) {
        _percentYield = (actual / mass) * 100.0;
      } else {
        _percentYield = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_outlined, color: AppColors.purpleBright, size: 20),
              SizedBox(width: 8),
              Text(
                'Mass ⇄ Mole ⇄ Particle Stoichiometry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$n = \frac{m}{M}, \quad N = n \times N_A, \quad V_{\text{STP}} = n \times 22.414\text{ L}$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _massController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Mass (g)'),
                  onChanged: (_) => _compute(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _molarMassController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Molar Mass (g/mol)'),
                  onChanged: (_) => _compute(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _actualYieldController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Actual Yield (g) [Optional]'),
                  onChanged: (_) => _compute(),
                ),
              ),
            ],
          ),
          if (_moles != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chemical Amount (n):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('${_moles!.toStringAsPrecision(4)} mol', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Particles (N):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('${_molecules!.toStringAsExponential(3)} particles', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gas Volume at STP (0°C, 1 atm):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('${_gasStpLitres!.toStringAsPrecision(4)} L', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold, fontSize: 13)),
                    ],
                  ),
                  if (_percentYield != null) ...[
                    const Divider(color: AppColors.borderSubtle, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reaction Percent Yield:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text('${_percentYield!.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: _percentYield! >= 70 ? AppColors.success : AppColors.warning, fontSize: 14)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 7. CHEMISTRY UNIT CONVERSIONS CALCULATOR
// ==========================================
class _UnitConversionCalculator extends StatefulWidget {
  const _UnitConversionCalculator();

  @override
  State<_UnitConversionCalculator> createState() => _UnitConversionCalculatorState();
}

class _UnitConversionCalculatorState extends State<_UnitConversionCalculator> {
  int _dimension = 0; // 0: Pressure, 1: Energy & Spectra, 2: Concentration, 3: Temperature
  final _inputController = TextEditingController(text: '1.0');
  String _sourceUnit = 'atm';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync_alt, color: AppColors.accentCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Chemistry Unit Conversions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _dimChip(0, 'Pressure'),
                _dimChip(1, 'Energy & Spectra'),
                _dimChip(2, 'Concentration'),
                _dimChip(3, 'Temperature'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Input Value ($_sourceUnit)',
              suffixText: _sourceUnit,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildConvertedOutputs(),
        ],
      ),
    );
  }

  Widget _dimChip(int idx, String title) {
    final sel = _dimension == idx;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(title, style: TextStyle(fontSize: 11.5, color: sel ? Colors.white : AppColors.textSecondary)),
        selected: sel,
        selectedColor: AppColors.purple,
        backgroundColor: AppColors.surfaceElevated,
        onSelected: (v) {
          if (v) {
            setState(() {
              _dimension = idx;
              if (idx == 0) _sourceUnit = 'atm';
              if (idx == 1) _sourceUnit = 'kJ/mol';
              if (idx == 2) _sourceUnit = 'M';
              if (idx == 3) _sourceUnit = '°C';
            });
          }
        },
      ),
    );
  }

  Widget _buildConvertedOutputs() {
    final val = double.tryParse(_inputController.text.trim()) ?? 1.0;
    final rows = <MapEntry<String, String>>[];

    if (_dimension == 0) {
      final atm = val;
      rows.add(MapEntry('Atmospheres (atm)', atm.toStringAsPrecision(4)));
      rows.add(MapEntry('Bar (bar)', (atm * 1.01325).toStringAsPrecision(4)));
      rows.add(MapEntry('Torr / mmHg', (atm * 760.0).toStringAsFixed(1)));
      rows.add(MapEntry('Kilopascals (kPa)', (atm * 101.325).toStringAsPrecision(4)));
      rows.add(MapEntry('Pascals (Pa)', (atm * 101325.0).toStringAsPrecision(5)));
      rows.add(MapEntry('Pounds / sq inch (psi)', (atm * 14.696).toStringAsPrecision(4)));
    } else if (_dimension == 1) {
      final kjMol = val;
      final joules = kjMol * 1000.0 / 6.02214e23;
      final ev = joules / 1.602176634e-19;
      final kcalMol = kjMol / 4.184;
      final cmInv = (joules / (6.62607e-34 * 2.99792e10));
      rows.add(MapEntry('kJ / mol', kjMol.toStringAsPrecision(4)));
      rows.add(MapEntry('kcal / mol', kcalMol.toStringAsPrecision(4)));
      rows.add(MapEntry('Electronvolts (eV)', ev.toStringAsPrecision(4)));
      rows.add(MapEntry('Single Molecule Joules (J)', joules.toStringAsExponential(3)));
      rows.add(MapEntry('Spectroscopic Wavenumber (cm⁻¹)', cmInv.toStringAsPrecision(4)));
    } else if (_dimension == 2) {
      final m = val;
      rows.add(MapEntry('Molarity (mol / L)', m.toStringAsPrecision(4)));
      rows.add(MapEntry('Millimolar (mM)', (m * 1000.0).toStringAsPrecision(4)));
      rows.add(MapEntry('Percent w/v (for MW 58.44)', '${(m * 5.844).toStringAsPrecision(3)} %'));
      rows.add(MapEntry('ppm (mg / L for MW 58.44)', (m * 58440.0).toStringAsPrecision(4)));
    } else if (_dimension == 3) {
      final c = val;
      final k = c + 273.15;
      final f = (c * 9.0 / 5.0) + 32.0;
      rows.add(MapEntry('Celsius (°C)', c.toStringAsFixed(2)));
      rows.add(MapEntry('Kelvin (K)', k.toStringAsFixed(2)));
      rows.add(MapEntry('Fahrenheit (°F)', f.toStringAsFixed(2)));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: rows.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              Text(e.value, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ==========================================
// 12. CRYSTAL FIELD THEORY (CFT) CALCULATOR
// ==========================================
class _CrystalFieldCalculator extends StatefulWidget {
  const _CrystalFieldCalculator();

  @override
  State<_CrystalFieldCalculator> createState() => _CrystalFieldCalculatorState();
}

class _CrystalFieldCalculatorState extends State<_CrystalFieldCalculator> {
  int _dElectrons = 6;
  bool _isOctahedral = true;
  bool _isStrongField = true;

  @override
  Widget build(BuildContext context) {
    // Octahedral CFSE calculation
    // t2g: -0.4 Δo, eg: +0.6 Δo
    // Tetrahedral CFSE calculation: e: -0.6 Δt, t2: +0.4 Δt
    int t2g = 0;
    int eg = 0;
    int unpaired = 0;
    double cfseVal = 0.0;
    int pairingCount = 0;

    if (_isOctahedral) {
      if (_dElectrons <= 3) {
        t2g = _dElectrons;
        eg = 0;
        unpaired = _dElectrons;
        cfseVal = -0.4 * t2g;
      } else if (_dElectrons >= 8) {
        t2g = 6;
        eg = _dElectrons - 6;
        unpaired = (eg == 2) ? 2 : (eg == 3 ? 1 : 0);
        cfseVal = (-0.4 * 6) + (0.6 * eg);
      } else {
        // d4, d5, d6, d7
        if (_isStrongField) {
          // Low spin
          if (_dElectrons == 4) {
            t2g = 4; eg = 0; unpaired = 2; cfseVal = -1.6; pairingCount = 1;
          } else if (_dElectrons == 5) {
            t2g = 5; eg = 0; unpaired = 1; cfseVal = -2.0; pairingCount = 2;
          } else if (_dElectrons == 6) {
            t2g = 6; eg = 0; unpaired = 0; cfseVal = -2.4; pairingCount = 2;
          } else {
            t2g = 6; eg = 1; unpaired = 1; cfseVal = -1.8; pairingCount = 1;
          }
        } else {
          // High spin
          if (_dElectrons == 4) {
            t2g = 3; eg = 1; unpaired = 4; cfseVal = -0.6;
          } else if (_dElectrons == 5) {
            t2g = 3; eg = 2; unpaired = 5; cfseVal = 0.0;
          } else if (_dElectrons == 6) {
            t2g = 4; eg = 2; unpaired = 4; cfseVal = -0.4;
          } else {
            t2g = 5; eg = 2; unpaired = 3; cfseVal = -0.8;
          }
        }
      }
    } else {
      // Tetrahedral: e (lower), t2 (higher), almost always high-spin (Δt < P)
      if (_dElectrons <= 2) {
        eg = _dElectrons; // e
        t2g = 0; // t2
        unpaired = _dElectrons;
        cfseVal = -0.6 * eg;
      } else if (_dElectrons <= 4) {
        eg = 2;
        t2g = _dElectrons - 2;
        unpaired = _dElectrons;
        cfseVal = (-0.6 * 2) + (0.4 * t2g);
      } else if (_dElectrons == 5) {
        eg = 2; t2g = 3; unpaired = 5; cfseVal = 0.0;
      } else if (_dElectrons <= 7) {
        eg = 2 + (_dElectrons - 5);
        t2g = 3;
        unpaired = 5 - (_dElectrons - 5);
        cfseVal = (-0.6 * eg) + (0.4 * 3);
      } else {
        eg = 4;
        t2g = _dElectrons - 4;
        unpaired = (t2g == 4) ? 2 : (t2g == 5 ? 1 : 0);
        cfseVal = (-0.6 * 4) + (0.4 * t2g);
      }
    }

    final spinOnlyMu = sqrt(unpaired * (unpaired + 2));
    final deltaSymbol = _isOctahedral ? 'Δₒ' : 'Δₜ';
    final configString = _isOctahedral
        ? 't₂g${_toSuper(t2g)} eg${_toSuper(eg)}'
        : 'e${_toSuper(eg)} t₂${_toSuper(t2g)}';

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_rounded, color: AppColors.purpleBright, size: 20),
              SizedBox(width: 8),
              Text(
                'Crystal Field & Ligand Field Solver',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Coordination Geometry', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Octahedral (Oₕ)', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: false, label: Text('Tetrahedral (T_d)', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_isOctahedral},
                      onSelectionChanged: (val) => setState(() => _isOctahedral = val.first),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('d-Electrons: d$_dElectrons', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Slider(
                      value: _dElectrons.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: 'd$_dElectrons',
                      activeColor: AppColors.brandPrimary,
                      onChanged: (v) => setState(() => _dElectrons = v.round()),
                    ),
                  ],
                ),
              ),
              if (_isOctahedral && _dElectrons >= 4 && _dElectrons <= 7) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ligand Field', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    ChoiceChip(
                      label: Text(_isStrongField ? 'Low Spin (Strong)' : 'High Spin (Weak)', style: const TextStyle(fontSize: 11)),
                      selected: _isStrongField,
                      selectedColor: AppColors.brandPrimary,
                      onSelected: (b) => setState(() => _isStrongField = b),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildMetricRow('Ground State Configuration', configString),
                const Divider(color: Colors.white12, height: 16),
                _buildMetricRow('Unpaired Electrons (n)', '$unpaired'),
                const Divider(color: Colors.white12, height: 16),
                _buildMetricRow('Spin-Only Magnetic Moment (μₛₒ)', '${spinOnlyMu.toStringAsFixed(2)} BM'),
                const Divider(color: Colors.white12, height: 16),
                _buildMetricRow(
                  'CFSE (Stabilization Energy)',
                  '${cfseVal.toStringAsFixed(1)} $deltaSymbol${pairingCount > 0 ? ' + ${pairingCount}P' : ''}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.accentCyan, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spectrochemical Series: CO > CN⁻ > NO₂⁻ > phen > bpy > en > NH₃ > H₂O > F⁻ > Cl⁻ > SCN⁻ > Br⁻ > I⁻. Strong-field ligands cause large Δₒ > P favoring low-spin complexes.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5)),
      ],
    );
  }

  static String _toSuper(int n) {
    const map = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
    if (n >= 0 && n <= 9) return map[n];
    return '$n';
  }
}

// ==========================================
// 13. INTEGRATED RATE LAW CALCULATOR
// ==========================================
class _IntegratedRateLawCalculator extends StatefulWidget {
  const _IntegratedRateLawCalculator();

  @override
  State<_IntegratedRateLawCalculator> createState() => _IntegratedRateLawCalculatorState();
}

class _IntegratedRateLawCalculatorState extends State<_IntegratedRateLawCalculator> {
  int _order = 1; // 0, 1, 2
  final _a0Ctrl = TextEditingController(text: '1.0');
  final _kCtrl = TextEditingController(text: '0.05');
  final _tCtrl = TextEditingController(text: '10.0');

  @override
  void dispose() {
    _a0Ctrl.dispose();
    _kCtrl.dispose();
    _tCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a0 = double.tryParse(_a0Ctrl.text) ?? 1.0;
    final k = double.tryParse(_kCtrl.text) ?? 0.05;
    final t = double.tryParse(_tCtrl.text) ?? 10.0;

    double at = 0.0;
    double halfLife = 0.0;
    String equation = '';
    String linearPlot = '';

    if (_order == 0) {
      equation = r'$$[\text{A}]_t = [\text{A}]_0 - kt$$';
      linearPlot = r'Plot $[\text{A}]$ vs $t$ (slope $= -k$)';
      at = max(0.0, a0 - (k * t));
      halfLife = a0 / (2 * k);
    } else if (_order == 1) {
      equation = r'$$\ln[\text{A}]_t = \ln[\text{A}]_0 - kt \implies [\text{A}]_t = [\text{A}]_0 e^{-kt}$$';
      linearPlot = r'Plot $\ln[\text{A}]$ vs $t$ (slope $= -k$)';
      at = a0 * exp(-k * t);
      halfLife = log(2) / k;
    } else {
      equation = r'$$\frac{1}{[\text{A}]_t} = \frac{1}{[\text{A}]_0} + kt$$';
      linearPlot = r'Plot $\frac{1}{[\text{A}]}$ vs $t$ (slope $= +k$)';
      at = 1.0 / ((1.0 / a0) + (k * t));
      halfLife = 1.0 / (k * a0);
    }

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.purpleBright, size: 20),
              SizedBox(width: 8),
              Text(
                'Chemical Kinetics & Integrated Rate Laws',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Reaction Order: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              ...[0, 1, 2].map((ord) {
                final isSel = _order == ord;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(ord == 0 ? '0th Order' : (ord == 1 ? '1st Order' : '2nd Order'), style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.textSecondary)),
                    selected: isSel,
                    selectedColor: AppColors.brandPrimary,
                    onSelected: (b) {
                      if (b) setState(() => _order = ord);
                    },
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _a0Ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Initial [A]₀ (M)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _kCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'k (${_order == 0 ? "M/s" : (_order == 1 ? "s⁻¹" : "M⁻¹s⁻¹")})',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _tCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Time t (s)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChemistryMarkdownView(
                  text: equation,
                  textStyle: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
                  selectable: false,
                ),
                const SizedBox(height: 4),
                ChemistryMarkdownView(
                  text: linearPlot,
                  textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  selectable: false,
                ),
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Remaining [A]ₜ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    Text('${at.toStringAsPrecision(4)} M', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Half-Life (t₁/₂)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    Text('${halfLife.toStringAsPrecision(4)} s', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 14. QUANTUM CHEMISTRY CALCULATOR
// ==========================================
class _QuantumChemistryCalculator extends StatefulWidget {
  const _QuantumChemistryCalculator();

  @override
  State<_QuantumChemistryCalculator> createState() => _QuantumChemistryCalculatorState();
}

class _QuantumChemistryCalculatorState extends State<_QuantumChemistryCalculator> {
  final _lCtrl = TextEditingController(text: '1.0'); // nm
  final _nCtrl = TextEditingController(text: '1');
  final _vCtrl = TextEditingController(text: '1.0e6'); // m/s for de Broglie

  @override
  void dispose() {
    _lCtrl.dispose();
    _nCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const h = 6.62607015e-34; // J s
    const m = 9.1093837e-31; // electron mass kg
    const c = 2.99792458e8; // m/s
    const eV = 1.602176634e-19; // J/eV

    final lNm = double.tryParse(_lCtrl.text) ?? 1.0;
    final lM = lNm * 1e-9;
    final n = int.tryParse(_nCtrl.text) ?? 1;
    final v = double.tryParse(_vCtrl.text) ?? 1e6;

    // E_n = (n^2 h^2) / (8 m L^2)
    final enJ = (n * n * h * h) / (8 * m * lM * lM);
    final enEv = enJ / eV;

    // Delta E (n -> n+1)
    final eNextJ = ((n + 1) * (n + 1) * h * h) / (8 * m * lM * lM);
    final deltaEJ = eNextJ - enJ;
    final lambdaNm = (deltaEJ > 0) ? (h * c / deltaEJ) * 1e9 : 0.0;

    // de Broglie: lambda = h / (m v)
    final deBroglieNm = (v > 0) ? (h / (m * v)) * 1e9 : 0.0;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.waves_rounded, color: AppColors.purpleBright, size: 20),
              SizedBox(width: 8),
              Text(
                'Quantum Chemistry: 1D Box & de Broglie',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Particle in a 1D Box (Electron)', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$E_n = \frac{n^2 h^2}{8mL^2}$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Box Length L (nm)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantum Number n'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildRow('Energy E_$n', '${enEv.toStringAsPrecision(4)} eV (${enJ.toStringAsPrecision(3)} J)'),
                const Divider(color: Colors.white12, height: 14),
                _buildRow('Transition ΔE (n → n+1)', '${(deltaEJ / eV).toStringAsPrecision(3)} eV'),
                const Divider(color: Colors.white12, height: 14),
                _buildRow('Absorption Wavelength (λ)', '${lambdaNm.toStringAsPrecision(4)} nm'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('de Broglie Wavelength', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          const ChemistryMarkdownView(
            text: r'$$\lambda = \frac{h}{mv}$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _vCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Electron Velocity v (m/s)', hintText: 'e.g. 1.0e6'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildRow('de Broglie Wavelength', '${deBroglieNm.toStringAsPrecision(4)} nm (${(deBroglieNm * 10).toStringAsPrecision(4)} Å)'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

// ==========================================
// 15. ANALYTICAL ERROR & DIXON Q-TEST
// ==========================================
class _AnalyticalErrorCalculator extends StatefulWidget {
  const _AnalyticalErrorCalculator();

  @override
  State<_AnalyticalErrorCalculator> createState() => _AnalyticalErrorCalculatorState();
}

class _AnalyticalErrorCalculatorState extends State<_AnalyticalErrorCalculator> {
  final _dataCtrl = TextEditingController(text: '12.45, 12.48, 12.46, 12.72, 12.47');

  @override
  void dispose() {
    _dataCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawTokens = _dataCtrl.text.split(RegExp(r'[,\s]+')).where((s) => s.isNotEmpty);
    final values = rawTokens.map((s) => double.tryParse(s)).whereType<double>().toList()..sort();

    final n = values.length;
    double mean = 0.0;
    double stdDev = 0.0;
    double rsd = 0.0;
    String qTestResult = 'Enter at least 3 replicate values';

    if (n >= 3) {
      mean = values.reduce((a, b) => a + b) / n;
      double varianceSum = 0.0;
      for (final v in values) {
        varianceSum += (v - mean) * (v - mean);
      }
      stdDev = sqrt(varianceSum / (n - 1));
      rsd = (mean != 0) ? (stdDev / mean.abs()) * 100.0 : 0.0;

      // Dixon Q-test
      // Suspect lowest or highest
      final range = values.last - values.first;
      if (range > 0) {
        final qLow = (values[1] - values[0]).abs() / range;
        final qHigh = (values.last - values[n - 2]).abs() / range;

        final isHighSuspect = qHigh >= qLow;
        final qCalc = isHighSuspect ? qHigh : qLow;
        final suspectVal = isHighSuspect ? values.last : values.first;

        // Q critical values at 90% confidence
        const qCritTable = {
          3: 0.941, 4: 0.765, 5: 0.642, 6: 0.560,
          7: 0.507, 8: 0.468, 9: 0.437, 10: 0.412
        };
        final qCrit = qCritTable[n] ?? 0.400;

        if (qCalc > qCrit) {
          qTestResult = 'Suspect $suspectVal: Q_calc ($qCalc) > Q_crit ($qCrit) ⟹ REJECT Outlier at 90% CL';
        } else {
          qTestResult = 'Suspect $suspectVal: Q_calc ($qCalc) ≤ Q_crit ($qCrit) ⟹ RETAIN Value';
        }
      }
    }

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.purpleBright, size: 20),
              SizedBox(width: 8),
              Text(
                'Error Analysis & Dixon’s Q-Test (Outliers)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _dataCtrl,
            decoration: const InputDecoration(
              labelText: 'Replicate Measurements (comma/space separated)',
              hintText: 'e.g. 12.45, 12.48, 12.46, 12.72, 12.47',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          if (n < 3)
            const Text('Please input at least 3 replicate observations to calculate statistics.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _row('Sample Size (N)', '$n'),
                  const Divider(color: Colors.white12, height: 14),
                  _row('Mean (x̄)', mean.toStringAsFixed(4)),
                  const Divider(color: Colors.white12, height: 14),
                  _row('Standard Deviation (s)', stdDev.toStringAsFixed(4)),
                  const Divider(color: Colors.white12, height: 14),
                  _row('Relative Std Dev (%RSD)', '${rsd.toStringAsFixed(2)} %'),
                  const Divider(color: Colors.white12, height: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bg1,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Dixon Q-Test (90% Conf.): $qTestResult',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

// ==========================================
// 16. VAN DEEMTER HPLC EFFICIENCY CALCULATOR
// ==========================================
class _VanDeemterCalculator extends StatefulWidget {
  const _VanDeemterCalculator();

  @override
  State<_VanDeemterCalculator> createState() => _VanDeemterCalculatorState();
}

class _VanDeemterCalculatorState extends State<_VanDeemterCalculator> {
  final _aCtrl = TextEditingController(text: '0.08'); // Eddy diffusion (cm)
  final _bCtrl = TextEditingController(text: '0.15'); // Longitudinal diffusion (cm^2/s)
  final _cCtrl = TextEditingController(text: '0.03'); // Mass transfer (s)
  final _uCtrl = TextEditingController(text: '2.0');  // Flow velocity (cm/s)
  final _colLengthCtrl = TextEditingController(text: '25.0'); // cm

  @override
  void dispose() {
    _aCtrl.dispose();
    _bCtrl.dispose();
    _cCtrl.dispose();
    _uCtrl.dispose();
    _colLengthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = double.tryParse(_aCtrl.text) ?? 0.08;
    final b = double.tryParse(_bCtrl.text) ?? 0.15;
    final c = double.tryParse(_cCtrl.text) ?? 0.03;
    final u = double.tryParse(_uCtrl.text) ?? 2.0;
    final length = double.tryParse(_colLengthCtrl.text) ?? 25.0;

    // H = A + B/u + C*u
    final currentH = (u > 0) ? (a + (b / u) + (c * u)) : 0.0;
    final currentPlates = (currentH > 0) ? (length / currentH).round() : 0;

    // Optimal velocity u_opt = sqrt(B / C)
    final uOpt = (c > 0 && b > 0) ? sqrt(b / c) : 0.0;
    final hMin = (c > 0 && b > 0) ? (a + (2 * sqrt(b * c))) : 0.0;
    final maxPlates = (hMin > 0) ? (length / hMin).round() : 0;

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.view_column_outlined, color: AppColors.purpleBright, size: 20),
              SizedBox(width: 8),
              Text(
                'HPLC Van Deemter Column Efficiency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const ChemistryMarkdownView(
            text: r'$$H = A + \frac{B}{u} + C \cdot u, \quad u_{\text{opt}} = \sqrt{\frac{B}{C}}$$',
            textStyle: TextStyle(fontSize: 12.5, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aCtrl,
                  decoration: const InputDecoration(labelText: 'A (Eddy, cm)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _bCtrl,
                  decoration: const InputDecoration(labelText: 'B (Diff, cm²/s)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cCtrl,
                  decoration: const InputDecoration(labelText: 'C (Mass Tr, s)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _uCtrl,
                  decoration: const InputDecoration(labelText: 'Linear Velocity u (cm/s)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _colLengthCtrl,
                  decoration: const InputDecoration(labelText: 'Column Length (cm)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _row('Plate Height at u = $u cm/s', '${currentH.toStringAsFixed(4)} cm'),
                const Divider(color: Colors.white12, height: 14),
                _row('Current Theoretical Plates (N)', '$currentPlates plates'),
                const Divider(color: Colors.white12, height: 14),
                _row('Optimal Velocity (u_opt)', '${uOpt.toStringAsFixed(3)} cm/s'),
                const Divider(color: Colors.white12, height: 14),
                _row('Minimum Plate Height (H_min)', '${hMin.toStringAsFixed(4)} cm'),
                const Divider(color: Colors.white12, height: 14),
                _row('Maximum Theoretical Plates (N_max)', '$maxPlates plates'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

// ==========================================
// 17. HPLC CALIBRATION CURVE PLOTTER
// ==========================================
class _CalibPoint {
  final double concentration;
  final double peakArea;
  const _CalibPoint(this.concentration, this.peakArea);
}

class _HplcCalibrationCurveCalculator extends StatefulWidget {
  const _HplcCalibrationCurveCalculator();

  @override
  State<_HplcCalibrationCurveCalculator> createState() => _HplcCalibrationCurveCalculatorState();
}

class _HplcCalibrationCurveCalculatorState extends State<_HplcCalibrationCurveCalculator> {
  final List<_CalibPoint> _points = [
    const _CalibPoint(10.0, 15200.0),
    const _CalibPoint(25.0, 37800.0),
    const _CalibPoint(50.0, 74500.0),
    const _CalibPoint(100.0, 149200.0),
    const _CalibPoint(200.0, 298000.0),
  ];

  final _newConcCtrl = TextEditingController();
  final _newAreaCtrl = TextEditingController();
  final _unknownAreaCtrl = TextEditingController(text: '85400');
  String? _error;

  @override
  void dispose() {
    _newConcCtrl.dispose();
    _newAreaCtrl.dispose();
    _unknownAreaCtrl.dispose();
    super.dispose();
  }

  void _addPoint() {
    final x = double.tryParse(_newConcCtrl.text.trim());
    final y = double.tryParse(_newAreaCtrl.text.trim());
    if (x == null || x < 0) {
      setState(() => _error = 'Concentration must be a valid non-negative number.');
      AppHaptics.error();
      return;
    }
    if (y == null || y < 0) {
      setState(() => _error = 'Peak area must be a valid non-negative number.');
      AppHaptics.error();
      return;
    }
    setState(() {
      _points.add(_CalibPoint(x, y));
      _points.sort((a, b) => a.concentration.compareTo(b.concentration));
      _newConcCtrl.clear();
      _newAreaCtrl.clear();
      _error = null;
    });
    AppHaptics.confirm();
  }

  void _removePoint(int index) {
    if (_points.length <= 2) {
      setState(() => _error = 'At least 2 calibration points are required for regression analysis.');
      AppHaptics.error();
      return;
    }
    setState(() {
      _points.removeAt(index);
      _error = null;
    });
    AppHaptics.selection();
  }

  void _resetDefaults() {
    setState(() {
      _points.clear();
      _points.addAll([
        const _CalibPoint(10.0, 15200.0),
        const _CalibPoint(25.0, 37800.0),
        const _CalibPoint(50.0, 74500.0),
        const _CalibPoint(100.0, 149200.0),
        const _CalibPoint(200.0, 298000.0),
      ]);
      _error = null;
    });
    AppHaptics.confirm();
  }

  @override
  Widget build(BuildContext context) {
    final n = _points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    for (final p in _points) {
      sumX += p.concentration;
      sumY += p.peakArea;
      sumXY += (p.concentration * p.peakArea);
      sumX2 += (p.concentration * p.concentration);
      sumY2 += (p.peakArea * p.peakArea);
    }
    final meanX = sumX / n;
    final meanY = sumY / n;
    final sxx = sumX2 - (n * meanX * meanX);
    final syy = sumY2 - (n * meanY * meanY);
    final sxy = sumXY - (n * meanX * meanY);

    final double slope = (sxx != 0) ? (sxy / sxx) : 0.0;
    final double intercept = meanY - (slope * meanX);
    final double r = (sxx > 0 && syy > 0) ? (sxy / sqrt(sxx * syy)) : 0.0;
    final double rSquared = r * r;

    // Residual standard deviation syx = sqrt( sum( (y - y_hat)^2 ) / (n - 2) )
    double ssResiduals = 0;
    for (final p in _points) {
      final yHat = slope * p.concentration + intercept;
      final diff = p.peakArea - yHat;
      ssResiduals += diff * diff;
    }
    final double syx = n > 2 ? sqrt(ssResiduals / (n - 2)) : 0.0;
    final double lod = (slope > 0 && n > 2) ? (3.3 * syx / slope) : 0.0;
    final double loq = (slope > 0 && n > 2) ? (10.0 * syx / slope) : 0.0;

    // Unknown sample quantification
    final unkY = double.tryParse(_unknownAreaCtrl.text.trim());
    final double? unkX = (unkY != null && slope != 0) ? ((unkY - intercept) / slope) : null;
    final bool isUnkInterpolated = (unkX != null && _points.isNotEmpty)
        ? (unkX >= _points.first.concentration && unkX <= _points.last.concentration)
        : false;

    // Chart data
    final spots = _points.map((p) => FlSpot(p.concentration, p.peakArea)).toList();
    final maxX = _points.isNotEmpty ? _points.last.concentration : 100.0;
    final lineSpots = [
      FlSpot(0, intercept > 0 ? intercept : 0),
      FlSpot(maxX * 1.05, slope * (maxX * 1.05) + intercept),
    ];

    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: AppColors.purpleBright, size: 20),
                  SizedBox(width: 8),
                  Text('HPLC Calibration Curve Plotter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: _resetDefaults,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Reset Defaults', style: TextStyle(color: AppColors.purpleBright, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const ChemistryMarkdownView(
            text: r'$$y = m x + c, \quad R^2 = \frac{S_{xy}^2}{S_{xx}S_{yy}}, \quad \text{LOD} = \frac{3.3 \, s_{y/x}}{m}, \quad \text{LOQ} = \frac{10 \, s_{y/x}}{m}$$',
            textStyle: TextStyle(fontSize: 12, color: AppColors.purpleBright),
            selectable: false,
          ),
          const SizedBox(height: 14),

          // Interactive Chart
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.borderSubtle, strokeWidth: 0.8),
                  getDrawingVerticalLine: (_) => const FlLine(color: AppColors.borderSubtle, strokeWidth: 0.8),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (val, meta) {
                        if (val == meta.min || val == meta.max) return const SizedBox.shrink();
                        final txt = val >= 1000 ? '${(val / 1000).toStringAsFixed(0)}k' : val.toStringAsFixed(0);
                        return Text(txt, style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, meta) {
                        if (val == meta.min || val == meta.max) return const SizedBox.shrink();
                        return Text(val.toStringAsFixed(0), style: const TextStyle(color: AppColors.textMuted, fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                lineBarsData: [
                  // 1. Fitted Regression Line
                  LineChartBarData(
                    spots: lineSpots,
                    isCurved: false,
                    color: AppColors.accentCyan,
                    barWidth: 2.2,
                    dotData: const FlDotData(show: false),
                  ),
                  // 2. Calibration Standards Scatter Points
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: Colors.transparent,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: AppColors.brandBright,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                  // 3. Unknown Sample Point (if calculated)
                  if (unkX != null && unkY != null)
                    LineChartBarData(
                      spots: [FlSpot(unkX, unkY)],
                      isCurved: false,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 6.5,
                          color: AppColors.accentGold,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'X-axis: Concentration (μg/mL)  •  Y-axis: Peak Area (mAU·s)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 14),

          // Regression Metrics Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Regression Equation:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    Text('y = ${slope.toStringAsFixed(2)} x + ${intercept.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Coefficient of Determination (R²):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    Row(
                      children: [
                        Text(rSquared.toStringAsFixed(5), style: TextStyle(fontWeight: FontWeight.bold, color: rSquared >= 0.999 ? AppColors.statusSuccess : AppColors.accentGold, fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (rSquared >= 0.999 ? AppColors.statusSuccess : AppColors.accentGold).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rSquared >= 0.999 ? 'ICH Q2 Linearity' : (rSquared >= 0.995 ? 'Acceptable' : 'Non-Linear'),
                            style: TextStyle(
                              color: rSquared >= 0.999 ? AppColors.statusSuccess : AppColors.accentGold,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Residual Std Dev (sy/x):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    Text(syx.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Limit of Detection (LOD, 3.3σ/S):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    Text('${lod.toStringAsFixed(3)} μg/mL', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 13)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Limit of Quantitation (LOQ, 10σ/S):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    Text('${loq.toStringAsFixed(3)} μg/mL', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandBright, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Unknown Sample Quantitation Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Unknown Sample Quantification 🔍', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unknownAreaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Unknown Peak Area (mAU·s)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (unkX != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantified Conc (x_unk):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      Text('${unkX.toStringAsFixed(3)} μg/mL', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Interpolation Status:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        isUnkInterpolated ? '✓ Within linear calibration range' : '⚠️ Extrapolated beyond standard range',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isUnkInterpolated ? AppColors.statusSuccess : AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Standards Data Table & Add Point
          const Text('Calibration Standards Table:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Conc (x)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted))),
                      Expanded(flex: 3, child: Text('Area (y)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted))),
                      Expanded(flex: 3, child: Text('Calc (ŷ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted))),
                      SizedBox(width: 30),
                    ],
                  ),
                ),
                ..._points.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pt = entry.value;
                  final yHat = slope * pt.concentration + intercept;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.5))),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(pt.concentration.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Colors.white))),
                        Expanded(flex: 3, child: Text(pt.peakArea.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: AppColors.accentCyan))),
                        Expanded(flex: 3, child: Text(yHat.toStringAsFixed(0), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                        SizedBox(
                          width: 30,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                            onPressed: () => _removePoint(idx),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newConcCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Conc (x)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newAreaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Area (y)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addPoint,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                child: const Text('Add'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
