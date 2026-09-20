# ChemBuddy v3.5.1 — Complete User & Technical Operating Manual
> **The Intelligent Academic Operating System for MSc Chemistry Students**  
> *Developed by Prajwal A Kambar*

---

## 📑 Table of Contents
1. [Introduction & Academic Architecture](#1-introduction--academic-architecture)
2. [Installation, Android Permissions & Initial Setup](#2-installation-android-permissions--initial-setup)
3. [🌟 Ask ChemBuddy AI — The Chemistry Intelligence Engine (FLAGSHIP FEATURE)](#3--ask-chembuddy-ai--the-chemistry-intelligence-engine-flagship-feature)
4. [Home Dashboard & Dynamic Contextual Greetings](#4-home-dashboard--dynamic-contextual-greetings)
5. [Smart Timetable & Attendance Intelligence Engine](#5-smart-timetable--attendance-intelligence-engine)
6. [Notification System & 1-Tap Action Shade (IST 8:30 AM Briefing)](#6-notification-system--1-tap-action-shade-ist-830-am-briefing)
7. [ChemDraw Pro & Ketcher Pro (118-Element Molecular Sketcher)](#7-chemdraw-pro--ketcher-pro-118-element-molecular-sketcher)
8. [Reaction Product Prediction & 2D Vector SVG Generator](#8-reaction-product-prediction--2d-vector-svg-generator)
9. [Spectroscopy & Chromatography Hub & Structure Solver](#9-spectroscopy--chromatography-hub--structure-solver)
10. [MSc Chemistry Toolkit & 16 Postgrad Calculators](#10-msc-chemistry-toolkit--16-postgrad-calculators)
11. [Pericyclic Hub & Woodward-Hoffmann FMO Engine](#11-pericyclic-hub--woodward-hoffmann-fmo-engine)
12. [Smart Flashcards & Spaced Repetition (Active Recall)](#12-smart-flashcards--spaced-repetition-active-recall)
13. [PDF Library, Study Hub & Strictly Grounded RAG Assistant](#13-pdf-library-study-hub--strictly-grounded-rag-assistant)
14. [Exam Mode & BCU Model Answer Generator](#14-exam-mode--bcu-model-answer-generator)
15. [Settings, Local Backup, Privacy & Offline Architecture](#15-settings-local-backup-privacy--offline-architecture)
16. [Troubleshooting & Frequently Asked Questions (FAQ)](#16-troubleshooting--frequently-asked-questions-faq)

---

## 1. Introduction & Academic Architecture
**ChemBuddy** is an advanced, offline-first mobile application designed specifically to eliminate the academic friction experienced by Master of Science (MSc) Chemistry postgraduates. Developed by **Prajwal A Kambar**, it merges rigorous chemoinformatics, high-precision spectroscopy solvers, attendance predictive mathematics, and state-of-the-art generative AI into a unified laboratory and classroom companion.

### Core Architectural Pillars
- **100% Offline Core Functionality**: Attendance math, timetable parsing, 16 chemistry calculators, Woodward-Hoffmann rules, spectroscopy databases, reaction prediction, and 2D vector SVG generation run entirely on-device with zero internet required.
- **Scientific Rigor**: Formulas, mechanisms, and spectroscopic peaks adhere strictly to IUPAC standards and standard graduate textbooks (Silverstein, Pavia, March, Clayden).
- **Privacy & Local Ownership**: Student profiles, attendance logs, notes, and PDFs reside in encrypted local Hive boxes.
- **Laboratory Ergonomics**: High-contrast dark theme (`#0A0914` canvas, `#8B5CF6` brand purple, `#06B6D4` cyan) protecting dark-adapted vision in laser labs.

---

## 2. Installation, Android Permissions & Initial Setup
1. **Download Release APK**: Obtain `ChemBuddy-v3.5.1-by-Prajwal-A-Kambar.apk` from the GitHub Releases page.
2. **Enable Unknown Sources**: Navigate to *Settings → Security → Install Unknown Apps* and allow installation.
3. **Grant Permissions**:
   - **Notifications**: For the 8:30 AM Timetable Briefing, 30-min class alerts, and 8:00 PM Psychology Facts.
   - **Exact Alarms (Android 12+)**: Ensures alerts fire with pinpoint accuracy.
   - **Battery Optimization**: Set to *Unrestricted* so Android Doze doesn't suppress notifications.
4. **Initial Profile Setup**: Input your Name, University/College, Semester, and Specialization (Organic, Inorganic, Physical, or Analytical).

---

## 3. 🌟 Ask ChemBuddy AI — The Chemistry Intelligence Engine (FLAGSHIP FEATURE)

> [!IMPORTANT]
> **ChemBuddy AI** is your 24/7 MSc Chemistry Research & Exam Companion. Accessible via the **Ask AI** bottom navigation tab or the Home Screen action card, it connects directly to Google Gemini models (with intelligent offline fallbacks) and provides 9 specialized academic modes, chemistry-aware speech recognition, and instant active recall flashcard generation.

### 3.1 Key Features of the ChemBuddy AI Interface
- **Horizontal Mode Scroller**: Instant switching between 9 specialized chemistry modes.
- **Chemistry-Aware Speech-to-Text**: Tap the pulsing microphone button (`🎙️`) to ask questions verbally. Spoken phrases are automatically normalized (e.g., "SN1" &rarr; $S_N1$, "Huckel rule" &rarr; $4n+2$, "H-NMR" &rarr; $^1\text{H NMR}$).
- **KaTeX Equation Box**: All chemical equations and thermodynamic formulas render in crisp LaTeX typography.
- **Curved Electron-Pushing Arrow Notation**: Step-by-step mechanism breakdowns detail electron displacement from nucleophiles to electrophiles.
- **1-Tap Flashcard Generation**: Turn any AI explanation into a Spaced Repetition (SM-2) flashcard with a single tap (`💾 Save as Flashcard`).
- **Interactive Viva Voce Practice**: Tap `🎤 Viva Practice` to launch an interactive oral exam simulation.

### 3.2 The 9 Specialized AI Modes
| Mode | Target Output | Best Used For |
|---|---|---|
| **1. Quick Answer** | High-yield, concise fact | Rapid lab lookups, boiling points, reagents, oxidation states, and formulas. |
| **2. General AI** | Broad generative reasoning | Open-ended chemistry discussions, general scientific writing, and research questions. |
| **3. Simple Explanation** | ELI5, jargon-free analogies | Breaking down intimidating concepts (e.g., Berry pseudorotation, NMR relaxation times). |
| **4. 2-Mark University Exam** | Concise, high-density definition | Section A questions: definitions, IUPAC rules, and single-equation answers. |
| **5. 5-Mark Exam Rubric** | Structured 5-section essay | Principle, Balanced Reaction, Stepwise Mechanism, Synthetic Scope, Summary. |
| **6. 10-Mark Full Rubric** | Comprehensive long-form essay | Long-form answers with curved arrows, orbital transition states, and stereochemical proofs. |
| **7. MSc Concept Deep-Dive** | Orbital & thermodynamic theory | FMO analysis, perturbation theory, and physical organic chemistry intuition. |
| **8. Stepwise Mechanisms** | Curved arrow electron flow | Detailed step-by-step reaction mechanisms, nucleophilic attacks, and driving forces. |
| **9. From My PDF (RAG)** | Strictly grounded in notes | Answers locked 100% to your uploaded syllabus or notes. Zero hallucinations. |

### 3.3 Multi-Key Gemini AI Orchestrator
- **High Availability**: Distributes requests across a multi-key pool with automatic round-robin rotation.
- **Automatic Failover**: Seamlessly shifts to fallback keys if a quota limit occurs.
- **Model Hierarchy**: Prioritizes `gemini-2.5-flash` &rarr; `gemini-2.0-flash` &rarr; `gemini-1.5-flash`.
- **Zero-Dead-End Offline Synthesizer**: If internet is unavailable, textbook offline databases generate intelligent answers.

---

## 4. Home Dashboard & Dynamic Contextual Greetings
- **40+ Contextual Greetings**: Dynamically adapting to time (late-night Bunsen burner, early morning, afternoon), day of week, and attendance tier (<75% danger warnings vs 85%+ praise).
- **Attendance Health Ring**: Real-time circular percentage meter indicating exam eligibility and safe bunks.
- **Daily Psychology Fact Card**: In-app widget rotating 120+ evidence-based cognitive insights daily at 8:00 PM IST with an on-demand shuffle button (`🔀`).
- **Quick Action Grid**: 1-tap shortcuts to Ask AI, ChemDraw Pro, Spectroscopy Solver, and 16 MSc Calculators.

---

## 5. Smart Timetable & Attendance Intelligence Engine
The attendance module uses predictive mathematical equations to keep students compliant with the 75% university eligibility cutoff.

### The 75% Cutoff Mathematics
1. **Classes Needed to Reach 75%**:
   $$\text{Needed} = \max\left(0, \lceil 3 \times \text{Absent} - \text{Present} \rceil\right)$$
   Indicates the exact consecutive classes required without a single absence to recover eligibility.

2. **Safe Bunks Available**:
   $$\text{Can Skip} = \max\left(0, \lfloor (\text{Present} - 3 \times \text{Absent}) / 3 \rfloor\right)$$
   Shows how many classes can be safely skipped while remaining strictly above 75.0%.

### Attendance States
- **Present (✅)**: Increments Present and Total counts.
- **Absent (❌)**: Increments Total count only.
- **Postponed / Cancelled (⏸️)**: **Excluded from calculations**. Does not penalize the student when a professor is absent or a holiday occurs.
- **Excused / On Duty (OD)**: Treated as Present for official university events or approved leave.

---

## 6. Notification System & Action Shade (1-Tap Attendance)
Anchored to the **Asia/Kolkata (IST)** timezone across 5 notification channels:

### 1-Tap Action Shade
When a class notification arrives in your Android notification shade, tap **Present ✅** or **Absent ❌** directly on the notification. ChemBuddy logs attendance to Hive storage immediately without needing to open the app!

### Notification Channels
| Channel ID | Name | Trigger Time | Description |
|---|---|---|---|
| `chem_buddy_classes` | Class reminders | 30m before class | Room, subject, attendance health %, and 1-tap Present / Absent buttons. |
| `chem_buddy_daily` | Daily timetable | 8:30 AM IST sharp | Morning briefing of all lectures, rooms, and attendance alerts. |
| `chem_buddy_psychology_facts` | Daily Psychology Facts | 8:00 PM IST sharp | Fascinating daily cognitive insight (120+ facts). |
| `chem_buddy_deadlines` | Tests & assignments | 24h & 2h before | Upcoming exams, submissions, and seminars. |
| `chem_buddy_flashcards` | Study & Flashcards | On review due date | Spaced repetition active recall reminders. |

---

## 7. ChemDraw Pro & Ketcher Pro (118-Element Molecular Sketcher)
- **118-Element Periodic Table**: Instant search by symbol, name, or atomic number with CPK coloring and category filters.
- **Drawing Tools**: Single, double, triple, wedge, and dash bonds, plus curved electron arrows (`⤴`).
- **Formal Charges**: `+1`, `-1`, `+2`, `-2`, and reset with circled badges & `M CHG` Molfile export.
- **Marquee Selection (`⬚`) & 2D Clean-Up (`🧹`)**: Select groups of atoms or standardize bond lengths to 55px.
- **Templates**: Non-destructive loading of Benzene, Cyclohexane, Pyridine, Steroid, Porphyrin, Aspirin, Naphthalene, Indole, Imidazole, Thiophene, Furan, 18-Crown-6, Ferrocene.
- **Multi-Reactant Mode**: Detects disconnected molecules with BFS graph partitioning, drawing a bold cyan `+` addition symbol between them and outputting dot-separated SMILES (`C1=CCC=C1.c1ccccc1`).

---

## 8. Reaction Product Prediction & 2D Vector SVG Generator
- **Gemini AI Internet Reaction Predictor**: Connects to Google Gemini over the internet to predict the major product, reaction classification (e.g., Diels-Alder `[4+2]`, EAS, Aldol), and step-by-step electron-pushing mechanisms.
- **Publication-Quality 2D Vector SVG Generator**: Standalone client-side SVG engine converting predicted SMILES into publication-grade 2D vector graphics with textbook coordinates and CPK heteroatoms, replacing raw text boxes.
- **45+ Instant Offline Reaction Rules (0ms)**: Predicts standard MSc reactions locally if offline.

---

## 9. Spectroscopy & Chromatography Hub & Structure Solver
- **8 Techniques**: RP-HPLC, GC, TLC, 500 MHz 1H NMR, 13C DEPT NMR, FT-IR, Mass Spectrometry, and UV-Vis.
- **Interactive Zoom & Pan (1.0x to 5.0x)**: Dedicated zoom toolbar and haptic peak snapping.
- **Textbook KaTeX Math**: Displays formulas and principles in crisp LaTeX notation.
- **52+ Curated Compounds Database**: Full spectral fingerprints for Aspirin, Paracetamol, Benzoic Acid, Salicylic Acid, Vanillin, etc.
- **Algorithmic Solver**: DBE calculation, FT-IR functional group classification, 1H NMR splitting analysis, and systematic ruling-out of constitutional isomers.

---

## 10. MSc Chemistry Toolkit & 16 Postgrad Calculators
- **Solutions**: Molar Mass, Molarity, Dilution ($C_1 V_1 = C_2 V_2$).
- **Acid-Base**: pH/pOH, Henderson-Hasselbalch, Buffer Formulation Assistant.
- **Thermodynamics & Kinetics**: Gibbs Free Energy, Arrhenius Rate Law.
- **Spectroscopy**: Beer-Lambert Law, Photon Energy & Wavelength.
- **Electrochemistry**: Nernst Equation, Standard Cell Potential.
- **Analytical Chromatography**: HPLC Calibration Curve ($y = mx + c$), Theoretical Plates ($N$), Resolution ($R_s$), Kovats Index ($I$).

---

## 11. Pericyclic Hub & Woodward-Hoffmann FMO Engine
- **Frontier Molecular Orbital (FMO) Theory**: Thermal vs Photochemical selection rules.
- **Electrocyclic Reactions**: $4n$ (Con/Dis) and $4n+2$ (Dis/Con).
- **Cycloadditions**: $[4+2]$ Diels-Alder (Endo-rule) and $[2+2]$ photo-additions.
- **Sigmatropic Rearrangements**: $[1,3]$, $[1,5]$, $[3,3]$ Cope and Claisen shifts.

---

## 12. Smart Flashcards & Spaced Repetition (Active Recall)
- **SuperMemo-2 (SM-2) Spaced Repetition**: Exponentially expanding review intervals.
- **4-Point Confidence Rating**: `Again (1)`, `Hard (2)`, `Good (3)`, `Easy (4)`.
- **Auto-Deck Creation**: Converts uploaded PDF notes or Ask ChemBuddy AI responses into active recall flashcards.

---

## 13. PDF Library, Study Hub & Strictly Grounded RAG Assistant
- **Offline PDF Viewer**: Smooth viewing, page navigation, and text extraction.
- **Strictly Grounded RAG Chat**: Constrained strictly to your uploaded notes (zero hallucinations).
- **8192 Token Complete Answers**: Comprehensive explanations with KaTeX math and ASCII reaction mechanisms.

---

## 14. Exam Mode & BCU Model Answer Generator
- **BCU & Central University Exam Blueprints**:
  - 2-Mark: Definitions, IUPAC names, concise statements.
  - 5-Mark: Mechanisms, intermediate structures, arrow pushing.
  - 10-Mark: Full synthesis pathways, retrosynthesis, spectroscopic proof.

---

## 15. Settings, Backup, Security & Offline Architecture
- **Notification Toggles**: Class reminders, 8:30 AM Timetable, 8:00 PM Psychology Facts, Deadlines, Flashcards.
- **Test Dispatch Buttons**: Send test class alert or test psychology fact notification instantly.
- **Local JSON Backup & Restore**: Full export/import of profile, timetable, and attendance.

---

## 16. Troubleshooting & FAQ
- **Q: Why didn't my 8:30 AM notification sound?**  
  *A:* Ensure "Alarms & Reminders" permission is granted on Android 12+, and set battery usage to "Unrestricted".
- **Q: Should I delete the older app or keep it?**  
  *A:* **Delete/uninstall the older app!** The new v3.5.1 APK has the updated graph-to-SMILES parser, Gemini AI reaction prediction, and 2D vector SVG engine compiled into the native binary.
- **Q: Does product prediction require internet?**  
  *A:* The 45+ offline reaction rules and `SmilesSvgGenerator` vector engine run 100% locally on-device. When connected to the internet, it additionally queries Google Gemini AI for advanced mechanisms.
- **Q: How does a cancelled class affect attendance?**  
  *A:* Mark as *Postponed / Cancelled (⏸️)* to exclude the class from calculations so your percentage is never penalized.

---
*ChemBuddy v3.5.1 — Engineered with ❤️ for MSc Chemistry Students worldwide by Prajwal A Kambar.*
