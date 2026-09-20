# ChemBuddy v3.5.0 — Complete User & Technical Operating Manual
> **The Intelligent Academic Operating System for MSc Chemistry Students**  
> *Developed by Prajwal A Kambar*

---

## 📑 Table of Contents
1. [Introduction & Architecture Overview](#1-introduction--architecture-overview)
2. [Installation & Quick Setup](#2-installation--quick-setup)
3. [Smart Timetable & Attendance Intelligence Engine](#3-smart-timetable--attendance-intelligence-engine)
4. [Notification System & Action Shade (1-Tap Attendance)](#4-notification-system--action-shade-1-tap-attendance)
5. [Daily Psychology Facts Engine (120+ Curated Facts)](#5-daily-psychology-facts-engine-120-curated-facts)
6. [Home Dashboard & Intelligent Contextual Greeting](#6-home-dashboard--intelligent-contextual-greeting)
7. [ChemDraw Pro & Ketcher Pro (118-Element Molecular Sketcher)](#7-chemdraw-pro--ketcher-pro-118-element-molecular-sketcher)
8. [Reaction Product Prediction & 2D Vector SVG Generator](#8-reaction-product-prediction--2d-vector-svg-generator)
9. [Spectroscopy & Chromatography Hub (KaTeX & Zoomable Spectrum)](#9-spectroscopy--chromatography-hub-katex--zoomable-spectrum)
10. [Spectroscopy Structure Solver Intelligence (52+ Molecules)](#10-spectroscopy-structure-solver-intelligence-52-molecules)
11. [MSc Chemistry Toolkit & 16 Postgrad Calculators](#11-msc-chemistry-toolkit--16-postgrad-calculators)
12. [Pericyclic Hub & Woodward-Hoffmann FMO Engine](#12-pericyclic-hub--woodward-hoffmann-fmo-engine)
13. [Smart Flashcards & Spaced Repetition (Active Recall)](#13-smart-flashcards--spaced-repetition-active-recall)
14. [PDF Library, Study Hub & Strictly Grounded RAG Assistant](#14-pdf-library-study-hub--strictly-grounded-rag-assistant)
15. [Exam Mode & BCU Model Answer Generator](#15-exam-mode--bcu-model-answer-generator)
16. [Settings, Backup, Security & Offline Architecture](#16-settings-backup-security--offline-architecture)
17. [Troubleshooting & Frequently Asked Questions (FAQ)](#17-troubleshooting--frequently-asked-questions-faq)

---

## 1. Introduction & Architecture Overview
**ChemBuddy** is an offline-first mobile and desktop application created exclusively for Master of Science (MSc) Chemistry students, researchers, and educators. It combines chemoinformatics tools, spectroscopy analyzers, attendance mathematics, and grounded artificial intelligence in a unified, privacy-focused interface.

### Core Architectural Pillars
- **100% Offline Core Functionality**: Attendance math, timetable parsing, 16 chemistry calculators, Woodward-Hoffmann rules, spectroscopy databases, reaction prediction, and 2D vector SVG generation run entirely on-device with zero internet required.
- **Scientific Rigor**: Formulas, mechanisms, and spectroscopic peaks adhere strictly to IUPAC standards and standard graduate textbooks (Silverstein, Pavia, March, Clayden).
- **Privacy & Local Ownership**: Student profiles, attendance logs, notes, and PDFs reside in encrypted local Hive boxes.
- **Laboratory Ergonomics**: High-contrast dark theme (#0A0914 canvas, #8B5CF6 brand purple, #06B6D4 cyan) protecting dark-adapted vision in laser labs.

---

## 2. Installation & Quick Setup
1. **Download Release APK**: Obtain `ChemBuddy-v3.5.0-by-Prajwal-A-Kambar.apk` from the GitHub Releases page.
2. **Enable Unknown Sources**: Navigate to *Settings → Security → Install Unknown Apps* and allow installation.
3. **Grant Permissions**:
   - **Notifications**: For the 8:30 AM Timetable Briefing, 30-min class alerts, and 8:00 PM Psychology Facts.
   - **Exact Alarms (Android 12+)**: Ensures alerts fire with pinpoint accuracy.
   - **Storage / Media**: Optional, for importing timetable PDFs and study notes.
4. **Initial Profile Setup**: Input your Name, University/College, Semester, and Specialization (Organic, Inorganic, Physical, or Analytical).

---

## 3. Smart Timetable & Attendance Intelligence Engine
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

## 4. Notification System & Action Shade (1-Tap Attendance)
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

## 5. Daily Psychology Facts Engine (120+ Curated Facts)
Inspired by the "Psychology Facts" app, delivering daily evidence-based cognitive insights:
- **Domains Covered**:
  1. *Cognitive Biases*: Zeigarnik Effect, Halo Effect, Dunning-Kruger, Pratfall Effect, Spotlight Effect, Framing, Anchoring.
  2. *Memory & Learning*: Ebbinghaus Forgetting Curve, Testing Effect, Serial Position, Sleep Consolidation.
  3. *Brain Science*: Mirror Neurons, Dopamine Anticipation, Neuroplasticity, Amygdala Hijack, Ultradian Rhythms.
  4. *Habits & Focus*: 20-Second Rule, Implementation Intentions, Parkinson's Law, Pomodoro, 5-Second Rule.
  5. *Social Dynamics & Relationships*: Bystander Effect, Chameleon Effect, Benjamin Franklin Effect, Pupil Dilation.
- **Prime-Weighted Rotation**:
  $$\text{Index} = (\text{Year} \times 365 + \text{DayOfYear} \times 47 + \text{Month} \times 13) \pmod{\text{TotalFacts}}$$
  Guarantees each day receives a unique, non-repeating fact with varied categories.

---

## 6. Home Dashboard & Intelligent Contextual Greeting
- **40+ Contextual Greetings**: Dynamically adapting to time (late-night Bunsen burner, early morning, afternoon), day of week, and attendance tier (<75% danger warnings vs 85%+ praise).
- **Daily Chemistry Thought**: Rotating quote and scientific thought of the day.
- **Psychology Fact Card**: In-app widget with category badge, explanation, takeaway (`💡 Insight:`), and shuffle button (`🔀`).

---

## 7. ChemDraw Pro & Ketcher Pro (118-Element Molecular Sketcher)
- **118-Element Periodic Table**: Instant search by symbol, name, or atomic number with CPK coloring and category filters.
- **Drawing Tools**: Single, double, triple, wedge, and dash bonds, plus curved electron arrows (`⤴`).
- **Formal Charges**: `+1`, `-1`, `+2`, `-2`, and reset with circled badges & `M CHG` Molfile export.
- **Marquee Selection (`⬚`) & 2D Clean-Up (`🧹`)**: Select groups of atoms or standardize bond lengths to 55px.
- **Templates**: Non-destructive loading of Benzene, Cyclohexane, Pyridine, Steroid, Porphyrin, Aspirin, Naphthalene, Indole, Imidazole, Thiophene, Furan, 18-Crown-6, Ferrocene.
- **Touch Navigation**: Two-finger pinch-to-zoom (0.3x to 3.0x) and pan.

---

## 8. Reaction Product Prediction & 2D Vector SVG Generator
- **45+ Instant Offline Reaction Rules (0ms)**: Predicts standard MSc reactions (Aspirin, Paracetamol, Acetanilide, Esters, EAS, Aldol, Cannizzaro, Diels-Alder, Reductions, Oxidations) locally.
- **`SmilesSvgGenerator`**: Standalone client-side SVG engine converting predicted SMILES into publication-grade 2D vector graphics with textbook coordinates and CPK heteroatoms, eliminating raw text placeholders.

---

## 9. Spectroscopy & Chromatography Hub
- **8 Techniques**: RP-HPLC, GC, TLC, 500 MHz 1H NMR, 13C DEPT NMR, FT-IR, Mass Spectrometry, and UV-Vis.
- **Interactive Zoom & Pan (1.0x to 5.0x)**: Dedicated zoom toolbar and haptic peak snapping.
- **Textbook KaTeX Math**: Displays formulas and principles in crisp LaTeX notation.

---

## 10. Spectroscopy Structure Solver Intelligence (52+ Molecules)
- **52+ Curated Compounds Database**: Full spectral fingerprints for Aspirin, Paracetamol, Benzoic Acid, Salicylic Acid, Vanillin, 1-Bromopropane, 2-Bromopropane, etc.
- **Algorithmic Solver**: DBE calculation, FT-IR functional group classification, 1H NMR splitting analysis, and systematic ruling-out of constitutional isomers.

---

## 11. MSc Chemistry Toolkit & 16 Postgrad Calculators
- **Solutions**: Molar Mass, Molarity, Dilution ($C_1 V_1 = C_2 V_2$).
- **Acid-Base**: pH/pOH, Henderson-Hasselbalch, Buffer Formulation Assistant.
- **Thermodynamics & Kinetics**: Gibbs Free Energy, Arrhenius Rate Law.
- **Spectroscopy**: Beer-Lambert Law, Photon Energy & Wavelength.
- **Electrochemistry**: Nernst Equation, Standard Cell Potential.
- **Analytical Chromatography**: HPLC Calibration Curve ($y = mx + c$), Theoretical Plates ($N$), Resolution ($R_s$), Kovats Index ($I$).

---

## 12. Pericyclic Hub & Woodward-Hoffmann FMO Engine
- **Frontier Molecular Orbital (FMO) Theory**: Thermal vs Photochemical selection rules.
- **Electrocyclic Reactions**: $4n$ (Con/Dis) and $4n+2$ (Dis/Con).
- **Cycloadditions**: $[4+2]$ Diels-Alder (Endo-rule) and $[2+2]$ photo-additions.
- **Sigmatropic Rearrangements**: $[1,3]$, $[1,5]$, $[3,3]$ Cope and Claisen shifts.

---

## 13. Smart Flashcards & Spaced Repetition (Active Recall)
- **SuperMemo-2 (SM-2) Spaced Repetition**: Exponentially expanding review intervals.
- **4-Point Confidence Rating**: `Again (1)`, `Hard (2)`, `Good (3)`, `Easy (4)`.
- **Auto-Deck Creation**: Converts uploaded PDF notes into active recall flashcards.

---

## 14. PDF Library, Study Hub & Strictly Grounded RAG Assistant
- **Offline PDF Viewer**: Smooth viewing, page navigation, and text extraction.
- **Strictly Grounded RAG Chat**: Constrained strictly to your uploaded notes (zero hallucinations).
- **8192 Token Complete Answers**: Comprehensive explanations with KaTeX math and ASCII reaction mechanisms.

---

## 15. Exam Mode & BCU Model Answer Generator
- **BCU & Central University Exam Blueprints**:
  - 2-Mark: Definitions, IUPAC names, concise statements.
  - 5-Mark: Mechanisms, intermediate structures, arrow pushing.
  - 10-Mark: Full synthesis pathways, retrosynthesis, spectroscopic proof.

---

## 16. Settings, Backup, Security & Offline Architecture
- **Notification Toggles**: Class reminders, 8:30 AM Timetable, 8:00 PM Psychology Facts, Deadlines, Flashcards.
- **Test Dispatch Buttons**: Send test class alert or test psychology fact notification instantly.
- **Local JSON Backup & Restore**: Full export/import of profile, timetable, and attendance.

---

## 17. Troubleshooting & FAQ
- **Q: Why didn't my 8:30 AM notification sound?**  
  *A:* Ensure "Alarms & Reminders" permission is granted on Android 12+, and set battery usage to "Unrestricted".
- **Q: Does product prediction require internet?**  
  *A:* No! The 45+ offline reaction rules and `SmilesSvgGenerator` run 100% locally on-device.
- **Q: How does a cancelled class affect attendance?**  
  *A:* Mark as *Postponed / Cancelled (⏸️)* to exclude the class from calculations so your percentage is never penalized.

---
*ChemBuddy v3.5.0 — Engineered with ❤️ for MSc Chemistry Students worldwide by Prajwal A Kambar.*
