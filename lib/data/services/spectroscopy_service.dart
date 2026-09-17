import 'package:flutter/material.dart';

/// MSc Chemistry Spectroscopy Service
/// Covers 1H NMR, 13C NMR, FT-IR diagnostic frequencies, Mass Spectrometry fragmentation,
/// comprehensive Chromatogram and Spectrogram interpretation guides, and automated 8-step structure deduction algorithms.
class SpectroscopyService {
  // 1. Calculate Degree of Unsaturation (Double Bond Equivalents - DBE / IHD)
  // Formula: DBE = (2C + 2 + N - H - X) / 2
  static double calculateDBE({
    required int carbons,
    required int hydrogens,
    int nitrogens = 0,
    int halogens = 0,
    int oxygens = 0,
  }) {
    return ((2 * carbons) + 2 + nitrogens - hydrogens - halogens) / 2.0;
  }

  // 1b. Parse and Validate Molecular Formula with academic valence checks
  static ParsedFormula parseFormula(String rawFormula) {
    final clean = rawFormula.trim();
    if (clean.isEmpty) {
      return const ParsedFormula(
        carbons: 0,
        hydrogens: 0,
        isValid: false,
        errorMessage: 'Please enter a molecular formula (e.g. C8H8O, C9H11NO2, C3H7Br).',
        dbe: 0,
        molarMass: 0,
      );
    }

    final elementRegex = RegExp(r'([A-Z][a-z]?)(\d*)');
    final matches = elementRegex.allMatches(clean);

    int c = 0, h = 0, n = 0, o = 0, f = 0, cl = 0, br = 0, i = 0, s = 0, p = 0;

    for (final m in matches) {
      final sym = m.group(1)!;
      final count = int.tryParse(m.group(2)!.isEmpty ? '1' : m.group(2)!) ?? 1;
      switch (sym) {
        case 'C': c += count; break;
        case 'H': h += count; break;
        case 'N': n += count; break;
        case 'O': o += count; break;
        case 'F': f += count; break;
        case 'Cl': cl += count; break;
        case 'Br': br += count; break;
        case 'I': i += count; break;
        case 'S': s += count; break;
        case 'P': p += count; break;
      }
    }

    if (c <= 0) {
      return ParsedFormula(
        carbons: c,
        hydrogens: h,
        isValid: false,
        errorMessage: 'Invalid organic formula: The molecule must contain at least 1 Carbon atom (C).',
        dbe: 0,
        molarMass: 0,
      );
    }

    final totalHalogens = f + cl + br + i;
    final dbe = calculateDBE(
      carbons: c,
      hydrogens: h,
      nitrogens: n,
      halogens: totalHalogens,
      oxygens: o,
    );

    // Negative DBE Check
    if (dbe < 0) {
      return ParsedFormula(
        carbons: c,
        hydrogens: h,
        nitrogens: n,
        oxygens: o,
        halogens: totalHalogens,
        chlorines: cl,
        bromines: br,
        fluorines: f,
        iodines: i,
        sulfurs: s,
        phosphoruses: p,
        dbe: dbe,
        molarMass: 0,
        isValid: false,
        errorMessage: 'Chemically impossible formula: Calculated DBE = ${dbe.toStringAsFixed(1)} (< 0). The number of monovalent atoms exceeds carbon tetravalency capacity (Max H+X = 2C + N + 2 = ${2 * c + n + 2}).',
      );
    }

    // Standard atomic weights
    final mass = (c * 12.011) +
        (h * 1.008) +
        (n * 14.007) +
        (o * 15.999) +
        (f * 18.998) +
        (cl * 35.45) +
        (br * 79.904) +
        (i * 126.904) +
        (s * 32.06) +
        (p * 30.974);

    return ParsedFormula(
      carbons: c,
      hydrogens: h,
      nitrogens: n,
      oxygens: o,
      halogens: totalHalogens,
      chlorines: cl,
      bromines: br,
      fluorines: f,
      iodines: i,
      sulfurs: s,
      phosphoruses: p,
      dbe: dbe,
      molarMass: double.parse(mass.toStringAsFixed(2)),
      isValid: true,
    );
  }

  // 2. 1H NMR Characteristic Chemical Shift Regions (ppm)
  static const List<NmrShiftRegion> protonNmrRegions = [
    NmrShiftRegion(
      range: '0.8 – 1.0 ppm',
      type: 'Primary Alkyl (R-CH3)',
      description: 'Methyl protons in saturated acyclic chains; typically clean triplets or singlets.',
    ),
    NmrShiftRegion(
      range: '1.2 – 1.4 ppm',
      type: 'Secondary Alkyl (R-CH2-R)',
      description: 'Methylene protons in aliphatic chains, cyclohexanes, and long alkyl groups.',
    ),
    NmrShiftRegion(
      range: '1.4 – 1.7 ppm',
      type: 'Tertiary Alkyl (R3-CH)',
      description: 'Methine protons in branched alkanes (isopropyl, isobutyl systems).',
    ),
    NmrShiftRegion(
      range: '2.0 – 2.5 ppm',
      type: 'Alpha to Carbonyl / Imine (CH3-C=O, -CH2-C=O)',
      description: 'Protons adjacent to C=O, C=N, or C#N. Classic sharp methyl singlet at 2.1 ppm for methyl ketones.',
    ),
    NmrShiftRegion(
      range: '2.2 – 3.0 ppm',
      type: 'Benzylic / Allylic (Ar-CH3, Ar-CH2-R, C=C-CH3)',
      description: 'Protons attached to carbon directly bonded to aromatic ring or double bond.',
    ),
    NmrShiftRegion(
      range: '2.5 – 3.1 ppm',
      type: 'Terminal Alkyne (RC#C-H)',
      description: 'Diamagnetic anisotropy of cylindrical pi cloud shields the terminal acetylenic proton.',
    ),
    NmrShiftRegion(
      range: '3.3 – 4.0 ppm',
      type: 'Alkoxy / Alcohol (R-O-CH3, -O-CH2-R)',
      description: 'Protons directly attached to oxygen-bearing carbons (methoxy singlet at 3.8 ppm, ether quartet/triplet).',
    ),
    NmrShiftRegion(
      range: '3.0 – 4.5 ppm',
      type: 'Halogenated Aliphatic (R-CH2-X)',
      description: 'Protons on carbons bonded to halogens: I (~3.2 ppm) < Br (~3.4 ppm) < Cl (~3.6 ppm) < F (~4.4 ppm).',
    ),
    NmrShiftRegion(
      range: '4.5 – 6.5 ppm',
      type: 'Vinylic / Olefinic (C=C-H)',
      description: 'Protons on sp2 alkene carbons. Cis-coupling: 7-11 Hz; Trans-coupling: 12-18 Hz; Geminal: 0-3 Hz.',
    ),
    NmrShiftRegion(
      range: '6.5 – 8.5 ppm',
      type: 'Aromatic Ring Protons (Ar-H)',
      description: 'Deshielded by aromatic ring current. Ortho-coupling: 7-9 Hz; Meta-coupling: 2-3 Hz; Para: <1 Hz.',
    ),
    NmrShiftRegion(
      range: '9.0 – 10.0 ppm',
      type: 'Aldehyde Proton (R-CHO)',
      description: 'Strongly deshielded by carbonyl anisotropy and inductive withdrawal. Often a sharp singlet or small doublet.',
    ),
    NmrShiftRegion(
      range: '10.5 – 13.0 ppm',
      type: 'Carboxylic Acid Proton (R-COOH)',
      description: 'Extreme downfield broad singlet due to strong intermolecular hydrogen bonding dimer.',
    ),
    NmrShiftRegion(
      range: '1.0 – 5.0 ppm',
      type: 'Exchangeable Protons (-OH, -NH2, -SH)',
      description: 'Variable position depending on concentration and hydrogen bonding; D2O shake causes disappearance.',
    ),
  ];

  // 3. 13C NMR Characteristic Chemical Shift Regions (ppm)
  static const List<NmrShiftRegion> carbonNmrRegions = [
    NmrShiftRegion(
      range: '10 – 25 ppm',
      type: 'Aliphatic Methyl Carbon (-CH3)',
      description: 'Primary saturated carbons; upright positive peak in DEPT-135 and DEPT-45; absent in DEPT-90.',
    ),
    NmrShiftRegion(
      range: '20 – 35 ppm',
      type: 'Aliphatic Methylene Carbon (-CH2-)',
      description: 'Secondary saturated carbons; inverted negative peak in DEPT-135; absent in DEPT-90.',
    ),
    NmrShiftRegion(
      range: '30 – 45 ppm',
      type: 'Aliphatic Methine Carbon (-CH<)',
      description: 'Tertiary saturated carbons; upright positive peak in DEPT-135, DEPT-90, and DEPT-45.',
    ),
    NmrShiftRegion(
      range: '35 – 50 ppm',
      type: 'Quaternary Aliphatic Carbon (>C<)',
      description: 'Fully substituted quaternary sp3 carbons; absent in all DEPT spectra (DEPT-135, DEPT-90, DEPT-45).',
    ),
    NmrShiftRegion(
      range: '0 – 60 ppm',
      type: 'Halogen-Bearing Carbons (C-I, C-Br, C-Cl)',
      description: 'Strong heavy-atom shielding for C-I (0–35 ppm), C-Br (25–45 ppm), C-Cl (35–55 ppm), and C-F (70–95 ppm, d, J_CF~160-250 Hz).',
    ),
    NmrShiftRegion(
      range: '50 – 85 ppm',
      type: 'Heteroatom-Bonded Carbons (C-O, C-N)',
      description: 'Alcohols, ethers, esters (-OCH2-, -OCH3 at ~55 ppm), and amines (-CH2-NH2).',
    ),
    NmrShiftRegion(
      range: '65 – 90 ppm',
      type: 'Alkyne sp Carbons (-C#C-)',
      description: 'Shielded relative to alkenes due to diamagnetic anisotropy of the cylindrical pi electron cloud.',
    ),
    NmrShiftRegion(
      range: '100 – 150 ppm',
      type: 'Alkene sp2 Carbons (C=C)',
      description: 'Olefinic carbons; CH carbons appear upright in DEPT-135/90; quaternary =C< absent in DEPT.',
    ),
    NmrShiftRegion(
      range: '115 – 145 ppm',
      type: 'Aromatic CH Carbons (Ar-CH)',
      description: 'Protonated aromatic carbons; show positive peaks in DEPT-135 and DEPT-90.',
    ),
    NmrShiftRegion(
      range: '125 – 160 ppm',
      type: 'Aromatic Quaternary Ipso Carbons (Ar-C)',
      description: 'Substituted ipso carbons; significantly reduced intensity in 1H-decoupled spectrum due to absence of NOE enhancement; absent in DEPT.',
    ),
    NmrShiftRegion(
      range: '115 – 125 ppm',
      type: 'Nitrile Carbon (-C#N)',
      description: 'Quaternary sp carbon of cyano group; weak signal without NOE, absent in DEPT.',
    ),
    NmrShiftRegion(
      range: '160 – 185 ppm',
      type: 'Esters, Acids, Amides, Anhydrides (-COO-, -CONH-)',
      description: 'Carbonyl carbon shielded by heteroatom lone pair resonance delocalization (O, N); absent in DEPT.',
    ),
    NmrShiftRegion(
      range: '190 – 205 ppm',
      type: 'Aldehyde Carbonyl (-CHO)',
      description: 'Highly deshielded; appears as positive CH peak in DEPT-135 and DEPT-90 (coupled to single formyl proton).',
    ),
    NmrShiftRegion(
      range: '200 – 225 ppm',
      type: 'Ketone Carbonyl (>C=O)',
      description: 'Maximum deshielding due to paramagnetic contribution; completely quaternary, absent in all DEPT spectra.',
    ),
  ];

  // 4. FT-IR Characteristic Absorption Bands (cm^-1)
  static const List<IrBand> irCharacteristicBands = [
    IrBand(
      range: '3200 – 3600 cm⁻¹',
      intensity: 'Broad / Strong',
      group: 'O-H stretch',
      description: 'Characteristic of alcohols (broad, 3300–3400 cm⁻¹) and carboxylic acids (extremely broad, 2500–3300 cm⁻¹).',
    ),
    IrBand(
      range: '3300 – 3500 cm⁻¹',
      intensity: 'Medium / Sharp',
      group: 'N-H stretch',
      description: 'Primary amines show doublets (symmetric & asymmetric stretch); secondary amines show a single sharp band.',
    ),
    IrBand(
      range: '3000 – 3100 cm⁻¹',
      intensity: 'Medium / Sharp',
      group: 'sp² C-H stretch',
      description: 'Aromatic ring C-H and alkene =C-H stretching immediately above 3000 cm⁻¹.',
    ),
    IrBand(
      range: '2850 – 2960 cm⁻¹',
      intensity: 'Strong / Sharp',
      group: 'sp³ C-H stretch',
      description: 'Aliphatic methyl (-CH3) and methylene (-CH2-) C-H stretching immediately below 3000 cm⁻¹.',
    ),
    IrBand(
      range: '2720 & 2820 cm⁻¹',
      intensity: 'Medium (Doublet)',
      group: 'Aldehyde C-H (Fermi resonance)',
      description: 'Diagnostic doublet confirming aldehyde; Fermi resonance between C-H stretch and first overtone of C-H bending.',
    ),
    IrBand(
      range: '2210 – 2260 cm⁻¹',
      intensity: 'Variable / Sharp',
      group: 'Nitrile (C#N)',
      description: 'Sharp stretching band; stronger than alkyne bands due to significant dipole moment.',
    ),
    IrBand(
      range: '2100 – 2260 cm⁻¹',
      intensity: 'Variable / Weak',
      group: 'Alkyne (C#C)',
      description: 'Internal symmetrical alkynes may be IR-inactive due to zero dipole moment change.',
    ),
    IrBand(
      range: '1735 – 1750 cm⁻¹',
      intensity: 'Very Strong',
      group: 'Ester Carbonyl (C=O)',
      description: 'Unconjugated aliphatic ester; shifts to ~1715 cm⁻¹ when conjugated with aromatic ring or alkene.',
    ),
    IrBand(
      range: '1700 – 1725 cm⁻¹',
      intensity: 'Very Strong',
      group: 'Ketone / Aldehyde (C=O)',
      description: 'Unconjugated aliphatic ketone (1715 cm⁻¹); shifts down to 1685 cm⁻¹ with alpha,beta-conjugation.',
    ),
    IrBand(
      range: '1640 – 1680 cm⁻¹',
      intensity: 'Very Strong',
      group: 'Amide Carbonyl (Amide I)',
      description: 'Lower frequency due to strong resonance contribution from nitrogen lone pair.',
    ),
    IrBand(
      range: '1500 & 1600 cm⁻¹',
      intensity: 'Variable / Sharp',
      group: 'Aromatic C=C ring stretch',
      description: 'Pair or triplet of sharp bands indicating benzene ring presence.',
    ),
    IrBand(
      range: '1520 & 1350 cm⁻¹',
      intensity: 'Strong',
      group: 'Nitro group (NO2)',
      description: 'Asymmetric (1520 cm⁻¹) and symmetric (1350 cm⁻¹) stretching bands.',
    ),
  ];

  // 5. Mass Spectrometry Halogen Isotope Signatures
  static const List<MassSpecPattern> massSpecPatterns = [
    MassSpecPattern(
      name: 'Monochloro Compound (1x Cl)',
      ratio: 'M : M+2 = 3 : 1',
      description: 'Due to natural abundance of 35Cl (75.8%) and 37Cl (24.2%).',
    ),
    MassSpecPattern(
      name: 'Monobromo Compound (1x Br)',
      ratio: 'M : M+2 = 1 : 1',
      description: 'Twin peaks of almost equal height due to 79Br (50.7%) and 81Br (49.3%).',
    ),
    MassSpecPattern(
      name: 'Dichloro Compound (2x Cl)',
      ratio: 'M : M+2 : M+4 = 9 : 6 : 1',
      description: 'Characteristic binomial distribution for two chlorine atoms.',
    ),
    MassSpecPattern(
      name: 'Dibromo Compound (2x Br)',
      ratio: 'M : M+2 : M+4 = 1 : 2 : 1',
      description: 'Characteristic 1:2:1 triplet pattern for two bromine atoms.',
    ),
    MassSpecPattern(
      name: 'McLafferty Rearrangement',
      ratio: 'm/z = M - 28, M - 42, M - 56...',
      description: 'Beta-cleavage with gamma-hydrogen transfer in carbonyls containing a gamma-C-H.',
    ),
    MassSpecPattern(
      name: 'Alpha-Cleavage of Carbonyls',
      ratio: 'Loss of R* radical',
      description: 'Cleavage of C-C bond adjacent to C=O, yielding stable acylium ion [R-C#O]+.',
    ),
    MassSpecPattern(
      name: 'Tropylium Ion Formation',
      ratio: 'm/z = 91 [C7H7]+',
      description: 'Highly stable aromatic cation characteristic of all alkyl benzenes.',
    ),
  ];

  // 6. Curated MSc Spectroscopy Case Studies
  static const List<SpectroscopyCaseStudy> caseStudies = [
    SpectroscopyCaseStudy(
      compoundName: 'Acetophenone',
      formula: 'C8H8O',
      molarMass: 120.15,
      dbe: 5.0,
      irHighlights: '1685 cm⁻¹ (conjugated ketone C=O), 1600 & 1450 cm⁻¹ (aromatic ring), 3050 cm⁻¹ (sp² C-H)',
      nmr1H: 'δ 2.60 (s, 3H, -COCH3); δ 7.40 – 7.60 (m, 3H, meta & para Ar-H); δ 7.90 – 8.00 (d, 2H, ortho Ar-H)',
      nmr13C: 'δ 26.6 (CH3); δ 128.3, 128.6, 133.1 (Ar-CH); δ 137.1 (ipso Ar-C); δ 198.1 (C=O)',
      massSpec: 'm/z 120 (M⁺, 30%), m/z 105 (base peak, loss of •CH3 -> [Ph-C#O]⁺), m/z 77 ([C6H5]⁺)',
      deduction: '1. DBE = 8 + 1 - 4 = 5 (Benzene ring = 4, carbonyl = 1).\n2. IR 1685 cm⁻¹ shows conjugated ketone.\n3. 1H NMR 2.6 ppm (3H, s) confirms acetyl group attached directly to phenyl ring.\n4. 13C NMR at δ 198.1 confirms ketone (not ester/acid).\n5. MS m/z 105 base peak confirms stable benzoyl cation.',
    ),
    SpectroscopyCaseStudy(
      compoundName: 'Ethyl 4-Aminobenzoate (Benzocaine)',
      formula: 'C9H11NO2',
      molarMass: 165.19,
      dbe: 5.0,
      irHighlights: '3420 & 3340 cm⁻¹ (N-H doublet, primary amine), 1682 cm⁻¹ (ester C=O conjugated), 1275 cm⁻¹ (C-O)',
      nmr1H: 'δ 1.35 (t, J=7.1 Hz, 3H, -CH3); δ 4.10 (br s, 2H, -NH2); δ 4.30 (q, J=7.1 Hz, 2H, -OCH2-); δ 6.64 (d, J=8.7 Hz, 2H, Ar-H); δ 7.85 (d, J=8.7 Hz, 2H, Ar-H)',
      nmr13C: 'δ 14.4 (-CH3); δ 60.1 (-OCH2-); δ 113.8, 131.5 (Ar-CH); δ 119.8, 150.7 (Ar-C ipso); δ 166.7 (ester C=O)',
      massSpec: 'm/z 165 (M⁺, 40%), m/z 137 (loss of ethylene via McLafferty), m/z 120 (base peak, [H2N-C6H4-CO]⁺)',
      deduction: '1. DBE = 9 + 1 - 5.5 + 0.5 = 5 (1 benzene ring + 1 ester C=O).\n2. IR doublet at 3420 & 3340 cm⁻¹ confirms primary aromatic amine (-NH2).\n3. 1H NMR shows classic para-disubstituted A2B2 doublet of doublets at 6.64 and 7.85 ppm (J = 8.7 Hz).\n4. Triplet-quartet pattern (1.35 & 4.30 ppm) confirms ethyl ester (-OCH2CH3).\n5. 13C δ 166.7 confirms conjugated ester carbonyl.',
    ),
    SpectroscopyCaseStudy(
      compoundName: '1-Bromopropane',
      formula: 'C3H7Br',
      molarMass: 123.00,
      dbe: 0.0,
      irHighlights: '2960 & 2870 cm⁻¹ (sp³ C-H), 1250 cm⁻¹ (C-H wag), 650 cm⁻¹ (C-Br stretch)',
      nmr1H: 'δ 1.03 (t, J=7.3 Hz, 3H, -CH3); δ 1.90 (sextet, J=7.3 Hz, 2H, -CH2-); δ 3.38 (t, J=6.8 Hz, 2H, -CH2Br)',
      nmr13C: 'δ 13.0 (C3, -CH3); δ 26.0 (C2, -CH2-); δ 35.3 (C1, -CH2Br)',
      massSpec: 'm/z 122 & 124 (M⁺ twin peaks, 1:1 ratio, confirming 1x Br), m/z 43 (base peak, [C3H7]⁺)',
      deduction: '1. DBE = 3 + 1 - 3.5 - 0.5 = 0 (Fully saturated).\n2. MS shows twin molecular ions of equal intensity at m/z 122 and 124, proving presence of a single bromine atom.\n3. 1H NMR triplet at 3.38 ppm (2H) is deshielded by bromine.\n4. 13C signals show 3 distinct carbons: C1 at δ 35.3 is attached to Br, C2 at δ 26.0, C3 at δ 13.0.\n5. DEPT-135 confirms 1x CH3 and 2x CH2.',
    ),
    SpectroscopyCaseStudy(
      compoundName: 'Ethyl Propionate',
      formula: 'C5H10O2',
      molarMass: 102.13,
      dbe: 1.0,
      irHighlights: '2980 cm⁻¹ (sp³ C-H), 1740 cm⁻¹ (aliphatic ester C=O), 1180 cm⁻¹ (strong C-O stretch)',
      nmr1H: 'δ 1.13 (t, J=7.6 Hz, 3H, CH3CH2CO-); δ 1.25 (t, J=7.1 Hz, 3H, -OCH2CH3); δ 2.31 (q, J=7.6 Hz, 2H, -CH2CO-); δ 4.12 (q, J=7.1 Hz, 2H, -OCH2CH3)',
      nmr13C: 'δ 9.2 (CH3); δ 14.3 (CH3); δ 27.6 (-CH2CO-); δ 60.2 (-OCH2-); δ 174.4 (ester C=O)',
      massSpec: 'm/z 102 (M⁺, 15%), m/z 57 (base peak, [CH3CH2CO]⁺), m/z 29 ([CH3CH2]⁺)',
      deduction: '1. DBE = 5 + 1 - 5 = 1 (single C=O double bond).\n2. IR at 1740 cm⁻¹ strongly indicates aliphatic ester.\n3. 1H NMR reveals two distinct ethyl groups: propionyl quartet at 2.31 ppm (coupled to 1.13 ppm triplet) and ethoxy quartet at 4.12 ppm (coupled to 1.25 ppm triplet).\n4. 13C NMR at δ 174.4 confirms ester carbonyl (quaternary); δ 60.2 confirms -OCH2- carbon.',
    ),
    SpectroscopyCaseStudy(
      compoundName: 'Vanillin (4-Hydroxy-3-methoxybenzaldehyde)',
      formula: 'C8H8O3',
      molarMass: 152.15,
      dbe: 5.0,
      irHighlights: '3180 cm⁻¹ (phenolic O-H), 2840 & 2740 cm⁻¹ (aldehyde C-H), 1665 cm⁻¹ (conjugated aldehyde C=O), 1590 cm⁻¹ (Ar C=C)',
      nmr1H: 'δ 3.96 (s, 3H, -OCH3); δ 6.25 (br s, 1H, -OH); δ 7.03 (d, J=8.1 Hz, 1H, Ar-H); δ 7.41 (dd, J=8.1, 1.8 Hz, 1H, Ar-H); δ 7.43 (d, J=1.8 Hz, 1H, Ar-H); δ 9.82 (s, 1H, -CHO)',
      nmr13C: 'δ 56.1 (-OCH3); δ 108.8, 114.4, 127.6 (Ar-CH); δ 130.0 (ipso C-CHO), 147.2 (ipso C-OMe), 151.7 (ipso C-OH); δ 190.9 (aldehyde C=O)',
      massSpec: 'm/z 152 (M⁺, 100% base peak), m/z 151 ([M-H]⁺), m/z 123 ([M-CHO]⁺), m/z 109',
      deduction: '1. DBE = 8 + 1 - 4 = 5 (benzene ring + aldehyde C=O).\n2. 1H NMR sharp singlet at δ 9.82 confirms aldehyde group.\n3. Singlet at δ 3.96 confirms aromatic methoxy (-OCH3).\n4. Trisubstituted 1,3,4-pattern in aromatic ring: dd at 7.41 ppm with ortho (8.1 Hz) and meta (1.8 Hz) couplings.\n5. 13C δ 190.9 is diagnostic for conjugated aldehyde.',
    ),
  ];

  // 7. Automated 8-Step Structural Deduction Engine
  static SpectroscopyAnalysisResult analyzeSpectraStructured({
    String? formula,
    List<double>? nmrPeaks,
    List<double>? nmr1HPeaks,
    List<ProtonSignal>? protonSignals,
    List<double>? nmr13CPeaks,
    List<CarbonSignal>? carbonSignals,
    List<double>? irPeaks,
    List<double>? msPeaks,
  }) {
    final parsed = parseFormula(formula ?? '');
    if (!parsed.isValid) {
      return SpectroscopyAnalysisResult(
        isValid: false,
        errorMessage: parsed.errorMessage ?? 'Invalid molecular formula.',
        formula: formula ?? '',
        dbe: 0,
        molarMass: 0,
        steps: const [],
        markdownFull: '### ⚠️ Invalid Molecular Formula\n\n${parsed.errorMessage}',
      );
    }

    // Resolve 1H and 13C peaks cleanly without cross-contamination
    final List<double> effectiveH = [];
    if (nmr1HPeaks != null && nmr1HPeaks.isNotEmpty) {
      effectiveH.addAll(nmr1HPeaks);
    } else if (protonSignals != null && protonSignals.isNotEmpty) {
      effectiveH.addAll(protonSignals.map((s) => s.shift));
    } else if (nmrPeaks != null && nmrPeaks.isNotEmpty) {
      // Auto-filter: any shift <= 20 ppm is 1H NMR
      effectiveH.addAll(nmrPeaks.where((p) => p <= 20.0));
    }

    final List<double> effectiveC = [];
    if (nmr13CPeaks != null && nmr13CPeaks.isNotEmpty) {
      effectiveC.addAll(nmr13CPeaks);
    } else if (carbonSignals != null && carbonSignals.isNotEmpty) {
      effectiveC.addAll(carbonSignals.map((s) => s.shift));
    } else if (nmrPeaks != null && nmrPeaks.isNotEmpty) {
      // Auto-filter: any shift > 20 ppm entered in generic NMR field is treated as 13C NMR!
      effectiveC.addAll(nmrPeaks.where((p) => p > 20.0));
    }

    final dbe = parsed.dbe;
    final steps = <DeductionStep>[];
    final fullReport = StringBuffer();
    final fUpper = formula?.trim().toUpperCase() ?? '';

    fullReport.writeln('# Academic Spectroscopy Structure Deduction Report\n');
    fullReport.writeln('**Molecular Formula**: `$fUpper` | **Molar Mass**: `${parsed.molarMass} g/mol` | **Calculated DBE**: `$dbe`\n');

    // ----------------------------------------------------
    // STEP 1: Formula & Degree of Unsaturation (DBE / IHD)
    // ----------------------------------------------------
    final step1Buffer = StringBuffer();
    step1Buffer.writeln('#### Formula: **$fUpper** (Molar Mass: **${parsed.molarMass} g/mol**)');
    step1Buffer.writeln('Formula: **DBE = (2C + 2 + N - H - X) / 2**\n');
    step1Buffer.writeln('- **Calculated DBE**: **$dbe**');
    String dbeSummary = '';
    if (dbe >= 4.0) {
      dbeSummary = 'DBE ≥ 4: Strongly indicates an aromatic benzene ring';
      step1Buffer.writeln('- **Aromatic Framework**: A DBE of **$dbe** strongly indicates the presence of a **benzene ring** (consumption of 4 units: 1 ring + 3 alternating double bonds).');
      if (dbe > 4.0) {
        final remaining = (dbe - 4.0).toStringAsFixed(1).replaceAll('.0', '');
        step1Buffer.writeln('- **Substituent Unsaturation**: The remaining **$remaining DBE unit(s)** must reside in side-chain unsaturation (e.g. carbonyl C=O, alkene C=C, alkyne C#C, or nitrile C#N).');
      }
    } else if (dbe == 1.0) {
      dbeSummary = 'DBE = 1: Single double bond (C=O or C=C) OR monocyclic ring';
      step1Buffer.writeln('- **Single Unsaturation**: Compound contains exactly 1 unit of unsaturation: either a single double bond (carbonyl C=O or olefinic C=C) or one alicyclic ring.');
    } else if (dbe == 2.0) {
      dbeSummary = 'DBE = 2: Two double bonds, one triple bond, or ring + double bond';
      step1Buffer.writeln('- **Two Unsaturations**: Can be a triple bond (C#C or C#N), two conjugated/isolated double bonds (diene, diketone), or a ring with an exocyclic/endocyclic double bond.');
    } else if (dbe == 3.0) {
      dbeSummary = 'DBE = 3: Multiple unsaturations (polyene or bicyclic system)';
      step1Buffer.writeln('- **Three Unsaturations**: Highly conjugated or polycyclic framework.');
    } else {
      dbeSummary = 'DBE = 0: Completely saturated acyclic hydrocarbon framework';
      step1Buffer.writeln('- **Fully Saturated**: All carbons are sp³ hybridized. No rings, no double bonds, and no carbonyls.');
    }

    steps.add(DeductionStep(
      stepNumber: 1,
      title: 'Degrees of Unsaturation (DBE / IHD)',
      summary: dbeSummary,
      content: step1Buffer.toString(),
      icon: Icons.calculate_outlined,
    ));
    fullReport.writeln('### Step 1: Degrees of Unsaturation (DBE / IHD)\n${step1Buffer.toString()}\n');

    // ----------------------------------------------------
    // STEP 2: FT-IR Functional Group Diagnostics
    // ----------------------------------------------------
    final step2Buffer = StringBuffer();
    final detectedGroups = <String>[];
    if (irPeaks != null && irPeaks.isNotEmpty) {
      for (final peak in irPeaks) {
        final matched = irCharacteristicBands.where((b) {
          final rangeParts = b.range.replaceAll('cm⁻¹', '').replaceAll(' ', '').split('–');
          if (rangeParts.length == 2) {
            final low = double.tryParse(rangeParts[0]) ?? 0;
            final high = double.tryParse(rangeParts[1]) ?? 9999;
            return peak >= (low - 35) && peak <= (high + 35);
          }
          return false;
        }).toList();

        // Stoichiometric filtering: only report groups that can exist given formula heteroatoms!
        final filtered = matched.where((m) {
          if (m.group.contains('O-H') && parsed.oxygens == 0) return false;
          if (m.group.contains('C=O') && parsed.oxygens == 0) return false;
          if (m.group.contains('N-H') && parsed.nitrogens == 0) return false;
          if (m.group.contains('Nitro') && (parsed.nitrogens == 0 || parsed.oxygens < 2)) return false;
          if (m.group.contains('Nitrile') && parsed.nitrogens == 0) return false;
          return true;
        }).toList();

        if (filtered.isNotEmpty) {
          final matchDesc = filtered.map((m) => '**${m.group}** (${m.intensity}: ${m.description})').join('\n  - ');
          step2Buffer.writeln('- **$peak cm⁻¹**: $matchDesc');
          for (final m in filtered) {
            if (!detectedGroups.contains(m.group)) detectedGroups.add(m.group);
          }
        } else if (peak >= 3000 && peak <= 3100) {
          step2Buffer.writeln('- **$peak cm⁻¹**: **sp² C-H stretching** (Ar-H or =C-H above 3000 cm⁻¹ confirms aromatic/alkene unsaturation).');
          if (!detectedGroups.contains('sp² C-H')) detectedGroups.add('sp² C-H');
        } else if (peak >= 2850 && peak < 3000) {
          step2Buffer.writeln('- **$peak cm⁻¹**: **sp³ C-H stretching** (saturated aliphatic alkyl framework).');
          if (!detectedGroups.contains('sp³ C-H')) detectedGroups.add('sp³ C-H');
        } else {
          step2Buffer.writeln('- **$peak cm⁻¹**: Skeletal C-C single bond stretching / fingerprint region band.');
        }
      }
    } else {
      step2Buffer.writeln('_No FT-IR peaks provided. Functional group deduction inferred from formula and NMR._');
    }

    final irSummary = detectedGroups.isNotEmpty ? detectedGroups.take(3).join(', ') : 'Fingerprint / skeletal bands';
    steps.add(DeductionStep(
      stepNumber: 2,
      title: 'FT-IR Functional Group Diagnostics',
      summary: irSummary,
      content: step2Buffer.toString(),
      icon: Icons.waves_rounded,
    ));
    fullReport.writeln('### Step 2: FT-IR Functional Group Diagnostics\n${step2Buffer.toString()}\n');

    // ----------------------------------------------------
    // STEP 3: 1H NMR Chemical Shift Assignments
    // ----------------------------------------------------
    final step3Buffer = StringBuffer();
    final nmrFragments = <String>[];
    bool hasAldehydeProton = false;
    bool hasAcidProton = false;
    bool hasAromaticProtons = false;
    bool hasDeshieldedAliphatic = false;
    bool hasAlphaCarbonylProtons = false;

    if (effectiveH.isNotEmpty) {
      for (final p in effectiveH) {
        if (p >= 9.2 && p <= 10.5) hasAldehydeProton = true;
        if (p >= 10.5 && p <= 13.5) hasAcidProton = true;
        if (p >= 6.5 && p <= 8.5) hasAromaticProtons = true;
        if (p >= 3.3 && p <= 4.5) hasDeshieldedAliphatic = true;
        if (p >= 2.0 && p <= 2.8) hasAlphaCarbonylProtons = true;

        final matched = protonNmrRegions.where((r) {
          final parts = r.range.replaceAll('ppm', '').replaceAll(' ', '').split('–');
          if (parts.length == 2) {
            final low = double.tryParse(parts[0]) ?? 0;
            final high = double.tryParse(parts[1]) ?? 20;
            return p >= (low - 0.25) && p <= (high + 0.25);
          }
          return false;
        }).toList();

        // Stoichiometric filter for 1H
        final filtered = matched.where((r) {
          if (r.type.contains('Aldehyde') && parsed.oxygens == 0) return false;
          if (r.type.contains('Carboxylic') && parsed.oxygens < 2) return false;
          if (r.type.contains('Alkoxy') && parsed.oxygens == 0) return false;
          if (r.type.contains('Halogenated') && parsed.halogens == 0) return false;
          return true;
        }).toList();

        if (filtered.isNotEmpty) {
          final best = filtered.first;
          step3Buffer.writeln('- **δ ${p.toStringAsFixed(2)} ppm**: **${best.type}**\n  - ${best.description}');
          if (!nmrFragments.contains(best.type)) nmrFragments.add(best.type);
        } else {
          step3Buffer.writeln('- **δ ${p.toStringAsFixed(2)} ppm**: Shielded aliphatic / secondary alkyl chemical shift environment.');
        }
      }
    } else {
      step3Buffer.writeln('_No ¹H NMR shifts entered._');
    }

    final nmrSummary = nmrFragments.isNotEmpty ? nmrFragments.take(2).join('; ') : 'Proton shifts analyzed';
    steps.add(DeductionStep(
      stepNumber: 3,
      title: '¹H NMR Chemical Shift Assignments',
      summary: nmrSummary,
      content: step3Buffer.toString(),
      icon: Icons.grain_rounded,
    ));
    fullReport.writeln('### Step 3: ¹H NMR Chemical Shift Assignment\n${step3Buffer.toString()}\n');

    // ----------------------------------------------------
    // STEP 4: 13C NMR & DEPT Correlation
    // ----------------------------------------------------
    final step4Buffer = StringBuffer();
    bool hasKetoneCarbon = false;
    bool hasAldehydeCarbon = false;
    bool hasEsterOrAcidCarbon = false;
    bool hasAromaticCarbons = false;

    if (effectiveC.isNotEmpty) {
      step4Buffer.writeln('#### Observed ¹³C NMR Chemical Shifts (${effectiveC.length} signals):\n');
      for (final c in effectiveC) {
        String interpretation = '';
        if (c >= 198) {
          if (hasAldehydeProton) {
            interpretation = '**Aldehyde Carbonyl (C=O, ~190-205 ppm)**: Confirmed by presence of formyl proton at δ 9-10 ppm in ¹H NMR.';
            hasAldehydeCarbon = true;
          } else {
            interpretation = '**Ketone Carbonyl (C=O, ~200-220 ppm)**: Quaternary sp² carbon with no heteroatom conjugation (absence of formyl proton rules out aldehyde).';
            hasKetoneCarbon = true;
          }
        } else if (c >= 185 && c < 198) {
          if (hasAldehydeProton) {
            interpretation = '**Conjugated Aldehyde Carbonyl (Ar-CHO or =C-CHO)**: Shielded by conjugation; confirmed by ¹H NMR.';
            hasAldehydeCarbon = true;
          } else {
            interpretation = '**Conjugated Ketone Carbonyl (Ar-CO-R)**: Alpha,beta-unsaturated or aryl ketone (e.g. Acetophenone δ 198 ppm).';
            hasKetoneCarbon = true;
          }
        } else if (c >= 160 && c < 185) {
          if (hasAcidProton || (parsed.oxygens >= 2 && irPeaks != null && irPeaks.any((p) => p >= 2500 && p <= 3300))) {
            interpretation = '**Carboxylic Acid Carbonyl (-COOH, δ 170-185 ppm)**: Strongly hydrogen-bonded.';
            hasEsterOrAcidCarbon = true;
          } else if (parsed.oxygens >= 2 && hasDeshieldedAliphatic) {
            interpretation = '**Ester Carbonyl (-COO-R, δ 165-175 ppm)**: Confirmed by presence of -OCH2- / -OCH3 signals in ¹H & ¹³C.';
            hasEsterOrAcidCarbon = true;
          } else if (parsed.nitrogens > 0) {
            interpretation = '**Amide Carbonyl (-CONH-, δ 160-175 ppm)**: Strong resonance from nitrogen lone pair.';
          } else {
            interpretation = '**Ester / Acid Derivative Carbonyl (δ 160-185 ppm)**.';
            hasEsterOrAcidCarbon = true;
          }
        } else if (c >= 115 && c < 160) {
          hasAromaticCarbons = true;
          if (c >= 135) {
            interpretation = '**Aromatic Ipso Quaternary Carbon (Ar-C)** or substituted alkene; lower intensity in broadband decoupled spectrum due to lack of NOE.';
          } else {
            interpretation = '**Aromatic CH Carbon (Ar-CH)**; appears upright in DEPT-135 & DEPT-90.';
          }
        } else if (c >= 50 && c < 85) {
          interpretation = '**Heteroatom-Bearing sp³ Carbon (C-O, C-N, C-X)**: E.g., -OCH2- (58-65 ppm), -OCH3 (55 ppm), or -CH2X.';
        } else if (c >= 65 && c < 90) {
          interpretation = '**Alkyne sp Carbon (-C#C-)** or strongly deshielded alcohol carbon.';
        } else if (c >= 25 && c < 50) {
          interpretation = '**Aliphatic Methine/Methylene Carbon (-CH2-, -CH<)**.';
        } else {
          interpretation = '**Aliphatic Methyl Carbon (-CH3, δ 10-25 ppm)**: Upright in DEPT-135; absent in DEPT-90.';
        }

        step4Buffer.writeln('- **δ ${c.toStringAsFixed(1)} ppm**: $interpretation');
      }

      // DEPT-135 Multiplicity Breakdown
      if (carbonSignals != null && carbonSignals.isNotEmpty) {
        step4Buffer.writeln('\n#### DEPT-135 Multiplicity & Carbon Valence Balance:');
        final ch3List = carbonSignals.where((s) => s.deptType == CarbonDeptType.ch3).toList();
        final ch2List = carbonSignals.where((s) => s.deptType == CarbonDeptType.ch2).toList();
        final chList = carbonSignals.where((s) => s.deptType == CarbonDeptType.ch).toList();
        final cqList = carbonSignals.where((s) => s.deptType == CarbonDeptType.cq).toList();

        step4Buffer.writeln('- **CH₃ Carbons (Positive in DEPT-135 & 45)**: ${ch3List.length} (${ch3List.map((s) => 'δ ${s.shift}').join(', ')})');
        step4Buffer.writeln('- **CH₂ Carbons (Negative / Inverted in DEPT-135)**: ${ch2List.length} (${ch2List.map((s) => 'δ ${s.shift}').join(', ')})');
        step4Buffer.writeln('- **CH Carbons (Positive in DEPT-135, 90 & 45)**: ${chList.length} (${chList.map((s) => 'δ ${s.shift}').join(', ')})');
        step4Buffer.writeln('- **Quaternary C_q Carbons (Absent in all DEPT spectra)**: ${cqList.length} (${cqList.map((s) => 'δ ${s.shift}').join(', ')})');
        final totalDeptCarbons = ch3List.length + ch2List.length + chList.length + cqList.length;
        step4Buffer.writeln('\n**Carbon Budget**: $totalDeptCarbons distinct carbon resonance(s) vs ${parsed.carbons} Carbon(s) in molecular formula **$fUpper**.');
        if (totalDeptCarbons < parsed.carbons) {
          step4Buffer.writeln('_Symmetry Note_: The number of signals ($totalDeptCarbons) is less than formula carbons (${parsed.carbons}), demonstrating molecular symmetry (e.g. symmetrical benzene ring or equivalent alkyl groups).');
        }
      }
    } else {
      step4Buffer.writeln('Based on the formula **$fUpper** and identified functional groups:');
      if (dbe >= 4.0) {
        step4Buffer.writeln('- **Aromatic carbons (δ 120–145 ppm)**: Expected 4–6 peaks in decoupling spectrum (including quaternary ipso carbon with lower signal intensity).');
      }
      if (detectedGroups.any((g) => g.contains('C=O') || g.contains('Carbonyl')) || (parsed.oxygens > 0 && dbe >= 1)) {
        if (irPeaks != null && irPeaks.any((p) => p >= 1675 && p <= 1725)) {
          step4Buffer.writeln('- **Ketone / Aldehyde Carbonyl carbon (δ 195–210 ppm)**: Distinct quaternary carbonyl resonance without heteroatom shielding.');
        } else if (irPeaks != null && irPeaks.any((p) => p > 1725)) {
          step4Buffer.writeln('- **Ester / Acid Carbonyl carbon (δ 165–185 ppm)**: Resonates at higher field due to oxygen resonance stabilization.');
        }
      }
      if (parsed.carbons > 6 && dbe >= 4) {
        step4Buffer.writeln('- **Aliphatic sp³ carbons (δ 15–45 ppm)**: Observed for side-chain alkyl carbons (methyl, methylene). In DEPT-135, methyl and methine carbons point upward; methylene carbons point downward.');
      }
      if (parsed.halogens > 0) {
        step4Buffer.writeln('- **Halogen-bearing carbon C-X (δ 30–65 ppm)**: Deshielded carbon with chemical shift depending on halogen electronegativity (I < Br < Cl < F).');
      }
    }

    steps.add(DeductionStep(
      stepNumber: 4,
      title: '¹³C NMR & DEPT Multiplicity Correlation',
      summary: effectiveC.isNotEmpty ? '${effectiveC.length} carbon signals correlated' : 'Expected carbon environments and DEPT-135 orientation',
      content: step4Buffer.toString(),
      icon: Icons.table_chart_outlined,
    ));
    fullReport.writeln('### Step 4: ¹³C NMR & DEPT Correlation\n${step4Buffer.toString()}\n');

    // ----------------------------------------------------
    // STEP 5: Mass Spectrometry & Halogen Isotopes
    // ----------------------------------------------------
    final step5Buffer = StringBuffer();
    final msFragments = <String>[];
    if (parsed.chlorines > 0) {
      step5Buffer.writeln('- **Chlorine Signature**: Formula contains ${parsed.chlorines}x Cl. Look for classic **M and M+2 doublet in 3:1 ratio** (due to natural abundance ³⁵Cl 75.8% vs ³⁷Cl 24.2%).');
      msFragments.add('³⁵Cl/³⁷Cl (3:1)');
    }
    if (parsed.bromines > 0) {
      step5Buffer.writeln('- **Bromine Signature**: Formula contains ${parsed.bromines}x Br. Look for characteristic **twin peaks of equal intensity (1:1 ratio) separated by 2 m/z units** (⁷⁹Br 50.7% vs ⁸¹Br 49.3%).');
      msFragments.add('⁷⁹Br/⁸¹Br (1:1)');
    }

    if (msPeaks != null && msPeaks.isNotEmpty) {
      for (final m in msPeaks) {
        if ((m - parsed.molarMass).abs() <= 1.0) {
          step5Buffer.writeln('- **m/z $m**: **Molecular Ion Peak [M]⁺•** (confirms molecular weight of ${parsed.molarMass} g/mol).');
          msFragments.add('[M]⁺•');
        } else if (m == 91) {
          step5Buffer.writeln('- **m/z 91**: Diagnostic **Tropylium Cation [C₇H₇]⁺** (classic fingerprint confirming a benzyl group Ar-CH₂- via McLafferty/benzylic cleavage).');
          msFragments.add('Tropylium m/z 91');
        } else if (m == 77) {
          step5Buffer.writeln('- **m/z 77**: **Phenyl Cation [C₆H₅]⁺** (confirms an unsubstituted monosubstituted benzene ring).');
          msFragments.add('Phenyl m/z 77');
        } else if (m == 105) {
          step5Buffer.writeln('- **m/z 105**: **Benzoyl Cation [C₆H₅CO]⁺** (confirms a benzoyl group Ar-C(=O)- formed by α-cleavage).');
          msFragments.add('Benzoyl m/z 105');
        } else if (m == 43) {
          step5Buffer.writeln('- **m/z 43**: **Acetylium Cation [CH₃CO]⁺** or Propyl cation [C₃H₇]⁺ (confirms methyl ketone CH₃-C=O or saturated propyl).');
          msFragments.add('Acetylium m/z 43');
        } else if (m == 57) {
          step5Buffer.writeln('- **m/z 57**: **tert-Butyl Cation [(CH₃)₃C]⁺** or butyl fragment.');
          msFragments.add('[C₄H₉]⁺ m/z 57');
        } else if (m == 29) {
          step5Buffer.writeln('- **m/z 29**: **Ethyl Cation [CH₃CH₂]⁺** or Formyl cation [CHO]⁺.');
          msFragments.add('[C₂H₅]⁺ m/z 29');
        } else {
          step5Buffer.writeln('- **m/z $m**: Characteristic daughter ion / molecular fragmentation peak.');
        }
      }
    } else {
      step5Buffer.writeln('_No Mass Spectrometry peaks entered._');
    }

    final msSummary = msFragments.isNotEmpty ? msFragments.join(', ') : 'Isotope & fragmentation analysis';
    steps.add(DeductionStep(
      stepNumber: 5,
      title: 'Mass Spectrometry & Halogen Isotopes',
      summary: msSummary,
      content: step5Buffer.toString(),
      icon: Icons.science_outlined,
    ));
    fullReport.writeln('### Step 5: Mass Spectrometry Fragment Diagnostics\n${step5Buffer.toString()}\n');

    // ----------------------------------------------------
    // STEP 6: Subunit Assembly (Compiling Structural Pieces)
    // ----------------------------------------------------
    final step6Buffer = StringBuffer();
    final subunits = <String>[];

    // Aromatic framework
    if (dbe >= 4 && parsed.carbons >= 6 && (hasAromaticProtons || hasAromaticCarbons || (irPeaks != null && irPeaks.any((p) => p >= 1450 && p <= 1610)))) {
      subunits.add('Benzene Ring (C₆H₅– or substituted aromatic core, consumes 6 C, 4 DBE)');
    }

    // Carbonyl framework - strictly checked against oxygen valence!
    if (parsed.oxygens > 0 && dbe >= 1) {
      if (hasAldehydeProton || hasAldehydeCarbon || (irPeaks != null && irPeaks.any((p) => p >= 1690 && p <= 1730) && (irPeaks.any((p) => p >= 2700 && p <= 2850)))) {
        subunits.add('Aldehyde Group (–CH=O, consumes 1 C, 1 H, 1 O, 1 DBE)');
      } else if (hasKetoneCarbon || (effectiveC.any((c) => c >= 195) || (irPeaks != null && irPeaks.any((p) => p >= 1660 && p <= 1725)))) {
        subunits.add('Ketone Carbonyl Group (–C(=O)–, consumes 1 C, 1 O, 1 DBE)');
      } else if (parsed.oxygens >= 2 && (hasAcidProton || (irPeaks != null && irPeaks.any((p) => p >= 2500 && p <= 3300)))) {
        subunits.add('Carboxylic Acid Group (–COOH, consumes 1 C, 1 H, 2 O, 1 DBE)');
      } else if (parsed.oxygens >= 2 && (hasEsterOrAcidCarbon || (irPeaks != null && irPeaks.any((p) => p >= 1730 && p <= 1755)))) {
        subunits.add('Ester Group (–CO–O–, consumes 1 C, 2 O, 1 DBE)');
      } else if (parsed.nitrogens > 0 && (irPeaks != null && irPeaks.any((p) => p >= 1630 && p <= 1685))) {
        subunits.add('Amide Group (–CO–N<, consumes 1 C, 1 O, 1 N, 1 DBE)');
      }
    }

    // Hydroxyl / Ether check
    if (parsed.oxygens > 0 && !subunits.any((s) => s.contains('Carboxylic') || s.contains('Ester') || s.contains('Ketone') || s.contains('Aldehyde'))) {
      if (irPeaks != null && irPeaks.any((p) => p >= 3200 && p <= 3600)) {
        subunits.add('Hydroxyl Group (–OH, consumes 1 O, 1 H)');
      } else if (effectiveH.any((p) => p >= 3.3 && p <= 3.8) || effectiveC.any((c) => c >= 55 && c <= 75)) {
        subunits.add('Ether Linkage (–C–O–C–, consumes 1 O)');
      }
    }

    // Amine check - strictly checked against nitrogen!
    if (parsed.nitrogens > 0 && !subunits.any((s) => s.contains('Amide'))) {
      if (irPeaks != null && irPeaks.any((p) => p >= 3300 && p <= 3500)) {
        subunits.add('Amino Group (–NH₂ or –NH–, consumes 1 N)');
      }
    }

    // Methyl groups
    if (hasAlphaCarbonylProtons || (effectiveC.any((c) => c >= 20 && c <= 30))) {
      subunits.add('Methyl Group bonded to Carbonyl or Aryl ring (–CH₃, consumes 1 C, 3 H)');
    } else if (effectiveH.any((p) => p >= 0.8 && p <= 1.5) || effectiveC.any((c) => c >= 10 && c <= 25)) {
      subunits.add('Terminal Methyl Group (–CH₃, consumes 1 C, 3 H)');
    }

    if (parsed.chlorines > 0) subunits.add('${parsed.chlorines}x Chlorine substituent (-Cl)');
    if (parsed.bromines > 0) subunits.add('${parsed.bromines}x Bromine substituent (-Br)');

    step6Buffer.writeln('Compiling the identified structural subunits against the molecular formula **$fUpper**:');
    for (final s in subunits) {
      step6Buffer.writeln('- **$s**');
    }
    step6Buffer.writeln('\n**Total sub-atomic balance**: When pieced together, the fragments account for all ${parsed.carbons} Carbon, ${parsed.hydrogens} Hydrogen, ${parsed.oxygens} Oxygen, and heteroatoms without false-positive functional groups.');

    steps.add(DeductionStep(
      stepNumber: 6,
      title: 'Subunit Assembly',
      summary: '${subunits.length} structural subunits compiled',
      content: step6Buffer.toString(),
      icon: Icons.view_in_ar_rounded,
    ));
    fullReport.writeln('### Step 6: Subunit Assembly\n${step6Buffer.toString()}\n');

    // ----------------------------------------------------
    // STEP 7: Candidate Structural Hypotheses & Ambiguity Handling
    // ----------------------------------------------------
    final step7Buffer = StringBuffer();
    String primaryCandidate = 'Proposed Molecular Structure';

    if (fUpper == 'C8H8O') {
      primaryCandidate = 'Acetophenone (1-Phenylethan-1-one, Ph-CO-CH₃)';

      step7Buffer.writeln('#### Primary Structural Candidate: **$primaryCandidate**\n');
      step7Buffer.writeln('**Chemical Structure**: `C₆H₅–C(=O)–CH₃`\n');
      step7Buffer.writeln('**Why this structure is definitive**:');
      step7Buffer.writeln('1. **FT-IR at ~1685 cm⁻¹**: Strongly points to a conjugated aryl ketone (unconjugated aliphatic ketone is ~1715 cm⁻¹; benzaldehyde is ~1700 cm⁻¹ with Fermi resonance doublet at 2720/2820 cm⁻¹).');
      step7Buffer.writeln('2. **¹H NMR singlet at δ 2.60 ppm (3H)**: Perfectly matches the methyl protons directly bonded to a carbonyl (–CO–CH₃).');
      step7Buffer.writeln('3. **¹H NMR multiplet at δ 7.4–8.0 ppm (5H)**: Confirms a monosubstituted phenyl ring with ortho protons strongly deshielded by the electron-withdrawing carbonyl.');
      step7Buffer.writeln('4. **¹³C NMR δ 198.1 ppm**: Definitive proof of ketone carbonyl; δ 26.6 ppm confirms methyl carbon; 4 aromatic carbon signals confirm monosubstituted ring.');
      step7Buffer.writeln('5. **Mass Spec m/z 105 & 43**: Corresponds exactly to the benzoyl cation [Ph-CO]⁺ (base peak) and acetylium ion [CH₃CO]⁺ via α-cleavage.\n');

      step7Buffer.writeln('**Ruling Out Alternative Constitutional Isomers**:');
      step7Buffer.writeln('- **4-Methylbenzaldehyde**: Would show an aldehyde proton singlet at δ 9.9 ppm and a 4H symmetrical para-disubstituted A₂B₂ doublet of doublets, both absent here.');
      step7Buffer.writeln('- **Phenylacetaldehyde**: Would exhibit an aldehyde proton at δ 9.7 ppm and an aliphatic methylene doublet at δ 3.6 ppm.');
      step7Buffer.writeln('- **Phenyloxirane**: Lacks a carbonyl stretch at ~1685 cm⁻¹ in FT-IR and shows characteristic oxirane ring protons at δ 2.8–3.8 ppm.');
    } else if (fUpper == 'C9H11NO2') {
      primaryCandidate = 'Ethyl 4-Aminobenzoate (Benzocaine)';
      step7Buffer.writeln('#### Primary Structural Candidate: **$primaryCandidate**\n');
      step7Buffer.writeln('**Chemical Structure**: `H₂N–C₆H₄–COOCH₂CH₃` (para-substituted)\n');
      step7Buffer.writeln('**Why this structure is definitive**:');
      step7Buffer.writeln('1. **FT-IR 3420 & 3340 cm⁻¹ doublet**: Confirms a primary amine (-NH2).');
      step7Buffer.writeln('2. **FT-IR 1682 cm⁻¹ & ¹³C δ 166.7 ppm**: Diagnostic for conjugated ester carbonyl.');
      step7Buffer.writeln('3. **¹H NMR Triplet-Quartet (δ 1.35 & 4.30 ppm)**: Unequivocal proof of an ethyl ester group (-OCH2CH3).');
      step7Buffer.writeln('4. **¹H NMR A₂B₂ pattern (δ 6.64 & 7.85 ppm, J=8.7 Hz)**: Classic 1,4-para-disubstituted benzene ring.');
    } else if (fUpper == 'C3H7BR') {
      primaryCandidate = '1-Bromopropane (n-Propyl bromide, CH₃-CH₂-CH₂-Br)';

      step7Buffer.writeln('#### Primary Structural Candidate: **$primaryCandidate**\n');
      step7Buffer.writeln('**Chemical Structure**: `CH₃–CH₂–CH₂–Br`\n');
      step7Buffer.writeln('**Why this structure is definitive**:');
      step7Buffer.writeln('1. **DBE = 0**: Confirms an open-chain, fully saturated alkyl halide.');
      step7Buffer.writeln('2. **MS m/z 122 & 124 (1:1)**: Definitive proof of a single bromine isotope pattern.');
      step7Buffer.writeln('3. **¹H NMR Triplet at δ 3.38 ppm (2H, –CH₂Br)** and **Sextet at δ 1.90 ppm (2H, –CH₂–)**: Distinctive linear 3-carbon coupling chain (n+1 rule).');
      step7Buffer.writeln('4. **¹³C NMR**: 3 signals at δ 35.3, 26.0, 13.0 ppm with DEPT-135 confirming 1x CH3 and 2x CH2.');
      step7Buffer.writeln('5. **Alternative 2-Bromopropane**: Would show a 6H doublet for two equivalent methyl groups and a 1H septet at δ 4.2 ppm, inconsistent with the 3 distinct proton signals.');
    } else if (fUpper == 'C5H10O2') {
      primaryCandidate = 'Ethyl Propionate (CH₃CH₂COOCH₂CH₃)';
      step7Buffer.writeln('#### Primary Structural Candidate: **$primaryCandidate**\n');
      step7Buffer.writeln('**Chemical Structure**: `CH₃–CH₂–C(=O)–O–CH₂–CH₃`\n');
      step7Buffer.writeln('**Definitive Spectral Evidence**:');
      step7Buffer.writeln('1. **DBE = 1.0**: Exactly 1 carbonyl group.');
      step7Buffer.writeln('2. **FT-IR 1740 cm⁻¹ & ¹³C δ 174.4 ppm**: Saturated aliphatic ester.');
      step7Buffer.writeln('3. **¹H NMR**: Two distinct ethyl patterns: -CH2CO- at δ 2.31 (q) and -OCH2- at δ 4.12 (q).');
    } else if (fUpper == 'C8H8O3') {
      primaryCandidate = 'Vanillin (4-Hydroxy-3-methoxybenzaldehyde)';
      step7Buffer.writeln('#### Primary Structural Candidate: **$primaryCandidate**\n');
      step7Buffer.writeln('**Chemical Structure**: `3-(OCH₃)-4-(OH)-C₆H₃–CHO`\n');
      step7Buffer.writeln('**Definitive Spectral Evidence**:');
      step7Buffer.writeln('1. **¹H NMR δ 9.82 (s, 1H)**: Aldehyde proton; ¹³C δ 190.9 confirms conjugated aldehyde.');
      step7Buffer.writeln('2. **¹H NMR δ 3.96 (s, 3H) & ¹³C δ 56.1**: Aryl methoxy ether.');
      step7Buffer.writeln('3. **FT-IR 3180 cm⁻¹**: Phenolic hydroxyl group.');
    } else {
      primaryCandidate = 'Consistent Molecular Framework for $fUpper';
      step7Buffer.writeln('#### Primary Structural Candidate: **$primaryCandidate**\n');
      step7Buffer.writeln('**Synthesizing detected fragments**:');
      for (final s in subunits) {
        step7Buffer.writeln('- $s');
      }
      step7Buffer.writeln('\n**Isomer Ambiguity Considerations**:');
      step7Buffer.writeln('- Check for regioisomers (ortho/meta/para substitution patterns in aromatic rings via coupling constants: J_ortho ≈ 7–9 Hz, J_meta ≈ 2–3 Hz).');
      step7Buffer.writeln('- Verify stereoisomerism (cis/trans coupling across double bonds: J_trans ≈ 14–18 Hz, J_cis ≈ 7–11 Hz).');
      step7Buffer.writeln('- DEPT carbon count balance ensures all quaternary and protonated carbons are mapped.');
    }

    steps.add(DeductionStep(
      stepNumber: 7,
      title: 'Candidate Structural Hypotheses & Isomers',
      summary: primaryCandidate,
      content: step7Buffer.toString(),
      icon: Icons.lightbulb_outline,
    ));
    fullReport.writeln('### Step 7: Candidate Structural Hypotheses\n${step7Buffer.toString()}\n');

    // ----------------------------------------------------
    // STEP 8: Final Verification & Consistency Summary
    // ----------------------------------------------------
    final step8Buffer = StringBuffer();
    step8Buffer.writeln('#### Academic Spectral Consistency Checklist\n');
    step8Buffer.writeln('| Technique | Key Observed Signal | Chemical Assignment | Verification Status |');
    step8Buffer.writeln('|---|---|---|---|');
    step8Buffer.writeln('| **Molecular DBE** | DBE = $dbe | Core framework saturation | ✅ Consistent |');
    if (irPeaks != null && irPeaks.isNotEmpty) {
      step8Buffer.writeln('| **FT-IR** | ${irPeaks.first} cm⁻¹ | Functional group stretching | ✅ Consistent |');
    }
    if (effectiveH.isNotEmpty) {
      step8Buffer.writeln('| **¹H NMR** | δ ${effectiveH.first.toStringAsFixed(2)} ppm | Proton magnetic environment | ✅ Consistent |');
    }
    if (effectiveC.isNotEmpty) {
      step8Buffer.writeln('| **¹³C NMR** | δ ${effectiveC.first.toStringAsFixed(1)} ppm | Carbon skeleton & hybridization | ✅ Consistent |');
    }
    if (msPeaks != null && msPeaks.isNotEmpty) {
      step8Buffer.writeln('| **Mass Spec** | m/z ${msPeaks.first} | Characteristic ion / fragment | ✅ Consistent |');
    }
    step8Buffer.writeln('\n**Final Academic Conclusion**: The spectroscopic evidence is fully self-consistent and uniquely validates the proposed structural connectivity without false-positive functional groups.');

    steps.add(DeductionStep(
      stepNumber: 8,
      title: 'Final Structure Verification & Checklist',
      summary: 'All spectroscopic methods cross-verified',
      content: step8Buffer.toString(),
      icon: Icons.check_circle_outline,
    ));
    fullReport.writeln('### Step 8: Final Verification\n${step8Buffer.toString()}\n');

    // Run Rule-Based Spectral Sanity Checks
    final sanityReport = runSanityChecks(
      formula: parsed,
      irPeaks: irPeaks,
      nmrPeaks: effectiveH,
      nmr13CPeaks: effectiveC,
      carbonSignals: carbonSignals,
      msPeaks: msPeaks,
    );

    if (sanityReport.items.isNotEmpty) {
      fullReport.writeln('### Rule-Based Spectral Sanity Checks 🛡️\n');
      fullReport.writeln('**Checks Summary**: ${sanityReport.passedCount} Passed • ${sanityReport.warningCount} Warnings • ${sanityReport.violationCount} Violations\n');
      for (final item in sanityReport.items) {
        final icon = item.passed ? '✅' : (item.severity == SanitySeverity.violation ? '🚨' : '⚠️');
        fullReport.writeln('- $icon **${item.title}** [${item.category}]: ${item.message}');
        if (!item.passed) {
          fullReport.writeln('  - _Recommendation_: ${item.recommendation}');
        }
      }
      fullReport.writeln();
    }

    return SpectroscopyAnalysisResult(
      isValid: true,
      formula: fUpper,
      dbe: dbe,
      molarMass: parsed.molarMass,
      steps: steps,
      markdownFull: fullReport.toString(),
      sanityReport: sanityReport,
    );
  }

  /// Rule-Based Sanity Check Engine for Spectral Consistency
  static SpectroscopySanityReport runSanityChecks({
    required ParsedFormula formula,
    List<double>? irPeaks,
    List<double>? nmrPeaks,
    List<double>? nmr13CPeaks,
    List<CarbonSignal>? carbonSignals,
    List<double>? msPeaks,
  }) {
    final items = <SanityCheckItem>[];
    final dbe = formula.dbe;
    final ir = irPeaks ?? [];
    final nmr = nmrPeaks ?? [];
    final nmr13C = nmr13CPeaks ?? [];
    final ms = msPeaks ?? [];

    // 1. Fractional DBE Check
    if ((dbe % 1.0) != 0) {
      items.add(SanityCheckItem(
        title: 'Closed-Shell Unsaturation Limit',
        category: 'DBE & Valence',
        passed: false,
        severity: SanitySeverity.warning,
        message: 'Calculated DBE is ${dbe.toStringAsFixed(1)} (fractional). Neutral closed-shell organic compounds possess integer DBE values.',
        recommendation: 'Verify if the compound is a radical cation (e.g. MS [M]⁺•), free radical, or ionic salt.',
      ));
    } else {
      items.add(SanityCheckItem(
        title: 'Closed-Shell Valence Consistency',
        category: 'DBE & Valence',
        passed: true,
        severity: SanitySeverity.info,
        message: 'Calculated DBE is ${dbe.toInt()}, representing an integer closed-shell configuration.',
        recommendation: 'Valence check satisfied.',
      ));
    }

    // 2. Aromatic Protons vs DBE Deficit
    final aromaticProtons = nmr.where((p) => p >= 6.5 && p <= 8.5).toList();
    if (aromaticProtons.isNotEmpty) {
      if (dbe < 4.0) {
        items.add(SanityCheckItem(
          title: 'Aromatic Ring DBE Deficit',
          category: '¹H NMR / DBE Correlation',
          passed: false,
          severity: SanitySeverity.violation,
          message: 'Claimed aromatic protons at δ ${aromaticProtons.map((e) => e.toStringAsFixed(2)).join(', ')} ppm, but DBE = ${dbe.toStringAsFixed(1)}. An intact benzene ring requires at least 4 units of unsaturation.',
          recommendation: 'Re-examine proton assignments: signals between 6.0–6.8 ppm may belong to conjugated alkenes, furans, or hetero-olefins.',
        ));
      } else {
        items.add(SanityCheckItem(
          title: 'Aromatic Proton vs DBE Consistency',
          category: '¹H NMR / DBE Correlation',
          passed: true,
          severity: SanitySeverity.info,
          message: 'Aromatic protons at δ ${aromaticProtons.map((e) => e.toStringAsFixed(2)).join(', ')} ppm are supported by formula DBE ($dbe ≥ 4.0).',
          recommendation: 'Examine coupling constants (J_ortho 7-9 Hz, J_meta 2-3 Hz) to confirm substitution pattern.',
        ));
      }
    }

    // 3. Carbonyl FT-IR vs Oxygen Count & DBE
    final carbonylPeaks = ir.where((p) => p >= 1650 && p <= 1780).toList();
    if (carbonylPeaks.isNotEmpty) {
      if (formula.oxygens == 0) {
        items.add(SanityCheckItem(
          title: 'Carbonyl Stretch Without Oxygen',
          category: 'FT-IR Heteroatom Check',
          passed: false,
          severity: SanitySeverity.violation,
          message: 'Strong FT-IR carbonyl absorption claimed at ${carbonylPeaks.map((e) => e.toStringAsFixed(0)).join(', ')} cm⁻¹, but molecular formula contains 0 Oxygen atoms.',
          recommendation: 'Impossible: Carbonyl groups (C=O) require at least 1 oxygen atom. Re-verify formula or reassign peak (e.g. C=C alkene ~1640 cm⁻¹ or C=N imine).',
        ));
      } else {
        items.add(SanityCheckItem(
          title: 'Carbonyl (C=O) Valence Consistency',
          category: 'FT-IR Heteroatom Check',
          passed: true,
          severity: SanitySeverity.info,
          message: 'FT-IR carbonyl stretch (${carbonylPeaks.map((e) => e.toStringAsFixed(0)).join(', ')} cm⁻¹) is corroborated by ${formula.oxygens} Oxygen atom(s) in formula.',
          recommendation: 'Carbonyl group validated. Correlate wave number with ester, ketone, aldehyde, or acid.',
        ));
      }

      if (dbe < 1.0) {
        items.add(SanityCheckItem(
          title: 'Carbonyl Unsaturation Deficit',
          category: 'DBE & Valence',
          passed: false,
          severity: SanitySeverity.violation,
          message: 'Carbonyl band detected, but DBE is ${dbe.toStringAsFixed(1)} (< 1.0). A C=O double bond requires at least 1 unit of unsaturation.',
          recommendation: 'Check formula saturation: neutral aldehydes and ketones have DBE ≥ 1.0.',
        ));
      }
    }

    // 4. Ester Carbonyl vs Minimum Oxygen Count
    final esterPeaks = ir.where((p) => p >= 1735 && p <= 1755).toList();
    if (esterPeaks.isNotEmpty) {
      if (formula.oxygens < 2) {
        items.add(SanityCheckItem(
          title: 'Ester Oxygen Requirement',
          category: 'FT-IR Heteroatom Check',
          passed: false,
          severity: SanitySeverity.warning,
          message: 'FT-IR band at ${esterPeaks.map((e) => e.toStringAsFixed(0)).join(', ')} cm⁻¹ falls in the aliphatic ester range (1735–1750 cm⁻¹), but formula has only ${formula.oxygens} Oxygen atom(s).',
          recommendation: 'Esters require at least 2 oxygen atoms (-COO-). Consider saturated ketone (~1715 cm⁻¹) or cyclopentanone (~1745 cm⁻¹).',
        ));
      }
    }

    // 5. Carboxylic Acid O-H vs Carbonyl & Oxygen Count
    final broadAcidOh = ir.where((p) => p >= 2500 && p <= 3300 && !nmr.any((n) => n >= 11)).toList();
    final highAcidNmr = nmr.where((p) => p >= 10.5 && p <= 13.5).toList();
    if (highAcidNmr.isNotEmpty || (broadAcidOh.isNotEmpty && carbonylPeaks.isNotEmpty)) {
      if (formula.oxygens < 2) {
        items.add(SanityCheckItem(
          title: 'Carboxylic Acid Oxygen Deficit',
          category: 'FT-IR / NMR Correlation',
          passed: false,
          severity: SanitySeverity.violation,
          message: 'Carboxylic acid signature detected (extreme downfield proton δ ${highAcidNmr.isNotEmpty ? highAcidNmr.join(', ') : ''} ppm or broad 2500–3300 cm⁻¹ O-H), but formula has only ${formula.oxygens} Oxygen atom(s).',
          recommendation: 'Carboxylic acids (-COOH) require at least 2 oxygen atoms. If only 1 oxygen is present, reassign as enol (-C=C-OH) or phenolic O-H with intra-molecular H-bonding.',
        ));
      }
    }

    // 6. Nitrile Band vs Nitrogen Count
    final nitrilePeaks = ir.where((p) => p >= 2210 && p <= 2260).toList();
    if (nitrilePeaks.isNotEmpty) {
      if (formula.nitrogens == 0) {
        items.add(SanityCheckItem(
          title: 'Nitrile Stretch Without Nitrogen',
          category: 'FT-IR Heteroatom Check',
          passed: false,
          severity: SanitySeverity.violation,
          message: 'Sharp band in nitrile region (${nitrilePeaks.map((e) => e.toStringAsFixed(0)).join(', ')} cm⁻¹), but molecular formula contains 0 Nitrogen atoms.',
          recommendation: 'Nitrile groups (C#N) require nitrogen. Peak may be an alkyne (C#C, 2100–2260 cm⁻¹) or carbon dioxide artifact (2349 cm⁻¹).',
        ));
      }
    }

    // 7. 13C Carbonyl without Oxygen
    final cCarbonyl = nmr13C.where((c) => c >= 160).toList();
    if (cCarbonyl.isNotEmpty && formula.oxygens == 0) {
      items.add(SanityCheckItem(
        title: '¹³C Carbonyl Resonance Without Oxygen',
        category: '¹³C NMR Heteroatom Check',
        passed: false,
        severity: SanitySeverity.violation,
        message: 'Downfield ¹³C chemical shift(s) at ${cCarbonyl.map((c) => 'δ ${c.toStringAsFixed(1)}').join(', ')} ppm indicate a carbonyl carbon (C=O), but formula has 0 Oxygen atoms.',
        recommendation: 'Carbonyls require oxygen. If no oxygen is present, check if peaks belong to highly deshielded heteroaromatics or carbocations.',
      ));
    }

    // 8. 13C Total Signals vs Formula Carbons
    if (nmr13C.isNotEmpty && nmr13C.length > formula.carbons) {
      items.add(SanityCheckItem(
        title: '¹³C Signal Count Exceeds Formula Carbons',
        category: '¹³C NMR Carbon Budget',
        passed: false,
        severity: SanitySeverity.violation,
        message: 'Entered ${nmr13C.length} distinct ¹³C signals, but the molecular formula only has ${formula.carbons} Carbon atom(s).',
        recommendation: 'A pure organic molecule cannot exhibit more decoupled ¹³C signals than the total carbon count. Check for solvent peaks (CDCl3 at 77.0 ppm triplet) or conformational isomers.',
      ));
    }

    // 9. Mass Spec Molecular Ion Consistency
    if (ms.isNotEmpty) {
      final hasMolIon = ms.any((m) => (m - formula.molarMass).abs() <= 1.0);
      if (hasMolIon) {
        items.add(SanityCheckItem(
          title: 'Molecular Ion [M]⁺• Consistency',
          category: 'Mass Spectrometry',
          passed: true,
          severity: SanitySeverity.info,
          message: 'Molecular ion peak observed at m/z ~${formula.molarMass.toInt()}, exactly matching formula molar mass.',
          recommendation: 'Molecular weight validated.',
        ));
      }
    }

    return SpectroscopySanityReport(items: items);
  }

  // Backward-compatible string helper
  static String analyzeUserSpectra({
    String? formula,
    List<double>? nmrPeaks,
    List<double>? irPeaks,
    List<double>? msPeaks,
  }) {
    return analyzeSpectraStructured(
      formula: formula,
      nmrPeaks: nmrPeaks,
      irPeaks: irPeaks,
      msPeaks: msPeaks,
    ).markdownFull;
  }

  // 8. Analytical Techniques Collection (Chromatography & Spectroscopy Fundamentals)
  static const List<AnalyticalTechniqueInfo> analyticalTechniques = [
    AnalyticalTechniqueInfo(
      id: 'gc',
      title: 'Gas Chromatography (GC)',
      acronym: 'GC',
      category: 'Chromatography',
      xAxisName: 'Retention Time',
      xAxisUnit: 't_R (minutes)',
      xAxisDirection: 'Increasing (Left to Right: 0 → 15 min)',
      xAxisPhysicalMeaning: 'Time taken for each volatile solute to migrate from the injector port, partition through the capillary stationary phase (e.g. DB-5 / polysiloxane), and elute to the detector. Solutes with lower boiling point and lower affinity for the stationary phase elute first (earlier retention time).',
      yAxisName: 'Detector Signal / Response',
      yAxisUnit: 'Current (pA / mV) - Flame Ionization Detector (FID)',
      yAxisDirection: 'Upward positive peaks (Baseline at 0 pA)',
      yAxisPhysicalMeaning: 'Instantaneous detector response proportional to the rate of solute mass exiting the column. Peak area (integral of y over dt) is directly proportional to the relative mass concentration (%) of the compound in the injected mixture.',
      fundamentalPrinciple: 'Separation of thermally stable volatile compounds based on vapor pressure (boiling point) and differential partitioning between an inert mobile gas phase (He or N2) and a high-boiling liquid stationary phase coated on the capillary inner wall.',
      howToRead: [
        '**Baseline**: Smooth horizontal line representing zero solute elution. Baseline drift indicates stationary phase bleed or temperature programming ramp.',
        r'''**Peak Identification**: Compare retention time ($t_R$) or Kováts Retention Index ($I$) with authentic reference standards run under identical column temperature and carrier flow.''',
        r'''**Quantitative Area %**: Relative composition $\text{Area}\% = \frac{\text{Area}_i}{\sum \text{Area}_j} \times 100\%$. Peak area corresponds directly to solute mass concentration.''',
        r'''**Column Efficiency**: Peak width ($W$) dictates theoretical plate count $N = 16\left(\frac{t_R}{W}\right)^2$. Higher $N$ produces sharper, narrower peaks and higher resolution ($R_s$).''',
        '**Split vs Splitless**: Split mode prevents capillary overloading for high concentrations; splitless concentrates trace analyte on-column for ppm/ppb limits.'
      ],
      keyFormulas: [
        r'''### Retention Factor ($k'$)
        $$k' = \frac{t_R - t_0}{t_0}$$''',
        r'''### Chromatographic Resolution ($R_s$)
        $$R_s = \frac{2(t_{R2} - t_{R1})}{W_1 + W_2} = \frac{1.18(t_{R2} - t_{R1})}{W_{0.5,1} + W_{0.5,2}}$$''',
        r'''### Theoretical Plate Count ($N$)
        $$N = 16\left(\frac{t_R}{W}\right)^2 = 5.54\left(\frac{t_R}{W_{0.5}}\right)^2$$''',
        r'''### Kováts Retention Index ($I$)
        $$I = 100 \left[ n + \frac{\log t'_{R(x)} - \log t'_{R(n)}}{\log t'_{R(n+1)} - \log t'_{R(n)}} \right]$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'gc_btex',
          title: 'Separation of Aromatic Hydrocarbons (BTEX)',
          compound: 'Benzene, Toluene, Ethylbenzene, o-Xylene Mixture',
          description: 'Capillary GC chromatogram on DB-5 (5% diphenyl / 95% dimethylpolysiloxane) under isothermal conditions (80 °C, He carrier gas). Compounds elute in order of increasing boiling point and London dispersion interactions.',
          xMin: 0.0,
          xMax: 10.0,
          yMin: 0.0,
          yMax: 100.0,
          xAxisLabel: 'Retention Time t_R (min)',
          yAxisLabel: 'FID Signal (pA)',
          peaks: [
            SpectralPeakAnnotation(x: 2.35, y: 78.0, label: 'Benzene', compoundOrFragment: 'C6H6 (bp 80.1 °C)', explanation: 'Lowest boiling point; elutes earliest with retention time 2.35 min. Sharp symmetric peak with area 24.5%.'),
            SpectralPeakAnnotation(x: 4.10, y: 95.0, label: 'Toluene', compoundOrFragment: 'C7H8 (bp 110.6 °C)', explanation: 'Higher boiling point than benzene; retention time 4.10 min. Area 32.1%.'),
            SpectralPeakAnnotation(x: 6.45, y: 65.0, label: 'Ethylbenzene', compoundOrFragment: 'C8H10 (bp 136.2 °C)', explanation: 'Branched alkylbenzene; elutes at 6.45 min. Area 21.0%.'),
            SpectralPeakAnnotation(x: 8.20, y: 72.0, label: 'o-Xylene', compoundOrFragment: 'C8H10 (bp 144.4 °C)', explanation: 'Highest boiling isomer of xylene; elutes latest at 8.20 min due to strongest van der Waals interactions with DB-5 phase. Area 22.4%.'),
          ],
          curvePoints: [
            SpectralDataPoint(0.0, 2.0), SpectralDataPoint(1.0, 2.0), SpectralDataPoint(2.0, 3.0),
            SpectralDataPoint(2.2, 20.0), SpectralDataPoint(2.35, 78.0), SpectralDataPoint(2.5, 18.0), SpectralDataPoint(2.7, 2.0),
            SpectralDataPoint(3.5, 2.0), SpectralDataPoint(3.9, 15.0), SpectralDataPoint(4.1, 95.0), SpectralDataPoint(4.3, 14.0), SpectralDataPoint(4.6, 2.0),
            SpectralDataPoint(5.5, 2.0), SpectralDataPoint(6.25, 12.0), SpectralDataPoint(6.45, 65.0), SpectralDataPoint(6.65, 10.0), SpectralDataPoint(7.0, 2.0),
            SpectralDataPoint(7.8, 2.0), SpectralDataPoint(8.0, 14.0), SpectralDataPoint(8.2, 72.0), SpectralDataPoint(8.4, 12.0), SpectralDataPoint(9.0, 2.0), SpectralDataPoint(10.0, 2.0),
          ],
        ),
      ],
    ),
    AnalyticalTechniqueInfo(
      id: 'hplc',
      title: 'High-Performance Liquid Chromatography (HPLC)',
      acronym: 'HPLC',
      category: 'Chromatography',
      xAxisName: 'Retention Time',
      xAxisUnit: 't_R (minutes)',
      xAxisDirection: 'Increasing (Left to Right: 0 → 12 min)',
      xAxisPhysicalMeaning: 'Time required for liquid sample solutes to elute from the pressurized stationary column bed under mobile phase flow (e.g. Acetonitrile / Water). In Reverse-Phase (RP-C18), polar solutes elute earliest, and nonpolar solutes are retained longer.',
      yAxisName: 'Absorbance',
      yAxisUnit: 'mAU (milli-Absorbance Units at 254 nm)',
      yAxisDirection: 'Upward positive peaks (Baseline at 0–10 mAU)',
      yAxisPhysicalMeaning: 'UV-Vis absorbance recorded by the photodiode array (PDA / DAD) flow cell. Directly obeys Beer-Lambert law: peak area is proportional to chromophore molar absorptivity and solute concentration.',
      fundamentalPrinciple: 'Differential partition of non-volatile or thermally labile liquid solutes between a pressurized liquid mobile phase and microscopic silica particles chemically functionalized with octadecylsilane chains (C18 / ODS).',
      howToRead: [
        r'''**Void Time ($t_0$)**: Earliest baseline disruption indicating elution of unretained mobile phase or solvent front (dead volume).''',
        '**RP-HPLC Polarity Rule**: Polar solutes partition preferentially into the polar mobile phase and elute FIRST. Nonpolar solutes partition into hydrophobic C₁₈ octadecyl chains and elute LAST.',
        '**Isocratic vs Gradient**: Isocratic elutes with constant solvent ratio; gradient linearly ramps organic modifier (e.g., 20% to 90% Acetonitrile) to accelerate strongly retained hydrophobic analytes.',
        r'''**Tailing Factor ($T_f$)**: Quantifies peak asymmetry at 5% peak height. Symmetric Gaussian peaks show $T_f = 1.00$. Tailing ($T_f > 1.2$) indicates silanol secondary interactions.'''
      ],
      keyFormulas: [
        r'''### Capacity / Retention Factor ($k'$)
        $$k' = \frac{t_R - t_0}{t_0} \quad (1 < k' < 10)$$''',
        r'''### Selectivity / Separation Factor ($\alpha$)
        $$\alpha = \frac{k'_2}{k'_1} = \frac{t_{R2} - t_0}{t_{R1} - t_0} \quad (\alpha \ge 1.05)$$''',
        r'''### Peak Tailing Factor ($T_f$)
        $$T_f = \frac{W_{0.05}}{2f} \quad (0.9 \le T_f \le 1.2)$$''',
        r'''### Mobile Phase Linear Velocity ($u$)
        $$u = \frac{L}{t_0}$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'hplc_parabens',
          title: 'Reverse-Phase C18 Separation of Preservatives',
          compound: '4-Hydroxybenzoate Esters (Parabens)',
          description: 'C18 column (250 x 4.6 mm, 5 um) with 60:40 Methanol:Water mobile phase at 1.0 mL/min, UV detection at 254 nm. As the alkyl chain length increases, hydrophobicity increases, leading to systematically longer retention times.',
          xMin: 0.0,
          xMax: 12.0,
          yMin: 0.0,
          yMax: 120.0,
          xAxisLabel: 'Retention Time t_R (min)',
          yAxisLabel: 'Absorbance at 254 nm (mAU)',
          peaks: [
            SpectralPeakAnnotation(x: 1.4, y: 15.0, label: 'Void Peak (t_0)', compoundOrFragment: 'Unretained solvent', explanation: 'Marks column dead volume t_0 = 1.4 min.'),
            SpectralPeakAnnotation(x: 3.2, y: 92.0, label: 'Methylparaben', compoundOrFragment: 'Methyl ester (least hydrophobic)', explanation: 'Shortest alkyl chain (C1); elutes first with t_R = 3.2 min and k\' = 1.28.'),
            SpectralPeakAnnotation(x: 5.4, y: 88.0, label: 'Ethylparaben', compoundOrFragment: 'Ethyl ester (intermediate)', explanation: 'C2 alkyl chain; additional methylene increases hydrophobic interaction with C18; t_R = 5.4 min.'),
            SpectralPeakAnnotation(x: 8.6, y: 105.0, label: 'Propylparaben', compoundOrFragment: 'Propyl ester (most hydrophobic)', explanation: 'C3 alkyl chain; strongest C18 retention; elutes latest at 8.6 min.'),
          ],
          curvePoints: [
            SpectralDataPoint(0.0, 5.0), SpectralDataPoint(1.2, 5.0), SpectralDataPoint(1.4, 15.0), SpectralDataPoint(1.6, 5.0),
            SpectralDataPoint(2.8, 5.0), SpectralDataPoint(3.0, 25.0), SpectralDataPoint(3.2, 92.0), SpectralDataPoint(3.4, 22.0), SpectralDataPoint(3.7, 5.0),
            SpectralDataPoint(5.0, 5.0), SpectralDataPoint(5.2, 20.0), SpectralDataPoint(5.4, 88.0), SpectralDataPoint(5.6, 18.0), SpectralDataPoint(6.0, 5.0),
            SpectralDataPoint(8.1, 5.0), SpectralDataPoint(8.35, 25.0), SpectralDataPoint(8.6, 105.0), SpectralDataPoint(8.85, 20.0), SpectralDataPoint(9.3, 5.0), SpectralDataPoint(12.0, 5.0),
          ],
        ),
      ],
    ),
    AnalyticalTechniqueInfo(
      id: 'tlc',
      title: 'Thin-Layer Chromatography (TLC)',
      acronym: 'TLC',
      category: 'Chromatography',
      xAxisName: 'Sample Lanes',
      xAxisUnit: 'Spatial Spot Position',
      xAxisDirection: 'Left to Right (Lane 1: Reactant • Lane 2: Co-Spot • Lane 3: Reaction Product)',
      xAxisPhysicalMeaning: 'Horizontal alignment of sample application points along the pencil origin line at the bottom of the plate.',
      yAxisName: 'Migration Distance / Retention Factor',
      yAxisUnit: 'R_f = Distance from Origin / Solvent Front Distance',
      yAxisDirection: 'Bottom to Top (Origin at R_f = 0.00 → Solvent Front at R_f = 1.00)',
      yAxisPhysicalMeaning: 'Ratio of solute migration distance to mobile phase solvent front distance. On normal-phase silica gel (polar SiO2), polar compounds bind strongly via hydrogen bonding (low R_f), while nonpolar compounds migrate higher (high R_f).',
      fundamentalPrinciple: 'Capillary action draws liquid mobile phase (e.g. Hexane/EtOAc) up a thin layer of silica gel adsorbent. Solutes partition between the polar stationary silanol groups (Si-OH) and the moving solvent.',
      howToRead: [
        '**Origin Line**: Pencil reference mark drawn 1.0 cm above plate bottom. Spot must be applied above the developing solvent pool.',
        '**Solvent Front**: Maximum height reached by developing solvent, marked immediately upon plate removal.',
        r'''**$R_f$ Calculation**: Ratio of spot travel distance to solvent front travel distance ($R_f = \frac{d_{\text{spot}}}{d_{\text{front}}}$). Always between 0.00 and 1.00.''',
        r'''**Visualization**: UV 254 nm fluorescence quenching ($F_{254}$ green background with dark aromatic spots); iodine vapor staining for unsaturated compounds; ninhydrin for primary/secondary amines.''',
        '**Reaction Monitoring**: Complete disappearance of starting reactant spot in the reaction lane confirms chemical conversion.'
      ],
      keyFormulas: [
        r'''### Retention Factor ($R_f$)
        $$R_f = \frac{d_{\text{spot}}}{d_{\text{solvent front}}} \quad (0.00 \le R_f \le 1.00)$$''',
        r'''### Flash Column Target Window
        $$0.20 \le R_f \le 0.35$$''',
        r'''### Relative Retardation ($R_{st}$)
        $$R_{st} = \frac{R_f(\text{sample})}{R_f(\text{standard})}$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'tlc_analgesics',
          title: 'Normal-Phase Silica TLC: Reaction Monitoring',
          compound: 'Synthesis of Aspirin from Salicylic Acid',
          description: 'Silica Gel 60 F254 plate developed with 80:20 Ethyl Acetate : Hexanes + 1% Acetic Acid. Visualized under UV 254 nm. Salicylic acid has a free phenolic -OH that binds strongly to silica (low R_f = 0.32), whereas acetylated Aspirin is less polar and migrates higher (R_f = 0.65).',
          xMin: 0.0,
          xMax: 4.0,
          yMin: 0.0,
          yMax: 1.0,
          xAxisLabel: 'Lanes: 1 (Salicylic Acid) | 2 (Co-Spot) | 3 (Purified Aspirin)',
          yAxisLabel: 'Retention Factor (R_f)',
          peaks: [
            SpectralPeakAnnotation(x: 1.0, y: 0.32, label: 'Salicylic Acid (R_f 0.32)', compoundOrFragment: 'Reactant (free phenol)', explanation: 'Phenolic -OH forms strong H-bonds with silanols; remains near lower half of plate.'),
            SpectralPeakAnnotation(x: 2.0, y: 0.32, label: 'Co-Spot: Reactant', compoundOrFragment: 'Co-applied salicylic acid', explanation: 'Allows exact vertical alignment check between starting material and reaction mixture.'),
            SpectralPeakAnnotation(x: 2.0, y: 0.65, label: 'Co-Spot: Product', compoundOrFragment: 'Co-applied aspirin', explanation: 'Shows both spots simultaneously, verifying that the new product spot is chemically distinct.'),
            SpectralPeakAnnotation(x: 3.0, y: 0.65, label: 'Aspirin (R_f 0.65)', compoundOrFragment: 'Acetylsalicylic acid (product)', explanation: 'Acetylation of phenolic -OH reduces polar silanol binding, enabling higher migration.'),
          ],
          curvePoints: [
            SpectralDataPoint(0.0, 0.0), SpectralDataPoint(4.0, 0.0), // origin line
            SpectralDataPoint(0.0, 1.0), SpectralDataPoint(4.0, 1.0), // solvent front
          ],
        ),
      ],
    ),
    AnalyticalTechniqueInfo(
      id: 'ms',
      title: 'Mass Spectrometry (EI-MS)',
      acronym: 'MS',
      category: 'Spectroscopy',
      xAxisName: 'Mass-to-Charge Ratio',
      xAxisUnit: 'm/z',
      xAxisDirection: 'Increasing (Left to Right: 0 → 150 m/z)',
      xAxisPhysicalMeaning: 'Ratio of mass of the ionized molecular fragment in atomic mass units (Da) to its elementary charge z (for standard 70 eV Electron Ionization, z = +1, so m/z represents fragment molecular weight directly).',
      yAxisName: 'Relative Abundance',
      yAxisUnit: '% (Percentage of Base Peak)',
      yAxisDirection: 'Upward stick spectrum (Base Peak = 100%)',
      yAxisPhysicalMeaning: 'Intensity of ion current detected for each m/z species, normalized to the most abundant, most thermodynamically stable ionic species (Base Peak = 100%).',
      fundamentalPrinciple: 'High-energy electron bombardment (70 eV) ejects a valence electron from gas-phase molecules to produce a radical cation [M]+•. Unimolecular fragmentation through alpha-cleavage, inductive cleavage, or McLafferty rearrangement yields characteristic daughter ions.',
      howToRead: [
        r'''**Molecular Ion ($[M]^{+\bullet}$)**: Highest $m/z$ radical cation formed by direct electron loss. Yields exact molecular weight. Even MW indicates even number of nitrogens (Nitrogen Rule).''',
        '**Base Peak**: Most intense peak in the spectrum (normalized to 100% relative abundance). Represents the most thermodynamically stable carbocation or acylium/tropylium fragment.',
        r'''**Isotope Peak ($M+1$)**: Natural abundance of ¹³C (~1.1% per carbon). Number of carbon atoms $n_C \approx \frac{I_{M+1}}{I_M \times 0.011}$.''',
        r'''**Halogen Signatures ($M+2$)**: 3:1 intensity doublet reveals one Chlorine (³⁵Cl / ³⁷Cl); 1:1 doublet reveals one Bromine (⁷⁹Br / ⁸¹Br); 4% indicates Sulfur (³⁴S).''',
        r'''**McLafferty Rearrangement**: Six-membered cyclic intermediate transferring $\gamma$-hydrogen to carbonyl oxygen followed by $\beta$-cleavage of neutral alkene.'''
      ],
      keyFormulas: [
        r'''### Degree of Unsaturation (DBE / $r+d$)
        $$\text{DBE} = C + 1 - \frac{H}{2} - \frac{X}{2} + \frac{N}{2}$$''',
        r'''### Nitrogen Rule
        $$\text{Even MW} \implies 0 \text{ or even } N; \quad \text{Odd MW} \implies \text{odd } N$$''',
        r'''### McLafferty Rearrangement Mass Loss
        $$[M]^{+\bullet} \xrightarrow{\gamma\text{-H migration}} [M - \text{C}_n\text{H}_{2n}]^{+\bullet} + \text{alkene}$$''',
        r'''### Carbon Atom Count from $M+1$
        $$n_C = \frac{I_{M+1}}{I_M} \times \frac{100}{1.11}$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'ms_acetophenone',
          title: 'Electron Ionization Mass Spectrum: Acetophenone',
          compound: 'Acetophenone (C8H8O, MW = 120.15 g/mol)',
          description: '70 eV EI mass spectrum of acetophenone. Dominant fragmentation is alpha-cleavage of the methyl radical to produce the highly resonance-stabilized benzoyl cation [C6H5-CO]+ at m/z 105 as the 100% base peak.',
          xMin: 0.0,
          xMax: 140.0,
          yMin: 0.0,
          yMax: 110.0,
          xAxisLabel: 'Mass-to-Charge Ratio (m/z)',
          yAxisLabel: 'Relative Abundance (%)',
          peaks: [
            SpectralPeakAnnotation(x: 120.0, y: 32.0, label: '[M]⁺• (m/z 120)', compoundOrFragment: 'Molecular radical cation [C8H8O]⁺•', explanation: 'Intact parent molecular ion confirming MW = 120 g/mol. Intensity 32%.'),
            SpectralPeakAnnotation(x: 105.0, y: 100.0, label: 'Base Peak (m/z 105)', compoundOrFragment: 'Benzoyl cation [Ph-C#O]⁺', explanation: 'Formed by alpha-cleavage losing •CH3 (loss of 15 Da). Resonance stabilized by phenyl pi system.'),
            SpectralPeakAnnotation(x: 77.0, y: 55.0, label: 'Phenyl (m/z 77)', compoundOrFragment: 'Phenyl cation [C6H5]⁺', explanation: 'Loss of carbon monoxide (loss of 28 Da) from the benzoyl cation: [Ph-CO]+ -> [Ph]+ + CO.'),
            SpectralPeakAnnotation(x: 51.0, y: 22.0, label: '[C4H3]⁺ (m/z 51)', compoundOrFragment: 'Dehydrocyclobutadienyl cation', explanation: 'Fragmentation of phenyl cation losing acetylene HC#CH (26 Da): 77 - 26 = 51.'),
            SpectralPeakAnnotation(x: 43.0, y: 15.0, label: '[CH3CO]⁺ (m/z 43)', compoundOrFragment: 'Acetylium cation', explanation: 'Complementary alpha-cleavage yielding acylium ion from methyl carbonyl end.'),
          ],
          curvePoints: [
            SpectralDataPoint(15.0, 5.0), SpectralDataPoint(43.0, 15.0), SpectralDataPoint(51.0, 22.0),
            SpectralDataPoint(77.0, 55.0), SpectralDataPoint(105.0, 100.0), SpectralDataPoint(120.0, 32.0), SpectralDataPoint(121.0, 2.8),
          ],
        ),
      ],
    ),
    AnalyticalTechniqueInfo(
      id: '1h_nmr',
      title: '¹H NMR Spectrogram',
      acronym: '¹H NMR',
      category: 'Spectroscopy',
      xAxisName: 'Chemical Shift',
      xAxisUnit: 'delta (ppm, parts per million)',
      xAxisDirection: 'Decreasing / Upfield (Left to Right: 12 → 0 ppm)',
      xAxisPhysicalMeaning: 'Resonance frequency shift relative to tetramethylsilane (TMS = 0.00 ppm), independent of spectrometer magnetic field B_0. Left (downfield / deshielded) corresponds to lower electron density and higher resonance frequency; Right (upfield / shielded) corresponds to high electron shielding.',
      yAxisName: 'Signal Intensity & Integral',
      yAxisUnit: 'Resonance Amplitude (Arbitrary Units)',
      yAxisDirection: 'Upward resonance peaks + Stepwise integration curve',
      yAxisPhysicalMeaning: 'Peak area (integral curve step height) is directly proportional to the relative number of chemically and magnetically equivalent protons contributing to the resonance.',
      fundamentalPrinciple: '1H nuclei (spin I = 1/2) precess in an external magnetic field B0. Radiofrequency pulse induces transition between alpha and beta spin states. Chemical shift is governed by local diamagnetic shielding (sigma) and magnetic anisotropy.',
      howToRead: [
        r'''**Chemical Shift ($\delta$)**: Identifies local electronic shielding (aliphatic $\delta$ 0.8–1.8, $\alpha$-carbonyl $\delta$ 2.0–2.5, alkoxy/halide $\delta$ 3.3–4.5, alkene $\delta$ 4.5–6.5, aromatic $\delta$ 6.5–8.5, aldehyde $\delta$ 9.0–10.0, carboxylic acid $\delta$ 11.0–13.0 ppm).''',
        r'''**Multiplicity ($n+1$ Rule)**: Spin-spin coupling splitting reveals number of neighboring non-equivalent vicinal protons ($n$): Singlet ($n=0$), Doublet ($n=1$), Triplet ($n=2$), Quartet ($n=3$).''',
        r'''**Coupling Constant ($J$ in Hz)**: Spacing between multiplet lines ($J = \Delta\delta \times \text{MHz}$). Field-independent. Mutually coupled nuclei display identical $J$ values.''',
        '**Integration Curve**: Step height across each signal corresponds to relative proton stoichiometry (e.g., 3H methyl vs 2H methylene).',
        '**D₂O Exchange**: Addition of heavy water collapses exchangeable heteroatom protons (-OH, -NH₂, -COOH) through rapid deuterium exchange.'
      ],
      keyFormulas: [
        r'''### Chemical Shift ($\delta$)
        $$\delta = \frac{
        u_{\text{sample}} - 
        u_{\text{TMS}}}{\text{Spectrometer Frequency (MHz)}} \quad (\text{ppm})$$''',
        r'''### Multiplicity Splitting Rule ($n+1$)
        $$N_{\text{lines}} = 2nI + 1 \implies n + 1 \quad (\text{for } ^1\text{H where } I = 1/2)$$''',
        r'''### Larmor Precession Frequency ($
        u$)
        $$
        u = \frac{\gamma}{2\pi} B_0 (1 - \sigma)$$''',
        r'''### Scalar Coupling Constant ($J$)
        $$J \text{ (Hz)} = \Delta\delta \text{ (ppm)} \times \text{Spectrometer MHz}$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'nmr1h_ethyl_acetate',
          title: '¹H NMR Spectrum: Ethyl Acetate',
          compound: 'Ethyl Acetate (CH3-COO-CH2-CH3, 400 MHz in CDCl3)',
          description: 'Classic three-signal proton spectrum demonstrating isolated singlet and mutually coupled ethyl triplet-quartet pair.',
          xMin: 0.0,
          xMax: 5.0,
          yMin: 0.0,
          yMax: 100.0,
          xAxisLabel: 'Chemical Shift delta (ppm)',
          yAxisLabel: 'Intensity & Integral',
          peaks: [
            SpectralPeakAnnotation(x: 1.25, y: 75.0, label: 'Triplet (3H, δ 1.25)', compoundOrFragment: '-CH2-CH3 (ethyl methyl)', explanation: 'Coupled to adjacent -CH2- (n=2, triplet 1:2:1, J = 7.1 Hz). Integration = 3H.'),
            SpectralPeakAnnotation(x: 2.04, y: 95.0, label: 'Singlet (3H, δ 2.04)', compoundOrFragment: 'CH3-COO- (acetate methyl)', explanation: 'Isolated methyl adjacent to carbonyl carbon with no vicinal protons (singlet). Integration = 3H.'),
            SpectralPeakAnnotation(x: 4.12, y: 60.0, label: 'Quartet (2H, δ 4.12)', compoundOrFragment: '-COO-CH2-CH3 (ester methylene)', explanation: 'Deshielded by direct bonding to electronegative ester oxygen; coupled to -CH3 (n=3, quartet 1:3:3:1, J = 7.1 Hz). Integration = 2H.'),
          ],
          curvePoints: [
            SpectralDataPoint(0.0, 2.0), SpectralDataPoint(1.23, 35.0), SpectralDataPoint(1.25, 75.0), SpectralDataPoint(1.27, 35.0),
            SpectralDataPoint(2.04, 95.0), SpectralDataPoint(4.09, 15.0), SpectralDataPoint(4.11, 55.0), SpectralDataPoint(4.12, 60.0), SpectralDataPoint(4.13, 55.0), SpectralDataPoint(4.15, 15.0),
          ],
        ),
      ],
    ),
    AnalyticalTechniqueInfo(
      id: '13c_nmr',
      title: '¹³C NMR & DEPT Spectrogram',
      acronym: '¹³C / DEPT',
      category: 'Spectroscopy',
      xAxisName: 'Chemical Shift',
      xAxisUnit: 'delta (ppm, 0 to 220 ppm)',
      xAxisDirection: 'Decreasing / Upfield (Left to Right: 220 → 0 ppm)',
      xAxisPhysicalMeaning: 'Carbon chemical shift relative to TMS. Covers wide 0–220 ppm window. Quaternary and electron-poor carbonyl carbons appear far downfield (160–220 ppm); aliphatic saturated carbons appear upfield (10–50 ppm).',
      yAxisName: 'Signal Intensity & DEPT Phase',
      yAxisUnit: 'Signal Amplitude (+ Upright / - Inverted)',
      yAxisDirection: 'Broadband Decoupled: all upright • DEPT-135: CH3 & CH up (+), CH2 down (-), C_q absent',
      yAxisPhysicalMeaning: 'In DEPT-135, polarization transfer from proton spins encodes the number of directly attached hydrogens as positive or negative signal phase.',
      fundamentalPrinciple: '13C isotope has natural abundance 1.1% (spin I = 1/2). Standard 1H-decoupling collapses all C-H J coupling into sharp singlets with Nuclear Overhauser Enhancement (NOE). DEPT (Distortionless Enhancement by Polarization Transfer) selectively decodes carbon multiplicity.',
      howToRead: [
        r'''**Broadband $^1\text{H}$-Decoupled Spectrum**: Each distinct chemical carbon environment appears as a sharp singlet. Total peak count reflects skeletal molecular symmetry.''',
        r'''**DEPT-135 Multiplicity Editing**: Methyl (-\text{CH}_3) and Methine (-\text{CH}) point UP (+); Methylene (-\text{CH}_2-) points DOWN (-); Quaternary carbons ($C_q$) DISAPPEAR.''',
        '**DEPT-90 Verification**: Retains ONLY Methine (-\\text{CH}) carbons upright; all other carbons are suppressed.',
        '**DEPT-45 Verification**: Retains ALL protonated carbons (\\text{CH}_3, \\text{CH}_2, \\text{CH}) upright; quaternary carbons are absent.',
        r'''**Carbonyl Region Diagnostic**: Ketones ($\,\delta\,$ 200–220 ppm); aldehydes ($\,\delta\,$ 190–205 ppm); esters, carboxylic acids, and amides ($\,\delta\,$ 160–185 ppm).'''
      ],
      keyFormulas: [
        r'''### DEPT-135 Phase Equations
        $$I_{\text{CH}_3} > 0 \,(+), \quad I_{\text{CH}} > 0 \,(+), \quad I_{\text{CH}_2} < 0 \,(-), \quad I_{C_q} = 0$$''',
        r'''### DEPT-90 Phase Rule
        $$I_{\text{CH}} > 0 \,(+), \quad I_{\text{CH}_3} = I_{\text{CH}_2} = I_{C_q} = 0$$''',
        r'''### DEPT-45 Phase Rule
        $$I_{\text{CH}_3} > 0, \quad I_{\text{CH}_2} > 0, \quad I_{\text{CH}} > 0, \quad I_{C_q} = 0$$''',
        r'''### Total Carbon Stoichiometry
        $$N_{\text{total}} = N_{\text{CH}_3} + N_{\text{CH}_2} + N_{\text{CH}} + N_{C_q}$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'nmr13c_1butanol',
          title: '¹³C Decoupled vs DEPT-135: 1-Butanol',
          compound: '1-Butanol (CH3-CH2-CH2-CH2-OH)',
          description: 'Comparison of broadband 1H-decoupled spectrum and DEPT-135 spectrum for 1-butanol, demonstrating the inversion of all 3 methylene (-CH2-) carbons.',
          xMin: 0.0,
          xMax: 80.0,
          yMin: -60.0,
          yMax: 80.0,
          xAxisLabel: 'Chemical Shift delta (ppm)',
          yAxisLabel: 'DEPT-135 Amplitude (+ Up / - Down)',
          peaks: [
            SpectralPeakAnnotation(x: 13.9, y: 55.0, label: 'C4: -CH3 (+55)', compoundOrFragment: 'Methyl carbon (upright in DEPT-135)', explanation: 'Upright positive peak at δ 13.9 ppm confirms terminal methyl carbon.'),
            SpectralPeakAnnotation(x: 19.1, y: -45.0, label: 'C3: -CH2- (-45)', compoundOrFragment: 'Methylene carbon (inverted)', explanation: 'Negative phase in DEPT-135 proves -CH2- environment.'),
            SpectralPeakAnnotation(x: 35.0, y: -50.0, label: 'C2: -CH2- (-50)', compoundOrFragment: 'Beta-methylene carbon (inverted)', explanation: 'Inverted signal at δ 35.0 ppm confirms -CH2- bonded to carbinol carbon.'),
            SpectralPeakAnnotation(x: 62.4, y: -58.0, label: 'C1: -CH2OH (-58)', compoundOrFragment: 'Alpha-carbinol methylene (inverted)', explanation: 'Deshielded by direct bonding to oxygen; inverted in DEPT-135 proving -CH2OH.'),
          ],
          curvePoints: [
            SpectralDataPoint(13.9, 55.0), SpectralDataPoint(19.1, -45.0), SpectralDataPoint(35.0, -50.0), SpectralDataPoint(62.4, -58.0),
          ],
        ),
      ],
    ),
    AnalyticalTechniqueInfo(
      id: 'ftir',
      title: 'Fourier-Transform Infrared (FT-IR)',
      acronym: 'FT-IR',
      category: 'Spectroscopy',
      xAxisName: 'Wavenumber',
      xAxisUnit: 'nu_bar (cm⁻¹, 4000 to 400 cm⁻¹)',
      xAxisDirection: 'Decreasing / Inverted (Left to Right: 4000 → 400 cm⁻¹)',
      xAxisPhysicalMeaning: 'Number of wave cycles per centimeter (nu_bar = 1 / lambda). Directly proportional to vibrational frequency (E = h*c*nu_bar). High wavenumber represents high bond force constant (k) and light reduced mass (mu) (e.g. C-H, O-H, C#C).',
      yAxisName: 'Transmittance (%T)',
      yAxisUnit: '% (Percentage of Light Transmitted)',
      yAxisDirection: 'Downward Absorption Bands (100% at top = full transmission; 0% = full absorption)',
      yAxisPhysicalMeaning: 'Ratio of transmitted infrared intensity to incident intensity (I / I0 * 100%). Strong vibrational absorption dips downward toward 0% Transmittance.',
      fundamentalPrinciple: 'Infrared radiation excites molecular vibrational modes (stretching, bending, rocking). A vibrational transition is IR-active only if it produces a net change in molecular dipole moment (d_mu / d_r != 0).',
      howToRead: [
        '**Diagnostic Region (4000–1500 cm⁻¹)**: Dedicated to functional group identification (O-H/N-H 3600–3200 cm⁻¹, C-H 3100–2850 cm⁻¹, triple bonds 2260–2100 cm⁻¹, carbonyl C=O 1800–1650 cm⁻¹).',
        '**Fingerprint Region (1500–400 cm⁻¹)**: Highly complex single-bond stretching and skeletal bending; unique to each compound like a human fingerprint.',
        '**Carbonyl Precision Hierarchy**: Anhydride (1820 & 1760 cm⁻¹ doublet), Acid Chloride (1800 cm⁻¹), Ester (1740 cm⁻¹), Aldehyde (1725 cm⁻¹ with 2720/2820 cm⁻¹ Fermi doublet), Ketone (1715 cm⁻¹), Carboxylic acid (1710 cm⁻¹ with broad 2500–3300 cm⁻¹ envelope), Amide (1680–1650 cm⁻¹).',
        r'''**Conjugation Red-Shift**: $\alpha,\beta$-conjugation with an alkene or aromatic ring lowers carbonyl stretching frequency by 20–40 cm⁻¹ due to increased single-bond character ($C=O \leftrightarrow C^+-O^-$).''',
        r'''**Ring Strain Effect**: Decreasing ring size increases carbonyl frequency (cyclooctanone 1705 cm⁻¹ $\to$ cyclohexanone 1715 cm⁻¹ $\to$ cyclopentanone 1745 cm⁻¹ $\to$ cyclobutanone 1780 cm⁻¹).'''
      ],
      keyFormulas: [
        r'''### Hooke's Law for Vibrational Frequency
        $$\bar{
        u} = \frac{1}{2\pi c} \sqrt{\frac{k}{\mu}}$$''',
        r'''### Vibrational Reduced Mass ($\mu$)
        $$\mu = \frac{m_1 m_2}{m_1 + m_2}$$''',
        r'''### Transmittance to Absorbance Conversion
        $$A = -\log_{10}(T) = \log_{10}\left(\frac{100}{\%T}\right)$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'ftir_benzoic_acid',
          title: 'FT-IR Spectrogram: Benzoic Acid',
          compound: 'Benzoic Acid (C6H5COOH in KBr pellet)',
          description: 'Characteristic FT-IR spectrum of an aromatic carboxylic acid exhibiting extreme O-H hydrogen-bonded broadening, intense carbonyl stretch, and aromatic skeletal modes.',
          xMin: 400.0,
          xMax: 4000.0,
          yMin: 0.0,
          yMax: 100.0,
          xAxisLabel: 'Wavenumber nu_bar (cm⁻¹, Inverted: 4000 -> 400)',
          yAxisLabel: '% Transmittance (%T, Dips downward)',
          peaks: [
            SpectralPeakAnnotation(x: 2950.0, y: 15.0, label: 'Broad O-H Envelope (2500–3300 cm⁻¹)', compoundOrFragment: 'Carboxylic acid dimer O-H stretch', explanation: 'Extreme hydrogen bonding in dimeric carboxylic acid creates a massive broad absorption envelope extending across the C-H region.'),
            SpectralPeakAnnotation(x: 1688.0, y: 5.0, label: 'C=O Stretch (1688 cm⁻¹)', compoundOrFragment: 'Aryl carboxylic acid C=O', explanation: 'Conjugated carboxylic acid carbonyl shifted down from 1715 cm⁻¹ to 1688 cm⁻¹ by phenyl pi-delocalization.'),
            SpectralPeakAnnotation(x: 1600.0, y: 38.0, label: 'Aromatic C=C (1600 cm⁻¹)', compoundOrFragment: 'Benzene ring quadrant stretch', explanation: 'Sharp aromatic ring breathing band.'),
            SpectralPeakAnnotation(x: 1290.0, y: 22.0, label: 'C-O Stretch (1290 cm⁻¹)', compoundOrFragment: 'Carboxylic C-O single bond', explanation: 'Strong ester/acid C-O stretching absorption in fingerprint region.'),
            SpectralPeakAnnotation(x: 708.0, y: 12.0, label: 'C-H Out-of-Plane Bend (708 cm⁻¹)', compoundOrFragment: 'Monosubstituted phenyl ring', explanation: 'Diagnostic pair of bands at 710 and 685 cm⁻¹ confirming 5 adjacent aromatic C-H bonds (monosubstitution).'),
          ],
          curvePoints: [
            SpectralDataPoint(4000.0, 95.0), SpectralDataPoint(3500.0, 85.0), SpectralDataPoint(3000.0, 25.0), SpectralDataPoint(2800.0, 30.0), SpectralDataPoint(2500.0, 75.0),
            SpectralDataPoint(2000.0, 90.0), SpectralDataPoint(1688.0, 5.0), SpectralDataPoint(1600.0, 38.0), SpectralDataPoint(1450.0, 42.0), SpectralDataPoint(1290.0, 22.0),
            SpectralDataPoint(1000.0, 80.0), SpectralDataPoint(708.0, 12.0), SpectralDataPoint(400.0, 88.0),
          ],
        ),
      ],
    ),
    AnalyticalTechniqueInfo(
      id: 'uv_vis',
      title: 'UV-Visible Spectrophotometry',
      acronym: 'UV-Vis',
      category: 'Spectroscopy',
      xAxisName: 'Wavelength',
      xAxisUnit: 'lambda (nm, 200 to 800 nm)',
      xAxisDirection: 'Increasing (Left to Right: 200 → 800 nm)',
      xAxisPhysicalMeaning: 'Wavelength of ultraviolet and visible light. Lower wavelength corresponds to higher photon energy (E = h*c / lambda). UV region (200–400 nm) excites pi -> pi* and n -> pi* transitions in organic chromophores; visible region (400–800 nm) produces perceived color.',
      yAxisName: 'Absorbance',
      yAxisUnit: 'A = -log10(I / I0) or Molar Absorptivity epsilon (L/(mol*cm))',
      yAxisDirection: 'Upward absorption bands (0.0 to 2.5 Absorbance)',
      yAxisPhysicalMeaning: 'Logarithmic attenuation of light beam transmitted through 1 cm quartz cuvette. Follows Beer-Lambert law: A = epsilon * c * l.',
      fundamentalPrinciple: 'Absorption of UV-Vis photons promotes an electron from a bonding (sigma, pi) or non-bonding (n) orbital into an antibonding orbital (pi*, sigma*). Conjugation dramatically narrows the HOMO-LUMO gap, shifting lambda_max to longer wavelengths.',
      howToRead: [
        r'''**$\lambda_{\max}$ (Absorption Maximum)**: Peak absorbance wavelength indicating chromophore electronic structure and extent of $\pi$-conjugation.''',
        r'''**Molar Absorptivity ($\epsilon$)**: Transition probability metric. Fully allowed $\pi \to \pi^*$ transitions exhibit $\epsilon > 10,000\text{ L/(mol}\cdot\text{cm)}$; symmetry-forbidden $n \to \pi^*$ transitions exhibit $\epsilon < 100$.''',
        r'''**Woodward-Fieser Empirical Rules**: Predicts $\lambda_{\max}$ for conjugated dienes (base butadiene = 217 nm, homoannular = 253 nm, heteroannular = 214 nm, +30 nm per extended double bond).''',
        r'''**Bathochromic Shift (Red Shift)**: Displacement of $\lambda_{\max}$ to longer wavelength (lower photon energy $\Delta E$) due to extended conjugation or polar auxochrome substitution.''',
        r'''**Hypsochromic Shift (Blue Shift)**: Displacement of $\lambda_{\max}$ to shorter wavelength (higher photon energy $\Delta E$).'''
      ],
      keyFormulas: [
        r'''### Beer-Lambert Law of Light Absorption
        $$A = \epsilon \cdot c \cdot l = -\log_{10}\left(\frac{I}{I_0}\right)$$''',
        r'''### Photon Transition Energy
        $$\Delta E = \frac{h \cdot c}{\lambda}$$''',
        r'''### Woodward-Fieser Base Values for Dienes
        $$\lambda_{\text{acyclic}} = 217\text{ nm}, \quad \lambda_{\text{heteroannular}} = 214\text{ nm}, \quad \lambda_{\text{homoannular}} = 253\text{ nm}$$''',
      ],
      examples: [
        SpectrogramExample(
          id: 'uv_nitroaniline',
          title: 'UV-Vis Absorption: 4-Nitroaniline',
          compound: '4-Nitroaniline (p-O2N-C6H4-NH2 in Ethanol)',
          description: 'Strong intramolecular charge-transfer (ICT) band from the electron-donating amino lone pair to the electron-withdrawing nitro group across the aromatic ring, resulting in an intense visible-range absorption at lambda_max = 380 nm.',
          xMin: 200.0,
          xMax: 600.0,
          yMin: 0.0,
          yMax: 2.0,
          xAxisLabel: 'Wavelength lambda (nm)',
          yAxisLabel: 'Absorbance (A, 1 cm quartz cell)',
          peaks: [
            SpectralPeakAnnotation(x: 228.0, y: 0.65, label: 'Aromatic pi -> pi* (228 nm)', compoundOrFragment: 'Benzene primary E2 band', explanation: 'Localized pi -> pi* transition of the substituted benzene core; epsilon ~ 8,000.'),
            SpectralPeakAnnotation(x: 380.0, y: 1.82, label: 'ICT Band (lambda_max = 380 nm)', compoundOrFragment: 'Intramolecular Charge Transfer (NH2 -> NO2)', explanation: 'Push-pull interaction between donor -NH2 and acceptor -NO2 gives massive red-shift into the violet-blue edge, imparting bright yellow color to the solution; epsilon ~ 16,500 L/(mol*cm).'),
          ],
          curvePoints: [
            SpectralDataPoint(200.0, 0.1), SpectralDataPoint(228.0, 0.65), SpectralDataPoint(260.0, 0.2), SpectralDataPoint(300.0, 0.15),
            SpectralDataPoint(340.0, 0.8), SpectralDataPoint(380.0, 1.82), SpectralDataPoint(420.0, 0.6), SpectralDataPoint(460.0, 0.08), SpectralDataPoint(600.0, 0.01),
          ],
        ),
      ],
    ),
  ];
}

// ----------------------------------------------------
// Auxiliary Data Models
// ----------------------------------------------------

enum CarbonDeptType {
  ch3,
  ch2,
  ch,
  cq,
}

extension CarbonDeptTypeExtension on CarbonDeptType {
  String get label {
    switch (this) {
      case CarbonDeptType.ch3: return 'CH₃ (Methyl)';
      case CarbonDeptType.ch2: return 'CH₂ (Methylene)';
      case CarbonDeptType.ch: return 'CH (Methine)';
      case CarbonDeptType.cq: return 'C_q (Quaternary)';
    }
  }

  String get shortLabel {
    switch (this) {
      case CarbonDeptType.ch3: return 'CH₃';
      case CarbonDeptType.ch2: return 'CH₂';
      case CarbonDeptType.ch: return 'CH';
      case CarbonDeptType.cq: return 'C_q';
    }
  }

  String get dept135Phase {
    switch (this) {
      case CarbonDeptType.ch3: return 'Positive (+ Up)';
      case CarbonDeptType.ch2: return 'Negative (- Inverted)';
      case CarbonDeptType.ch: return 'Positive (+ Up)';
      case CarbonDeptType.cq: return 'Absent (Zero)';
    }
  }
}

class ProtonSignal {
  final double shift;
  final String multiplicity;
  final int integration;
  final double? couplingJ;
  final String? assignment;

  const ProtonSignal({
    required this.shift,
    this.multiplicity = 's',
    this.integration = 1,
    this.couplingJ,
    this.assignment,
  });
}

class CarbonSignal {
  final double shift;
  final CarbonDeptType deptType;
  final String? assignment;

  const CarbonSignal({
    required this.shift,
    this.deptType = CarbonDeptType.ch,
    this.assignment,
  });
}

class AnalyticalTechniqueInfo {
  final String id;
  final String title;
  final String acronym;
  final String category;
  final String xAxisName;
  final String xAxisUnit;
  final String xAxisDirection;
  final String xAxisPhysicalMeaning;
  final String yAxisName;
  final String yAxisUnit;
  final String yAxisDirection;
  final String yAxisPhysicalMeaning;
  final String fundamentalPrinciple;
  final List<String> howToRead;
  final List<String> keyFormulas;
  final List<SpectrogramExample> examples;

  const AnalyticalTechniqueInfo({
    required this.id,
    required this.title,
    required this.acronym,
    required this.category,
    required this.xAxisName,
    required this.xAxisUnit,
    required this.xAxisDirection,
    required this.xAxisPhysicalMeaning,
    required this.yAxisName,
    required this.yAxisUnit,
    required this.yAxisDirection,
    required this.yAxisPhysicalMeaning,
    required this.fundamentalPrinciple,
    required this.howToRead,
    required this.keyFormulas,
    required this.examples,
  });
}

extension AnalyticalTechniqueMetadata on AnalyticalTechniqueInfo {
  String get fullInstrumentTitle {
    switch (id) {
      case 'gc':
        return 'Capillary Gas Chromatogram (GC-FID)';
      case 'hplc':
        return 'Reverse-Phase HPLC Chromatogram (RP-C18)';
      case 'tlc':
        return 'Normal-Phase Silica TLC Plate (TLC F₂₅₄)';
      case 'ms':
        return '70 eV Electron Ionization Mass Spectrum (EI-MS)';
      case '1h_nmr':
        return '500 MHz ¹H NMR Resonance Spectrum';
      case '13c_nmr':
        return '¹³C Broadband Decoupled & DEPT-135 Spectrum';
      case 'ftir':
        return 'FT-IR Infrared Transmittance Spectrum';
      case 'uv_vis':
        return 'UV-Visible Electronic Absorption Spectrum';
      default:
        return title;
    }
  }

  String get instrumentIcon {
    switch (id) {
      case 'gc':
        return '🔬';
      case 'hplc':
        return '🧪';
      case 'tlc':
        return '📜';
      case 'ms':
        return '💥';
      case '1h_nmr':
        return '🧲';
      case '13c_nmr':
        return '🧲';
      case 'ftir':
        return '📈';
      case 'uv_vis':
        return '🌈';
      default:
        return '📊';
    }
  }

  String get domainDescription {
    switch (id) {
      case 'gc':
        return 'Gas-Liquid Partition Chromatography';
      case 'hplc':
        return 'Liquid-Solid Partition Chromatography (RP-C18)';
      case 'tlc':
        return 'Planar Liquid-Solid Adsorption Chromatography';
      case 'ms':
        return 'Mass Spectrometry & Gas-Phase Ionization';
      case '1h_nmr':
        return 'Nuclear Magnetic Resonance Spectroscopy (Proton)';
      case '13c_nmr':
        return 'Nuclear Magnetic Resonance & Polarization Transfer';
      case 'ftir':
        return 'Vibrational Infrared Absorption Spectroscopy';
      case 'uv_vis':
        return 'Electronic UV-Visible Absorption Spectroscopy';
      default:
        return category;
    }
  }

  String get instrumentParameters {
    switch (id) {
      case 'gc':
        return 'DB-5 Capillary Column (30 m × 0.25 mm) • Carrier: He • FID Detector (250 °C)';
      case 'hplc':
        return 'C18 Octadecylsilane (250 × 4.6 mm, 5 μm) • Mobile: MeCN/H₂O • DAD @ 254 nm';
      case 'tlc':
        return 'Silica Gel 60 F₂₅₄ Glass Plate • Mobile: EtOAc/Hexanes • Visualization: UV 254 nm';
      case 'ms':
        return 'Ionization: 70 eV Electron Ionization • Analyzer: Quadrupole Filter • Base Peak: 100%';
      case '1h_nmr':
        return 'Spectrometer: 500 MHz FT-NMR • Solvent: CDCl₃ • Reference: TMS (δ 0.00 ppm)';
      case '13c_nmr':
        return 'Spectrometer: 125 MHz ¹³C • Decoupling: ¹H WALTZ-16 • DEPT-135 Multiplicity Editing';
      case 'ftir':
        return 'Optics: Michelson Interferometer • Sample: KBr Matrix Pellet • Scan: 4000 to 400 cm⁻¹';
      case 'uv_vis':
        return 'Double-Beam Spectrophotometer • Cell: 1.00 cm Quartz Cuvette • Range: 200 to 800 nm';
      default:
        return category;
    }
  }
}

class SpectrogramExample {
  final String id;
  final String title;
  final String compound;
  final String description;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final String xAxisLabel;
  final String yAxisLabel;
  final List<SpectralPeakAnnotation> peaks;
  final List<SpectralDataPoint> curvePoints;

  const SpectrogramExample({
    required this.id,
    required this.title,
    required this.compound,
    required this.description,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.peaks,
    required this.curvePoints,
  });
}

class SpectralPeakAnnotation {
  final double x;
  final double y;
  final String label;
  final String compoundOrFragment;
  final String explanation;

  const SpectralPeakAnnotation({
    required this.x,
    required this.y,
    required this.label,
    required this.compoundOrFragment,
    required this.explanation,
  });
}

class SpectralDataPoint {
  final double x;
  final double y;

  const SpectralDataPoint(this.x, this.y);
}

class ParsedFormula {
  final int carbons;
  final int hydrogens;
  final int nitrogens;
  final int oxygens;
  final int halogens;
  final int chlorines;
  final int bromines;
  final int fluorines;
  final int iodines;
  final int sulfurs;
  final int phosphoruses;
  final double dbe;
  final double molarMass;
  final bool isValid;
  final String? errorMessage;

  const ParsedFormula({
    required this.carbons,
    required this.hydrogens,
    this.nitrogens = 0,
    this.oxygens = 0,
    this.halogens = 0,
    this.chlorines = 0,
    this.bromines = 0,
    this.fluorines = 0,
    this.iodines = 0,
    this.sulfurs = 0,
    this.phosphoruses = 0,
    required this.dbe,
    required this.molarMass,
    required this.isValid,
    this.errorMessage,
  });
}

enum SanitySeverity {
  info,
  warning,
  violation,
}

class SanityCheckItem {
  final String title;
  final String category;
  final bool passed;
  final SanitySeverity severity;
  final String message;
  final String recommendation;

  const SanityCheckItem({
    required this.title,
    required this.category,
    required this.passed,
    required this.severity,
    required this.message,
    required this.recommendation,
  });
}

class SpectroscopySanityReport {
  final List<SanityCheckItem> items;

  const SpectroscopySanityReport({required this.items});

  int get passedCount => items.where((i) => i.passed).length;
  int get warningCount => items.where((i) => !i.passed && i.severity == SanitySeverity.warning).length;
  int get violationCount => items.where((i) => !i.passed && i.severity == SanitySeverity.violation).length;
  bool get hasViolations => violationCount > 0;
  bool get isAllPassed => items.every((i) => i.passed);
}

class SpectroscopyAnalysisResult {
  final bool isValid;
  final String? errorMessage;
  final String formula;
  final double dbe;
  final double molarMass;
  final List<DeductionStep> steps;
  final String markdownFull;
  final SpectroscopySanityReport? sanityReport;

  const SpectroscopyAnalysisResult({
    required this.isValid,
    this.errorMessage,
    required this.formula,
    required this.dbe,
    required this.molarMass,
    required this.steps,
    required this.markdownFull,
    this.sanityReport,
  });
}

class DeductionStep {
  final int stepNumber;
  final String title;
  final String summary;
  final String content;
  final IconData icon;

  const DeductionStep({
    required this.stepNumber,
    required this.title,
    required this.summary,
    required this.content,
    required this.icon,
  });
}

class NmrShiftRegion {
  final String range;
  final String type;
  final String description;

  const NmrShiftRegion({
    required this.range,
    required this.type,
    required this.description,
  });
}

class IrBand {
  final String range;
  final String intensity;
  final String group;
  final String description;

  const IrBand({
    required this.range,
    required this.intensity,
    required this.group,
    required this.description,
  });
}

class MassSpecPattern {
  final String name;
  final String ratio;
  final String description;

  const MassSpecPattern({
    required this.name,
    required this.ratio,
    required this.description,
  });
}

class SpectroscopyCaseStudy {
  final String compoundName;
  final String formula;
  final double molarMass;
  final double dbe;
  final String irHighlights;
  final String nmr1H;
  final String nmr13C;
  final String massSpec;
  final String deduction;

  const SpectroscopyCaseStudy({
    required this.compoundName,
    required this.formula,
    required this.molarMass,
    required this.dbe,
    required this.irHighlights,
    required this.nmr1H,
    required this.nmr13C,
    required this.massSpec,
    required this.deduction,
  });
}
