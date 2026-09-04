#!/usr/bin/env python3
"""Generate ChemDraw-style step SVGs for the 10 in-app ChemBuddy mechanisms."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "mechanisms"


def wrap(title: str, desc: str, inner: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 820 360" width="820" height="360" role="img">
  <title>{title}</title>
  <desc>{desc}</desc>
  <defs>
    <marker id="electron-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
      <path d="M 0 1.2 L 10 5 L 0 8.8 Z" fill="#111111"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
      <path d="M 0 2 L 10 5 L 0 5 Z" fill="#111111"/>
    </marker>
  </defs>
  <rect x="0" y="0" width="820" height="360" fill="#ffffff"/>
{inner}
</svg>
"""


def write(rel: str, title: str, desc: str, inner: str) -> None:
    path = ASSETS / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(wrap(title, desc, inner), encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


# --- SN1 t-BuBr + H2O ---
write(
    "substitution/sn1/step-01.svg",
    "SN1 reaction mechanism - step 1",
    "Heterolysis of tert-butyl bromide. The C-Br bonding pair moves onto bromine, forming a planar tert-butyl cation and bromide. This is the rate-determining step.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">polar protic, RDS</text></g>
  <g id="reactants">
    <line x1="220" y1="200" x2="220" y2="130" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="220" y1="200" x2="160" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="220" y1="200" x2="280" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="220" y1="200" x2="330" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="338" y="208" font-family="Arial, Helvetica, sans-serif" font-size="20" font-weight="600">Br</text>
    <text x="206" y="118" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="128" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="274" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
  </g>
  <g id="electron-arrows">
    <path d="M 270 192 C 300 150 320 152 342 188" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="210" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">tert-butyl bromide</text></g>
""",
)
write(
    "substitution/sn1/step-02.svg",
    "SN1 reaction mechanism - step 2",
    "Planar tert-butyl cation. Water oxygen lone pair attacks the empty p orbital at carbon from either face.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">planar carbocation</text></g>
  <g id="intermediate-1">
    <line x1="300" y1="200" x2="300" y2="130" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="300" y1="200" x2="240" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="300" y1="200" x2="360" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="286" y="118" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="208" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="354" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="308" y="196" font-family="Arial, Helvetica, sans-serif" font-size="16">+</text>
    <ellipse cx="300" cy="200" rx="10" ry="26" fill="none" stroke="#555" stroke-dasharray="3 3"/>
    <text x="80" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">H2O</text>
    <ellipse cx="130" cy="192" rx="2.2" ry="2.2" fill="#111"/>
    <ellipse cx="130" cy="204" rx="2.2" ry="2.2" fill="#111"/>
  </g>
  <g id="electron-arrows">
    <path d="M 140 198 C 200 160 250 160 288 188" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="70" y="240" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">water lone pair to C+</text></g>
""",
)
write(
    "substitution/sn1/step-03.svg",
    "SN1 reaction mechanism - step 3",
    "Oxonium deprotonation. A second water molecule removes a proton from the oxygen, giving tert-butanol. Attack from either face of the cation gives racemization on a chiral analogue.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">deprotonation / racemic if chiral</text></g>
  <g id="products">
    <line x1="260" y1="200" x2="260" y2="130" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="260" y1="200" x2="200" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="260" y1="200" x2="320" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="260" y1="200" x2="330" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="336" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">OH</text>
    <text x="246" y="118" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="168" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="314" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="520" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">H3O+</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="200" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">tert-butanol</text></g>
""",
)

# --- E1 t-BuBr ---
write(
    "elimination/e1/step-01.svg",
    "E1 reaction mechanism - step 1",
    "Leaving-group departure from tert-butyl bromide to the tert-butyl cation. Same ionization as SN1; E1 vs SN1 is decided in the next step.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">heat, polar protic</text></g>
  <g id="reactants">
    <line x1="220" y1="200" x2="220" y2="130" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="220" y1="200" x2="160" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="220" y1="200" x2="280" y2="240" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="220" y1="200" x2="330" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="338" y="208" font-family="Arial, Helvetica, sans-serif" font-size="20" font-weight="600">Br</text>
  </g>
  <g id="electron-arrows">
    <path d="M 270 192 C 300 150 320 152 342 188" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="180" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">C-Br to Br</text></g>
""",
)
write(
    "elimination/e1/step-02.svg",
    "E1 reaction mechanism - step 2",
    "Water abstracts a beta-hydrogen. The C-H bonding pair forms the C=C pi bond of 2-methylpropene. No rearrangement is required for this tert-butyl cation.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">beta-deprotonation</text></g>
  <g id="intermediate-1">
    <text x="70" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">H2O</text>
    <ellipse cx="120" cy="192" rx="2.2" ry="2.2" fill="#111"/>
    <line x1="220" y1="140" x2="260" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="200" y="132" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
    <line x1="260" y1="200" x2="260" y2="270" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="260" y1="200" x2="330" y2="170" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="268" y="196" font-family="Arial, Helvetica, sans-serif" font-size="16">+</text>
  </g>
  <g id="electron-arrows">
    <path d="M 128 196 C 170 150 200 140 218 142" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 232 160 C 250 170 255 185 258 198" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels">
    <text x="90" y="250" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">O to beta-H</text>
    <text x="270" y="130" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">C-H to C-C</text>
  </g>
""",
)
write(
    "elimination/e1/step-03.svg",
    "E1 reaction mechanism - step 3",
    "2-methylpropene (Zaitsev alkene for this substrate) plus hydronium and bromide.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">Zaitsev alkene</text></g>
  <g id="products">
    <line x1="280" y1="200" x2="360" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="280" y1="194" x2="360" y2="194" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="280" y1="200" x2="240" y2="140" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="280" y1="200" x2="240" y2="260" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="500" y="208" font-family="Arial, Helvetica, sans-serif" font-size="16">H3O+  Br-</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="250" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">2-methylpropene</text></g>
""",
)

# --- E2 2-bromobutane + EtO- ---
write(
    "elimination/e2/step-01.svg",
    "E2 reaction mechanism - step 1",
    "Concerted anti-periplanar elimination of (2R,3R)-relative 2-bromobutane with ethoxide. Base lone pair to beta-H, C-H to C-C, C-Br to Br, all in one step.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">EtO-, EtOH, heat; anti-periplanar</text></g>
  <g id="reactants">
    <text x="40" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">EtO-</text>
    <ellipse cx="100" cy="192" rx="2.2" ry="2.2" fill="#111"/>
    <text x="150" y="150" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
    <line x1="160" y1="158" x2="220" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="220" y1="200" x2="300" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="180" y1="200" x2="220" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="160" y1="240" x2="220" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="300" y1="200" x2="360" y2="160" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <line x1="300" y1="200" x2="380" y2="200" stroke="#111" stroke-width="2.1" stroke-linecap="round"/>
    <text x="388" y="208" font-family="Arial, Helvetica, sans-serif" font-size="20" font-weight="600">Br</text>
    <text x="148" y="268" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="368" y="150" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
  </g>
  <g id="electron-arrows">
    <path d="M 108 194 C 130 150 145 140 158 152" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 180 170 C 200 180 210 190 218 198" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 340 192 C 365 155 385 158 402 188" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="200" y="320" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">three arrows, one step</text></g>
""",
)
write(
    "elimination/e2/step-02.svg",
    "E2 reaction mechanism - step 2",
    "trans-but-2-ene (Zaitsev) plus ethanol and bromide after concerted elimination.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">Zaitsev trans alkene</text></g>
  <g id="products">
    <line x1="240" y1="200" x2="320" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="240" y1="194" x2="320" y2="194" stroke="#111" stroke-width="2.1"/>
    <line x1="240" y1="200" x2="200" y2="250" stroke="#111" stroke-width="2.1"/>
    <line x1="320" y1="200" x2="360" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="500" y="208" font-family="Arial, Helvetica, sans-serif" font-size="16">EtOH  Br-</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="220" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">trans-but-2-ene</text></g>
""",
)

# --- Cannizzaro PhCHO ---
write(
    "named/cannizzaro/step-01.svg",
    "Cannizzaro reaction mechanism - step 1",
    "Hydroxide adds to benzaldehyde carbonyl carbon. The C=O pi bond moves onto oxygen, giving a tetrahedral alkoxide.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">conc. NaOH, no enolizable H</text></g>
  <g id="reactants">
    <text x="40" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">HO-</text>
    <ellipse cx="90" cy="192" rx="2.2" ry="2.2" fill="#111"/>
    <polygon points="200,160 230,175 230,205 200,220 170,205 170,175" fill="none" stroke="#111" stroke-width="2"/>
    <circle cx="200" cy="190" r="12" fill="none" stroke="#111" stroke-width="1.2"/>
    <line x1="230" y1="190" x2="290" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="290" y1="190" x2="330" y2="140" stroke="#111" stroke-width="2.1"/>
    <line x1="286" y1="190" x2="326" y2="140" stroke="#111" stroke-width="2.1"/>
    <text x="334" y="136" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <text x="300" y="230" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
    <line x1="290" y1="190" x2="310" y2="230" stroke="#111" stroke-width="2"/>
  </g>
  <g id="electron-arrows">
    <path d="M 98 194 C 160 150 220 150 278 178" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 308 168 C 325 150 330 145 338 148" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="160" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">HO- to carbonyl C; pi to O</text></g>
""",
)
write(
    "named/cannizzaro/step-02.svg",
    "Cannizzaro reaction mechanism - step 2",
    "Hydride transfer from the tetrahedral intermediate to a second benzaldehyde. The C-H bonding pair is the hydride source; destination is the second carbonyl carbon.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">hydride transfer</text></g>
  <g id="intermediate-1">
    <polygon points="160,160 190,175 190,205 160,220 130,205 130,175" fill="none" stroke="#111" stroke-width="2"/>
    <line x1="190" y1="190" x2="250" y2="190" stroke="#111" stroke-width="2.1"/>
    <text x="256" y="180" font-family="Arial, Helvetica, sans-serif" font-size="14">O-</text>
    <line x1="250" y1="190" x2="250" y2="240" stroke="#111" stroke-width="2.1"/>
    <text x="244" y="262" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
    <line x1="250" y1="190" x2="290" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="292" y="146" font-family="Arial, Helvetica, sans-serif" font-size="14">OH</text>
    <polygon points="480,160 510,175 510,205 480,220 450,205 450,175" fill="none" stroke="#111" stroke-width="2"/>
    <line x1="510" y1="190" x2="570" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="570" y1="190" x2="610" y2="140" stroke="#111" stroke-width="2.1"/>
    <line x1="566" y1="190" x2="606" y2="140" stroke="#111" stroke-width="2.1"/>
    <text x="614" y="136" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
  </g>
  <g id="electron-arrows">
    <path d="M 252 230 C 320 250 400 230 555 198" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 588 168 C 605 150 610 145 618 148" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="280" y="310" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">C-H hydride to second carbonyl C</text></g>
""",
)
write(
    "named/cannizzaro/step-03.svg",
    "Cannizzaro reaction mechanism - step 3",
    "Products after proton transfer: benzoate and benzyl alcohol. The hydride-reduced aldehyde is the alcohol; the oxidized partner is the carboxylate.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">proton transfer</text></g>
  <g id="products">
    <polygon points="180,160 210,175 210,205 180,220 150,205 150,175" fill="none" stroke="#111" stroke-width="2"/>
    <line x1="210" y1="190" x2="270" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="270" y1="190" x2="310" y2="150" stroke="#111" stroke-width="2.1"/>
    <line x1="266" y1="190" x2="306" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="314" y="146" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <line x1="270" y1="190" x2="310" y2="230" stroke="#111" stroke-width="2.1"/>
    <text x="314" y="246" font-family="Arial, Helvetica, sans-serif" font-size="16">O-</text>
    <polygon points="480,160 510,175 510,205 480,220 450,205 450,175" fill="none" stroke="#111" stroke-width="2"/>
    <line x1="510" y1="190" x2="570" y2="190" stroke="#111" stroke-width="2.1"/>
    <text x="576" y="196" font-family="Arial, Helvetica, sans-serif" font-size="16">CH2OH</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="150" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">benzoate</text>
  <text x="470" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">benzyl alcohol</text></g>
""",
)

# --- Aldol acetaldehyde ---
write(
    "enolate/aldol/step-01.svg",
    "Aldol condensation mechanism - step 1",
    "Ethoxide deprotonates acetaldehyde at the alpha carbon, forming the enolate. Lone pair on oxygen of ethoxide to alpha-H; C-H bonding pair to the carbonyl pi system / enolate oxygen.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">NaOEt, EtOH</text></g>
  <g id="reactants">
    <text x="40" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">EtO-</text>
    <ellipse cx="95" cy="192" rx="2.2" ry="2.2" fill="#111"/>
    <text x="150" y="230" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
    <line x1="160" y1="218" x2="210" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="210" y1="200" x2="270" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="270" y1="200" x2="310" y2="150" stroke="#111" stroke-width="2.1"/>
    <line x1="266" y1="200" x2="306" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="314" y="146" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <text x="278" y="230" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
    <line x1="270" y1="200" x2="285" y2="230" stroke="#111" stroke-width="2"/>
  </g>
  <g id="electron-arrows">
    <path d="M 104 194 C 125 210 140 220 158 218" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 180 210 C 230 170 260 160 300 160" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="120" y="290" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">base to alpha-H; C-H to enolate O</text></g>
""",
)
write(
    "enolate/aldol/step-02.svg",
    "Aldol condensation mechanism - step 2",
    "Enolate carbon attacks a second acetaldehyde carbonyl. Enolate pi/lone pair equivalent to the electrophilic carbonyl carbon; C=O pi bond to oxygen.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">C-C bond formation</text></g>
  <g id="intermediate-1">
    <line x1="140" y1="200" x2="200" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="140" y1="194" x2="200" y2="194" stroke="#111" stroke-width="2.1"/>
    <text x="90" y="198" font-family="Arial, Helvetica, sans-serif" font-size="16">O-</text>
    <line x1="140" y1="200" x2="110" y2="160" stroke="#111" stroke-width="2.1"/>
    <line x1="320" y1="200" x2="380" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="380" y1="200" x2="420" y2="150" stroke="#111" stroke-width="2.1"/>
    <line x1="376" y1="200" x2="416" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="424" y="146" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <text x="388" y="230" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
  </g>
  <g id="electron-arrows">
    <path d="M 200 198 C 250 170 300 170 368 188" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 398 168 C 415 150 420 145 428 148" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="220" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">enolate C to carbonyl C</text></g>
""",
)
write(
    "enolate/aldol/step-03.svg",
    "Aldol condensation mechanism - step 3",
    "After protonation of the alkoxide, E1cB dehydration (heat) gives crotonaldehyde. Shown as the condensed enone product plus water.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">protonation then heat / dehydration</text></g>
  <g id="products">
    <line x1="200" y1="200" x2="260" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="260" y1="200" x2="320" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="260" y1="194" x2="320" y2="194" stroke="#111" stroke-width="2.1"/>
    <line x1="320" y1="200" x2="380" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="380" y1="200" x2="420" y2="150" stroke="#111" stroke-width="2.1"/>
    <line x1="376" y1="200" x2="416" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="424" y="146" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <text x="188" y="196" font-family="Arial, Helvetica, sans-serif" font-size="14">H3C</text>
    <text x="500" y="208" font-family="Arial, Helvetica, sans-serif" font-size="16">H2O</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="220" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">but-2-enal (crotonaldehyde)</text></g>
""",
)

# --- Wittig Ph3P=CH2 + acetone ---
write(
    "carbonyl/wittig/step-01.svg",
    "Wittig reaction mechanism - step 1",
    "Methylidenetriphenylphosphorane attacks acetone. The ylide carbon lone pair / C-P ylidic electron density attacks the carbonyl carbon; C=O pi electrons move to oxygen.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">Ph3P=CH2 + acetone</text></g>
  <g id="reactants">
    <text x="40" y="200" font-family="Arial, Helvetica, sans-serif" font-size="16">Ph3P</text>
    <line x1="90" y1="194" x2="140" y2="194" stroke="#111" stroke-width="2.1"/>
    <text x="144" y="200" font-family="Arial, Helvetica, sans-serif" font-size="16">CH2</text>
    <ellipse cx="168" cy="178" rx="2.2" ry="2.2" fill="#111"/>
    <line x1="300" y1="140" x2="340" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="300" y1="240" x2="340" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="340" y1="190" x2="390" y2="140" stroke="#111" stroke-width="2.1"/>
    <line x1="336" y1="190" x2="386" y2="140" stroke="#111" stroke-width="2.1"/>
    <text x="394" y="136" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <text x="268" y="136" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="268" y="256" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
  </g>
  <g id="electron-arrows">
    <path d="M 172 180 C 230 150 290 150 330 178" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 365 160 C 380 145 385 140 394 144" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="80" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">ylide C to carbonyl C</text></g>
""",
)
write(
    "carbonyl/wittig/step-02.svg",
    "Wittig reaction mechanism - step 2",
    "Oxaphosphetane. Oxygen bonds to phosphorus. Collapse: C-P bonding pair to form the alkene and P-O of Ph3P=O. Li-salt-free conditions favor this [2+2] path over a long-lived betaine.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">oxaphosphetane (not a free betaine under salt-free conditions)</text></g>
  <g id="intermediate-1">
    <text x="200" y="160" font-family="Arial, Helvetica, sans-serif" font-size="16">Ph3P</text>
    <line x1="250" y1="154" x2="310" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="250" y1="154" x2="310" y2="110" stroke="#111" stroke-width="2.1"/>
    <text x="314" y="106" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <line x1="310" y1="110" x2="310" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="310" y1="200" x2="370" y2="200" stroke="#111" stroke-width="2.1"/>
    <text x="376" y="204" font-family="Arial, Helvetica, sans-serif" font-size="14">CMe2</text>
  </g>
  <g id="electron-arrows">
    <path d="M 270 160 C 255 130 270 115 300 112" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="200" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">four-membered P-C-C-O ring</text></g>
""",
)
write(
    "carbonyl/wittig/step-03.svg",
    "Wittig reaction mechanism - step 3",
    "2-methylpropene and triphenylphosphine oxide after cycloreversion of the oxaphosphetane.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">alkene + Ph3P=O</text></g>
  <g id="products">
    <line x1="200" y1="200" x2="280" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="200" y1="194" x2="280" y2="194" stroke="#111" stroke-width="2.1"/>
    <line x1="280" y1="200" x2="320" y2="150" stroke="#111" stroke-width="2.1"/>
    <line x1="280" y1="200" x2="320" y2="250" stroke="#111" stroke-width="2.1"/>
    <text x="450" y="208" font-family="Arial, Helvetica, sans-serif" font-size="16">Ph3P=O</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="180" y="290" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">2-methylpropene</text></g>
""",
)

# --- Diels-Alder butadiene + ethylene ---
write(
    "pericyclic/diels_alder/step-01.svg",
    "Diels-Alder reaction mechanism - step 1",
    "s-cis 1,3-butadiene and ethene aligned for [4+2] cycloaddition. Three two-electron arrows in a cycle: diene HOMO to ethene, ethene pi to diene terminus, diene internal pi reorganization. Concerted, no intermediate.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">heat; concerted [4+2]</text></g>
  <g id="reactants">
    <line x1="180" y1="230" x2="240" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="180" y1="224" x2="240" y2="194" stroke="#111" stroke-width="2.1"/>
    <line x1="240" y1="200" x2="300" y2="230" stroke="#111" stroke-width="2.1"/>
    <line x1="300" y1="230" x2="360" y2="200" stroke="#111" stroke-width="2.1"/>
    <line x1="300" y1="224" x2="360" y2="194" stroke="#111" stroke-width="2.1"/>
    <line x1="220" y1="120" x2="320" y2="120" stroke="#111" stroke-width="2.1"/>
    <line x1="220" y1="114" x2="320" y2="114" stroke="#111" stroke-width="2.1"/>
  </g>
  <g id="electron-arrows">
    <path d="M 210 210 C 210 160 220 140 230 128" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 310 122 C 330 150 340 170 350 190" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 270 220 C 280 210 290 210 300 220" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="160" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">1,3-butadiene + ethene</text></g>
""",
)
write(
    "pericyclic/diels_alder/step-02.svg",
    "Diels-Alder reaction mechanism - step 2",
    "Cyclohexene. The new sigma bonds and the remaining endocyclic alkene are the concerted cycloaddition product. Stereochemistry is syn with respect to the diene/dienophile approach.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">cyclohexene</text></g>
  <g id="products">
    <polygon points="300,120 360,150 360,210 300,240 240,210 240,150" fill="none" stroke="#111" stroke-width="2.1"/>
    <line x1="240" y1="150" x2="300" y2="120" stroke="#111" stroke-width="2.1"/>
    <line x1="242" y1="156" x2="298" y2="126" stroke="#111" stroke-width="2.1"/>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="250" y="290" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">new C-C bonds at the former termini</text></g>
""",
)

# --- Grignard MeMgBr + acetone ---
write(
    "carbonyl/grignard/step-01.svg",
    "Grignard reaction mechanism - step 1",
    "Methylmagnesium bromide attacks acetone. The C-Mg bonding pair is the nucleophile source and attacks the carbonyl carbon; C=O pi electrons move to oxygen, which coordinates Mg.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">dry Et2O; then H3O+ workup later</text></g>
  <g id="reactants">
    <text x="40" y="208" font-family="Arial, Helvetica, sans-serif" font-size="16">H3C-MgBr</text>
    <line x1="250" y1="140" x2="290" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="250" y1="240" x2="290" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="290" y1="190" x2="340" y2="140" stroke="#111" stroke-width="2.1"/>
    <line x1="286" y1="190" x2="336" y2="140" stroke="#111" stroke-width="2.1"/>
    <text x="344" y="136" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <text x="218" y="136" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="218" y="256" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
  </g>
  <g id="electron-arrows">
    <path d="M 130 200 C 180 160 240 160 280 178" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 315 160 C 330 145 335 140 344 144" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="80" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">C-Mg to carbonyl C; pi to O</text></g>
""",
)
write(
    "carbonyl/grignard/step-02.svg",
    "Grignard reaction mechanism - step 2",
    "Tetrahedral alkoxide-magnesium complex. Do not skip this intermediate.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">alkoxide-MgX complex</text></g>
  <g id="intermediate-1">
    <line x1="250" y1="140" x2="300" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="250" y1="240" x2="300" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="200" y1="190" x2="300" y2="190" stroke="#111" stroke-width="2.1"/>
    <text x="168" y="196" font-family="Arial, Helvetica, sans-serif" font-size="14">H3C</text>
    <line x1="300" y1="190" x2="360" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="364" y="146" font-family="Arial, Helvetica, sans-serif" font-size="16">O- MgBr+</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="180" y="290" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">tert-alkoxide (from acetone + MeMgBr)</text></g>
""",
)
write(
    "carbonyl/grignard/step-03.svg",
    "Grignard reaction mechanism - step 3",
    "Aqueous acid protonates the alkoxide oxygen to give tert-butanol.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">H3O+ workup</text></g>
  <g id="products">
    <line x1="260" y1="200" x2="260" y2="130" stroke="#111" stroke-width="2.1"/>
    <line x1="260" y1="200" x2="200" y2="240" stroke="#111" stroke-width="2.1"/>
    <line x1="260" y1="200" x2="320" y2="240" stroke="#111" stroke-width="2.1"/>
    <line x1="260" y1="200" x2="330" y2="200" stroke="#111" stroke-width="2.1"/>
    <text x="336" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">OH</text>
    <text x="246" y="118" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="168" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
    <text x="314" y="258" font-family="Arial, Helvetica, sans-serif" font-size="14">CH3</text>
  </g>
  <g id="electron-arrows">
    <path d="M 400 160 C 370 170 350 185 338 198" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="200" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">tert-butanol; arrow: O- to H of H3O+</text>
  <text x="430" y="150" font-family="Arial, Helvetica, sans-serif" font-size="14">H3O+</text></g>
""",
)

# --- Beckmann cyclohexanone oxime ---
write(
    "rearrangements/beckmann/step-01.svg",
    "Beckmann rearrangement mechanism - step 1",
    "Acid activates the oxime OH. The alkyl group anti to the leaving group migrates from carbon to nitrogen as water departs. The migrating C-C bond is the electron source; destination is nitrogen.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">H2SO4; cyclohexanone oxime</text></g>
  <g id="reactants">
    <polygon points="260,140 320,160 330,220 280,260 220,240 210,180" fill="none" stroke="#111" stroke-width="2.1"/>
    <line x1="320" y1="160" x2="380" y2="140" stroke="#111" stroke-width="2.1"/>
    <line x1="316" y1="160" x2="376" y2="140" stroke="#111" stroke-width="2.1"/>
    <text x="384" y="136" font-family="Arial, Helvetica, sans-serif" font-size="16">N</text>
    <line x1="400" y1="136" x2="450" y2="136" stroke="#111" stroke-width="2.1"/>
    <text x="454" y="142" font-family="Arial, Helvetica, sans-serif" font-size="16">OH2+</text>
  </g>
  <g id="electron-arrows">
    <path d="M 300 200 C 340 180 360 160 382 142" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 420 136 C 440 120 448 118 460 128" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="180" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">anti C-C migrates to N; N-O to leaving water</text></g>
""",
)
write(
    "rearrangements/beckmann/step-02.svg",
    "Beckmann rearrangement mechanism - step 2",
    "Nitrilium-like ring expansion intermediate is hydrated. Water attacks carbon; tautomerization gives epsilon-caprolactam.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">hydration</text></g>
  <g id="intermediate-1">
    <polygon points="240,150 310,150 340,200 310,250 240,250 210,200" fill="none" stroke="#111" stroke-width="2.1"/>
    <line x1="310" y1="150" x2="360" y2="120" stroke="#111" stroke-width="2.1"/>
    <line x1="306" y1="150" x2="356" y2="120" stroke="#111" stroke-width="2.1"/>
    <text x="364" y="116" font-family="Arial, Helvetica, sans-serif" font-size="16">N+</text>
    <text x="80" y="208" font-family="Arial, Helvetica, sans-serif" font-size="16">H2O</text>
  </g>
  <g id="electron-arrows">
    <path d="M 120 200 C 180 160 250 140 300 148" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="200" y="300" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">water to nitrilium carbon</text></g>
""",
)
write(
    "rearrangements/beckmann/step-03.svg",
    "Beckmann rearrangement mechanism - step 3",
    "epsilon-Caprolactam after tautomerization. The migrating methylene is now attached to nitrogen.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">caprolactam</text></g>
  <g id="products">
    <polygon points="250,140 330,150 350,210 310,260 230,250 220,190" fill="none" stroke="#111" stroke-width="2.1"/>
    <line x1="330" y1="150" x2="380" y2="120" stroke="#111" stroke-width="2.1"/>
    <line x1="326" y1="150" x2="376" y2="120" stroke="#111" stroke-width="2.1"/>
    <text x="384" y="116" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <text x="300" y="280" font-family="Arial, Helvetica, sans-serif" font-size="16">NH</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="230" y="320" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">epsilon-caprolactam</text></g>
""",
)

# --- Benzoin PhCHO / CN- ---
write(
    "named/benzoin/step-01.svg",
    "Benzoin condensation mechanism - step 1",
    "Cyanide adds to benzaldehyde, then proton transfer gives the umpolung carbanion (Breslow-type cyanide adduct). Cyanide carbon lone pair to carbonyl carbon; pi to O.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">KCN, EtOH/H2O</text></g>
  <g id="reactants">
    <text x="40" y="208" font-family="Arial, Helvetica, sans-serif" font-size="18">NC-</text>
    <ellipse cx="90" cy="192" rx="2.2" ry="2.2" fill="#111"/>
    <polygon points="200,160 230,175 230,205 200,220 170,205 170,175" fill="none" stroke="#111" stroke-width="2"/>
    <circle cx="200" cy="190" r="12" fill="none" stroke="#111" stroke-width="1.2"/>
    <line x1="230" y1="190" x2="290" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="290" y1="190" x2="330" y2="140" stroke="#111" stroke-width="2.1"/>
    <line x1="286" y1="190" x2="326" y2="140" stroke="#111" stroke-width="2.1"/>
    <text x="334" y="136" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <line x1="290" y1="190" x2="310" y2="230" stroke="#111" stroke-width="2"/>
    <text x="300" y="250" font-family="Arial, Helvetica, sans-serif" font-size="14">H</text>
  </g>
  <g id="electron-arrows">
    <path d="M 98 194 C 160 150 220 150 278 178" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 308 168 C 325 150 330 145 338 148" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="150" y="290" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">CN- to carbonyl C</text></g>
""",
)
write(
    "named/benzoin/step-02.svg",
    "Benzoin condensation mechanism - step 2",
    "The umpolung carbanion attacks a second benzaldehyde. Carbanion lone pair to the second carbonyl carbon.",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">C-C bond to second ArCHO</text></g>
  <g id="intermediate-1">
    <polygon points="150,160 180,175 180,205 150,220 120,205 120,175" fill="none" stroke="#111" stroke-width="2"/>
    <line x1="180" y1="190" x2="240" y2="190" stroke="#111" stroke-width="2.1"/>
    <text x="220" y="176" font-family="Arial, Helvetica, sans-serif" font-size="14">-</text>
    <text x="246" y="186" font-family="Arial, Helvetica, sans-serif" font-size="14">OH,CN</text>
    <polygon points="430,160 460,175 460,205 430,220 400,205 400,175" fill="none" stroke="#111" stroke-width="2"/>
    <line x1="460" y1="190" x2="520" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="520" y1="190" x2="560" y2="140" stroke="#111" stroke-width="2.1"/>
    <line x1="516" y1="190" x2="556" y2="140" stroke="#111" stroke-width="2.1"/>
    <text x="564" y="136" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
  </g>
  <g id="electron-arrows">
    <path d="M 240 188 C 320 160 400 160 508 178" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
    <path d="M 538 168 C 555 150 560 145 568 148" fill="none" stroke="#111" stroke-width="1.7" marker-end="url(#electron-arrow)"/>
  </g>
  <g id="labels"><text x="250" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">carbanion to second carbonyl C</text></g>
""",
)
write(
    "named/benzoin/step-03.svg",
    "Benzoin condensation mechanism - step 3",
    "Collapse ejects cyanide, regenerating the catalyst, and yields benzoin (PhCH(OH)COPh).",
    """
  <g id="conditions"><text x="410" y="28" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333333">CN- leaves; catalyst regenerated</text></g>
  <g id="products">
    <polygon points="160,160 190,175 190,205 160,220 130,205 130,175" fill="none" stroke="#111" stroke-width="2"/>
    <line x1="190" y1="190" x2="250" y2="190" stroke="#111" stroke-width="2.1"/>
    <text x="256" y="196" font-family="Arial, Helvetica, sans-serif" font-size="14">CHOH</text>
    <line x1="310" y1="190" x2="370" y2="190" stroke="#111" stroke-width="2.1"/>
    <line x1="370" y1="190" x2="410" y2="150" stroke="#111" stroke-width="2.1"/>
    <line x1="366" y1="190" x2="406" y2="150" stroke="#111" stroke-width="2.1"/>
    <text x="414" y="146" font-family="Arial, Helvetica, sans-serif" font-size="16">O</text>
    <polygon points="430,160 460,175 460,205 430,220 400,205 400,175" fill="none" stroke="#111" stroke-width="2"/>
    <text x="560" y="208" font-family="Arial, Helvetica, sans-serif" font-size="16">CN-</text>
  </g>
  <g id="electron-arrows"></g>
  <g id="labels"><text x="160" y="280" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#444">benzoin</text></g>
""",
)

print("done")
