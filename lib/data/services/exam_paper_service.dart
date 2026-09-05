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

  const ExamQuestionItem({
    required this.section,
    required this.marks,
    required this.question,
    required this.modelAnswer,
    required this.markingRubric,
  });

  Map<String, dynamic> toJson() => {
    'section': section,
    'marks': marks,
    'question': question,
    'modelAnswer': modelAnswer,
    'markingRubric': markingRubric,
  };

  factory ExamQuestionItem.fromJson(Map<String, dynamic> json) => ExamQuestionItem(
    section: json['section'] as String? ?? 'General',
    marks: json['marks'] as int? ?? 2,
    question: json['question'] as String? ?? '',
    modelAnswer: json['modelAnswer'] as String? ?? '',
    markingRubric: (json['markingRubric'] as List? ?? []).map((e) => e.toString()).toList(),
  );
}

class ExamPaperService {
  ExamPaperService._();
  static final ExamPaperService instance = ExamPaperService._();

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
    ),
  ];

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
    ),

    // Part C: 10 Marks
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the electronic absorption spectroscopy of transition metal complexes:' '\n' r'(a) Formulate the Laporte and Spin selection rules for electronic transitions and discuss relaxation mechanisms (vibronic coupling and spin-orbit coupling).' '\n' r'(b) Using the **Tanabe-Sugano diagram for $d^2$ octahedral complexes**, assign the three spin-allowed absorption bands and explain why $\nu_1 = {^3T_{1g}(F)} \to {^3T_{2g}(F)}$ directly yields $10 Dq$.' '\n' r'(c) For $[V(H_2O)_6]^{3+}$, absorption bands occur at $\nu_1 = 17,800\text{ cm}^{-1}$ and $\nu_2 = 25,700\text{ cm}^{-1}$. Calculate $10 Dq$ ($\Delta_o$) and the Racah parameter $B$.',
      modelAnswer: r'(a) **Selection Rules & Relaxation**:' '\n' r'• **Laporte Rule**: Transitions between states of the same parity ($g \leftrightarrow g$ or $u \leftrightarrow u$) are forbidden ($\Delta l = \pm 1$). Pure $d-d$ transitions in centrosymmetric $O_h$ complexes are Laporte forbidden ($\epsilon \sim 1-100\text{ M}^{-1}\text{cm}^{-1}$).' '\n' r'• **Spin Rule**: Transitions between states of different spin multiplicity are forbidden ($\Delta S = 0$).' '\n' r'• **Relaxation**: Vibronic coupling momentarily removes the inversion center via asymmetric vibrational modes (e.g. $T_{1u}$ or $T_{2u}$), mixing $p$ and $d$ orbitals to allow weak Laporte-forbidden transitions. Spin-orbit coupling mixes states of differing multiplicity, allowing weak spin-forbidden bands.' '\n\n' r'(b) **Tanabe-Sugano for $d^2$ Octahedral**:' '\n' r'Ground state is $^3T_{1g}(F)$. The three spin-allowed transitions ($\Delta S = 0$) are:' '\n' r'   1. $\nu_1: {^3T_{1g}(F)} \to {^3T_{2g}(F)}$' '\n' r'   2. $\nu_2: {^3T_{1g}(F)} \to {^3T_{1g}(P)}$' '\n' r'   3. $\nu_3: {^3T_{1g}(F)} \to {^3A_{2g}(F)}$' '\n' r'In the weak field limit, the energy difference between $^3T_{1g}(F)$ and $^3T_{2g}(F)$ is exactly equal to the crystal field splitting parameter: $E(\nu_1) = 10 Dq$.' '\n\n' r'(c) **Numerical Calculation for $[V(H_2O)_6]^{3+}$**:' '\n' r'1. $10 Dq = \nu_1 = \mathbf{17,800\text{ cm}^{-1}}$.' '\n' r'2. In $d^2$ TS secular equations: $\nu_2 + \nu_1 = 3(10 Dq) + 15B - \text{correction}$; with standard fitting relation: $B = \frac{2\nu_1^2 + \nu_2^2 - 3\nu_1\nu_2}{15\nu_2 - 27\nu_1} \approx \mathbf{640\text{ cm}^{-1}}$.' '\n' r'Given free ion $B_0 \approx 860\text{ cm}^{-1}$, the nephelauxetic parameter $\beta = \frac{640}{860} \approx 0.74$, demonstrating $\sim 26\%$ covalent character.',
      markingRubric: [
        '3.0 Marks: Laporte and Spin selection rules with vibronic and spin-orbit relaxation.',
        '3.5 Marks: Correct assignment of the three spin-allowed bands from d2 Tanabe-Sugano diagram.',
        '3.5 Marks: Accurate calculation of 10 Dq (17,800 cm⁻¹) and Racah parameter B (~640 cm⁻¹).',
      ],
    ),
  ];

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
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'State the **Debye-Hückel Limiting Law** for the mean activity coefficient $\gamma_\pm$ of strong electrolytes in dilute aqueous solutions. Explain the physical concept of the **ionic atmosphere** and the Debye screening length $\kappa^{-1}$.',
      modelAnswer: r'• **The Equation**: $\log_{10}\gamma_\pm = -A |z_+ z_-|\sqrt{I}$' '\n' r'Where $A = 0.509\text{ mol}^{-1/2}\text{kg}^{1/2}$ for water at $298\text{ K}$, $z_+, z_-$ are ionic valencies, and $I$ is ionic strength: $I = \frac{1}{2}\sum_i c_i z_i^2$.' '\n\n' r'• **Ionic Atmosphere**: Due to Coulombic attractions, each central positive ion is, on time-average, surrounded by a spherical cloud containing excess negative counter-ions (and vice versa). Thermal kinetic motion tends to disperse this cloud, while electrostatic forces maintain it.' '\n\n' r'• **Debye Length ($\kappa^{-1}$)**: The effective radius or thickness of this ionic atmosphere. It scales inversely with the square root of ionic strength ($\kappa^{-1} \propto \frac{1}{\sqrt{I}}$). In concentrated solutions, the atmosphere shrinks, screening charges more tightly.',
      markingRubric: [
        '1.5 Marks: Mathematical formulation with all constants and parameters defined.',
        '2.0 Marks: Physical description of the counter-ion cloud (ionic atmosphere).',
        '1.5 Marks: Definition of Debye screening length and inverse square-root dependence on I.',
      ],
    ),

    // Part C: 10 Marks
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the fundamental role of the **canonical partition function ($Q$)** in connecting microscopic quantum states to macroscopic thermodynamics:' '\n' r'(a) Define the molecular partition function $q$ and express the canonical partition function $Q$ for a system of $N$ indistinguishable, independent molecules.' '\n' r'(b) Derive the expressions for internal energy ($U$) and Helmholtz free energy ($A$) in terms of $\ln Q$.' '\n' r'(c) Factorize the molecular partition function into its four classical components ($q = q_{\text{trans}} \cdot q_{\text{rot}} \cdot q_{\text{vib}} \cdot q_{\text{elec}}$) and give explicit analytical formulas for each.',
      modelAnswer: r'(a) **Partition Functions**:' '\n' r'Molecular partition function: $q = \sum_i g_i e^{-\epsilon_i / k_B T}$.' '\n' r'For $N$ indistinguishable, non-interacting particles, the states are permuted by $N!$: $Q = \frac{q^N}{N!}$.' '\n\n' r'(b) **Thermodynamic Potentials**:' '\n' r'• Internal energy $U = \sum_i P_i E_i = \sum_i \frac{E_i e^{-\beta E_i}}{Q} = -\frac{\partial \ln Q}{\partial \beta} = \mathbf{k_B T^2 \left(\frac{\partial \ln Q}{\partial T}\right)_V}$.' '\n' r'• Helmholtz free energy $A = U - TS = -k_B T \ln Q$.' '\n' r'• Entropy $S = \frac{U - A}{T} = k_B \ln Q + k_B T \left(\frac{\partial \ln Q}{\partial T}\right)_V$.' '\n\n' r'(c) **Factorization of $q$**:' '\n' r'Assuming independent modes of motion ($\epsilon_{\text{total}} = \epsilon_t + \epsilon_r + \epsilon_v + \epsilon_e$):' '\n' r'1. $q_{\text{trans}} = \left(\frac{2\pi m k_B T}{h^2}\right)^{3/2} V = \frac{V}{\Lambda^3}$ (where $\Lambda$ is thermal de Broglie wavelength).' '\n' r'2. $q_{\text{rot}} = \frac{k_B T}{\sigma h c B}$ for linear molecules (where $\sigma$ is symmetry number and $B$ is rotational constant).' '\n' r'3. $q_{\text{vib}} = \prod_j \frac{1}{1 - e^{-h\nu_j / k_B T}}$ (product over normal modes relative to zero-point energy).' '\n' r'4. $q_{\text{elec}} = g_0 + g_1 e^{-\Delta\epsilon_1 / k_B T} \approx g_0$ (electronic ground state degeneracy).',
      markingRubric: [
        '3.0 Marks: Definition of q and derivation of Q = q^N / N! for indistinguishable molecules.',
        '3.5 Marks: Mathematical derivation of U and A from Boltzmann statistical ensemble.',
        '3.5 Marks: Factorization and explicit equations for translational, rotational, vibrational, and electronic terms.',
      ],
    ),
  ];

  static const List<ExamQuestionItem> analyticalPaper = [
    // Part A: 2 Marks
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'State the **Van Deemter equation** for chromatographic column efficiency and identify the physical significance of the coefficients $A$, $B$, and $C$.',
      modelAnswer: r'The Van Deemter equation relates plate height (HETP, $H$) to linear mobile phase velocity ($u$):' '\n' r'$H = A + \frac{B}{u} + C u$' '\n' r'• **$A$ (Eddy Diffusion)**: Multiple flow paths caused by non-uniform stationary phase particle packing.' '\n' r'• **$B/u$ (Longitudinal Diffusion)**: Molecular diffusion of analyte along the axial direction away from peak center.' '\n' r'• **$C u$ (Resistance to Mass Transfer)**: Finite rate of analyte mass transfer between mobile and stationary phases.',
      markingRubric: [
        '1 Mark: Correct equation H = A + B/u + C*u.',
        '1 Mark: Accurate identification of Eddy diffusion (A), longitudinal diffusion (B), and mass transfer resistance (C).',
      ],
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Explain the statistical rationale and decision rule for applying **Dixon’s Q-Test** to reject suspected outlier data points.',
      modelAnswer: r'1. Arrange replicate measurements in ascending numerical order: $x_1 \le x_2 \le \dots \le x_n$.' '\n' r'2. Compute the experimental quotient: $Q_{\text{calc}} = \frac{|\text{suspected value} - \text{nearest neighbor}|}{\text{range}} = \frac{|x_{\text{outlier}} - x_{\text{adjacent}}|}{x_{\text{max}} - x_{\text{min}}}$.' '\n' r'3. Compare $Q_{\text{calc}}$ to the critical value $Q_{\text{crit}}$ from Dixon’s table for sample size $n$ at the $95\%$ confidence level:' '\n' r'   - If $Q_{\text{calc}} > Q_{\text{crit}}$, the outlier is rejected with $95\%$ statistical confidence.' '\n' r'   - If $Q_{\text{calc}} \le Q_{\text{crit}}$, the point must be retained.',
      markingRubric: [
        '1 Mark: Formula Q = gap / range.',
        '1 Mark: Decision criterion Q_calc > Q_crit at specified confidence level.',
      ],
    ),
    ExamQuestionItem(
      section: 'Part A — Short Conceptual (2 Marks each)',
      marks: 2,
      question: r'Differentiate between **chemical deviations** and **instrumental deviations** from the Beer-Lambert Law ($A = \epsilon b c$).',
      modelAnswer: r'• **Chemical Deviations**: Occur when the absorbing analyte undergoes dissociation, association, protonation/deprotonation, or solvolysis at higher concentrations (e.g. dimerization of methylene blue or $\text{Cr}_2\text{O}_7^{2-} \rightleftharpoons 2\text{CrO}_4^{2-}$ equilibrium with shifting pH).' '\n' r'• **Instrumental Deviations**: Occur due to hardware imperfections such as polychromatic radiation (stray light leaking to the detector) or mismatched optical path lengths.',
      markingRubric: [
        '1 Mark: Explaining chemical causes (equilibrium shifts, association, pH change).',
        '1 Mark: Explaining instrumental causes (stray light, polychromatic radiation).',
      ],
    ),

    // Part B: 5 Marks
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'In HPLC chromatography:' '\n' r'(a) Define retention factor ($k^\prime$), selectivity factor ($\alpha$), and chromatographic resolution ($R_s$).' '\n' r'(b) Using the Purnell equation $R_s = \frac{\sqrt{N}}{4}\left(\frac{\alpha - 1}{\alpha}\right)\left(\frac{k_2^\prime}{1 + k_2^\prime}\right)$, explain why increasing column efficiency ($N$) is less practical for improving resolution than altering mobile phase selectivity ($\alpha$).',
      modelAnswer: r'(a) **Definitions**:' '\n' r'• Retention Factor $k^\prime = \frac{t_r - t_0}{t_0}$ (relative retention compared to void volume).' '\n' r'• Selectivity Factor $\alpha = \frac{k_2^\prime}{k_1^\prime} > 1$ (ratio of retention factors of adjacent peaks).' '\n' r'• Resolution $R_s = \frac{2(t_{r2} - t_{r1})}{w_1 + w_2}$ (baseline separation achieved when $R_s \ge 1.5$).' '\n\n' r'(b) **Purnell Analysis**:' '\n' r'Resolution scales with the square root of theoretical plate count: $R_s \propto \sqrt{N}$. To double the resolution ($2 \times R_s$), one requires a **four-fold increase in $N$** ($4 \times N$). This translates to quadrupling column length or reducing particle size, resulting in a 4-fold increase in retention time and severe column backpressure ($\Delta P \propto N$).' '\n' r'In contrast, altering mobile phase solvent composition, pH, or temperature changes the chemical selectivity $\alpha$, which directly scales the $(\frac{\alpha - 1}{\alpha})$ term without increasing pressure or run time.',
      markingRubric: [
        '2.0 Marks: Clear definitions and formulas for k-prime, alpha, and Rs.',
        '3.0 Marks: Mathematical analysis of Purnell equation showing square-root dependence on N versus direct selectivity optimization.',
      ],
    ),
    ExamQuestionItem(
      section: 'Part B — Analytical & Mechanism (5 Marks each)',
      marks: 5,
      question: r'Compare **Flame Atomic Absorption Spectroscopy (FAAS)** with **Graphite Furnace AAS (GFAAS)** in terms of atomization mechanics, detection limits, and the function of chemical matrix modifiers.',
      modelAnswer: r'• **Atomization Mechanics & Sample Size**:' '\n' r'   - **FAAS**: Continuous pneumatic nebulization into a premixed laminar flame ($\text{C}_2\text{H}_2/\text{air}$ or $\text{C}_2\text{H}_2/\text{N}_2\text{O}$). Sample consumption is $1-5\text{ mL/min}$ and atom residence time in the light beam is extremely short ($\sim 10^{-4}\text{ s}$).' '\n' r'   - **GFAAS**: Discrete micro-volume ($10-50\ \mu\text{L}$) injected into an electrothermally heated graphite tube under inert argon flow. Programmed thermal cycle: Drying ($100-120^\circ\text{C}$) $\to$ Pyrolysis/Ashing ($400-1000^\circ\text{C}$) $\to$ Atomization ($2000-2800^\circ\text{C}$) $\to$ Cleanout. Atom residence time is $\sim 1\text{ s}$ (10,000x longer than flame).' '\n\n' r'• **Detection Limits**: FAAS detects in parts-per-million (ppm; $\mu\text{g/mL}$); GFAAS achieves parts-per-billion (ppb; $\mu\text{g/L}$) to parts-per-trillion (ppt).' '\n\n' r'• **Matrix Modifiers**: Reagents like $\text{Pd}(\text{NO}_3)_2 + \text{Mg}(\text{NO}_3)_2$ added to the sample. They convert volatile analytes (e.g. $\text{As}, \text{Se}, \text{Cd}, \text{Pb}$) into refractory intermetallic complexes, permitting higher pyrolysis temperatures ($>1000^\circ\text{C}$) to vaporize interfering matrix salts without premature analyte volatilization.',
      markingRubric: [
        '1.5 Marks: Comparison of atomization mechanisms and optical residence times.',
        '1.5 Marks: Sample volume and sensitivity/LOD comparison (ppm vs ppb/ppt).',
        '2.0 Marks: GFAAS thermal temperature stages and exact chemical role of matrix modifiers.',
      ],
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
    ),

    // Part C: 10 Marks
    ExamQuestionItem(
      section: 'Part C — Comprehensive Essay / Synthesis (10 Marks)',
      marks: 10,
      question: r'Discuss the principles of modern Mass Spectrometry (MS) and 2D NMR in structural identification:' '\n' r'(a) Compare **Electron Ionization (EI)** and **Electrospray Ionization (ESI)** in terms of ionization mechanism, internal energy transfer, and application scope.' '\n' r'(b) Detail the mechanism and electron-pushing scheme of the **McLafferty rearrangement** in carbonyl compounds containing $\gamma$-hydrogens.' '\n' r'(c) Deduce the characteristic isotope peak patterns for mono- and di-chlorinated ($^{35}\text{Cl} : {^{37}\text{Cl}} \approx 3:1$) and brominated ($^{79}\text{Br} : {^{81}\text{Br}} \approx 1:1$) organic molecules.',
      modelAnswer: r'(a) **EI vs ESI Ionization**:' '\n' r'• **EI (Hard Ionization)**: High-energy beam ($70\text{ eV}$) strikes vaporized analyte molecules, ejecting an electron to produce odd-electron radical cations ($M^{+\bullet}$). Imparts high internal excess energy, causing extensive reproducible fragmentation. Ideal for small, volatile, non-polar molecules ($<1000\text{ Da}$) and NIST spectral library matching.' '\n' r'• **ESI (Soft Ionization)**: Atmospheric pressure technique where analyte solution passes through a high-voltage capillary ($3-5\text{ kV}$) generating charged droplets that undergo desolvation (Coulomb explosion). Yields intact quasimolecular ions ($[M+H]^+$, $[M+\text{Na}]^+$) with minimal fragmentation, enabling multi-charging ($[M+zH]^{z+}$) to analyze large biomolecules, proteins, and supramolecular complexes ($>100\text{ kDa}$).' '\n\n' r'(b) **McLafferty Rearrangement**:' '\n' r'Occurs in odd-electron molecular ions of aldehydes, ketones, esters, or carboxylic acids having at least one hydrogen on the $\gamma$-carbon.' '\n' r'1. Ionization removes an electron from the carbonyl oxygen non-bonding pair to yield an oxy-radical cation.' '\n' r'2. The system forms a sterically favorable six-membered cyclic transition state.' '\n' r'3. The carbonyl radical abstracts the $\gamma$-hydrogen, triggering homolytic $\beta$-cleavage of the $\text{C}_\alpha-\text{C}_beta$ bond.' '\n' r'4. Expels a neutral alkene molecule (e.g. ethylene) and leaves a resonance-stabilized enol radical cation ($m/z = 58$ for methyl ketones).' '\n\n' r'(c) **Isotope Abundance Patterns**:' '\n' r'• **Chlorine ($^{35}\text{Cl} : {^{37}\text{Cl}} \approx 3:1$)**:' '\n' r'   - Mono-chloro ($R-\text{Cl}$): $M : (M+2) \approx 3:1$ (100% : 33%).' '\n' r'   - Di-chloro ($R-\text{Cl}_2$): $(3+1)^2 = 9 : 6 : 1$ for $M : (M+2) : (M+4)$ (100% : 66.7% : 11.1%).' '\n' r'• **Bromine ($^{79}\text{Br} : {^{81}\text{Br}} \approx 1:1$)**:' '\n' r'   - Mono-bromo ($R-\text{Br}$): $M : (M+2) \approx 1:1$ twin peaks of equal intensity.' '\n' r'   - Di-bromo ($R-\text{Br}_2$): $(1+1)^2 = 1 : 2 : 1$ for $M : (M+2) : (M+4)$ (50% : 100% : 50%).',
      markingRubric: [
        '3.0 Marks: EI vs ESI mechanism, energy differences, and molecular weight suitability.',
        '3.5 Marks: McLafferty rearrangement 6-membered TS, gamma-H transfer, and beta-cleavage.',
        '3.5 Marks: Binomial calculation of Cl (3:1, 9:6:1) and Br (1:1, 1:2:1) isotopic clusters.',
      ],
    ),
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
        return [
          // Part A (4 questions, 8 marks - 1 from each branch)
          organicPaper[0],
          inorganicPaper[0],
          physicalPaper[0],
          analyticalPaper[0],
          // Part B (8 questions, 40 marks - 2 from each branch)
          organicPaper[3],
          organicPaper[4],
          inorganicPaper[3],
          inorganicPaper[4],
          physicalPaper[3],
          physicalPaper[4],
          analyticalPaper[3],
          analyticalPaper[4],
          // Part C (2 questions, 20 marks - alternating comprehensive essays)
          organicPaper[6],
          inorganicPaper[6],
        ];
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
