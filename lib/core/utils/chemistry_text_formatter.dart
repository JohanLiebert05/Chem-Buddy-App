/// Universal, chemistry-aware formatter and sanitizer that transforms raw AI output,
/// LaTeX macros, ASCII math, and chemical equations into clean, readable textbook Unicode.
///
/// Preserves legitimate chemistry notation (subscripts, superscripts, ionic charges,
/// Greek letters, reaction arrows, equilibrium symbols, partial charges, and scientific math)
/// while strictly stripping decorative noise, unwanted separators, and prompt instruction leaks.
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

  /// Main public entry point: sanitizes and formats any chemistry text or AI response.
  static String format(String? raw) => sanitizeChemistryResponse(raw);

  /// Public converter: converts any LaTeX math expression or equation to a clean,
  /// formatted Unicode mathematical representation with zero raw TeX commands.
  static String toUnicodeMath(String? expr) {
    if (expr == null || expr.isEmpty) return '';
    var s = expr.trim();
    if (s.startsWith(r'$$') && s.endsWith(r'$$') && s.length >= 4) {
      s = s.substring(2, s.length - 2).trim();
    } else if (s.startsWith(r'\[') && s.endsWith(r'\]') && s.length >= 4) {
      s = s.substring(2, s.length - 2).trim();
    } else if (s.startsWith(r'$') && s.endsWith(r'$') && s.length >= 2) {
      s = s.substring(1, s.length - 1).trim();
    }
    return _cleanMathExpression(s);
  }

  /// Comprehensive chemistry-aware sanitization pipeline.

  /// IMPORTANT: Preserves $...$ and $$...$$ delimiters so ChemistryMarkdownView
  /// can pass them to flutter_math_fork for native KaTeX rendering.
  static String sanitizeChemistryResponse(String? raw) {
    if (raw == null || raw.isEmpty) return '';

    var text = raw;

    // 1. Remove internal AI prompt instruction leaks
    text = _removePromptInstructions(text);

    // 2. Normalize malformed headings and strip decorative dot/separator noise
    text = _stripDecorativeNoise(text);

    // 3. Normalize \[...\] display math → $$...$$ (preserve KaTeX delimiters)
    text = text.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]', dotAll: true), (m) {
      final inner = (m[1] ?? '').trim();
      return '\n\$\$$inner\$\$\n';
    });

    // 4. Normalize \(...\) inline math → $...$ (preserve KaTeX delimiters)
    text = text.replaceAllMapped(RegExp(r'\\\(([^\)]+?)\\\)'), (m) {
      final inner = (m[1] ?? '').trim();
      return '\$$inner\$';
    });

    // 5. IMPORTANT: Do NOT strip $...$ or $$...$$ — leave them for the renderer.
    // Only clean LaTeX in plaintext regions (outside math delimiters).
    text = _cleanLatexInPlainTextRegions(text);

    // 6. Normalize chemical notation, equations, arrows, charges, and formulas
    // Only outside of LaTeX math blocks to avoid corrupting formulas.
    text = _normalizeChemistryInPlainTextRegions(text);

    // 7. Normalize Markdown headings, lists, and spacing
    text = _normalizeMarkdownStructure(text);

    return text.trim();
  }

  /// Cleans LaTeX macros ONLY in plain-text regions outside of $...$ and $$...$$ blocks.
  static String _cleanLatexInPlainTextRegions(String input) {
    return _processOutsideMathDelimiters(input, _cleanMathExpression);
  }

  /// Normalizes chemistry typography ONLY in plain-text regions outside math blocks.
  static String _normalizeChemistryInPlainTextRegions(String input) {
    return _processOutsideMathDelimiters(input, _normalizeChemistryTypography);
  }

  /// Splits input at math delimiters, applies [fn] to non-math segments, and reassembles.
  static String _processOutsideMathDelimiters(String input, String Function(String) fn) {
    final result = StringBuffer();
    final pattern = RegExp(r'\$\$[\s\S]*?\$\$|\$[^\$\n]+?\$', dotAll: false);
    var lastEnd = 0;
    for (final match in pattern.allMatches(input)) {
      // Apply fn to the plain-text segment before this math block
      if (match.start > lastEnd) {
        result.write(fn(input.substring(lastEnd, match.start)));
      }
      // Copy the math block verbatim — do not transform it
      result.write(match[0]);
      lastEnd = match.end;
    }
    // Apply fn to trailing plain-text after last math block
    if (lastEnd < input.length) {
      result.write(fn(input.substring(lastEnd)));
    }
    return result.toString();
  }



  // =========================================================================
  // 1. PROMPT LEAK REMOVAL
  // =========================================================================

  static String _removePromptInstructions(String input) {
    var s = input;
    // Remove full instruction lines matching [Format as...]: query
    s = s.replaceAll(
      RegExp(r'^\[\s*(?:Format as a structured|Give me only|Principle, Reaction|Instruction:|Note for AI|Guidelines:|MSc Chemistry Answer Format|Exam Format|Mark Distribution).*?\]:?.*?\n', caseSensitive: false, multiLine: true),
      '',
    );
    s = s.replaceAll(
      RegExp(r'^\[(?:2|5|10)\s*[-–]?\s*Mark\s*(?:Answer|Format|MSc).*?\]:?.*?\n', caseSensitive: false, multiLine: true),
      '',
    );
    // Remove standalone bracketed instructions anywhere
    s = s.replaceAll(
      RegExp(r'\[\s*(?:Format as a structured|Give me only|Principle, Reaction|Instruction:|Note for AI|Guidelines:|MSc Chemistry Answer Format|Exam Format|Mark Distribution).*?\]:?', caseSensitive: false),
      '',
    );
    s = s.replaceAll(
      RegExp(r'\[(?:2|5|10)\s*[-–]?\s*Mark\s*(?:Answer|Format|MSc).*?\]:?', caseSensitive: false),
      '',
    );
    // Remove prefix system instructions
    s = s.replaceAll(
      RegExp(r'^(?:System Prompt|Assistant Prompt|Format Instruction|CRITICAL INSTRUCTION):?.*?\n', caseSensitive: false, multiLine: true),
      '',
    );
    return s;
  }

  // =========================================================================
  // 2. DECORATIVE NOISE STRIPPING & HEADING NORMALIZATION
  // =========================================================================

  static String _stripDecorativeNoise(String input) {
    var s = input;

    // Convert decorative framed lines to standard Markdown headings line by line
    final lines = s.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check if line starts and ends with decorative characters: ·, •, ▪, ◆, ⋯, ∶, :, -, *, ~, =
      if (RegExp(r'^[·•▪◆⋯∶:\-\*~=\s]+').hasMatch(trimmed) && RegExp(r'[·•▪◆⋯∶:\-\*~=\s]+$').hasMatch(trimmed)) {
        final textOnly = trimmed
            .replaceAll(RegExp(r'^[·•▪◆⋯∶:\-\*~=\s]+'), '')
            .replaceAll(RegExp(r'[·•▪◆⋯∶:\-\*~=\s]+$'), '')
            .trim();
        if (textOnly.isNotEmpty && textOnly.length >= 3 && textOnly.length < 70 && !textOnly.contains('.')) {
          lines[i] = '### $textOnly';
        }
      }
    }
    s = lines.join('\n');

    // Remove repeated decorative dot clusters: "· · ·", "⋯ ⋯ ⋯", "⋯", "∶ ∶", "•••", ":::", ". . .", "····"
    s = s.replaceAll(RegExp(r'(?:[·•▪◆]\s*){3,}'), '');
    s = s.replaceAll(RegExp(r'(?:⋯\s*)+'), '');
    s = s.replaceAll(RegExp(r'(?:\.\s*){4,}'), '');
    s = s.replaceAll(RegExp(r'(?:∶\s*){2,}'), ':');
    s = s.replaceAll(RegExp(r'(?::{3,})'), '');

    // Remove inline or trailing stray markdown hashes (e.g. "R-COO⁻ ####", "Reaction ### Dis...")
    s = s.replaceAll(RegExp(r'(?<=[^\s#\n])[ \t]*#{1,6}[ \t]*(?=[^\s#\n]|$)'), ' ');
    s = s.replaceAll(RegExp(r'(?<=[^\s#\n])[ \t]*#{1,6}[ \t]*$', multiLine: true), '');

    // Normalize 4+ hashes at line starts to standard h3 ###
    s = s.replaceAllMapped(RegExp(r'^(?:[ \t]*)#{4,}\s*', multiLine: true), (m) => '### ');

    // Remove decorative separator lines: "---", "***", "___", "━━━", "───", "┈┈┈"
    s = s.replaceAll(RegExp(r'^[ \t]*[-*_—━─~┈·•]{3,}[ \t]*$', multiLine: true), '');

    return s;
  }

  // =========================================================================
  // 3. LATEX & MATH CLEANUP
  // =========================================================================

  static String _cleanMathExpression(String expr) {
    var s = expr;

    // Remove LaTeX text wrappers: \text{...}, \mathrm{...}, \mathbf{...}, \mathit{...}
    s = s.replaceAllMapped(RegExp(r'\\(?:text|mathrm|mathbf|mathit|boldsymbol|operatorname)\{([^}]*)\}'), (m) => m[1] ?? '');

    // Arrow with conditions: \xrightarrow[\text{below}]{\text{above}} -> [above] →
    s = s.replaceAllMapped(RegExp(r'\\xrightarrow(?:\[([^\]]*)\])?\{([^}]*)\}'), (m) {
      final above = _cleanMathExpression(m[2]?.trim() ?? '');
      final below = m[1] != null ? ' (${_cleanMathExpression(m[1]!.trim())})' : '';
      if (above.isNotEmpty) {
        return ' ─[$above$below]→ ';
      }
      return ' → ';
    });

    // Common fractions: \frac{a}{b} -> a/b or (a)/(b)
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

    // Specific combined chemistry variables
    s = s.replaceAll(RegExp(r'\\Delta\s*\\rho|\\Delta\s*rho|delta_rho', caseSensitive: false), 'Δρ');
    s = s.replaceAll(RegExp(r'\\Delta\s*G|delta_G', caseSensitive: false), 'ΔG');
    s = s.replaceAll(RegExp(r'\\Delta\s*H|delta_H', caseSensitive: false), 'ΔH');
    s = s.replaceAll(RegExp(r'\\Delta\s*S|delta_S', caseSensitive: false), 'ΔS');
    s = s.replaceAll(RegExp(r'\\Delta\s*E|delta_E', caseSensitive: false), 'ΔE');
    s = s.replaceAll(RegExp(r'\\Delta\s*T|delta_T', caseSensitive: false), 'ΔT');
    s = s.replaceAll(RegExp(r'\\Delta\b'), 'Δ');
    s = s.replaceAll(RegExp(r'h\\nu|hnu\b', caseSensitive: false), 'hν');

    // Collapse spaces around Greek letters: "Δ G" -> "ΔG", "T ΔS" -> "TΔS", "Δ H" -> "ΔH"
    s = s.replaceAllMapped(RegExp(r'([ΔδΑαΒβΓγΕεΖζΗηΘθΙιΚκΛλΜμΝνΞξΠπΡρΣσΤτΥυΦφΧχΨψΩω])\s+([A-Za-z0-9])'), (m) => '${m[1]}${m[2]}');
    s = s.replaceAllMapped(RegExp(r'([A-Za-z0-9])\s+([ΔδΑαΒβΓγΕεΖζΗηΘθΙιΚκΛλΜμΝνΞξΠπΡρΣσΤτΥυΦφΧχΨψΩω])'), (m) => '${m[1]}${m[2]}');

    // Operators and Symbols
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
    s = s.replaceAll(r'\leftrightarrow', '↔');
    s = s.replaceAll(r'\uparrow', '↑');
    s = s.replaceAll(r'\downarrow', '↓');

    // Handle braces around superscripts and subscripts
    s = s.replaceAllMapped(RegExp(r'\^\{([^}]+)\}'), (m) => _toSuperscript(m[1] ?? ''));
    s = s.replaceAllMapped(RegExp(r'_\{([^}]+)\}'), (m) => _toSubscript(m[1] ?? ''));

    // Handle naked superscripts and subscripts (without curly braces: ^-, ^+, ^2-, ^3+, ^2, _2)
    s = s.replaceAllMapped(RegExp(r'\^([0-9]*[-+−])'), (m) => _toSuperscript(m[1] ?? ''));
    s = s.replaceAllMapped(RegExp(r'\^([0-9a-zA-Z]+)'), (m) => _toSuperscript(m[1] ?? ''));
    s = s.replaceAllMapped(RegExp(r'_([0-9a-zA-Z]+)'), (m) => _toSubscript(m[1] ?? ''));

    // Remove only truly invalid/noise LaTeX commands (NOT valid KaTeX macros like \log, \ln, \sin, \left, \right)
    // Safe to strip: display-only structure wrappers that have no Unicode equivalent
    s = s.replaceAll(r'\displaystyle', '');
    s = s.replaceAll(r'\textstyle', '');
    s = s.replaceAll(r'\scriptstyle', '');
    s = s.replaceAll(r'\scriptscriptstyle', '');
    s = s.replaceAll(r'\normalsize', '');
    s = s.replaceAll(r'\small', '');
    s = s.replaceAll(r'\large', '');
    s = s.replaceAll(r'\Large', '');
    s = s.replaceAll(r'\LARGE', '');
    s = s.replaceAll(r'\huge', '');
    s = s.replaceAll(r'\Huge', '');
    s = s.replaceAll(r'\noindent', '');
    s = s.replaceAll(r'\hspace{', '');
    s = s.replaceAll(r'\vspace{', '');
    s = s.replaceAll(r'\quad', ' ');
    s = s.replaceAll(r'\qquad', '  ');
    s = s.replaceAll(r'\,', ' ');
    s = s.replaceAll(r'\;', ' ');
    s = s.replaceAll(r'\:', ' ');
    s = s.replaceAll(r'\!', '');
    // Strip \left and \right bracket modifiers (keep the bracket itself)
    s = s.replaceAll(r'\left(', '(');
    s = s.replaceAll(r'\right)', ')');
    s = s.replaceAll(r'\left[', '[');
    s = s.replaceAll(r'\right]', ']');
    s = s.replaceAll(r'\left\{', '{');
    s = s.replaceAll(r'\right\}', '}');
    s = s.replaceAll(r'\left|', '|');
    s = s.replaceAll(r'\right|', '|');
    s = s.replaceAll(r'\left.', '');
    s = s.replaceAll(r'\right.', '');
    // Preserve \log, \ln, \sin, \cos, \tan etc. by converting to plain text
    s = s.replaceAll(r'\log_{10}', 'log₁₀');
    s = s.replaceAll(r'\log_{e}', 'ln');
    s = s.replaceAll(r'\log', 'log');
    s = s.replaceAll(r'\ln', 'ln');
    s = s.replaceAll(r'\exp', 'exp');
    s = s.replaceAll(r'\sin', 'sin');
    s = s.replaceAll(r'\cos', 'cos');
    s = s.replaceAll(r'\tan', 'tan');
    s = s.replaceAll(r'\cot', 'cot');
    s = s.replaceAll(r'\sec', 'sec');
    s = s.replaceAll(r'\csc', 'csc');
    s = s.replaceAll(r'\min', 'min');
    s = s.replaceAll(r'\max', 'max');
    s = s.replaceAll(r'\lim', 'lim');
    // Strip remaining unknown backslash commands (noise only — after all valid ones handled above)
    s = s.replaceAll(RegExp(r'\\(?![$\\])([a-zA-Z]+)\{'), r'\{'); // \cmd{ → { for bracket preservation
    s = s.replaceAll(RegExp(r'\\(?![$\\])[a-zA-Z]+\b'), '');
    s = s.replaceAll(r'\', '');
    s = s.replaceAll(r'$$', '').replaceAll(r'$', '');

    return s.trim();
  }

  // =========================================================================
  // 4. CHEMISTRY TYPOGRAPHY & FORMULAS
  // =========================================================================

  static String _normalizeChemistryTypography(String input) {
    var s = input;

    // Partial charges and nucleophiles
    s = s.replaceAll(RegExp(r'\bdelta\s*\+|\bdelta\(\+\)', caseSensitive: false), 'δ⁺');
    s = s.replaceAll(RegExp(r'\bdelta\s*[-−]|\bdelta\([-−]\)', caseSensitive: false), 'δ⁻');
    s = s.replaceAllMapped(RegExp(r'(^|[^\w])Nu\s*(?:[-−]|\^[-−]|\^\{[-−]\})(?=[^\w]|$)'), (m) => '${m[1]}Nu⁻');
    s = s.replaceAllMapped(RegExp(r'(^|[^\w])E\s*(?:\+|\^\+|\^\{\+\})(?=[^\w]|$)'), (m) => '${m[1]}E⁺');

    // Arrows and Equilibrium
    s = s.replaceAll(RegExp(r'\s*-->\s*|\s*->\s*|\s*⟶\s*'), ' → ');
    s = s.replaceAll(RegExp(r'\s*<--\s*|\s*<-\s*|\s*⟵\s*'), ' ← ');
    s = s.replaceAll(RegExp(r'\s*<=>\s*|\s*<->\s*|\s*<==>\s*|\s*⟷\s*'), ' ⇌ ');
    s = s.replaceAll(RegExp(r'\s*<=\s*'), ' ≤ ');
    s = s.replaceAll(RegExp(r'\s*>=\s*'), ' ≥ ');
    s = s.replaceAll(RegExp(r'\s*\+-\s*'), ' ± ');

    // Greek letters in text
    s = s.replaceAll(RegExp(r'\balpha(?=[ \-_A-Za-z])', caseSensitive: false), 'α');
    s = s.replaceAll(RegExp(r'\bbeta(?=[ \-_A-Za-z])', caseSensitive: false), 'β');
    s = s.replaceAll(RegExp(r'\bgamma(?=[ \-_A-Za-z])', caseSensitive: false), 'γ');

    // Chemical Ion Charges & Explicit Superscripts: SO4^2-, SO4 2-, Fe3+, Fe2+, Cu2+, etc.
    s = s.replaceAll(RegExp(r'SO4\s*\^\s*\{?2[-−]\}?|SO4\s*²[-−]|SO4\^2[-−]'), 'SO₄²⁻');
    s = s.replaceAll(RegExp(r'PO4\s*\^\s*\{?3[-−]\}?|PO4\s*³[-−]|PO4\^3[-−]'), 'PO₄³⁻');
    s = s.replaceAll(RegExp(r'CO3\s*\^\s*\{?2[-−]\}?|CO3\s*²[-−]|CO3\^2[-−]'), 'CO₃²⁻');
    s = s.replaceAll(RegExp(r'NO3\s*\^\s*\{?[-−]\}?|NO3\^-'), 'NO₃⁻');
    s = s.replaceAll(RegExp(r'NH4\s*\^\s*\{?\+\}?|NH4\^\+'), 'NH₄⁺');
    s = s.replaceAll(RegExp(r'Fe\s*\^\s*\{?3\+\}?|Fe\s*³\+|Fe\^3\+'), 'Fe³⁺');
    s = s.replaceAll(RegExp(r'Fe\s*\^\s*\{?2\+\}?|Fe\s*²\+|Fe\^2\+'), 'Fe²⁺');
    s = s.replaceAll(RegExp(r'Cu\s*\^\s*\{?2\+\}?|Cu\s*²\+|Cu\^2\+'), 'Cu²⁺');
    s = s.replaceAll(RegExp(r'Cu\s*\^\s*\{?\+\}?|Cu\^\+'), 'Cu⁺');
    s = s.replaceAll(RegExp(r'Al\s*\^\s*\{?3\+\}?|Al\s*³\+|Al\^3\+'), 'Al³⁺');
    s = s.replaceAll(RegExp(r'Ca\s*\^\s*\{?2\+\}?|Ca\s*²\+|Ca\^2\+'), 'Ca²⁺');
    s = s.replaceAll(RegExp(r'Mg\s*\^\s*\{?2\+\}?|Mg\s*²\+|Mg\^2\+'), 'Mg²⁺');
    s = s.replaceAll(RegExp(r'Zn\s*\^\s*\{?2\+\}?|Zn\s*²\+|Zn\^2\+'), 'Zn²⁺');
    s = s.replaceAll(RegExp(r'Ba\s*\^\s*\{?2\+\}?|Ba\s*²\+|Ba\^2\+'), 'Ba²⁺');
    s = s.replaceAll(RegExp(r'Na\s*\^\s*\{?\+\}?|Na\^\+'), 'Na⁺');
    s = s.replaceAll(RegExp(r'K\s*\^\s*\{?\+\}?|K\^\+'), 'K⁺');
    s = s.replaceAll(RegExp(r'Ag\s*\^\s*\{?\+\}?|Ag\^\+'), 'Ag⁺');
    s = s.replaceAll(RegExp(r'Cl\s*\^\s*\{?[-−]\}?|Cl\^-'), 'Cl⁻');
    s = s.replaceAll(RegExp(r'Br\s*\^\s*\{?[-−]\}?|Br\^-'), 'Br⁻');
    s = s.replaceAll(RegExp(r'I\s*\^\s*\{?[-−]\}?|I\^-'), 'I⁻');
    s = s.replaceAll(RegExp(r'F\s*\^\s*\{?[-−]\}?|F\^-'), 'F⁻');

    // Standalone H+ and OH- matching
    s = s.replaceAllMapped(RegExp(r'(^|[^\w])H\s*(?:\+|\^\+|\^\{\+\})(?=[^\w]|$)'), (m) => '${m[1]}H⁺');
    s = s.replaceAllMapped(RegExp(r'(^|[^\w])OH\s*(?:[-−]|\^[-−]|\^\{[-−]\})(?=[^\w]|$)'), (m) => '${m[1]}OH⁻');

    // Standalone common ions written without caret when separated:
    // e.g. "Fe2+", "Fe3+", "Ba2+", "Ca2+", "Cu2+", "Al3+"
    s = s.replaceAllMapped(RegExp(r'\b(Fe|Cu|Al|Ca|Ba|Mg|Zn|Na|K|Ag)(2\+|3\+|\+)(?=[^\w]|\$)'), (m) {
      final metal = m[1]!;
      final charge = m[2]!;
      return '$metal${_toSuperscript(charge)}';
    });

    // General explicit ions matching: e.g. M^{n+}, X^{n-}
    s = s.replaceAllMapped(RegExp(r'([A-Za-z0-9\u2080-\u2089\)]+)\^\{?([0-9]?[+\-−])\}?'), (m) {
      return '${m[1]}${_toSuperscript(m[2] ?? '')}';
    });

    // Subscripts in explicit formulas: H_2SO_4 -> H₂SO₄
    s = s.replaceAllMapped(RegExp(r'([A-Za-z\(\)])_\{?([0-9a-z\+\-]+)\}?'), (m) {
      return '${m[1]}${_toSubscript(m[2] ?? '')}';
    });

    // Authoritative chemical formula dictionary
    s = _applyChemicalDictionary(s);

    // Multi-element formula subscripts: e.g. C6H5CHO -> C₆H₅CHO, CH3COOH -> CH₃COOH
    s = s.replaceAllMapped(
      RegExp(r'([A-Z][a-z]?|\))(\d+)'),
      (m) {
        final elem = m[1]!;
        final num = m[2]!;
        // Protect non-chemical acronyms with numbers
        if (elem == 'SN' || elem == 'UV' || elem == 'IC' || elem == 'EC' || elem == 'LD' || elem == 'pH' || elem == 'E') {
          return m[0]!;
        }
        return '$elem${_toSubscript(num)}';
      },
    );

    // Ensure spaces around reaction plus signs: " + "
    s = s.replaceAllMapped(RegExp(r'([A-Za-z0-9\u2070-\u209f\)])\+([A-Za-z0-9\u2070-\u209f\(])'), (m) => '${m[1]} + ${m[2]}');

    return s;
  }

  static String _applyChemicalDictionary(String text) {
    const formulaMap = {
      'H2SO4': 'H₂SO₄',
      'HNO3': 'HNO₃',
      'H3PO4': 'H₃PO₄',
      'HClO4': 'HClO₄',
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
      'NH4': 'NH₄',
      'CH4': 'CH₄',
      'C2H6': 'C₂H₆',
      'C2H4': 'C₂H₄',
      'C2H2': 'C₂H₂',
      'C6H6': 'C₆H₆',
      'C6H12O6': 'C₆H₁₂O₆',
      'CH3COOH': 'CH₃COOH',
      'CH3COONa': 'CH₃COONa',
      'CH3COOK': 'CH₃COOK',
      'CH3CHO': 'CH₃CHO',
      'CH3OH': 'CH₃OH',
      'C2H5OH': 'C₂H₅OH',
      'CH3COOC2H5': 'CH₃COOC₂H₅',
      'C6H5CHO': 'C₆H₅CHO',
      'C6H5COOH': 'C₆H₅COOH',
      'C6H5COONa': 'C₆H₅COONa',
      'C6H5COOK': 'C₆H₅COOK',
      'C6H5CH2OH': 'C₆H₅CH₂OH',
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
      '1H NMR': '¹H NMR',
      '13C NMR': '¹³C NMR',
      'D2O': 'D₂O',
      'R-CHO': 'R-CHO',
      'R-COOH': 'R-COOH',
      'R-COONa': 'R-COONa',
      'R-COOK': 'R-COOK',
      'R-CH2OH': 'R-CH₂OH',
      'R-CH2O-': 'R-CH₂O⁻',
      'R-CH2O^-': 'R-CH₂O⁻',
      'R-COO-': 'R-COO⁻',
      'R-COO^-': 'R-COO⁻',
      'R-CH(O-)(OH)': 'R-CH(O⁻)(OH)',
      'R-CH(O^-)(OH)': 'R-CH(O⁻)(OH)',
    };

    var res = text;
    formulaMap.forEach((plain, formatted) {
      res = res.replaceAllMapped(
        RegExp('(^|[^A-Za-z])(${RegExp.escape(plain)})(?=[^A-Za-z0-9]|\$)', multiLine: true),
        (m) => '${m[1]}$formatted',
      );
    });

    return res;
  }

  // =========================================================================
  // 5. MARKDOWN STRUCTURE NORMALIZATION
  // =========================================================================

  static String _normalizeMarkdownStructure(String input) {
    var s = input;

    // Clean redundant bold markup inside headings:
    // "### **Definition**" -> "### Definition"
    // "#### **1. Principle**" -> "### Principle"
    s = s.replaceAllMapped(
      RegExp(r'^(#{1,6})\s*\*\*+(?:\d+[\.\)]\s*)?([^*]+?)\*\*+:?[ \t]*$', multiLine: true),
      (m) => '${m[1]} ${m[2]?.trim()}',
    );

    // Clean single colon or period at the end of Markdown headings
    s = s.replaceAllMapped(
      RegExp(r'^(#{1,6}\s+[^:\n]+):[ \t]*$', multiLine: true),
      (m) => '${m[1]?.trim()}',
    );

    // Ensure chemical equations on standalone lines have clear vertical breathing room
    s = s.replaceAllMapped(
      RegExp(r'^[ \t]*([0-9A-Za-z\u2070-\u209f\(\)\+\-· \t]+[→⇌][0-9A-Za-z\u2070-\u209f\(\)\+\-· \t]+)[ \t]*$', multiLine: true),
      (m) => '${m[1]?.trim()}',
    );

    // Collapse multiple consecutive blank lines to at most two
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return s;
  }

  static String _toSubscript(String s) {
    return s.split('').map((c) => _subscripts[c] ?? c).join();
  }

  static String _toSuperscript(String s) {
    return s.split('').map((c) => _superscripts[c] ?? c).join();
  }
}
