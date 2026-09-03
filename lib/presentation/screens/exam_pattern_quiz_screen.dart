import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';

class ExamQuestionItem {
  final String section;
  final int marks;
  final String question;
  final String modelAnswer;
  final List<String> markingRubric;

  const ExamQuestionItem({
    required this.section,
    required this.marks,
    required this.question,
    required this.modelAnswer,
    required this.markingRubric,
  });
}

class ExamPatternQuizScreen extends ConsumerStatefulWidget {
  const ExamPatternQuizScreen({super.key, this.examTitle = 'MSc Chemistry End-Semester Examination'});

  final String examTitle;

  @override
  ConsumerState<ExamPatternQuizScreen> createState() => _ExamPatternQuizScreenState();
}

class _ExamPatternQuizScreenState extends ConsumerState<ExamPatternQuizScreen> {
  final Map<int, bool> _revealed = {};
  final Map<int, int> _awardedMarks = {};

  static const List<ExamQuestionItem> defaultExamPaper = [
    // PART A: 2-MARK QUESTIONS
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'State the **Woodward-Hoffmann rule** for a thermal $[4n+2]$ electrocyclic ring closure and indicate whether the stereochemical mode is conrotatory or disrotatory.',
      modelAnswer: r'Under thermal conditions ($\Delta$), a conjugated polyene with $4n+2$ $\pi$ electrons undergoes electrocyclic ring closure via a **disrotatory** mode. The ground-state HOMO ($\Psi_3$) has mirror plane ($m$) symmetry, requiring opposite-direction rotation of the terminal lobes to achieve constructive in-phase overlap.',
      markingRubric: [
        '1 Mark: Correctly naming Disrotatory mode under thermal conditions.',
        '1 Mark: Explaining mirror plane (m) symmetry of the ground state HOMO (Psi3).',
      ],
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Differentiate between **kinetic control** and **thermodynamic control** in organic reactions with reference to activation energy ($\Delta G^\ddagger$) and product stability ($\Delta G^\circ$).',
      modelAnswer: r'• **Kinetic Control**: The major product is the one formed faster due to a lower activation energy barrier ($\Delta G^\ddagger$). Favored at low temperatures and short reaction times.' '\n' r'• **Thermodynamic Control**: The major product is the most stable species with the lowest Gibbs free energy ($\Delta G^\circ$). Favored at higher temperatures and longer reaction times with reversible equilibrium.',
      markingRubric: [
        '1 Mark: Stating kinetic control is governed by lower activation energy (Delta G^double-dagger).',
        '1 Mark: Stating thermodynamic control is governed by overall stability (Delta G^degree).',
      ],
    ),

    // PART B: 5-MARK QUESTIONS
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Write the complete mechanism for the **Aldol Condensation** of acetaldehyde catalyzed by base ($\text{OH}^-$). Explain the driving force for the final dehydration step leading to crotonaldehyde.',
      modelAnswer: r'1. **Enolate Formation**: Base abstracts an $\alpha$-proton from acetaldehyde to form a resonance-stabilized enolate ion.' '\n' r'2. **Nucleophilic Addition**: The enolate attacks the electrophilic carbonyl carbon of a second acetaldehyde molecule, producing an alkoxide intermediate.' '\n' r'3. **Proton Transfer**: The alkoxide takes a proton from water to yield $\beta$-hydroxybutyraldehyde (aldol) and regenerates base.' '\n' r'4. **E1cB Dehydration**: Base abstracts an $\alpha$-proton followed by expulsion of hydroxide, driven by the **extended $\pi$-conjugation** between the newly formed $\text{C}=\text{C}$ double bond and the carbonyl group, yielding crotonaldehyde.',
      markingRubric: [
        '1.5 Marks: Correct enolate generation and resonance structures.',
        '1.5 Marks: Nucleophilic attack on second aldehyde yielding alkoxide.',
        '2.0 Marks: E1cB dehydration mechanism and thermodynamic driving force of conjugation.',
      ],
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'An organic compound of formula $\text{C}_8\text{H}_8\text{O}$ exhibits an intense IR absorption at $1685\text{ cm}^{-1}$ and $^1\text{H}$ NMR signals at $\delta\ 2.6\text{ ppm}\ (\text{s}, 3\text{H})$, $\delta\ 7.5\text{ ppm}\ (\text{m}, 3\text{H})$, and $\delta\ 7.9\text{ ppm}\ (\text{d}, 2\text{H})$. Deduce the structure with complete spectroscopic justification.',
      modelAnswer: r'1. **DBE Calculation**: $\text{DBE} = 8 + 1 - (8/2) = 5$. A DBE of 5 indicates a benzene ring (4) + 1 carbonyl (1).' '\n' r'2. **IR Analysis**: The sharp band at $1685\text{ cm}^{-1}$ is characteristic of a conjugated aromatic ketone (shifted down from $1715\text{ cm}^{-1}$ due to resonance).' '\n' r'3. **¹H NMR Analysis**:' '\n' r'   • $\delta\ 2.6\text{ ppm}$ (singlet, $3\text{H}$): Methyl group directly adjacent to a carbonyl ($-\text{COCH}_3$).' '\n' r'   • $\delta\ 7.5\text{ ppm}$ (multiplet, $3\text{H}$) & $\delta\ 7.9\text{ ppm}$ (doublet, $2\text{H}$): Monosubstituted benzene ring with ortho protons deshielded by the electron-withdrawing acetyl group.' '\n' r'4. **Conclusion**: The compound is **Acetophenone** ($\text{PhCOCH}_3$).',
      markingRubric: [
        '1.0 Mark: Accurate DBE calculation (DBE = 5).',
        '1.5 Marks: Correct interpretation of IR 1685 cm⁻¹ as conjugated ketone.',
        '1.5 Marks: Correct NMR assignment of methyl singlet and aromatic signals.',
        '1.0 Mark: Final structural assignment of Acetophenone.',
      ],
    ),

    // PART C: 10-MARK QUESTIONS
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the **Diels-Alder $[4+2]$ Cycloaddition** reaction comprehensively:' '\n' r'(a) Explain why the reaction is thermally allowed using Frontier Molecular Orbital (FMO) symmetry.' '\n' r'(b) Formulate the **Endo Rule** with secondary orbital interactions.' '\n' r'(c) Illustrate regioselectivity with an electron-donating group (EDG) at C1 of the diene reacting with methyl acrylate.',
      modelAnswer: r'(a) **FMO Symmetry**:' '\n' r'In thermal $[4s+2s]$, the diene acts as the nucleophile (HOMO = $\Psi_2$) and the dienophile as the electrophile (LUMO = $\pi^*$). At carbons 1 and 4, the lobes of $\Psi_2$ match the phases of the dienophile LUMO, resulting in constructive in-phase orbital overlap simultaneously on both termini (suprafacial-suprafacial).' '\n\n' r'(b) **The Endo Rule**:' '\n' r'When a dienophile has an electron-withdrawing carbonyl or ester group, the endo transition state is kinetically favored over the exo isomer due to **secondary orbital interactions** between the $\pi$-system of the substituent and the developing double bond at C2-C3 of the diene, lowering the activation energy.' '\n\n' r'(c) **Regioselectivity (1-Substituted Diene)**:' '\n' r'With an EDG at C1 (e.g. 1-methoxybutadiene), resonance puts higher electron density on C4. For methyl acrylate, the carbonyl polarizes the alkene, making C$\beta$ more electrophilic. Overlap of the largest HOMO coefficient (C4) with the largest LUMO coefficient (C$\beta$) gives the **ortho-like (1,2-disubstituted) adduct** as the major regioisomer.',
      markingRubric: [
        '3.5 Marks: Detailed FMO orbital symmetry diagram and phase overlap explanation.',
        '3.5 Marks: Clear explanation and 3D diagram of secondary orbital interactions for Endo rule.',
        '3.0 Marks: Accurate frontier orbital coefficient analysis demonstrating ortho regioselectivity.',
      ],
    ),

  ];

  int get totalPossibleMarks => defaultExamPaper.fold(0, (sum, q) => sum + q.marks);
  int get currentEarnedMarks => _awardedMarks.values.fold(0, (sum, m) => sum + m);

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.examTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Exam Header Banner
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.brandBright, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('University Exam Pattern', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          'Total Marks: $totalPossibleMarks • Your Score: $currentEarnedMarks / $totalPossibleMarks',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${((currentEarnedMarks / (totalPossibleMarks > 0 ? totalPossibleMarks : 1)) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Questions List
            ...List.generate(defaultExamPaper.length, (i) {
              final q = defaultExamPaper[i];
              final isRevealed = _revealed[i] ?? false;
              final score = _awardedMarks[i] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlowCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: isRevealed ? AppColors.brandBright.withValues(alpha: 0.4) : AppColors.borderSubtle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Q${i + 1} • ${q.section}',
                              style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '[${q.marks} Marks]',
                              style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ChemistryMarkdownView(
                        text: q.question,
                        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.4),
                      ),
                      const SizedBox(height: 14),

                      // Model Answer Reveal Button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isRevealed ? AppColors.statusSuccess : AppColors.brandBright,
                                side: BorderSide(color: isRevealed ? AppColors.statusSuccess : AppColors.borderHighlight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                AppHaptics.tap();
                                setState(() => _revealed[i] = !isRevealed);
                              },
                              icon: Icon(isRevealed ? Icons.visibility_off : Icons.visibility, size: 16),
                              label: Text(isRevealed ? 'Hide Model Answer' : 'Reveal Model Answer & Rubric'),
                            ),
                          ),
                        ],
                      ),

                      // Answer and Rubric
                      if (isRevealed) ...[
                        const Divider(color: AppColors.borderSubtle, height: 24),
                        const Text('MODEL ACADEMIC ANSWER', style: TextStyle(color: AppColors.statusSuccess, fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        ChemistryMarkdownView(
                          text: q.modelAnswer,
                          textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        const Text('EXAMINATION MARKING RUBRIC', style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        ...q.markingRubric.map((rubric) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w800)),
                              Expanded(child: Text(rubric, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5))),
                            ],
                          ),
                        )),
                        const SizedBox(height: 12),

                        // Self-grading Bar
                        Row(
                          children: [
                            const Text('Self-Assess Score: ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            ...List.generate(q.marks + 1, (m) {
                              final isSelected = score == m;
                              return Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: InkWell(
                                  onTap: () {
                                    AppHaptics.selection();
                                    setState(() => _awardedMarks[i] = m);
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.brandPrimary : AppColors.bg2,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSelected ? AppColors.brandBright : AppColors.borderSubtle),
                                    ),
                                    child: Text(
                                      '$m',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textMuted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
