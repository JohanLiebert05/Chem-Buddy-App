import 'dart:math' as math;

/// Racah & Ligand Field Calculation Result
class RacahCalculationResult {
  final double nu1;
  final double nu2;
  final double nu3;
  final double tenDq;
  final double bComplex;
  final double bFreeIon;
  final double beta;
  final double nephelauxeticPercentage;
  final double racahC;
  final String groundStateTerm;
  final List<String> transitionTerms;
  final String derivationKaTeX;

  const RacahCalculationResult({
    required this.nu1,
    required this.nu2,
    required this.nu3,
    required this.tenDq,
    required this.bComplex,
    required this.bFreeIon,
    required this.beta,
    required this.nephelauxeticPercentage,
    required this.racahC,
    required this.groundStateTerm,
    required this.transitionTerms,
    required this.derivationKaTeX,
  });
}

/// Magnetic Moment & Spin-Orbit Coupling Calculation Result
class MagneticMomentResult {
  final int dElectrons;
  final int unpairedElectrons;
  final double totalSpin;
  final double spinOnlyMoment;
  final double effectiveMoment;
  final double spinOrbitConstant;
  final double alphaCoefficient;
  final String groundTerm;
  final String spinState;
  final double? susceptibilityChiM;
  final String derivationKaTeX;

  const MagneticMomentResult({
    required this.dElectrons,
    required this.unpairedElectrons,
    required this.totalSpin,
    required this.spinOnlyMoment,
    required this.effectiveMoment,
    required this.spinOrbitConstant,
    required this.alphaCoefficient,
    required this.groundTerm,
    required this.spinState,
    this.susceptibilityChiM,
    required this.derivationKaTeX,
  });
}

/// EPR / ESR Calculation Result
class EprCalculationResult {
  final double frequencyGhz;
  final double magneticFieldGauss;
  final double gFactor;
  final int totalHyperfineLines;
  final List<String> intensityRatio;
  final bool isKramersDegenerate;
  final String spinSystem;
  final String interpretation;
  final String derivationKaTeX;

  const EprCalculationResult({
    required this.frequencyGhz,
    required this.magneticFieldGauss,
    required this.gFactor,
    required this.totalHyperfineLines,
    required this.intensityRatio,
    required this.isKramersDegenerate,
    required this.spinSystem,
    required this.interpretation,
    required this.derivationKaTeX,
  });
}

/// Mössbauer Spectroscopy Result
class MossbauerResult {
  final String nucleus; // 57Fe or 119Sn
  final double isomerShift;
  final double quadrupoleSplitting;
  final String oxidationState;
  final String spinState;
  final String coordination;
  final String electronicConfiguration;
  final String explanation;
  final String derivationKaTeX;

  const MossbauerResult({
    required this.nucleus,
    required this.isomerShift,
    required this.quadrupoleSplitting,
    required this.oxidationState,
    required this.spinState,
    required this.coordination,
    required this.electronicConfiguration,
    required this.explanation,
    required this.derivationKaTeX,
  });
}

/// Metal Carbonyl IR Stretching Modes Result
class CarbonylIrResult {
  final String formula;
  final String pointGroup;
  final int totalCoLigands;
  final int irActiveBands;
  final int ramanActiveBands;
  final List<String> irSymmetries;
  final List<String> ramanSymmetries;
  final String backbondingAnalysis;
  final String derivationKaTeX;

  const CarbonylIrResult({
    required this.formula,
    required this.pointGroup,
    required this.totalCoLigands,
    required this.irActiveBands,
    required this.ramanActiveBands,
    required this.irSymmetries,
    required this.ramanSymmetries,
    required this.backbondingAnalysis,
    required this.derivationKaTeX,
  });
}

/// 10-Mark Postgraduate Examination Solved Problem
class Inorganic10MarkExamProblem {
  final String id;
  final String title;
  final String topic;
  final String universityExam;
  final String problemStatement;
  final Map<String, int> rubricMarkDistribution; // e.g. {'Term Symbols': 2, 'Racah B': 3, ...}
  final String fullKaTeXSolution;
  final String takeawayPoints;

  const Inorganic10MarkExamProblem({
    required this.id,
    required this.title,
    required this.topic,
    required this.universityExam,
    required this.problemStatement,
    required this.rubricMarkDistribution,
    required this.fullKaTeXSolution,
    required this.takeawayPoints,
  });
}

/// Comprehensive Inorganic Spectroscopy Calculation Engine
/// Developed for postgraduate MSc Chemistry curricula, CSIR-NET, and GATE examinations.
class InorganicSpectroscopyService {
  // Free-ion Racah B0 values (cm^-1)
  static const Map<String, double> freeIonRacahB = {
    'Ti3+': 850.0,
    'V3+': 860.0,
    'Cr3+': 918.0,
    'Mn3+': 1140.0,
    'Fe3+': 1015.0,
    'Fe2+': 1058.0,
    'Co2+': 971.0,
    'Ni2+': 1030.0,
    'Cu2+': 1240.0,
  };

  // --- 1. Electronic Spectra & Racah Parameters (d8 Octahedral, e.g. Ni2+) ---
  static RacahCalculationResult calculateRacahOctahedralD8({
    required double nu1,
    required double nu2,
    required double nu3,
    double? b0,
    String complexName = '[Ni(H₂O)₆]²⁺',
  }) {
    final tenDq = nu1;
    // Standard approximation from Tanabe-Sugano matrix: 15B = nu2 + nu3 - 3*nu1
    final bComplex = (nu2 + nu3 - (3.0 * nu1)) / 15.0;
    final bFree = b0 ?? freeIonRacahB['Ni2+']!;
    final beta = bComplex / bFree;
    final nephelauxetic = (1.0 - beta) * 100.0;
    final cVal = 4.0 * bComplex;

    final ratio21 = (nu2 / nu1).toStringAsFixed(2);

    final katex = '''
### 10-Mark Academic Derivation: Racah Parameters for Octahedral \$d^8\$ ($complexName)

#### Step 1: Identification of Ground and Excited State Terms
- **Free Ion Ground Term**: For \$d^8\$ (\$Ni^{2+}\$), Russell-Saunders term is \$^3F\$ with excited \$^3P\$ situated at \$15B\$ above \$^3F\$.
- In an octahedral ligand field (\$O_h\$), the \$F\$ term splits into:
  \$\$^3F \\implies ^3A_{2g} (\\text{Ground State}),\\quad ^3T_{2g},\\quad ^3T_{1g}(F)\$\$
  The \$^3P\$ term transforms directly into:
  \$\$^3P \\implies ^3T_{1g}(P)\$\$

#### Step 2: Assignment of Observed Spin-Allowed Absorption Bands
1. \$\\nu_1 = ^3A_{2g} \\to ^3T_{2g} = 10Dq = ${nu1.toStringAsFixed(1)}\\text{ cm}^{-1}\$
2. \$\\nu_2 = ^3A_{2g} \\to ^3T_{1g}(F) = ${nu2.toStringAsFixed(1)}\\text{ cm}^{-1}\$
3. \$\\nu_3 = ^3A_{2g} \\to ^3T_{1g}(P) = ${nu3.toStringAsFixed(1)}\\text{ cm}^{-1}\$

#### Step 3: Calculation of Crystal Field Splitting (\$10Dq\$)
Directly from the lowest energy transition:
\$\$10Dq = \\nu_1 = ${tenDq.toStringAsFixed(1)}\\text{ cm}^{-1}\$\$
\$\$\\text{Transition Ratio: } \\frac{\\nu_2}{\\nu_1} = \\frac{${nu2.toStringAsFixed(1)}}{${nu1.toStringAsFixed(1)}} = $ratio21\\quad (\\text{Expected for octahedral } d^8: 1.5 - 1.8)\$\$

#### Step 4: Calculation of Racah Interelectronic Repulsion Parameter (\$B\$)
Using the secular determinant relation:
\$\$\\nu_2 + \\nu_3 - 3\\nu_1 = 15B\$\$
\$\$B = \\frac{\\nu_2 + \\nu_3 - 3\\nu_1}{15}\$\$
\$\$B = \\frac{${nu2.toStringAsFixed(1)} + ${nu3.toStringAsFixed(1)} - 3(${nu1.toStringAsFixed(1)})}{15}\$\$
\$\$B = \\frac{${(nu2 + nu3).toStringAsFixed(1)} - ${(3.0 * nu1).toStringAsFixed(1)}}{15} = \\mathbf{${bComplex.toStringAsFixed(2)}\\text{ cm}^{-1}}\$\$

#### Step 5: Calculation of Nephelauxetic Ratio (\$\\beta\$) & Covalency
Given free-ion Racah parameter \$B_0(Ni^{2+}) = ${bFree.toStringAsFixed(1)}\\text{ cm}^{-1}\$:
\$\$\\beta = \\frac{B_{\\text{complex}}}{B_0} = \\frac{${bComplex.toStringAsFixed(2)}}{${bFree.toStringAsFixed(1)}} = \\mathbf{${beta.toStringAsFixed(4)}}\$\$
\$\$\\text{Nephelauxetic Effect } (1 - \\beta) \\times 100\\% = \\mathbf{${nephelauxetic.toStringAsFixed(2)}\\%}\$\$
- **Interpretation**: A reduction of \$\$bComplex < $bFree\\text{ cm}^{-1}\$ confirms orbital expansion (cloud-expanding / nephelauxetic effect) and substantial \$M-L\$ covalent bond character.
- **Estimated Racah \$C\$ parameter**: \$C \\approx 4B = \\mathbf{${cVal.toStringAsFixed(1)}\\text{ cm}^{-1}}\$.
''';

    return RacahCalculationResult(
      nu1: nu1,
      nu2: nu2,
      nu3: nu3,
      tenDq: tenDq,
      bComplex: double.parse(bComplex.toStringAsFixed(2)),
      bFreeIon: bFree,
      beta: double.parse(beta.toStringAsFixed(4)),
      nephelauxeticPercentage: double.parse(nephelauxetic.toStringAsFixed(2)),
      racahC: double.parse(cVal.toStringAsFixed(1)),
      groundStateTerm: '^3A_{2g}',
      transitionTerms: ['^3A_{2g} \\to ^3T_{2g}', '^3A_{2g} \\to ^3T_{1g}(F)', '^3A_{2g} \\to ^3T_{1g}(P)'],
      derivationKaTeX: katex,
    );
  }

  // --- 2. Magnetic Moments & Spin-Orbit Coupling ---
  static MagneticMomentResult calculateMagneticMoment({
    required int dElectrons,
    required String geometry, // 'Oh' or 'Td'
    required bool isHighSpin,
    double? lambda, // Spin-orbit coupling constant in cm^-1
    double? tenDq,  // 10Dq in cm^-1
    double? temperatureKelvin,
    double? curieWeissTheta,
    String metalIon = 'Transition Metal Ion',
  }) {
    int unpaired = 0;
    String groundTerm = '';
    double alpha = 4.0;
    double defaultLambda = 0.0;

    // Determine unpaired electrons based on d count and spin
    if (geometry == 'Oh') {
      if (isHighSpin) {
        switch (dElectrons) {
          case 1: unpaired = 1; groundTerm = '^2T_{2g}'; alpha = 0.0; defaultLambda = 154.0; break;
          case 2: unpaired = 2; groundTerm = '^3T_{1g}'; alpha = 0.0; defaultLambda = 104.0; break;
          case 3: unpaired = 3; groundTerm = '^4A_{2g}'; alpha = 4.0; defaultLambda = 92.0; break;
          case 4: unpaired = 4; groundTerm = '^5E_g'; alpha = 2.0; defaultLambda = 88.0; break;
          case 5: unpaired = 5; groundTerm = '^6A_{1g}'; alpha = 0.0; defaultLambda = 0.0; break;
          case 6: unpaired = 4; groundTerm = '^5T_{2g}'; alpha = 0.0; defaultLambda = -100.0; break;
          case 7: unpaired = 3; groundTerm = '^4T_{1g}'; alpha = 0.0; defaultLambda = -180.0; break;
          case 8: unpaired = 2; groundTerm = '^3A_{2g}'; alpha = 4.0; defaultLambda = -315.0; break;
          case 9: unpaired = 1; groundTerm = '^2E_g'; alpha = 2.0; defaultLambda = -830.0; break;
        }
      } else {
        // Low-Spin Octahedral
        switch (dElectrons) {
          case 4: unpaired = 2; groundTerm = '^3T_{1g}'; alpha = 0.0; defaultLambda = 88.0; break;
          case 5: unpaired = 1; groundTerm = '^2T_{2g}'; alpha = 0.0; defaultLambda = 400.0; break;
          case 6: unpaired = 0; groundTerm = '^1A_{1g}'; alpha = 0.0; defaultLambda = 0.0; break;
          case 7: unpaired = 1; groundTerm = '^2E_g'; alpha = 2.0; defaultLambda = -180.0; break;
          case 8: unpaired = 0; groundTerm = '^1A_{1g}'; alpha = 0.0; defaultLambda = 0.0; break; // Square planar analog
          default: unpaired = dElectrons <= 3 ? dElectrons : (10 - dElectrons);
        }
      }
    } else {
      // Tetrahedral
      if (dElectrons == 7) { unpaired = 3; groundTerm = '^4A_2'; alpha = 4.0; defaultLambda = -180.0; }
      else if (dElectrons == 8) { unpaired = 2; groundTerm = '^3T_1'; alpha = 0.0; defaultLambda = -315.0; }
      else if (dElectrons == 9) { unpaired = 1; groundTerm = '^2T_2'; alpha = 0.0; defaultLambda = -830.0; }
      else { unpaired = dElectrons <= 5 ? dElectrons : (10 - dElectrons); }
    }

    final sVal = unpaired / 2.0;
    final muSO = math.sqrt(unpaired * (unpaired + 2.0));

    final effectiveLambda = lambda ?? defaultLambda;
    final dq = tenDq ?? 10000.0;

    // Spin-orbit correction: mu_eff = mu_SO * (1 - alpha * lambda / 10Dq)
    double muEff = muSO;
    if (unpaired > 0 && alpha > 0 && dq > 0) {
      muEff = muSO * (1.0 - (alpha * effectiveLambda / dq));
    }

    // Curie-Weiss Susceptibility
    final temp = temperatureKelvin ?? 298.0;
    final theta = curieWeissTheta ?? 0.0;
    double? chiM;
    if (temp - theta > 0) {
      // mu_eff = 2.828 * sqrt(chi_M * (T - theta)) => chi_M = (mu_eff / 2.828)^2 / (T - theta)
      final cCurie = math.pow(muEff / 2.828, 2);
      chiM = cCurie / (temp - theta);
    }

    final katex = '''
### 10-Mark Academic Derivation: Magnetic Susceptibility & Spin-Orbit Coupling

#### Step 1: Ground State Configuration & Unpaired Electrons
- Electronic configuration: \$d^{$dElectrons}\$ in **$geometry** symmetry (**${isHighSpin ? "High Spin" : "Low Spin"}**).
- Number of unpaired electrons (\$n\$): \$\\mathbf{$unpaired}\$. Total spin \$S = \\frac{n}{2} = ${sVal.toStringAsFixed(1)}\$.
- Ground term: \$\\mathbf{\$\$groundTerm}\$.

#### Step 2: Spin-Only Magnetic Moment (\$\\mu_{\\text{s.o.}}\$)
\$\$\\mu_{\\text{s.o.}} = \\sqrt{n(n + 2)}\\text{ B.M.} = \\sqrt{$unpaired($unpaired + 2)} = \\sqrt{${unpaired * (unpaired + 2)}} = \\mathbf{${muSO.toStringAsFixed(3)}\\text{ B.M.}}\$\$

#### Step 3: Spin-Orbit Coupling Correction (Griffith-Kotani Equation)
For complexes with an \$\$groundTerm\$ ground state:
\$\$\\mu_{\\text{eff}} = \\mu_{\\text{s.o.}} \\left(1 - \\frac{\\alpha \\lambda}{10Dq}\\right)\$\$
Where:
- Orbital mixing coefficient \$\\alpha = ${alpha.toStringAsFixed(1)}\$
- Spin-orbit coupling constant \$\\lambda = ${effectiveLambda.toStringAsFixed(1)}\\text{ cm}^{-1}\$
- Crystal field splitting \$10Dq = ${dq.toStringAsFixed(1)}\\text{ cm}^{-1}\$

Substitution:
\$\$\\mu_{\\text{eff}} = ${muSO.toStringAsFixed(3)} \\left(1 - \\frac{${alpha.toStringAsFixed(1)} \\times (${effectiveLambda.toStringAsFixed(1)})}{${dq.toStringAsFixed(1)}}\\right)\$\$
\$\$\\mu_{\\text{eff}} = ${muSO.toStringAsFixed(3)} \\times \\left(1 - ${(alpha * effectiveLambda / dq).toStringAsFixed(4)}\\right) = \\mathbf{${muEff.toStringAsFixed(3)}\\text{ B.M.}}\$\$

#### Step 4: Curie-Weiss Law Molar Susceptibility (\$\\chi_M\$)
At \$T = ${temp.toStringAsFixed(1)}\\text{ K}\$ with Curie temperature \$\\theta = ${theta.toStringAsFixed(1)}\\text{ K}\$:
\$\$\\chi_M = \\frac{C}{T - \\theta} = \\frac{(\\mu_{\\text{eff}} / 2.828)^2}{T - \\theta} = \\mathbf{${chiM != null ? chiM.toStringAsExponential(3) : "N/A"}\\text{ cm}^3\\text{ mol}^{-1}}\$\$
- **Physical Deduction**: Since \$\\lambda ${effectiveLambda >= 0 ? '> 0' : '< 0'}\$, \$\\mu_{\\text{eff}}\$ is **${muEff > muSO ? "higher than" : "lower than"}** the spin-only value due to **${muEff > muSO ? "mixing with higher T states in > d⁵ configurations" : "covalent orbital quenching"}**.
''';

    return MagneticMomentResult(
      dElectrons: dElectrons,
      unpairedElectrons: unpaired,
      totalSpin: sVal,
      spinOnlyMoment: double.parse(muSO.toStringAsFixed(3)),
      effectiveMoment: double.parse(muEff.toStringAsFixed(3)),
      spinOrbitConstant: effectiveLambda,
      alphaCoefficient: alpha,
      groundTerm: groundTerm,
      spinState: isHighSpin ? 'High Spin' : 'Low Spin',
      susceptibilityChiM: chiM != null ? double.parse(chiM.toStringAsExponential(3)) : null,
      derivationKaTeX: katex,
    );
  }

  // --- 3. EPR / ESR Spectroscopy Engine ---
  static EprCalculationResult calculateEprGFactor({
    required double frequencyGhz,
    required double magneticFieldGauss,
    int? nuclearSpinDouble, // 2*I (e.g. for Cu-63 I=3/2 -> 3)
    int numberOfCoupledNuclei = 1,
    int? superHyperfineSpinDouble, // 2*I for ligand (e.g. 14N I=1 -> 2)
    int numberOfLigands = 0,
  }) {
    // h * nu = g * beta * B
    // g = (h * nu) / (beta_e * B) = 714.484 * nu(GHz) / B(Gauss)
    final gVal = (714.484 * frequencyGhz) / magneticFieldGauss;

    // Hyperfine lines calculation: N = (2*n1*I1 + 1) * (2*n2*I2 + 1)
    int metalLines = 1;
    if (nuclearSpinDouble != null && nuclearSpinDouble > 0) {
      final iMetal = nuclearSpinDouble / 2.0;
      metalLines = (2 * numberOfCoupledNuclei * iMetal + 1).round();
    }

    int ligandLines = 1;
    if (superHyperfineSpinDouble != null && superHyperfineSpinDouble > 0 && numberOfLigands > 0) {
      final iLigand = superHyperfineSpinDouble / 2.0;
      ligandLines = (2 * numberOfLigands * iLigand + 1).round();
    }

    final totalLines = metalLines * ligandLines;

    // Determine Kramers degeneracy
    // Assume S = 1/2 for classic radical / Cu(II) system
    const isKramers = true;

    final katex = '''
### 10-Mark Academic Derivation: EPR / ESR Spectroscopy & \$g\$-Factor Evaluation

#### Step 1: Fundamental EPR Resonance Condition
The interaction of the electron magnetic moment with the static magnetic field is described by the Zeeman Hamiltonian:
\$\$\\hat{H} = g \\beta_e \\mathbf{B} \\cdot \\hat{S}\$\$
Resonance occurs when the microwave photon energy equals the Zeeman energy separation:
\$\$h\\nu = g \\beta_e B\$\$
Rearranging for the Landé \$g\$-factor:
\$\$g = \\frac{h\\nu}{\\beta_e B} = \\frac{714.484 \\times \\nu (\\text{GHz})}{B (\\text{Gauss})}\$\$

#### Step 2: Numerical Substitution & \$g\$-Factor Calculation
- Microwave frequency (\$\\nu\$): \$\\mathbf{${frequencyGhz.toStringAsFixed(3)}\\text{ GHz}}\$ (X-band)
- Magnetic resonance field (\$B\$): \$\\mathbf{${magneticFieldGauss.toStringAsFixed(1)}\\text{ Gauss}}\$
\$\$g = \\frac{714.484 \\times ${frequencyGhz.toStringAsFixed(3)}}{${magneticFieldGauss.toStringAsFixed(1)}} = \\mathbf{${gVal.toStringAsFixed(4)}}\$\$

#### Step 3: Comparison with Free Electron Value (\$g_e = 2.0023\$)
- \$\\Delta g = g - g_e = ${gVal.toStringAsFixed(4)} - 2.0023 = ${(gVal - 2.0023).toStringAsFixed(4)}\$
- **Physical Deduction**: For a \$d^9\$ system (\$Cu^{2+}\$, \$d_{x^2-y^2}\$ ground state), spin-orbit coupling gives:
  \$\$g_\\parallel = 2.0023 - \\frac{8\\lambda}{10Dq} > 2.0023\\quad (\\text{since } \\lambda < 0)\$\$
  The calculated value \$g = ${gVal.toStringAsFixed(4)}\$ is in excellent agreement with metal-centered spin density.

#### Step 4: Hyperfine & Superhyperfine Splitting Multiplets
- Number of lines from central nucleus with spin \$I_M\$:
  \$\$N_{\\text{metal}} = 2 n I_M + 1 = $metalLines\\text{ lines}\$
- Number of superhyperfine lines from \$\${numberOfLigands}\$ equivalent ligand nuclei:
  \$\$N_{\\text{ligand}} = 2 n_L I_L + 1 = $ligandLines\\text{ lines}\$
- **Total Theoretical EPR Lines**:
  \$\$N_{\\text{total}} = N_{\\text{metal}} \\times N_{\\text{ligand}} = $metalLines \\times $ligandLines = \\mathbf{$totalLines\\text{ lines}}\$
- **Kramers Degeneracy**: For odd electron systems (\$S = 1/2\$), time-reversal symmetry ensures twofold Kramers degeneracy in zero field, guaranteeing an observable EPR signal.
''';

    return EprCalculationResult(
      frequencyGhz: frequencyGhz,
      magneticFieldGauss: magneticFieldGauss,
      gFactor: double.parse(gVal.toStringAsFixed(4)),
      totalHyperfineLines: totalLines,
      intensityRatio: totalLines == 4 ? ['1', '1', '1', '1'] : ['1', '2', '3', '2', '1'],
      isKramersDegenerate: isKramers,
      spinSystem: 'S = 1/2',
      interpretation: 'Deviations from g_e (2.0023) arise from spin-orbit mixing of the ground state with excited crystal field states.',
      derivationKaTeX: katex,
    );
  }

  // --- 4. Mössbauer Spectroscopy Engine ---
  static MossbauerResult diagnoseMossbauerFe({
    required double isomerShift, // delta in mm/s (relative to alpha-Fe at 298K)
    required double quadrupoleSplitting, // Delta E_Q in mm/s
    double temperatureK = 298.0,
  }) {
    String oxidation = '';
    String spin = '';
    String config = '';
    String explanation = '';

    if (isomerShift >= 1.0) {
      oxidation = 'Fe(II) [Fe²⁺]';
      spin = 'High Spin (S = 2)';
      config = 't_{2g}^4 e_g^2';
      explanation = 'Large positive isomer shift (1.2-1.4 mm/s) arises from 4 d-electrons shielding the 3s electrons, reducing s-electron density at the nucleus. The large quadrupole splitting (2.0-3.2 mm/s) is caused by the asymmetric non-spherical extra electron in the t₂g shell (q_valence >> 0).';
    } else if (isomerShift >= 0.5 && isomerShift < 1.0) {
      oxidation = 'Fe(III) [Fe³⁺]';
      spin = 'High Spin (S = 5/2)';
      config = 't_{2g}^3 e_g^2';
      explanation = 'Moderate isomer shift (0.6-0.8 mm/s). Because the d⁵ shell is spherically symmetric (half-filled t₂g³ e_g²), the valence electric field gradient is zero (q_valence = 0). The small quadrupole splitting (0.0-0.5 mm/s) is purely due to lattice asymmetry.';
    } else if (isomerShift >= 0.2 && isomerShift < 0.5) {
      oxidation = 'Fe(III) [Fe³⁺]';
      spin = 'Low Spin (S = 1/2)';
      config = 't_{2g}^5 e_g^0';
      explanation = 'Low isomer shift (0.2-0.4 mm/s). The asymmetric hole in the t₂g shell (t₂g⁵) creates a substantial valence electric field gradient, giving significant quadrupole splitting (1.5-2.5 mm/s).';
    } else {
      oxidation = 'Fe(II) [Fe²⁺] or Nitroprusside';
      spin = 'Low Spin (S = 0)';
      config = 't_{2g}^6 e_g^0';
      explanation = 'Very low isomer shift (0.0-0.2 mm/s or negative) due to strong metal-to-ligand π-backbonding into empty π* orbitals (e.g. CN⁻ or NO⁺), which removes d-electron density and unshields 3s electrons, dramatically increasing s-electron density at the nucleus.';
    }

    final katex = '''
### 10-Mark Academic Deduction: ⁵⁷Fe Mössbauer Spectral Diagnosis

#### Step 1: Physical Principles of Isomer Shift (\$\\delta\$)
The isomer shift reflects the difference in \$s\$-electron density between source and absorber:
\$\$\\delta = \\frac{2\\pi}{5} Z e^2 \\left[ R_{\\text{exc}}^2 - R_{\\text{gr}}^2 \\right] \\left\\{ |\\psi_s(0)|_{\\text{absorber}}^2 - |\\psi_s(0)|_{\\text{source}}^2 \\right\\}\$\$
- For \$^{57}\\text{Fe}\$, the nuclear radius factor is negative: \$\\Delta R / R < 0\$.
- Consequently, **greater \$s\$-electron density at the nucleus results in a more negative (lower) isomer shift \$\\delta\$**.
- Observed Isomer Shift: \$\\mathbf{\\delta = ${isomerShift.toStringAsFixed(2)}\\text{ mm/s}}\$.

#### Step 2: Physical Principles of Quadrupole Splitting (\$\\Delta E_Q\$)
Quadrupole splitting arises from the interaction of the nuclear quadrupole moment (\$Q\$ for \$I = 3/2\$) with the Electric Field Gradient (\$q\$):
\$\$\\Delta E_Q = \\frac{1}{2} e^2 q Q \\sqrt{1 + \\frac{\\eta^2}{3}}\$\$
Where the total field gradient \$q = q_{\\text{valence}} (1 - R) + q_{\\text{lattice}} (1 - \\gamma_\\infty)\$.
- Observed Quadrupole Splitting: \$\\mathbf{\\Delta E_Q = ${quadrupoleSplitting.toStringAsFixed(2)}\\text{ mm/s}}\$.

#### Step 3: Unambiguous Assignment of Oxidation & Spin State
- **Assigned Oxidation State**: \$\\mathbf{$oxidation}\$
- **Spin Multiplicity**: \$\\mathbf{$spin}\$
- **Electronic Configuration**: \$\$\\mathbf{$config}\$\$

#### Step 4: Examination Model Justification
$explanation
''';

    return MossbauerResult(
      nucleus: '57Fe',
      isomerShift: isomerShift,
      quadrupoleSplitting: quadrupoleSplitting,
      oxidationState: oxidation,
      spinState: spin,
      coordination: 'Octahedral (Oh)',
      electronicConfiguration: config,
      explanation: explanation,
      derivationKaTeX: katex,
    );
  }

  // --- 5. Metal Carbonyl IR Stretching Modes ---
  static CarbonylIrResult predictCarbonylIrModes({
    required String complexType, // 'M(CO)6', 'M(CO)5L', 'cis-M(CO)4L2', 'trans-M(CO)4L2', 'fac-M(CO)3L3', 'mer-M(CO)3L3'
  }) {
    String ptGroup = '';
    int totalCo = 6;
    int irCount = 1;
    int ramanCount = 2;
    List<String> irSyms = [];
    List<String> ramanSyms = [];
    String analysis = '';

    switch (complexType) {
      case 'M(CO)6':
        ptGroup = 'O_h';
        totalCo = 6;
        irCount = 1;
        ramanCount = 2;
        irSyms = ['T_{1u} (Very Strong)'];
        ramanSyms = ['A_{1g} (Polarized)', 'E_g (Depolarized)'];
        analysis = 'Octahedral M(CO)₆ exhibits rule of mutual exclusion: vibrations active in IR (T₁ᵤ) are inactive in Raman, and vice versa. Only 1 sharp ν(CO) band appears in IR around 2000 cm⁻¹.';
        break;
      case 'M(CO)5L':
        ptGroup = 'C_{4v}';
        totalCo = 5;
        irCount = 3;
        ramanCount = 4;
        irSyms = ['2A_1', 'E'];
        ramanSyms = ['2A_1', 'B_1', 'E'];
        analysis = 'Substitution of 1 CO breaks Oh symmetry down to C₄ᵥ. The reducible representation Γ_CO = 2A₁ + B₁ + E yields exactly 3 IR-active ν(CO) stretching bands.';
        break;
      case 'trans-M(CO)4L2':
        ptGroup = 'D_{4h}';
        totalCo = 4;
        irCount = 1;
        ramanCount = 2;
        irSyms = ['E_u (Strong)'];
        ramanSyms = ['A_{1g}', 'B_{1g}'];
        analysis = 'trans-Isomer possesses a center of inversion (i) in D₄ₕ symmetry. By mutual exclusion, only 1 IR-active band (Eᵤ) appears. This unequivocally distinguishes it from the cis isomer!';
        break;
      case 'cis-M(CO)4L2':
        ptGroup = 'C_{2v}';
        totalCo = 4;
        irCount = 4;
        ramanCount = 4;
        irSyms = ['2A_1', 'B_1', 'B_2'];
        ramanSyms = ['2A_1', 'B_1', 'B_2'];
        analysis = 'cis-Isomer lacks inversion symmetry (C₂ᵥ). All 4 fundamental ν(CO) modes are IR active (2A₁ + B₁ + B₂), giving 4 distinct absorption bands in the FT-IR spectrum.';
        break;
      case 'fac-M(CO)3L3':
        ptGroup = 'C_{3v}';
        totalCo = 3;
        irCount = 2;
        ramanCount = 2;
        irSyms = ['A_1 (Sharp)', 'E (Broad, Strong)'];
        ramanSyms = ['A_1', 'E'];
        analysis = 'Facial isomer has C₃ᵥ threefold axis. Γ_CO = A₁ + E, producing exactly 2 IR bands (one sharp A₁ symmetric stretch, one intense degenerate E mode).';
        break;
      case 'mer-M(CO)3L3':
        ptGroup = 'C_{2v}';
        totalCo = 3;
        irCount = 3;
        ramanCount = 3;
        irSyms = ['2A_1', 'B_1'];
        ramanSyms = ['2A_1', 'B_1'];
        analysis = 'Meridional isomer has lower C₂ᵥ symmetry. Γ_CO = 2A₁ + B₁, producing 3 IR active bands. This provides a direct spectroscopic method to differentiate fac vs mer isomers.';
        break;
      default:
        ptGroup = 'O_h';
        totalCo = 6;
        irCount = 1;
        ramanCount = 2;
        irSyms = ['T_{1u}'];
        ramanSyms = ['A_{1g}', 'E_g'];
        analysis = 'Standard octahedral metal hexacarbonyl.';
    }

    final katex = '''
### 10-Mark Academic Derivation: Group Theory & Carbonyl IR Selection Rules ($complexType)

#### Step 1: Determination of Point Group Symmetry
- Complex geometry: **$complexType**
- Point Group: \$\\mathbf{$ptGroup}\$
- Number of coordinate CO ligands: \$\\mathbf{$totalCo}\$

#### Step 2: Reducible Representation of C-O Stretches (\$\\Gamma_{\\text{CO}}\$)
By setting up basis vectors along each C-O bond axis and applying symmetry operations of \$\$ptGroup\$, reduction via the Great Orthogonality Theorem yields:
- **IR-Active Symmetries**: \$\\mathbf{${irSyms.join(', ')}}\$ (\$\$irCount\$ active bands)
- **Raman-Active Symmetries**: \$\\mathbf{${ramanSyms.join(', ')}}\$ (\$\$ramanCount\$ active bands)

#### Step 3: Spectroscopic Distinction & Inversion Center Principle
$analysis

#### Step 4: Synergic \$\\pi\$-Backbonding & Frequency Shifts
- In free CO, \$\\nu(\\text{CO}) = 2143\\text{ cm}^{-1}\$.
- Formation of the coordinate \$\\sigma\$-bond (\$M \\leftarrow CO\$) and subsequent \$\\pi\$-backdonation (\$M(d_\\pi) \\to CO(\\pi^*)\$) populates C-O antibonding orbitals.
- Consequently, **greater electron density on the central metal decreases the C-O bond order and lowers the stretching frequency**:
  \$\$\\nu(\\text{CO}) [\\text{Mn(CO)}_6]^+ (2090\\text{ cm}^{-1}) > \\text{Cr(CO)}_6 (2000\\text{ cm}^{-1}) > [\\text{V(CO)}_6]^- (1860\\text{ cm}^{-1})\$\$
''';

    return CarbonylIrResult(
      formula: complexType,
      pointGroup: ptGroup,
      totalCoLigands: totalCo,
      irActiveBands: irCount,
      ramanActiveBands: ramanCount,
      irSymmetries: irSyms,
      ramanSymmetries: ramanSyms,
      backbondingAnalysis: analysis,
      derivationKaTeX: katex,
    );
  }

  // --- 6. Curated 10-Mark Postgraduate Exam Solved Problems Database ---
  static const List<Inorganic10MarkExamProblem> curated10MarkProblems = [
    Inorganic10MarkExamProblem(
      id: 'inorg-10m-01',
      title: 'Electronic Spectra & Racah Parameters of [Ni(H₂O)₆]²⁺',
      topic: 'Electronic Spectra & Tanabe-Sugano',
      universityExam: 'Delhi University / CSIR-NET Dec',
      problemStatement:
          'The electronic spectrum of [Ni(H₂O)₆]²⁺ exhibits three spin-allowed bands at 8,500 cm⁻¹, 13,800 cm⁻¹, and 25,300 cm⁻¹. '
          '(a) Assign the transitions with appropriate term symbols. (b) Calculate 10Dq, Racah parameter B, and the nephelauxetic ratio β (B₀ = 1030 cm⁻¹). '
          '(c) Discuss the physical origin of the nephelauxetic effect.',
      rubricMarkDistribution: {
        'Term Symbol Deductions & Assignments': 2,
        'Calculation of 10Dq & ν2/ν1 Ratio': 2,
        'Racah Parameter B Derivation': 3,
        'β & Nephelauxetic Interpretation': 3,
      },
      fullKaTeXSolution: r'''
### Model 10/10 Examination Solution

#### (a) Assignment of Transitions with Term Symbols [2 Marks]
For \$Ni^{2+}\$ (\$d^8\$), the ground free-ion term is \$^3F\$ with excited \$^3P\$ at \$15B\$ above.
In octahedral symmetry (\$O_h\$), the term splitting produces three spin-allowed quartet transitions:
1. \$\\nu_1: ^3A_{2g} \\to ^3T_{2g} = 8,500\\text{ cm}^{-1}\$
2. \$\\nu_2: ^3A_{2g} \\to ^3T_{1g}(F) = 13,800\\text{ cm}^{-1}\$
3. \$\\nu_3: ^3A_{2g} \\to ^3T_{1g}(P) = 25,300\\text{ cm}^{-1}\$

#### (b) Calculation of 10Dq, Racah B, and \$\\beta\$ [5 Marks]
- **Crystal Field Splitting**:
  \$\$10Dq = \\nu_1 = 8,500\\text{ cm}^{-1}\$\$
- **Band Ratio**:
  \$\$\\frac{\\nu_2}{\\nu_1} = \\frac{13,800}{8,500} = 1.62\\quad (\\text{Within ideal range } 1.5 - 1.8)\$\$
- **Racah Parameter \$B\$**:
  From the secular equation determinant:
  \$\$\\nu_2 + \\nu_3 - 3\\nu_1 = 15B\$\$
  \$\$B = \\frac{13,800 + 25,300 - 3(8,500)}{15} = \\frac{39,100 - 25,500}{15} = \\frac{13,600}{15} = \\mathbf{906.67\\text{ cm}^{-1}}\$\$
- **Nephelauxetic Ratio (\$\\beta\$)**:
  \$\$\\beta = \\frac{B_{\\text{complex}}}{B_0} = \\frac{906.67}{1030} = \\mathbf{0.8803}\$\$
  \$\$\\text{Nephelauxetic parameter: } (1 - \\beta) \\times 100\\% = \\mathbf{11.97\\%}\$\$

#### (c) Physical Origin of the Nephelauxetic Effect [3 Marks]
1. **Central Field Covalency**: Overlap of ligand donor orbitals with metal \$3d\$ orbitals expands the metal electron cloud, lowering effective nuclear charge \$Z_{\\text{eff}}\$.
2. **Symmetry-Restricted Covalency**: Delocalization of metal electrons into ligand orbitals reduces interelectronic repulsion between \$d\$-electrons.
3. This \$\\sim 12\\%\$ reduction confirms moderate covalent character in the \$Ni-OH_2\$ coordination bond.
''',
      takeawayPoints: 'Always remember: 10Dq = ν1 directly for d8 and d3 octahedral complexes. 15B = ν2 + ν3 - 3ν1.',
    ),
    Inorganic10MarkExamProblem(
      id: 'inorg-10m-02',
      title: 'Spin-Orbit Coupling & Magnetic Moment of [Cr(H₂O)₆]³⁺ and [Ni(H₂O)₆]²⁺',
      topic: 'Magnetochemistry & Spin-Orbit Coupling',
      universityExam: 'Mumbai University / GATE Chemistry',
      problemStatement:
          'Calculate the spin-only magnetic moment for [Cr(H₂O)₆]³⁺ and [Ni(H₂O)₆]²⁺. '
          'Given that spin-orbit coupling constant λ is +92 cm⁻¹ for Cr³⁺ and -315 cm⁻¹ for Ni²⁺ (10Dq = 17,400 cm⁻¹ for Cr³⁺ and 8,500 cm⁻¹ for Ni²⁺), '
          'derive the corrected effective magnetic moment μ_eff and account for why μ_eff > μ_s.o. for Ni²⁺ but μ_eff < μ_s.o. for Cr³⁺.',
      rubricMarkDistribution: {
        'Spin-only Moments Calculation': 2,
        'Application of Griffith-Kotani Formula': 3,
        'Numerical Evaluation for Cr(III) and Ni(II)': 3,
        'Origin of Sign Reversal in λ': 2,
      },
      fullKaTeXSolution: r'''
### Model 10/10 Examination Solution

#### Step 1: Spin-Only Magnetic Moments [2 Marks]
- For \$[Cr(H_2O)_6]^{3+}\$ (\$d^3\$, \$t_{2g}^3\$): \$n = 3\$ unpaired electrons.
  \$\$\\mu_{\\text{s.o.}} = \\sqrt{3(3 + 2)} = \\sqrt{15} = \\mathbf{3.873\\text{ B.M.}}\$\$
- For \$[Ni(H_2O)_6]^{2+}\$ (\$d^8\$, \$t_{2g}^6 e_g^2\$): \$n = 2\$ unpaired electrons.
  \$\$\\mu_{\\text{s.o.}} = \\sqrt{2(2 + 2)} = \\sqrt{8} = \\mathbf{2.828\\text{ B.M.}}\$\$

#### Step 2: Griffith-Kotani Equation for A₂ Ground States [3 Marks]
Both complexes possess an \$A_{2g}\$ ground term (\$d^3 \\to ^4A_{2g}\$, \$d^8 \\to ^3A_{2g}\$).
Because \$A\$ terms have no first-order orbital angular momentum (\$L=0\$), second-order spin-orbit mixing with excited \$T_2\$ states modifies the moment:
\$\$\\mu_{\\text{eff}} = \\mu_{\\text{s.o.}} \\left(1 - \\frac{4\\lambda}{10Dq}\\right)\$\$

#### Step 3: Numerical Substitution [3 Marks]
- **For \$[Cr(H_2O)_6]^{3+}\$** (\$\\lambda = +92\\text{ cm}^{-1}, 10Dq = 17,400\\text{ cm}^{-1}\$):
  \$\$\\mu_{\\text{eff}} = 3.873 \\times \\left(1 - \\frac{4 \\times 92}{17,400}\\right) = 3.873 \\times (1 - 0.02115) = \\mathbf{3.791\\text{ B.M.}}\$\$
- **For \$[Ni(H_2O)_6]^{2+}\$** (\$\\lambda = -315\\text{ cm}^{-1}, 10Dq = 8,500\\text{ cm}^{-1}\$):
  \$\$\\mu_{\\text{eff}} = 2.828 \\times \\left(1 - \\frac{4 \\times (-315)}{8,500}\\right) = 2.828 \\times (1 + 0.1482) = \\mathbf{3.247\\text{ B.M.}}\$\$

#### Step 4: Explanation of Sign Reversal in \$\\lambda\$ [2 Marks]
- For electron shells that are **less than half-full** (\$d^3 < d^5\$), \$\\lambda\$ is **positive**, causing \$\\mu_{\\text{eff}} < \\mu_{\\text{s.o.}}\$.
- For electron shells that are **more than half-full** (\$d^8 > d^5\$), holes replace electrons and \$\\lambda\$ is **negative**, causing \$\\mu_{\\text{eff}} > \\mu_{\\text{s.o.}}\$.
''',
      takeawayPoints: 'λ is positive for d1-d4, negative for d6-d9. A2 ground state complexes use alpha = 4.',
    ),
    Inorganic10MarkExamProblem(
      id: 'inorg-10m-03',
      title: 'EPR Spectrum of [Cu(salen)] with ⁶³Cu and ¹⁴N Hyperfine Couplings',
      topic: 'EPR / ESR Spectroscopy',
      universityExam: 'Karnataka State MSc / CSIR-NET June',
      problemStatement:
          'A square-planar copper(II) complex [Cu(salen)] is analyzed by X-band EPR at 9.45 GHz. '
          '(a) Calculate the resonance magnetic field if g = 2.08. '
          '(b) Copper has two isotopes ⁶³Cu and ⁶⁵Cu both with nuclear spin I = 3/2. How many lines appear due to copper hyperfine coupling? '
          '(c) If the copper is coordinated to two nitrogen atoms (¹⁴N, I = 1), calculate the total number of superhyperfine lines.',
      rubricMarkDistribution: {
        'Resonance Field Calculation': 2,
        'Copper Hyperfine Multiplicity': 3,
        'Nitrogen Superhyperfine Multiplicity': 3,
        'Line Intensity Distribution': 2,
      },
      fullKaTeXSolution: r'''
### Model 10/10 Examination Solution

#### (a) Calculation of Resonance Magnetic Field [2 Marks]
From the resonance equation \$h\\nu = g\\beta_e B\$:
\$\$B = \\frac{714.484 \\times \\nu (\\text{GHz})}{g} = \\frac{714.484 \\times 9.45}{2.08} = \\frac{6751.87}{2.08} = \\mathbf{3246.09\\text{ Gauss (0.3246 Tesla)}}\$\$

#### (b) Copper Hyperfine Multiplicity [3 Marks]
Copper(II) is a \$3d^9\$ system with one unpaired electron (\$S = 1/2\$).
For a single nucleus with spin \$I\$, the number of lines is:
\$\$N_{\\text{Cu}} = 2I + 1 = 2(3/2) + 1 = \\mathbf{4\\text{ lines}}\$\$
The 4 hyperfine lines have equal intensity ratio **1 : 1 : 1 : 1**.

#### (c) Nitrogen Superhyperfine Multiplicity [3 Marks]
The complex contains two equivalent nitrogen atoms (\$^{14}\\text{N}\$, \$I_N = 1\$).
The number of superhyperfine lines is:
\$\$N_{\\text{SHF}} = 2 n I_N + 1 = 2(2)(1) + 1 = \\mathbf{5\\text{ lines}}\$\$
The intensity distribution for \$n=2\$ with \$I=1\$ is given by:
\$\$\\mathbf{1 : 2 : 3 : 2 : 1}\$\$

#### (d) Total Number of Observable Lines [2 Marks]
Each of the 4 primary copper lines is split into 5 sub-lines:
\$\$N_{\\text{total}} = N_{\\text{Cu}} \\times N_{\\text{N}} = 4 \\times 5 = \\mathbf{20\\text{ lines}}\$\$
''',
      takeawayPoints: 'Total lines = (2*n1*I1 + 1) * (2*n2*I2 + 1). Cu(II) has S = 1/2 and I = 3/2.',
    ),
    Inorganic10MarkExamProblem(
      id: 'inorg-10m-04',
      title: 'Distinguishing Cis and Trans Isomers of Mo(CO)₄(PPh₃)₂ via FT-IR Group Theory',
      topic: 'Metal Carbonyls & Group Theory',
      universityExam: 'IISc Bangalore / Pune University',
      problemStatement:
          'Explain how Infrared (IR) and Raman spectroscopy can unequivocally distinguish between cis- and trans-isomers of Mo(CO)₄(PPh₃)₂. '
          'Derive the number of IR- and Raman-active ν(CO) stretching vibrations for both isomers using group theoretical principles.',
      rubricMarkDistribution: {
        'Point Group Assignment': 2,
        'Cis-isomer Irreducible Representations': 3,
        'Trans-isomer Irreducible Representations': 3,
        'Mutual Exclusion Principle Application': 2,
      },
      fullKaTeXSolution: r'''
### Model 10/10 Examination Solution

#### 1. Point Group Symmetries [2 Marks]
- **trans-Mo(CO)₄(PPh₃)₂**: Belongs to the \$\\mathbf{D_{4h}}\$ point group (possesses a center of inversion \$i\$).
- **cis-Mo(CO)₄(PPh₃)₂**: Belongs to the \$\\mathbf{C_{2v}}\$ point group (no center of inversion).

#### 2. trans-Isomer (\$D_{4h}\$) Analysis [3 Marks]
Using the four C-O stretching vectors as basis:
\$\$\\Gamma_{\\text{CO}} = A_{1g} + B_{1g} + E_u\$\$
- In \$D_{4h}\$, dipole moment transforms as \$A_{2u} (z)\$ and \$E_u (x, y)\$.
  \$\$\\implies \\mathbf{1\\text{ IR-Active Band: } E_u\\text{ (Very Strong)}}\$\$
- Polarizability transforms as \$A_{1g}, B_{1g}, B_{2g}, E_g\$.
  \$\$\\implies \\mathbf{2\\text{ Raman-Active Bands: } A_{1g} + B_{1g}}\$\$

#### 3. cis-Isomer (\$C_{2v}\$) Analysis [3 Marks]
Using the four C-O stretching vectors as basis:
\$\$\\Gamma_{\\text{CO}} = 2A_1 + B_1 + B_2\$\$
- In \$C_{2v}\$, dipole moment transforms as \$A_1 (z), B_1 (x), B_2 (y)\$.
  \$\$\\implies \\text{All 4 modes are IR-active: } \\mathbf{2A_1 + B_1 + B_2\\text{ (4 Bands)}}\$\$
- All 4 modes are also Raman active in \$C_{2v}\$.

#### 4. Spectroscopic Conclusion [2 Marks]
- **Rule of Mutual Exclusion**: Holds strictly for the trans-isomer (\$D_{4h}\$ contains \$i\$). The single IR band (\$E_u\$) is Raman inactive.
- **Diagnostic Decision**: An FT-IR spectrum showing **1 strong band** confirms the **trans-isomer**, while **4 bands** confirms the **cis-isomer**.
''',
      takeawayPoints: 'trans-M(CO)4L2 has D4h symmetry and 1 IR band. cis-M(CO)4L2 has C2v symmetry and 4 IR bands.',
    ),
    Inorganic10MarkExamProblem(
      id: 'inorg-10m-05',
      title: 'Mössbauer Spectroscopy of Potassium Ferrocyanide vs Potassium Ferricyanide',
      topic: '⁵⁷Fe Mössbauer Spectroscopy',
      universityExam: 'University of Hyderabad / CSIR-NET',
      problemStatement:
          'Compare the ⁵⁷Fe Mössbauer spectra of K₄[Fe(CN)₆] and K₃[Fe(CN)₆] at room temperature. '
          'Account for the differences in their isomer shifts (δ) and explain why K₃[Fe(CN)₆] exhibits quadrupole splitting (ΔEQ) while K₄[Fe(CN)₆] gives only a single sharp singlet.',
      rubricMarkDistribution: {
        'Electronic Configurations & Spin States': 2,
        'Isomer Shift (δ) Comparison & Backbonding': 3,
        'Quadrupole Splitting (ΔEQ) & EFG Analysis': 3,
        'Summary Spectral Signatures': 2,
      },
      fullKaTeXSolution: r'''
### Model 10/10 Examination Solution

#### 1. Oxidation & Spin States [2 Marks]
- **\$K_4[Fe(CN)_6]\$**: \$Fe(II)\$, \$d^6\$ low-spin (\$t_{2g}^6 e_g^0, S = 0\$). Diamagnetic.
- **\$K_3[Fe(CN)_6]\$**: \$Fe(III)\$, \$d^5\$ low-spin (\$t_{2g}^5 e_g^0, S = 1/2\$). Paramagnetic.

#### 2. Isomer Shift (\$\\delta\$) Comparison [3 Marks]
- \$\\delta\$ measures \$s\$-electron density at the \$^{57}\\text{Fe}\$ nucleus. For \$^{57}\\text{Fe}\$, \$\\Delta R/R < 0\$.
- \$Fe(II)\$ has one more \$d\$-electron than \$Fe(III)\$. Normally, extra \$d\$-electrons shield \$3s\$, lowering \$s\$-density and increasing \$\\delta\$.
- However, with strong \$\\pi\$-acceptor \$CN^-\$ ligands, **metal-to-ligand \$\\pi\$-backdonation** (\$Fe(d) \\to CN(\\pi^*)\$) is greater in \$Fe(II)\$ due to higher electron density.
- Consequently, \$\\delta\$ for both complexes is very low:
  \$\$\\delta [Fe(II)] \\approx -0.04\\text{ mm/s},\\quad \\delta [Fe(III)] \\approx -0.12\\text{ mm/s}\$\$

#### 3. Quadrupole Splitting (\$\\Delta E_Q\$) Explanation [3 Marks]
Quadrupole splitting requires a non-zero Electric Field Gradient (\$q \\ne 0\$):
\$\$q = q_{\\text{valence}} + q_{\\text{lattice}}\$\$
- In **\$K_4[Fe(CN)_6]\$**: The \$t_{2g}^6\$ subshell is completely filled and spherically symmetric.
  \$\$\\implies q_{\\text{valence}} = 0\$\$
  The regular octahedral environment means \$q_{\\text{lattice}} \\approx 0\$.
  Hence, \$\\Delta E_Q = 0\\implies\$ **Single sharp resonance line (singlet)**.
- In **\$K_3[Fe(CN)_6]\$**: The \$t_{2g}^5\$ subshell has an asymmetric hole (electron deficiency in one of \$d_{xy}, d_{yz}, d_{xz}\$).
  \$\$\\implies q_{\\text{valence}} \\ne 0\$\$
  This substantial valence EFG splits the \$I = 3/2\$ excited state into \$M_I = \\pm 3/2\$ and \$\\pm 1/2\$, giving **\$\\Delta E_Q \\approx 0.70\\text{ mm/s}\$ (Doublet)**.
''',
      takeawayPoints: 't2g6 (Fe2+ LS) is spherically symmetric -> singlet (no quadrupole splitting). t2g5 (Fe3+ LS) has an asymmetric hole -> doublet.',
    ),
  ];
}
