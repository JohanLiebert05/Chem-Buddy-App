import '../../../core/utils/chemistry_text_formatter.dart';

/// Domain-specific OCR post-processing normalizer for MSc Chemistry documents.
/// Fixes common OCR confusion artifacts, formats subscripts/superscripts,
/// normalizes reaction arrows/conditions, and preserves mathematical equations.
class ChemistryOcrNormalizer {
  ChemistryOcrNormalizer._();

  static const Map<String, String> _subscriptMap = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
    '+': '₊',
    '-': '₋',
  };

  static const Map<String, String> _superscriptMap = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '-': '⁻',
  };

  /// Main entrypoint: Cleans and normalizes raw OCR / extracted text.
  static String normalize(String raw) {
    if (raw.trim().isEmpty) return '';

    var text = raw;

    // 1. Basic character / whitespace normalization
    text = text
        .replaceAll('\u0000', ' ')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ');

    // 2. Fix OCR character confusion in chemical formulas (O vs 0, 1 vs l, NA vs Na)
    text = _fixOcrConfusion(text);

    // 3. Normalize NMR isotopes and spectroscopy designations
    text = _normalizeSpectroscopy(text);

    // 4. Normalize reaction arrows and conditions (->, <=>, delta, hv, deg C)
    text = _normalizeReactionArrowsAndConditions(text);

    // 5. Normalize common physical chemistry and math equation symbols
    text = _normalizeEquations(text);

    // 6. Subscript & superscript chemical formulas and ionic charges
    text = _formatChemicalFormulasAndCharges(text);

    // 7. Leverage core chemistry formatter for polish
    text = ChemistryTextFormatter.format(text);

    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  /// Fixes frequent OCR character mixups in chemical contexts.
  static String _fixOcrConfusion(String text) {
    var s = text;

    // 1. O vs 0 confusion in standard chemical formulas & common organic groups:
    // H2S04 -> H2SO4, KMN04 -> KMnO4, H20 -> H2O, C02 -> CO2, C0 -> CO, C00H -> COOH, CH3C00H -> CH3COOH
    final formulaZeros = [
      (RegExp(r'\bH2S04\b', caseSensitive: false), 'H2SO4'),
      (RegExp(r'\bKMN04\b', caseSensitive: false), 'KMnO4'),
      (RegExp(r'\bK2Cr207\b', caseSensitive: false), 'K2Cr2O7'),
      (RegExp(r'\bH20\b'), 'H2O'),
      (RegExp(r'\bC02\b'), 'CO2'),
      (RegExp(r'\bC0\b'), 'CO'),
      (RegExp(r'\bC00H\b'), 'COOH'),
      (RegExp(r'\bCH3C00H\b'), 'CH3COOH'),
      (RegExp(r'\bCH3C00Na\b', caseSensitive: false), 'CH3COONa'),
      (RegExp(r'\bN02\b'), 'NO2'),
      (RegExp(r'\bN03\b'), 'NO3'),
      (RegExp(r'\bS04\b'), 'SO4'),
      (RegExp(r'\bP04\b'), 'PO4'),
      (RegExp(r'\bCaC03\b'), 'CaCO3'),
      (RegExp(r'\bNa2C03\b'), 'Na2CO3'),
      (RegExp(r'\bNaHC03\b'), 'NaHCO3'),
      (RegExp(r'\bFe203\b'), 'Fe2O3'),
      (RegExp(r'\bAl203\b'), 'Al2O3'),
      (RegExp(r'\bC6H1206\b'), 'C6H12O6'),
      (RegExp(r'\bPb02\b'), 'PbO2'),
      (RegExp(r'\bMn02\b'), 'MnO2'),
      (RegExp(r'\bTi02\b'), 'TiO2'),
      (RegExp(r'\bBaS04\b', caseSensitive: false), 'BaSO4'),
      (RegExp(r'\bCuS04\b', caseSensitive: false), 'CuSO4'),
      (RegExp(r'\bFeS04\b', caseSensitive: false), 'FeSO4'),
      (RegExp(r'\bMgS04\b', caseSensitive: false), 'MgSO4'),
      (RegExp(r'\bZnS04\b', caseSensitive: false), 'ZnSO4'),
    ];

    for (final pair in formulaZeros) {
      s = s.replaceAll(pair.$1, pair.$2);
    }

    // 2. Handwriting S vs 5 confusion in sulfate, sulfite, sulfide and tin contexts:
    final sVs5Fixes = [
      (RegExp(r'\b5O4\b'), 'SO4'),
      (RegExp(r'\b5O3\b'), 'SO3'),
      (RegExp(r'\b5O2\b'), 'SO2'),
      (RegExp(r'\bH25O4\b', caseSensitive: false), 'H2SO4'),
      (RegExp(r'\bFe5O4\b', caseSensitive: false), 'FeSO4'),
      (RegExp(r'\bCu5O4\b', caseSensitive: false), 'CuSO4'),
      (RegExp(r'\bZn5O4\b', caseSensitive: false), 'ZnSO4'),
      (RegExp(r'\bNa25O4\b', caseSensitive: false), 'Na2SO4'),
      (RegExp(r'\bK25O4\b', caseSensitive: false), 'K2SO4'),
      (RegExp(r'\bBa5O4\b', caseSensitive: false), 'BaSO4'),
      (RegExp(r'\bCa5O4\b', caseSensitive: false), 'CaSO4'),
      (RegExp(r'\bMg5O4\b', caseSensitive: false), 'MgSO4'),
      (RegExp(r'\b5nCl2\b', caseSensitive: false), 'SnCl2'),
      (RegExp(r'\b5nCl4\b', caseSensitive: false), 'SnCl4'),
      (RegExp(r'\b5n/HCl\b', caseSensitive: false), 'Sn/HCl'),
    ];

    for (final pair in sVs5Fixes) {
      s = s.replaceAll(pair.$1, pair.$2);
    }

    // 3. Chlorine / Halogen OCR confusions (Cl vs CI vs C1, Al vs A1):
    final halogenFixes = [
      (RegExp(r'\bNACl\b'), 'NaCl'),
      (RegExp(r'\bNaCI\b'), 'NaCl'),
      (RegExp(r'\bNaC1\b'), 'NaCl'),
      (RegExp(r'\bNAOH\b'), 'NaOH'),
      (RegExp(r'\bHCL\b'), 'HCl'),
      (RegExp(r'\bHCI\b'), 'HCl'),
      (RegExp(r'\bHC1\b'), 'HCl'),
      (RegExp(r'\bHBR\b'), 'HBr'),
      (RegExp(r'\bHI\b'), 'HI'),
      (RegExp(r'\bCI2\b'), 'Cl2'),
      (RegExp(r'\bC12\b'), 'Cl2'),
      (RegExp(r'\bCI-\b'), 'Cl-'),
      (RegExp(r'\bC1-\b'), 'Cl-'),
      (RegExp(r'\bCCI4\b'), 'CCl4'),
      (RegExp(r'\bCC14\b'), 'CCl4'),
      (RegExp(r'\bCH2CI2\b'), 'CH2Cl2'),
      (RegExp(r'\bCH2C12\b'), 'CH2Cl2'),
      (RegExp(r'\bCHCI3\b'), 'CHCl3'),
      (RegExp(r'\bCHC13\b'), 'CHCl3'),
      (RegExp(r'\bAICI3\b'), 'AlCl3'),
      (RegExp(r'\bA1Cl3\b'), 'AlCl3'),
      (RegExp(r'\bA1C13\b'), 'AlCl3'),
      (RegExp(r'\bAlC13\b'), 'AlCl3'),
      (RegExp(r'\bPCI5\b'), 'PCl5'),
      (RegExp(r'\bPC15\b'), 'PCl5'),
      (RegExp(r'\bPCI3\b'), 'PCl3'),
      (RegExp(r'\bPC13\b'), 'PCl3'),
      (RegExp(r'\bSOCI2\b'), 'SOCl2'),
      (RegExp(r'\bSOC12\b'), 'SOCl2'),
      (RegExp(r'\bFECL3\b'), 'FeCl3'),
      (RegExp(r'\bFeCI3\b'), 'FeCl3'),
      (RegExp(r'\bFeC13\b'), 'FeCl3'),
      (RegExp(r'\bFECL2\b'), 'FeCl2'),
      (RegExp(r'\bFeCI2\b'), 'FeCl2'),
      (RegExp(r'\bFeC12\b'), 'FeCl2'),
      (RegExp(r'\bCACL2\b'), 'CaCl2'),
      (RegExp(r'\bCaCI2\b'), 'CaCl2'),
      (RegExp(r'\bCaC12\b'), 'CaCl2'),
      (RegExp(r'\bZNCL2\b'), 'ZnCl2'),
      (RegExp(r'\bZnCI2\b'), 'ZnCl2'),
      (RegExp(r'\bZnC12\b'), 'ZnCl2'),
      (RegExp(r'\bAGCL\b'), 'AgCl'),
      (RegExp(r'\bAgCI\b'), 'AgCl'),
      (RegExp(r'\bAgC1\b'), 'AgCl'),
      (RegExp(r'\bKMNO4\b'), 'KMnO4'),
      (RegExp(r'\bK2CR2O7\b'), 'K2Cr2O7'),
      (RegExp(r'\bMGSO4\b'), 'MgSO4'),
      (RegExp(r'\bCUSO4\b'), 'CuSO4'),
      (RegExp(r'\bAGNO3\b'), 'AgNO3'),
      (RegExp(r'\bPB\(NO3\)2\b', caseSensitive: false), 'Pb(NO3)2'),
      (RegExp(r'\bNA2SO4\b'), 'Na2SO4'),
      (RegExp(r'\bK2SO4\b'), 'K2SO4'),
    ];

    for (final pair in halogenFixes) {
      s = s.replaceAll(pair.$1, pair.$2);
    }

    return s;
  }

  /// Normalizes NMR isotopes and spectroscopy units.
  static String _normalizeSpectroscopy(String text) {
    var s = text;

    // Isotopes for NMR
    s = s.replaceAllMapped(RegExp(r'\b1H\s*[-–]?\s*NMR\b', caseSensitive: false), (_) => '¹H NMR');
    s = s.replaceAllMapped(RegExp(r'\b13C\s*[-–]?\s*NMR\b', caseSensitive: false), (_) => '¹³C NMR');
    s = s.replaceAllMapped(RegExp(r'\b31P\s*[-–]?\s*NMR\b', caseSensitive: false), (_) => '³¹P NMR');
    s = s.replaceAllMapped(RegExp(r'\b19F\s*[-–]?\s*NMR\b', caseSensitive: false), (_) => '¹⁹F NMR');
    s = s.replaceAllMapped(RegExp(r'\b14N\b'), (_) => '¹⁴N');
    s = s.replaceAllMapped(RegExp(r'\b15N\b'), (_) => '¹⁵N');
    s = s.replaceAllMapped(RegExp(r'\b12C\b'), (_) => '¹²C');
    s = s.replaceAllMapped(RegExp(r'\b14C\b'), (_) => '¹⁴C');

    // Units
    s = s.replaceAll(RegExp(r'cm\s*[-–\^]?\s*1\b', caseSensitive: false), 'cm⁻¹');
    s = s.replaceAll(RegExp(r'kJ\s*/\s*mol\b|kJ\s+mol\s*[-–\^]?\s*1\b', caseSensitive: false), 'kJ·mol⁻¹');
    s = s.replaceAll(RegExp(r'kcal\s*/\s*mol\b', caseSensitive: false), 'kcal·mol⁻¹');
    s = s.replaceAll(RegExp(r'mol\s*/\s*L\b|mol\s+L\s*[-–\^]?\s*1\b', caseSensitive: false), 'mol·L⁻¹');
    s = s.replaceAll(RegExp(r'mol\s*/\s*dm3\b|mol\s+dm\s*[-–\^]?\s*3\b', caseSensitive: false), 'mol·dm⁻³');

    return s;
  }

  /// Normalizes reaction arrows, equilibrium symbols, and reaction conditions.
  static String _normalizeReactionArrowsAndConditions(String text) {
    var s = text;

    // Reaction Arrows
    s = s.replaceAll(RegExp(r'<==>|<=>|<->'), '⇌');
    s = s.replaceAll(RegExp(r'<-->'), '↔');
    s = s.replaceAll(RegExp(r'-->|==>|->|=>'), '→');

    // Reaction conditions / Symbols
    s = s.replaceAll(RegExp(r'\b(?:delta|Delta|/\\)\b'), 'Δ');
    s = s.replaceAll(RegExp(r'\b(?:hv|h\.v|h\s+nu|hnu)\b', caseSensitive: false), 'hν');
    s = s.replaceAll(RegExp(r'\b(?:deg\s*C|oC|°\s*C)\b'), '°C');
    s = s.replaceAll(RegExp(r'\bt(?:1/2|_1/2|\s*1/2)\b'), 't½');
    s = s.replaceAll(RegExp(r'\bpka\b'), 'pKa');
    s = s.replaceAll(RegExp(r'\bpkb\b'), 'pKb');

    return s;
  }

  /// Normalizes math equations and physical chemistry expressions.
  static String _normalizeEquations(String text) {
    var s = text;

    // Gibbs Free Energy: delta G = delta H - T delta S
    s = s.replaceAllMapped(
      RegExp(r'Δ\s*G°?\s*=\s*Δ\s*H°?\s*[-–]\s*T\s*Δ\s*S°?', caseSensitive: false),
      (m) => 'ΔG° = ΔH° − TΔS°',
    );

    // Arrhenius Equation: k = A e^(-Ea/RT)
    s = s.replaceAllMapped(
      RegExp(r'k\s*=\s*A\s*e\s*[\^]?\s*\(?\s*[-–]?\s*Ea\s*/\s*RT\s*\)?', caseSensitive: false),
      (m) => 'k = A e^(−Ea / RT)',
    );

    // Beer-Lambert Law: A = e * b * c / A = eps * c * l
    s = s.replaceAllMapped(
      RegExp(r'\bA\s*=\s*(?:ε|eps|epsilon)\s*[\*·\.]?\s*([bcl])\s*[\*·\.]?\s*([bcl])\b', caseSensitive: false),
      (m) => 'A = ε · ${m.group(1)} · ${m.group(2)}',
    );

    // Bragg's Law: n lambda = 2 d sin theta
    s = s.replaceAllMapped(
      RegExp(r'\bn\s*(?:λ|lambda)\s*=\s*2\s*d\s*sin\s*(?:θ|theta)\b', caseSensitive: false),
      (m) => 'nλ = 2d sin(θ)',
    );

    return s;
  }

  /// Subscripts numbers in chemical formulas and superscripts ionic charges.
  static String _formatChemicalFormulasAndCharges(String text) {
    var s = text;

    // 1. Single-atom metal/non-metal ions (Fe3+, Fe2+, Cu2+, Ca2+, Mg2+, Al3+, Zn2+, Na+, K+, H+, Cl-, Br-, I-)
    s = s.replaceAllMapped(RegExp(r'\b([A-Z][a-z]?)([23456789]?)([\+\-])(?!\w)'), (m) {
      final elem = m.group(1)!;
      final num = m.group(2)!;
      final sign = m.group(3)!;
      final superNum = num.split('').map((c) => _superscriptMap[c] ?? c).join();
      final superSign = _superscriptMap[sign] ?? sign;
      return '$elem$superNum$superSign';
    });

    // 2. Polyatomic ions with charge (H3O+, NH4+, OH-, SO4 2-, SO42-, NO3-, CO3 2-, PO4 3-)
    s = s.replaceAllMapped(RegExp(r'\b(H3O|NH4|OH|SO4|NO3|CO3|PO4)\s*([23456789]?)([\+\-])(?!\w)'), (m) {
      final base = m.group(1)!;
      final num = m.group(2)!;
      final sign = m.group(3)!;
      final superNum = num.split('').map((c) => _superscriptMap[c] ?? c).join();
      final superSign = _superscriptMap[sign] ?? sign;
      return '$base$superNum$superSign';
    });

    // 3. Chemical Formula Subscripting:
    // Matches common chemical formulas e.g. H2SO4, KMnO4, CH3COOH, C6H12O6, [Fe(CN)6]4-
    final formulaRegex = RegExp(
      r'\b([A-Z][a-z]?\d+|[A-Z][a-z]?[A-Z][a-z]?\d+|\b[A-Z][a-z]?(?:[A-Z][a-z]?\d*){2,})\b',
    );

    s = s.replaceAllMapped(formulaRegex, (m) {
      final token = m.group(0)!;

      // Exclude common acronyms, units, years, or mixed alphanumeric labels
      if (_isNonFormulaWord(token)) {
        return token;
      }

      // Convert digits to subscripts
      return token.replaceAllMapped(RegExp(r'\d+'), (digitMatch) {
        return digitMatch.group(0)!.split('').map((d) => _subscriptMap[d] ?? d).join();
      });
    });

    // 4. Handle bracketed coordination complexes with charges e.g. [Fe(CN)6]4-, [Co(NH3)6]3+, [Ni(CN)4]2-
    s = s.replaceAllMapped(RegExp(r'\[([A-Za-z0-9\(\)]+)\](\d*)([23456789]?)([\+\-]?)'), (m) {
      final inside = m.group(1)!;
      final outerDigits = m.group(2)!;
      final chargeNum = m.group(3)!;
      final chargeSign = m.group(4)!;

      final formattedInside = inside.replaceAllMapped(RegExp(r'\d+'), (d) {
        return d.group(0)!.split('').map((c) => _subscriptMap[c] ?? c).join();
      });
      final formattedOuter = outerDigits.split('').map((c) => _subscriptMap[c] ?? c).join();

      var formattedCharge = '';
      if (chargeSign.isNotEmpty) {
        final superNum = chargeNum.split('').map((c) => _superscriptMap[c] ?? c).join();
        final superSign = _superscriptMap[chargeSign] ?? chargeSign;
        formattedCharge = '$superNum$superSign';
      }

      return '[$formattedInside]$formattedOuter$formattedCharge';
    });

    // 5. Scientific concentration notation: 10^-3 M -> 10⁻³ M, 10^-7 M -> 10⁻⁷ M
    s = s.replaceAllMapped(RegExp(r'\b10\s*[\^]?\s*([–\-]?)(\d+)\s*([MmMµu]?)(\b|\s)'), (m) {
      final sign = m.group(1)!;
      final exponent = m.group(2)!;
      final unit = m.group(3)!;
      final trail = m.group(4)!;

      final superSign = sign.isNotEmpty ? '⁻' : '';
      final superExp = exponent.split('').map((c) => _superscriptMap[c] ?? c).join();
      final unitStr = unit.isNotEmpty ? ' $unit' : '';

      return '10$superSign$superExp$unitStr$trail';
    });

    return s;
  }

  /// Specialized normalizer specifically tuned for handwritten chemistry notes.
  /// Handles handwriting quirks, arrow conversions, loose spacing, and structural annotations.
  static String normalizeHandwritten(String raw) {
    if (raw.trim().isEmpty) return '';

    var text = raw;

    // 1. Convert handwriting single '>' arrow when surrounded by chemistry terms:
    // e.g. "Reactant > Product" or "A + B > C" -> "A + B → C"
    text = text.replaceAllMapped(
      RegExp(r'([A-Za-z0-9\)\}\]]+)\s*>\s*([A-Za-z0-9\(\{\[]+)'),
      (m) => '${m.group(1)} → ${m.group(2)}',
    );

    // 2. Normalise equilibrium handwriting `<=>`, `<->`, `~>`
    text = text.replaceAll(RegExp(r'<==>|<=>|<->|<=+>'), '⇌');
    text = text.replaceAll(RegExp(r'-->|==>|->|=>|~>'), '→');

    // 3. Run master chemistry normalization pipeline
    text = normalize(text);

    return text;
  }

  /// Checks whether a token is an English word or acronym rather than a chemical formula.
  static bool _isNonFormulaWord(String token) {
    const nonFormulas = {
      'HPLC', 'GCMS', 'LCMS', 'NMR', 'FTIR', 'UV', 'VIS', 'PDA', 'DAD', 'TOF', 'MS',
      'ICH', 'USP', 'EP', 'BP', 'WHO', 'LOD', 'LOQ', 'SNR', 'RSD', 'SD', 'PPM',
      'HOMO', 'LUMO', 'SOMO', 'CFSE', 'LFT', 'CFT', 'MOT', 'VSEPR', 'HSAB', 'ORD', 'CD',
      'DNA', 'RNA', 'ATP', 'ADP', 'NAD', 'NADH', 'DCM', 'THF', 'DMF', 'DMSO', 'TFA',
      'NBS', 'PCC', 'PDC', 'DIBAL', 'LDA', 'DCC', 'DMAP', 'AIBN', 'MCPBA', 'TLC',
      'SEC', 'PAGE', 'SDS', 'CDCL3', 'TMS', 'SN1', 'SN2', 'E1', 'E2', 'RDS',
      'PART1', 'PART2', 'PAGE1', 'PAGE2', 'STEP1', 'STEP2', 'FIG1', 'FIG2', 'TABLE1',
      'YEAR2024', 'YEAR2025', 'YEAR2026', 'MSc', 'BSc', 'PhD',
    };

    if (nonFormulas.contains(token.toUpperCase())) return true;

    // Tokens without any digits don't need subscripting
    if (!RegExp(r'\d').hasMatch(token)) return true;

    // Tokens starting with numbers aren't simple formulas
    if (RegExp(r'^\d').hasMatch(token)) return true;

    return false;
  }

  /// Extracts chemistry formulas, equations and reaction expressions found in text.
  static List<String> extractDetectedFormulas(String text) {
    final formulas = <String>{};

    // Subscripted formulas
    final subRegex = RegExp(r'\b[A-Z][a-z]?[₀-₉]+(?:[A-Z][a-z]?[₀-₉]*)*\b');
    for (final m in subRegex.allMatches(text)) {
      final f = m.group(0)!.trim();
      if (f.length >= 2) formulas.add(f);
    }

    // Reaction lines containing arrows
    final lines = text.split('\n');
    for (final line in lines) {
      final l = line.trim();
      if (l.contains('→') || l.contains('⇌') || l.contains('↔')) {
        if (l.length >= 5 && l.length <= 120) {
          formulas.add(l);
        }
      }
    }

    // Equations (ΔG, k = A e^..., A = ε b c, Nernst)
    for (final line in lines) {
      final l = line.trim();
      if (l.contains('ΔG') ||
          l.contains('k = A') ||
          l.contains('A = ε') ||
          l.contains('nλ =') ||
          l.contains('pH =')) {
        if (l.length >= 5 && l.length <= 120) {
          formulas.add(l);
        }
      }
    }

    return formulas.toList();
  }
}
