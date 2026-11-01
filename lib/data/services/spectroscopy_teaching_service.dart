import '../../core/chemistry/spectroscopy_graph_layout.dart';
import '../../core/chemistry/spectroscopy_structure_svg.dart';
import '../../core/chemistry/spectrum_svg_renderer.dart';
import 'spectroscopy_reference_service.dart';
import 'spectroscopy_service.dart';

class StudentDeductionStep {
  const StudentDeductionStep(this.title, this.explanation, this.mscCheckpoint);
  final String title;
  final String explanation;
  final String mscCheckpoint;
}

/// Evidence-linked explanations: reference metadata is never promoted to an
/// observation, and a formula/shift match is never a proof of uniqueness.
class SpectroscopyTeachingService {
  static List<StudentDeductionStep> explain({
    required SpectroscopyAnalysisResult result,
    required Map<SpectrumTechnique, List<SpectrumSignal>> observed,
    SpectroscopyCompoundEntry? reference,
    bool workedReference = false,
  }) {
    final f = SpectroscopyService.parseFormula(result.formula);
    final compound = reference ?? result.supportedCompound;
    List<SpectrumSignal> data(SpectrumTechnique technique) =>
        workedReference && compound != null
        ? SpectroscopyReferenceService.signals(compound, technique)
        : observed[technique] ?? [];
    final h = data(SpectrumTechnique.proton),
        c = data(SpectrumTechnique.carbon);
    final ir = data(SpectrumTechnique.ir), ms = data(SpectrumTechnique.mass);
    String list(List<SpectrumSignal> values, {String unit = 'ppm'}) =>
        values.isEmpty
        ? 'not supplied'
        : '${values.map((s) => s.position.toStringAsFixed(unit == 'ppm' ? 2 : 0)).join(', ')} $unit';
    final carbonyl = c
        .where((s) => s.position >= 185 && s.position <= 230)
        .toList();
    final acidDerivative = c
        .where((s) => s.position >= 160 && s.position < 185)
        .toList();
    final aldehyde = h.any((s) => s.position >= 9.2 && s.position <= 10.5);
    final aromaticH = h
        .where((s) => s.position >= 6.5 && s.position <= 8.5)
        .length;
    final source = workedReference
        ? 'This is a worked reference example for ${compound!.commonName}. These are library values, not measurements from your sample.'
        : 'Use only the formula and peak positions you entered. Missing integration, splitting or peaks remain unknown.';
    final alternatives = compound == null
        ? <String>[]
        : compound.alternativeIsomersRuledOut
              .map((s) => RegExp(r'^\*\*(.*?)\*\*').firstMatch(s)?.group(1))
              .whereType<String>()
              .toList();
    var assembly =
        'We have possible fragments, not their complete connections. Do not draw an exact structure until the atom and unsaturation budgets can be reconciled.';
    if (compound != null) {
      final depiction = SpectroscopyStructureSvg.depict(compound);
      if (depiction.graph case final graph?) {
        final rings = SpectroscopyGraphLayout.rings(graph);
        final shared = rings.any(
          (ring) => rings.any(
            (other) => !identical(ring, other) && ring.any(other.contains),
          ),
        );
        assembly =
            'Test the candidate ${compound.commonName}: ${compound.structure}. The drawing’s atom inventory matches ${result.formula}. ';
        if (!shared &&
            rings.isNotEmpty &&
            rings.every(
              (ring) =>
                  ring.length == 6 &&
                  graph.bonds
                      .where(
                        (b) =>
                            ring.contains(b.atom1Id) &&
                            ring.contains(b.atom2Id),
                      )
                      .every((b) => b.type.name == 'aromatic'),
            )) {
          assembly +=
              '${rings.length} benzene ring(s) use ${rings.length * 4} DBE; the remaining ${result.dbe - rings.length * 4} unit(s) must be explained by other multiple bonds or rings. ';
        } else if (shared) {
          assembly +=
              'Fused rings share atoms and bonds: do not add four DBE separately for every drawn hexagon. Check the overall DBE of ${result.dbe}. ';
        }
        assembly += 'A candidate drawing is a hypothesis, not a consequence of DBE alone.';
      }
    }
    final referenceH = compound == null
        ? <SpectrumSignal>[]
        : SpectroscopyReferenceService.signals(
            compound,
            SpectrumTechnique.proton,
          );
    final assignedReference = referenceH
        .where((s) => s.integration != null)
        .map(
          (s) =>
              'δ ${s.position.toStringAsFixed(2)} (${s.integration}H, ${s.multiplicity}${s.couplingsHz.isEmpty ? '' : ', J ${s.couplingsHz.join('/')} Hz'})',
        )
        .join('; ');
    return [
      StudentDeductionStep(
        'Start with the formula and question',
        '$source\n\n${result.formula} contains ${f.carbons} C, ${f.hydrogens} H, ${f.nitrogens} N, ${f.oxygens} O and ${f.halogens} halogen atom(s). Keep this inventory beside your working. If the formula came from percentages, establish the molecular formula using molar mass first.',
        'Check formula validity, charge state and sample purity. An empirical formula gives an atom ratio; it need not be the molecular formula.',
      ),
      StudentDeductionStep(
        'Calculate DBE: count the unsaturation budget',
        'DBE = (2C + 2 + N − H − X) / 2, where X is the total number of F, Cl, Br and I atoms.\n\nFor your formula: (2 × ${f.carbons} + 2 + ${f.nitrogens} − ${f.hydrogens} − ${f.halogens}) / 2 = **${result.dbe.toStringAsFixed(1)}**.\n\nOne ring or one double bond uses 1 DBE. A triple bond uses 2. A benzene ring uses 4 (three π bonds and one ring). DBE tells us how much unsaturation is possible; it does not prove a benzene ring is present.',
        'The usual expression assumes a neutral, ordinary-valence organic compound. Oxygen does not change this count. Variable-valence S/P species and ions need separate treatment.',
      ),
      StudentDeductionStep(
        'Use IR to suggest functional groups',
        'IR positions: ${list(ir, unit: 'cm⁻¹')}. ${ir.isEmpty ? 'Without IR data, leave functional-group assignments open.' : 'Look for a compatible carbonyl band, an O–H/N–H envelope or a triple-bond band, then check whether the formula contains the required elements.'}\n\nA peak position alone does not tell us whether a band is broad, sharp, strong or weak. Nearby groups overlap, so keep alternatives until NMR supports an assignment.',
        'Conjugation, hydrogen bonding and ring strain shift IR bands. A C=C or C=N band can overlap the lower carbonyl region; C≡C can overlap a nitrile region.',
      ),
      StudentDeductionStep(
        'Use ¹³C NMR to map carbon environments',
        'Carbon shifts: ${list(c)}. ${carbonyl.isNotEmpty
            ? 'The signal(s) ${list(carbonyl)} support an aldehyde/ketone-type carbonyl environment when oxygen and DBE allow it.'
            : acidDerivative.isNotEmpty
            ? 'Signals ${list(acidDerivative)} may indicate acid derivatives or deshielded aryl/heteroaromatic carbons; IR and proton evidence must distinguish them.'
            : c.isEmpty
            ? 'No carbon spectrum was supplied, so the carbon framework is not yet established.'
            : 'Separate alkyl, heteroatom-bearing and unsaturated environments before connecting them.'}\n\nThe number of signals counts distinct environments, not necessarily all carbon atoms: symmetry can make several carbons equivalent.',
        'Chemical shift alone does not identify CH₃, CH₂, CH or quaternary carbon. Use DEPT/APT and HSQC; broadband-decoupled ¹³C peak heights are not reliable carbon counts.',
      ),
      StudentDeductionStep(
        'Use ¹H NMR: shift, integration and splitting',
        'Proton shifts: ${list(h)}. ${aldehyde ? 'A very downfield signal in the formyl region makes an aldehyde a possibility; correlate it with a carbonyl carbon.' : 'No formyl-region signal was entered; an incomplete peak list does not rule an aldehyde out.'} ${aromaticH > 0 ? '$aromaticH entered signal(s) overlap the aromatic/alkene region; compare them with the DBE budget.' : ''}\n\nAsk three questions: Where is the signal (environment)? How many H does its integral represent? What neighbours produce the splitting? Your plain shift list does not supply the last two answers.${assignedReference.isEmpty ? '' : '\n\nExpected reference pattern for ${compound!.commonName}: $assignedReference. Confirm these integrals and multiplicities experimentally; they are not inferred from your typed shifts.'}',
        'The simple n+1 rule applies to first-order coupling with n equivalent spin-½ neighbours. Exchangeable OH/NH, non-equivalent neighbours, overlap and second-order effects require more care. Match J values when assembling coupled groups.',
      ),
      StudentDeductionStep(
        'Check mass evidence and assemble fragments',
        'Entered/reference mass peaks: ${list(ms, unit: 'm/z')}. Compare the nominal molecular ion and isotope cluster with the formula; do not equate an isotope peak with average molar mass. Fragments can suggest subunits, but the same nominal m/z can have several formulas.\n\n$assembly',
        'Use the complete carbon, hydrogen and heteroatom inventory. Avoid double counting atoms shared by fragments. HMBC connects fragments through longer-range correlations; COSY and HSQC help establish local connectivity.',
      ),
      StudentDeductionStep(
        'Challenge the structure with alternative isomers',
        '${alternatives.isEmpty ? 'Consider alternative carbon skeletons, functional-group isomers and substitution positions sharing this formula.' : 'Reference alternatives worth testing: ${alternatives.join('; ')}.'}\n\nFor each candidate, predict a diagnostic difference: a formyl H, methyl singlet, ethyl triplet/quartet, number of carbon environments or aromatic substitution pattern. Reject it only when the required observation is genuinely measured and incompatible.',
        'Do not invent missing coupling constants, infer ortho/meta/para relationships from shifts alone, or claim stereochemistry from these peak lists. A close library match is not an exhaustive isomer search.',
      ),
      StudentDeductionStep(
        'Draw, verify and state the final conclusion',
        result.sanityReport?.hasViolations == true
            ? 'The inputs contain conflicts. Resolve the flagged formula/spectral inconsistencies before assigning an exact structure.'
            : compound == null
            ? 'The evidence does not yet support one exact structure. Keep the functional-group and framework hypotheses, request the missing spectra/integration, and use the comparison tools to narrow them. “Insufficient evidence” is the correct conclusion when the data do not distinguish isomers.'
            : '${workedReference ? 'The selected worked reference is' : 'The supplied evidence supports a tentative library match to'} **${compound.commonName}**, ${compound.structure}. Use **Deduce into Structure** to reveal its formula-checked SVG. Finally account for every observed signal and every DBE, and list what still requires confirmation.',
        'An MSc answer should connect each conclusion to evidence, state unresolved ambiguity and propose a discriminating experiment. The SVG validates a candidate’s atom inventory, not unique experimental identity.',
      ),
    ];
  }
}
