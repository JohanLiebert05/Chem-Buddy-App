import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';

class ChemistryToolkitScreen extends StatefulWidget {
  const ChemistryToolkitScreen({super.key});

  @override
  State<ChemistryToolkitScreen> createState() => _ChemistryToolkitScreenState();
}

class _ChemistryToolkitScreenState extends State<ChemistryToolkitScreen> {
  int _selectedCategory = 0; // 0: Solutions, 1: Acid-Base, 2: Thermo/Kinetics, 3: Spectroscopy, 4: Electrochemistry

  final _categories = ['Solutions', 'Acid-Base', 'Thermo & Kinetics', 'Spectroscopy', 'Electrochem'];

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
              const _MolarMassCalculator(),
              const SizedBox(height: 16),
              const _MolarityCalculator(),
              const SizedBox(height: 16),
              const _DilutionCalculator(),
            ] else if (_selectedCategory == 1) ...[
              const _PhCalculator(),
              const SizedBox(height: 16),
              const _HendersonHasselbalchCalculator(),
            ] else if (_selectedCategory == 2) ...[
              const _GibbsFreeEnergyCalculator(),
              const SizedBox(height: 16),
              const _ArrheniusCalculator(),
            ] else if (_selectedCategory == 3) ...[
              const _BeerLambertCalculator(),
              const SizedBox(height: 16),
              const _PhotonEnergyCalculator(),
            ] else if (_selectedCategory == 4) ...[
              const _NernstCalculator(),
              const SizedBox(height: 16),
              const _CellPotentialCalculator(),
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
  const _MolarMassCalculator();

  @override
  State<_MolarMassCalculator> createState() => _MolarMassCalculatorState();
}

class _MolarMassCalculatorState extends State<_MolarMassCalculator> {
  final _controller = TextEditingController(text: 'H2SO4');
  double? _result = 98.079;
  String? _error;

  static const Map<String, double> _atomicMasses = {
    'H': 1.008, 'He': 4.003, 'Li': 6.941, 'Be': 9.012, 'B': 10.811,
    'C': 12.011, 'N': 14.007, 'O': 15.999, 'F': 18.998, 'Ne': 20.180,
    'Na': 22.990, 'Mg': 24.305, 'Al': 26.982, 'Si': 28.086, 'P': 30.974,
    'S': 32.065, 'Cl': 35.453, 'Ar': 39.948, 'K': 39.098, 'Ca': 40.078,
    'Sc': 44.956, 'Ti': 47.867, 'V': 50.942, 'Cr': 51.996, 'Mn': 54.938,
    'Fe': 55.845, 'Co': 58.933, 'Ni': 58.693, 'Cu': 63.546, 'Zn': 65.38,
    'Ga': 69.723, 'Ge': 72.630, 'As': 74.922, 'Se': 78.96, 'Br': 79.904,
    'Kr': 83.798, 'Rb': 85.468, 'Sr': 87.62, 'Y': 88.906, 'Zr': 91.224,
    'Ag': 107.868, 'Cd': 112.411, 'Sn': 118.710, 'I': 126.904, 'Ba': 137.327,
    'Pt': 195.084, 'Au': 196.967, 'Hg': 200.592, 'Pb': 207.2, 'U': 238.029,
  };

  void _calculate() {
    final formula = _controller.text.trim();
    if (formula.isEmpty) {
      setState(() {
        _result = null;
        _error = 'Please enter a chemical formula';
      });
      return;
    }

    final regex = RegExp(r'([A-Z][a-z]?)(\d*)');
    final matches = regex.allMatches(formula);

    double total = 0.0;
    bool valid = false;

    for (final match in matches) {
      final elem = match.group(1);
      final countStr = match.group(2);
      if (elem == null || elem.isEmpty) continue;

      final count = countStr == null || countStr.isEmpty ? 1 : int.tryParse(countStr) ?? 1;
      final mass = _atomicMasses[elem];

      if (mass != null) {
        total += mass * count;
        valid = true;
      } else {
        setState(() {
          _result = null;
          _error = 'Unknown element symbol: $elem';
        });
        return;
      }
    }

    if (valid) {
      setState(() {
        _result = total;
        _error = null;
      });
      AppHaptics.confirm();
    } else {
      setState(() {
        _result = null;
        _error = 'Could not parse formula. Example: KMnO4 or C6H12O6';
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
              const Icon(Icons.grain, color: AppColors.purpleBright, size: 20),
              const SizedBox(width: 8),
              const Text('Molar Mass Formula Parser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Enter molecular formula with standard capitalization (e.g. H2SO4, KMnO4, C6H12O6):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'e.g. C6H12O6'),
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
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('Molar Mass = ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  Text('${_result!.toStringAsFixed(3)} g/mol', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
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

  void _calculate() {
    final m = double.tryParse(_mass.text);
    final mm = double.tryParse(_molarMass.text);
    final vMl = double.tryParse(_volume.text);
    final nf = double.tryParse(_nFactor.text) ?? 1.0;

    if (m != null && mm != null && mm > 0 && vMl != null && vMl > 0) {
      final vL = vMl / 1000.0;
      final moles = m / mm;
      final molarity = moles / vL;
      final normality = molarity * nf;

      setState(() {
        _molarity = molarity;
        _normality = normality;
      });
      AppHaptics.confirm();
    }
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
              Expanded(child: TextField(controller: _mass, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mass (g)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _molarMass, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Molar Mass (g/mol)'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _volume, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Volume (mL)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _nFactor, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'n-Factor (Acidity/Basicity)'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Compute M & N')),
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

  void _calculate() {
    final c1 = double.tryParse(_c1.text);
    final v1 = double.tryParse(_v1.text);
    final v2 = double.tryParse(_v2.text);

    if (c1 != null && v1 != null && v2 != null && v2 > 0) {
      setState(() => _c2 = (c1 * v1) / v2);
      AppHaptics.confirm();
    }
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
              Expanded(child: TextField(controller: _c1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial C1 (M)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _v1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Initial V1 (mL)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _v2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Final V2 (mL)'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate Final Conc C2')),
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

  void _calculate() {
    final h = double.tryParse(_hConc.text);
    if (h != null && h > 0) {
      final ph = -log(h) / ln10;
      final poh = 14.0 - ph;
      setState(() {
        _ph = ph;
        _poh = poh;
      });
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('pH & pOH Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(r'pH = -\log[H^+], \quad pOH = 14 - pH', style: TextStyle(fontSize: 12, color: AppColors.purpleBright)),
          const SizedBox(height: 12),
          TextField(controller: _hConc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '[H+] Ion Concentration (mol/L)')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate pH')),
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
// 5. HENDERSON-HASSELBALCH BUFFER CALCULATOR
// ==========================================
class _HendersonHasselbalchCalculator extends StatefulWidget {
  const _HendersonHasselbalchCalculator();

  @override
  State<_HendersonHasselbalchCalculator> createState() => _HendersonHasselbalchCalculatorState();
}

class _HendersonHasselbalchCalculatorState extends State<_HendersonHasselbalchCalculator> {
  final _pKa = TextEditingController(text: '4.76'); // Acetic acid
  final _salt = TextEditingController(text: '0.1'); // [A-]
  final _acid = TextEditingController(text: '0.1'); // [HA]
  double? _ph = 4.76;

  void _calculate() {
    final pka = double.tryParse(_pKa.text);
    final a = double.tryParse(_salt.text);
    final ha = double.tryParse(_acid.text);

    if (pka != null && a != null && ha != null && ha > 0 && a > 0) {
      final ph = pka + (log(a / ha) / ln10);
      setState(() => _ph = ph);
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Henderson-Hasselbalch Buffer pH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(r'pH = pK_a + \log\frac{[A^-]}{[HA]}', style: TextStyle(fontSize: 12, color: AppColors.purpleBright)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _pKa, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'pKa'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _salt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '[Conjugate Base]'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _acid, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '[Weak Acid]'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Compute Buffer pH')),
          if (_ph != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: Text('Buffer pH = ${_ph!.toStringAsFixed(3)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.purpleBright)),
            ),
          ],
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

  void _calculate() {
    final dh = double.tryParse(_deltaH.text);
    final t = double.tryParse(_temp.text);
    final ds = double.tryParse(_deltaS.text);

    if (dh != null && t != null && ds != null) {
      final dg = dh - (t * (ds / 1000.0));
      setState(() => _deltaG = dg);
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gibbs Free Energy (ΔG = ΔH - TΔS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _deltaH, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ΔH (kJ/mol)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _temp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Temp T (K)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _deltaS, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ΔS (J/mol·K)'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate ΔG')),
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

  void _calculate() {
    final a = double.tryParse(_aFactor.text);
    final ea = double.tryParse(_ea.text);
    final t = double.tryParse(_temp.text);

    if (a != null && ea != null && t != null && t > 0) {
      const r = 8.314; // J/mol·K
      final eaJoules = ea * 1000.0;
      final k = a * exp(-eaJoules / (r * t));
      setState(() => _k = k);
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Arrhenius Equation (Rate Constant k)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(r'k = A \exp(-E_a / RT)', style: TextStyle(fontSize: 12, color: AppColors.purpleBright)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _aFactor, decoration: const InputDecoration(labelText: 'A (Frequency Factor)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _ea, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ea (kJ/mol)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _temp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Temp (K)'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Compute Rate Constant k')),
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
// 8. BEER-LAMBERT LAW
// ==========================================
class _BeerLambertCalculator extends StatefulWidget {
  const _BeerLambertCalculator();

  @override
  State<_BeerLambertCalculator> createState() => _BeerLambertCalculatorState();
}

class _BeerLambertCalculatorState extends State<_BeerLambertCalculator> {
  final _molarAbs = TextEditingController(text: '15000'); // L/mol·cm
  final _pathLength = TextEditingController(text: '1.0'); // cm
  final _conc = TextEditingController(text: '0.00005'); // mol/L
  double? _absorbance = 0.75;
  double? _transmittance;

  void _calculate() {
    final eps = double.tryParse(_molarAbs.text);
    final l = double.tryParse(_pathLength.text);
    final c = double.tryParse(_conc.text);

    if (eps != null && l != null && c != null) {
      final a = eps * c * l;
      final t = pow(10, -a) * 100;
      setState(() {
        _absorbance = a;
        _transmittance = t.toDouble();
      });
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Beer-Lambert Law (UV-Vis Absorbance)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(r'A = \varepsilon \cdot c \cdot l', style: TextStyle(fontSize: 12, color: AppColors.purpleBright)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _molarAbs, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ε (M⁻¹cm⁻¹)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _pathLength, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Path l (cm)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _conc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Conc c (mol/L)'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Compute Absorbance A')),
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

  void _calculate() {
    final wlNm = double.tryParse(_wavelength.text);
    if (wlNm != null && wlNm > 0) {
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
      });
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(r'Photon Energy & Frequency (E = hc/λ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _wavelength, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wavelength λ (nm)')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Convert to Energy & Frequency')),
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

  void _calculate() {
    final e0 = double.tryParse(_eStd.text);
    final n = double.tryParse(_nElectrons.text);
    final q = double.tryParse(_qRatio.text);

    if (e0 != null && n != null && n > 0 && q != null && q > 0) {
      // E = E0 - (0.0592 / n) * log10(Q)
      final e = e0 - (0.0592 / n) * (log(q) / ln10);
      setState(() => _eCell = e);
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nernst Equation at 298 K', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(r'E = E^\circ - \frac{0.0592}{n} \log Q', style: TextStyle(fontSize: 12, color: AppColors.purpleBright)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _eStd, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'E°cell (V)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _nElectrons, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'n (electrons)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _qRatio, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quotient Q'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate Non-Standard E_cell')),
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

  void _calculate() {
    final ec = double.tryParse(_eCathode.text);
    final ea = double.tryParse(_eAnode.text);
    final n = double.tryParse(_nElectrons.text) ?? 2.0;

    if (ec != null && ea != null) {
      final eCell = ec - ea;
      const f = 96485.33; // C/mol
      final dgJ = -n * f * eCell;
      final dgKj = dgJ / 1000.0;

      setState(() {
        _eCell = eCell;
        _deltaGZero = dgKj;
      });
      AppHaptics.confirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Standard Cell Potential & ΔG°', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(r'E^\circ_{cell} = E^\circ_{cathode} - E^\circ_{anode}, \quad \Delta G^\circ = -nFE^\circ_{cell}', style: TextStyle(fontSize: 12, color: AppColors.purpleBright)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _eCathode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'E°cathode (V)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _eAnode, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'E°anode (V)'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _nElectrons, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'n (e-)'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate E°cell & ΔG°')),
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
