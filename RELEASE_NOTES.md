# ChemBuddy 3.5.6 by Prajwal A Kambar

- Rebuilds the structure solver with separate entered and expected spectra, SVG proton/carbon NMR, IR and mass previews, reference assignments and formula-checked candidate structures.
- Tightens formula, DBE and peak matching; conflicting or insufficient evidence stays unresolved instead of forcing an exact compound.
- Adds eight guided deduction steps, from molecular formula and DBE to fragment assembly, alternative isomers and final verification, with MSc checkpoints.
- Adds percentage-composition problems, empirical/molecular formula calculations, oxygen-by-difference as an explicit option, and direct transfer into the solver.
- Makes the bundled molecular sketcher light, adds connectivity/valence/formula checks, restores bounded SMILES import, removes atom-count identity guesses and fixes molfile indices after atom deletion.
- Fixes the populated attendance crash caused by a dynamic extension lookup; adapts schedule cards, controls and simulator to narrow screens and larger text.

Predicted spectra are educational references, not experimental measurements. Sparse spectra may admit multiple structures. The sketcher rejects import syntax it cannot preserve, including isotope and stereochemical annotations.

Production signing is used when configured. Otherwise the APK is the separate ChemBuddy Preview app for testing.

# ChemBuddy 3.5.5 by Prajwal A Kambar

- Theme editing now lives directly in Profile: display mode, Classic/Fan/Prism collections, glass finish, collection-aware Surprise me and Undo.
- Expands the Fan collection with Papaya Grid, Rosso, Centre Court, Neon Arcade, Deep Orbit and Reef, inspired by racing, tennis, gaming, space and the ocean.
- Adds six coordinated three-colour Prism gradients with readable Material 3 roles and tinted glass surfaces.
- Rebuilds the chemistry toolkit, spectroscopy hub and pericyclic hub around searchable overviews and focused, state-preserving workspaces.
- Adds three optional chemistry Easter eggs and a device-local Curiosity cabinet.
- Expands the first-launch welcome with clear setup, guest, offline and cloud-AI guidance; rebuilds the post-login tour with consistent theme colours and readable cards.
- Retains quick-tap spring feedback, reduced-motion support and the earlier security and reliability fixes.

Production signing is used when configured. Otherwise the APK is a separately installed ChemBuddy Preview test app. Database deployment and rotation of previously embedded provider keys remain separate live steps.

---

# ChemBuddy 3.5.4 by Prajwal A Kambar

- Added a floating liquid-glass navigation dock, elastic selection indicators and subtle spring feedback across buttons, chips, cards and page transitions, with reduced-motion support.
- Refined Material 3 Expressive typography, spacing, buttons and glass surfaces.
- Strong dark text on light themes, with readable semantic and subject colors.
- Added a separate Fan collection: Blancos (black and white), Pellara (yellow and charcoal), and RCB (red, black and gold), each with light and dark modes.
- Light, Dark and System modes across twelve palettes, with Surprise me and saved glass finishes.
- Redesigned welcome, university, semester and subject setup with a calmer layout.
- Added Continue as guest: local study data stays separate from signed-in accounts and is retained between guest visits.
- Added confirmation before leaving the app with Android's root Back action; normal page navigation is preserved.
- Included the reviewed security, sync reliability, PDF export, attendance and chemistry-tool fixes.

Guest mode supports local notes, attendance and study tools. Sign in for cloud AI. Backend hardening files and deployment instructions are included; they do not deploy the database or server automatically.

The workflow publishes a production-signed APK when signing secrets are configured. Otherwise it publishes an explicitly labeled mobile preview app with a separate package so it can be installed alongside an existing version.
