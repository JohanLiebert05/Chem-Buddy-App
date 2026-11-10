import 'mechanism_flow_frame.dart' show mechanismArrowMarkers;

/// Original two-dimensional reaction-center drawings used by multiple lessons.
/// R groups stand for spectator substituents of the depicted carbonyl.
abstract final class ReactionCenterDrawings {
  static String carbonylAddition(String donor) {
    final label = donor
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return _svg('''
  <text x="122" y="162" text-anchor="middle" font-size="25">Nu</text>
  <text x="122" y="205" text-anchor="middle" font-size="15">$label</text>
  <circle cx="149" cy="149" r="2.8"/><circle cx="149" cy="158" r="2.8"/>
  <text x="241" y="158" text-anchor="middle" font-size="22">+</text>
  <path d="M 377 139 L 324 190 M 404 139 L 458 190 M 385 121 V 75 M 396 121 V 75"
        fill="none" stroke="#233144" stroke-width="3" stroke-linecap="round"/>
  <text x="391" y="141" text-anchor="middle" font-size="23">C</text>
  <text x="391" y="67" text-anchor="middle" font-size="23">O</text>
  <text x="311" y="209" text-anchor="middle" font-size="20">R¹</text>
  <text x="472" y="209" text-anchor="middle" font-size="20">R²</text>
  <g id="electron-arrows" fill="none" stroke="#24435F" stroke-width="2">
    <path d="M 149 153.5 C 192 91 317 96 380 132" marker-end="url(#electron-arrow)"/>
    <path d="M 396 98 Q 435 77 403 65" marker-end="url(#electron-arrow)"/>
  </g>''');
  }

  static String enolate() => _svg('''
  <text x="104" y="144" font-size="21">Base</text>
  <circle cx="163" cy="128" r="2.6"/><circle cx="163" cy="137" r="2.6"/>
  <text x="231" y="98" font-size="22">H</text>
  <text x="313" y="194" font-size="21">Cα</text>
  <text x="470" y="105" font-size="22">O</text>
  <text x="525" y="207" font-size="19">R</text>
  <path d="M 248 103 L 320 174 M 342 183 H 479 L 519 194 M 474 182 V 113 M 484 182 V 113 M 318 199 L 290 228" fill="none" stroke="#233144" stroke-width="3"/>
  <g id="electron-arrows" fill="none" stroke="#24435F" stroke-width="2">
    <path d="M 163 132.5 Q 189 78 229 91" marker-end="url(#electron-arrow)"/>
    <path d="M 284 138.5 C 335 104 388 115 407 182" marker-end="url(#electron-arrow)"/>
    <path d="M 484 145 Q 526 119 491 103" marker-end="url(#electron-arrow)"/>
  </g>''');

  static String michael() => _svg('''
  <text x="103" y="149" font-size="23">Nu⁻</text>
  <circle cx="154" cy="132" r="2.6"/><circle cx="154" cy="141" r="2.6"/>
  <text x="218" y="183" font-size="19">Cβ</text>
  <text x="327" y="183" font-size="19">Cα</text>
  <text x="469" y="94" font-size="22">O</text>
  <text x="535" y="206" font-size="19">R</text>
  <path d="M 247 168 H 320 M 247 178 H 320 M 355 173 H 478 L 528 194 M 473 172 V 103 M 483 172 V 103" fill="none" stroke="#233144" stroke-width="3"/>
  <g id="electron-arrows" fill="none" stroke="#24435F" stroke-width="2">
    <path d="M 154 136.5 Q 189 112 223 163" marker-end="url(#electron-arrow)"/>
    <path d="M 284 168 Q 337 101 414 173" marker-end="url(#electron-arrow)"/>
    <path d="M 483 137 Q 518 117 488 93" marker-end="url(#electron-arrow)"/>
  </g>''');

  static String sigmatropic({required bool oxygen}) {
    final center = oxygen
        ? '<path d="M 215 102 L 300 59 M 322 59 L 410 102"/><text x="311" y="60" text-anchor="middle" font-size="22" fill="#A52752" stroke="none">O</text>'
        : '<path d="M 215 102 L 311 52 L 410 102"/>';
    return _svg('''
  <g fill="none" stroke="#233144" stroke-width="3" stroke-linecap="round">
    $center
    <path d="M 215 102 L 215 192 M 224 106 L 224 188 M 410 102 L 410 192
             M 410 192 L 311 238 M 400 186 L 312 227"/>
  </g>
  <g font-size="14" fill="#526579">
    <text x="193" y="201">1</text><text x="192" y="99">2</text>
    <text x="303" y="34">3</text><text x="425" y="103">4</text>
    <text x="426" y="197">5</text><text x="308" y="259">6</text>
  </g>
  <g id="electron-arrows" fill="none" stroke="#24435F" stroke-width="2">
    <path d="M 224 148 Q 270 153 261 216" marker-end="url(#electron-arrow)"/>
    <path d="M 355 208 Q 362 161 410 147" marker-end="url(#electron-arrow)"/>
    <path d="M 361 77 Q 312 116 264 77" marker-end="url(#electron-arrow)"/>
  </g>''');
  }

  static String _svg(String content) =>
      '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 270">
  <rect width="640" height="270" rx="18" fill="#F9FAFE"/>
  $mechanismArrowMarkers
  <g font-family="sans-serif" fill="#233144">$content</g>
</svg>''';
}
