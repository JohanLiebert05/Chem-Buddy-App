# Structure solver accuracy

The solver compares the supplied spectra with a finite reference library. Formula
agreement is a necessary filter, not identification. All supplied NMR resonances
must have a compatible reference position before a compound is suggested.
Unexplained proton or carbon resonances reject the reference even when its IR fits.

The comparison uses one-to-one peak matching, with initial tolerances of 0.30 ppm
for proton NMR and 3 ppm for carbon NMR. Proton and carbon evidence each have a
minimum agreement requirement. At least two distinct resonances in one NMR
technique are required. IR and mass peaks supply smaller supporting weights;
they cannot rescue incompatible NMR. Close scores remain ambiguous. These are
heuristic comparison scores, not calibrated probabilities.

The report labels expected reference spectra separately from observed peaks.
Missing signals do not establish absence. Solvent, concentration, temperature,
exchangeable protons and incomplete peak lists can shift or omit resonances.
The solver does not predict an arbitrary molecule's NMR spectrum or establish
connectivity from shifts alone. Confirm integration, multiplicities, coupling
constants, DEPT/HSQC and HMBC where needed. Isomer discrimination remains limited
by the reference library and the supplied data.

Presets extract only marked peak positions; integrations, coupling constants,
isotope ratios and relative intensities are not fed into the shift fields.
Malformed user input is reported instead of silently dropped. Formula validation
supports explicit neutral organic atom counts and Unicode subscripts, rejecting
unsupported elements, charges, parentheses and stray text.

Chemical interpretation references:

- [Oregon State University: carbon-13 chemical shifts](https://sites.science.oregonstate.edu/~gablek/CH362/cshifts.htm): overlapping sp² regions and aldehyde/ketone carbonyl regions. Carbon shift alone does not supply DEPT multiplicity.
- [ACS: NMR spectroscopy](https://inchemistry.acs.org/college-life/know-your-techniques-nmr.html): distinct environments, integration and splitting in structural analysis.
- [AIST SDBS: acetophenone reference spectra](https://sdbs.db.aist.go.jp/SpectralLanding.aspx?spcode=IR-NIDA-05227): experimental reference spectrum source.

Regression tests cover matching IR with incorrect proton/carbon shifts,
aldehyde/ester disambiguation, aromatic/alkene overlap, aryl C–O ambiguity,
insufficient evidence, input validation and every built-in solver preset.

## SVG workbench

The solver separates **Interpret peaks** from **Explore a compound**.
Interpretation shows entered spectra, any supported reference, expected NMR
assignments, the DBE reasoning, and a final **Deduce into Structure** action.
The explorer accepts a library name or formula and previews the selected
reference without identifying an unknown sample from its formula alone.

SVG plots cover proton NMR, carbon-13 NMR, FT-IR and MS. Entered and expected
traces can be toggled independently. NMR and IR axes decrease left to right;
mass spectra increase left to right. The plots reconstruct peak lists rather
than measured spectra. Unknown intensities and line shapes remain schematic.
The proton reference plot illustrates first-order multiplets only when the
reference contains the required coupling constants. J in Hz is divided by
the selected proton frequency (300–800 MHz) to obtain ppm spacing. Complex
or second-order multiplets are not simulated.

Expected NMR tables preserve chemical shifts, proton integration, multiplicity,
coupling constants and assignment descriptions. Nearby entered positions
are displayed for comparison, not as unique experimental assignments.

Structure revelation uses the supported candidate's actual SMILES graph. Atom
counts, including implicit hydrogens, must agree with the molecular formula
before the SVG is shown. Aromatic bonds and carbonyl/ether/alcohol oxygen are
handled explicitly. Ambiguous or conflicting inputs request more evidence
instead of drawing a fabricated exact structure. Drawings are 2D connectivity
diagrams; stereochemistry is not established by shift matching.

Spectrum and structure SVG source can be copied. A valid structure can also be
opened directly in the existing chemical sketcher, preserving its SMILES.

Graph conventions: [Stanford NMR tutorial](https://web.stanford.edu/~kaleeg/chem32/nmrT/)
and [JEOL's guide to chemical shifts, integration and splitting](https://www.jeol.com/column/detail005.php).

## Follow-up accuracy and polish

Mobile NMR assignments use readable cards with the full assignment instead of
requiring horizontal table scrolling. Compact SVG plots use a dedicated smaller
viewBox and larger labels. Unspecified MS intensities use equal schematic
heights rather than treating missing values as one-percent peaks.

Every entered NMR resonance now requires its own compatible reference resonance.
IR bands overlapping alkene/alkyne regions are distinguished from confirmed
carbonyl/nitrile assignments. Molecular ion checks use nominal isotope mass,
not average molar mass, and fragment labels respect the parent's atom inventory.

See [Elemental Analysis](ELEMENTAL_ANALYSIS.md) for the percentage-composition
workspace and its connection to the structure solver.

## Version 3.5.6 teaching walkthrough

Eight evidence-linked lessons explain formula validation, numerical DBE,
functional groups from IR, carbon environments, proton shifts/integration/
splitting, mass evidence and fragment assembly, alternative isomers, and final
verification. Each has a plain-language explanation and an MSc checkpoint.
Missing observations remain unknown. Expected reference integrals and coupling
constants are labelled separately from entered shifts. Fused rings are not
double-counted as independent benzene units.

The bundled molecular editor uses a light drawing surface and controls. Its
Check action reports ordinary valence, formula, mass and disconnected fragments.
These are educational connectivity checks, not full chemical validation.
Unknown metal valence, variable-valence chemistry and stereochemistry require
separate review. The bounded SMILES importer rejects isotope/stereochemical
syntax it cannot preserve; it never silently strips it. Export follows actual
connectivity, and molfile indices remain valid after deletion.
