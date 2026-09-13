// Generated postgraduate MSc Chemistry reactions library
// Contains 10 postgraduate mechanisms with 2D vector schematics and 3D molecular structures.

import '../models/reaction_models.dart';
import '../../core/widgets/molecule_3d/molecule_3d_models.dart';

class PostgraduateReactionData {
  PostgraduateReactionData._();

  static final List<ReactionMechanism> mechanisms = [
    ReactionMechanism(
      id: 'sharpless_epoxidation',
      name: 'Sharpless Asymmetric Epoxidation',
      aliases: ['Sharpless Epoxidation', 'Katsuki-Sharpless Epoxidation', 'Enantioselective Epoxidation'],
      category: ReactionCategory.stereochemistry,
      summary:
          r'''Catalytic enantioselective epoxidation of primary and secondary allylic alcohols to chiral 2,3-epoxy alcohols using titanium tetraisopropoxide $\text{Ti}(\text{O-}i\text{-Pr})_4$, optically pure diethyl tartrate ((+) or (-)-DET), and tert-butyl hydroperoxide ($t\text{-BuOOH}$). Governed by the Katsuki-Sharpless stereochemical mnemonic yielding >90% ee.''',
      reactants: r'''Allylic alcohol ($\text{R-CH=CH-CH}_2\text{OH}$), tert-Butyl hydroperoxide ($t\text{-BuOOH}$)''',
      reagentsAndConditions: r'''$\text{Ti}(\text{O-}i\text{-Pr})_4$ (5-10 mol%), (+)- or (-)-Diethyl tartrate (DET, 10-12 mol%), 4Å Molecular Sieves, $\text{CH}_2\text{Cl}_2$, $-20^\circ\text{C}$''',
      products: r'''Chiral 2,3-epoxy alcohol (up to >98% ee)''',
      regioselectivity: r'''Exclusively epoxidizes allylic alkenes. Isolated, non-allylic double bonds in polyenes remain completely untouched due to lack of Ti-alkoxide coordination.''',
      stereochemistry: r'''Enantiofacial delivery dictated by tartrate chirality (Katsuki-Sharpless mnemonic): with allylic alcohol drawn with hydroxymethyl group at bottom right, (+)-DET directs oxygen transfer from the Re (bottom) face, while (-)-DET directs from the Si (top) face.''',
      drivingForce: r'''Assembly of a dynamic C2-symmetric dimeric titanate-tartrate chiral pocket $[\text{Ti}_2(\text{DET})_2(\text{O-}i\text{-Pr})_4]$ coordinating both the allylic alcohol and tert-butyl peroxide, positioning the peroxide oxygen for low-activation-energy electrophilic delivery.''',
      representativeExample: r'''Asymmetric epoxidation of geraniol to (2R,3R)-epoxygeraniol in 95% ee using (+)-DET.''',
      keyApplications: [
        r'''Key chiral building block in total synthesis of macrolides, polyketides, and pheromones.''',
        r'''Kinetic resolution of racemic secondary allylic alcohols (one enantiomer epoxidizes up to 100x faster).''',
      ],
      limitations: [
        r'''Strictly requires an allylic alcohol moiety; unfunctionalized alkenes and homoallylic alcohols fail or show very poor ee.''',
        r'''Requires strictly anhydrous conditions and 4Å molecular sieves to prevent catalyst deactivation.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Dimeric Chiral Titanate Catalyst Assembly',
          description: r'''Ligand exchange between $\text{Ti}(\text{O-}i\text{-Pr})_4$ and diethyl tartrate (DET) establishes a dynamic $C_2$-symmetric bimetallic dimer $[\text{Ti}_2(\text{DET})_2(\text{O-}i\text{-Pr})_4]$ as the active catalytic template.''',
          curvedArrowNotes: r'''Nucleophilic attack of tartrate hydroxyl groups onto titanium with displacement of isopropanol ligands.''',
          intermediate: r'''$[\text{Ti}_2(\text{DET})_2(\text{O-}i\text{-Pr})_4]$ Dimeric Chiral Complex''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Catalyst Pre-Assembly (Ligand Exchange)</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Ti(O-i-Pr)4 + (+)-DET in CH2Cl2 generates dynamic dimeric chiral template</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="210" cy="130" r="18" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="210" y="135" fill="#38BDF8" font-size="12" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ti</text>
          <circle cx="390" cy="130" r="18" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="390" y="135" fill="#38BDF8" font-size="12" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ti</text>
          <path d="M 226 122 Q 300 85 374 122" fill="none" stroke="#A855F7" stroke-width="2.5"/>
          <text x="300" y="85" fill="#A855F7" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">(+)-DET Bridge</text>
          <path d="M 226 138 Q 300 175 374 138" fill="none" stroke="#A855F7" stroke-width="2.5"/>
          <text x="300" y="195" fill="#A855F7" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">(+)-DET Bridge</text>
          <line x1="195" y1="118" x2="140" y2="90"/>
          <text x="110" y="90" fill="#94A3B8" font-size="11" font-family="sans-serif">OiPr</text>
          <line x1="195" y1="142" x2="140" y2="170"/>
          <text x="110" y="175" fill="#94A3B8" font-size="11" font-family="sans-serif">OiPr</text>
          <line x1="405" y1="118" x2="460" y2="90"/>
          <text x="480" y="90" fill="#94A3B8" font-size="11" font-family="sans-serif">OiPr</text>
          <line x1="405" y1="142" x2="460" y2="170"/>
          <text x="480" y="175" fill="#94A3B8" font-size="11" font-family="sans-serif">OiPr</text>
        </g>
        <rect x="225" y="205" width="200" height="22" rx="4" fill="#0F172A" stroke="#334155"/>
        <text x="325" y="220" fill="#38BDF8" font-size="11" text-anchor="middle" font-family="sans-serif">C2-Symmetric Dimer [Ti(DET)(OiPr)2]2</text>
        
  <g id="electron-arrows">
    
        <path d="M 125 105 Q 160 115 190 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        <path d="M 470 105 Q 435 115 410 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Substrate & Peroxide Coordination in Chiral Pocket',
          description: r'''The allylic alcohol and tert-butyl hydroperoxide displace remaining isopropoxide ligands, binding to adjacent titanium atoms in a rigid, chiral, bidentate coordination sphere.''',
          curvedArrowNotes: r'''Coordination of allylic alkoxide and alkylperoxo ligands to Ti centers locks conformational flexibility.''',
          intermediate: r'''$[\text{Ti}_2(\text{DET})_2(t\text{-BuOO})(\text{OCH}_2\text{CH=CHR})]$ Ternary Complex''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Substrate & Peroxide Coordination</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Allylic alcohol & t-BuOOH displace isopropoxides into rigid chiral pocket</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="230" cy="130" r="16" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="230" y="135" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ti</text>
          <line x1="214" y1="130" x2="165" y2="130"/>
          <text x="155" y="134" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">O</text>
          <line x1="145" y1="130" x2="110" y2="130"/>
          <line x1="110" y1="130" x2="80" y2="105"/>
          <line x1="80" y1="105" x2="40" y2="105"/>
          <line x1="80" y1="100" x2="40" y2="100"/>
          <text x="25" y="106" fill="#F8FAFC" font-size="11" font-family="sans-serif">R</text>
          <circle cx="390" cy="130" r="16" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="390" y="135" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ti</text>
          <line x1="406" y1="130" x2="455" y2="130"/>
          <text x="465" y="134" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">O</text>
          <line x1="478" y1="130" x2="510" y2="130"/>
          <text x="520" y="134" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">O</text>
          <line x1="535" y1="130" x2="575" y2="130"/>
          <text x="590" y="134" fill="#F8FAFC" font-size="11" font-weight="bold" font-family="sans-serif">t-Bu</text>
          <path d="M 244 120 Q 310 80 376 120" fill="none" stroke="#A855F7" stroke-width="2.5"/>
          <text x="310" y="75" fill="#A855F7" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">(+)-DET Chiral Pocket</text>
          <path d="M 515 120 Q 300 35 70 95" fill="none" stroke="#F59E0B" stroke-width="1.8" stroke-dasharray="4,3"/>
          <text x="290" y="45" fill="#F59E0B" font-size="10.5" font-weight="bold" text-anchor="middle" font-family="sans-serif">Electrophilic Oxygen Transfer Vector</text>
        </g>
        
  <g id="electron-arrows">
    
        <path d="M 75 92 Q 280 25 510 115" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Enantiospecific Oxygen Transfer & Product Release',
          description: r'''Electrophilic oxygen of the coordinated peroxide is transferred intramolecularly to the coordinated alkene face dictated by DET chirality. Subsequent ligand exchange regenerates catalyst.''',
          curvedArrowNotes: r'''Curved arrow from alkene $\pi$-bond onto electrophilic oxygen of Ti-coordinated peroxo group, displacing $t\text{-BuO}^-$.''',
          intermediate: r'''Chiral 2,3-Epoxy alcohol + $t\text{-BuOH}$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Enantioselective Oxygen Transfer & Epoxidation</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">(+)-DET directs attack to Re-face giving (2R,3R)-epoxy alcohol (>95% ee)</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <line x1="120" y1="140" x2="180" y2="140"/>
          <line x1="120" y1="140" x2="150" y2="90"/>
          <line x1="180" y1="140" x2="150" y2="90"/>
          <text x="145" y="85" fill="#EF4444" font-size="14" font-weight="bold" font-family="sans-serif">O</text>
          <line x1="180" y1="140" x2="225" y2="165"/>
          <text x="235" y="172" fill="#38BDF8" font-size="12" font-weight="bold" font-family="sans-serif">CH2OH</text>
          <line x1="120" y1="140" x2="80" y2="165"/>
          <text x="65" y="172" fill="#F8FAFC" font-size="12" font-weight="bold" font-family="sans-serif">R</text>
          <text x="320" y="145" fill="#94A3B8" font-size="20" font-weight="bold" font-family="sans-serif">+</text>
          <text x="360" y="145" fill="#10B981" font-size="13" font-weight="bold" font-family="sans-serif">t-BuOH + [Ti-DET] (recycled)</text>
          <rect x="80" y="195" width="180" height="26" rx="5" fill="#1E293B" stroke="#10B981" stroke-width="1.2"/>
          <text x="170" y="212" fill="#10B981" font-size="11.5" font-weight="bold" text-anchor="middle" font-family="sans-serif">(2R, 3R)-Epoxy Alcohol (95% ee)</text>
        </g>
        
  <g id="electron-arrows">
    
        <path d="M 145 92 Q 135 110 125 130" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'suzuki_coupling',
      name: 'Suzuki-Miyaura Cross-Coupling',
      aliases: ['Suzuki Coupling', 'Suzuki-Miyaura Reaction', 'Pd-Catalyzed Biaryl Coupling'],
      category: ReactionCategory.organometallics,
      summary:
          r'''Palladium-catalyzed cross-coupling between organoboron compounds (e.g. arylboronic acids) and organic halides/triflates in the presence of base. Forms robust carbon-carbon (sp2-sp2) biaryl or alkenyl bonds with high functional group tolerance and non-toxic boronic acid byproducts.''',
      reactants: r'''Aryl/Alkenyl halide or triflate ($\text{Ar-X}$), Arylboronic acid ($\text{Ar\'-B(OH)}_2$)''',
      reagentsAndConditions: r'''$\text{Pd(PPh}_3)_4$ or $\text{Pd(dppf)Cl}_2$ (1-5 mol%), Base ($\text{Na}_2\text{CO}_3, \text{K}_3\text{PO}_4, \text{CsF}$), $\text{THF/H}_2\text{O}$ or Toluene/EtOH, $60-100^\circ\text{C}$''',
      products: r'''Biaryl or substituted alkene ($\text{Ar-Ar\'}$), Boric acid / borate salt''',
      regioselectivity: r'''Cross-coupling occurs selectively at the C(sp2)-halide or triflate site. Relative reactivity: $\text{I} > \text{OTf} > \text{Br} \gg \text{Cl}$.''',
      stereochemistry: r'''Complete stereoretention of alkene double-bond geometry ($E$ or $Z$) from alkenylboronic acid or alkenyl halide into coupled product.''',
      drivingForce: r'''Thermodynamic affinity of boron for oxygen driving base-promoted quaternization to $[\text{Ar-B(OH)}_3]^-$, coupled with the high thermodynamic stability of the formed aromatic C-C bond ($\sim 435\text{ kJ/mol}$).''',
      representativeExample: r'''Coupling of 4-bromotoluene with phenylboronic acid using $\text{Pd(PPh}_3)_4$ and $\text{Na}_2\text{CO}_3$ yielding 4-methylbiphenyl (>92% yield).''',
      keyApplications: [
        r'''Industrial synthesis of pharmaceuticals (e.g. Losartan, Valsartan) and agrochemicals.''',
        r'''Synthesis of conjugated polymers, OLED materials, and biaryl liquid crystals.''',
      ],
      limitations: [
        r'''Aryl chlorides are sluggish and require bulky electron-rich Buchwald phosphine ligands (SPhos, XPhos).''',
        r'''Base can induce homocoupling or protodeboronation of electron-deficient heteroarylboronic acids.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Oxidative Addition to Pd(0)',
          description: r'''Aryl halide $\text{Ar-X}$ coordinates to and oxidatively adds across the coordinatively unsaturated 14e- $[\text{Pd(0)L}_2]$ complex, forming a square-planar $16\text{e}^-$ $[\text{Ar-Pd(II)L}_2\text{-X}]$ intermediate.''',
          curvedArrowNotes: r'''Nucleophilic Pd(0) d-orbital attacks C-X $\sigma^*$ antibonding orbital, cleaving C-X bond.''',
          intermediate: r'''$trans-[\text{Ar-Pd(II)L}_2\text{-X}]$ Square-Planar Adduct''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Oxidative Addition (RDS)</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Aryl halide adds to 14e- Pd(0)L2 complex, increasing oxidation state to Pd(II)</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="120" cy="130" r="20" fill="#1E293B" stroke="#38BDF8" stroke-width="2.2"/>
          <text x="120" y="135" fill="#38BDF8" font-size="12" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(0)L2</text>
          <text x="175" y="135" fill="#94A3B8" font-size="18" font-weight="bold" font-family="sans-serif">+</text>
          <polygon points="230,130 245,105 275,105 290,130 275,155 245,155" fill="none" stroke="#E2E8F0" stroke-width="2"/>
          <circle cx="260" cy="130" r="14" fill="none" stroke="#E2E8F0" stroke-width="1.5" stroke-dasharray="3,3"/>
          <line x1="290" y1="130" x2="330" y2="130"/>
          <text x="345" y="135" fill="#EF4444" font-size="13" font-weight="bold" font-family="sans-serif">Br</text>
          <line x1="390" y1="130" x2="440" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="445,130 435,125 435,135" fill="#38BDF8"/>
          <circle cx="530" cy="130" r="18" fill="#1E293B" stroke="#F59E0B" stroke-width="2"/>
          <text x="530" y="135" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(II)</text>
          <line x1="512" y1="130" x2="480" y2="130"/>
          <text x="465" y="134" fill="#F8FAFC" font-size="11" font-family="sans-serif">Ar</text>
          <line x1="548" y1="130" x2="580" y2="130"/>
          <text x="590" y="134" fill="#EF4444" font-size="11" font-weight="bold" font-family="sans-serif">Br</text>
          <line x1="530" y1="112" x2="530" y2="85"/>
          <text x="530" y="78" fill="#94A3B8" font-size="10" text-anchor="middle" font-family="sans-serif">L</text>
          <line x1="530" y1="148" x2="530" y2="175"/>
          <text x="530" y="188" fill="#94A3B8" font-size="10" text-anchor="middle" font-family="sans-serif">L</text>
        </g>
        <rect x="470" y="205" width="130" height="22" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="535" y="220" fill="#F59E0B" font-size="10.5" font-weight="bold" text-anchor="middle" font-family="sans-serif">trans-[Ar-Pd(II)L2-Br]</text>
        
  <g id="electron-arrows">
    
        <path d="M 140 120 Q 220 70 310 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Base-Promoted Transmetalation',
          description: r'''Inorganic base ($\text{OH}^-$) coordinates to neutral arylboronic acid $\text{Ar\'-B(OH)}_2$ to generate a nucleophilic, negatively charged tetrahedral borate $[\text{Ar\'-B(OH)}_3]^-$, which transfers the aryl carbanion to $\text{Pd(II)}$, displacing halide.''',
          curvedArrowNotes: r'''Curved arrow from nucleophilic B-Ar\' bond to electrophilic Pd(II) center, with halide departure.''',
          intermediate: r'''$cis-[\text{Ar-Pd(II)L}_2\text{-Ar\']}$ Diaryl Palladium Complex''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Base-Promoted Transmetalation</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Hydroxyborate [Ar-B(OH)3]- delivers aryl group to trans-[Ar-Pd-Br]</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="130" cy="130" r="16" fill="#1E293B" stroke="#A855F7" stroke-width="2"/>
          <text x="130" y="135" fill="#A855F7" font-size="12" font-weight="bold" text-anchor="middle" font-family="sans-serif">B-</text>
          <line x1="114" y1="130" x2="80" y2="130"/>
          <text x="65" y="134" fill="#F8FAFC" font-size="11" font-family="sans-serif">Ar'</text>
          <line x1="130" y1="114" x2="130" y2="85"/>
          <text x="130" y="78" fill="#94A3B8" font-size="10" text-anchor="middle" font-family="sans-serif">OH</text>
          <line x1="130" y1="146" x2="130" y2="175"/>
          <text x="130" y="188" fill="#94A3B8" font-size="10" text-anchor="middle" font-family="sans-serif">OH</text>
          <line x1="144" y1="120" x2="170" y2="95"/>
          <text x="180" y="92" fill="#94A3B8" font-size="10" font-family="sans-serif">OH</text>
          <text x="215" y="135" fill="#94A3B8" font-size="18" font-weight="bold" font-family="sans-serif">+</text>
          <circle cx="300" cy="130" r="18" fill="#1E293B" stroke="#F59E0B" stroke-width="2"/>
          <text x="300" y="135" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(II)</text>
          <line x1="282" y1="130" x2="250" y2="130"/>
          <text x="238" y="134" fill="#F8FAFC" font-size="11" font-family="sans-serif">Ar</text>
          <line x1="318" y1="130" x2="350" y2="130"/>
          <text x="360" y="134" fill="#EF4444" font-size="11" font-weight="bold" font-family="sans-serif">Br</text>
          <line x1="390" y1="130" x2="440" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="445,130 435,125 435,135" fill="#38BDF8"/>
          <circle cx="530" cy="130" r="18" fill="#1E293B" stroke="#F59E0B" stroke-width="2"/>
          <text x="530" y="135" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(II)</text>
          <line x1="512" y1="130" x2="480" y2="130"/>
          <text x="468" y="134" fill="#F8FAFC" font-size="11" font-family="sans-serif">Ar</text>
          <line x1="530" y1="112" x2="530" y2="80"/>
          <text x="530" y="72" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ar'</text>
          <line x1="548" y1="130" x2="580" y2="130"/>
          <text x="590" y="134" fill="#94A3B8" font-size="10" font-family="sans-serif">L</text>
          <line x1="530" y1="148" x2="530" y2="175"/>
          <text x="530" y="188" fill="#94A3B8" font-size="10" text-anchor="middle" font-family="sans-serif">L</text>
        </g>
        
  <g id="electron-arrows">
    
        <path d="M 90 120 Q 180 50 290 115" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Reductive Elimination & Biaryl Formation',
          description: r'''The two mutually cis aryl ligands undergo concerted intramolecular reductive elimination to forge the new C-C biaryl bond, regenerating active $[\text{Pd(0)L}_2]$ to restart the catalytic cycle.''',
          curvedArrowNotes: r'''Concerted electron flow from Pd-Ar and Pd-Ar\' bonding orbitals to form Ar-Ar\' $\sigma$-bond while transferring 2 electrons back onto Pd(0).''',
          intermediate: r'''Biaryl ($\text{Ar-Ar\'}$) + Regenerated $[\text{Pd(0)L}_2]$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Reductive Elimination</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Concerted C-C coupling yields biaryl product and regenerates active Pd(0) catalyst</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="160" cy="130" r="18" fill="#1E293B" stroke="#F59E0B" stroke-width="2"/>
          <text x="160" y="135" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(II)</text>
          <line x1="142" y1="130" x2="110" y2="130"/>
          <text x="95" y="134" fill="#F8FAFC" font-size="11" font-family="sans-serif">Ar</text>
          <line x1="160" y1="112" x2="160" y2="80"/>
          <text x="160" y="72" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ar'</text>
          <line x1="220" y1="130" x2="280" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="285,130 275,125 275,135" fill="#38BDF8"/>
          <polygon points="340,130 355,105 385,105 400,130 385,155 355,155" fill="none" stroke="#10B981" stroke-width="2"/>
          <line x1="400" y1="130" x2="435" y2="130" stroke="#10B981" stroke-width="2.5"/>
          <polygon points="435,130 450,105 480,105 495,130 480,155 450,155" fill="none" stroke="#10B981" stroke-width="2"/>
          <text x="525" y="135" fill="#94A3B8" font-size="18" font-weight="bold" font-family="sans-serif">+</text>
          <circle cx="580" cy="130" r="18" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="580" y="135" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(0)L2</text>
        </g>
        <rect x="330" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="420" y="211" fill="#10B981" font-size="11.5" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ar-Ar' Biaryl Cross-Coupled</text>
        
  <g id="electron-arrows">
    
        <path d="M 105 125 Q 125 85 150 75" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'mitsunobu_reaction',
      name: 'Mitsunobu Reaction',
      aliases: ['Mitsunobu Inversion', 'Phosphonium-Mediated Substitution'],
      category: ReactionCategory.rearrangements,
      summary:
          r'''Stereospecific conversion of primary and secondary alcohols into esters, ethers, amines, or thioethers using diethyl azodicarboxylate (DEAD) or DIAD, triphenylphosphine (PPh3), and a pronucleophile with pKa < 15. Proceeds with 100% Walden inversion of configuration at secondary chiral carbinols.''',
      reactants: r'''Alcohol ($\text{R-OH}$), Pronucleophile with $\text{p}K_a < 15$ (e.g. $\text{PhCOOH, Phthalimide}$)''',
      reagentsAndConditions: r'''$\text{PPh}_3$ (1.2 equiv), DEAD or DIAD (1.2 equiv), Anhydrous THF, $0^\circ\text{C}$ to room temperature''',
      products: r'''Inverted product (e.g. Inverted ester $\text{R-OC(O)Ph}$), $\text{O=PPh}_3$, Diethyl hydrazinedicarboxylate''',
      regioselectivity: r'''Selectively functionalizes primary and unhindered secondary alcohols. Tertiary alcohols fail due to steric hindrance preventing nucleophilic attack on phosphorus.''',
      stereochemistry: r'''Complete stereochemical inversion (100% Walden inversion) at secondary chiral carbon centers via an SN2 backside displacement mechanism.''',
      drivingForce: r'''Tremendous thermodynamic driving force of forming the exceptionally strong phosphorus-oxygen double bond in triphenylphosphine oxide ($\text{O=PPh}_3, \sim 540\text{ kJ/mol}$) and stable hydrazine byproduct.''',
      representativeExample: r'''Conversion of (R)-2-octanol into (S)-2-octyl benzoate using benzoic acid, PPh3, and DEAD with complete optical inversion (>98% ee).''',
      keyApplications: [
        r'''Inversion of stereocenters in natural products, steroid chemistry, and prostaglandin synthesis.''',
        r'''Mild formation of esters, azides, phthalimides (Gabriel amine precursor), and alkyl halides.''',
      ],
      limitations: [
        r'''Pronucleophile pKa must be strictly < 15; weakly acidic substrates fail to protonate the betaine intermediate.''',
        r'''Chromatographic removal of Ph3P=O and reduced DEAD byproducts can be challenging in large-scale synthesis.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Phosphonium Betaine Generation',
          description: r'''Nucleophilic addition of triphenylphosphine $\text{PPh}_3$ to the azo nitrogen of diethyl azodicarboxylate (DEAD) generates the zwitterionic Morrison-Brunn-Huisgen phosphonium betaine $[\text{Ph}_3\text{P}^+-\text{N}(\text{CO}_2\text{Et})-\bar{\text{N}}\text{CO}_2\text{Et}]$.''',
          curvedArrowNotes: r'''PPh3 phosphorus lone pair attacks the electron-deficient azo nitrogen, shifting pi-electrons onto the adjacent nitrogen.''',
          intermediate: r'''$[\text{Ph}_3\text{P}^+-\text{N}(\text{CO}_2\text{Et})-\bar{\text{N}}\text{CO}_2\text{Et}]$ Betaine''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Phosphonium Betaine Generation</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Triphenylphosphine attacks DEAD/DIAD azo bond forming zwitterionic betaine</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="70" y="135" fill="#F59E0B" font-size="13" font-weight="bold" font-family="sans-serif">PPh3</text>
          <text x="135" y="135" fill="#94A3B8" font-size="18" font-weight="bold" font-family="sans-serif">+</text>
          <text x="175" y="135" fill="#38BDF8" font-size="12" font-family="sans-serif">EtO2C-N=N-CO2Et (DEAD)</text>
          <line x1="330" y1="130" x2="380" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="385,130 375,125 375,135" fill="#38BDF8"/>
          <text x="410" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">Ph3P+</text>
          <line x1="455" y1="130" x2="485" y2="130"/>
          <text x="495" y="135" fill="#A855F7" font-size="12" font-weight="bold" font-family="sans-serif">N(CO2Et)-N-(CO2Et)</text>
        </g>
        <rect x="390" y="190" width="220" height="24" rx="4" fill="#1E293B" stroke="#A855F7" stroke-width="1"/>
        <text x="500" y="206" fill="#A855F7" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Morrison-Brunn-Huisgen Betaine</text>
        
  <g id="electron-arrows">
    
        <path d="M 105 125 Q 140 100 200 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Pronucleophile Deprotonation & Alcohol Activation',
          description: r'''The basic nitrogen of the betaine deprotonates the acidic pronucleophile $\text{Nu-H}$ ($\text{p}K_a < 15$). The alcohol $\text{R-OH}$ then attacks the electrophilic phosphonium center, displacing the hydrazine anion to form an active alkoxyphosphonium intermediate $[\text{Ph}_3\text{P}^+-\text{O-R}]$.''',
          curvedArrowNotes: r'''Alcohol oxygen attacks phosphonium cation with expulsion of reduced hydrazine leaving group.''',
          intermediate: r'''$[\text{Ph}_3\text{P}^+-\text{O-R}] + \text{Nu}^-$ Alkoxyphosphonium Salt''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Pronucleophile Deprotonation & Alcohol Activation</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Betaine deprotonates Nu-H, then alcohol attacks P to form alkoxyphosphonium</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="60" y="125" fill="#F8FAFC" font-size="12" font-family="sans-serif">R-OH</text>
          <text x="115" y="125" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="135" y="125" fill="#EF4444" font-size="12" font-family="sans-serif">Nu-H (pKa &lt; 15)</text>
          <line x1="240" y1="120" x2="290" y2="120" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="295,120 285,115 285,125" fill="#38BDF8"/>
          <text x="320" y="125" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">Ph3P+-O-R</text>
          <text x="410" y="125" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="430" y="125" fill="#10B981" font-size="12" font-weight="bold" font-family="sans-serif">Nu-</text>
          <text x="475" y="125" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="495" y="125" fill="#94A3B8" font-size="11" font-family="sans-serif">DEAD-H2</text>
        </g>
        <rect x="300" y="180" width="180" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="390" y="196" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Alkoxyphosphonium Interm.</text>
        
  <g id="electron-arrows">
    
        <path d="M 85 110 Q 180 80 320 110" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'SN2 Backside Displacement with 100% Inversion',
          description: r'''The nucleophile $\text{Nu}^-$ performs an $S_N2$ backside attack at the carbinol carbon of the alkoxyphosphonium intermediate, displacing triphenylphosphine oxide $\text{O=PPh}_3$ and affording the product with complete inversion of configuration.''',
          curvedArrowNotes: r'''Nucleophile attacks back-lobe of C-O sigma* orbital at 180 degrees, releasing triphenylphosphine oxide.''',
          intermediate: r'''Inverted Product ($\text{R-Nu}$) + $\text{O=PPh}_3$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: SN2 Backside Displacement & 100% Inversion</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Nu- attacks chiral carbinol carbon; O=PPh3 departs as exceptionally stable byproduct</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="70" y="135" fill="#10B981" font-size="14" font-weight="bold" font-family="sans-serif">Nu:-</text>
          <circle cx="210" cy="130" r="16" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="210" y="135" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">C* (R)</text>
          <line x1="226" y1="130" x2="270" y2="130"/>
          <text x="280" y="135" fill="#EF4444" font-size="12" font-family="sans-serif">O-P+Ph3</text>
          <line x1="360" y1="130" x2="410" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="415,130 405,125 405,135" fill="#38BDF8"/>
          <circle cx="470" cy="130" r="16" fill="#1E293B" stroke="#10B981" stroke-width="2"/>
          <text x="470" y="135" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">C* (S)</text>
          <line x1="454" y1="130" x2="430" y2="130"/>
          <text x="415" y="134" fill="#10B981" font-size="12" font-family="sans-serif">Nu</text>
          <text x="505" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="525" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">O=PPh3 (P=O bond driving force)</text>
        </g>
        <rect x="390" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="480" y="211" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Inverted (S) Stereocenter</text>
        
  <g id="electron-arrows">
    
        <path d="M 95 125 Q 145 95 195 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        <path d="M 235 125 Q 260 100 290 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'baeyer_villiger',
      name: 'Baeyer-Villiger Oxidation',
      aliases: ['Baeyer-Villiger Rearrangement', 'Ketone to Ester Oxidation', 'Lactone Synthesis'],
      category: ReactionCategory.oxidationReduction,
      summary:
          r'''Oxidative cleavage of ketones to esters, or cyclic ketones to ring-expanded lactones, using peroxyacids (e.g. mCPBA, trifluoroperacetic acid). Proceeds via the tetrahedral Criegee intermediate with concerted alkyl migration occurring with complete stereochemical retention.''',
      reactants: r'''Ketone ($\text{R-CO-R\'}$), Peroxyacid ($\text{mCPBA}, \text{CF}_3\text{CO}_3\text{H}$)''',
      reagentsAndConditions: r'''$\text{mCPBA}$ (1.1-1.5 equiv), $\text{NaHCO}_3$ buffer, $\text{CH}_2\text{Cl}_2$, room temperature''',
      products: r'''Ester or Lactone ($\text{R-C(O)O-R\'}$), Carboxylic acid byproduct''',
      regioselectivity: r'''Migratory aptitude governs which carbon migrates to oxygen: $3^\circ\text{ alkyl} > \text{cyclohexyl} > 2^\circ\text{ alkyl} \approx \text{benzyl} \approx \text{phenyl} > 1^\circ\text{ alkyl} > \text{methyl}$.''',
      stereochemistry: r'''The migrating group migrates with 100% retention of stereochemical configuration at the chiral migration terminus.''',
      drivingForce: r'''Cleavage of the weak, high-energy peroxide O-O bond ($\sim 140\text{ kJ/mol}$) and expulsion of the resonance-stabilized carboxylate leaving group ($m$-chlorobenzoate).''',
      representativeExample: r'''Oxidation of cyclohexanone with mCPBA to form epsilon-caprolactone in 94% yield.''',
      keyApplications: [
        r'''Synthesis of biodegradable polyesters and plastics via lactone ring-opening polymerization.''',
        r'''Regioselective functionalization of complex steroids and bicyclic terpenoids.''',
      ],
      limitations: [
        r'''Aldehydes typically oxidize to carboxylic acids via hydride migration rather than alkyl migration.''',
        r'''Electron-rich alkenes in the substrate may undergo competitive epoxidation by peracid.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Nucleophilic Addition of Peroxyacid',
          description: r'''Peroxyacid ($m\text{CPBA}$) nucleophilically attacks the electrophilic carbonyl carbon of the ketone, producing a tetrahedral adduct.''',
          curvedArrowNotes: r'''Peracid peroxy oxygen attacks carbonyl carbon, shifting pi-electrons onto carbonyl oxygen.''',
          intermediate: r'''Peroxyhemiacetal Tetrahedral Adduct''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Nucleophilic Addition of Peroxyacid</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Peroxyacid (mCPBA) attacks ketone carbonyl carbon forming tetrahedral intermediate</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <polygon points="120,130 135,105 165,105 180,130 165,155 135,155" fill="none" stroke="#E2E8F0" stroke-width="2"/>
          <line x1="180" y1="130" x2="220" y2="130"/>
          <line x1="180" y1="126" x2="220" y2="126"/>
          <text x="230" y="133" fill="#EF4444" font-size="13" font-weight="bold" font-family="sans-serif">O</text>
          <text x="270" y="135" fill="#94A3B8" font-size="18" font-family="sans-serif">+</text>
          <text x="310" y="135" fill="#A855F7" font-size="12" font-weight="bold" font-family="sans-serif">R'CO3H (mCPBA)</text>
          <line x1="430" y1="130" x2="480" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="485,130 475,125 475,135" fill="#38BDF8"/>
          <text x="510" y="135" fill="#F8FAFC" font-size="12" font-family="sans-serif">Tetrahedral Adduct</text>
        </g>
        
  <g id="electron-arrows">
    
        <path d="M 330 120 Q 250 80 185 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Criegee Intermediate Formation',
          description: r'''Rapid intramolecular proton transfer stabilizes the adduct into the classical Criegee intermediate, activating the peroxy oxygen for departure of the carboxylate leaving group.''',
          curvedArrowNotes: r'''Proton migration from peroxy oxygen to carbonyl oxygen sets up leaving group departure.''',
          intermediate: r'''Criegee Intermediate $[\text{R}_2\text{C(OH)OO(CO)Ar}]$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Formation of Criegee Intermediate</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Intramolecular proton transfer prepares peroxy oxygen for alkyl migration</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="200" cy="130" r="16" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="200" y="135" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">C(sp3)</text>
          <line x1="200" y1="114" x2="200" y2="85"/>
          <text x="200" y="78" fill="#EF4444" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">OH</text>
          <line x1="216" y1="130" x2="260" y2="130"/>
          <text x="270" y="134" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">O</text>
          <line x1="285" y1="130" x2="315" y2="130"/>
          <text x="325" y="134" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">O</text>
          <line x1="340" y1="130" x2="380" y2="130"/>
          <text x="390" y="134" fill="#94A3B8" font-size="11" font-family="sans-serif">CO-Ar</text>
          <line x1="184" y1="130" x2="140" y2="130"/>
          <text x="110" y="134" fill="#F8FAFC" font-size="11" font-weight="bold" font-family="sans-serif">R(migrating)</text>
        </g>
        <rect x="180" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="290" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Key Criegee Intermediate</text>
        
  <g id="electron-arrows">
    
        <path d="M 200 80 Q 240 60 270 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Concerted Alkyl Migration & O-O Cleavage',
          description: r'''The more substituted alkyl group migrates to the adjacent electron-deficient peroxy oxygen with complete stereoretention, simultaneously expelling $m$-chlorobenzoate. Deprotonation delivers the ester/lactone.''',
          curvedArrowNotes: r'''Migration of C-C sigma-bond to peroxy oxygen as the weak O-O bond cleaves.''',
          intermediate: r'''Ester / Lactone + $m\text{-Chlorobenzoic acid}$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Concerted Alkyl Migration & O-O Cleavage</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Migration with 100% stereoretention expels carboxylate yielding Lactone/Ester</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <polygon points="180,100 220,90 250,115 240,155 200,170 165,150 160,115" fill="none" stroke="#10B981" stroke-width="2.2"/>
          <text x="250" y="120" fill="#EF4444" font-size="13" font-weight="bold" font-family="sans-serif">O</text>
          <line x1="180" y1="100" x2="160" y2="70"/>
          <text x="150" y="65" fill="#EF4444" font-size="13" font-weight="bold" font-family="sans-serif">=O</text>
          <text x="320" y="135" fill="#94A3B8" font-size="18" font-family="sans-serif">+</text>
          <text x="360" y="135" fill="#94A3B8" font-size="12" font-family="sans-serif">m-Chlorobenzoate anion (leaving group)</text>
        </g>
        <rect x="140" y="195" width="200" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="240" y="211" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">epsilon-Caprolactone (Ring Expansion)</text>
        
  <g id="electron-arrows">
    
        <path d="M 130 130 Q 200 100 270 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'swern_oxidation',
      name: 'Swern Oxidation',
      aliases: ['Swern Carbonyl Synthesis', 'DMSO-Oxalyl Chloride Oxidation'],
      category: ReactionCategory.oxidationReduction,
      summary:
          r'''Mild, chemoselective oxidation of primary alcohols to aldehydes (without over-oxidation to carboxylic acids) and secondary alcohols to ketones using dimethyl sulfoxide (DMSO), oxalyl chloride $(COCl)_2$, and triethylamine at low temperature ($-78^\circ\text{C}$).''',
      reactants: r'''$1^\circ$ or $2^\circ$ Alcohol ($\text{R-CH}_2\text{OH}$ or $\text{R}_2\text{CHOH}$)''',
      reagentsAndConditions: r'''$\text{DMSO}$ (2.2 equiv), Oxalyl chloride $(COCl)_2$ (1.1 equiv), $\text{Et}_3\text{N}$ (3-5 equiv), $\text{CH}_2\text{Cl}_2$, $-78^\circ\text{C}$ to room temperature''',
      products: r'''Aldehyde or Ketone ($\text{R-CHO}$ or $\text{R}_2\text{C=O}$), $\text{Me}_2\text{S}, \text{CO}_2, \text{CO}, \text{Et}_3\text{NH}^+\text{Cl}^-$''',
      regioselectivity: r'''Exclusively oxidizes alcohols to carbonyl compounds without over-oxidizing primary aldehydes to carboxylic acids, in stark contrast to aqueous Cr(VI) Jones reagents.''',
      stereochemistry: r'''Mild conditions prevent racemization or epimerization at sensitive chiral centers alpha to the newly formed carbonyl.''',
      drivingForce: r'''Irreversible evolution of non-condensable gases ($\text{CO}_2$ and $\text{CO}$) and generation of volatile dimethyl sulfide ($\text{Me}_2\text{S}$), driving entropy strongly positive.''',
      representativeExample: r'''Oxidation of benzyl alcohol to benzaldehyde in 96% yield without trace benzoic acid.''',
      keyApplications: [
        r'''Total synthesis of complex natural products containing acid- or base-sensitive chiral centers.''',
        r'''Oxidation of polyols and carbohydrate derivatives without protecting group cleavage.''',
      ],
      limitations: [
        r'''Generates volatile, toxic, and noxious dimethyl sulfide ($Me_2S$), requiring good fumehood ventilation.''',
        r'''Must be kept strictly at $-78^\circ\text{C}$ before base addition to prevent Pummerer rearrangement side reactions.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Activation of DMSO by Oxalyl Chloride',
          description: r'''DMSO attacks oxalyl chloride at $-78^\circ\text{C}$, followed by rapid collapse with loss of $\text{CO}_2$ and $\text{CO}$ to generate the highly electrophilic chlorodimethylsulfonium chloride intermediate.''',
          curvedArrowNotes: r'''DMSO oxygen attacks oxalyl carbonyl; fragmentation expels CO2 and CO gases.''',
          intermediate: r'''$[\text{Me}_2\text{S}^+-\text{Cl}]\text{Cl}^-$ Chlorodimethylsulfonium Cation''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Oxalyl Chloride Activation of DMSO</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">DMSO nucleophilic addition to (COCl)2 expels CO2 + CO to form active sulfonium</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="70" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">Me2S=O (DMSO)</text>
          <text x="195" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="220" y="135" fill="#38BDF8" font-size="12" font-weight="bold" font-family="sans-serif">(COCl)2 (-78°C)</text>
          <line x1="330" y1="130" x2="380" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="385,130 375,125 375,135" fill="#38BDF8"/>
          <text x="405" y="135" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">[Me2S+-Cl] Cl-</text>
          <text x="510" y="135" fill="#94A3B8" font-size="15" font-family="sans-serif">+</text>
          <text x="530" y="135" fill="#10B981" font-size="11" font-family="sans-serif">CO2 + CO (g)</text>
        </g>
        <rect x="375" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#EF4444" stroke-width="1"/>
        <text x="485" y="211" fill="#EF4444" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Chlorodimethylsulfonium Cation</text>
        
  <g id="electron-arrows">
    
        <path d="M 140 125 Q 180 90 230 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Attack of Alcohol on Sulfur',
          description: r'''The alcohol oxygen attacks the sulfur atom of the chlorodimethylsulfonium cation, displacing chloride ion to form the alkoxydimethylsulfonium intermediate.''',
          curvedArrowNotes: r'''Alcohol hydroxyl oxygen attacks electrophilic sulfur cation with chloride departure.''',
          intermediate: r'''$[\text{R-CH}_2\text{-O-S}^+\text{Me}_2]$ Alkoxydimethylsulfonium Adduct''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Nucleophilic Attack of Alcohol on Sulfur</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Alcohol oxygen displaces chloride generating alkoxydimethylsulfonium cation</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="70" y="135" fill="#F8FAFC" font-size="12" font-family="sans-serif">R-CH2-OH</text>
          <text x="160" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="180" y="135" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">[Me2S+-Cl]</text>
          <line x1="270" y1="130" x2="320" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="325,130 315,125 315,135" fill="#38BDF8"/>
          <text x="345" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">[R-CH2-O-S+Me2]</text>
          <text x="480" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="500" y="135" fill="#10B981" font-size="12" font-family="sans-serif">HCl</text>
        </g>
        <rect x="320" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="430" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Alkoxydimethylsulfonium Cation</text>
        
  <g id="electron-arrows">
    
        <path d="M 125 125 Q 155 105 185 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Base Deprotonation & Intramolecular Elimination',
          description: r'''Triethylamine deprotonates a methyl group on sulfur to create a sulfur ylide. The carbanion then executes an intramolecular 5-membered cyclic elimination, abstracting the carbinol proton to yield the carbonyl and expel dimethyl sulfide.''',
          curvedArrowNotes: r'''Intramolecular 5-membered cyclic proton abstraction from carbinol carbon, with C=O double bond formation and Me2S departure.''',
          intermediate: r'''Aldehyde / Ketone + $\text{Me}_2\text{S} + \text{Et}_3\text{NH}^+\text{Cl}^-$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Base-Promoted Intramolecular Elimination</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Et3N forms sulfur ylide; 5-membered cyclic elimination yields aldehyde + Me2S</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="210" cy="130" r="14" fill="#1E293B" stroke="#F59E0B" stroke-width="1.8"/>
          <text x="210" y="134" fill="#F59E0B" font-size="10" font-weight="bold" text-anchor="middle" font-family="sans-serif">S+</text>
          <line x1="224" y1="130" x2="260" y2="130"/>
          <text x="270" y="134" fill="#EF4444" font-size="12" font-family="sans-serif">O</text>
          <line x1="280" y1="130" x2="310" y2="130"/>
          <text x="320" y="134" fill="#38BDF8" font-size="11" font-family="sans-serif">CH(R)</text>
          <line x1="380" y1="130" x2="430" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="435,130 425,125 425,135" fill="#38BDF8"/>
          <text x="460" y="135" fill="#10B981" font-size="13" font-weight="bold" font-family="sans-serif">R-CH=O (Aldehyde)</text>
          <text x="590" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="610" y="135" fill="#F59E0B" font-size="11" font-family="sans-serif">Me2S</text>
        </g>
        <rect x="440" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="530" y="211" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">No Over-Oxidation to Acid</text>
        
  <g id="electron-arrows">
    
        <path d="M 210 116 Q 260 75 320 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'birch_reduction',
      name: 'Birch Reduction',
      aliases: ['Dissolving Metal Aromatic Reduction', '1,4-Cyclohexadiene Synthesis'],
      category: ReactionCategory.oxidationReduction,
      summary:
          r'''Dissolving metal reduction of aromatic rings using alkali metals (Na, Li) in liquid ammonia in the presence of an alcohol (t-BuOH). Produces non-conjugated 1,4-cyclohexadienes under kinetic protonation control with high regiochemical predictability dictated by aromatic substituents.''',
      reactants: r'''Aromatic compound (e.g. Anisole or Benzoic acid), Alkali metal ($\text{Na}$ or $\text{Li}$)''',
      reagentsAndConditions: r'''$\text{Na}$ or $\text{Li}$ (2-3 equiv), Liquid $\text{NH}_3$, $t\text{-BuOH}$ or $\text{EtOH}$, $-78^\circ\text{C}$ to $-33^\circ\text{C}$''',
      products: r'''Non-conjugated 1,4-cyclohexadiene''',
      regioselectivity: r'''Electron-Donating Groups (EDG, e.g. $-OMe, -CH_3$) direct reduction to ortho and meta positions (substituent remains on remaining double bond). Electron-Withdrawing Groups (EWG, e.g. $-COOH$) direct reduction to ipso and para positions.''',
      stereochemistry: r'''Yields exclusively non-conjugated 1,4-cyclohexadienes as kinetic products, which do not isomerize to the conjugated 1,3-dienes under reaction conditions.''',
      drivingForce: r'''High chemical potential of the deep-blue solvated electide single electron transfer (SET) overcoming aromatic resonance stabilization under kinetic control.''',
      representativeExample: r'''Reduction of anisole to 1-methoxycyclohexa-1,4-diene in 88% yield.''',
      keyApplications: [
        r'''Key step in Birch-reduction / Robinson annulation sequences for steroid and alkaloid synthesis.''',
        r'''Synthesis of cyclohexenones via subsequent mild acid hydrolysis of enol ethers.''',
      ],
      limitations: [
        r'''Requires handling cryogenic liquid ammonia and reactive alkali metals.''',
        r'''Over-reduction to mono-alkenes can occur if excess metal and prolonged reaction times are used.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'First Single Electron Transfer (SET)',
          description: r'''A solvated electron $e^-(\text{NH}_3)$ from dissolved sodium transfers into the aromatic ring $\pi^*$ LUMO, generating a resonance-delocalized radical anion.''',
          curvedArrowNotes: r'''Single-barbed fishhook arrow representing single electron transfer from solvated electron to aromatic ring LUMO.''',
          intermediate: r'''$[\text{Ar}^{\bullet-}]$ Radical Anion Intermediate''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: First Single Electron Transfer (SET)</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Solvated electron e-(NH3) transfers to aromatic pi* LUMO forming radical anion</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <polygon points="120,130 135,105 165,105 180,130 165,155 135,155" fill="none" stroke="#E2E8F0" stroke-width="2"/>
          <circle cx="150" cy="130" r="14" fill="none" stroke="#E2E8F0" stroke-width="1.5" stroke-dasharray="3,3"/>
          <line x1="180" y1="130" x2="215" y2="130"/>
          <text x="225" y="134" fill="#38BDF8" font-size="12" font-family="sans-serif">OCH3</text>
          <text x="280" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <circle cx="320" cy="130" r="14" fill="#1E293B" stroke="#F59E0B" stroke-width="2"/>
          <text x="320" y="135" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">e-(NH3)</text>
          <line x1="360" y1="130" x2="410" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="415,130 405,125 405,135" fill="#38BDF8"/>
          <!-- Radical anion -->
          <polygon points="460,130 475,105 505,105 520,130 505,155 475,155" fill="none" stroke="#F59E0B" stroke-width="2"/>
          <circle cx="460" cy="130" r="4" fill="#F59E0B"/>
          <text x="510" y="95" fill="#EF4444" font-size="14" font-weight="bold" font-family="sans-serif">(-)</text>
          <line x1="520" y1="130" x2="550" y2="130"/>
          <text x="560" y="134" fill="#38BDF8" font-size="11" font-family="sans-serif">OCH3</text>
        </g>
        <rect x="425" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="515" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Radical Anion Intermediate</text>
        
  <g id="electron-arrows">
    
        <path d="M 320 116 Q 370 75 460 120" fill="none" stroke="#F59E0B" stroke-width="2.2" marker-end="url(#fishhook)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'First Protonation by Alcohol',
          description: r'''The radical anion is kinetically protonated by tert-butanol at the carbon with the highest carbanionic charge density (ortho/meta for EDG, ipso/para for EWG), yielding a neutral cyclohexadienyl radical.''',
          curvedArrowNotes: r'''Carbanion pair attacks proton of t-BuOH; fishhook radical remains delocalized across remaining 5 carbons.''',
          intermediate: r'''Cyclohexadienyl Radical Intermediate''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Protonation by Alcohol at Ortho/Para</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Alcohol protonates the electron-dense carbanion giving cyclohexadienyl radical</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="60" y="135" fill="#F59E0B" font-size="12" font-family="sans-serif">[Radical Anion]</text>
          <text x="175" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="195" y="135" fill="#38BDF8" font-size="12" font-family="sans-serif">t-BuOH (Proton source)</text>
          <line x1="330" y1="130" x2="380" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="385,130 375,125 375,135" fill="#38BDF8"/>
          <!-- Neutral radical -->
          <polygon points="430,130 445,105 475,105 490,130 475,155 445,155" fill="none" stroke="#38BDF8" stroke-width="2"/>
          <circle cx="430" cy="130" r="4" fill="#F59E0B"/>
          <line x1="490" y1="130" x2="520" y2="130"/>
          <text x="530" y="134" fill="#38BDF8" font-size="11" font-family="sans-serif">OCH3</text>
          <text x="575" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="595" y="135" fill="#10B981" font-size="11" font-family="sans-serif">t-BuO-</text>
        </g>
        <rect x="400" y="195" width="200" height="24" rx="4" fill="#1E293B" stroke="#38BDF8" stroke-width="1"/>
        <text x="500" y="211" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Cyclohexadienyl Radical</text>
        
  <g id="electron-arrows">
    
        <path d="M 120 125 Q 160 95 210 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Second SET & Final Protonation',
          description: r'''A second solvated electron reduces the cyclohexadienyl radical to a cyclohexadienyl anion, which undergoes rapid kinetic protonation at the central carbon, delivering the non-conjugated 1,4-diene.''',
          curvedArrowNotes: r'''Fishhook transfer of second electron, followed by two-electron proton transfer from alcohol delivering 1,4-diene.''',
          intermediate: r'''1,4-Cyclohexadiene + $t\text{-BuO}^- \text{Na}^+$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Second SET & Final Protonation</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Second electron reduces radical; central protonation delivers non-conjugated 1,4-diene</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <!-- 1,4-cyclohexadiene -->
          <polygon points="180,130 195,105 225,105 240,130 225,155 195,155" fill="none" stroke="#10B981" stroke-width="2.2"/>
          <line x1="184" y1="126" x2="197" y2="107" stroke="#10B981" stroke-width="2.5"/>
          <line x1="223" y1="153" x2="236" y2="134" stroke="#10B981" stroke-width="2.5"/>
          <line x1="240" y1="130" x2="275" y2="130"/>
          <text x="285" y="134" fill="#38BDF8" font-size="12" font-family="sans-serif">OCH3</text>
          <text x="360" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="380" y="135" fill="#10B981" font-size="12" font-family="sans-serif">t-BuO- + Na+</text>
        </g>
        <rect x="140" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="250" y="211" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">1-Methoxycyclohexa-1,4-diene</text>
        
  <g id="electron-arrows">
    
        <path d="M 120 120 Q 150 90 180 125" fill="none" stroke="#F59E0B" stroke-width="2.2" marker-end="url(#fishhook)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'heck_coupling',
      name: 'Heck Cross-Coupling',
      aliases: ['Mizoroki-Heck Reaction', 'Palladium-Catalyzed Alkene Arylation'],
      category: ReactionCategory.organometallics,
      summary:
          r'''Palladium-catalyzed cross-coupling of aryl/alkenyl halides or triflates with alkenes in the presence of base. Proceeds via oxidative addition, stereospecific syn-migratory insertion, and syn-beta-hydride elimination to furnish trans-(E)-substituted alkenes.''',
      reactants: r'''Aryl / Alkenyl halide ($\text{Ar-X}$), Terminal or electron-poor alkene ($\text{CH}_2\text{=CH-R}$)''',
      reagentsAndConditions: r'''$\text{Pd(OAc)}_2$ or $\text{Pd(PPh}_3)_4$ (1-5 mol%), Phosphine ligand, $\text{Et}_3\text{N}$ or $\text{K}_2\text{CO}_3$, DMF or MeCN, $80-120^\circ\text{C}$''',
      products: r'''trans-(E)-Substituted alkene ($\text{Ar-CH=CH-R}$), $\text{Et}_3\text{NH}^+\text{X}^-$''',
      regioselectivity: r'''Occurs selectively at the least sterically hindered terminus of electron-poor alkenes (acrylates, styrenes) yielding linear cinnamate/stilbene products.''',
      stereochemistry: r'''Syn-migratory insertion followed by C-C bond rotation and syn-beta-hydride elimination dictates formation of the thermodynamically favored trans-(E)-alkene with high diastereoselectivity.''',
      drivingForce: r'''Thermodynamic stability of the extended conjugated pi-system and precipitation/neutralization of amine hydrohalide salt.''',
      representativeExample: r'''Coupling of iodobenzene with methyl acrylate in the presence of Pd(OAc)2 and Et3N yielding trans-methyl cinnamate in 95% yield.''',
      keyApplications: [
        r'''Industrial synthesis of UV absorbers, sunscreens, and conjugated polymers.''',
        r'''Synthesis of non-steroidal anti-inflammatory drugs and complex bioactive terpenes.''',
      ],
      limitations: [
        r'''Substrates possessing beta-hydrogens on the alkyl halide component undergo competitive beta-hydride elimination rather than coupling.''',
        r'''Aryl chlorides require specialized bulky electron-rich phosphines or N-heterocyclic carbenes (NHCs).''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Oxidative Addition to Pd(0)',
          description: r'''Aryl halide $\text{Ar-X}$ oxidatively adds to the 14e- $[\text{Pd(0)L}_2]$ complex to generate trans-$[\text{Ar-Pd(II)L}_2\text{-X}]$.''',
          curvedArrowNotes: r'''Pd(0) d-electrons insert into Ar-X sigma-bond.''',
          intermediate: r'''trans-$[\text{Ar-Pd(II)L}_2\text{-X}]$ Adduct''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Oxidative Addition of Aryl Halide</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Aryl iodide adds to 14e- Pd(0) complex to generate trans-[Ar-Pd(II)L2-I]</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="120" cy="130" r="20" fill="#1E293B" stroke="#38BDF8" stroke-width="2.2"/>
          <text x="120" y="135" fill="#38BDF8" font-size="12" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(0)L2</text>
          <text x="175" y="135" fill="#94A3B8" font-size="18" font-weight="bold" font-family="sans-serif">+</text>
          <text x="210" y="135" fill="#F8FAFC" font-size="13" font-family="sans-serif">Ph-I</text>
          <line x1="270" y1="130" x2="330" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="335,130 325,125 325,135" fill="#38BDF8"/>
          <circle cx="430" cy="130" r="18" fill="#1E293B" stroke="#F59E0B" stroke-width="2"/>
          <text x="430" y="135" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(II)</text>
          <line x1="412" y1="130" x2="380" y2="130"/>
          <text x="365" y="134" fill="#F8FAFC" font-size="11" font-family="sans-serif">Ph</text>
          <line x1="448" y1="130" x2="480" y2="130"/>
          <text x="490" y="134" fill="#7C3AED" font-size="11" font-weight="bold" font-family="sans-serif">I</text>
        </g>
        <rect x="360" y="195" width="160" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="440" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">trans-[Ph-Pd(II)L2-I]</text>
        
  <g id="electron-arrows">
    
        <path d="M 140 120 Q 180 80 230 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Syn-Migratory Insertion of Alkene',
          description: r'''The alkene coordinates to Pd(II) and undergoes stereospecific syn-addition across the Pd-Ar bond, forming a neutral sigma-alkylpalladium intermediate.''',
          curvedArrowNotes: r'''Syn-addition of Ar and Pd across alkene double bond in a 4-center coplanar transition state.''',
          intermediate: r'''sigma-Alkylpalladium Insertion Intermediate''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Syn-Migratory Insertion of Alkene</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Alkene coordinates to Pd and inserts into Pd-Ar bond with strict syn-stereospecificity</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="60" y="135" fill="#F8FAFC" font-size="12" font-family="sans-serif">CH2=CH-CO2Me</text>
          <text x="180" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="200" y="135" fill="#F59E0B" font-size="12" font-family="sans-serif">[Ph-Pd(II)-I]</text>
          <line x1="300" y1="130" x2="350" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="355,130 345,125 345,135" fill="#38BDF8"/>
          <!-- Syn insertion adduct -->
          <text x="380" y="135" fill="#38BDF8" font-size="12" font-weight="bold" font-family="sans-serif">Ph-CH2-CH(CO2Me)-Pd(II)I</text>
        </g>
        <rect x="360" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#38BDF8" stroke-width="1"/>
        <text x="470" y="211" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Syn-Insertion Palladacycle</text>
        
  <g id="electron-arrows">
    
        <path d="M 120 125 Q 160 90 220 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Syn Beta-Hydride Elimination & Catalyst Regeneration',
          description: r'''Internal rotation aligns a beta-hydrogen syn-periplanar to Pd, followed by syn-beta-hydride elimination to release the (E)-alkene. Base deprotonates $[\text{H-Pd(II)-X}]$ to regenerate active $[\text{Pd(0)L}_2]$.''',
          curvedArrowNotes: r'''Pd abstracts syn-beta-hydrogen with double bond reformation and release of (E)-alkene.''',
          intermediate: r'''(E)-Alkene + Regenerated $[\text{Pd(0)L}_2]$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Syn Beta-Hydride Elimination</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Syn-periplanar beta-H and Pd eliminate yielding (E)-trans alkene + H-Pd-I</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <!-- (E)-trans alkene product -->
          <text x="70" y="135" fill="#F8FAFC" font-size="12" font-family="sans-serif">Ph</text>
          <line x1="90" y1="130" x2="130" y2="130"/>
          <line x1="130" y1="130" x2="160" y2="105"/>
          <line x1="130" y1="126" x2="160" y2="101" stroke="#10B981" stroke-width="2.2"/>
          <line x1="160" y1="105" x2="200" y2="105"/>
          <text x="210" y="110" fill="#10B981" font-size="12" font-weight="bold" font-family="sans-serif">CO2Me</text>
          <text x="290" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="320" y="135" fill="#F59E0B" font-size="12" font-family="sans-serif">[H-Pd-I] + Et3N</text>
          <line x1="420" y1="130" x2="470" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="475,130 465,125 465,135" fill="#38BDF8"/>
          <text x="500" y="135" fill="#38BDF8" font-size="12" font-weight="bold" font-family="sans-serif">Pd(0)L2 + Et3NH+ I-</text>
        </g>
        <rect x="80" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="170" y="211" fill="#10B981" font-size="11.5" font-weight="bold" text-anchor="middle" font-family="sans-serif">(E)-Methyl Cinnamate</text>
        
  <g id="electron-arrows">
    
        <path d="M 145 110 Q 155 80 180 95" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'corey_chaykovsky',
      name: 'Corey-Chaykovsky Reaction',
      aliases: ['Corey-Chaykovsky Epoxidation', 'Sulfur Ylide Epoxidation / Cyclopropanation'],
      category: ReactionCategory.rearrangements,
      summary:
          r'''Reaction of sulfur ylides with aldehydes, ketones, or imines to synthesize epoxides, cyclopropanes, or aziridines. Dimethylsulfonium methylide delivers epoxides via kinetic 1,2-addition, whereas dimethyloxosulfonium methylide adds 1,4-conjugate to alpha,beta-unsaturated systems to form cyclopropanes.''',
      reactants: r'''Carbonyl compound (Ketone / Aldehyde), Trimethylsulfonium iodide / NaH''',
      reagentsAndConditions: r'''$\text{Me}_3\text{S}^+\text{I}^-$ (1.2 equiv), $\text{NaH}$ (1.2 equiv), Anhydrous DMSO/THF, $0^\circ\text{C}$ to room temperature''',
      products: r'''Epoxide (Oxirane), Dimethyl sulfide ($\text{Me}_2\text{S}$)''',
      regioselectivity: r'''Sulfonium methylide ($Me_2S=CH_2$) attacks under kinetic control (1,2-addition to enones giving epoxides); Oxosulfonium methylide ($Me_2S(O)=CH_2$) undergoes reversible 1,4-conjugate addition giving cyclopropanes.''',
      stereochemistry: r'''Diastereoselective ring closure governed by anti-periplanar alignment of the alkoxide oxygen and sulfonium leaving group during intramolecular SN2 displacement.''',
      drivingForce: r'''Relief of charge separation in the zwitterionic betaine intermediate and expulsion of the neutral, volatile dimethyl sulfide leaving group ($Me_2S$).''',
      representativeExample: r'''Conversion of cyclohexanone to 1-oxaspiro[2.5]octane in 91% yield using dimethylsulfonium methylide.''',
      keyApplications: [
        r'''Synthesis of spiro-epoxides and cyclopropanes in steroid and polycycle building.''',
        r'''Enantioselective epoxidation utilizing chiral camphor-derived sulfide catalysts.''',
      ],
      limitations: [
        r'''Requires strong base (NaH, DMSO) which can deprotonate enolizable ketones causing aldol condensation.''',
        r'''Reagents produce noxious dimethyl sulfide byproduct.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Sulfur Ylide Generation',
          description: r'''Deprotonation of trimethylsulfonium iodide with NaH generates dimethylsulfonium methylide as a nucleophilic sulfur ylide.''',
          curvedArrowNotes: r'''Hydride abstracts methyl proton forming H2 gas and carbanionic ylide.''',
          intermediate: r'''$[\text{Me}_2\text{S}^+-\text{CH}_2^-]$ Sulfur Ylide''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Sulfur Ylide Generation</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Deprotonation of trimethylsulfonium iodide with NaH generates dimethylsulfonium methylide</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="70" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">[Me3S+] I-</text>
          <text x="160" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="180" y="135" fill="#38BDF8" font-size="12" font-family="sans-serif">NaH (DMSO)</text>
          <line x1="280" y1="130" x2="330" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="335,130 325,125 325,135" fill="#38BDF8"/>
          <text x="360" y="135" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">Me2S+-CH2- &lt;=&gt; Me2S=CH2</text>
          <text x="540" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="560" y="135" fill="#10B981" font-size="12" font-family="sans-serif">H2 (g)</text>
        </g>
        <rect x="340" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#EF4444" stroke-width="1"/>
        <text x="450" y="211" fill="#EF4444" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Dimethylsulfonium Methylide</text>
        
  <g id="electron-arrows">
    
        <path d="M 210 120 Q 250 85 300 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic 1,2-Addition to Carbonyl',
          description: r'''The ylide carbanion attacks the electrophilic carbonyl carbon in a 1,2-addition, generating a tetrahedral zwitterionic betaine intermediate.''',
          curvedArrowNotes: r'''Ylide carbanion attacks carbonyl carbon, pushing pi-electrons to oxygen.''',
          intermediate: r'''$[\text{Me}_2\text{S}^+-\text{CH}_2-\text{C(R}_2)-\text{O}^-]$ Betaine Intermediate''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Nucleophilic Addition to Carbonyl</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Ylide carbanion attacks ketone carbonyl in 1,2-addition forming betaine intermediate</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="60" y="135" fill="#EF4444" font-size="12" font-family="sans-serif">Me2S+-CH2:-</text>
          <text x="170" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <!-- Cyclohexanone -->
          <polygon points="210,130 225,105 255,105 270,130 255,155 225,155" fill="none" stroke="#E2E8F0" stroke-width="2"/>
          <line x1="270" y1="130" x2="300" y2="130"/>
          <text x="310" y="134" fill="#EF4444" font-size="12" font-family="sans-serif">=O</text>
          <line x1="340" y1="130" x2="390" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="395,130 385,125 385,135" fill="#38BDF8"/>
          <!-- Betaine intermediate -->
          <text x="420" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">Me2S+-CH2-C(R2)-O-</text>
        </g>
        <rect x="400" y="195" width="200" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="500" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Zwitterionic Betaine Adduct</text>
        
  <g id="electron-arrows">
    
        <path d="M 125 125 Q 180 85 270 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Intramolecular SN2 Ring Closure',
          description: r'''The alkoxide oxygen executes an intramolecular $S_N2$ backside attack on the methylene carbon, expelling dimethyl sulfide as a neutral leaving group to close the 3-membered oxirane ring.''',
          curvedArrowNotes: r'''Alkoxide oxygen attacks CH2 carbon, cleanly displacing neutral Me2S.''',
          intermediate: r'''Epoxide (Oxirane) + $\text{Me}_2\text{S}$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Intramolecular SN2 Ring Closure</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Alkoxide oxygen displaces neutral Me2S leaving group closing oxirane ring</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <!-- Epoxide -->
          <polygon points="160,130 175,105 205,105 220,130 205,155 175,155" fill="none" stroke="#10B981" stroke-width="2"/>
          <line x1="220" y1="130" x2="260" y2="115" stroke="#10B981" stroke-width="2"/>
          <line x1="220" y1="130" x2="260" y2="145" stroke="#10B981" stroke-width="2"/>
          <line x1="260" y1="115" x2="260" y2="145" stroke="#10B981" stroke-width="2"/>
          <text x="268" y="134" fill="#EF4444" font-size="13" font-weight="bold" font-family="sans-serif">O</text>
          <text x="330" y="135" fill="#94A3B8" font-size="18" font-family="sans-serif">+</text>
          <text x="360" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">Me2S (dimethyl sulfide leaving group)</text>
        </g>
        <rect x="140" y="195" width="200" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="240" y="211" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Oxirane / Epoxide Ring Closure</text>
        
  <g id="electron-arrows">
    
        <path d="M 270 120 Q 250 85 225 115" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'stille_coupling',
      name: 'Stille Cross-Coupling',
      aliases: ['Stille Reaction', 'Migita-Kosugi-Stille Coupling', 'Organotin Cross-Coupling'],
      category: ReactionCategory.organometallics,
      summary:
          r'''Palladium-catalyzed cross-coupling reaction between organotin compounds (organostannanes) and organic halides or pseudohalides. Features exceptional functional group tolerance due to the mild, neutral nature of organostannanes.''',
      reactants: r'''Organohalide / Triflate ($\text{R-X}$), Organostannane ($\text{R\'-SnBu}_3$)''',
      reagentsAndConditions: r'''$\text{Pd(PPh}_3)_4$ (1-5 mol%), LiCl, CuI (cocatalyst), 1,4-Dioxane or Toluene, $80-110^\circ\text{C}$''',
      products: r'''Cross-coupled product ($\text{R-R\'}$), Trialkyltin halide ($\text{Bu}_3\text{Sn-X}$)''',
      regioselectivity: r'''Selective transfer of sp2/sp alkynyl, alkenyl, or aryl groups from tin over the spectator sp3 butyl or methyl groups ($k_\text{alkynyl} > k_\text{alkenyl} > k_\text{aryl} \gg k_\text{alkyl}$).''',
      stereochemistry: r'''Complete retention of double bond geometry ($E/Z$) in both the alkenylstannane and alkenyl halide components.''',
      drivingForce: r'''Thermodynamic formation of the robust C-C bond and precipitation/formation of insoluble trialkyltin halide driven by halide additives (LiCl, KF).''',
      representativeExample: r'''Coupling of bromobenzene with tributyl(vinyl)stannane in the presence of Pd(PPh3)4 yielding styrene (>90% yield).''',
      keyApplications: [
        r'''Total synthesis of complex, delicate polyene macrolides (e.g. Rapamycin, Amphotericin B).''',
        r'''Coupling of acid-sensitive and base-sensitive multifunctional drug intermediates.''',
      ],
      limitations: [
        r'''High toxicity of organotin reagents and byproducts; organotin residues are notoriously difficult to remove from pharmaceutical compounds.''',
        r'''Requires stoichiometric organostannane waste handling.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Oxidative Addition to Pd(0)',
          description: r'''Organohalide $\text{R-X}$ oxidatively adds across $[\text{Pd(0)L}_2]$ to yield a 16-electron square-planar trans-$[\text{R-Pd(II)L}_2\text{-X}]$ complex.''',
          curvedArrowNotes: r'''Pd(0) inserts into R-X bond with loss of coordinate ligand.''',
          intermediate: r'''trans-$[\text{R-Pd(II)L}_2\text{-X}]$ Complex''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Oxidative Addition</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Aryl or alkenyl halide oxidatively adds to Pd(0)L2 to form Pd(II) complex</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <circle cx="120" cy="130" r="20" fill="#1E293B" stroke="#38BDF8" stroke-width="2.2"/>
          <text x="120" y="135" fill="#38BDF8" font-size="12" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(0)L2</text>
          <text x="175" y="135" fill="#94A3B8" font-size="18" font-weight="bold" font-family="sans-serif">+</text>
          <text x="210" y="135" fill="#F8FAFC" font-size="13" font-family="sans-serif">R-X (X = Br, I, OTf)</text>
          <line x1="330" y1="130" x2="380" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="385,130 375,125 375,135" fill="#38BDF8"/>
          <text x="410" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">trans-[R-Pd(II)L2-X]</text>
        </g>
        <rect x="380" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="470" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">trans-Square Planar Adduct</text>
        
  <g id="electron-arrows">
    
        <path d="M 140 120 Q 200 80 270 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Transmetalation with Organostannane',
          description: r'''The organostannane $\text{R\'-SnBu}_3$ transfers its organic group to Pd(II) via an open or cyclic associative transition state, generating cis-$[\text{R-Pd(II)L}_2\text{-R\']}$ and trialkyltin halide.''',
          curvedArrowNotes: r'''Transmetalation: R\' group transfers from Sn to Pd, displacing halide onto Sn.''',
          intermediate: r'''cis-$[\text{R-Pd(II)L}_2\text{-R\']}$ Complex''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Transmetalation with Organostannane</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">R'-SnBu3 transfers R' group to Pd(II) with formation of Bu3Sn-X byproduct</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="60" y="135" fill="#38BDF8" font-size="12" font-family="sans-serif">R'-SnBu3</text>
          <text x="145" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="170" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">[R-Pd(II)L2-X]</text>
          <line x1="280" y1="130" x2="330" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="335,130 325,125 325,135" fill="#38BDF8"/>
          <text x="355" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">cis-[R-Pd(II)L2-R']</text>
          <text x="495" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="515" y="135" fill="#10B981" font-size="12" font-family="sans-serif">Bu3Sn-X (toxic)</text>
        </g>
        <rect x="340" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="430" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">cis-Diorganopalladium</text>
        
  <g id="electron-arrows">
    
        <path d="M 110 125 Q 160 85 220 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Reductive Elimination & C-C Coupling',
          description: r'''Cis-oriented R and R\' groups undergo concerted reductive elimination, forging the new C-C bond and regenerating the active $[\text{Pd(0)L}_2]$ catalyst.''',
          curvedArrowNotes: r'''Concerted C-C bond formation with simultaneous return of 2 electrons to Pd(0).''',
          intermediate: r'''Cross-Coupled Product ($\text{R-R\'}$) + Regenerated $[\text{Pd(0)L}_2]$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Reductive Elimination</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Concerted C-C bond formation yields R-R' product and regenerates Pd(0) catalyst</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="60" y="135" fill="#F59E0B" font-size="12" font-family="sans-serif">cis-[R-Pd(II)L2-R']</text>
          <line x1="180" y1="130" x2="230" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="235,130 225,125 225,135" fill="#38BDF8"/>
          <text x="260" y="135" fill="#10B981" font-size="14" font-weight="bold" font-family="sans-serif">R-R' Cross-Coupled</text>
          <text x="430" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <circle cx="480" cy="130" r="18" fill="#1E293B" stroke="#38BDF8" stroke-width="2"/>
          <text x="480" y="135" fill="#38BDF8" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Pd(0)L2</text>
        </g>
        <rect x="240" y="195" width="180" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="330" y="211" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">High Functional Group Tolerance</text>
        
  <g id="electron-arrows">
    
        <path d="M 120 125 Q 160 90 200 120" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

    ReactionMechanism(
      id: 'favorskii_rearrangement',
      name: 'Favorskii Rearrangement',
      aliases: ['Favorskii Ester Synthesis', 'Cyclopropanone Ring Contraction'],
      category: ReactionCategory.rearrangements,
      summary:
          r'''Base-catalyzed rearrangement of alpha-haloketones into carboxylic acid derivatives (esters, amides, acids) via a strained cyclopropanone intermediate. Cyclic alpha-haloketones undergo stereospecific ring contraction to provide smaller cycloalkane carboxylic acid derivatives.''',
      reactants: r'''$\alpha$-Haloketone (e.g. 2-Chlorocyclohexanone), Alkoxide base ($\text{RONa}$)''',
      reagentsAndConditions: r'''$\text{NaOMe}$ or $\text{NaOEt}$ (1.5 equiv), $\text{MeOH}$ or $\text{EtOH}$, $0^\circ\text{C}$ to $60^\circ\text{C}$''',
      products: r'''Ring-contracted ester (e.g. Methyl cyclopentanecarboxylate), Halide salt''',
      regioselectivity: r'''Cleavage of the unsymmetrical cyclopropanone intermediate occurs regioselectively to generate the more thermodynamically stable carbanion intermediate prior to protonation.''',
      stereochemistry: r'''Inversion of configuration occurs at the alpha-carbon bearing halogen during intramolecular enolate displacement to close the cyclopropanone ring.''',
      drivingForce: r'''Tremendous relief of angle strain in the 3-membered cyclopropanone ring ($\sim 115\text{ kJ/mol}$) upon nucleophilic addition and ring cleavage.''',
      representativeExample: r'''Rearrangement of 2-chlorocyclohexanone with sodium methoxide to methyl cyclopentanecarboxylate in 85% yield.''',
      keyApplications: [
        r'''Ring contraction of cyclohexanes and cycloheptanes to cyclopentanes and cyclohexanes in terpene synthesis.''',
        r'''Key step in the classic total synthesis of cubane (Eaton cubane synthesis).''',
      ],
      limitations: [
        r'''Alpha-haloketones without alpha\'-hydrogens undergo quasi-Favorskii rearrangements via benzylic-acid-type semi-pinacol mechanisms instead.''',
        r'''Strong alkoxide can promote alpha,beta-elimination yielding enones as competing side products.''',
      ],
      isVerified: true,
      verificationStatus: 'verified',
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Enolization & Cyclopropanone Formation',
          description: r'''Alkoxide base deprotonates the alpha\'-carbon. The resulting enolate executes an intramolecular $S_N2$ displacement of the alpha-halogen, constructing a highly strained cyclopropanone intermediate.''',
          curvedArrowNotes: r'''Enolate alpha-carbon attacks alpha\'-carbon with Walden inversion, displacing chloride.''',
          intermediate: r'''Strained Cyclopropanone Intermediate''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 1: Enolization & Cyclopropanone Formation</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Alkoxide base abstracts alpha'-H; intramolecular displacement of halogen forms 3-membered ring</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <!-- 2-chlorocyclohexanone -->
          <polygon points="120,130 135,105 165,105 180,130 165,155 135,155" fill="none" stroke="#E2E8F0" stroke-width="2"/>
          <line x1="180" y1="130" x2="210" y2="130"/>
          <text x="220" y="134" fill="#EF4444" font-size="12" font-family="sans-serif">=O</text>
          <line x1="165" y1="155" x2="165" y2="185"/>
          <text x="165" y="198" fill="#10B981" font-size="12" font-weight="bold" text-anchor="middle" font-family="sans-serif">Cl</text>
          <text x="255" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="280" y="135" fill="#38BDF8" font-size="12" font-family="sans-serif">RO- Base</text>
          <line x1="360" y1="130" x2="410" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="415,130 405,125 405,135" fill="#38BDF8"/>
          <!-- Cyclopropanone intermediate -->
          <text x="435" y="135" fill="#F59E0B" font-size="12" font-weight="bold" font-family="sans-serif">Bicyclo[3.1.0]hexan-6-one (Strained)</text>
        </g>
        <rect x="400" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#F59E0B" stroke-width="1"/>
        <text x="510" y="211" fill="#F59E0B" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Key Cyclopropanone Intermediate</text>
        
  <g id="electron-arrows">
    
        <path d="M 300 120 Q 230 80 145 100" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        <path d="M 135 155 Q 145 175 160 175" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Addition to Strained Carbonyl',
          description: r'''Alkoxide ($RO^-$) attacks the carbonyl carbon of the cyclopropanone, relieving angle strain partially and forming a tetrahedral hemiacetal alkoxide intermediate.''',
          curvedArrowNotes: r'''Alkoxide lone pair attacks carbonyl carbon, shifting pi-electrons to oxygen.''',
          intermediate: r'''Tetrahedral Hemiacetal Alkoxide Adduct''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 2: Nucleophilic Attack of Alkoxide on Strained Carbonyl</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">RO- attacks cyclopropanone carbonyl forming tetrahedral hemiacetal alkoxide</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <text x="60" y="135" fill="#38BDF8" font-size="12" font-family="sans-serif">RO:-</text>
          <text x="110" y="135" fill="#94A3B8" font-size="16" font-family="sans-serif">+</text>
          <text x="135" y="135" fill="#F59E0B" font-size="12" font-family="sans-serif">[Cyclopropanone]</text>
          <line x1="260" y1="130" x2="310" y2="130" stroke="#38BDF8" stroke-width="2"/>
          <polygon points="315,130 305,125 305,135" fill="#38BDF8"/>
          <text x="340" y="135" fill="#EF4444" font-size="12" font-weight="bold" font-family="sans-serif">Tetrahedral Intermediate [-O-C(OR)-cyclopropyl]</text>
        </g>
        <rect x="320" y="195" width="260" height="24" rx="4" fill="#1E293B" stroke="#EF4444" stroke-width="1"/>
        <text x="450" y="211" fill="#EF4444" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Tetrahedral Addition Intermediate</text>
        
  <g id="electron-arrows">
    
        <path d="M 90 125 Q 140 90 185 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Strain-Driven Ring Cleavage & Protonation',
          description: r'''The tetrahedral intermediate collapses, expelling a cyclopropane C-C bond towards the carbon that can better stabilize negative charge. Subsequent protonation yields the ring-contracted ester.''',
          curvedArrowNotes: r'''Alkoxide electrons reform C=O double bond, cleaving strained 3-membered ring bond to carbanion, which captures proton from alcohol solvent.''',
          intermediate: r'''Ring-Contracted Ester + $\text{RO}^-$''',
          svgContent: r'''<svg viewBox="0 0 660 240" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arrowhead" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#E54D2E"/>
    </marker>
    <marker id="fishhook" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 2 L 8 5 L 4 5 z" fill="#F59E0B"/>
    </marker>
    <marker id="arrowhead-violet" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#A855F7"/>
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#0B0F19" rx="12" stroke="#1E293B" stroke-width="1.5"/>
  <text x="24" y="28" fill="#A855F7" font-size="12" font-weight="bold" font-family="system-ui, -apple-system, sans-serif">Step 3: Relief of Ring Strain & Ring Contraction</text>
  <text x="24" y="46" fill="#94A3B8" font-size="11" font-family="system-ui, -apple-system, sans-serif">Cleavage to more stable carbanion followed by protonation gives ring-contracted ester</text>
  
        <g stroke="#E2E8F0" stroke-width="2" stroke-linecap="round">
          <!-- Cyclopentanecarboxylate ester -->
          <polygon points="160,130 180,105 210,115 210,145 180,155" fill="none" stroke="#10B981" stroke-width="2"/>
          <line x1="210" y1="130" x2="245" y2="130"/>
          <line x1="245" y1="130" x2="265" y2="105"/>
          <text x="268" y="100" fill="#EF4444" font-size="12" font-family="sans-serif">=O</text>
          <line x1="245" y1="130" x2="265" y2="155"/>
          <text x="270" y="165" fill="#38BDF8" font-size="12" font-family="sans-serif">OR</text>
        </g>
        <rect x="130" y="195" width="220" height="24" rx="4" fill="#1E293B" stroke="#10B981" stroke-width="1"/>
        <text x="240" y="211" fill="#10B981" font-size="11" font-weight="bold" text-anchor="middle" font-family="sans-serif">Ring-Contracted Cyclopentane Ester</text>
        
  <g id="electron-arrows">
    
        <path d="M 180 115 Q 220 90 245 125" fill="none" stroke="#E54D2E" stroke-width="2.2" marker-end="url(#arrowhead)"/>
        
  </g>
</svg>''',
        ),
      ],
    ),

  ];

  static final Map<String, Reaction3DSet> molecular3DSets = {
    'sharpless_epoxidation': Reaction3DSet(
      reactionId: 'sharpless_epoxidation',
      title: 'Sharpless Asymmetric Epoxidation',
      keyTransformationNote: 'Observe chiral facial delivery: (E)-allylic alcohol coordinated with titanium tartrate peroxo complex, followed by stereospecific oxygen insertion yielding (2R,3R)-epoxygeraniol.',
      reactant:
        const Molecule3D(
          id: 'sharpless_reactant',
          name: 'Geraniol (Allylic Alcohol)',
          formula: 'C10H18O',
          iupacName: '(2E)-3,7-dimethylocta-2,6-dien-1-ol',
          description: 'Planar (E)-allylic double bond positioned for coordination to chiral titanate.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'C2 allylic alkene carbon'),
            Atom3D(symbol: 'C', x: 1.34, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'C3 substituted alkene carbon'),
            Atom3D(symbol: 'C', x: -0.75, y: 1.25, z: 0.0, hybridization: 'sp³', note: 'C1 hydroxymethyl carbon'),
            Atom3D(symbol: 'O', x: -0.2, y: 2.45, z: 0.2, hybridization: 'sp³', note: 'Coordinating hydroxyl oxygen'),
            Atom3D(symbol: 'H', x: -0.8, y: 3.1, z: 0.25, note: 'Hydroxyl proton'),
            Atom3D(symbol: 'C', x: 2.1, y: 1.25, z: 0.0, hybridization: 'sp³', note: 'C4 methyl group'),
            Atom3D(symbol: 'C', x: 2.1, y: -1.25, z: 0.0, hybridization: 'sp³', note: 'C5 prenyl tail carbon'),
            Atom3D(symbol: 'H', x: -0.5, y: -0.9, z: 0.0, note: 'Alkene C2 proton'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 1, atomIndex2: 5),
            Bond3D(atomIndex1: 1, atomIndex2: 6),
            Bond3D(atomIndex1: 0, atomIndex2: 7),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'sharpless_intermediate',
          name: 'Titanium-Tartrate Peroxo Complex',
          formula: '[Ti(DET)(OiPr)(tBuOO)(AllylO)]',
          iupacName: 'bimetallic titanate chiral ternary complex',
          description: 'Chiral pocket holding allylic alcohol and peroxide oxygen in proximity.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'C2 alkene center'),
            Atom3D(symbol: 'C', x: 1.34, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'C3 alkene center'),
            Atom3D(symbol: 'O', x: 0.67, y: 0.8, z: 1.6, note: 'Electrophilic peroxo oxygen migrating to alkene'),
            Atom3D(symbol: 'O', x: 1.8, y: 1.4, z: 1.8, note: 'Peroxide oxygen bound to t-Bu'),
            Atom3D(symbol: 'C', x: 2.8, y: 2.2, z: 1.8, note: 'tert-Butyl quaternary carbon'),
            Atom3D(symbol: 'C', x: -0.75, y: 1.25, z: 0.0),
            Atom3D(symbol: 'O', x: -0.2, y: 2.45, z: 0.2, note: 'Ti-coordinated allylic oxygen'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.partial),
            Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.partial),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 0, atomIndex2: 5),
            Bond3D(atomIndex1: 5, atomIndex2: 6),
          ],
        ),
      product:
        const Molecule3D(
          id: 'sharpless_product',
          name: '(2R,3R)-Epoxygeraniol',
          formula: 'C10H18O2',
          iupacName: '[(2R,3R)-3-methyl-3-(4-methylpent-3-en-1-yl)oxiran-2-yl]methanol',
          description: 'Enantiopure (2R,3R) oxirane ring with preserved stereocenter.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'C2 chiral stereocenter (R)'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'C3 chiral stereocenter (R)'),
            Atom3D(symbol: 'O', x: 0.72, y: 1.2, z: 0.0, hybridization: 'sp³', note: 'Epoxide oxirane ring oxygen'),
            Atom3D(symbol: 'C', x: -0.8, y: -1.25, z: 0.0, hybridization: 'sp³', note: 'C1 hydroxymethyl'),
            Atom3D(symbol: 'O', x: -0.25, y: -2.45, z: 0.1, hybridization: 'sp³'),
            Atom3D(symbol: 'H', x: -0.85, y: -3.15, z: 0.15),
            Atom3D(symbol: 'C', x: 2.15, y: -1.25, z: 0.0),
            Atom3D(symbol: 'C', x: 2.15, y: 1.25, z: 0.0),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 4, atomIndex2: 5),
            Bond3D(atomIndex1: 1, atomIndex2: 6),
            Bond3D(atomIndex1: 1, atomIndex2: 7),
          ],
        ),
    ),
    'suzuki_coupling': Reaction3DSet(
      reactionId: 'suzuki_coupling',
      title: 'Suzuki-Miyaura Cross-Coupling',
      keyTransformationNote: 'Observe transition from aryl halide + boronic acid to square-planar Pd(II) intermediate, followed by reductive elimination to biaryl.',
      reactant:
        const Molecule3D(
          id: 'suzuki_reactant',
          name: 'Bromobenzene + Phenylboronic Acid',
          formula: 'C6H5Br + C6H5B(OH)2',
          iupacName: 'bromobenzene and phenylboronic acid',
          description: 'Electrophilic aryl halide and nucleophilic organoboron coupling partners.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Aryl C-Br ipso carbon'),
            Atom3D(symbol: 'Br', x: 0.0, y: 0.0, z: 1.9, note: 'Halide leaving group'),
            Atom3D(symbol: 'C', x: 1.2, y: 0.7, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 1.2, y: 2.1, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.8, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -1.2, y: 2.1, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -1.2, y: 0.7, z: 0.0, hybridization: 'sp²'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 5, atomIndex2: 6, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 6, atomIndex2: 0, type: BondType3D.aromatic),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'suzuki_intermediate',
          name: 'cis-Bis(triphenylphosphine)diphenylpalladium(II)',
          formula: '[Pd(PPh3)2(Ph)2]',
          iupacName: 'cis-diphenylbis(triphenylphosphine)palladium(II)',
          description: 'Square-planar 16e- Pd(II) complex with cis-oriented phenyl ligands ready for elimination.',
          atoms: [
            Atom3D(symbol: 'Pd', x: 0.0, y: 0.0, z: 0.0, note: 'Square-planar Pd(II) center'),
            Atom3D(symbol: 'C', x: 2.05, y: 0.0, z: 0.0, note: 'Phenyl ligand 1 ipso carbon'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.05, z: 0.0, note: 'Phenyl ligand 2 ipso carbon'),
            Atom3D(symbol: 'P', x: -2.3, y: 0.0, z: 0.0, note: 'PPh3 ligand 1'),
            Atom3D(symbol: 'P', x: 0.0, y: -2.3, z: 0.0, note: 'PPh3 ligand 2'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
            Bond3D(atomIndex1: 0, atomIndex2: 4),
            Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.partial),
          ],
        ),
      product:
        const Molecule3D(
          id: 'suzuki_product',
          name: 'Biphenyl',
          formula: 'C12H10',
          iupacName: '1,1\'-biphenyl',
          description: 'Robust sp2-sp2 biaryl product with dihedral twist angle.',
          atoms: [
            Atom3D(symbol: 'C', x: -0.75, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Ring 1 ipso carbon'),
            Atom3D(symbol: 'C', x: 0.75, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Ring 2 ipso carbon'),
            Atom3D(symbol: 'C', x: -1.45, y: 1.2, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -2.85, y: 1.2, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -3.55, y: 0.0, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -2.85, y: -1.2, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -1.45, y: -1.2, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 1.45, y: 1.15, z: 0.4, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 2.85, y: 1.15, z: 0.4, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 3.55, y: 0.0, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 2.85, y: -1.15, z: -0.4, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 1.45, y: -1.15, z: -0.4, hybridization: 'sp²'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 5, atomIndex2: 6, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 6, atomIndex2: 0, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 1, atomIndex2: 7, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 7, atomIndex2: 8, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 8, atomIndex2: 9, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 9, atomIndex2: 10, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 10, atomIndex2: 11, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 11, atomIndex2: 1, type: BondType3D.aromatic),
          ],
        ),
    ),
    'mitsunobu_reaction': Reaction3DSet(
      reactionId: 'mitsunobu_reaction',
      title: 'Mitsunobu Reaction',
      keyTransformationNote: 'Observe 100% Walden inversion: (R)-2-octanol activated as alkoxyphosphonium undergoes backside attack by benzoate to furnish (S)-2-octyl benzoate.',
      reactant:
        const Molecule3D(
          id: 'mitsunobu_reactant',
          name: '(R)-2-Octanol',
          formula: 'C8H18O',
          iupacName: '(2R)-octan-2-ol',
          description: 'Chiral secondary alcohol with (R) stereocenter.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Chiral C2 carbon (R)'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45, hybridization: 'sp³', note: 'Hydroxyl oxygen'),
            Atom3D(symbol: 'H', x: 0.85, y: 0.0, z: 1.85, note: 'Hydroxyl proton'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.52, hybridization: 'sp³', note: 'C1 methyl'),
            Atom3D(symbol: 'C', x: -0.75, y: 1.25, z: -0.52, hybridization: 'sp³', note: 'C3 hexyl chain'),
            Atom3D(symbol: 'H', x: -0.5, y: -0.9, z: -0.35, note: 'Alpha-hydrogen'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
            Bond3D(atomIndex1: 0, atomIndex2: 4),
            Bond3D(atomIndex1: 0, atomIndex2: 5),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'mitsunobu_intermediate',
          name: 'Alkoxyphosphonium Ion + Benzoate',
          formula: '[Ph3P-O-CH(CH3)C6H13]+ + PhCOO-',
          iupacName: 'alkoxyphosphonium intermediate',
          description: 'Positively charged phosphorus activating oxygen as leaving group for SN2.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Chiral carbinol carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45, note: 'Leaving oxygen'),
            Atom3D(symbol: 'P', x: 0.0, y: 0.0, z: 3.1, formalCharge: '+1', note: 'Phosphonium cation'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.52),
            Atom3D(symbol: 'C', x: -0.75, y: 1.25, z: -0.52),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: -2.3, formalCharge: '-1', note: 'Nucleophile attacking 180 deg backside'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
            Bond3D(atomIndex1: 0, atomIndex2: 4),
            Bond3D(atomIndex1: 0, atomIndex2: 5, type: BondType3D.partial),
          ],
        ),
      product:
        const Molecule3D(
          id: 'mitsunobu_product',
          name: '(S)-2-Octyl Benzoate',
          formula: 'C15H22O2',
          iupacName: '[(2S)-octan-2-yl] benzoate',
          description: 'Inverted (S) stereocenter with ester linkage.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Inverted chiral C2 carbon (S)'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: -1.45, hybridization: 'sp³', note: 'Inverted ester oxygen'),
            Atom3D(symbol: 'C', x: 1.2, y: 0.0, z: -2.15, hybridization: 'sp²', note: 'Benzoate carbonyl carbon'),
            Atom3D(symbol: 'O', x: 2.25, y: 0.0, z: -1.55, hybridization: 'sp²', note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: 0.52, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -0.75, y: 1.25, z: 0.52, hybridization: 'sp³'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 4),
            Bond3D(atomIndex1: 0, atomIndex2: 5),
          ],
        ),
    ),
    'baeyer_villiger': Reaction3DSet(
      reactionId: 'baeyer_villiger',
      title: 'Baeyer-Villiger Oxidation',
      keyTransformationNote: 'Observe ring expansion: cyclohexanone forms tetrahedral Criegee intermediate, followed by concerted migration of C-C bond to peroxy oxygen to yield epsilon-caprolactone.',
      reactant:
        const Molecule3D(
          id: 'baeyer_reactant',
          name: 'Cyclohexanone',
          formula: 'C6H10O',
          iupacName: 'cyclohexanone',
          description: 'Chair conformation cyclic ketone with electrophilic carbonyl.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Carbonyl carbon C1'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.22, hybridization: 'sp²', note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'C', x: 1.25, y: 0.0, z: -0.85, hybridization: 'sp³', note: 'Alpha-carbon C2'),
            Atom3D(symbol: 'C', x: 1.25, y: 1.45, z: -1.45, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.15, z: -0.85, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -1.25, y: 1.45, z: -1.45, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -1.25, y: 0.0, z: -0.85, hybridization: 'sp³', note: 'Alpha-carbon C6'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 4, atomIndex2: 5),
            Bond3D(atomIndex1: 5, atomIndex2: 6),
            Bond3D(atomIndex1: 6, atomIndex2: 0),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'baeyer_intermediate',
          name: 'Criegee Intermediate',
          formula: 'C13H15ClO4',
          iupacName: 'tetrahedral peroxyhemiacetal adduct',
          description: 'Tetrahedral center with peroxide O-O bond ready for migration.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Tetrahedral C1 carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45, note: 'Hydroxyl group'),
            Atom3D(symbol: 'O', x: 1.4, y: 0.0, z: 0.35, note: 'Peroxy oxygen accepting alkyl migration'),
            Atom3D(symbol: 'O', x: 2.15, y: 1.2, z: 0.35, note: 'Peroxy oxygen bound to aroyl group'),
            Atom3D(symbol: 'C', x: 0.0, y: 1.45, z: -0.75, note: 'Migrating alpha-carbon'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 0, atomIndex2: 4),
            Bond3D(atomIndex1: 2, atomIndex2: 4, type: BondType3D.partial),
          ],
        ),
      product:
        const Molecule3D(
          id: 'baeyer_product',
          name: 'epsilon-Caprolactone',
          formula: 'C6H10O2',
          iupacName: 'oxepan-2-one',
          description: '7-membered cyclic lactone formed by oxygen insertion.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Lactone carbonyl C2'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.22, note: 'Exocyclic carbonyl oxygen'),
            Atom3D(symbol: 'O', x: 1.35, y: 0.0, z: -0.45, note: 'Inserted ring oxygen O1'),
            Atom3D(symbol: 'C', x: 2.15, y: 1.15, z: -0.85, hybridization: 'sp³', note: 'Ring carbon C7'),
            Atom3D(symbol: 'C', x: 1.55, y: 2.45, z: -1.35, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.75, z: -1.05, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -1.15, y: 2.05, z: -1.65, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -1.15, y: 0.6, z: -0.85, hybridization: 'sp³', note: 'Alpha-carbon C3'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 4, atomIndex2: 5),
            Bond3D(atomIndex1: 5, atomIndex2: 6),
            Bond3D(atomIndex1: 6, atomIndex2: 7),
            Bond3D(atomIndex1: 7, atomIndex2: 0),
          ],
        ),
    ),
    'swern_oxidation': Reaction3DSet(
      reactionId: 'swern_oxidation',
      title: 'Swern Oxidation',
      keyTransformationNote: 'Observe chemoselective alcohol oxidation: benzyl alcohol activated by sulfonium cation, followed by 5-membered cyclic elimination yielding benzaldehyde.',
      reactant:
        const Molecule3D(
          id: 'swern_reactant',
          name: 'Benzyl Alcohol',
          formula: 'C7H8O',
          iupacName: 'phenylmethanol',
          description: 'Primary benzylic alcohol with intact carbinol methylene.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Carbinol carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45, note: 'Hydroxyl oxygen'),
            Atom3D(symbol: 'H', x: 0.85, y: 0.0, z: 1.85, note: 'Hydroxyl proton'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.52, hybridization: 'sp²', note: 'Phenyl ipso carbon'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'swern_intermediate',
          name: 'Alkoxydimethylsulfonium Cation',
          formula: '[PhCH2-O-SMe2]+',
          iupacName: 'alkoxydimethylsulfonium intermediate',
          description: 'Positively charged sulfur activating carbinol proton for elimination.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Carbinol carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45, note: 'Oxygen atom'),
            Atom3D(symbol: 'S', x: 0.0, y: 1.65, z: 1.8, formalCharge: '+1', note: 'Sulfonium cation'),
            Atom3D(symbol: 'C', x: 1.4, y: 2.1, z: 1.2, note: 'Methyl 1'),
            Atom3D(symbol: 'C', x: -1.2, y: 2.4, z: 1.2, note: 'Methyl 2 (deprotonated to ylide)'),
            Atom3D(symbol: 'H', x: 0.9, y: -0.5, z: 0.35, note: 'Carbinol proton abstracted in elimination'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 2, atomIndex2: 4),
            Bond3D(atomIndex1: 0, atomIndex2: 5),
          ],
        ),
      product:
        const Molecule3D(
          id: 'swern_product',
          name: 'Benzaldehyde',
          formula: 'C7H6O',
          iupacName: 'benzaldehyde',
          description: 'Oxidized aldehyde product without over-oxidation.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Carbonyl carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.22, note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'H', x: -0.95, y: 0.0, z: -0.55, note: 'Aldehyde proton'),
            Atom3D(symbol: 'C', x: 1.25, y: 0.0, z: -0.8, hybridization: 'sp²', note: 'Phenyl ipso carbon'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
          ],
        ),
    ),
    'birch_reduction': Reaction3DSet(
      reactionId: 'birch_reduction',
      title: 'Birch Reduction',
      keyTransformationNote: 'Observe loss of full aromaticity: anisole undergoes two SET and two protonation steps to yield non-conjugated 1-methoxycyclohexa-1,4-diene.',
      reactant:
        const Molecule3D(
          id: 'birch_reactant',
          name: 'Anisole',
          formula: 'C7H8O',
          iupacName: 'methoxybenzene',
          description: 'Planar aromatic benzene ring with electron-donating methoxy group.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'C1 ipso carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.37, note: 'Methoxy oxygen'),
            Atom3D(symbol: 'C', x: 1.2, y: 0.0, z: 2.1, note: 'Methoxy methyl'),
            Atom3D(symbol: 'C', x: 1.2, y: 0.7, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 1.2, y: 2.1, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.8, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -1.2, y: 2.1, z: 0.0, hybridization: 'sp²'),
            Atom3D(symbol: 'C', x: -1.2, y: 0.7, z: 0.0, hybridization: 'sp²'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 5, atomIndex2: 6, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 6, atomIndex2: 7, type: BondType3D.aromatic),
            Bond3D(atomIndex1: 7, atomIndex2: 0, type: BondType3D.aromatic),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'birch_intermediate',
          name: 'Cyclohexadienyl Radical',
          formula: '[C7H9O]•',
          iupacName: 'cyclohexadienyl radical intermediate',
          description: 'Neutral radical with one sp3 methylene and delocalized pentadienyl radical.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, note: 'C1 methoxy carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.37),
            Atom3D(symbol: 'C', x: 1.25, y: 0.7, z: 0.0),
            Atom3D(symbol: 'C', x: 1.25, y: 2.1, z: 0.0),
            Atom3D(symbol: 'C', x: 0.0, y: 2.8, z: -0.3, hybridization: 'sp³', note: 'Protonated sp3 carbon with two hydrogens'),
            Atom3D(symbol: 'C', x: -1.25, y: 2.1, z: 0.0),
            Atom3D(symbol: 'C', x: -1.25, y: 0.7, z: 0.0),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 4, atomIndex2: 5),
            Bond3D(atomIndex1: 5, atomIndex2: 6),
            Bond3D(atomIndex1: 6, atomIndex2: 0),
          ],
        ),
      product:
        const Molecule3D(
          id: 'birch_product',
          name: '1-Methoxycyclohexa-1,4-diene',
          formula: 'C7H10O',
          iupacName: '1-methoxycyclohexa-1,4-diene',
          description: 'Non-conjugated 1,4-diene with two isolated double bonds.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'C1 enol ether carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.37, note: 'Methoxy group'),
            Atom3D(symbol: 'C', x: 1.3, y: 0.0, z: -0.3, hybridization: 'sp²', note: 'C2 alkene carbon'),
            Atom3D(symbol: 'C', x: 2.15, y: 1.25, z: -0.5, hybridization: 'sp³', note: 'C3 methylene sp3'),
            Atom3D(symbol: 'C', x: 1.3, y: 2.45, z: -0.3, hybridization: 'sp²', note: 'C4 alkene carbon'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.45, z: 0.0, hybridization: 'sp²', note: 'C5 alkene carbon'),
            Atom3D(symbol: 'C', x: -0.85, y: 1.25, z: 0.25, hybridization: 'sp³', note: 'C6 methylene sp3'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 5, atomIndex2: 6),
            Bond3D(atomIndex1: 6, atomIndex2: 0),
          ],
        ),
    ),
    'heck_coupling': Reaction3DSet(
      reactionId: 'heck_coupling',
      title: 'Heck Cross-Coupling',
      keyTransformationNote: 'Observe syn-addition across double bond followed by C-C rotation and syn-beta-hydride elimination to furnish (E)-methyl cinnamate.',
      reactant:
        const Molecule3D(
          id: 'heck_reactant',
          name: 'Iodobenzene + Methyl Acrylate',
          formula: 'C6H5I + C4H6O2',
          iupacName: 'iodobenzene and methyl prop-2-enoate',
          description: 'Aryl iodide and electron-poor alkene substrates.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Phenyl ipso carbon'),
            Atom3D(symbol: 'I', x: 0.0, y: 0.0, z: 2.1, note: 'Iodine leaving group'),
            Atom3D(symbol: 'C', x: 3.5, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Alkene terminal CH2'),
            Atom3D(symbol: 'C', x: 4.8, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Alkene CH'),
            Atom3D(symbol: 'C', x: 5.6, y: 1.25, z: 0.0, hybridization: 'sp²', note: 'Ester carbonyl'),
            Atom3D(symbol: 'O', x: 6.8, y: 1.25, z: 0.0),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.doubleBond),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'heck_intermediate',
          name: 'Syn-Insertion Palladacycle',
          formula: '[Ph-CH2-CH(CO2Me)-Pd(PPh3)2-I]',
          iupacName: 'sigma-alkylpalladium intermediate',
          description: 'Intermediate showing syn-conformation of beta-hydrogen and Pd.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Benzylic carbon bonded to phenyl'),
            Atom3D(symbol: 'C', x: 1.5, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Beta-carbon holding Pd and ester'),
            Atom3D(symbol: 'Pd', x: 1.5, y: 2.05, z: 0.0, note: 'Pd(II) center'),
            Atom3D(symbol: 'H', x: 0.0, y: 1.1, z: 0.0, note: 'Syn-coplanar beta-H for elimination'),
            Atom3D(symbol: 'C', x: 2.5, y: -1.1, z: 0.0, note: 'CO2Me ester group'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
            Bond3D(atomIndex1: 1, atomIndex2: 4),
            Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.partial),
          ],
        ),
      product:
        const Molecule3D(
          id: 'heck_product',
          name: 'trans-Methyl Cinnamate',
          formula: 'C10H10O2',
          iupacName: 'methyl (2E)-3-phenylprop-2-enoate',
          description: 'Extended conjugated (E)-trans alkene product.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Phenyl ipso carbon'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Alpha-alkene carbon'),
            Atom3D(symbol: 'C', x: 2.2, y: 1.2, z: 0.0, hybridization: 'sp²', note: 'Beta-alkene carbon (E)'),
            Atom3D(symbol: 'C', x: 3.65, y: 1.2, z: 0.0, hybridization: 'sp²', note: 'Ester carbonyl'),
            Atom3D(symbol: 'O', x: 4.35, y: 2.2, z: 0.0, note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'O', x: 4.25, y: 0.0, z: 0.0, note: 'Methoxy oxygen'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 3, atomIndex2: 5),
          ],
        ),
    ),
    'corey_chaykovsky': Reaction3DSet(
      reactionId: 'corey_chaykovsky',
      title: 'Corey-Chaykovsky Reaction',
      keyTransformationNote: 'Observe ylide addition and intramolecular ring closure: dimethylsulfonium methylide attacks cyclohexanone, followed by displacement of Me2S to form 1-oxaspiro[2.5]octane.',
      reactant:
        const Molecule3D(
          id: 'corey_reactant',
          name: 'Cyclohexanone + Dimethylsulfonium Methylide',
          formula: 'C6H10O + C3H8S',
          iupacName: 'cyclohexanone and dimethylsulfaniumylmethylide',
          description: 'Ketone and sulfur ylide nucleophile.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Carbonyl carbon'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.22, note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'C', x: 2.5, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Ylide carbanion carbon'),
            Atom3D(symbol: 'S', x: 4.2, y: 0.0, z: 0.0, formalCharge: '+1', note: 'Sulfonium sulfur'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'corey_intermediate',
          name: 'Zwitterionic Betaine Intermediate',
          formula: '[C9H18OS]',
          iupacName: '2-(dimethylsulfonio)ethan-1-olate intermediate',
          description: 'Tetrahedral alkoxide aligned anti-periplanar to departing sulfonium.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Tetrahedral quaternary center'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45, formalCharge: '-1', note: 'Nucleophilic alkoxide'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.5, hybridization: 'sp³', note: 'Methylene carbon'),
            Atom3D(symbol: 'S', x: 1.45, y: 1.8, z: -0.5, formalCharge: '+1', note: 'Departing Me2S leaving group'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.partial),
          ],
        ),
      product:
        const Molecule3D(
          id: 'corey_product',
          name: '1-Oxaspiro[2.5]octane',
          formula: 'C7H12O',
          iupacName: '1-oxaspiro[2.5]octane',
          description: 'Spirocyclic oxirane epoxide on cyclohexane framework.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Spiro quaternary carbon'),
            Atom3D(symbol: 'C', x: 1.25, y: 0.0, z: 0.7, hybridization: 'sp³', note: 'Oxirane methylene carbon'),
            Atom3D(symbol: 'O', x: 0.6, y: 1.15, z: 0.0, hybridization: 'sp³', note: 'Oxirane ring oxygen'),
            Atom3D(symbol: 'C', x: -1.25, y: 0.0, z: -0.85, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -1.25, y: 1.45, z: -1.45, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.15, z: -0.85, hybridization: 'sp³'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 0),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 4, atomIndex2: 5),
          ],
        ),
    ),
    'stille_coupling': Reaction3DSet(
      reactionId: 'stille_coupling',
      title: 'Stille Cross-Coupling',
      keyTransformationNote: 'Observe organostannane transmetalation: vinyl group transfer from tin to Pd(II), followed by reductive elimination to form styrene.',
      reactant:
        const Molecule3D(
          id: 'stille_reactant',
          name: 'Bromobenzene + Tributyl(vinyl)stannane',
          formula: 'C6H5Br + C14H30Sn',
          iupacName: 'bromobenzene and tributyl(ethenyl)stannane',
          description: 'Organohalide and organostannane partners.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Aryl ipso carbon'),
            Atom3D(symbol: 'Br', x: 0.0, y: 0.0, z: 1.9, note: 'Bromine leaving group'),
            Atom3D(symbol: 'Sn', x: 3.5, y: 0.0, z: 0.0, note: 'Tin atom'),
            Atom3D(symbol: 'C', x: 5.5, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Vinyl C1 carbon'),
            Atom3D(symbol: 'C', x: 6.7, y: 0.5, z: 0.0, hybridization: 'sp²', note: 'Vinyl C2 methylene'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'stille_intermediate',
          name: 'cis-Bis(triphenylphosphine)phenyl(vinyl)palladium(II)',
          formula: '[Pd(PPh3)2(Ph)(CH=CH2)]',
          iupacName: 'cis-phenyl(ethenyl)bis(triphenylphosphine)palladium(II)',
          description: 'Square-planar complex with cis-coordinated phenyl and vinyl groups.',
          atoms: [
            Atom3D(symbol: 'Pd', x: 0.0, y: 0.0, z: 0.0, note: 'Square-planar Pd(II)'),
            Atom3D(symbol: 'C', x: 2.05, y: 0.0, z: 0.0, note: 'Phenyl ipso carbon'),
            Atom3D(symbol: 'C', x: 0.0, y: 2.05, z: 0.0, note: 'Vinyl alpha carbon'),
            Atom3D(symbol: 'C', x: 0.0, y: 3.35, z: 0.0, note: 'Vinyl beta methylene'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.partial),
          ],
        ),
      product:
        const Molecule3D(
          id: 'stille_product',
          name: 'Styrene',
          formula: 'C8H8',
          iupacName: 'ethenylbenzene',
          description: 'Cross-coupled vinylbenzene product.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Phenyl ipso carbon'),
            Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Vinyl alpha carbon'),
            Atom3D(symbol: 'C', x: 2.3, y: 1.15, z: 0.0, hybridization: 'sp²', note: 'Vinyl beta carbon'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          ],
        ),
    ),
    'favorskii_rearrangement': Reaction3DSet(
      reactionId: 'favorskii_rearrangement',
      title: 'Favorskii Rearrangement',
      keyTransformationNote: 'Observe ring contraction: 2-chlorocyclohexanone enolizes to cyclopropanone, followed by nucleophilic attack of methoxide and ring-cleavage to methyl cyclopentanecarboxylate.',
      reactant:
        const Molecule3D(
          id: 'favorskii_reactant',
          name: '2-Chlorocyclohexanone',
          formula: 'C6H9ClO',
          iupacName: '2-chlorocyclohexan-1-one',
          description: 'Alpha-haloketone starting material with equatorial chlorine.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Carbonyl carbon C1'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.22, note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'C', x: 1.25, y: 0.0, z: -0.85, hybridization: 'sp³', note: 'C2 bearing Cl'),
            Atom3D(symbol: 'Cl', x: 1.25, y: 0.0, z: -2.65, note: 'Leaving chloride'),
            Atom3D(symbol: 'C', x: -1.25, y: 0.0, z: -0.85, hybridization: 'sp³', note: 'C6 alpha-prime carbon'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
            Bond3D(atomIndex1: 0, atomIndex2: 4),
          ],
        ),
      intermediate:
        const Molecule3D(
          id: 'favorskii_intermediate',
          name: 'Bicyclo[3.1.0]hexan-6-one',
          formula: 'C6H8O',
          iupacName: 'bicyclo[3.1.0]hexan-6-one',
          description: 'Highly strained 3-membered cyclopropanone fused to cyclopentane ring.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Strained cyclopropanone carbonyl'),
            Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.2, note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'C', x: 1.15, y: 0.0, z: -0.9, hybridization: 'sp³', note: 'Bridgehead carbon 1'),
            Atom3D(symbol: 'C', x: -1.15, y: 0.0, z: -0.9, hybridization: 'sp³', note: 'Bridgehead carbon 2'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 0, atomIndex2: 2),
            Bond3D(atomIndex1: 0, atomIndex2: 3),
            Bond3D(atomIndex1: 2, atomIndex2: 3),
          ],
        ),
      product:
        const Molecule3D(
          id: 'favorskii_product',
          name: 'Methyl Cyclopentanecarboxylate',
          formula: 'C7H12O2',
          iupacName: 'methyl cyclopentanecarboxylate',
          description: 'Ring-contracted 5-membered cyclopentane ester.',
          atoms: [
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Cyclopentyl C1 carbon'),
            Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 1.5, hybridization: 'sp²', note: 'Ester carbonyl carbon'),
            Atom3D(symbol: 'O', x: 0.9, y: 0.0, z: 2.3, note: 'Carbonyl oxygen'),
            Atom3D(symbol: 'O', x: -1.25, y: 0.0, z: 1.95, note: 'Ester methoxy oxygen'),
            Atom3D(symbol: 'C', x: -1.45, y: 0.0, z: 3.35, note: 'Methoxy methyl carbon'),
            Atom3D(symbol: 'C', x: 1.25, y: 0.65, z: -0.65, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: 0.75, y: 2.1, z: -0.75, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -0.75, y: 2.1, z: -0.75, hybridization: 'sp³'),
            Atom3D(symbol: 'C', x: -1.25, y: 0.65, z: -0.65, hybridization: 'sp³'),
          ],
          bonds: [
            Bond3D(atomIndex1: 0, atomIndex2: 1),
            Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
            Bond3D(atomIndex1: 1, atomIndex2: 3),
            Bond3D(atomIndex1: 3, atomIndex2: 4),
            Bond3D(atomIndex1: 0, atomIndex2: 5),
            Bond3D(atomIndex1: 5, atomIndex2: 6),
            Bond3D(atomIndex1: 6, atomIndex2: 7),
            Bond3D(atomIndex1: 7, atomIndex2: 8),
            Bond3D(atomIndex1: 8, atomIndex2: 0),
          ],
        ),
    ),
  };
}
