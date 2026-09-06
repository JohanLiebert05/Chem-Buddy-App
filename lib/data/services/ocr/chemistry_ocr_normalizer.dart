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

    // 1. O vs 0 confusion in standard chemical formulas:
    // H2S04 -> H2SO4, KMN04 -> KMnO4, H20 -> H2O, C02 -> CO2, C00H -> COOH, CH3C00H -> CH3COOH
    final formulaZeros = [
      (RegExp(r'\bH2S04\b', caseSensitive: false), 'H2SO4'),
      (RegExp(r'\bKMN04\b', caseSensitive: false), 'KMnO4'),
      (RegExp(r'\bK2Cr207\b', caseSensitive: false), 'K2Cr2O7'),
      (RegExp(r'\bH20\b'), 'H2O'),
      (RegExp(r'\bC02\b'), 'CO2'),
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
    ];

    for (final pair in formulaZeros) {
      s = s.replaceAll(pair.$1, pair.$2);
    }

    // 2. Element Capitalization / OCR Fixes:
    // NACl -> NaCl, NAOH -> NaOH, HCL -> HCl, HBR -> HBr, CACL2 -> CaCl2, MGSO4 -> MgSO4
    final elementFixes = [
      (RegExp(r'\bNACl\b'), 'NaCl'),
      (RegExp(r'\bNAOH\b'), 'NaOH'),
      (RegExp(r'\bHCL\b'), 'HCl'),
      (RegExp(r'\bHBR\b'), 'HBr'),
      (RegExp(r'\bKMNO4\b'), 'KMnO4'),
      (RegExp(r'\bK2CR2O7\b'), 'K2Cr2O7'),
      (RegExp(r'\bMGSO4\b'), 'MgSO4'),
      (RegExp(r'\bCACL2\b'), 'CaCl2'),
      (RegExp(r'\bFECL3\b'), 'FeCl3'),
      (RegExp(r'\bFECL2\b'), 'FeCl2'),
      (RegExp(r'\bCUSO4\b'), 'CuSO4'),
      (RegExp(r'\bZNCL2\b'), 'ZnCl2'),
      (RegExp(r'\bAGNO3\b'), 'AgNO3'),
      (RegExp(r'\bAGCL\b'), 'AgCl'),
      (RegExp(r'\bPB\(NO3\)2\b', caseSensitive: false), 'Pb(NO3)2'),
      (RegExp(r'\bNA2SO4\b'), 'Na2SO4'),
      (RegExp(r'\bK2SO4\b'), 'K2SO4'),
    ];

    for (final pair in elementFixes) {
      s = s.replaceAll(pair.$1, pair.$2);
    }

    // 3. OCR number 1 vs letter l in specific elements:
    // C12 -> Cl2 (in chlorine context)
    s = s.replaceAllMapped(RegExp(r'\bC12\b'), (m) => 'Cl2');
    s = s.replaceAllMapped(RegExp(r'\bC1-\b'), (m) => 'Cl-');

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

    // Handle bracketed coordination complexes e.g. [Fe(CN)6]
    s = s.replaceAllMapped(RegExp(r'\[([A-Za-z0-9\(\)]+)\](\d*)'), (m) {
      final inside = m.group(1)!;
      final outerDigits = m.group(2)!;

      final formattedInside = inside.replaceAllMapped(RegExp(r'\d+'), (d) {
        return d.group(0)!.split('').map((c) => _subscriptMap[c] ?? c).join();
      });
      final formattedOuter = outerDigits.split('').map((c) => _subscriptMap[c] ?? c).join();

      return '[$formattedInside]$formattedOuter';
    });

    return s;
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
