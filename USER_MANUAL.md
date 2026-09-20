# ChemBuddy v3.5.2 — Academic User & Technical Operating Manual

**The Comprehensive Academic Operating System for Master of Science (MSc) Chemistry Students, University Faculty & Research Scholars**

- **Author & Developer:** Prajwal A Kambar
- **Academic Affiliation:** Post-Graduate Department of Studies in Chemistry
- **Application Version:** v3.5.2 (Academic Production Release)
- **Target Audience:** MSc Chemistry Students, University Faculty & Researchers
- **Publication Date:** September 2026
- **Supported Platforms:** Android (API 26+), Web, Linux, macOS, Windows

---

## Table of Contents
1. [Introduction & Academic Architecture Overview](#1-introduction--academic-architecture-overview)
2. [Installation, System Requirements & Quick Setup](#2-installation-system-requirements--quick-setup)
3. [Personalized Onboarding & Decluttered Academic Dashboard](#3-personalized-onboarding--decluttered-academic-dashboard)
4. [Ask ChemBuddy (Intelligent Chemical Reasoning & Computational Tutor)](#4-ask-chembuddy-intelligent-chemical-reasoning--computational-tutor)
5. [Reaction Mechanisms & Step-by-Step Pathway Explorer](#5-reaction-mechanisms--step-by-step-pathway-explorer)
6. [Publication-Grade Reaction Export (PDF Dossier, Excel XLV/CSV & SVG)](#6-publication-grade-reaction-export-pdf-dossier-excel-xlvcsv--svg)
7. [ChemDraw Pro & Ketcher Canvas (118-Element Molecular Sketcher)](#7-chemdraw-pro--ketcher-canvas-118-element-molecular-sketcher)
8. [Reaction Product Prediction & 2D Vector SVG Generator](#8-reaction-product-prediction--2d-vector-svg-generator)
9. [Spectroscopy & Chromatography Suite (8 Analytical Techniques)](#9-spectroscopy--chromatography-suite-8-analytical-techniques)
10. [Spectroscopy Structure Solver Intelligence (52+ Benchmark Molecules)](#10-spectroscopy-structure-solver-intelligence-52-benchmark-molecules)
11. [MSc Chemistry Toolkit & 16 Postgrad Calculators](#11-msc-chemistry-toolkit--16-postgrad-calculators)
12. [Pericyclic Hub & Woodward-Hoffmann FMO Symmetry Engine](#12-pericyclic-hub--woodward-hoffmann-fmo-symmetry-engine)
13. [Smart Timetable & Attendance Intelligence Engine (The 75% Cutoff)](#13-smart-timetable--attendance-intelligence-engine-the-75-cutoff)
14. [Notification System & Action Shade (1-Tap Attendance Tracking)](#14-notification-system--action-shade-1-tap-attendance-tracking)
15. [Exporting Attendance Records (Institutional PDF & Excel XLV/CSV)](#15-exporting-attendance-records-institutional-pdf--excel-xlvcsv)
16. [Smart Flashcards & Spaced Repetition (SuperMemo-2 Active Recall)](#16-smart-flashcards--spaced-repetition-supermemo-2-active-recall)
17. [PDF Library, Study Hub & Grounded Academic RAG Assistant](#17-pdf-library-study-hub--grounded-academic-rag-assistant)
18. [Exam Mode & BCU Model Answer Generator](#18-exam-mode--bcu-model-answer-generator)
19. [Daily Cognitive & Learning Science Facts (120+ Curated Insights)](#19-daily-cognitive--learning-science-facts-120-curated-insights)
20. [Laboratory Safety & GHS Hazard Library](#20-laboratory-safety--ghs-hazard-library)
21. [Offline Security, Local Encrypted Storage & Data Portability](#21-offline-security-local-encrypted-storage--data-portability)
22. [Troubleshooting & Frequently Asked Questions (FAQ)](#22-troubleshooting--frequently-asked-questions-faq)

---

## 1. Introduction & Academic Architecture Overview

**ChemBuddy** is an advanced, offline-first academic operating system designed exclusively for Master of Science (MSc) Chemistry students, researchers, and university faculties. Unlike generic student planners or basic scientific calculator tools, ChemBuddy integrates specialized chemoinformatics algorithms, textbook-grade spectroscopy simulation tools, attendance forecasting mathematics, and chemical reasoning systems into a single, unified, privacy-respecting environment.

### Core Engineering Principles
- **100% Offline Core Capabilities:** Timetable intelligence, attendance buffer calculations, 16 physical chemistry calculators, Woodward-Hoffmann pericyclic selection rules, spectroscopy databases, reaction prediction, and 2D vector SVG generation execute completely on-device without requiring an internet connection.
- **Curriculum Grounding:** All chemical formulas, reaction mechanisms, spectroscopic tables, and mathematical derivations strictly adhere to IUPAC nomenclature and standard postgraduate reference texts (*Silverstein, Pavia, March, Clayden, Carey-Sundberg, Miessler-Tarr*).
- **Data Privacy & Local Sovereignty:** Student profiles, attendance records, study notes, and PDF documents remain stored locally in high-performance encrypted storage boxes. Cloud synchronization is entirely optional.
- **Laboratory Ergonomics:** The interface uses a specialized dark-mode palette (`#0A0914` canvas, `#7C3AED` primary purple, `#06B6D4` cyan, `#F59E0B` gold) engineered to protect dark-adapted eyes in laser spectroscopy rooms, darkrooms, and low-light laboratory settings.

---

## 2. Installation, System Requirements & Quick Setup

ChemBuddy is distributed as an optimized Android APK and standalone cross-platform application package.

### System Requirements
| Parameter | Minimum Requirement | Recommended Specification |
| :--- | :--- | :--- |
| **Operating System** | Android 8.0 (Oreo, API Level 26) | Android 11.0+ (API Level 30+) |
| **RAM** | 2 GB RAM | 4 GB+ RAM (for large PDF caching & 3D rendering) |
| **Storage Space** | 85 MB free disk space | 250 MB free disk space (for offline databases) |
| **Display** | 720 × 1280 pixels | 1080 × 2400 pixels (AMOLED recommended) |

### Installation Steps
1. **Download Release Package:** Download `ChemBuddy-v3.5.2-by-Prajwal-A-Kambar.apk` from the official university repository or GitHub release page.
2. **Enable Package Installation:** On Android, navigate to *Settings → Security → Install Unknown Apps* and authorize your file manager.
3. **Run Package Installer:** Open the downloaded file and select **Install**.
4. **Grant Essential Permissions:**
   - **Notifications:** Required for the 8:30 AM morning timetable briefing, advance class alerts, and evening cognitive insights.
   - **Exact Alarms (Android 12+):** Ensures schedule notifications trigger with minute-precise accuracy.
   - **Storage / Media:** Required for importing syllabus PDFs, research papers, and exporting attendance or reaction dossiers.
5. **Profile Initialization:** On first launch, enter your Full Name, University/College Name (e.g., Bangalore City University), Academic Semester (Semester 1 through 4), and Specialization Branch (Organic, Inorganic, Physical, or Analytical Chemistry).

---

## 3. Personalized Onboarding & Decluttered Academic Dashboard

ChemBuddy v3.5.2 introduces a refined, decluttered header layout that balances clean typography with immediate access to daily academic tasks.

### Personalized Identity & Greeting Logic
The system replaces all generic greetings with the student's actual name entered during registration (stored in the local repository as `fullName` or extracted from `registerNumber`, defaulting gracefully to `Prajwal`).

The greeting dynamically adapts to the current hour and attendance standing:
- **00:00 – 04:59 (Late Night Synthesis):** *"Burning the midnight burner, [Name] 🔬"*
- **05:00 – 11:59 (Morning Energy):** *"Good morning, [Name] 👋"*
- **12:00 – 16:59 (Afternoon Laboratory):** *"In the flow, [Name] 📚"*
- **17:00 – 23:59 (Evening Study):** *"Good evening, [Name] 🌌"*

### Decluttered Layout Architecture
To prevent interface clutter on mobile devices, the top header height has been reduced from ~250px to **~65px**:
- **Single-Line Compact Greeting:** Rendered with a clean 17px font weight, constrained to a single line with ellipsis truncation to avoid text wrapping.
- **Persistent Quick Actions:** Notification toggle, global search, and profile status icons are positioned in a streamlined horizontal row.
- **Daily Chem Pulse:** Directly below the greeting, students see their active attendance status badge, next scheduled class countdown, and quick-launch shortcuts to the molecular sketcher, calculators, and spectroscopy tools.

---

## 4. Ask ChemBuddy (Intelligent Chemical Reasoning & Computational Tutor)

**Ask ChemBuddy** is a specialized chemical reasoning tutor designed to guide postgraduate students through complex chemistry concepts, mechanism pathways, spectroscopic interpretation, and computational derivations.

### Academic Scope & Capabilities
- **Organic Reaction Mechanisms:** Detailed breakdowns of nucleophilic/electrophilic substitutions, additions, eliminations, rearrangement mechanisms (*Pinacol, Beckmann, Baeyer-Villiger, Hofmann, Curtius*), and organometallic catalytic cycles (*Heck, Suzuki, Stille, Grubbs*).
- **Spectroscopic Deduction:** Step-by-step interpretation of multi-spectral problems combining 1H NMR, 13C DEPT, FT-IR, and Mass Spectrometry data to deduce constitutional and stereochemical structures.
- **Physical Chemistry Derivations:** Rigorous step-by-step mathematical derivations of thermodynamic potentials, Maxwell relations, rate laws, quantum mechanical operators (particle in a box, harmonic oscillator), and electrochemistry equations.
- **Inorganic Chemistry & Coordination Complexes:** Crystal Field Theory (CFT), Ligand Field Theory (LFT), Jahn-Teller distortion, Tanabe-Sugano diagrams, magnetic susceptibility, and Wade's rules for cluster compounds.

### Structured Presentation Format
1. **Core Principle / Theorem:** Clear statement of the underlying chemical law or concept.
2. **Mathematical / Mechanistic Formulation:** Step-by-step derivation or electron movement sequence.
3. **Reaction Conditions & Reagents:** Stoichiometry, solvents, temperature requirements, and catalysts.
4. **Stereochemical & Regiochemical Outcomes:** Retention, inversion, Markovnikov/anti-Markovnikov, endo/exo preferences.
5. **Exam Summary / Key Takeaways:** Concise summary points optimized for university answer scripts.

---

## 5. Reaction Mechanisms & Step-by-Step Pathway Explorer

The Reaction Mechanisms module provides a comprehensive compendium of organic transformations taught across advanced master's programs.

### Comprehensive Reaction Catalog
| Reaction Category | Representative Examples | Key Mechanistic Focus |
| :--- | :--- | :--- |
| **Nucleophilic Substitution & Elimination** | SN1, SN2, SNi, E1, E2, E1cB | Leaving group ability, solvent polarity, carbocation stability, anti-periplanar geometry. |
| **Electrophilic Aromatic Substitution (EAS)** | Nitration, Friedel-Crafts, Halogenation | Arenium ion (sigma complex) intermediate, directing effects of activating/deactivating substituents. |
| **Named Carbonyl Condensations** | Aldol, Claisen, Dieckmann, Knoevenagel, Mannich | Enolate generation, nucleophilic addition to carbonyl, dehydration driving forces. |
| **Rearrangements & Migrations** | Beckmann, Hofmann, Curtius, Lossen, Favorskii | Electron-deficient nitrogen/carbon migration, stereospecificity, migratory aptitude. |
| **Oxidation & Reduction** | Swern, PCC, Jones, Dess-Martin, Birch Reduction | Chemoselectivity, partial vs full oxidation, radical anion mechanisms. |
| **Transition-Metal Catalysis** | Suzuki-Miyaura, Heck, Sonogashira, Stille | Oxidative addition, transmetalation, migratory insertion, reductive elimination cycles. |

### Step-by-Step Mechanistic Breakdown
- **Step Number & Transformation:** Clear identification of what chemical event occurs (e.g., *Step 1: Enolate Formation by Base Deprotonation*).
- **Curved Arrow Electron Movement:** Explicit textual and diagrammatic description of electron pair movement from nucleophile to electrophile.
- **Reactive Intermediates:** Identification of carbocations, carbanions, free radicals, carbenes, or cyclic transition states.
- **Driving Force:** Thermodynamic and kinetic factors driving the reaction forward (e.g., release of aromatic stabilization, formation of gaseous CO2 or N2, precipitation of salt).

---

## 6. Publication-Grade Reaction Export (PDF Dossier, Excel XLV/CSV & SVG)

ChemBuddy v3.5.2 features an updated export engine (`ExportService`) designed to produce publication-grade documentation for laboratory records, seminars, research presentations, and departmental reviews.

### Export Formats & Structural Specifications
| Format | Output Extension | Structure & Content Included |
| :--- | :--- | :--- |
| **Academic PDF Dossier** | `.pdf` | 0.5-inch margins with deep purple (#4C1D95) institutional styling; reaction equation banner and dedicated SVG vector scheme diagram; comprehensive chemical properties grid; step-by-step mechanism table; applications and running page footer (`Page X of Y`). |
| **Excel Spreadsheet (XLV/CSV)** | `.csv` | Preceded by a UTF-8 Byte Order Mark (`\uFEFF`) for seamless 1-click opening in Microsoft Excel; full metadata columns; dedicated Step-by-Step Mechanism breakdown column; embedded standalone SVG vector markup. |
| **Standalone Vector Graphic** | `.svg` | Pure scalable vector XML markup with standard atom coordinate geometry; crisp rendering at any zoom level. |

### In-App Export Workflow
1. **Single Reaction Dossier:** Navigate to any reaction in the Reaction Explorer, tap the **Export / Share** icon in the top AppBar, and select your preferred format.
2. **Full Compendium Export:** On the main Reaction Mechanism catalog screen, tap the **Download** icon in the AppBar to export the entire library as a comprehensive multi-reaction Excel database or master PDF compendium.

---

## 7. ChemDraw Pro & Ketcher Canvas (118-Element Molecular Sketcher)

ChemBuddy includes a chemical structure drawing canvas optimized for mobile touchscreens, tablets, and desktop input devices.

### 118-Element Periodic Table Selection Palette
Tap the element button or the `🧪` icon to open the complete 118-element IUPAC periodic table modal:
- **Search & Filter:** Real-time filtering by element symbol (`Fe`), English name (`Iron`), or atomic number (`26`).
- **Standard CPK Coloring:** All elements follow standard CPK color conventions.
- **Coordination Complex Support:** Full access to transition metals, lanthanides, and actinides for organometallic and inorganic coordination geometry sketches.

### Canvas Drawing Tools & Gestures
| Tool / Icon | Tool Name | Operation & Functionality |
| :--- | :--- | :--- |
| **— / = / ≡** | Bonds | Draws single, double, or triple covalent bonds between atoms with automatic angle snapping (30°, 60°, 120°). |
| **▲ / ▰** | Stereo Bonds | Wedge (solid) and Dash (hashed) bonds for defining R/S stereocenters and 3D spatial orientation. |
| **⤴** | Electron Arrow | Curved arrows for drawing arrow-pushing mechanisms, resonance structures, and orbital interactions. |
| **⬚** | Marquee Selection | Select, drag, rotate, or delete groups of atoms and bonds collectively. |
| **🧹** | 2D Clean-Up | Standardizes all bond lengths to 55px and snaps bond angles to idealized textbook geometries. |
| **+ / -** | Formal Charges | Applies formal charges (+1, -1, +2, -2) and exports `M CHG` records in MDL Molfiles. |
| **→** | Reaction Arrow | Draws a horizontal reaction arrow separating reactants from products directly on the canvas. |
| **🔍** | Pinch & Pan | Two-finger pinch to zoom (0.3x to 3.0x) and two-finger drag to pan across large schemes. Tap 🔍 to reset view. |

---

## 8. Reaction Product Prediction & 2D Vector SVG Generator

### Deterministic Offline Reaction Engine
When reactants are drawn on the canvas or provided via SMILES notation and the user taps **Predict Product ⚡**, the system evaluates the transformation against its local rule database:
- **Pharmaceutical Syntheses:** Salicylic Acid + Acetic Anhydride $ightarrow$ Aspirin; 4-Aminophenol + Acetic Anhydride $ightarrow$ Paracetamol; Aniline + Acetic Anhydride $ightarrow$ Acetanilide.
- **Esterification:** Benzoic Acid / Carboxylic acids + Alcohols (with acid catalyst) $ightarrow$ Esters.
- **Electrophilic Aromatic Substitution (EAS):** Nitration, Bromination, Sulfonation, Friedel-Crafts Alkylation & Acylation.
- **Named Condensations:** Kolbe-Schmitt, Reimer-Tiemann, Williamson Ether Synthesis, Aldol Condensation, Cannizzaro, Benzoin, Diels-Alder.
- **Functional Group Interconversions:** Carbonyl reductions, alcohol oxidations, and nucleophilic additions.

### Client-Side 2D Vector SVG Engine (`SmilesSvgGenerator`)
- **Textbook Coordinate Calibration:** Uses calibrated 2D coordinates for all major ring systems, preserving standard aromatic orientations.
- **Graph Layout Parser:** Converts arbitrary SMILES strings into connected molecular graphs with 120° zig-zag aliphatic chains and double/triple bond offsets.
- **Heteroatom Masking:** Draws circular background masks behind heteroatom labels to cleanly occlude intersecting bond lines.
- **Resolution Independence:** Generates clean SVG markup that scales infinitely without degradation on high-DPI screens or printed media.

---

## 9. Spectroscopy & Chromatography Suite (8 Analytical Techniques)

The Spectroscopy Hub covers the 8 core analytical and spectroscopic methods central to postgraduate chemical analysis:
1. **Reverse-Phase HPLC (Chromatography):** Retention factor ($k'$), resolution ($R_s$), theoretical plate count ($N$), and peak asymmetry/tailing ($T_f$).
2. **Gas Chromatography (Chromatography):** Kovats retention index ($I$), Van Deemter equation ($H = A + B/u + Cu$), and carrier gas optimization.
3. **Thin Layer Chromatography (Chromatography):** Retention factor ($R_f = d_{\text{solute}} / d_{\text{solvent}}$) and mobile phase polarity screening.
4. **500 MHz 1H NMR (Spectroscopy):** Chemical shift values ($\delta$, ppm), scalar coupling constants ($J$, Hz), proton integration, and multiplicity splitting patterns.
5. **13C DEPT NMR (Spectroscopy):** Carbon-13 chemical shifts with DEPT-45, DEPT-90, and DEPT-135 discrimination of quaternary, CH, CH2, and CH3 carbons.
6. **FT-IR Spectroscopy (Spectroscopy):** Characteristic functional group stretching frequencies ($ar{\nu}$, $\text{cm}^{-1}$), Hooke's law calculations, and reduced mass ($\mu$).
7. **Mass Spectrometry (Spectroscopy):** Molecular ion ($M^+$), base peak, isotope abundance clusters ($M+1$, $M+2$ for Cl and Br), and fragmentation pathways.
8. **UV-Visible Spectroscopy (Spectroscopy):** Beer-Lambert law ($A = \varepsilon c l$), $\lambda_{\max}$ estimation via Woodward-Fieser rules.

---

## 10. Spectroscopy Structure Solver Intelligence (52+ Benchmark Molecules)

### Curated MSc Chemistry Database (52+ Compounds)
Contains complete spectral fingerprints ($^1\text{H}$ NMR, $^{13}\text{C}$ NMR, FT-IR, MS, UV-Vis) for over 52 postgraduate benchmark molecules (*Aspirin, Paracetamol, Benzoic Acid, Salicylic Acid, Benzaldehyde, Phenol, Aniline, Nitrobenzene, Toluene, Benzyl Alcohol, Acetophenone, Benzocaine, 1-Bromopropane, 2-Bromopropane, Vanillin, etc.*).

### 4-Step Algorithmic Deduction Framework
1. **Degree of Unsaturation / Double Bond Equivalent (DBE / IHD):**
   $$\text{DBE} = C + 1 - \frac{H}{2} - \frac{X}{2} + \frac{N}{2}$$
2. **FT-IR Functional Group Classification:** Identifies key diagnostic bands (carbonyls, hydroxyls, amines, aromatic stretches).
3. **1H NMR Chemical Shift & Splitting Analysis:** Distinguishes constitutional isomers based on integration and coupling.
4. **Constitutional Isomer Elimination:** Explains systematically why alternative isomers matching the formula are ruled out.

---

## 11. MSc Chemistry Toolkit & 16 Postgrad Calculators

The Chemistry Toolkit consolidates 16 high-precision calculators across 6 dedicated tabs:

| Category Tab | Calculator Name | Governing Mathematical Formulation |
| :--- | :--- | :--- |
| **Solutions** | Molar Mass Calculator | $\text{MW} = \sum n_i \cdot M_i$ |
| **Solutions** | Molarity Calculator | $M = \frac{m}{MW \times V_{\text{liters}}}$ |
| **Solutions** | Dilution Assistant | $C_1 V_1 = C_2 V_2$ |
| **Acid-Base** | pH & pOH Calculator | $\text{pH} = -\log[H^+]$, $\text{pH} + \text{pOH} = 14$ |
| **Acid-Base** | Henderson-Hasselbalch | $\text{pH} = \text{p}K_a + \log([\text{A}^-]/[\text{HA}])$ |
| **Acid-Base** | Buffer Formulation | Exact masses of weak acid and conjugate base required for target buffer pH. |
| **Thermo & Kinetics** | Gibbs Free Energy | $\Delta G = \Delta H - T\Delta S$ |
| **Thermo & Kinetics** | Arrhenius Rate Law | $k = A e^{-E_a / RT}$, $\ln(k_2/k_1) = \frac{E_a}{R}(1/T_1 - 1/T_2)$ |
| **Spectroscopy** | Beer-Lambert Law | $A = \varepsilon \cdot b \cdot c$ |
| **Spectroscopy** | Photon Energy & Wavelength | $E = h\nu = \frac{hc}{\lambda}$ |
| **Electrochemistry** | Nernst Equation | $E = E^\circ - \frac{0.05916}{n}\log_{10} Q$ (at 298.15 K) |
| **Electrochemistry** | Standard Cell Potential | $E^\circ_{\text{cell}} = E^\circ_{\text{cathode}} - E^\circ_{\text{anode}}$ |
| **Analytical** | HPLC Calibration Curve | Linear regression ($y = mx + c$), $R^2$, and unknown quantification. |
| **Analytical** | Theoretical Plates ($N$) | $N = 16 (t_R/W)^2 = 5.54 (t_R/W_{1/2})^2$ |
| **Analytical** | Chromatographic Resolution ($R_s$) | $R_s = \frac{2(t_{R2} - t_{R1})}{W_1 + W_2}$ |
| **Analytical** | Kovats Retention Index ($I$) | Logarithmic retention index relative to n-alkane standards. |

---

## 12. Pericyclic Hub & Woodward-Hoffmann FMO Symmetry Engine

| Reaction Type | Electron System | Thermal ($\Delta$) Mode | Photochemical ($h
u$) Mode |
| :--- | :--- | :--- | :--- |
| **Electrocyclic** | $4n$ electrons | **Conrotatory** (HOMO $\psi_2$) | **Disrotatory** (HOMO $\psi_3$) |
| **Electrocyclic** | $4n+2$ electrons | **Disrotatory** (HOMO $\psi_3$) | **Conrotatory** (HOMO $\psi_4$) |
| **Cycloadditions** | $4n$ electrons | Symmetry Forbidden | **Symmetry Allowed** ($[\pi 2s + \pi 2s]$) |
| **Cycloadditions** | $4n+2$ electrons | **Symmetry Allowed** ($[\pi 4s + \pi 2s]$) | Symmetry Forbidden |
| **Sigmatropic** | $[1,3]$ Hydrogen Shift | Symmetry Forbidden | **Symmetry Allowed** |
| **Sigmatropic** | $[1,5]$ & $[3,3]$ (Cope, Claisen) | **Symmetry Allowed** (Chair-like) | Symmetry Forbidden |

---

## 13. Smart Timetable & Attendance Intelligence Engine (The 75% Cutoff)

The attendance module in ChemBuddy is an analytical forecasting engine designed to ensure strict compliance with university regulations.

### The 75% Cutoff Mathematics
1. **Classes Needed to Recover 75% (Target Equation):**
   $$\text{Classes Needed} = \max(0, \lceil 3 \times \text{Absent} - \text{Present} \rceil)$$
2. **Safe Classes That Can Be Skipped (Buffer Equation):**
   $$\text{Safe Bunks Available} = \max(0, \lfloor (\text{Present} - 3 \times \text{Absent}) / 3 \rfloor)$$

### Supported Attendance Statuses
- **Present (✅):** Increments both Present and Total Count.
- **Absent (❌):** Increments Total Count; Present count unchanged.
- **Postponed / Cancelled (⏸️):** Excluded entirely from calculation; does not penalize student.
- **Excused / On Duty (OD):** Treated as Present for official university events or medical leave.

---

## 14. Notification System & Action Shade (1-Tap Attendance Tracking)

ChemBuddy features an automated background notification engine synchronized to the **Asia/Kolkata (IST)** timezone across 5 dedicated channels:
1. **Class Reminders (`chem_buddy_classes`):** 30 minutes prior to class with 1-tap **Present ✅** and **Absent ❌** action buttons.
2. **Daily Timetable (`chem_buddy_daily`):** Every morning at **8:30 AM IST** with complete schedule summary.
3. **Daily Psychology Facts (`chem_buddy_psychology_facts`):** Every evening at **8:00 PM IST** with learning science insights.
4. **Tests & Deadlines (`chem_buddy_deadlines`):** 24h & 2h prior to deadlines.
5. **Study & Flashcards (`chem_buddy_flashcards`):** Prompts for spaced repetition reviews.

---

## 15. Exporting Attendance Records (Institutional PDF & Excel XLV/CSV)

- **Institutional PDF Report:** Formatted with official university headers, student registration number, department name, subject-wise lecture breakdown (Total, Attended, Missed, Percentage), and eligibility status certification.
- **Excel Spreadsheet (XLV/CSV):** Formatted with a UTF-8 Byte Order Mark (BOM) for direct compatibility with Microsoft Excel, featuring date-stamped audit logs.

---

## 16. Smart Flashcards & Spaced Repetition (SuperMemo-2 Active Recall)

Implements the **SuperMemo-2 (SM-2) algorithm** to support long-term memorization of reaction mechanisms, reagents, and spectroscopic data:
- **Active Recall Testing:** Front-to-back card flip testing.
- **Recall Quality Rating (1 to 4):** `Again (1)`, `Hard (2)`, `Good (3)`, `Easy (4)`.
- **Automated Deck Generation:** Converts notes into study decks.

---

## 17. PDF Library, Study Hub & Grounded Academic RAG Assistant

- **Strictly Grounded Retrieval:** In the PDF Study Hub, the assistant is constrained strictly to the extracted text of the uploaded PDF document.
- **Standardized Refusal:** If a query is outside the document, the assistant states: *"This topic is not covered in the provided document."*
- **Extended Token Output:** Supports comprehensive answers up to 8,192 tokens formatted with mathematical typography.

---

## 18. Exam Mode & BCU Model Answer Generator

Calibrated to Bangalore City University (BCU) and Indian university examination patterns:
- **2-Mark Question Mode:** Concise definitions and fundamental statements.
- **5-Mark Question Mode:** Step-by-step mechanisms and intermediate structures.
- **10-Mark Question Mode:** Comprehensive essays, retro-synthetic analysis, and spectroscopic validation.

---

## 19. Daily Cognitive & Learning Science Facts (120+ Curated Insights)

120+ evidence-based insights across Cognitive Biases, Memory Psychology, Neurobiology, and Academic Habits.

### Prime-Weighted Non-Repeating Distribution Formula
$$\text{Index} = (\text{Year} \times 365 + \text{DayOfYear} \times 47 + \text{Month} \times 13) \pmod{\text{TotalFacts}}$$

---

## 20. Laboratory Safety & GHS Hazard Library

- **GHS Pictograms & Hazard Codes:** H-statements and P-statements.
- **Chemical Incompatibility Matrix:** Critical hazard warnings for strong oxidizers, acids, and water-reactive reagents.
- **First Aid Protocols:** Immediate response protocols for acid burns, alkali splashes, and vapor inhalation.

---

## 21. Offline Security, Local Encrypted Storage & Data Portability

- **Encrypted Local Storage:** Student profiles, attendance logs, and notes are stored in encrypted binary format on the user's device.
- **Complete Data Portability:** Export complete profile, timetable, and attendance records as a structured JSON file at any time.
- **Zero Unsolicited Data Transmission:** No student personal data, attendance logs, or sketcher data is transmitted to external servers.

---

## 22. Troubleshooting & Frequently Asked Questions (FAQ)

- **Q1: Why did the 8:30 AM morning timetable notification not trigger?**  
  *Resolution:* On Android 12+, confirm that *"Alarms & Reminders"* permission is granted and set battery optimization for ChemBuddy to *"Unrestricted"*.
- **Q2: Can coordination complexes and organometallics be sketched in ChemDraw Pro?**  
  *Resolution:* Yes. Open the 118-element periodic table palette, select the transition metal center, and use coordination bonds.
- **Q3: How does ChemBuddy handle attendance for cancelled or rescheduled lectures?**  
  *Resolution:* Mark the lecture as *Postponed / Cancelled (⏸️)*. ChemBuddy removes that class slot from both numerator and denominator.
- **Q4: Does reaction prediction or SVG generation require an active internet connection?**  
  *Resolution:* No. The offline reaction rule engine and `SmilesSvgGenerator` vector layout engine run entirely on-device with zero latency.
- **Q5: How can attendance records and reaction mechanisms be presented to university faculty?**  
  *Resolution:* Use the built-in export engine to generate either an official Academic PDF Dossier or an Excel Spreadsheet (XLV/CSV) with UTF-8 BOM encoding.

---

*ChemBuddy v3.5.2 Operating Manual — Engineered for MSc Chemistry Students, University Faculty & Research Scholars worldwide by Prajwal A Kambar.*
