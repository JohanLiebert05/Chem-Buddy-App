# Gemini NMR prediction — 3.5.6 build 36

Open Spectroscopy Hub → Structure Solver → **Predict with Gemini**. Enter a
specific compound name or supported SMILES, solvent, temperature and proton
frequency. The offline solver and finite reference explorer remain available.

The client invokes the existing authenticated `ask-gemini-orchestrator` function.
Provider credentials remain on the server; no new provider key is embedded or
required in the APK. The existing function and its key/model rotation must be
configured and the user must sign in. No new Edge Function deployment is needed.
See [Supabase function invocation](https://supabase.com/docs/reference/dart/functions-invoke).

The response must contain structured JSON with a molecular formula, explicit
SMILES, conditions, assigned proton/carbon signals, representative shifts,
heuristic shift ranges, approximate multiplicities/J where defensible, explanation
and uncertainties. The client parses the raw response without prose formatting.
One correction attempt is allowed for inconsistent output; intentional ambiguity
or unsupported-chemistry responses are not pressured into a fabricated answer.

Before showing results, the app checks:

- Exact requested input and solvent/temperature/frequency.
- Supported SMILES grammar, closed rings/branches, no duplicate/self bonds,
  connectedness, charge and ordinary valence; formula/structure atom inventories.
- Valid integer DBE for the supported neutral organic subset.
- Every carbon assigned exactly once to a carbon signal.
- Every implicit hydrogen accounted for exactly once by proton assignments,
  with integration checked per signal and per atom, including exchangeable H.
- Finite shifts/ranges and couplings, supported multiplicities and bounded sizes.
- Account ownership after an asynchronous request; cancellation and edits cannot
  attach a stale result to a different compound.

SVG is generated locally from validated numerical data and connectivity, never
from model-supplied SVG/HTML. NMR axes decrease left to right. First-order splitting
uses estimated J only when supplied; unresolved multiplets are schematic envelopes.
Broadband-decoupled carbon peak heights are not carbon atom counts.

These checks establish internal consistency, **not experimental accuracy**.
Gemini may still predict wrong shifts or resolve a name incorrectly. Formula alone
does not establish one isomer. Heuristic ranges are not statistical confidence
intervals. Verify the proposed structure, spectra and conditions with experimental
data. General JSON structure does not guarantee semantic correctness; see
[Gemini structured output guidance](https://ai.google.dev/gemini-api/docs/structured-output).

The local validator supports bounded, single neutral organic molecules using
C/H/N/O/S/P/F/Cl/Br/I (up to 100 carbons and 150 heavy atoms). It deliberately
withholds isotope/stereochemical SMILES annotations, mixtures, polymers and other
unsupported structures. It cannot provide guaranteed predictions for every
organic compound. The drawing shows constitutional connectivity only.

## Twenty-five molecule offline simulation

`test/spectroscopy_random_25_test.dart` uses seed **35625** to select 25 distinct
formulas from the app's curated organic library, each with an exact structure.
It checks formula/DBE, refuses formula-only identity, checks that reference spectra
do not yield a wrong isomer, balances SVG atom/H inventories, and parses/renders
all 75 SVGs (structure plus proton/carbon spectra) through Flutter SVG.

Run `flutter test --dart-define=WRITE_SPECTROSCOPY_REPORT=true` to generate
`build/spectroscopy-review/random-25-report.html` and `.json`. The release workflow
attaches these reports to the APK release. These are **offline reference/rendering
simulations**, not 25 live Gemini requests or an independent experimental benchmark.
The reference library's measurement provenance/conditions are not established.
No experimental accuracy percentage is inferred from these checks.

## Partial live review — 1 November 2026

Forty distinct PubChem-verified molecular formulas with specified connectivity
were submitted through the authenticated app and existing server-side keys.
Ten molecules received Gemini responses: seven passed the client's consistency
checks, two still returned malformed JSON after correction, and one incorrectly
refused the valid PubChem vanillin structure. The remaining thirty were blocked
by the account's daily AI request limit. The user chose to finish this partial
report rather than increase the allowance. No quota or authentication bypass was
used.

The responding model was `gemini-3.6-flash`. Server metadata reported **one
configured key slot**; this run confirms connectivity, not multi-key failover.
Conditions requested were CDCl3, 298 K and 400 MHz proton frequency. Seven
accepted responses have formula/structure consistency, balanced H/C assignments,
and 21 locally generated SVGs. Captured-response regression tests replay and
render these outputs offline without credentials or new API calls.

Read the [40-case report](reports/live-40-report.html) or
[machine-readable outcomes](reports/live-40-report.json). PubChem supplies formula
and connectivity references, not measured NMR shifts. This is **not a completed
40-prediction run or an experimental accuracy benchmark**. Model rejection of a
valid input is a recorded failure, not evidence that the molecule is invalid.

## Subsequent credential check

After the partial run, the owner added a new backend secret as `GEMINI_KEY_1`.
A project-server-authorized diagnostic on 1 November 2026 returned
`generation_ok` (HTTP 200) for both it and the existing `GEMINI_API_KEY`, using
`gemini-3.6-flash`. The deployed orchestrator already recognizes both secret
names. Neither credential is embedded in the application or these reports.
This later connectivity check does not change the earlier partial-run numbers
or the student's daily allowance. See the maintenance
[diagnostic documentation](../supabase/functions/gemini-key-health/README.md).
