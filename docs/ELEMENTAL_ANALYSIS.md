# Elemental analysis and validation

Open **Spectroscopy Hub → Elemental Analysis**. Enter the mass percentages of
all elements, or paste a question such as `40% carbon, 6.71% hydrogen, 53.29%
oxygen`. Both element-first and percentage-first wording are supported. A
labelled molar mass in g/mol can also be read from pasted text.

The calculation uses a 100 g basis, converts masses to moles, and searches small
integer ratios. Every proposed formula is checked by reconstructing its mass
percentages. The tolerance is explicit (default ±0.20 percentage points per
element). Percentages are not silently normalized to 100%. Oxygen is calculated
by difference only when the user explicitly requests it and has left O blank.

`47% C, 8% H, 36% O` totals 91%; the tool reports the unaccounted 9% and does
not invent a missing element or formula.

Without molar mass, the output is an empirical ratio, not a molecular formula.
For example, 40.00% C, 6.71% H and 53.29% O are compatible with CH2O. A molar
mass of 60.05 g/mol supports C2H4O2, whereas 180.16 g/mol supports C6H12O6.
Neither identifies a structural isomer. With a molar mass, integer atom counts
are enumerated and checked against both percentages and mass (±0.50 g/mol in
the UI). Multiple compatible formulas are displayed instead of forcing one.
The empirical ratio then comes from the mass-compatible molecular candidates.

**Use formula in Structure Solver** transfers the molecular formula and clears
all example IR/NMR/MS values. The user can add sample spectra, compare references,
and use the existing SVG and structure deduction features. An empirical ratio
alone is not passed off as a molecule.

Scope: neutral organic formulas containing C/H/N/O/S/P/F/Cl/Br/I and conventional
natural-abundance atomic weights. Formula inference does not prove a structure
exists or establish stereochemistry. The standard DBE parity filter is applied
to CHNO/halogen molecular formulas; variable-valence S/P cases are labelled.
The empirical search uses multipliers 1–100 and at most 300 atoms. Molecular
search accepts masses up to 5000 g/mol and at most 100,000 count combinations.
Out-of-range, incomplete, inconsistent and overly broad data fail explicitly.

Validation includes 390 rounded synthetic CHO compositions, nitrogen/halogen
cases, fractional ratios, missing totals, oxygen-by-difference, incompatible
mass, ambiguous formulas, and the full mobile composition-to-solver handoff.
Spectroscopy regression simulations also cover every library entry at three
shift perturbations, unexplained peaks, distinct-peak matching, overlapping IR
bands, nominal isotope mass and SVG rendering. These checks establish the tested
behavior; they are not a guarantee of identifying every unknown compound.

References: [OpenStax: empirical and molecular formulas](https://openstax.org/books/chemistry-2e/pages/3-2-determining-empirical-and-molecular-formulas),
[CIAAW: abridged atomic weights](https://www.ciaaw.org/abridged-atomic-weights.htm).
