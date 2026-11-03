# Curious expansion and evidence-aware structure deduction

ChemBuddy 3.5.9 by Prajwal A Kambar.

Curious contains 60 stable-ID questions: 48 new foundations and the previous twelve
deeper questions. Each article includes original teaching, a themed diagram,
a formula-checked molecular reference and a related worked example. The structure
is explicitly a comparison where it does not exhibit the discussed property.
The related ten-minute lesson retains existing saved sessions and assessments.

The collection is lazily rendered. Theme-based random selection uses a shuffle
bag with no immediate cycle-boundary repeat and makes no AI request. Online
enrichment uses the existing authenticated `ask-gemini-orchestrator` key rotation
and AI budget. No keys are embedded; no database permissions or functions change.

The client checks question identity, fixed example SMILES, structural formula,
response size, required fields and two to six reasoning steps. Local chemistry
code draws structures. Prose remains explicitly AI-assisted, rather than
experimental or expert-reviewed evidence. A six-hour, twenty-entry, account-scoped
memory cache and in-flight coalescing reduce duplicate requests. Late results
after account changes are discarded. Failure preserves the offline article and
does not falsely diagnose the device as offline.

## Solver evidence

The optional integration field accepts one absolute integer H count per entered
proton shift. It rejects nonpositive counts, mismatched lists and totals above the
formula H count. Ratios must first be converted to absolute counts; a smaller sum
is allowed for partial data or missing exchangeable protons.

For annotated references, filtering assigns whole environments to observed
regions within the existing shift tolerance. Several reference environments can
overlap in one observed region. One equivalent group cannot be split into
arbitrary fragments. The memoised search conservatively stops after 20,000
states; failure to establish an assignment never promotes a candidate. Existing
formula, IR, carbon and mass constraints still apply.

The evidence guide accounts for missing hydrogens, recommends targeted NMR/IR
measurements and compares a distinguishing reference shift when candidates remain.
It distinguishes unmeasured evidence from absence, and the limited library from
all possible organic compounds. Agreement scores are not probabilities.

Visible labels use structure, spectrum, diagram and AI explanation. Internal
identifiers, standard file encodings and provider connections remain compatible.

The Study Mode, lesson and Curious backdrops now use static coral, mint, violet
and theme colours with sparse decorative molecular motifs. A separate repaint
boundary isolates the backdrop from timer updates and scrolling. High-contrast
mode reduces decoration. Existing glass surfaces retain their readable borders
and translucent highlights without an additional backdrop-blur pass.

## Validation

The full Flutter suite passed 620 tests. Seventeen affected widget and feature
tests passed again after the final background change, including narrow light/dark
layouts with enlarged text. Analysis reported no issues. A signed-in live
application check of **New discovery · online** returned the double-bond-twisting
question with ethene, a validated explanation and a working self-check reveal.
The new backend key in slot 4 passed a separate generation diagnostic after one
inconclusive timeout. These results do not establish physical-phone frame timing
or scientifically certify all generated explanations.

## Teaching references checked

Explanations and diagrams are original. Core concepts were checked against:

- [OpenStax: rules for resonance forms](https://openstax.org/books/organic-chemistry/pages/2-5-rules-for-resonance-forms)
- [OpenStax: structure and stability of benzene](https://openstax.org/books/organic-chemistry/pages/15-2-structure-and-stability-of-benzene)
- [OpenStax: aromaticity and the Hückel rule](https://openstax.org/books/organic-chemistry/pages/15-3-aromaticity-and-the-huckel-4n-2-rule)
- [OpenStax: complex splitting and accidental overlap](https://openstax.org/books/organic-chemistry/pages/13-8-more-complex-spin-spin-splitting-patterns)
