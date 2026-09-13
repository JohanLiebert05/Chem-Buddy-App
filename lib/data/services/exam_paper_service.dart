import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ChemistryBranch {
  all(
    id: 'all',
    name: 'All Branches',
    icon: '🌟',
    subtitle: 'Comprehensive 70-Mark University Exam Pattern MSc Paper',
  ),
  organic(
    id: 'organic',
    name: 'Organic Chemistry',
    icon: '⚗️',
    subtitle: 'Pericyclic, Stereochemistry, Mechanisms & Asymmetric Synthesis',
  ),
  inorganic(
    id: 'inorganic',
    name: 'Inorganic Chemistry',
    icon: '🧪',
    subtitle: 'Coordination CFT, Organometallics, Catalysis & Bioinorganic',
  ),
  physical(
    id: 'physical',
    name: 'Physical Chemistry',
    icon: '⚡',
    subtitle: 'Quantum Chemistry, Kinetics, Statistical Thermodynamics & Electrochemistry',
  ),
  analytical(
    id: 'analytical',
    name: 'Analytical Chemistry',
    icon: '📊',
    subtitle: 'HPLC Chromatography, Mass Spectrometry, AAS & Error Analysis',
  );

  const ChemistryBranch({
    required this.id,
    required this.name,
    required this.icon,
    required this.subtitle,
  });

  final String id;
  final String name;
  final String icon;
  final String subtitle;
}

class ExamQuestionItem {
  final String section;
  final int marks;
  final String question;
  final String modelAnswer;
  final List<String> markingRubric;
  final List<String> mandatoryKeywords;
  final List<String> commonPitfalls;
  final String topic;
  final String difficulty;
  final String frequency;
  final String examTips;

  const ExamQuestionItem({
    required this.section,
    required this.marks,
    required this.question,
    required this.modelAnswer,
    required this.markingRubric,
    this.mandatoryKeywords = const [],
    this.commonPitfalls = const [],
    this.topic = 'Core MSc Chemistry',
    this.difficulty = 'Moderate',
    this.frequency = '🔥 High Probability Exam Question',
    this.examTips = '',
  });

  Map<String, dynamic> toJson() => {
    'section': section,
    'marks': marks,
    'question': question,
    'modelAnswer': modelAnswer,
    'markingRubric': markingRubric,
    'mandatoryKeywords': mandatoryKeywords,
    'commonPitfalls': commonPitfalls,
    'topic': topic,
    'difficulty': difficulty,
    'frequency': frequency,
    'examTips': examTips,
  };

  factory ExamQuestionItem.fromJson(Map<String, dynamic> json) => ExamQuestionItem(
    section: json['section'] as String? ?? 'General',
    marks: json['marks'] as int? ?? 2,
    question: json['question'] as String? ?? '',
    modelAnswer: json['modelAnswer'] as String? ?? '',
    markingRubric: (json['markingRubric'] as List? ?? []).map((e) => e.toString()).toList(),
    mandatoryKeywords: (json['mandatoryKeywords'] as List? ?? []).map((e) => e.toString()).toList(),
    commonPitfalls: (json['commonPitfalls'] as List? ?? []).map((e) => e.toString()).toList(),
    topic: json['topic'] as String? ?? 'Core MSc Chemistry',
    difficulty: json['difficulty'] as String? ?? 'Moderate',
    frequency: json['frequency'] as String? ?? '🔥 High Probability Exam Question',
    examTips: json['examTips'] as String? ?? '',
  );
}

class ExamEvaluationResult {
  final double score;
  final double maxScore;
  final double percentage;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final List<({String criterion, bool met, double marksAwarded})> rubricBreakdown;
  final List<String> detectedPitfalls;
  final String feedback;
  final String grade;

  const ExamEvaluationResult({
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.rubricBreakdown,
    required this.detectedPitfalls,
    required this.feedback,
    required this.grade,
  });
}

class ExamPaperService {
  ExamPaperService._();
  static final ExamPaperService instance = ExamPaperService._();

  /// Evaluates a student's answer against the examiner's standardized rubric,
  /// mandatory keywords, and common academic pitfalls.
  static ExamEvaluationResult evaluateStudentAnswer({
    required ExamQuestionItem question,
    required String studentAnswer,
  }) {
    final text = studentAnswer.trim().toLowerCase();
    if (text.isEmpty) {
      return ExamEvaluationResult(
        score: 0.0,
        maxScore: question.marks.toDouble(),
        percentage: 0.0,
        matchedKeywords: const [],
        missingKeywords: question.mandatoryKeywords,
        rubricBreakdown: question.markingRubric.map((r) => (criterion: r, met: false, marksAwarded: 0.0)).toList(),
        detectedPitfalls: const [],
        feedback: 'No answer provided. Enter your technical explanation to receive rubric evaluation.',
        grade: 'No Submission',
      );
    }

    final matched = <String>[];
    final missing = <String>[];

    for (final kw in question.mandatoryKeywords) {
      final cleanKw = kw.toLowerCase().trim();
      if (text.contains(cleanKw)) {
        matched.add(kw);
      } else {
        // Stem check (e.g. "disrotatory" vs "disrotation")
        final stem = cleanKw.length > 5 ? cleanKw.substring(0, cleanKw.length - 2) : cleanKw;
        if (text.contains(stem)) {
          matched.add(kw);
        } else {
          missing.add(kw);
        }
      }
    }

    final pitfallsFound = <String>[];
    final questionWords = ('${question.question} ${question.mandatoryKeywords.join(' ')}').toLowerCase().split(RegExp(r'\W+')).toSet();
    for (final pitfall in question.commonPitfalls) {
      final cleanP = pitfall.toLowerCase();
      final stopWords = {'applying', 'stating', 'assuming', 'writing', 'ignoring', 'confusing', 'omitting', 'forgetting', 'without', 'instead', 'because', 'which', 'their', 'there', 'having', 'with'};
      final words = cleanP.replaceAll(RegExp(r'[(),.]'), ' ').split(' ').where((w) => w.length > 3 && !stopWords.contains(w) && !questionWords.contains(w)).toList();
      int triggerCount = 0;
      for (final w in words) {
        if (text.contains(w)) triggerCount++;
      }
      if (words.isNotEmpty && triggerCount >= 1) {
        pitfallsFound.add(pitfall);
      }
    }

    // Evaluate each rubric criterion
    final rubricBreakdown = <({String criterion, bool met, double marksAwarded})>[];
    double totalAwarded = 0.0;
    final totalRubricCount = question.markingRubric.length;

    for (var i = 0; i < totalRubricCount; i++) {
      final r = question.markingRubric[i];
      // Extract marks from string e.g. "1.5 Marks: ..."
      double maxForCriterion = 1.0;
      final markMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*Marks?').firstMatch(r);
      if (markMatch != null) {
        maxForCriterion = double.tryParse(markMatch.group(1)!) ?? 1.0;
      } else {
        maxForCriterion = question.marks / totalRubricCount;
      }

      // Check if keywords belonging to this segment match
      final metaWords = {'marks', 'mark', 'correct', 'correctly', 'accurate', 'accurately', 'clear', 'clearly', 'detailed', 'explaining', 'explanation', 'description', 'describing', 'stating', 'diagram', 'points', 'rule'};
      final rWords = r.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3 && !metaWords.contains(w)).toList();
      int matchCount = 0;
      for (final rw in rWords) {
        if (text.contains(rw)) matchCount++;
      }

      final kwCoverage = question.mandatoryKeywords.isEmpty ? 1.0 : matched.length / question.mandatoryKeywords.length;
      final ratio = rWords.isNotEmpty ? matchCount / rWords.length : 0.0;
      final isMet = ratio >= 0.2 || (kwCoverage >= 0.5);

      double awarded = 0.0;
      if (isMet) {
        if (ratio >= 0.4 || kwCoverage >= 0.75) {
          awarded = maxForCriterion;
        } else {
          awarded = (maxForCriterion * 0.75).clamp(0.5, maxForCriterion);
        }
      }
      totalAwarded += awarded;
      rubricBreakdown.add((criterion: r, met: isMet, marksAwarded: double.parse(awarded.toStringAsFixed(1))));
    }

    // Keyword coverage weight
    final kwRatio = question.mandatoryKeywords.isEmpty ? 0.8 : matched.length / question.mandatoryKeywords.length;
    double calculatedScore = totalAwarded;

    // Apply keyword proportion clamp
    if (kwRatio < 0.3) {
      calculatedScore = calculatedScore.clamp(0.0, question.marks * 0.4);
    } else if (kwRatio < 0.6) {
      calculatedScore = calculatedScore.clamp(0.0, question.marks * 0.75);
    }

    // Penalty for critical pitfalls
    if (pitfallsFound.isNotEmpty) {
      calculatedScore = (calculatedScore - (0.5 * pitfallsFound.length)).clamp(0.0, question.marks.toDouble());
    }

    calculatedScore = double.parse(calculatedScore.clamp(0.0, question.marks.toDouble()).toStringAsFixed(1));
    final percentage = (calculatedScore / question.marks) * 100;

    String grade = 'Needs Improvement';
    if (percentage >= 85) {
      grade = 'First Class with Distinction ⭐';
    } else if (percentage >= 70) {
      grade = 'First Class 🎯';
    } else if (percentage >= 50) {
      grade = 'Second Class 👍';
    }

    // Construct constructive examiner summary
    final feedbackBuf = StringBuffer();
    if (percentage >= 80) {
      feedbackBuf.write('Excellent postgraduate response! High theoretical precision and strong chemical reasoning.');
    } else if (percentage >= 50) {
      feedbackBuf.write('Good foundational response. Covers primary mechanism/concept, but lacks key academic rigour.');
    } else {
      feedbackBuf.write('Incomplete answer. Critical theoretical elements or mechanistic driving forces are omitted.');
    }

    if (missing.isNotEmpty) {
      feedbackBuf.write(' To score full marks, ensure you explicitly integrate: ${missing.take(3).join(", ")}.');
    }
    if (pitfallsFound.isNotEmpty) {
      feedbackBuf.write(' Warning: Avoid examiner pitfall: ${pitfallsFound.first}.');
    }

    return ExamEvaluationResult(
      score: calculatedScore,
      maxScore: question.marks.toDouble(),
      percentage: percentage,
      matchedKeywords: matched,
      missingKeywords: missing,
      rubricBreakdown: rubricBreakdown,
      detectedPitfalls: pitfallsFound,
      feedback: feedbackBuf.toString(),
      grade: grade,
    );
  }

  // =========================================================================
  // 1. ORGANIC CHEMISTRY (Postgraduate CBCS Standard)
  // =========================================================================
  static const List<ExamQuestionItem> organicPaper = [
    // Part A: 2 Marks
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'State the **Woodward-Hoffmann rule** for a thermal $[4n+2]$ electrocyclic ring closure and indicate whether the stereochemical mode is conrotatory or disrotatory.',
      modelAnswer: r'Under thermal conditions ($\Delta$), a conjugated polyene with $4n+2$ $\pi$ electrons undergoes electrocyclic ring closure via a **disrotatory** mode. The ground-state HOMO ($\Psi_3$) possesses mirror plane ($m$) symmetry, which requires opposite-direction rotation of the terminal lobes to maintain constructive in-phase overlap.',
      markingRubric: [
        '1 Mark: Correctly stating Disrotatory mode under thermal conditions.',
        '1 Mark: Explaining mirror plane (m) symmetry of the ground-state HOMO (Psi3).',
      ],
      mandatoryKeywords: ['disrotatory', 'HOMO', 'mirror plane', 'symmetry'],
      commonPitfalls: ['Stating conrotatory mode (which applies to photochemical or 4n systems)', 'Confusing thermal HOMO with LUMO'],
      topic: 'Pericyclic Reactions',
      difficulty: 'Moderate',
      frequency: '🔥 Very High Frequency',
      examTips: 'Always specify the terminal orbital symmetry (m or C2) alongside the rotational mode.',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Differentiate between **kinetic control** and **thermodynamic control** in organic enolate generation with reference to activation energy ($\Delta G^\ddagger$) and product stability ($\Delta G^\circ$).',
      modelAnswer: r'• **Kinetic Control**: Favors the enolate formed faster via lower activation barrier ($\Delta G^\ddagger$). Generated at $-78^\circ\text{C}$ using a strong, sterically hindered non-nucleophilic base (LDA in THF) under irreversible conditions.' '\n' r'• **Thermodynamic Control**: Favors the more substituted, thermodynamically stable enolate ($\Delta G^\circ$). Generated at $>0^\circ\text{C}$ using smaller/weaker bases ($\text{KO}t\text{Bu}$ or $\text{NaOMe}$ in protic solvent) allowing reversible equilibration.',
      markingRubric: [
        '1 Mark: Kinetic control definition (Delta G-double-dagger, low T, hindered base LDA).',
        '1 Mark: Thermodynamic control definition (Delta G-degree, equilibration, more substituted enolate).',
      ],
      mandatoryKeywords: ['kinetic', 'thermodynamic', 'activation energy', 'stability', 'LDA'],
      commonPitfalls: ['Mixing up LDA conditions with high temperature equilibration', 'Omitting the role of steric hindrance'],
      topic: 'Enolate Chemistry',
      difficulty: 'Easy-Moderate',
      frequency: '🔥 High Frequency',
      examTips: 'Draw the two isomeric enolates of 2-methylcyclohexanone to guarantee maximum marks.',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'State the **Curtin-Hammett Principle** and describe its significance in conformational stereochemical reactivity.',
      modelAnswer: r'In a chemical reaction of two rapidly interconverting ground-state conformers, the product distribution depends strictly on the difference in free energies of their respective transition states ($\Delta \Delta G^\ddagger$), and is completely independent of the relative ground-state conformer equilibrium populations.',
      markingRubric: [
        '1 Mark: Stating product ratio depends solely on transition state energy difference.',
        '1 Mark: Stating independence from ground-state conformer ratio.',
      ],
      mandatoryKeywords: ['transition state', 'conformers', 'equilibrium', 'independent'],
      commonPitfalls: ['Assuming the major ground-state conformer always gives the major product'],
      topic: 'Conformational Analysis',
      difficulty: 'Hard',
      frequency: '⚡ Concept Question',
      examTips: 'Emphasize that rate of interconversion must be much faster than the rate of reaction.',
    ),

    // Part B: 5 Marks
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Write the complete mechanism for the **Aldol Condensation** of acetaldehyde catalyzed by hydroxide ($\text{OH}^-$). Explain the thermodynamic driving force for the final dehydration step to crotonaldehyde.',
      modelAnswer: r'1. **Enolate Generation**: Hydroxide abstracts an $\alpha$-proton from acetaldehyde ($pK_a \approx 17$) to form a resonance-stabilized enolate anion.' '\n' r'2. **Nucleophilic Addition**: The carbanionic enolate attacks the electrophilic carbonyl carbon of a second acetaldehyde molecule, producing an alkoxide intermediate.' '\n' r'3. **Proton Transfer**: The alkoxide abstracts a proton from $\text{H}_2\text{O}$, regenerating $\text{OH}^-$ and yielding $\beta$-hydroxybutyraldehyde (aldol).' '\n' r'4. **E1cB Dehydration**: Base abstracts the remaining acidic $\alpha$-proton to generate an enolate-like carbanion intermediate, which then expels the leaving group $\text{OH}^-$. The driving force is the formation of an **extended conjugated $\pi$-system** ($\alpha,\beta$-unsaturated enal), which provides substantial resonance stabilization.',
      markingRubric: [
        '1.5 Marks: Correct enolate resonance structures and generation.',
        '1.5 Marks: Nucleophilic attack on the second aldehyde and protonation.',
        '2.0 Marks: E1cB dehydration mechanism and thermodynamic driving force of conjugation.',
      ],
      mandatoryKeywords: ['enolate', 'nucleophilic addition', 'E1cB', 'conjugated', 'driving force'],
      commonPitfalls: ['Writing E2 instead of E1cB under basic conditions', 'Omitting the resonance driving force of the conjugated enal'],
      topic: 'Carbonyl Condensations',
      difficulty: 'Moderate',
      frequency: '🔥 Core Mechanism',
      examTips: 'Show lone pair electron pushes clearly using curved arrows.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'An organic compound of formula $\text{C}_8\text{H}_8\text{O}$ exhibits an intense IR absorption at $1685\text{ cm}^{-1}$ and $^1\text{H}$ NMR signals at $\delta\ 2.6\text{ ppm}\ (\text{s}, 3\text{H})$, $\delta\ 7.5\text{ ppm}\ (\text{m}, 3\text{H})$, and $\delta\ 7.9\text{ ppm}\ (\text{d}, 2\text{H})$. Deduce the structure with complete spectroscopic justification.',
      modelAnswer: r'1. **Degree of Unsaturation (DBE)**: $\text{DBE} = C + 1 - (H/2) = 8 + 1 - 4 = 5$. DBE of 5 indicates a benzene ring (4) + 1 carbonyl (1).' '\n' r'2. **IR Analysis**: The intense carbonyl band at $1685\text{ cm}^{-1}$ is significantly lower than typical aliphatic ketones ($1715\text{ cm}^{-1}$), confirming conjugation with the aromatic ring.' '\n' r'3. **¹H NMR Assignment**:' '\n' r'   • $\delta\ 2.6\text{ ppm}$ ($3\text{H}$, singlet): Protons on a methyl group directly bonded to a carbonyl ($-\text{COCH}_3$).' '\n' r'   • $\delta\ 7.5\text{ ppm}$ ($3\text{H}$, multiplet): Meta and para protons of monosubstituted benzene ring.' '\n' r'   • $\delta\ 7.9\text{ ppm}$ ($2\text{H}$, doublet): Ortho aromatic protons strongly deshielded by the electron-withdrawing carbonyl group.' '\n' r'4. **Structure**: **Acetophenone** ($\text{C}_6\text{H}_5\text{COCH}_3$).',
      markingRubric: [
        '1.0 Mark: Accurate DBE calculation (DBE = 5).',
        '1.5 Marks: Correct IR assignment of conjugated aromatic ketone at 1685 cm⁻¹.',
        '1.5 Marks: Assignment of methyl singlet at 2.6 ppm and split aromatic multiplet/doublet.',
        '1.0 Mark: Final identification of Acetophenone.',
      ],
      mandatoryKeywords: ['DBE', 'acetophenone', 'conjugation', 'singlet', 'deshielded'],
      commonPitfalls: ['Ignoring the IR shift from 1715 to 1685 cm⁻¹ due to aryl conjugation', 'Misidentifying 5 DBE as aliphatic diene'],
      topic: 'Organic Spectroscopy',
      difficulty: 'Moderate',
      frequency: '🔥 High Probability',
      examTips: 'Tabulate NMR peaks with Chemical Shift, Multiplicity, Integration, and Assignment.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Discuss the reagents, catalytic complex geometry, and stereochemical mnemonic of the **Sharpless Asymmetric Epoxidation** of allylic alcohols.',
      modelAnswer: r'• **Reagents**: Titanium(IV) isopropoxide $\text{Ti}(\text{O}i\text{Pr})_4$, optically pure chiral tartrate ester ($(+)$-diethyl tartrate or $(-)$-diethyl tartrate), and $tert$-butyl hydroperoxide ($t\text{-BuOOH}$) in anhydrous $\text{CH}_2\text{Cl}_2$ at $-20^\circ\text{C}$.' '\n' r'• **Catalytic Complex**: Forms a $C_2$-symmetric titanium-tartrate bridged dimer that coordinates both the allylic alcohol and the alkyl peroxide in a rigid chiral pocket.' '\n' r'• **Stereochemical Mnemonic**: Orient the allylic alcohol with the hydroxymethyl group ($-\text{CH}_2\text{OH}$) in the lower right corner in the plane of the page:' '\n' r'   - $(+)$-DET delivers oxygen from the **bottom face** ($\alpha$-face).' '\n' r'   - $(-)$-DET delivers oxygen from the **top face** ($\beta$-face).' '\n' r'Consistently delivers enantiomeric excess ($ee$) $>90\%$.',
      markingRubric: [
        '1.5 Marks: Correct catalytic cocktail (Ti(OiPr)4, DET, t-BuOOH).',
        '1.5 Marks: Dimeric chiral titanium-tartrate complex structure description.',
        '2.0 Marks: Accurate Sharpless quadrant mnemonic and face-delivery rule.',
      ],
      mandatoryKeywords: ['titanium', 'tartrate', 'dimer', 'mnemonic', 'allylic alcohol'],
      commonPitfalls: ['Applying Sharpless epoxidation to unfunctionalized alkenes without allylic OH', 'Reversing (+) and (-) delivery faces'],
      topic: 'Asymmetric Synthesis',
      difficulty: 'Hard',
      frequency: '⚡ Advanced MSc Topic',
      examTips: 'Draw the standard Sharpless quadrant diagram with allylic alcohol in the bottom-right.',
    ),

    // Part C: 10 Marks
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the **Diels-Alder $[4+2]$ Cycloaddition** reaction comprehensively:' '\n' r'(a) Explain why the thermal reaction is symmetry-allowed using Frontier Molecular Orbital (FMO) analysis.' '\n' r'(b) State and rationalize the **Endo Rule** based on secondary orbital interactions.' '\n' r'(c) Explain regioselectivity when 1-methoxybuta-1,3-diene reacts with methyl acrylate.',
      modelAnswer: r'(a) **FMO Symmetry**:' '\n' r'Under thermal conditions, interaction occurs between the diene HOMO ($\Psi_2$) and the dienophile LUMO ($\pi^*$). Both terminal carbons (C1 and C4) of $\Psi_2$ match the orbital phases of the dienophile LUMO simultaneously in a suprafacial-suprafacial ($[4s+2s]$) mode, generating constructive in-phase bonding overlap across the transition state without orbital symmetry forbidden barriers.' '\n\n' r'(b) **The Endo Rule**:' '\n' r'When dienophiles contain electron-withdrawing carbonyl or nitro groups, the endo transition state is kinetically preferred over exo. In the endo orientation, the $\pi$ orbitals of the electron-withdrawing substituent align directly underneath the developing C2-C3 double bond of the diene. This allows **favorable secondary orbital overlap**, which lowers the activation energy ($\Delta G^\ddagger$) of the transition state.' '\n\n' r'(c) **Regioselectivity (Ortho/Para Rule)**:' '\n' r'• For 1-methoxybutadiene: The methoxy lone pair donates into the diene via resonance ($\text{MeO}-\text{CH}=\text{CH}-\text{CH}=\text{CH}_2 \leftrightarrow \text{MeO}^+=\text{CH}-\text{CH}=\text{CH}-\text{CH}_2^-$), giving C4 the largest HOMO orbital coefficient.' '\n' r'• For methyl acrylate: The electron-withdrawing ester carbonyl polarizes the alkene ($\text{CH}_2=\text{CH}-\text{COOMe} \leftrightarrow ^+\text{CH}_2-\text{CH}=\text{C}(\text{O}^-)\text{OMe}$), giving C$\beta$ the largest LUMO orbital coefficient.' '\n' r'• Overlap of largest HOMO coefficient (C4) with largest LUMO coefficient (C$\beta$) gives the **ortho-like 1,2-disubstituted cyclohexene** as the dominant regioisomer ($>95\%$).',
      markingRubric: [
        '3.5 Marks: Detailed FMO orbital symmetry diagram and [4s+2s] suprafacial overlap.',
        '3.5 Marks: Clear explanation and diagram of secondary orbital interactions for the Endo rule.',
        '3.0 Marks: Frontier orbital coefficient analysis demonstrating ortho regioselectivity.',
      ],
      mandatoryKeywords: ['HOMO', 'LUMO', 'suprafacial', 'secondary orbital', 'endo', 'regioselectivity'],
      commonPitfalls: ['Assuming exo product is kinetic product because of sterics (endo is kinetic due to secondary overlap)', 'Failing to determine largest orbital coefficients in regioselectivity'],
      topic: 'Pericyclic Cycloadditions',
      difficulty: 'Hard',
      frequency: '🔥 10-Mark Essential Essay',
      examTips: 'Draw the phase-shaded orbital lobes for HOMO and LUMO clearly.',
    ),
  ];

  // =========================================================================
  // 2. INORGANIC CHEMISTRY (Postgraduate CBCS Standard)
  // =========================================================================
  static const List<ExamQuestionItem> inorganicPaper = [
    // Part A: 2 Marks
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Determine the total valence electron count for dimanganese decacarbonyl $\text{Mn}_2(\text{CO})_{10}$ and show how the 18-electron rule explains the presence of a metal-metal ($\text{Mn}-\text{Mn}$) single bond.',
      modelAnswer: r'• Manganese is in Group 7 ($7 e^-$ each $\times 2 = 14 e^-$).' '\n' r'• 10 terminal carbonyl ligands donate $2 e^-$ each ($10 \times 2 = 20 e^-$).' '\n' r'• Total valence electrons without metal-metal bond $= 14 + 20 = 34 e^-$.' '\n' r'• To satisfy the 18-electron rule for both metal centers, $2 \times 18 = 36 e^-$ are required. The difference ($36 - 34 = 2 e^-$) is fulfilled by a single $2c-2e^-$ $\text{Mn}-\text{Mn}$ covalent bond, giving each Mn center 18 valence electrons.',
      markingRubric: [
        '1 Mark: Correct electron calculation (34 valence electrons from Mn and CO).',
        '1 Mark: Explaining the Mn-Mn bond provides 2 shared electrons satisfying 18e per center.',
      ],
      mandatoryKeywords: ['18-electron', 'manganese', 'metal-metal bond', '34 electrons'],
      commonPitfalls: ['Counting Mn as Group 5 or 8', 'Forgetting that each center shares 1 electron from the M-M bond'],
      topic: 'Organometallic Chemistry',
      difficulty: 'Moderate',
      frequency: '🔥 High Probability',
      examTips: 'Always calculate total valence electrons first, then divide by number of metals.',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Define the **nephelauxetic effect** and explain how it affects the Racah interelectronic repulsion parameter $B$ in transition metal complexes.',
      modelAnswer: r'The nephelauxetic effect refers to the radial expansion of metal $d$-electron clouds upon coordination with ligands due to covalent sharing and orbital overlap. This reduces electron-electron repulsion within the $d$ shell. Consequently, the Racah parameter $B$ in complexes is lower than in the free gaseous ion ($B_{\text{complex}} < B_{\text{free}}$), with the nephelauxetic ratio $\beta = B_{\text{complex}} / B_{\text{free}} < 1$.',
      markingRubric: [
        '1 Mark: Definition of metal d-orbital cloud expansion via ligand covalency.',
        '1 Mark: Stating reduction of Racah parameter B and defining ratio beta < 1.',
      ],
      mandatoryKeywords: ['nephelauxetic', 'cloud expansion', 'Racah', 'covalency'],
      commonPitfalls: ['Confusing nephelauxetic effect (covalency) with spectrochemical series (splitting magnitude Delta)'],
      topic: 'Electronic Spectroscopy',
      difficulty: 'Moderate',
      frequency: '⚡ Concept Question',
      examTips: 'State the nephelauxetic series of ligands: F- < H2O < NH3 < en < Cl- < CN- < I-.',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'State the **Jahn-Teller Theorem** and identify which octahedral electronic configurations exhibit strong Jahn-Teller distortions.',
      modelAnswer: r'Any non-linear molecular system in a spatially degenerate electronic ground state is thermodynamically unstable and will undergo geometrical distortion to lower its symmetry and lift the orbital degeneracy.' '\n' r'Strong distortions occur when the degenerate $e_g$ orbitals (pointing directly at ligands) are asymmetrically filled: high-spin $d^4$ ($\text{Cr}^{2+}, \text{Mn}^{3+}$), low-spin $d^7$ ($\text{Co}^{2+}, \text{Ni}^{3+}$), and $d^9$ ($\text{Cu}^{2+}$).',
      markingRubric: [
        '1 Mark: Correct statement of the Jahn-Teller theorem (symmetry lowering to lift degeneracy).',
        '1 Mark: Identifying asymmetric eg configurations (especially d9 Cu2+ and high-spin d4).',
      ],
      mandatoryKeywords: ['Jahn-Teller', 'degenerate', 'distortion', 'eg', 'd9'],
      commonPitfalls: ['Claiming t2g asymmetry causes strong distortion (it only causes very weak distortion)'],
      topic: 'Crystal Field Theory',
      difficulty: 'Moderate',
      frequency: '🔥 Core Question',
      examTips: 'Cite Cu(II) d9 complexes (tetragonal elongation along z-axis) as classic example.',
    ),

    // Part B: 5 Marks
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Derive the relationship $\Delta_t = \frac{4}{9}\Delta_o$ for crystal field splitting in tetrahedral vs octahedral geometries. Calculate the CFSE in terms of $\Delta_o$ and pairing energy $P$ for both high-spin and low-spin $d^6$ octahedral complexes.',
      modelAnswer: r'• **Derivation of $\Delta_t = \frac{4}{9}\Delta_o$**:' '\n' r'   1. A tetrahedral complex has 4 ligands compared to 6 in an octahedral complex, giving an electrostatic ratio of $4/6 = 2/3$.' '\n' r'   2. In $T_d$ symmetry, no ligand points directly along the Cartesian axes; directional overlap factor provides another factor of $2/3$.' '\n' r'   3. Therefore: $\Delta_t = \frac{2}{3} \times \frac{2}{3} \Delta_o = \frac{4}{9}\Delta_o$.' '\n\n' r'• **CFSE for $d^6$ Octahedral Complexes**:' '\n' r'   - **High-Spin ($t_{2g}^4 e_g^2$)**: $\text{CFSE} = 4(-0.4\Delta_o) + 2(+0.6\Delta_o) = -1.6\Delta_o + 1.2\Delta_o = \mathbf{-0.4\Delta_o}$ (0 net pairing energy contribution).' '\n' r'   - **Low-Spin ($t_{2g}^6 e_g^0$)**: $\text{CFSE} = 6(-0.4\Delta_o) + 2P = \mathbf{-2.4\Delta_o + 2P}$ (where 2 extra pairs are forced).',
      markingRubric: [
        '2.0 Marks: Geometric derivation of 4/9 factor from 4/6 ligand ratio and 2/3 directional factor.',
        '1.5 Marks: Correct CFSE calculation for high-spin d6 (-0.4 Delta_o).',
        '1.5 Marks: Correct CFSE calculation for low-spin d6 (-2.4 Delta_o + 2P).',
      ],
      mandatoryKeywords: ['4/9', 'CFSE', 'octahedral', 'tetrahedral', 'pairing energy'],
      commonPitfalls: ['Writing 3P instead of 2P for d6 low-spin (free ion already has 1 pair)'],
      topic: 'Crystal Field Theory',
      difficulty: 'Moderate-Hard',
      frequency: '🔥 Standard Exam Derivation',
      examTips: 'Remember that free d6 ion has 1 pair, so net pairing energy in low-spin is 3 - 1 = 2P.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Diagram and explain the catalytic cycle of the **Monsanto Acetic Acid Synthesis** from methanol and $\text{CO}$ using the $[Rh(CO)_2I_2]^-$ catalyst. State the rate-determining step, oxidation state changes, and electron counts.',
      modelAnswer: r'1. **Oxidative Addition (Rate-Determining Step)**: Methyl iodide ($\text{CH}_3\text{I}$) adds to square-planar $[Rh^\text{I}(CO)_2I_2]^-$ ($16e^-$) to yield octahedral $[(CH_3)Rh^\text{III}(CO)_2I_3]^-$ ($18e^-$).' '\n' r'2. **Migratory Insertion**: A coordinated $\text{CO}$ inserts into the $\text{Rh}-\text{CH}_3$ bond, forming a 5-coordinate 16-electron acyl complex $[(CH_3CO)Rh^\text{III}(CO)I_3]^-$.' '\n' r'3. **Ligand Addition**: Free $\text{CO}$ coordinates to fill the vacant site, restoring the 18-electron count: $[(CH_3CO)Rh^\text{III}(CO)_2I_3]^-$.' '\n' r'4. **Reductive Elimination**: Acetyl iodide ($\text{CH}_3\text{COI}$) is eliminated, regenerating the active 16-electron catalyst $[Rh^\text{I}(CO)_2I_2]^-$.' '\n' r'5. **Off-Loop Chemistry**: Hydrolysis of $\text{CH}_3\text{COI}$ produces $\text{CH}_3\text{COOH}$ and $\text{HI}$; reaction of $\text{HI}$ with $\text{CH}_3\text{OH}$ regenerates $\text{CH}_3\text{I}$.',
      markingRubric: [
        '1.5 Marks: Identifying Rh(I) 16e to Rh(III) 18e oxidative addition as rate-determining.',
        '1.5 Marks: Correct migratory insertion and ligand coordination steps.',
        '2.0 Marks: Reductive elimination of acetyl iodide and catalytic loop regeneration.',
      ],
      mandatoryKeywords: ['Monsanto', 'rhodium', 'oxidative addition', 'migratory insertion', 'rate-determining'],
      commonPitfalls: ['Confusing Monsanto process (Rh catalyst) with Cativa process (Ir catalyst)', 'Miscounting electron counts (16e to 18e)'],
      topic: 'Homogeneous Catalysis',
      difficulty: 'Hard',
      frequency: '🔥 High Probability',
      examTips: 'Clearly write oxidation state and valence electrons for every rhodium intermediate.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Explain the structural basis of **cooperative oxygen binding in Hemoglobin** vs Myoglobin. Describe the Perutz mechanism for the allosteric T-to-R transition and the role of the proximal histidine.',
      modelAnswer: r'• **Deoxyhemoglobin (T-State)**: Iron is high-spin $\text{Fe}^\text{II}$ ($S=2$, $t_{2g}^4 e_g^2$) with large ionic radius ($r \approx 0.78\text{ Å}$), sitting $\sim 0.4\text{ Å}$ out of the porphyrin plane toward proximal His F8.' '\n' r'• **Oxyhemoglobin (R-State)**: Binding of $\text{O}_2$ causes electron transfer/pairing to low-spin $\text{Fe}^\text{II}$ ($S=0$, $t_{2g}^6$), reducing iron radius ($r \approx 0.61\text{ Å}$). The iron pulls directly into the porphyrin plane.' '\n' r'• **The Perutz Trigger**: Moving the iron atom drags the proximal His F8 by $0.6\text{ Å}$, which tilts $\alpha$-helix F. This shifts the $\alpha_1\beta_2$ and $\alpha_2\beta_1$ subunit interfaces, breaking eight inter-subunit salt bridges.' '\n' r'• **Allosteric Cooperativity**: The quaternary shift transforms low-affinity Tense (T) state to high-affinity Relaxed (R) state, yielding the classic sigmoidal Hill binding curve ($n \approx 2.8$), unlike monomeric Myoglobin which exhibits non-cooperative hyperbolic binding ($n = 1$).',
      markingRubric: [
        '1.5 Marks: High-spin to low-spin Fe(II) radius reduction and movement into the porphyrin plane.',
        '1.5 Marks: Proximal His F8 translation and F-helix tilt (Perutz trigger).',
        '2.0 Marks: Salt-bridge rupture, T-to-R quaternary transition, and sigmoidal Hill cooperativity.',
      ],
      mandatoryKeywords: ['hemoglobin', 'Perutz', 'proximal histidine', 'T-to-R', 'cooperativity'],
      commonPitfalls: ['Confusing proximal His F8 (coordinated to Fe) with distal His E7 (stabilizes O2 via H-bond)'],
      topic: 'Bioinorganic Chemistry',
      difficulty: 'Moderate',
      frequency: '🔥 Core Bioinorganic',
      examTips: 'Draw the displacement of the iron atom relative to the heme porphyrin ring.',
    ),

    // Part C: 10 Marks
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the electronic absorption spectroscopy of transition metal complexes:' '\n' r'(a) Formulate the Laporte and Spin selection rules for electronic transitions and discuss relaxation mechanisms (vibronic coupling and spin-orbit coupling).' '\n' r'(b) Using the **Tanabe-Sugano diagram for $d^2$ octahedral complexes**, assign the three spin-allowed absorption bands and explain why $\nu_1 = {^3T_{1g}(F)} \to {^3T_{2g}(F)}$ directly yields $10 Dq$.' '\n' r'(c) For $[V(H_2O)_6]^{3+}$, absorption bands occur at $\nu_1 = 17,800\text{ cm}^{-1}$ and $\nu_2 = 25,700\text{ cm}^{-1}$. Calculate $10 Dq$ ($\Delta_o$) and the Racah parameter $B$.',
      modelAnswer: r'(a) **Selection Rules & Relaxation**:' '\n' r'• **Laporte Rule**: Transitions between states of the same parity ($g \leftrightarrow g$ or $u \leftrightarrow u$) are forbidden ($\Delta l = \pm 1$). Pure $d-d$ transitions in centrosymmetric $O_h$ complexes are Laporte forbidden ($\epsilon \sim 1-100\text{ M}^{-1}\text{cm}^{-1}$).' '\n' r'• **Spin Rule**: Transitions between states of different spin multiplicity are forbidden ($\Delta S = 0$).' '\n' r'• **Relaxation**: Vibronic coupling momentarily removes the inversion center via asymmetric vibrational modes (e.g. $T_{1u}$ or $T_{2u}$), mixing $p$ and $d$ orbitals to allow weak Laporte-forbidden transitions. Spin-orbit coupling mixes states of differing multiplicity, allowing weak spin-forbidden bands.' '\n\n' r'(b) **Tanabe-Sugano for $d^2$ Octahedral**:' '\n' r'Ground state is $^3T_{1g}(F)$. The three spin-allowed transitions ($\Delta S = 0$) are:' '\n' r'   1. $\nu_1: {^3T_{1g}(F)} \to {^3T_{2g}(F)}$' '\n' r'   2. $\nu_2: {^3T_{1g}(F)} \to {^3T_{1g}(P)}$' '\n' r'   3. $\nu_3: {^3T_{1g}(F)} \to {^3A_{2g}(F)}$' '\n' r'In the weak field limit, the energy difference between $^3T_{1g}(F)$ and $^3T_{2g}(F)$ is exactly equal to the crystal field splitting parameter: $E(\nu_1) = 10 Dq$.' '\n\n' r'(c) **Numerical Calculation for $[V(H_2O)_6]^{3+}$**:' '\n' r'1. $10 Dq = \nu_1 = \mathbf{17,800\text{ cm}^{-1}}$.' '\n' r'2. In $d^2$ TS secular equations: $B = \frac{2\nu_1^2 + \nu_2^2 - 3\nu_1\nu_2}{15\nu_2 - 27\nu_1} \approx \mathbf{640\text{ cm}^{-1}}$.' '\n' r'Given free ion $B_0 \approx 860\text{ cm}^{-1}$, the nephelauxetic parameter $\beta = \frac{640}{860} \approx 0.74$, demonstrating $\sim 26\%$ covalent character.',
      markingRubric: [
        '3.0 Marks: Laporte and Spin selection rules with vibronic and spin-orbit relaxation.',
        '3.5 Marks: Correct assignment of the three spin-allowed bands from d2 Tanabe-Sugano diagram.',
        '3.5 Marks: Accurate calculation of 10 Dq (17,800 cm⁻¹) and Racah parameter B (~640 cm⁻¹).',
      ],
      mandatoryKeywords: ['Laporte', 'spin selection', 'vibronic coupling', 'Tanabe-Sugano', '10 Dq', 'Racah'],
      commonPitfalls: ['Confusing Tanabe-Sugano diagrams (constant ground state horizontal axis) with Orgel diagrams'],
      topic: 'Electronic Spectroscopy',
      difficulty: 'Hard',
      frequency: '🔥 Comprehensive 10-Mark Essay',
      examTips: 'State the difference between Laporte forbidden (d-d, epsilon < 100) and charge transfer (CT, epsilon > 10,000).',
    ),
  ];

  // =========================================================================
  // 3. PHYSICAL CHEMISTRY (Postgraduate CBCS Standard)
  // =========================================================================
  static const List<ExamQuestionItem> physicalPaper = [
    // Part A: 2 Marks
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'State the quantum mechanical postulate regarding physical observables and linear operators, and explain why observable operators must be **Hermitian**.',
      modelAnswer: r'Every physically observable dynamical variable in classical mechanics corresponds to a linear Hermitian operator in quantum mechanics. Operators must be Hermitian because:' '\n' r'1. Their eigenvalues are mathematically guaranteed to be strictly real numbers, which corresponds to measurable physical quantities.' '\n' r'2. Their eigenfunctions corresponding to distinct eigenvalues are mutually orthogonal.',
      markingRubric: [
        '1 Mark: Stating that observables correspond to linear Hermitian operators.',
        '1 Mark: Explaining that Hermitian operators ensure real eigenvalues and orthogonal eigenfunctions.',
      ],
      mandatoryKeywords: ['Hermitian', 'real eigenvalues', 'orthogonal', 'observable'],
      commonPitfalls: ['Forgetting to mention orthogonality of eigenfunctions'],
      topic: 'Quantum Mechanics',
      difficulty: 'Moderate',
      frequency: '🔥 Core Postulate',
      examTips: 'Write down the integral condition for a Hermitian operator: <psi|A|phi> = <A psi|phi>.',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Write the energy eigenvalues for a 1D Quantum Harmonic Oscillator and explain the physical origin of the **zero-point energy** ($E_0 = \frac{1}{2}\hbar \omega$).',
      modelAnswer: r'• Energy eigenvalues: $E_n = \left(n + \frac{1}{2}\right)\hbar \omega$ with $n = 0, 1, 2, \dots$' '\n' r'• **Physical Origin**: The zero-point energy $E_0 = \frac{1}{2}\hbar \omega$ at $T = 0\text{ K}$ is a fundamental consequence of the **Heisenberg Uncertainty Principle** ($\Delta x \Delta p \ge \frac{\hbar}{2}$). If the particle had zero energy, it would be motionless at the exact potential minimum ($x=0$, $p=0$), violating quantum indeterminacy.',
      markingRubric: [
        '1 Mark: Correct harmonic oscillator equation En = (n + 1/2) hbar omega.',
        '1 Mark: Connecting zero-point energy to Heisenberg uncertainty principle.',
      ],
      mandatoryKeywords: ['harmonic oscillator', 'zero-point energy', 'Heisenberg', 'uncertainty'],
      commonPitfalls: ['Writing n hbar omega without the + 1/2 zero-point correction'],
      topic: 'Quantum Mechanics',
      difficulty: 'Easy-Moderate',
      frequency: '🔥 High Frequency',
      examTips: 'Distinguish between h and hbar in the formula.',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Define the **Franck-Rabinowitch cage effect** in solution-phase photochemical kinetics.',
      modelAnswer: r'In solution photolysis, photochemically generated radicals or reactive fragments are initially enclosed in a microscopic "solvent cage" formed by surrounding solvent molecules. Before escaping by diffusion into bulk solution, they undergo hundreds of collisions with each other, leading to a high probability of **geminate recombination** compared to gas-phase reactions.',
      markingRubric: [
        '1 Mark: Description of the surrounding solvent cage enclosing radical pairs.',
        '1 Mark: Contrast between geminate recombination and diffusion into bulk solution.',
      ],
      mandatoryKeywords: ['cage effect', 'solvent cage', 'geminate recombination', 'diffusion'],
      commonPitfalls: ['Confusing cage recombination with secondary radical termination in bulk solvent'],
      topic: 'Chemical Kinetics',
      difficulty: 'Moderate',
      frequency: '⚡ Concept Question',
      examTips: 'Explain that the quantum yield of photochemical dissociation in solution is lower than in gas phase.',
    ),

    // Part B: 5 Marks
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'For a particle of mass $m$ confined in a 1D box of length $L$ ($0 \le x \le L$):' '\n' r'(a) Solve the Schrödinger equation to find the normalized wavefunctions $\psi_n(x)$ and energy levels $E_n$.' '\n' r'(b) Calculate the probability of finding the particle in the middle third of the box ($L/3 \le x \le 2L/3$) in its ground state ($n=1$).',
      modelAnswer: r'(a) **Wavefunction and Energy**:' '\n' r'Schrödinger equation: $-\frac{\hbar^2}{2m}\frac{d^2\psi}{dx^2} = E\psi \implies \psi(x) = A\sin(kx) + B\cos(kx)$.' '\n' r'Boundary condition $\psi(0)=0 \implies B=0$; $\psi(L)=0 \implies k = \frac{n\pi}{L}$.' '\n' r'Normalization: $\int_0^L A^2 \sin^2\left(\frac{n\pi x}{L}\right)dx = 1 \implies A = \sqrt{\frac{2}{L}}$.' '\n' r'Thus $\psi_n(x) = \sqrt{\frac{2}{L}}\sin\left(\frac{n\pi x}{L}\right)$ and $E_n = \frac{n^2 h^2}{8mL^2}$.' '\n\n' r'(b) **Probability in Middle Third ($n=1$)**:' '\n' r'$P = \int_{L/3}^{2L/3} \frac{2}{L}\sin^2\left(\frac{\pi x}{L}\right)dx = \frac{1}{L}\int_{L/3}^{2L/3} \left[1 - \cos\left(\frac{2\pi x}{L}\right)\right]dx$' '\n' r'$P = \frac{1}{L}\left[x - \frac{L}{2\pi}\sin\left(\frac{2\pi x}{L}\right)\right]_{L/3}^{2L/3} = \frac{1}{3} - \frac{1}{2\pi}\left[\sin\left(\frac{4\pi}{3}\right) - \sin\left(\frac{2\pi}{3}\right)\right]$' '\n' r'$P = \frac{1}{3} - \frac{1}{2\pi}\left[-\frac{\sqrt{3}}{2} - \frac{\sqrt{3}}{2}\right] = \frac{1}{3} + \frac{\sqrt{3}}{2\pi} \approx 0.3333 + 0.2757 = \mathbf{0.609}\ (60.9\%)$.',
      markingRubric: [
        '2.5 Marks: Derivation of normalized wavefunction and energy eigenvalues.',
        '2.5 Marks: Integral evaluation and final probability calculation (60.9%).',
      ],
      mandatoryKeywords: ['particle in a box', 'Schrodinger', 'normalization', 'probability', '60.9%'],
      commonPitfalls: ['Integrating from 0 to L instead of L/3 to 2L/3', 'Sign error in integrating -cos(2pi x/L)'],
      topic: 'Quantum Mechanics',
      difficulty: 'Moderate-Hard',
      frequency: '🔥 Classic Numerical',
      examTips: 'Classical probability is 1/3 (33.3%), whereas quantum probability is 60.9% due to central antinode.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Formulate the **Lindemann-Hinshelwood mechanism** for unimolecular gas-phase reactions. Apply the steady-state approximation (SSA) to derive the effective rate law, and demonstrate the limiting kinetics at high and low pressures.',
      modelAnswer: r'• **Elementary Reaction Steps**:' '\n' r'   1. $A + M \xrightarrow{k_1} A^* + M$ (collision activation)' '\n' r'   2. $A^* + M \xrightarrow{k_{-1}} A + M$ (collisional deactivation)' '\n' r'   3. $A^* \xrightarrow{k_2} P$ (unimolecular reaction)' '\n\n' r'• **Steady-State Approximation on $[A^*]$**:' '\n' r'$\frac{d[A^*]}{dt} = k_1 [A][M] - k_{-1}[A^*][M] - k_2[A^*] = 0 \implies [A^*] = \frac{k_1 [A][M]}{k_{-1}[M] + k_2}$.' '\n' r'Overall rate: $v = k_2 [A^*] = \frac{k_1 k_2 [A][M]}{k_{-1}[M] + k_2}$.' '\n\n' r'• **Limiting Behaviors**:' '\n' r'   - **High Pressure Limit ($k_{-1}[M] \gg k_2$)**: $v = \frac{k_1 k_2}{k_{-1}}[A] = k_\infty [A]$ (**First Order** in $A$).' '\n' r'   - **Low Pressure Limit ($k_2 \gg k_{-1}[M]$)**: $v = k_1 [A][M]$ (**Second Order** overall).',
      markingRubric: [
        '1.5 Marks: Three elementary kinetic equations with energized intermediate A*.',
        '2.0 Marks: Derivation of rate equation using Steady State Approximation.',
        '1.5 Marks: Demonstrating 1st order at high pressure and 2nd order at low pressure.',
      ],
      mandatoryKeywords: ['Lindemann', 'steady-state', 'unimolecular', 'high pressure', 'low pressure'],
      commonPitfalls: ['Neglecting collisional deactivation step (k-1)', 'Confusing order at high pressure vs low pressure'],
      topic: 'Chemical Kinetics',
      difficulty: 'Moderate',
      frequency: '🔥 Core Kinetic Derivation',
      examTips: 'Sketch the 1/k_obs vs 1/[M] Hinshelwood plot with slope k-1/(k1 k2) and intercept 1/k_inf.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'State the **Debye-Hückel Limiting Law** for mean ionic activity coefficients in dilute electrolyte solutions. Calculate the ionic strength ($I$) and mean activity coefficient ($\gamma_\pm$) of a $0.005\text{ M}$ aqueous $\text{CaCl}_2$ solution at $25^\circ\text{C}$ ($A = 0.509\text{ kg}^{1/2}\text{mol}^{-1/2}$).',
      modelAnswer: r'• **Debye-Hückel Limiting Law**:' '\n' r'$\log_{10}\gamma_\pm = -A |z_+ z_-| \sqrt{I}$' '\n' r'Where $A = 0.509$ for water at $298\text{ K}$, $z_+, z_-$ are ionic charges, and $I = \frac{1}{2}\sum c_i z_i^2$ is ionic strength.' '\n\n' r'• **Calculation for $0.005\text{ M}\ \text{CaCl}_2$**:' '\n' r'Dissociation: $\text{CaCl}_2 \to \text{Ca}^{2+} + 2\text{Cl}^-$.' '\n' r'$[\text{Ca}^{2+}] = 0.005\text{ M}$, $[\text{Cl}^-] = 2(0.005) = 0.010\text{ M}$.' '\n' r'$I = \frac{1}{2}\left[(0.005)(+2)^2 + (0.010)(-1)^2\right] = \frac{1}{2}[0.020 + 0.010] = \mathbf{0.015\text{ M}}$.' '\n\n' r'• **Mean Activity Coefficient**:' '\n' r'$\log_{10}\gamma_\pm = -0.509 \times |(+2)(-1)| \times \sqrt{0.015} = -0.509 \times 2 \times 0.1225 = -0.1247$.' '\n' r'$\gamma_\pm = 10^{-0.1247} = \mathbf{0.750}$.',
      markingRubric: [
        '1.5 Marks: Statement of Debye-Hückel Limiting Law with all symbols defined.',
        '1.5 Marks: Accurate ionic strength calculation (I = 0.015 M).',
        '2.0 Marks: Log gamma calculation and final mean activity coefficient (0.750).',
      ],
      mandatoryKeywords: ['Debye-Huckel', 'ionic strength', 'activity coefficient', '0.015', '0.75'],
      commonPitfalls: ['Forgetting to double chloride concentration [Cl-] = 2 * 0.005 M = 0.01 M', 'Omitting the factor of 2 from |z+ z-| = 2 * 1 = 2'],
      topic: 'Electrochemistry',
      difficulty: 'Moderate',
      frequency: '🔥 Numerical Standard',
      examTips: 'Remember that ionic strength for 1:2 electrolytes is always 3m.',
    ),

    // Part C: 10 Marks
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the principles and applications of **Hückel Molecular Orbital (HMO) Theory**:' '\n' r'(a) Formulate the three fundamental approximations regarding overlap integrals ($S_{ij}$), Coulomb integrals ($\alpha$), and resonance integrals ($\beta$).' '\n' r'(b) Construct and solve the Hückel secular determinant for **1,3-butadiene**. Calculate the four molecular orbital energy levels in terms of $\alpha$ and $\beta$.' '\n' r'(c) Calculate the **delocalization energy** (resonance energy) of 1,3-butadiene compared to two isolated ethylene molecules.',
      modelAnswer: r'(a) **Fundamental HMO Approximations**:' '\n' r'1. Overlap Integral: $S_{ij} = \delta_{ij}$ (1 if $i=j$, 0 if $i \neq j$; zero differential overlap).' '\n' r'2. Coulomb Integral: $H_{ii} = \alpha$ (energy of an electron in an isolated carbon $2p_z$ orbital; same for all identical carbons).' '\n' r'3. Resonance Integral: $H_{ij} = \beta$ if carbons $i$ and $j$ are directly bonded, and $0$ if non-adjacent.' '\n\n' r'(b) **Secular Determinant for Butadiene ($C_1-C_2-C_3-C_4$)**:' '\n' r'Let $x = \frac{\alpha - E}{\beta}$:' '\n' r'$\begin{vmatrix} x & 1 & 0 & 0 \\ 1 & x & 1 & 0 \\ 0 & 1 & x & 1 \\ 0 & 0 & 1 & x \end{vmatrix} = 0 \implies x^4 - 3x^2 + 1 = 0$' '\n' r'Roots of quadratic in $x^2$: $x^2 = \frac{3 \pm \sqrt{9 - 4}}{2} = \frac{3 \pm \sqrt{5}}{2} \approx 2.618\text{ and }0.382$.' '\n' r'Four roots: $x = \pm 1.618, \pm 0.618$.' '\n' r'Orbital Energies ($E = \alpha - x\beta$, note $\beta < 0$):' '\n' r'   • $\psi_1: E_1 = \alpha + 1.618\beta$ (bonding)' '\n' r'   • $\psi_2: E_2 = \alpha + 0.618\beta$ (bonding, HOMO)' '\n' r'   • $\psi_3: E_3 = \alpha - 0.618\beta$ (antibonding, LUMO)' '\n' r'   • $\psi_4: E_4 = \alpha - 1.618\beta$ (antibonding)' '\n\n' r'(c) **Total $\pi$-Electron Energy and Delocalization Energy**:' '\n' r'Ground state configuration has $4 \pi$ electrons occupying $\psi_1$ and $\psi_2$:' '\n' r'$E_\pi(\text{butadiene}) = 2(\alpha + 1.618\beta) + 2(\alpha + 0.618\beta) = 4\alpha + 4.472\beta$.' '\n' r'For two isolated ethylene molecules: $E_\pi(\text{isolated}) = 2 \times (2\alpha + 2\beta) = 4\alpha + 4.000\beta$.' '\n' r'$\mathbf{E_{\text{deloc}}} = (4\alpha + 4.472\beta) - (4\alpha + 4.000\beta) = \mathbf{0.472\beta} \approx 0.472(-75\text{ kJ/mol}) \approx \mathbf{-35.4\text{ kJ/mol}}$.',
      markingRubric: [
        '2.5 Marks: Detailed explanation of Hückel alpha, beta, and S_ij approximations.',
        '4.5 Marks: Complete secular determinant derivation and calculation of all 4 roots and orbital energies.',
        '3.0 Marks: Calculation of total pi-electron energy and delocalization energy (0.472 beta).',
      ],
      mandatoryKeywords: ['Huckel', 'secular determinant', 'butadiene', 'Coulomb integral', 'resonance integral', 'delocalization energy'],
      commonPitfalls: ['Remembering beta is intrinsically negative so alpha + 1.618 beta is lowest in energy', 'Omitting the factor of 2 when comparing against two ethylenes'],
      topic: 'Quantum Chemistry & HMO',
      difficulty: 'Hard',
      frequency: '🔥 Comprehensive 10-Mark Essay',
      examTips: 'Draw the 4 MO energy levels showing electron pairing in psi1 and psi2.',
    ),
  ];

  // =========================================================================
  // 4. ANALYTICAL CHEMISTRY (Postgraduate CBCS Standard)
  // =========================================================================
  static const List<ExamQuestionItem> analyticalPaper = [
    // Part A: 2 Marks
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Differentiate between **Limit of Detection (LOD)** and **Limit of Quantitation (LOQ)** in instrumental chemical analysis in terms of signal-to-noise ratio ($S/N$) and standard deviation ($\sigma$).',
      modelAnswer: r'• **Limit of Detection (LOD)**: The lowest analyte concentration reliably distinguished from background noise ($S/N = 3:1$ or $\text{LOD} = \frac{3.3 \sigma}{S}$, where $\sigma$ is standard deviation of blank and $S$ is calibration slope).' '\n' r'• **Limit of Quantitation (LOQ)**: The lowest concentration quantifiable with acceptable precision and accuracy ($S/N = 10:1$ or $\text{LOQ} = \frac{10 \sigma}{S} \approx 3.3 \times \text{LOD}$).',
      markingRubric: [
        '1 Mark: LOD definition (S/N = 3, 3.3 sigma/S).',
        '1 Mark: LOQ definition (S/N = 10, 10 sigma/S).',
      ],
      mandatoryKeywords: ['LOD', 'LOQ', 'signal-to-noise', 'blank'],
      commonPitfalls: ['Stating LOD is where concentration can be measured accurately (that is LOQ)'],
      topic: 'Validation Parameters',
      difficulty: 'Easy-Moderate',
      frequency: '🔥 Standard Definition',
      examTips: 'Always cite ICH guidelines for the 3.3 and 10 multiplier formulas.',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'State the **van Deemter equation** for chromatographic column efficiency and identify the three kinetic dispersion factors ($A$, $B$, and $C$).',
      modelAnswer: r'The van Deemter equation relates plate height ($H$) to mobile phase linear velocity ($u$):' '\n' r'$H = A + \frac{B}{u} + C \cdot u$' '\n' r'• $A$ = **Eddy Diffusion**: Multiple path dispersion through packing particles.' '\n' r'• $B$ = **Longitudinal Diffusion**: Molecular diffusion of analyte along flow axis.' '\n' r'• $C$ = **Resistance to Mass Transfer**: Slow equilibration between stationary and mobile phases.',
      markingRubric: [
        '1 Mark: van Deemter equation H = A + B/u + Cu.',
        '1 Mark: Physical definition of Eddy diffusion (A), longitudinal diffusion (B), and mass transfer resistance (C).',
      ],
      mandatoryKeywords: ['van Deemter', 'eddy diffusion', 'longitudinal diffusion', 'mass transfer'],
      commonPitfalls: ['Writing u in the numerator of B or denominator of C'],
      topic: 'Chromatography',
      difficulty: 'Moderate',
      frequency: '🔥 Core Chromatography',
      examTips: 'Minimum H (maximum column efficiency) occurs at optimal velocity u_opt = sqrt(B/C).',
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Define the **matrix effect** in quantitative analytical spectrometry and state how the **Standard Addition Method** overcomes it.',
      modelAnswer: r'The matrix effect refers to signal suppression or enhancement caused by all components in a sample other than the target analyte (salts, proteins, solvents). The **Standard Addition Method** overcomes this by adding known increments of pure analyte standard directly to equal aliquots of the real sample matrix, ensuring analyte and standard experience identical chemical environments.',
      markingRubric: [
        '1 Mark: Definition of matrix effect (interference from sample components).',
        '1 Mark: Mechanism of standard addition maintaining identical sample matrix.',
      ],
      mandatoryKeywords: ['matrix effect', 'standard addition', 'suppression', 'interference'],
      commonPitfalls: ['Confusing standard addition with internal standard method'],
      topic: 'Analytical Calibration',
      difficulty: 'Moderate',
      frequency: '⚡ High Practical Value',
      examTips: 'In standard addition plot, x-intercept magnitude gives original sample concentration.',
    ),

    // Part B: 5 Marks
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Discuss the instrumentation and chemical interference mechanisms in **Atomic Absorption Spectroscopy (AAS)**. Explain how chemical interferences like refractory oxide formation are suppressed.',
      modelAnswer: r'• **Instrumentation**:' '\n' r'   1. **Hollow Cathode Lamp (HCL)**: Emits narrow elemental resonance emission lines of the target analyte.' '\n' r'   2. **Atomizer (Flame/Graphite Furnace)**: Desolvates, vaporizes, and atomizes analyte into ground-state atoms.' '\n' r'   3. **Monochromator**: Isolates target analytical wavelength from other lamp and flame emission lines.' '\n' r'   4. **Photomultiplier Tube (PMT)**: Measures attenuated intensity.' '\n\n' r'• **Chemical Interferences**:' '\n' r'   - Refractory compounds: In calcium determination, phosphate ($\text{PO}_4^{3-}$) forms stable, non-volatile $\text{Ca}_3(\text{PO}_4)_2$, preventing atomization.' '\n' r'• **Suppression Methods**:' '\n' r'   1. **Releasing Agents**: Adding lanthanum ($\text{La}^{3+}$) or strontium preferentially binds phosphate, releasing free $\text{Ca}^{2+}$.' '\n' r'   2. **Protective Chelating Agents**: Adding EDTA forms volatile chelates that decompose cleanly in the flame.' '\n' r'   3. **Higher Temperature**: Using nitrous oxide-acetylene flame ($2900^\circ\text{C}$) decomposes refractory oxides.',
      markingRubric: [
        '2.0 Marks: Core instrumentation components and operating principle of Hollow Cathode Lamp.',
        '1.5 Marks: Chemical interference mechanism (e.g. Ca3(PO4)2 refractory formation).',
        '1.5 Marks: Suppression methods using releasing agents (La3+) and nitrous oxide flame.',
      ],
      mandatoryKeywords: ['Hollow Cathode Lamp', 'atomizer', 'releasing agent', 'lanthanum', 'phosphate'],
      commonPitfalls: ['Confusing chemical interference (non-atomized compounds) with spectral interference (overlapping lines)'],
      topic: 'Spectroscopy',
      difficulty: 'Moderate',
      frequency: '🔥 Standard Topic',
      examTips: 'Lanthanum is the universal releasing agent for alkaline earth analysis in presence of phosphate/sulfate.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'For a reversible redox couple $O + n e^- \rightleftharpoons R$ analyzed by Cyclic Voltammetry (CV):' '\n' r'(a) State the **Randles-Sevcik equation** for peak current $i_p$ at $25^\circ\text{C}$.' '\n' r'(b) State the four fundamental diagnostic criteria that establish electrochemical reversibility.',
      modelAnswer: r'(a) **Randles-Sevcik Equation** ($25^\circ\text{C}$):' '\n' r'$i_p = (2.69 \times 10^5) n^{3/2} A D^{1/2} C v^{1/2}$' '\n' r'Where $i_p$ is peak current (A), $n$ is number of electrons, $A$ is electrode surface area ($\text{cm}^2$), $D$ is diffusion coefficient ($\text{cm}^2/\text{s}$), $C$ is bulk concentration ($\text{mol/cm}^3$), and $v$ is potential scan rate ($\text{V/s}$).' '\n\n' r'(b) **Diagnostic Criteria for Reversibility**:' '\n' r'1. Peak potential separation $\Delta E_p = |E_{pa} - E_{pc}| \approx \frac{59.2\text{ mV}}{n}$ at $25^\circ\text{C}$, independent of scan rate.' '\n' r'2. Peak current ratio $\frac{i_{pa}}{i_{pc}} = 1.0$.' '\n' r'3. Peak current $i_p$ is strictly proportional to the square root of scan rate ($i_p \propto \sqrt{v}$).' '\n' r'4. The positions of peak potentials $E_{pa}$ and $E_{pc}$ do not shift with increasing scan rate.',
      markingRubric: [
        '2.0 Marks: Randles-Sevcik equation with all physical variables identified.',
        '3.0 Marks: Stating all 4 electrochemical reversibility diagnostic criteria.',
      ],
      mandatoryKeywords: ['Randles-Sevcik', 'cyclic voltammetry', 'reversibility', 'scan rate', '59.2 mV'],
      commonPitfalls: ['Writing Delta E_p = 59.2 mV without dividing by n', 'Confusing reversible couple with quasi-reversible where Delta Ep increases with scan rate'],
      topic: 'Electroanalytical Methods',
      difficulty: 'Moderate-Hard',
      frequency: '🔥 High Probability',
      examTips: 'Draw the duck-shaped CV curve marking E_pa, E_pc, i_pa, and i_pc.',
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Explain the principle, stationary phase packing chemistry, and mobile phase optimization in **Reversed-Phase High-Performance Liquid Chromatography (RP-HPLC)**.',
      modelAnswer: r'• **Principle**: RP-HPLC utilizes a non-polar stationary phase and a polar aqueous mobile phase. Solutes partition based on hydrophobicity; polar solutes elute first, and non-polar solutes are retained longer.' '\n' r'• **Stationary Phase Chemistry**: Derivatized silica gel coated with octadecylsilane ($\text{C}_{18}$ or ODS, $-\text{Si}-(\text{CH}_2)_{17}\text{CH}_3$) via siloxane bonds. Residual acidic silanol groups ($-\text{Si}-\text{OH}$) are deactivated by **end-capping** with trimethylchlorosilane ($\text{TMS}$) to prevent peak tailing of basic analytes.' '\n' r'• **Mobile Phase Optimization**:' '\n' r'   1. Solvent mixtures: Water (polar) combined with organic modifiers (acetonitrile, methanol, or THF).' '\n' r'   2. Gradient Elution: Increasing the organic modifier percentage over time increases solvent elution strength, eluting strongly retained hydrophobic compounds faster with sharp peak shapes.',
      markingRubric: [
        '1.5 Marks: Explanation of non-polar stationary / polar mobile phase retention mechanism.',
        '2.0 Marks: C18 packing chemistry, silanol tailing, and end-capping deactivation.',
        '1.5 Marks: Isocratic vs Gradient mobile phase elution optimization.',
      ],
      mandatoryKeywords: ['C18', 'ODS', 'end-capping', 'hydrophobicity', 'gradient elution'],
      commonPitfalls: ['Confusing Reversed-Phase (non-polar stationary) with Normal Phase (polar stationary)'],
      topic: 'Chromatography',
      difficulty: 'Moderate',
      frequency: '🔥 Industrial Core Topic',
      examTips: 'Remember that acetonitrile provides lower column backpressure than methanol due to lower viscosity.',
    ),

    // Part C: 10 Marks
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the principles of modern Mass Spectrometry (MS) and 2D NMR in structural identification:' '\n' r'(a) Compare **Electron Ionization (EI)** and **Electrospray Ionization (ESI)** in terms of ionization mechanism, internal energy transfer, and application scope.' '\n' r'(b) Detail the mechanism and electron-pushing scheme of the **McLafferty rearrangement** in carbonyl compounds containing $\gamma$-hydrogens.' '\n' r'(c) Deduce the characteristic isotope peak patterns for mono- and di-chlorinated ($^{35}\text{Cl} : {^{37}\text{Cl}} \approx 3:1$) and brominated ($^{79}\text{Br} : {^{81}\text{Br}} \approx 1:1$) organic molecules.',
      modelAnswer: r'(a) **EI vs ESI Ionization**:' '\n' r'• **EI (Hard Ionization)**: High-energy beam ($70\text{ eV}$) strikes vaporized analyte molecules, ejecting an electron to produce odd-electron radical cations ($M^{+\bullet}$). Imparts high internal excess energy, causing extensive reproducible fragmentation. Ideal for small, volatile, non-polar molecules ($<1000\text{ Da}$) and NIST spectral library matching.' '\n' r'• **ESI (Soft Ionization)**: Atmospheric pressure technique where analyte solution passes through a high-voltage capillary ($3-5\text{ kV}$) generating charged droplets that undergo desolvation (Coulomb explosion). Yields intact quasimolecular ions ($[M+H]^+$, $[M+\text{Na}]^+$) with minimal fragmentation, enabling multi-charging ($[M+zH]^{z+}$) to analyze large biomolecules, proteins, and supramolecular complexes ($>100\text{ kDa}$).' '\n\n' r'(b) **McLafferty Rearrangement**:' '\n' r'Occurs in odd-electron molecular ions of aldehydes, ketones, esters, or carboxylic acids having at least one hydrogen on the $\gamma$-carbon.' '\n' r'1. Ionization removes an electron from the carbonyl oxygen non-bonding pair to yield an oxy-radical cation.' '\n' r'2. The system forms a sterically favorable six-membered cyclic transition state.' '\n' r'3. The carbonyl radical abstracts the $\gamma$-hydrogen, triggering homolytic $\beta$-cleavage of the $\text{C}_\alpha-\text{C}_\beta$ bond.' '\n' r'4. Expels a neutral alkene molecule (e.g. ethylene) and leaves a resonance-stabilized enol radical cation ($m/z = 58$ for methyl ketones).' '\n\n' r'(c) **Isotope Abundance Patterns**:' '\n' r'• **Chlorine ($^{35}\text{Cl} : {^{37}\text{Cl}} \approx 3:1$)**:' '\n' r'   - Mono-chloro ($R-\text{Cl}$): $M : (M+2) \approx 3:1$ (100% : 33%).' '\n' r'   - Di-chloro ($R-\text{Cl}_2$): $(3+1)^2 = 9 : 6 : 1$ for $M : (M+2) : (M+4)$ (100% : 66.7% : 11.1%).' '\n' r'• **Bromine ($^{79}\text{Br} : {^{81}\text{Br}} \approx 1:1$)**:' '\n' r'   - Mono-bromo ($R-\text{Br}$): $M : (M+2) \approx 1:1$ twin peaks of equal intensity.' '\n' r'   - Di-bromo ($R-\text{Br}_2$): $(1+1)^2 = 1 : 2 : 1$ for $M : (M+2) : (M+4)$ (50% : 100% : 50%).',
      markingRubric: [
        '3.0 Marks: EI vs ESI mechanism, energy differences, and molecular weight suitability.',
        '3.5 Marks: McLafferty rearrangement 6-membered TS, gamma-H transfer, and beta-cleavage.',
        '3.5 Marks: Binomial calculation of Cl (3:1, 9:6:1) and Br (1:1, 1:2:1) isotopic clusters.',
      ],
      mandatoryKeywords: ['Electron Ionization', 'Electrospray', 'McLafferty', 'six-membered', 'isotope ratio'],
      commonPitfalls: ['Describing McLafferty as an even-electron fragment (it is an odd-electron radical cation rearrangement)', 'Forgetting the 9:6:1 ratio for dichlorinated species'],
      topic: 'Mass Spectrometry',
      difficulty: 'Hard',
      frequency: '🔥 Comprehensive 10-Mark Essay',
      examTips: 'Draw the 6-membered ring transition state with single-headed arrows for radical movement.',
    ),
  ];

  /// Comprehensive 70-Mark University Blueprint for All Branches
  /// Part A: 10 Questions x 2 Marks = 20 Marks (Compulsory)
  /// Part B: 6 Questions x 5 Marks = 30 Marks
  /// Part C: 2 Questions x 10 Marks = 20 Marks
  /// Total: 70 Marks
  static List<ExamQuestionItem> get comprehensive70MarkPaper => [
    // PART A: 10 x 2M = 20 Marks
    organicPaper[0],
    organicPaper[1],
    organicPaper[2],
    inorganicPaper[0],
    inorganicPaper[1],
    inorganicPaper[2],
    physicalPaper[0],
    physicalPaper[1],
    physicalPaper[2],
    analyticalPaper[0],

    // PART B: 6 x 5M = 30 Marks
    organicPaper[3],
    organicPaper[5],
    inorganicPaper[3],
    inorganicPaper[4],
    physicalPaper[3],
    analyticalPaper[5],

    // PART C: 2 x 10M = 20 Marks
    organicPaper[6],
    physicalPaper[6],
  ];

  static List<ExamQuestionItem> getPaperForBranch(ChemistryBranch branch) {
    switch (branch) {
      case ChemistryBranch.organic:
        return organicPaper;
      case ChemistryBranch.inorganic:
        return inorganicPaper;
      case ChemistryBranch.physical:
        return physicalPaper;
      case ChemistryBranch.analytical:
        return analyticalPaper;
      case ChemistryBranch.all:
        return comprehensive70MarkPaper;
    }
  }

  /// Caches progress for a specific branch exam paper.
  Future<void> savePaperProgress(ChemistryBranch branch, Map<int, int> awardedMarks, Map<int, bool> revealed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksJson = jsonEncode(awardedMarks.map((k, v) => MapEntry(k.toString(), v)));
      final revealedJson = jsonEncode(revealed.map((k, v) => MapEntry(k.toString(), v)));
      await prefs.setString('exam_paper_marks_${branch.id}', marksJson);
      await prefs.setString('exam_paper_revealed_${branch.id}', revealedJson);
    } catch (_) {}
  }

  /// Loads saved progress for a branch exam paper.
  Future<({Map<int, int> marks, Map<int, bool> revealed})> loadPaperProgress(ChemistryBranch branch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksRaw = prefs.getString('exam_paper_marks_${branch.id}');
      final revealedRaw = prefs.getString('exam_paper_revealed_${branch.id}');

      final marks = <int, int>{};
      final revealed = <int, bool>{};

      if (marksRaw != null) {
        final decoded = jsonDecode(marksRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final idx = int.tryParse(entry.key);
          if (idx != null && entry.value is int) {
            marks[idx] = entry.value as int;
          }
        }
      }

      if (revealedRaw != null) {
        final decoded = jsonDecode(revealedRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final idx = int.tryParse(entry.key);
          if (idx != null && entry.value is bool) {
            revealed[idx] = entry.value as bool;
          }
        }
      }

      return (marks: marks, revealed: revealed);
    } catch (_) {
      return (marks: <int, int>{}, revealed: <int, bool>{});
    }
  }
}
