/// Universal formatter that transforms raw LaTeX, ASCII math, and chemical equations
/// into clean, readable Unicode notation that looks like a printed chemistry textbook.
class ChemistryTextFormatter {
  ChemistryTextFormatter._();

  static const Map<String, String> _greekMap = {
    r'\Alpha': 'Α', r'\alpha': 'α',
    r'\Beta': 'Β', r'\beta': 'β',
    r'\Gamma': 'Γ', r'\gamma': 'γ',
    r'\Delta': 'Δ', r'\delta': 'δ',
    r'\Epsilon': 'Ε', r'\epsilon': 'ε', r'\varepsilon': 'ε',
    r'\Zeta': 'Ζ', r'\zeta': 'ζ',
    r'\Eta': 'Η', r'\eta': 'η',
    r'\Theta': 'Θ', r'\theta': 'θ', r'\vartheta': 'θ',
    r'\Iota': 'Ι', r'\iota': 'ι',
    r'\Kappa': 'Κ', r'\kappa': 'κ',
    r'\Lambda': 'Λ', r'\lambda': 'λ',
    r'\Mu': 'Μ', r'\mu': 'μ',
    r'\Nu': 'Ν', r'\nu': 'ν',
    r'\Xi': 'Ξ', r'\xi': 'ξ',
    r'\Pi': 'Π', r'\pi': 'π',
    r'\Rho': 'Ρ', r'\rho': 'ρ',
    r'\Sigma': 'Σ', r'\sigma': 'σ',
    r'\Tau': 'Τ', r'\tau': 'τ',
    r'\Upsilon': 'Υ', r'\upsilon': 'υ',
    r'\Phi': 'Φ', r'\phi': 'φ', r'\varphi': 'φ',
    r'\Chi': 'Χ', r'\chi': 'χ',
    r'\Psi': 'Ψ', r'\psi': 'ψ',
    r'\Omega': 'Ω', r'\omega': 'ω',
  };

  static const Map<String, String> _subscripts = {
    '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
    '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
    '+': '₊', '-': '₋', '=': '₌', '(': '₍', ')': '₎',
    'a': 'ₐ', 'e': 'ₑ', 'h': 'ₕ', 'i': 'ᵢ', 'j': 'ⱼ',
    'k': 'ₖ', 'l': 'ₗ', 'm': 'ₘ', 'n': 'ₙ', 'o': 'ₒ',
    'p': 'ₚ', 'r': 'ᵣ', 's': 'ₛ', 't': 'ₜ', 'u': 'ᵤ',
    'v': 'ᵥ', 'x': 'ₓ',
  };

  static const Map<String, String> _superscripts = {
    '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
    '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
    '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽', ')': '⁾',
    'n': 'ⁿ', 'i': 'ⁱ', 'x': 'ˣ', 'y': 'ʸ', 't': 'ᵗ',
    'a': 'ᵃ', 'b': 'ᵇ', 'c': 'ᶜ', 'd': 'ᵈ', 'e': 'ᵉ',
  };

  /// Main formatting function applied to all AI responses and chemistry cards.
  static String format(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    var text = raw;

    // 1. Convert display math blocks: $$...$$ or \[...\]
    text = text.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$|\\\[(.*?)\\\]', dotAll: true), (m) {
      final inner = (m[1] ?? m[2] ?? '').trim();
      return '\n${_cleanMathExpression(inner)}\n';
    });

    // 2. Convert inline math blocks: $...$ or \(...\)
    text = text.replaceAllMapped(RegExp(r'\$([^\$\n]+?)\$|\\\(([^\)]+?)\\\)'), (m) {
      final inner = (m[1] ?? m[2] ?? '').trim();
      return _cleanMathExpression(inner);
    });

    // 3. Process remaining LaTeX macros (like \frac, \sqrt, \Delta, \times without $)
    text = _cleanMathExpression(text);

    // 4. Process text-level formulas, arrows, variables
    text = _cleanTextLevelMath(text);

    return text;
  }

  static String _cleanMathExpression(String expr) {
    var s = expr;

    // Remove LaTeX text wrappers: \text{...}, \mathrm{...}, \mathbf{...}, \mathit{...}
    s = s.replaceAllMapped(RegExp(r'\\(?:text|mathrm|mathbf|mathit|boldsymbol|operatorname)\{([^}]*)\}'), (m) => m[1] ?? '');

    // Common fractions: \frac{a}{b} -> (a) / (b)
    s = s.replaceAllMapped(RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'), (m) {
      final num = m[1]?.trim() ?? '';
      final den = m[2]?.trim() ?? '';
      final cleanNum = _cleanMathExpression(num);
      final cleanDen = _cleanMathExpression(den);
      if (cleanNum.length <= 4 && !cleanNum.contains(' ') && cleanDen.length <= 4 && !cleanDen.contains(' ')) {
        return '$cleanNum/$cleanDen';
      }
      return '($cleanNum) / ($cleanDen)';
    });

    // Square roots: \sqrt[n]{x} -> ⁿ√(x) or \sqrt{x} -> √(x)
    s = s.replaceAllMapped(RegExp(r'\\sqrt\[([^\]]*)\]\{([^}]*)\}'), (m) => '${_toSuperscript(m[1] ?? '')}√(${m[2] ?? ''})');
    s = s.replaceAllMapped(RegExp(r'\\sqrt\{([^}]*)\}'), (m) => '√(${m[1] ?? ''})');

    // LaTeX Greek replacements
    _greekMap.forEach((k, v) => s = s.replaceAll(k, v));

    // Collapse LaTeX command delimiter spaces after Greek letters: "\Delta G" -> "Δ G" -> "ΔG"
    s = s.replaceAllMapped(RegExp(r'([ΔδΑαΒβΓγΕεΖζΗηΘθΙιΚκΛλΜμΝνΞξΠπΡρΣσΤτΥυΦφΧχΨψΩω])\s+([A-Za-z0-9])'), (m) => '${m[1]}${m[2]}');

    // Specific combined chemistry variables
    s = s.replaceAll(RegExp(r'\\Delta\s*\\rho|\\Delta\s*rho|delta_rho', caseSensitive: false), 'Δρ');
    s = s.replaceAll(RegExp(r'\\Delta\s*G|delta_G', caseSensitive: false), 'ΔG');
    s = s.replaceAll(RegExp(r'\\Delta\s*H|delta_H', caseSensitive: false), 'ΔH');
    s = s.replaceAll(RegExp(r'\\Delta\s*S|delta_S', caseSensitive: false), 'ΔS');
    s = s.replaceAll(RegExp(r'\\Delta\s*E|delta_E', caseSensitive: false), 'ΔE');
    s = s.replaceAll(RegExp(r'\\Delta\s*T|delta_T', caseSensitive: false), 'ΔT');
    s = s.replaceAll(RegExp(r'\\Delta|delta(?=[\s\-_A-Za-z])', caseSensitive: false), 'Δ');
    s = s.replaceAll(RegExp(r'\beta(?=[\s\-_A-Za-z])', caseSensitive: false), 'β');

    // LaTeX Operators and Symbols
    s = s.replaceAll(r'\times', '×');
    s = s.replaceAll(r'\cdot', '·');
    s = s.replaceAll(r'\approx', '≈');
    s = s.replaceAll(r'\sim', '~');
    s = s.replaceAll(r'\neq', '≠');
    s = s.replaceAll(r'\pm', '±');
    s = s.replaceAll(r'\mp', '∓');
    s = s.replaceAll(r'\leq', '≤');
    s = s.replaceAll(r'\le', '≤');
    s = s.replaceAll(r'\geq', '≥');
    s = s.replaceAll(r'\ge', '≥');
    s = s.replaceAll(r'\infty', '∞');
    s = s.replaceAll(r'\degree', '°');
    s = s.replaceAll(r'^\circ', '°');
    s = s.replaceAll(r'\circ', '°');
    s = s.replaceAll(r'\partial', '∂');
    s = s.replaceAll(r'\int', '∫');
    s = s.replaceAll(r'\sum', '∑');
    s = s.replaceAll(r'\prod', '∏');
    s = s.replaceAll(r'\rightarrow', '→');
    s = s.replaceAll(r'\leftarrow', '←');
    s = s.replaceAll(r'\rightleftharpoons', '⇌');
    s = s.replaceAll(r'\uparrow', '↑');
    s = s.replaceAll(r'\downarrow', '↓');

    // Handle braces around superscripts and subscripts
    s = s.replaceAllMapped(RegExp(r'\^\{([^}]+)\}'), (m) => _toSuperscript(m[1] ?? ''));
    s = s.replaceAllMapped(RegExp(r'_\{([^}]+)\}'), (m) => _toSubscript(m[1] ?? ''));

    // Handle single-char superscripts and subscripts
    s = s.replaceAllMapped(RegExp(r'\^([0-9\+\-nix])'), (m) => _toSuperscript(m[1] ?? ''));
    s = s.replaceAllMapped(RegExp(r'_([0-9a-z\+\-])'), (m) => _toSubscript(m[1] ?? ''));

    // Numbers multiplied by variables: "2 * r^2" -> "2r²", "9 * eta" -> "9η"
    s = s.replaceAllMapped(RegExp(r'(\d+)\s*\*\s*([a-zA-Z\u0370-\u03ff\u2070-\u209f])'), (m) => '${m[1]}${m[2]}');

    // Clean remaining multiplication stars between variables/expressions: "r² * Δρ * g" -> "r² · Δρ · g"
    s = s.replaceAllMapped(RegExp(r'([a-zA-Z\u0370-\u03ff\u2070-\u209f²³⁴⁵⁶⁷⁸⁹⁺⁻\)])\s*\*\s*([a-zA-Z\u0370-\u03ff\u2070-\u209f\(])'), (m) => '${m[1]} · ${m[2]}');
    s = s.replaceAll(RegExp(r'\s*\*\s*'), ' · ');

    // Remove remaining stray backslashes from unrecognized LaTeX commands
    s = s.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');
    s = s.replaceAll(r'\', '');

    return s.trim();
  }

  static String _cleanTextLevelMath(String input) {
    var s = input;

    // Greek word substitutions in general text
    s = s.replaceAll(RegExp(r'\bdelta_rho\b', caseSensitive: false), 'Δρ');
    s = s.replaceAll(RegExp(r'\bv_t\b', caseSensitive: false), 'vₜ');
    s = s.replaceAll(RegExp(r'\bv_0\b', caseSensitive: false), 'v₀');
    s = s.replaceAll(RegExp(r'\br\^2\b', caseSensitive: false), 'r²');
    s = s.replaceAll(RegExp(r'\br\^3\b', caseSensitive: false), 'r³');
    s = s.replaceAll(RegExp(r'\bx\^2\b', caseSensitive: false), 'x²');
    s = s.replaceAll(RegExp(r'\bk_1\b', caseSensitive: false), 'k₁');
    s = s.replaceAll(RegExp(r'\bk_-1\b', caseSensitive: false), 'k₋₁');
    s = s.replaceAll(RegExp(r'\bk_2\b', caseSensitive: false), 'k₂');
    s = s.replaceAll(RegExp(r'\bt_1/2\b|\bt_\{1/2\}\b', caseSensitive: false), 't½');

    // Reaction and relation arrows in plain text
    s = s.replaceAll(RegExp(r'\s*-->\s*|\s*->\s*'), ' → ');
    s = s.replaceAll(RegExp(r'\s*<--\s*|\s*<-\s*'), ' ← ');
    s = s.replaceAll(RegExp(r'\s*<=>\s*|\s*<->\s*'), ' ⇌ ');
    s = s.replaceAll(RegExp(r'\s*<=\s*'), ' ≤ ');
    s = s.replaceAll(RegExp(r'\s*>=\s*'), ' ≥ ');
    s = s.replaceAll(RegExp(r'\s*\+-\s*'), ' ± ');

    // Common LaTeX words that leak without dollar signs
    s = s.replaceAll(r'\Delta', 'Δ');
    s = s.replaceAll(r'\rho', 'ρ');
    s = s.replaceAll(r'\eta', 'η');
    s = s.replaceAll(r'\alpha', 'α');
    s = s.replaceAll(r'\beta', 'β');
    s = s.replaceAll(r'\gamma', 'γ');
    s = s.replaceAll(r'\lambda', 'λ');
    s = s.replaceAll(r'\pi', 'π');
    s = s.replaceAll(r'\sigma', 'σ');
    s = s.replaceAll(r'\omega', 'ω');
    s = s.replaceAll(r'\theta', 'θ');

    // Standalone or coefficient-attached "eta" (e.g. "9 * eta", "9eta", "eta")
    s = s.replaceAllMapped(RegExp(r'(\d*)\s*\*?\s*eta\b', caseSensitive: false), (m) => '${m[1] ?? ""}η');

    // Clean multiplication stars in math: "2 * r²" -> "2r²", "* Δρ * g" -> "· Δρ · g"
    s = s.replaceAllMapped(RegExp(r'(\d+)\s*\*\s*([a-zA-Z\u0370-\u03ff\u2070-\u209f])'), (m) => '${m[1]}${m[2]}');
    s = s.replaceAll(RegExp(r'\s*\*\s*'), ' · ');

    // Common chemical formulas with explicit underscores: H_2SO_4 -> H₂SO₄, CH_3COOH -> CH₃COOH
    s = s.replaceAllMapped(RegExp(r'([A-Za-z\(\)])_\{?([0-9a-z\+\-]+)\}?'), (m) {
      return '${m[1]}${_toSubscript(m[2] ?? '')}';
    });

    // Common chemical ions with charges: Ca^{2+} -> Ca²⁺, SO_4^{2-} -> SO₄²⁻
    s = s.replaceAllMapped(RegExp(r'([A-Za-z0-9\u2080-\u2089]+)\^\{?([0-9]?[+-])\}?'), (m) {
      return '${m[1]}${_toSuperscript(m[2] ?? '')}';
    });

    // Superscripts in braces: ^{2+} -> ²⁺
    s = s.replaceAllMapped(RegExp(r'\^\{([^}]+)\}'), (m) => _toSuperscript(m[1] ?? ''));

    // Multi-element molecular formulas and brackets: NH3 -> NH₃, C6H12O6 -> C₆H₁₂O₆, Ca(OH)2 -> Ca(OH)₂
    s = s.replaceAllMapped(
      RegExp(r'([A-Z][a-z]?|\))(\d+)'),
      (m) {
        final elem = m[1]!;
        final num = m[2]!;
        if (elem == 'SN' || elem == 'UV' || elem == 'IC' || elem == 'EC' || elem == 'LD' || elem == 'pH') return m[0]!;
        return '$elem${_toSubscript(num)}';
      },
    );

    // Clean common chemical formula patterns: H2SO4, KMnO4, CaCO3, CH3COOH, etc.
    s = _formatChemicalFormulas(s);

    return s;
  }

  static String _formatChemicalFormulas(String text) {
    // List of known molecular formula patterns to format cleanly
    const formulaMap = {
      'H2SO4': 'H₂SO₄',
      'HNO3': 'HNO₃',
      'H3PO4': 'H₃PO₄',
      'H2O': 'H₂O',
      'H2O2': 'H₂O₂',
      'CO2': 'CO₂',
      'CO3': 'CO₃',
      'SO4': 'SO₄',
      'SO3': 'SO₃',
      'SO2': 'SO₂',
      'NO3': 'NO₃',
      'NO2': 'NO₂',
      'NH3': 'NH₃',
      'NH4+': 'NH₄⁺',
      'NH4': 'NH₄',
      'CH4': 'CH₄',
      'C2H6': 'C₂H₆',
      'C2H4': 'C₂H₄',
      'C2H2': 'C₂H₂',
      'C6H6': 'C₆H₆',
      'C6H12O6': 'C₆H₁₂O₆',
      'CH3COOH': 'CH₃COOH',
      'CH3OH': 'CH₃OH',
      'C2H5OH': 'C₂H₅OH',
      'KMnO4': 'KMnO₄',
      'K2Cr2O7': 'K₂Cr₂O₇',
      'Na2CO3': 'Na₂CO₃',
      'NaHCO3': 'NaHCO₃',
      'NaCl': 'NaCl',
      'NaOH': 'NaOH',
      'KOH': 'KOH',
      'HCl': 'HCl',
      'CaCl2': 'CaCl₂',
      'CaCO3': 'CaCO₃',
      'Ca(OH)2': 'Ca(OH)₂',
      'BaSO4': 'BaSO₄',
      'Fe2O3': 'Fe₂O₃',
      'Al2O3': 'Al₂O₃',
      'CuSO4': 'CuSO₄',
      'AgNO3': 'AgNO₃',
      'Ca2+': 'Ca²⁺',
      'Fe3+': 'Fe³⁺',
      'Fe2+': 'Fe²⁺',
      'Cu2+': 'Cu²⁺',
      'Al3+': 'Al³⁺',
      'Na+': 'Na⁺',
      'K+': 'K⁺',
      'Cl-': 'Cl⁻',
      'OH-': 'OH⁻',
      'H+': 'H⁺',
    };

    var res = text;
    formulaMap.forEach((plain, formatted) {
      res = res.replaceAll(RegExp('\\b${RegExp.escape(plain)}\\b'), formatted);
    });

    return res;
  }

  static String _toSubscript(String s) {
    return s.split('').map((c) => _subscripts[c] ?? c).join();
  }

  static String _toSuperscript(String s) {
    return s.split('').map((c) => _superscripts[c] ?? c).join();
  }
}
