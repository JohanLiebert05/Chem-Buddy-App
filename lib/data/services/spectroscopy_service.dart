/// MSc Chemistry Spectroscopy Service
/// Covers 1H NMR, 13C NMR, FT-IR diagnostic frequencies, Mass Spectrometry fragmentation,
/// and automated structure deduction algorithms.
class SpectroscopyService {
  // 1. Calculate Degree of Unsaturation (Double Bond Equivalents - DBE / IHD)
  // Formula: DBE = C + 1 - (H / 2) - (Halogens / 2) + (N / 2)
  static double calculateDBE({
    required int carbons,
    required int hydrogens,
    int nitrogens = 0,
    int halogens = 0,
    int oxygens = 0,
  }) {
    return (carbons + 1) - (hydrogens / 2.0) - (halogens / 2.0) + (nitrogens / 2.0);
  }

  // 2. 1H NMR Characteristic Chemical Shift Regions (ppm)
  static const List<NmrShiftRegion> protonNmrRegions = [
    NmrShiftRegion(
      range: '0.8 – 1.0 ppm',
      type: 'Primary Aliphatic (R-CH3)',
      description: 'Methyl protons attached to sp3 carbon; typically sharp triplet if adjacent to -CH2-.',
    ),
    NmrShiftRegion(
      range: '1.2 – 1.4 ppm',
      type: 'Secondary Aliphatic (R-CH2-R)',
      description: 'Methylene protons in saturated alkyl chains.',
    ),
    NmrShiftRegion(
      range: '1.4 – 1.7 ppm',
      type: 'Tertiary Aliphatic (R3-CH)',
      description: 'Methine proton attached to three alkyl groups.',
    ),
    NmrShiftRegion(
      range: '2.0 – 2.4 ppm',
      type: 'Allylic / Protons adjacent to Carbonyl (CH3-C=O, -CH2-C=C)',
      description: 'Deshielded by adjacent pi-system (alpha to ketone, aldehyde, ester, or alkene).',
    ),
    NmrShiftRegion(
      range: '2.2 – 2.9 ppm',
      type: 'Benzylic Protons (Ar-CH2-R, Ar-CH3)',
      description: 'Protons on carbon directly attached to aromatic ring.',
    ),
    NmrShiftRegion(
      range: '3.2 – 4.0 ppm',
      type: 'Protons adjacent to Oxygen / Halogen (-CH2-O-R, -CH2-Cl)',
      description: 'Strongly deshielded by electronegative heteroatom (ethers, alcohols, alkyl halides).',
    ),
    NmrShiftRegion(
      range: '4.5 – 6.5 ppm',
      type: 'Vinylic / Olefinic Protons (=C-H)',
      description: 'Protons on sp2 alkene carbon; show characteristic cis (J = 7–11 Hz) and trans (J = 12–18 Hz) coupling.',
    ),
    NmrShiftRegion(
      range: '6.5 – 8.5 ppm',
      type: 'Aromatic Protons (Ar-H)',
      description: 'Strongly deshielded by aromatic ring current. Multiplicity indicates ortho, meta, para substitution patterns.',
    ),
    NmrShiftRegion(
      range: '9.0 – 10.0 ppm',
      type: 'Aldehyde Proton (-CH=O)',
      description: 'Distinctive low-field sharp singlet or doublet (J = 1–3 Hz from alpha-protons).',
    ),
    NmrShiftRegion(
      range: '10.5 – 13.0 ppm',
      type: 'Carboxylic Acid Proton (-COOH)',
      description: 'Broad singlet at very low field due to strong hydrogen bonding; disappears with D2O exchange.',
    ),
    NmrShiftRegion(
      range: '0.5 – 5.0 ppm (variable)',
      type: 'Alcohol / Amine / Thiol (R-OH, R-NH2, R-SH)',
      description: 'Variable position depending on concentration and hydrogen bonding; D2O shake causes disappearance.',
    ),
  ];

  // 3. 13C NMR Characteristic Chemical Shift Regions (ppm)
  static const List<NmrShiftRegion> carbonNmrRegions = [
    NmrShiftRegion(
      range: '0 – 50 ppm',
      type: 'Aliphatic sp3 Carbons (C-C, C-H)',
      description: 'Methyl, methylene, and methine carbons in saturated hydrocarbons.',
    ),
    NmrShiftRegion(
      range: '50 – 90 ppm',
      type: 'Carbons attached to Heteroatoms (C-O, C-N, C-X)',
      description: 'Carbons bonded to oxygen (alcohols, ethers) or nitrogen (amines).',
    ),
    NmrShiftRegion(
      range: '65 – 90 ppm',
      type: 'Alkyne sp Carbons (C#C)',
      description: 'Shielded by cylindrical pi-electron cloud.',
    ),
    NmrShiftRegion(
      range: '100 – 150 ppm',
      type: 'Alkene & Aromatic sp2 Carbons (C=C, Ar-C)',
      description: 'Aromatic carbons typically 120–140 ppm; quaternary ipso-carbons have lower intensity.',
    ),
    NmrShiftRegion(
      range: '160 – 185 ppm',
      type: 'Esters, Amides, Carboxylic Acids (-COO-, -CONH-)',
      description: 'Carbonyl carbons with heteroatom resonance stabilization.',
    ),
    NmrShiftRegion(
      range: '190 – 220 ppm',
      type: 'Aldehydes & Ketones (R-CHO, R2-C=O)',
      description: 'Highly deshielded carbonyl carbon with no heteroatom conjugation (ketones ~205 ppm, aldehydes ~195 ppm).',
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
      intensity: 'Medium',
      group: 'N-H stretch',
      description: 'Primary amines show doublet (symmetric/antisymmetric); secondary amines show singlet.',
    ),
    IrBand(
      range: '3000 – 3100 cm⁻¹',
      intensity: 'Medium',
      group: 'sp² C-H stretch (Ar-H, =C-H)',
      description: 'Protons on alkene or aromatic rings; diagnostic when just above 3000 cm⁻¹.',
    ),
    IrBand(
      range: '2850 – 2960 cm⁻¹',
      intensity: 'Strong',
      group: 'sp³ C-H stretch',
      description: 'Saturated aliphatic C-H stretching; diagnostic when just below 3000 cm⁻¹.',
    ),
    IrBand(
      range: '2720 & 2820 cm⁻¹',
      intensity: 'Medium (Fermi Doublet)',
      group: 'Aldehyde C-H stretch',
      description: 'Diagnostic Fermi resonance doublet confirming aldehyde alongside carbonyl.',
    ),
    IrBand(
      range: '2210 – 2260 cm⁻¹',
      intensity: 'Medium / Sharp',
      group: 'C#N stretch (Nitrile)',
      description: 'Sharp, distinct band characteristic of aliphatic and aromatic nitriles.',
    ),
    IrBand(
      range: '1735 – 1750 cm⁻¹',
      intensity: 'Very Strong',
      group: 'Ester Carbonyl (C=O)',
      description: 'Higher frequency than ketones due to -I inductive effect of adjacent oxygen.',
    ),
    IrBand(
      range: '1705 – 1725 cm⁻¹',
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
      nmr1H: 'δ 2.6 (s, 3H, -COCH3); δ 7.4 – 7.6 (m, 3H, meta & para Ar-H); δ 7.9 – 8.0 (d, 2H, ortho Ar-H)',
      nmr13C: 'δ 26.6 (CH3); δ 128.3, 128.6, 133.1 (Ar-CH); δ 137.1 (ipso Ar-C); δ 198.1 (C=O)',
      massSpec: 'm/z 120 (M⁺, 30%), m/z 105 (base peak, loss of •CH3 -> [Ph-C#O]⁺), m/z 77 ([C6H5]⁺)',
      deduction: '1. DBE = 8 + 1 - 4 = 5 (Benzene ring = 4, carbonyl = 1).\n2. IR 1685 cm⁻¹ shows conjugated ketone.\n3. 1H NMR 2.6 ppm (3H, s) confirms acetyl group attached directly to phenyl ring.\n4. MS m/z 105 base peak confirms stable benzoyl cation.',
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
      deduction: '1. DBE = 9 + 1 - 5.5 + 0.5 = 5 (1 benzene ring + 1 ester C=O).\n2. IR doublet at 3420 & 3340 cm⁻¹ confirms primary aromatic amine (-NH2).\n3. 1H NMR shows classic para-disubstituted A2B2 doublet of doublets at 6.64 and 7.85 ppm (J = 8.7 Hz).\n4. Triplet-quartet pattern (1.35 & 4.30 ppm) confirms ethyl ester (-OCH2CH3).',
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
      deduction: '1. DBE = 3 + 1 - 3.5 - 0.5 = 0 (Fully saturated).\n2. MS shows twin molecular ions of equal intensity at m/z 122 and 124, proving presence of a single bromine atom.\n3. 1H NMR triplet at 3.38 ppm (2H) is deshielded by bromine.\n4. Sextet at 1.90 ppm (coupling with 3 protons on methyl and 2 on -CH2Br) confirms linear propyl chain.',
    ),
  ];

  // 7. Structural Deduction Helper
  static String analyzeUserSpectra({
    String? formula,
    List<double>? nmrPeaks,
    List<double>? irPeaks,
    List<double>? msPeaks,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('### Academic Spectroscopy Interpretation Walkthrough\n');

    // Formula DBE analysis
    if (formula != null && formula.trim().isNotEmpty) {
      final f = formula.trim().toUpperCase();
      buffer.writeln('#### 1. Degrees of Unsaturation (DBE / IHD)');
      buffer.writeln('Formula: **$f**');
      // Simple regex parse for C, H, N, O, Halogen
      final cMatch = RegExp(r'C(\d*)').firstMatch(f);
      final hMatch = RegExp(r'H(\d*)').firstMatch(f);
      final nMatch = RegExp(r'N(\d*)').firstMatch(f);
      final clMatch = RegExp(r'CL(\d*)').firstMatch(f);
      final brMatch = RegExp(r'BR(\d*)').firstMatch(f);

      final c = int.tryParse(cMatch?.group(1)?.isEmpty == true ? '1' : (cMatch?.group(1) ?? '0')) ?? 0;
      final h = int.tryParse(hMatch?.group(1)?.isEmpty == true ? '1' : (hMatch?.group(1) ?? '0')) ?? 0;
      final n = int.tryParse(nMatch?.group(1)?.isEmpty == true ? '1' : (nMatch?.group(1) ?? '0')) ?? 0;
      final x = (int.tryParse(clMatch?.group(1)?.isEmpty == true ? '1' : (clMatch?.group(1) ?? '0')) ?? 0) +
                (int.tryParse(brMatch?.group(1)?.isEmpty == true ? '1' : (brMatch?.group(1) ?? '0')) ?? 0);

      if (c > 0) {
        final dbe = calculateDBE(carbons: c, hydrogens: h, nitrogens: n, halogens: x);
        buffer.writeln('- **Calculated DBE**: `$dbe`');
        if (dbe >= 4.0) {
          buffer.writeln(r'- **DBE $\ge 4$ strongly indicates an aromatic benzene ring** (3 double bonds + 1 ring = 4).');
        } else if (dbe == 1.0) {
          buffer.writeln('- **DBE = 1 indicates either 1 double bond (C=C or C=O) or 1 aliphatic ring**.');
        } else if (dbe == 0.0) {
          buffer.writeln('- **DBE = 0 indicates an acyclic, fully saturated compound**.');
        }

      }
      buffer.writeln();
    }

    // IR analysis
    if (irPeaks != null && irPeaks.isNotEmpty) {
      buffer.writeln('#### 2. FT-IR Functional Group Diagnostics');
      for (final peak in irPeaks) {
        final matched = irCharacteristicBands.where((b) {
          final rangeParts = b.range.replaceAll('cm⁻¹', '').replaceAll(' ', '').split('–');
          if (rangeParts.length == 2) {
            final low = double.tryParse(rangeParts[0]) ?? 0;
            final high = double.tryParse(rangeParts[1]) ?? 9999;
            return peak >= (low - 30) && peak <= (high + 30);
          }
          return false;
        }).toList();

        if (matched.isNotEmpty) {
          buffer.writeln('- **$peak cm⁻¹**: ${matched.map((m) => '${m.group} (${m.intensity})').join(' OR ')}');
        } else {
          buffer.writeln('- **$peak cm⁻¹**: Saturated skeleton / fingerprint band.');
        }
      }
      buffer.writeln();
    }

    // NMR analysis
    if (nmrPeaks != null && nmrPeaks.isNotEmpty) {
      buffer.writeln('#### 3. ¹H NMR Chemical Shift Assignment');
      for (final p in nmrPeaks) {
        final matched = protonNmrRegions.where((r) {
          final parts = r.range.replaceAll('ppm', '').replaceAll(' ', '').split('–');
          if (parts.length == 2) {
            final low = double.tryParse(parts[0]) ?? 0;
            final high = double.tryParse(parts[1]) ?? 20;
            return p >= (low - 0.2) && p <= (high + 0.2);
          }
          return false;
        }).toList();

        if (matched.isNotEmpty) {
          buffer.writeln('- **δ ${p.toStringAsFixed(2)} ppm**: ${matched.first.type}');
        } else {
          buffer.writeln('- **δ ${p.toStringAsFixed(2)} ppm**: Aliphatic / shielded environment.');
        }
      }
      buffer.writeln();
    }

    // Mass Spec analysis
    if (msPeaks != null && msPeaks.isNotEmpty) {
      buffer.writeln('#### 4. Mass Spectrometry Fragment Diagnostics');
      for (final m in msPeaks) {
        if (m == 91) {
          buffer.writeln(r'- **m/z 91**: Diagnostic Tropylium cation $[\text{C}_7\text{H}_7]^+$ (indicates benzyl/alkylbenzene group).');
        } else if (m == 77) {
          buffer.writeln(r'- **m/z 77**: Phenyl cation $[\text{C}_6\text{H}_5]^+$ (unsubstituted phenyl ring).');
        } else if (m == 43) {
          buffer.writeln(r'- **m/z 43**: Acetylium $[\text{CH}_3\text{CO}]^+$ or propyl cation $[\text{C}_3\text{H}_7]^+$.');
        } else if (m == 105) {
          buffer.writeln(r'- **m/z 105**: Benzoyl cation $[\text{C}_6\text{H}_5\text{CO}]^+$ (benzoyl substituent).');
        } else {
          buffer.writeln('- **m/z $m**: Molecular fragment or cluster peak.');
        }
      }

      buffer.writeln();
    }

    buffer.writeln('#### 5. Recommended Structural Hypothesis');
    buffer.writeln('Combine the DBE count with the highest-field/lowest-field NMR signals to propose candidate constitutional isomers.');

    return buffer.toString();
  }
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
