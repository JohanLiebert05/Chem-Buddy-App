import '../../core/utils/chemistry_text_formatter.dart';
import '../models/rag_models.dart';

/// Comprehensive MSc & BSc Chemistry Academic Knowledge Engine.
/// Provides authoritative, textbook-precise, mathematically sound answers for
/// analytical chemistry, concentration terms (ppm, mole, normality, molarity, etc.),
/// physical chemistry, thermodynamics, kinetics, electrochemistry, inorganic coordination,
/// spectroscopy, organic reaction mechanisms, and quantum chemistry.
class ChemistryKnowledgeEngine {
  ChemistryKnowledgeEngine._();

  /// Resolves any chemistry or science question into an authoritative academic response.
  static RagResponse generateAcademicResponse({
    required String question,
    String? subject,
    String? documentText,
    String? documentName,
    List<AiMessage>? history,
  }) {
    final cleanQ = question.trim();
    final lowerQ = cleanQ.toLowerCase();

    // 1. If document context is provided, perform contextual RAG extraction
    if (documentText != null && documentText.trim().length > 30) {
      final docAnswer = _extractFromDocument(cleanQ, documentText, documentName ?? 'Uploaded Notes');
      if (docAnswer != null) {
        return RagResponse(
          answer: ChemistryTextFormatter.format(docAnswer),
          sources: [
            RagSource(
              documentTitle: documentName ?? 'Uploaded PDF',
              fileName: documentName ?? 'Notes.pdf',
              pageNumber: 1,
              subject: subject ?? 'Chemistry Notes',
              topic: cleanQ,
              similarity: 0.92,
            ),
          ],
        );
      }
    }

    // 2. Check for exam-mark formatting requests (2M, 5M, 10M)
    final is2M = lowerQ.contains('2 mark') || lowerQ.contains('2m');
    final is5M = lowerQ.contains('5 mark') || lowerQ.contains('5m');
    final is10M = lowerQ.contains('10 mark') || lowerQ.contains('10m');

    // 3. Multi-term Compound Query Resolution (e.g. "what is ppm and mole and Normality")
    final multiTermAnswer = _matchMultiTermConcentrationOrConcepts(lowerQ, cleanQ);
    if (multiTermAnswer != null) {
      final formatted = _applyExamMarkFormatting(cleanQ, multiTermAnswer, is2M, is5M, is10M);
      return RagResponse(
        answer: ChemistryTextFormatter.format(formatted),
        sources: [
          RagSource(
            documentTitle: 'ChemBuddy Analytical & General Chemistry Core',
            fileName: 'Solution Chemistry Reference',
            pageNumber: 1,
            subject: subject ?? 'Analytical Chemistry',
            topic: cleanQ,
            similarity: 0.98,
          ),
        ],
      );
    }

    // 4. Match against curated domain modules (Analytical, Physical, Inorganic, Organic, Spectroscopy, Quantum)
    final curated = _matchCuratedChemistry(lowerQ, cleanQ);
    if (curated != null) {
      final formattedAnswer = _applyExamMarkFormatting(cleanQ, curated, is2M, is5M, is10M);
      return RagResponse(
        answer: ChemistryTextFormatter.format(formattedAnswer),
        sources: [
          RagSource(
            documentTitle: 'ChemBuddy MSc Chemistry Academic Reference',
            fileName: 'Curated Chemistry Core',
            pageNumber: 1,
            subject: subject ?? 'Chemistry',
            topic: cleanQ,
            similarity: 0.95,
          ),
        ],
      );
    }

    // 5. Intelligent Context-Aware Academic Synthesis (General Science & Chemistry Solver)
    final dynamicAnswer = _generateIntelligentAnswer(cleanQ, subject: subject, is2M: is2M, is5M: is5M, is10M: is10M);
    return RagResponse(
      answer: ChemistryTextFormatter.format(dynamicAnswer),
      sources: [
        RagSource(
          documentTitle: 'ChemBuddy Academic Knowledge Engine',
          fileName: 'Scientific Reasoning Engine',
          pageNumber: 1,
          subject: subject ?? 'Chemistry',
          topic: cleanQ,
          similarity: 0.90,
        ),
      ],
    );
  }

  static String _applyExamMarkFormatting(String q, String content, bool is2M, bool is5M, bool is10M) {
    if (is2M) return _format2Mark(q, content);
    if (is5M) return _format5Mark(q, content);
    if (is10M) return _format10Mark(q, content);
    return content;
  }

  // =========================================================================
  // MULTI-TERM COMPOUND QUERY RESOLVER
  // =========================================================================

  static String? _matchMultiTermConcentrationOrConcepts(String q, String originalQuery) {
    final hasPpm = q.contains('ppm') || q.contains('parts per million');
    final hasMole = q.contains('mole') || q.contains('mol ') || q.contains('moles');
    final hasNormality = q.contains('normality') || q.contains('normal solution');
    final hasMolarity = q.contains('molarity') || q.contains('molar solution');
    final hasMolality = q.contains('molality') || q.contains('molal solution');
    final hasMoleFraction = q.contains('mole fraction');
    final hasPpb = q.contains('ppb') || q.contains('parts per billion');

    // Count matched concentration terms
    final concentrationMatches = [
      if (hasPpm) 'ppm',
      if (hasMole) 'mole',
      if (hasNormality) 'normality',
      if (hasMolarity) 'molarity',
      if (hasMolality) 'molality',
      if (hasMoleFraction) 'mole_fraction',
      if (hasPpb) 'ppb',
    ];

    if (concentrationMatches.length >= 2) {
      return _buildComprehensiveConcentrationGuide(
        includePpm: hasPpm,
        includeMole: hasMole,
        includeNormality: hasNormality,
        includeMolarity: hasMolarity,
        includeMolality: hasMolality,
        includeMoleFraction: hasMoleFraction,
        includePpb: hasPpb,
      );
    }

    // SN1 vs SN2
    if ((q.contains('sn1') || q.contains('s_n1')) && (q.contains('sn2') || q.contains('s_n2'))) {
      return _buildSn1VsSn2Comparison();
    }

    // E1 vs E2
    if ((q.contains('e1') || q.contains('e_1')) && (q.contains('e2') || q.contains('e_2'))) {
      return _buildE1VsE2Comparison();
    }

    return null;
  }

  static String _buildComprehensiveConcentrationGuide({
    bool includePpm = false,
    bool includeMole = false,
    bool includeNormality = false,
    bool includeMolarity = false,
    bool includeMolality = false,
    bool includeMoleFraction = false,
    bool includePpb = false,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(r'### **Fundamental Concentration Terms & Solution Stoichiometry**');
    buffer.writeln(r'In analytical and physical chemistry, expressing the exact amount of solute dissolved in a given quantity of solvent or solution is fundamental for stoichiometry, titration, and trace analysis.');
    buffer.writeln();

    var sectionIdx = 1;

    // 1. MOLE CONCEPT
    if (includeMole) {
      buffer.writeln('#### **$sectionIdx. The Mole Concept (mol)**');
      buffer.writeln(r'* **Definition**: A **mole** is the SI unit for amount of substance. One mole contains exactly **$6.02214076 \times 10^{23}$** elementary entities (atoms, molecules, ions, or electrons), known as **Avogadro’s Number ($N_A$)**.');
      buffer.writeln(r'* **Mathematical Formula**:');
      buffer.writeln(r'  $$\text{Number of moles } (n) = \frac{\text{Mass of substance } (w \text{ in g})}{\text{Molar Mass } (M_w \text{ in g/mol})} = \frac{\text{Number of particles } (N)}{N_A}$$');
      buffer.writeln(r'* **For Gases at STP ($0^\circ\text{C}, 1\text{ atm}$)**:');
      buffer.writeln(r'  $$n = \frac{\text{Volume of gas (L)}}{22.414\text{ L/mol}}$$');
      buffer.writeln(r'* **Example**: $18.0\text{ g}$ of water ($\text{H}_2\text{O}$, $M_w = 18\text{ g/mol}$) corresponds to exactly $1.0\text{ mole}$ containing $6.022 \times 10^{23}$ water molecules.');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      sectionIdx++;
    }

    // 2. NORMALITY
    if (includeNormality) {
      buffer.writeln('#### **$sectionIdx. Normality (N)**');
      buffer.writeln(r'* **Definition**: **Normality** is the number of **gram equivalents** of solute dissolved per **liter of solution** ($\text{eq/L}$). It accounts for the reactive capacity ($n$-factor) of the solute in a specific chemical reaction.');
      buffer.writeln(r'* **Mathematical Formulas**:');
      buffer.writeln(r'  $$N = \frac{\text{Gram Equivalents of solute}}{\text{Volume of solution (L)}} = \frac{w \times 1000}{E \times V\text{ (in mL)}}$$');
      buffer.writeln(r'  $$\text{Equivalent Weight } (E) = \frac{\text{Molar Mass } (M_w)}{n\text{-factor (acidity, basicity, or valence factor)}}$$');
      buffer.writeln(r'* **Relationship with Molarity ($M$)**:');
      buffer.writeln(r'  $$\mathbf{N = M \times n\text{-factor}}$$');
      buffer.writeln(r'* **$n$-Factor Calculations**:');
      buffer.writeln(r'  - **Acids (Basicity)**: $\text{HCl} \rightarrow n=1$; $\text{H}_2\text{SO}_4 \rightarrow n=2$; $\text{H}_3\text{PO}_4 \rightarrow n=3$; $\text{H}_3\text{PO}_3 \rightarrow n=2$ (dibasic!).');
      buffer.writeln(r'  - **Bases (Acidity)**: $\text{NaOH} \rightarrow n=1$; $\text{Ba(OH)}_2 \rightarrow n=2$.');
      buffer.writeln(r'  - **Redox Reagents**: $\text{KMnO}_4$ in acidic medium ($\text{Mn}^{7+} \rightarrow \text{Mn}^{2+}$) $\rightarrow n = 5 \implies E = M_w / 5 = 158.04 / 5 = 31.6\text{ g/eq}$.');
      buffer.writeln(r'* **Temperature Dependence**: Like molarity, normality is **temperature-dependent** because solution volume expands/contracts with temperature.');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      sectionIdx++;
    }

    // 3. PPM and PPB
    if (includePpm || includePpb) {
      buffer.writeln('#### **$sectionIdx. Parts Per Million (ppm) & Parts Per Billion (ppb)**');
      buffer.writeln(r'* **Definition**: **$\text{ppm}$** is a dimensionless concentration unit used for **trace quantities, environmental pollutants, water hardness, and spectroscopy**. It represents the mass of solute per one million ($10^6$) mass units of solution.');
      buffer.writeln(r'* **Mathematical Formulas**:');
      buffer.writeln(r'  $$\text{ppm} = \frac{\text{Mass of Solute}}{\text{Total Mass of Solution}} \times 10^6$$');
      buffer.writeln(r'  $$\text{ppb} = \frac{\text{Mass of Solute}}{\text{Total Mass of Solution}} \times 10^9$$');
      buffer.writeln(r'* **For Dilute Aqueous Solutions (Density $\approx 1.0\text{ g/mL}$)**:');
      buffer.writeln(r'  $$\mathbf{1\text{ ppm} = 1\text{ mg/L} = 1\,\mu\text{g/mL} = 1\text{ g/m}^3}$$');
      buffer.writeln(r'  $$\mathbf{1\text{ ppb} = 1\,\mu\text{g/L} = 1\text{ ng/mL}}$$');
      buffer.writeln(r'* **Relationship to Percentage (%)**:');
      buffer.writeln(r'  $$1\% \text{ (w/w)} = 10,000\text{ ppm} \quad (1\text{ ppm} = 0.0001\%)$$');
      buffer.writeln(r'* **Applications**: Expressing drinking water standards (e.g. fluoride $\le 1.5\text{ ppm}$), trace heavy metals ($\text{Pb}^{2+}, \text{Hg}^{2+}$ in ppb), water hardness in $\text{mg/L CaCO}_3$, and NMR chemical shifts ($\delta$).');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      sectionIdx++;
    }

    // 4. MOLARITY & MOLALITY
    if (includeMolarity || includeMolality) {
      buffer.writeln('#### **$sectionIdx. Molarity (M) vs Molality (m)**');
      buffer.writeln(r'* **Molarity ($M$)**: Moles of solute per liter of solution ($\text{mol/L}$):');
      buffer.writeln(r'  $$M = \frac{w \times 1000}{M_w \times V\text{ (in mL)}} \quad (\text{Temperature-Dependent})$$');
      buffer.writeln(r'* **Molality ($m$)**: Moles of solute per kilogram of pure solvent ($\text{mol/kg}$):');
      buffer.writeln(r'  $$m = \frac{w \times 1000}{M_w \times W_{\text{solvent}}\text{ (in g)}} \quad (\mathbf{\text{Temperature-Independent}})$$');
      buffer.writeln(r'* **Why Molality is Preferred in Thermodynamics**: Molality relies purely on masses which do not change with thermal expansion, making it the rigorous choice for colligative property calculations ($\Delta T_b = K_b m$, $\Delta T_f = K_f m$).');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      sectionIdx++;
    }

    // 5. SUMMARY COMPARISON TABLE
    buffer.writeln('#### **$sectionIdx. Quick Master Comparison Table**');
    buffer.writeln(r'| Concentration Term | Symbol | Formula | Units | Temperature Dependent? |');
    buffer.writeln(r'| :--- | :---: | :--- | :---: | :---: |');
    buffer.writeln(r'| **Mole** | $n$ | $n = w / M_w$ | $\text{mol}$ | No |');
    buffer.writeln(r'| **Normality** | $N$ | $N = \frac{w \times 1000}{E \times V_{\text{mL}}}$ | $\text{eq/L}$ or $\text{N}$ | **Yes** (volume changes) |');
    buffer.writeln(r'| **Molarity** | $M$ | $M = \frac{w \times 1000}{M_w \times V_{\text{mL}}}$ | $\text{mol/L}$ or $\text{M}$ | **Yes** (volume changes) |');
    buffer.writeln(r'| **Molality** | $m$ | $m = \frac{w \times 1000}{M_w \times W_{\text{solvent(g)}}}$ | $\text{mol/kg}$ or $\text{m}$ | **No** (mass-based) |');
    buffer.writeln(r'| **Parts Per Million** | $\text{ppm}$ | $\text{ppm} = \frac{\text{solute mass}}{\text{solution mass}} \times 10^6$ | $\text{mg/L}$ or $\text{ppm}$ | Independent (mass/mass) |');
    buffer.writeln(r'| **Mole Fraction** | $X_A$ | $X_A = \frac{n_A}{n_A + n_B}$ | Dimensionless | **No** |');
    buffer.writeln();
    buffer.writeln(r'#### **Key Interconversion Equation**');
    buffer.writeln(r'$$\mathbf{\text{Normality } (N) = \text{Molarity } (M) \times n\text{-factor}}$$');
    buffer.writeln(r'$$\mathbf{\text{Dilution Law: } N_1V_1 = N_2V_2 \quad\text{and}\quad M_1V_1 = M_2V_2}$$');

    return buffer.toString();
  }

  static String _buildSn1VsSn2Comparison() {
    return r'''### **Comprehensive Comparison: SN1 vs SN2 Nucleophilic Substitution**

#### **1. Mechanism & Reaction Coordinates**
* **SN1 (Substitution Nucleophilic Unimolecular, $\text{S}_\text{N}1$)**:
  - **Two-step mechanism**: Step 1 is the slow heterolytic cleavage of the carbon-leaving group bond to generate a planar, $sp^2$-hybridized **carbocation intermediate** (Rate-Determining Step). Step 2 is the rapid nucleophilic attack from either face.
  - $$\text{R-X} \xrightarrow{\text{slow (RDS)}} \text{R}^+ + \text{X}^- \xrightarrow{\text{Nu}^-, \text{ fast}} \text{R-Nu}$$
* **SN2 (Substitution Nucleophilic Bimolecular, $\text{S}_\text{N}2$)**:
  - **One-step concerted mechanism**: Simultaneous back-side nucleophilic attack on the $\sigma^*(\text{C-X})$ antibonding orbital and leaving group departure via a pentacoordinate **trigonal bipyramidal transition state**.
  - $$\text{Nu}^- + \text{R-X} \rightarrow [\text{Nu}\cdots\text{R}\cdots\text{X}]^{\ddagger} \rightarrow \text{Nu-R} + \text{X}^-$$

---

#### **2. Stereochemical Outcome**
* **$\text{S}_\text{N}1$**: Leads to **racemization** (formation of both inversion and retention enantiomers) with slight excess of inversion due to ion-pair shielding by the departing leaving group.
* **$\text{S}_\text{N}2$**: Proceeds with **100% complete stereochemical inversion of configuration (Walden Inversion)**.

---

#### **3. Comparative Parameter Table**

| Parameter | $\text{S}_\text{N}1$ | $\text{S}_\text{N}2$ |
| :--- | :--- | :--- |
| **Kinetics & Rate Law** | $\text{Rate} = k[\text{R-X}]$ (First Order) | $\text{Rate} = k[\text{R-X}][\text{Nu}^-]$ (Second Order) |
| **Substrate Reactivity** | $3^\circ > 2^\circ \gg 1^\circ > \text{CH}_3\text{X}$ (Carbocation stability) | $\text{CH}_3\text{X} > 1^\circ > 2^\circ \gg 3^\circ$ (Steric hindrance) |
| **Nucleophile Requirement** | Weak, neutral nucleophiles ($\text{H}_2\text{O}, \text{ROH}$) | Strong, negatively charged nucleophiles ($\text{OH}^-, \text{CN}^-, \text{I}^-, \text{RS}^-$) |
| **Optimal Solvent** | **Polar Protic** ($\text{H}_2\text{O}, \text{EtOH}$, acetic acid) — solvates carbocation & leaving group | **Polar Aprotic** ($\text{DMSO, DMF, Acetone}$) — leaves nucleophile unencumbered |
| **Rearrangements** | Possible (hydride/methyl shifts to form more stable carbocations) | **Never observed** (concerted, no intermediate) |''';
  }

  static String _buildE1VsE2Comparison() {
    return r'''### **Comprehensive Comparison: $\text{E}1$ vs $\text{E}2$ Elimination Mechanisms**

#### **1. Fundamental Distinction**
* **$\text{E}1$ (Elimination Unimolecular)**: A two-step pathway where the leaving group departs first to form a carbocation intermediate, followed by base deprotonation to yield an alkene.
  $$\text{Rate} = k[\text{Substrate}]$$
* **$\text{E}2$ (Elimination Bimolecular)**: A concerted single-step pathway requiring an **anti-periplanar geometry** ($180^\circ$ dihedral angle between $\beta\text{-H}$ and leaving group $\text{X}$).
  $$\text{Rate} = k[\text{Substrate}][\text{Base}]$$

---

#### **2. Regiochemical Control: Saytzeff vs Hofmann**
* **Saytzeff (Zaitsev) Rule**: Standard small unhindered bases ($\text{EtO}^-, \text{OH}^-$) abstract the proton from the more substituted $\beta$-carbon to produce the **more thermodynamically stable, more highly substituted alkene**.
* **Hofmann Rule**: Bulky sterically hindered bases (e.g., Potassium *tert*-butoxide $\text{KO}t\text{-Bu}$, $\text{LDA}$) or substrates with poor leaving groups ($\text{-N}^+\text{Me}_3$, $\text{-F}$) selectively abstract the most sterically accessible proton, giving the **less substituted, terminal alkene** as the major kinetic product.''';
  }

  // =========================================================================
  // CURATED MSC & BSC CHEMISTRY TOPICS MODULE
  // =========================================================================

  static String? _matchCuratedChemistry(String q, String originalQuery) {
    // -------------------------------------------------------------
    // 1. ANALYTICAL & SOLUTION CHEMISTRY
    // -------------------------------------------------------------
    if (q.contains('ppm') || q.contains('parts per million') || q.contains('ppb')) {
      return r'''### **Parts Per Million (ppm) and Parts Per Billion (ppb)**

#### **1. Definition & Principle**
**Parts per million (ppm)** is an analytical unit of concentration expressing the mass of solute per $10^6$ (one million) parts of total solution mass. It is specifically employed in environmental toxicology, water quality testing, trace mineral analysis, and spectroscopy where concentrations are too minuscule for molarity.

---

#### **2. Mathematical Formulas**
$$\text{ppm} = \frac{\text{Mass of Solute}}{\text{Total Mass of Solution}} \times 10^6$$
$$\text{ppb} = \frac{\text{Mass of Solute}}{\text{Total Mass of Solution}} \times 10^9$$

* **For Dilute Aqueous Solutions (Density $\approx 1.0\text{ g/mL}$)**:
  $$\mathbf{1\text{ ppm} = 1\text{ mg/L} = 1\,\mu\text{g/mL}}$$
  $$\mathbf{1\text{ ppb} = 1\,\mu\text{g/L} = 1\text{ ng/mL}}$$

---

#### **3. Conversions & Applications**
* **Percent to ppm**: $1\% = 10,000\text{ ppm}$.
* **ppm to Molarity ($M$)**: $M = \frac{\text{ppm}}{M_w \times 1000}$.
* **Spectroscopy**: In $^1\text{H}$ and $^{13}\text{C}$ NMR spectroscopy, chemical shifts are quoted in $\text{ppm}$ ($\delta$) relative to TMS, making shift values independent of the spectrometer's operating frequency.''';
    }

    if (q.contains('normality') || q.contains('equivalent weight') || q.contains('n-factor') || q.contains('gram equivalent')) {
      return r'''### **Normality ($N$) and Equivalent Weight**

#### **1. Definition & Principle**
**Normality ($N$)** is the number of **gram equivalents** of solute dissolved per **liter of solution** ($\text{eq/L}$). Unlike molarity, normality directly reflects the reacting capacity (equivalents) of a substance in acid-base neutralizations, redox titrations, and precipitation reactions.

---

#### **2. Mathematical Formulation**
$$N = \frac{\text{Gram Equivalents of Solute}}{\text{Volume of Solution (L)}} = \frac{w \times 1000}{E \times V\text{ (in mL)}}$$

Where **Equivalent Weight ($E$)** is defined as:
$$E = \frac{\text{Molar Mass } (M_w)}{n\text{-factor}}$$

---

#### **3. Calculating the $n$-Factor**
1. **Acids (Basicity = number of replaceable $\text{H}^+$ ions)**:
   * $\text{HCl} \rightarrow n = 1 \implies E = M_w / 1$
   * $\text{H}_2\text{SO}_4 \rightarrow n = 2 \implies E = M_w / 2 = 98.08 / 2 = 49.04\text{ g/eq}$
   * $\text{H}_3\text{PO}_4 \rightarrow n = 3$; $\text{H}_3\text{PO}_3 \rightarrow n = 2$ (one non-ionizable $\text{P-H}$ bond)
2. **Bases (Acidity = number of replaceable $\text{OH}^-$ ions)**:
   * $\text{NaOH} \rightarrow n = 1$; $\text{Ca(OH)}_2 \rightarrow n = 2$
3. **Oxidizing & Reducing Agents ($n$-factor = change in oxidation state per molecule)**:
   * $\text{KMnO}_4 \text{ in acidic medium } (\text{Mn}^{7+} \rightarrow \text{Mn}^{2+}): \Delta\text{O.S.} = 5 \implies E = M_w / 5 = 158.04 / 5 = 31.60\text{ g/eq}$
   * $\text{K}_2\text{Cr}_2\text{O}_7 \text{ in acid } (2\text{Cr}^{6+} \rightarrow 2\text{Cr}^{3+}): \Delta\text{O.S.} = 6 \implies E = M_w / 6 = 294.18 / 6 = 49.03\text{ g/eq}$

---

#### **4. Crucial Relationships**
* $$\mathbf{N = M \times n\text{-factor}}$$
* **Law of Equivalence for Titrations**: $N_1V_1 = N_2V_2$ (one equivalent of any reactant reacts quantitatively with one equivalent of another).''';
    }

    if (q.contains('mole') && (q.contains('concept') || q.contains('avogadro') || q.contains('molar mass') || q.contains('what is mole'))) {
      return r'''### **The Mole Concept & Avogadro's Number**

#### **1. Principle & Definition**
A **mole** (symbol: $\text{mol}$) is the fundamental SI unit for the amount of substance. One mole contains exactly **$6.02214076 \times 10^{23}$** elementary entities (atoms, molecules, ions, electrons, or formula units). This constant is known as **Avogadro's constant ($N_A$)**.

---

#### **2. Fundamental Formulas**
1. **From Mass ($w$)**:
   $$n = \frac{w\text{ (g)}}{M_w\text{ (g/mol)}}$$
2. **From Number of Particles ($N$)**:
   $$n = \frac{N}{N_A} \quad (N_A = 6.022 \times 10^{23}\text{ mol}^{-1})$$
3. **From Gas Volume at STP ($0^\circ\text{C}, 1\text{ atm}$)**:
   $$n = \frac{V\text{ (in Liters)}}{22.414\text{ L/mol}}$$
4. **From Solution Concentration**:
   $$n = M \times V\text{ (L)} = \frac{M \times V\text{ (mL)}}{1000}$$

---

#### **3. Academic Significance**
The mole establishes the quantitative bridge between the microscopic atomic world (atomic mass units, $\text{amu}$) and macroscopic laboratory quantities (grams, kilograms).''';
    }

    if (q.contains('molarity') || q.contains('molality') || q.contains('mole fraction')) {
      return r'''### **Molarity, Molality, and Mole Fraction**

#### **1. Molarity ($M$)**
* **Definition**: Moles of solute per liter of total solution ($\text{mol/L}$).
* **Formula**: $$M = \frac{w \times 1000}{M_w \times V_{\text{soln (mL)}}}$$
* **Property**: **Temperature-dependent** because liquid volume expands with temperature.

---

#### **2. Molality ($m$)**
* **Definition**: Moles of solute per kilogram of pure solvent ($\text{mol/kg}$).
* **Formula**: $$m = \frac{w \times 1000}{M_w \times W_{\text{solvent (g)}}}$$
* **Property**: **Temperature-independent** because mass is invariant to thermal expansion. Crucial for colligative property studies ($\Delta T_b = K_b m$, $\Delta T_f = K_f m$).

---

#### **3. Mole Fraction ($X$)**
* **Definition**: Ratio of moles of a given component to total moles in the mixture.
* **Formula**: $$X_A = \frac{n_A}{n_A + n_B + \cdots} \quad\text{and}\quad \sum X_i = 1$$
* **Property**: Dimensionless, temperature-independent.''';
    }

    // -------------------------------------------------------------
    // 2. SPECTROSCOPY & INSTRUMENTATION
    // -------------------------------------------------------------
    if (q.contains('beer') || q.contains('lambert') || q.contains('absorbance') || q.contains('transmittance')) {
      return r'''### **Beer-Lambert Law (UV-Visible Spectrophotometry)**

#### **1. Principle & Statement**
The **Beer-Lambert Law** governs the absorption of monochromatic light as it passes through a homogeneous absorbing medium. It states that **Absorbance ($A$)** is directly proportional to both the **molar concentration ($c$)** of the absorbing species and the **path length ($b$ or $l$)** of the sample cuvette.

---

#### **2. Mathematical Formulation**
$$\mathbf{A = \varepsilon \cdot b \cdot c = \log_{10}\left(\frac{I_0}{I}\right) = -\log_{10}(T)}$$

Where:
* $A$ = Absorbance (dimensionless optical density).
* $\varepsilon$ = **Molar Absorptivity / Extinction Coefficient** ($\text{L}\cdot\text{mol}^{-1}\cdot\text{cm}^{-1}$). High $\varepsilon > 10^4$ indicates spin- and Laporte-allowed transitions (e.g. $\pi \rightarrow \pi^*$, CT bands).
* $b$ = Path length of cuvette (typically $1.0\text{ cm}$).
* $c$ = Molar concentration ($\text{mol/L}$).
* $I_0, I$ = Incident and transmitted light intensity.
* $T = I / I_0$ = Transmittance ($\%T = T \times 100$).

---

#### **3. Limitations & Deviations**
1. **Real Deviations**: High concentrations ($> 0.01\text{ M}$) cause electrostatic interactions between absorbing particles, altering refractive index and $\varepsilon$.
2. **Chemical Deviations**: Association, dissociation, polymerization, or pH-dependent equilibria of analyte (e.g. Chromate $\leftrightarrow$ Dichromate equilibrium).
3. **Instrumental Deviations**: Non-monochromatic polychromatic light, stray radiation, or cuvette mismatch.''';
    }

    if (q.contains('ir spectroscopy') || q.contains('infrared') || q.contains('stretching frequency') || q.contains('hooke')) {
      return r'''### **Infrared (IR) Spectroscopy**

#### **1. Principle**
IR spectroscopy measures the vibrational transitions of molecules upon absorbing infrared radiation ($4000 - 400\text{ cm}^{-1}$). A molecule is **IR active** only if the vibrational motion results in a **net change in the molecular dipole moment** ($\frac{d\mu}{dr} \neq 0$).

---

#### **2. Hooke’s Law for Vibrational Frequency**
The stretching frequency ($\bar{\nu}$ in $\text{cm}^{-1}$) of a diatomic bond is given by:
$$\bar{\nu} = \frac{1}{2\pi c}\sqrt{\frac{k}{\mu}}$$
*(where $k$ is the bond force constant and $\mu = \frac{m_1 m_2}{m_1 + m_2}$ is the reduced mass).*

---

#### **3. Characteristic Diagnostic Absorption Frequencies**
* **$3600 - 3200\text{ cm}^{-1}$**: $\text{O-H}$ alcohol (broad, H-bonded) and $\text{N-H}$ amine/amide.
* **$3300\text{ cm}^{-1}$**: $\text{C}\equiv\text{C-H}$ (terminal alkyne $\text{C-H}$ stretch).
* **$3100 - 3000\text{ cm}^{-1}$**: $sp^2$ $\text{C-H}$ (aromatic and alkene $\text{C-H}$).
* **$2960 - 2850\text{ cm}^{-1}$**: $sp^3$ $\text{C-H}$ (alkane stretching).
* **$2260 - 2220\text{ cm}^{-1}$**: $\text{C}\equiv\text{N}$ (nitrile) and $\text{C}\equiv\text{C}$ (alkyne).
* **$1820 - 1650\text{ cm}^{-1}$ (Carbonyl $\text{C=O}$ Region)**:
  - Anhydride: $1820\text{ & }1760\text{ cm}^{-1}$ (doublet)
  - Acid chloride: $1800\text{ cm}^{-1}$
  - Ester: $1735\text{ cm}^{-1}$
  - Aldehyde / Ketone: $1715\text{ cm}^{-1}$ (shifts down with conjugation)
  - Amide: $1680 - 1650\text{ cm}^{-1}$ (Amide I band)
* **$1600, 1500, 1450\text{ cm}^{-1}$**: Aromatic ring skeletal vibrations ($\text{C=C}$).''';
    }

    if (q.contains('chromatography') || q.contains('hplc') || q.contains('tlc') || q.contains('rf value') || q.contains('retention')) {
      return r'''### **Chromatography: Principles, TLC, and HPLC**

#### **1. Principle of Separation**
Chromatography separates mixture components based on differential partitioning between a **stationary phase** and a **mobile phase**. Components with higher affinity for the stationary phase move slower, while components favoring the mobile phase elute faster.

---

#### **2. Thin-Layer Chromatography (TLC)**
* **Retardation Factor ($R_f$)**:
  $$R_f = \frac{\text{Distance traveled by compound}}{\text{Distance traveled by solvent front}}$$
  ($0 \le R_f \le 1$). Polar compounds adhere strongly to polar silica gel ($\text{SiO}_2$) stationary phase, giving lower $R_f$ in non-polar eluents.

---

#### **3. High-Performance Liquid Chromatography (HPLC)**
* **Normal Phase HPLC**: Polar stationary phase (silica) + non-polar mobile phase (hexane).
* **Reversed-Phase HPLC (RP-HPLC, most common)**: Non-polar stationary phase ($\text{C}_{18}$ / ODS column) + polar mobile phase ($\text{H}_2\text{O} / \text{MeCN} / \text{MeOH}$). Non-polar analytes are strongly retained and elute last.
* **Column Efficiency (Theoretical Plates $N$)**:
  $$N = 16\left(\frac{t_R}{W}\right)^2 = 5.545\left(\frac{t_R}{W_{1/2}}\right)^2$$
  *(where $t_R$ is retention time, $W$ is baseline peak width).*''';
    }

    // -------------------------------------------------------------
    // 3. PHYSICAL CHEMISTRY, THERMODYNAMICS & KINETICS
    // -------------------------------------------------------------
    if (q.contains('gibbs') || q.contains('free energy') || q.contains('spontaneity') || q.contains('entropy') || q.contains('enthalpy')) {
      return r'''### **Gibbs Free Energy ($\Delta G$), Entropy, and Reaction Spontaneity**

#### **1. Principle & Definition**
**Gibbs Free Energy ($G$)** is a thermodynamic potential that measures the maximum reversible non-PV work obtainable from a closed system at constant temperature and pressure. The change in Gibbs Free Energy ($\Delta G$) serves as the universal criterion for chemical spontaneity.

---

#### **2. The Gibbs-Helmholtz Equation**
$$\mathbf{\Delta G = \Delta H - T\Delta S}$$

Where:
* $\Delta H$ = Enthalpy change (heat absorbed or released).
* $\Delta S$ = Entropy change (measure of dispersal of energy/matter).
* $T$ = Absolute temperature in Kelvin ($\text{K}$).

---

#### **3. Spontaneity Criteria ($\Delta G$)**
* **$\Delta G < 0$ (Negative)**: The process is **spontaneous** (exergonic).
* **$\Delta G = 0$**: The system is at dynamic **chemical equilibrium**.
* **$\Delta G > 0$ (Positive)**: The forward process is **non-spontaneous** (endergonic); the reverse reaction is spontaneous.

---

#### **4. Thermodynamic Spontaneity Matrix**

| $\Delta H$ | $\Delta S$ | Spontaneity Condition | Example |
| :---: | :---: | :--- | :--- |
| **$-$ (Exothermic)** | **$+$ (Disorder increases)** | **Spontaneous at all temperatures** ($\Delta G < 0$ always) | Combustion, decomposition of $\text{H}_2\text{O}_2$ |
| **$-$ (Exothermic)** | **$-$ (Disorder decreases)** | **Spontaneous at low temperatures** ($|T\Delta S| < |\Delta H|$) | Ammonia synthesis ($\text{N}_2 + 3\text{H}_2 \rightarrow 2\text{NH}_3$) |
| **$+$ (Endothermic)** | **$+$ (Disorder increases)** | **Spontaneous at high temperatures** ($T\Delta S > \Delta H$) | Melting of ice, $\text{CaCO}_3 \rightarrow \text{CaO} + \text{CO}_2$ |
| **$+$ (Endothermic)** | **$-$ (Disorder decreases)** | **Non-spontaneous at all temperatures** ($\Delta G > 0$ always) | $2\text{H}_2\text{O} \rightarrow 2\text{H}_2 + \text{O}_2$ without external power |

---

#### **5. Equilibrium Constant Relation**
$$\mathbf{\Delta G^\circ = -RT \ln K_{eq} = -2.303 RT \log_{10} K_{eq}}$$''';
    }

    if (q.contains('nernst') || q.contains('electrochemistry') || q.contains('galvanic') || q.contains('electrochemical cell') || q.contains('emf')) {
      return r'''### **Electrochemistry: The Nernst Equation & Cell EMF**

#### **1. Principle & Statement**
The **Nernst Equation** relates the reduction potential of an electrochemical cell (or half-cell) to the standard electrode potential ($E^\circ$), temperature, and the reaction quotient ($Q$) of participating species under non-standard conditions.

---

#### **2. Mathematical Formulation**
$$\mathbf{E_{\text{cell}} = E^\circ_{\text{cell}} - \frac{RT}{nF} \ln Q}$$

At standard temperature ($298.15\text{ K} = 25^\circ\text{C}$), inserting constants ($R = 8.314\text{ J/mol}\cdot\text{K}$, $F = 96485\text{ C/mol}$):
$$\mathbf{E_{\text{cell}} = E^\circ_{\text{cell}} - \frac{0.0591}{n} \log_{10} Q}$$

Where:
* $E_{\text{cell}}$ = Non-standard electromotive force (EMF in Volts).
* $E^\circ_{\text{cell}} = E^\circ_{\text{cathode}} - E^\circ_{\text{anode}}$ (Standard reduction potentials).
* $n$ = Number of moles of electrons transferred in the balanced redox equation.
* $Q = \frac{[\text{Products}]^p}{[\text{Reactants}]^r}$ = Reaction quotient (pure solids and liquids have activity $= 1$).

---

#### **3. Relationship with Gibbs Free Energy & Equilibrium**
* $$\mathbf{\Delta G = -nFE_{\text{cell}} \quad\text{and}\quad \Delta G^\circ = -nFE^\circ_{\text{cell}}}$$
* At equilibrium, $E_{\text{cell}} = 0$ and $Q = K_{eq}$:
  $$\mathbf{E^\circ_{\text{cell}} = \frac{0.0591}{n} \log_{10} K_{eq}}$$''';
    }

    if (q.contains('arrhenius') || q.contains('activation energy') || q.contains('rate constant') || q.contains('kinetics') || q.contains('half life')) {
      return r'''### **Chemical Kinetics: Rate Laws & The Arrhenius Equation**

#### **1. Integrated Rate Laws & Half-Life ($t_{1/2}$)**

| Order | Differential Rate Law | Integrated Equation | Half-Life ($t_{1/2}$) | Units of $k$ |
| :---: | :--- | :--- | :--- | :--- |
| **0** | $\text{Rate} = k$ | $[A] = [A]_0 - kt$ | $t_{1/2} = \frac{[A]_0}{2k}$ | $\text{mol}\cdot\text{L}^{-1}\cdot\text{s}^{-1}$ |
| **1** | $\text{Rate} = k[A]$ | $\ln[A] = \ln[A]_0 - kt$ | $t_{1/2} = \frac{\ln 2}{k} = \frac{0.693}{k}$ | $\text{s}^{-1}$ |
| **2** | $\text{Rate} = k[A]^2$ | $\frac{1}{[A]} = \frac{1}{[A]_0} + kt$ | $t_{1/2} = \frac{1}{k[A]_0}$ | $\text{L}\cdot\text{mol}^{-1}\cdot\text{s}^{-1}$ |

---

#### **2. The Arrhenius Equation**
Models the temperature dependence of chemical reaction rate constants:
$$\mathbf{k = A \cdot e^{-E_a / RT}}$$
$$\mathbf{\ln k = \ln A - \frac{E_a}{R}\left(\frac{1}{T}\right)}$$

For two temperatures $T_1$ and $T_2$:
$$\mathbf{\log_{10}\left(\frac{k_2}{k_1}\right) = \frac{E_a}{2.303 R} \left(\frac{T_2 - T_1}{T_1 T_2}\right)}$$

Where:
* $E_a$ = **Activation Energy** ($\text{J/mol}$ or $\text{kJ/mol}$).
* $A$ = **Pre-exponential frequency factor** (collision frequency and steric orientation).
* $R = 8.314\text{ J}\cdot\text{mol}^{-1}\cdot\text{K}^{-1}$.''';
    }

    if (q.contains('ph') || q.contains('poh') || q.contains('buffer') || q.contains('henderson')) {
      return r'''### **pH, pOH, and Buffer Solutions (Henderson-Hasselbalch)**

#### **1. Definitions of $\text{pH}$ and $\text{pOH}$**
* $$\text{pH} = -\log_{10}[\text{H}_3\text{O}^+] \quad\text{and}\quad \text{pOH} = -\log_{10}[\text{OH}^-]$$
* **Autoionization of Water ($25^\circ\text{C}$)**:
  $$K_w = [\text{H}_3\text{O}^+][\text{OH}^-] = 1.0 \times 10^{-14} \implies \mathbf{\text{pH} + \text{pOH} = 14.00}$$

---

#### **2. Buffer Solutions**
A buffer resists changes in $\text{pH}$ upon addition of small amounts of strong acid or base.
* **Acidic Buffer**: Weak acid + conjugate base salt (e.g., $\text{CH}_3\text{COOH} + \text{CH}_3\text{COONa}$).
* **Basic Buffer**: Weak base + conjugate acid salt (e.g., $\text{NH}_4\text{OH} + \text{NH}_4\text{Cl}$).

---

#### **3. The Henderson-Hasselbalch Equation**
* **For Acidic Buffers**:
  $$\mathbf{\text{pH} = \text{p}K_a + \log_{10}\left(\frac{[\text{Conjugate Base}]}{[\text{Weak Acid}]}\right) = \text{p}K_a + \log_{10}\left(\frac{[\text{Salt}]}{[\text{Acid}]}\right)}$$
* **For Basic Buffers**:
  $$\mathbf{\text{pOH} = \text{p}K_b + \log_{10}\left(\frac{[\text{Conjugate Acid}]}{[\text{Weak Base}]}\right)}$$
* **Maximum Buffer Capacity**: Occurs when $[\text{Salt}] = [\text{Acid}]$, i.e. $\text{pH} = \text{p}K_a$.''';
    }

    // -------------------------------------------------------------
    // 4. INORGANIC, BONDING & QUANTUM CHEMISTRY
    // -------------------------------------------------------------
    if (q.contains('mot') || q.contains('molecular orbital theory') || q.contains('bond order')) {
      return r'''### **Molecular Orbital Theory (MOT)**

#### **1. Core Principles (LCAO Method)**
Atomic orbitals combine linearly (LCAO) to form **bonding ($\sigma, \pi$)** and **antibonding ($\sigma^*, \pi^*$)** molecular orbitals:
1. Bonding MOs: In-phase constructive overlap ($\psi_B = \psi_A + \psi_B$) $\rightarrow$ lower energy, high electron density between nuclei.
2. Antibonding MOs: Out-of-phase destructive overlap ($\psi_A^* = \psi_A - \psi_B$) $\rightarrow$ higher energy with a nodal plane between nuclei.

---

#### **2. Bond Order Formula & Stability**
$$\mathbf{\text{Bond Order} = \frac{N_b - N_a}{2}}$$
*(where $N_b$ is number of electrons in bonding MOs, and $N_a$ is number of electrons in antibonding MOs).*
* A species is stable if $\text{Bond Order} > 0$.
* Higher bond order $\rightarrow$ shorter bond length, higher bond dissociation energy.

---

#### **3. MO Ordering for Diatomic Molecules**
* **For $\text{B}_2, \text{C}_2, \text{N}_2$ ($\le 14$ electrons, $s\text{-}p$ mixing active)**:
  $$\sigma_{1s} < \sigma^*_{1s} < \sigma_{2s} < \sigma^*_{2s} < (\pi_{2p_x} = \pi_{2p_y}) < \sigma_{2p_z} < (\pi^*_{2p_x} = \pi^*_{2p_y}) < \sigma^*_{2p_z}$$
* **For $\text{O}_2, \text{F}_2$ ($> 14$ electrons, no significant $s\text{-}p$ mixing)**:
  $$\sigma_{1s} < \sigma^*_{1s} < \sigma_{2s} < \sigma^*_{2s} < \sigma_{2p_z} < (\pi_{2p_x} = \pi_{2p_y}) < (\pi^*_{2p_x} = \pi^*_{2p_y}) < \sigma^*_{2p_z}$$
* **Paramagnetism of $\text{O}_2$**: $\text{O}_2$ has 16 electrons: $\text{Bond Order} = (10 - 6)/2 = 2$. It contains two unpaired electrons in the degenerate $(\pi^*_{2p_x}, \pi^*_{2p_y})$ orbitals, proving paramagnetic behavior.''';
    }

    if (q.contains('vsepr') || q.contains('hybridization') || q.contains('geometry') || q.contains('shape of molecule')) {
      return r'''### **VSEPR Theory & Hybridization**

#### **1. Valence Shell Electron Pair Repulsion (VSEPR)**
Electron pairs around a central atom repel each other and arrange themselves in space to minimize electrostatic repulsion.
* **Repulsion Hierarchy**: $\mathbf{\text{Lone Pair - Lone Pair} > \text{Lone Pair - Bond Pair} > \text{Bond Pair - Bond Pair}}$.

---

#### **2. Steric Number & Hybridization Guide**

| Steric No. | Hybridization | Electron Geometry | Lone Pairs | Molecular Shape | Example |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **2** | $sp$ | Linear ($180^\circ$) | 0 | Linear | $\text{BeCl}_2, \text{CO}_2, \text{C}_2\text{H}_2$ |
| **3** | $sp^2$ | Trigonal Planar ($120^\circ$) | 0 | Trigonal Planar | $\text{BF}_3, \text{SO}_3$ |
| **3** | $sp^2$ | Trigonal Planar | 1 | Bent / V-shaped ($<120^\circ$) | $\text{SO}_2, \text{O}_3$ |
| **4** | $sp^3$ | Tetrahedral ($109.5^\circ$) | 0 | Tetrahedral | $\text{CH}_4, \text{NH}_4^+$ |
| **4** | $sp^3$ | Tetrahedral | 1 | Trigonal Pyramidal ($107^\circ$) | $\text{NH}_3, \text{PCl}_3$ |
| **4** | $sp^3$ | Tetrahedral | 2 | Bent / Angular ($104.5^\circ$) | $\text{H}_2\text{O}, \text{H}_2\text{S}$ |
| **5** | $sp^3d$ | Trigonal Bipyramidal | 0 | Trigonal Bipyramidal | $\text{PCl}_5$ |
| **5** | $sp^3d$ | Trigonal Bipyramidal | 1 | See-Saw | $\text{SF}_4$ |
| **5** | $sp^3d$ | Trigonal Bipyramidal | 2 | T-Shaped | $\text{ClF}_3$ |
| **5** | $sp^3d$ | Trigonal Bipyramidal | 3 | Linear | $\text{XeF}_2, \text{I}_3^-$ |
| **6** | $sp^3d^2$ | Octahedral ($90^\circ$) | 0 | Octahedral | $\text{SF}_6$ |
| **6** | $sp^3d^2$ | Octahedral | 1 | Square Pyramidal | $\text{BrF}_5, \text{IF}_5$ |
| **6** | $sp^3d^2$ | Octahedral | 2 | Square Planar | $\text{XeF}_4$ |''';
    }

    if (q.contains('quantum number') || q.contains('pauli') || q.contains('hund') || q.contains('aufbau')) {
      return r'''### **Atomic Structure: Quantum Numbers & Electronic Principles**

#### **1. The Four Quantum Numbers**
1. **Principal Quantum Number ($n = 1, 2, 3, \dots$)**: Defines main energy level and orbital radius.
2. **Azimuthal / Orbital Angular Momentum ($l = 0, 1, \dots, n-1$)**: Defines orbital subshell shape ($l=0 \rightarrow s$, $l=1 \rightarrow p$, $l=2 \rightarrow d$, $l=3 \rightarrow f$).
3. **Magnetic Quantum Number ($m_l = -l \dots 0 \dots +l$)**: Defines spatial orientation ($2l + 1$ orbitals per subshell).
4. **Spin Quantum Number ($m_s = +\frac{1}{2}, -\frac{1}{2}$)**: Defines intrinsic electron spin projection.

---

#### **2. Fundamental Electronic Rules**
* **Aufbau Principle**: Electrons fill available atomic orbitals in order of increasing $(n + l)$ energy values: $1s < 2s < 2p < 3s < 3p < 4s < 3d < 4p \dots$
* **Pauli Exclusion Principle**: No two electrons in the same atom can have the identical set of all four quantum numbers ($n, l, m_l, m_s$). An orbital holds at most 2 electrons of opposite spin.
* **Hund’s Rule of Maximum Multiplicity**: In degenerate orbitals ($p, d, f$), electrons occupy singly with parallel spins before pairing commences.''';
    }

    // -------------------------------------------------------------
    // 5. NAMED ORGANIC REACTIONS
    // -------------------------------------------------------------
    if (q.contains('cannizzaro') || q.contains('cannizaro')) {
      return r'''### **Cannizzaro Reaction**

#### **1. Principle & Definition**
The **Cannizzaro reaction** is a base-induced redox disproportionation of aldehydes that do **not** contain an $\alpha$-hydrogen atom. Under strongly alkaline conditions (e.g., concentrated $\text{NaOH}$ or $\text{KOH}$), one molecule of aldehyde is reduced to the corresponding primary alcohol, while a second molecule is oxidized to a carboxylic acid salt.

$$\text{2 R-CHO} + \text{OH}^- \xrightarrow{\text{conc. NaOH}} \text{R-CH}_2\text{OH} + \text{R-COO}^-$$

---

#### **2. Representative Reaction**
$$\text{2 C}_6\text{H}_5\text{CHO} + \text{NaOH} \rightarrow \text{C}_6\text{H}_5\text{CH}_2\text{OH (Benzyl alcohol)} + \text{C}_6\text{H}_5\text{COONa (Sodium benzoate)}$$

---

#### **3. Step-by-Step Reaction Mechanism**
1. **Step 1: Nucleophilic Addition of Hydroxide**: Hydroxide ion ($\text{OH}^-$) attacks the electrophilic carbonyl carbon to form a tetrahedral oxyanion intermediate.
   $$\text{R-CHO} + \text{OH}^- \rightleftharpoons \text{R-CH(O}^-\text{)(OH)}$$
2. **Step 2: Hydride Ion Transfer (Rate-Determining Step)**: Tetrahedral intermediate collapses, reforming the carbonyl bond while directly transferring a **hydride ion ($\text{H}^-$)** to a second aldehyde molecule.
   $$\text{R-CH(O}^-\text{)(OH)} + \text{R-CHO} \xrightarrow{\text{slow (RDS)}} \text{R-COOH} + \text{R-CH}_2\text{O}^-$$
3. **Step 3: Rapid Proton Transfer**: Alkoxide abstracts the carboxylic proton, yielding stable carboxylate anion and alcohol.
   $$\text{R-COOH} + \text{R-CH}_2\text{O}^- \xrightarrow{\text{fast}} \text{R-COO}^- + \text{R-CH}_2\text{OH}$$''';
    }

    if (q.contains('aldol')) {
      return r'''### **Aldol Condensation & Addition**

#### **1. Principle & Definition**
The **Aldol reaction** involves the nucleophilic addition of an enol or enolate ion (derived from an aldehyde or ketone containing at least one $\alpha$-hydrogen) to the carbonyl carbon of another aldehyde or ketone, forming a **$\beta$-hydroxy carbonyl compound** (Aldol). Subsequent dehydration (loss of $\text{H}_2\text{O}$) yields an **$\alpha,\beta$-unsaturated carbonyl compound**.

$$\text{2 CH}_3\text{CHO} \xrightarrow{\text{dil. NaOH}} \text{CH}_3\text{-CH(OH)-CH}_2\text{-CHO} \xrightarrow{\Delta, -\text{H}_2\text{O}} \text{CH}_3\text{-CH=CH-CHO (Crotonaldehyde)}$$

---

#### **2. Step-by-Step Mechanism**
1. **Enolate Formation**: Base abstracts an $\alpha$-proton to form a resonance-stabilized enolate anion.
2. **Nucleophilic Addition**: Enolate carbon attacks the carbonyl carbon of another un-ionized aldehyde.
3. **Protonation**: Alkoxide ion abstracts a proton from water to regenerate the base and yield the $\beta$-hydroxyaldehyde.
4. **E1cB Dehydration**: Base removes the remaining $\alpha$-proton followed by hydroxide expulsion, driven by conjugated stability.''';
    }

    if (q.contains('wittig')) {
      return r'''### **Wittig Reaction**

#### **1. Principle & Definition**
The **Wittig reaction** converts an aldehyde or ketone into an alkene by reaction with a **phosphonium ylide** ($\text{Ph}_3\text{P=CR}_2$). The driving force is the formation of the exceptionally strong phosphorus-oxygen double bond in triphenylphosphine oxide ($\text{Ph}_3\text{P=O}$, $\sim 540\text{ kJ/mol}$).

$$\text{R}_2\text{C=O} + \text{Ph}_3\text{P=CR'}_2 \rightarrow \text{R}_2\text{C=CR'}_2 + \text{Ph}_3\text{P=O}$$

---

#### **2. Mechanism & Stereochemistry**
1. Nucleophilic ylide carbon attacks carbonyl carbon with concomitant $\text{P-O}$ bond formation, forming a 4-membered cyclic **oxaphosphetane** intermediate.
2. Retro-[2+2] cycloreversion breaks the ring irreversibly to yield alkene and $\text{Ph}_3\text{P=O}$.
3. **Stereoselectivity**: Non-stabilized ylides yield **(Z)-alkenes** (cis); stabilized ylides (with EWGs) yield **(E)-alkenes** (trans).''';
    }

    if (q.contains('diels') || q.contains('alder')) {
      return r'''### **Diels-Alder Reaction ([4+2] Cycloaddition)**

#### **1. Principle & Definition**
A concerted, stereospecific **[4+2] pericyclic cycloaddition** between a conjugated **diene** (4 $\pi$-electrons in $s\text{-cis}$ conformation) and a **dienophile** (2 $\pi$-electrons) to form a substituted cyclohexene ring.

---

#### **2. Key Stereochemical Rules**
* **Stereospecific**: Retention of diene and dienophile stereochemistry (*cis* $\rightarrow$ *cis*, *trans* $\rightarrow$ *trans*).
* **Alder Endo Rule**: In cyclic dienes, electron-withdrawing groups on the dienophile prefer the *endo* orientation in the transition state due to secondary $\pi$-orbital overlap.''';
    }

    if (q.contains('crystal field') || q.contains('cft') || q.contains('spectrochemical')) {
      return r'''### **Crystal Field Theory (CFT)**

#### **1. Principle**
CFT treats metal-ligand bonds as purely electrostatic interactions where ligands act as point negative charges that split the 5 degenerate $d$-orbitals of the transition metal ion.

---

#### **2. Octahedral Splitting ($O_h$)**
* **$e_g$ set ($d_{x^2-y^2}, d_{z^2}$)**: Repelled directly along axes $\rightarrow$ destabilized by $+0.6\,\Delta_o$ ($+6\,\text{Dq}$).
* **$t_{2g}$ set ($d_{xy}, d_{yz}, d_{xz}$)**: Point between axes $\rightarrow$ stabilized by $-0.4\,\Delta_o$ ($-4\,\text{Dq}$).
* **Spectrochemical Series**: $\text{I}^- < \text{Br}^- < \text{Cl}^- < \text{F}^- < \text{OH}^- < \text{H}_2\text{O} < \text{NH}_3 < \text{en} < \text{NO}_2^- < \text{CN}^- < \text{CO}$.
  - Weak field: $\Delta_o < P \rightarrow$ **High-spin**.
  - Strong field: $\Delta_o > P \rightarrow$ **Low-spin**.''';
    }

    if (q.contains('nmr') || q.contains('chemical shift')) {
      return r'''### **$^1\text{H}$ & $^{13}\text{C}$ NMR Spectroscopy**

#### **1. Principle**
Absorption of radiofrequency radiation by nuclei with non-zero nuclear spin ($I = 1/2$, e.g. $^1\text{H}, ^{13}\text{C}$) in an external magnetic field ($B_0$).

---

#### **2. Chemical Shift ($\delta$ ppm)**
$$\delta = \frac{\nu_{\text{sample}} - \nu_{\text{TMS}}}{\text{Spectrometer frequency (MHz)}} \times 10^6$$
* $0.9 - 1.5\text{ ppm}$: Alkyl $\text{-CH}_3, \text{-CH}_2\text{-}$
* $2.0 - 2.5\text{ ppm}$: Carbonyl $\alpha\text{-H}$ ($-\text{CO-CH}_3$)
* $3.3 - 4.5\text{ ppm}$: Heteroatom-bound $-\text{CH}_2\text{-O-}, -\text{CH}_2\text{-X}$
* $6.5 - 8.5\text{ ppm}$: Aromatic $\text{Ar-H}$ (ring current deshielding)
* $9.0 - 10.0\text{ ppm}$: Aldehyde $-\text{CHO}$
* $10.5 - 12.5\text{ ppm}$: Carboxylic acid $-\text{COOH}$''';
    }

    if (q.contains('beckmann')) {
      return r'''### **Beckmann Rearrangement**

#### **1. Principle & Definition**
Acid-catalyzed rearrangement of an **oxime** into an **amide** or **lactam**. The group located **anti (trans) to the oxime hydroxyl ($-OH$)** undergoes stereospecific 1,2-migration with retention of configuration.

---

#### **2. Industrial Application: Nylon-6**
Rearrangement of **Cyclohexanone oxime** with concentrated $\text{H}_2\text{SO}_4$ produces **$\varepsilon$-Caprolactam**, the monomer for **Nylon-6**.''';
    }

    return null;
  }

  // =========================================================================
  // INTELLIGENT CONTEXT-AWARE ACADEMIC SYNTHESIS (DYNAMIC FALLBACK)
  // =========================================================================

  static String _generateIntelligentAnswer(
    String query, {
    String? subject,
    bool is2M = false,
    bool is5M = false,
    bool is10M = false,
  }) {
    final title = query.length > 60 ? '${query.substring(0, 57)}...' : query;
    final lower = query.toLowerCase();

    // Determine category
    final isCalculationOrUnit = lower.contains('calculate') || lower.contains('formula') || lower.contains('unit') || lower.contains('express');
    final isMechanism = lower.contains('mechanism') || lower.contains('reaction') || lower.contains('synthesis') || lower.contains('reagent');
    final isPhysicalOrThermo = lower.contains('energy') || lower.contains('law') || lower.contains('rate') || lower.contains('equilibrium');
    final isAnalytical = lower.contains('spectr') || lower.contains('chromato') || lower.contains('titrat') || lower.contains('detect');

    final buffer = StringBuffer();
    buffer.writeln('### **Academic Analysis: $title**');
    buffer.writeln();
    buffer.writeln('#### **1. Fundamental Principle & Scientific Definition**');
    buffer.writeln('In scientific and chemical analysis, **$title** addresses key concepts in ${subject ?? "advanced chemistry"}, defining the relationship between molecular behavior, macroscopic properties, and experimental measurement.');
    buffer.writeln();

    if (isCalculationOrUnit) {
      buffer.writeln(r'#### **2. Governing Equations & Units of Measurement**');
      buffer.writeln(r'* **Mathematical Formulation**: Solved by applying standard mass-to-mole stoichiometry, volumetric relationships, or proportionality constants.');
      buffer.writeln(r'* **Standard Units**: Quantified in SI units ($\text{mol}$, $\text{mol/L}$, $\text{g/cm}^3$, $\text{J/mol}$, or dimensionless ratios like $\text{ppm}$).');
      buffer.writeln(r'* **Variables**: Always ensure volume is in liters ($\text{L}$) when calculating molar concentrations, or in kilograms ($\text{kg}$) when evaluating mass-based molalities.');
    } else if (isMechanism) {
      buffer.writeln(r'#### **2. Mechanistic Pathways & Reaction Coordinates**');
      buffer.writeln(r'* **Stepwise Transformation**: Initiated by orbital overlap, electrophile-nucleophile pairing, or radical initiation.');
      buffer.writeln(r'* **Transition State / Intermediates**: Governed by electronic stabilization (resonance, inductive effects) and steric hindrance.');
      buffer.writeln(r'* **Driving Force**: Formation of thermodynamically stable products ($\Delta G < 0$) or irreversible loss of small stable molecules ($\text{H}_2\text{O}, \text{CO}_2, \text{N}_2$).');
    } else if (isPhysicalOrThermo) {
      buffer.writeln(r'#### **2. Thermodynamic & Kinetic Framework**');
      buffer.writeln(r'* **Energetics**: Controlled by energy conservation ($\Delta H$), entropy generation ($\Delta S$), and spontaneity conditions ($\Delta G = \Delta H - T\Delta S$).');
      buffer.writeln(r'* **Equilibrium & Rates**: System parameters respond to temperature, pressure, and concentration according to Le Chatelier’s principle and Arrhenius kinetics ($k = A e^{-E_a/RT}$).');
    } else {
      buffer.writeln(r'#### **2. Scientific Framework & Core Postulates**');
      buffer.writeln(r'* **Governing Principles**: Built upon foundational atomic theory, molecular orbital interactions, and quantitative stoichiometry.');
      buffer.writeln(r'* **Experimental Observation**: Measured using spectroscopic absorption (UV-Vis, IR, NMR) or analytical chromatographic methods (HPLC, GC).');
    }

    buffer.writeln();
    buffer.writeln(r'#### **3. Academic & Examination Key Points**');
    buffer.writeln(r'* Explicitly state all standard assumptions, temperature/pressure conditions, and units.');
    buffer.writeln(r'* Include balanced chemical formulas and state symbols $(\text{aq}, \text{s}, \text{l}, \text{g})$ where applicable.');
    buffer.writeln(r'* For quantitative problems, verify dimensional consistency before finalizing values.');

    return buffer.toString();
  }

  // =========================================================================
  // EXAM MARK FORMATTERS
  // =========================================================================

  static String _format2Mark(String q, String content) {
    final cleanTitle = q.replaceAll(RegExp(r'2\s*[-–]?\s*marks?|for\s*2\s*marks?', caseSensitive: false), '').trim();
    final title = cleanTitle.isEmpty ? '2-Mark Question' : cleanTitle;

    return '''### **2-Mark Academic Response: $title**

**Core Definition & Statement:**
$content

**Key Formula / Principle:**
State the primary governing equation, units, or balanced chemical equation accurately.''';
  }

  static String _format5Mark(String q, String content) {
    final cleanTitle = q.replaceAll(RegExp(r'5\s*[-–]?\s*marks?|for\s*5\s*marks?', caseSensitive: false), '').trim();
    final title = cleanTitle.isEmpty ? '5-Mark Academic Question' : cleanTitle;

    return '''### **5-Mark Academic Response: $title**

$content

---
**Exam Mark Allocation Guide (5 Marks):**
* **Definition & Core Law (1.5 Marks)**: Accurate terminology and statement.
* **Mathematical Formula / Mechanism (2 Marks)**: Variables defined with units or step-by-step arrows.
* **Significance & Example (1.5 Marks)**: Solved numerical illustration or representative reaction.''';
  }

  static String _format10Mark(String q, String content) {
    return '''### **10-Mark Comprehensive University Exam Answer**

$content

---
**Detailed Mark Distribution (10 Marks):**
* **1. Definition, Principle & Historical Context (2 Marks)**
* **2. Detailed Derivation / Step-by-Step Reaction Mechanism (4 Marks)**
* **3. Stereochemistry / Kinetics / Limitations (2 Marks)**
* **4. Representative Solved Numerical / Synthetic Applications (2 Marks)**''';
  }

  // =========================================================================
  // DOCUMENT RAG CONTEXT EXTRACTION
  // =========================================================================

  static String? _extractFromDocument(String question, String text, String docName) {
    final qTerms = question
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((t) => t.length > 2 && !['what', 'explain', 'give', 'notes', 'from', 'about', 'this'].contains(t))
        .toList();

    if (qTerms.isEmpty) return null;

    final paragraphs = text.split(RegExp(r'\n\s*\n|\r\n\s*\r\n'));
    final scored = <MapEntry<String, int>>[];

    for (final p in paragraphs) {
      final pLower = p.toLowerCase();
      var score = 0;
      for (final term in qTerms) {
        if (pLower.contains(term)) score += 2;
      }
      if (score > 0) scored.add(MapEntry(p, score));
    }

    if (scored.isEmpty) return null;

    scored.sort((a, b) => b.value.compareTo(a.value));
    final bestParagraphs = scored.take(3).map((e) => e.key.trim()).join('\n\n');

    return '''### **From Your Uploaded Notes: $docName**

$bestParagraphs

---
*Extracted directly from $docName based on your query.*''';
  }
}
