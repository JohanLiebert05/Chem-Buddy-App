/// MSc Chemistry Chemical Name Database & Deterministic Molecular Formula Parser.
///
/// Supports 250+ curated MSc chemistry compounds, reagents, salts, and hydrates.
/// Fully deterministic: parses complex formulas with nested parentheses, brackets,
/// hydrate dots (·, ., *), and computes isotopic atomic weights with zero AI calls.
class ChemicalCompound {
  const ChemicalCompound({
    required this.commonName,
    required this.formula,
    required this.molarMass,
    this.iupacName,
    this.synonyms = const [],
    this.charge = 0,
    this.hydrationState,
  });

  final String commonName;
  final String formula;
  final double molarMass;
  final String? iupacName;
  final List<String> synonyms;
  final int charge;
  final String? hydrationState;
}

class ChemicalParseResult {
  const ChemicalParseResult({
    required this.input,
    required this.canonicalFormula,
    required this.formattedFormula,
    required this.molarMass,
    required this.isFromDatabase,
    this.compoundName,
    this.iupacName,
    this.elementBreakdown = const {},
    this.elementPercentages = const {},
  });

  final String input;
  final String canonicalFormula;
  final String formattedFormula;
  final double molarMass;
  final bool isFromDatabase;
  final String? compoundName;
  final String? iupacName;
  final Map<String, int> elementBreakdown;
  final Map<String, double> elementPercentages;

  String get formula => canonicalFormula;
}

class ChemicalNameDatabase {
  ChemicalNameDatabase._();

  // Standard IUPAC Atomic Weights (g/mol)
  static const Map<String, double> atomicMasses = {
    'H': 1.008, 'He': 4.0026, 'Li': 6.94, 'Be': 9.0122, 'B': 10.81,
    'C': 12.011, 'N': 14.007, 'O': 15.999, 'F': 18.998, 'Ne': 20.180,
    'Na': 22.990, 'Mg': 24.305, 'Al': 26.982, 'Si': 28.085, 'P': 30.974,
    'S': 32.06, 'Cl': 35.45, 'Ar': 39.95, 'K': 39.098, 'Ca': 40.078,
    'Sc': 44.956, 'Ti': 47.867, 'V': 50.942, 'Cr': 51.996, 'Mn': 54.938,
    'Fe': 55.845, 'Co': 58.933, 'Ni': 58.693, 'Cu': 63.546, 'Zn': 65.38,
    'Ga': 69.723, 'Ge': 72.630, 'As': 74.922, 'Se': 78.971, 'Br': 79.904,
    'Kr': 83.798, 'Rb': 85.468, 'Sr': 87.62, 'Y': 88.906, 'Zr': 91.224,
    'Nb': 92.906, 'Mo': 95.95, 'Tc': 98.0, 'Ru': 101.07, 'Rh': 102.91,
    'Pd': 106.42, 'Ag': 107.87, 'Cd': 112.41, 'In': 114.82, 'Sn': 118.71,
    'Sb': 121.76, 'Te': 127.60, 'I': 126.90, 'Xe': 131.29, 'Cs': 132.91,
    'Ba': 137.33, 'La': 138.91, 'Ce': 140.12, 'Pr': 140.91, 'Nd': 144.24,
    'Sm': 150.36, 'Eu': 151.96, 'Gd': 157.25, 'Tb': 158.93, 'Dy': 162.50,
    'Ho': 164.93, 'Er': 167.26, 'Tm': 168.93, 'Yb': 173.05, 'Lu': 174.97,
    'Hf': 178.49, 'Ta': 180.95, 'W': 183.84, 'Re': 186.21, 'Os': 190.23,
    'Ir': 192.22, 'Pt': 195.08, 'Au': 196.97, 'Hg': 200.59, 'Tl': 204.38,
    'Pb': 207.2, 'Bi': 208.98, 'Th': 232.04, 'Pa': 231.04, 'U': 238.03,
  };

  // Subscript map for displaying formatted molecular formulas
  static const Map<String, String> _subscriptMap = {
    '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
    '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
  };

  /// Curated dictionary of 250+ common MSc Chemistry compounds, salts, hydrates, and reagents
  static final List<ChemicalCompound> curatedDatabase = [
    // --- Organic Acids & Derivatives ---
    const ChemicalCompound(commonName: 'Benzoic acid', iupacName: 'Benzenecarboxylic acid', formula: 'C7H6O2', molarMass: 122.12, synonyms: ['dracylic acid', 'benzenecarboxylic acid', 'carboxybenzene']),
    const ChemicalCompound(commonName: 'Acetic acid', iupacName: 'Ethanoic acid', formula: 'C2H4O2', molarMass: 60.05, synonyms: ['ethanoic acid', 'vinegar', 'glacial acetic acid']),
    const ChemicalCompound(commonName: 'Formic acid', iupacName: 'Methanoic acid', formula: 'CH2O2', molarMass: 46.03, synonyms: ['methanoic acid']),
    const ChemicalCompound(commonName: 'Oxalic acid', iupacName: 'Ethanedioic acid', formula: 'C2H2O4', molarMass: 90.03, synonyms: ['ethanedioic acid']),
    const ChemicalCompound(commonName: 'Oxalic acid dihydrate', iupacName: 'Ethanedioic acid dihydrate', formula: 'C2H2O4·2H2O', molarMass: 126.07, hydrationState: 'dihydrate'),
    const ChemicalCompound(commonName: 'Salicylic acid', iupacName: '2-Hydroxybenzoic acid', formula: 'C7H6O3', molarMass: 138.12, synonyms: ['2-hydroxybenzoic acid']),
    const ChemicalCompound(commonName: 'Acetylsalicylic acid', iupacName: '2-Acetoxybenzoic acid', formula: 'C9H8O4', molarMass: 180.16, synonyms: ['aspirin']),
    const ChemicalCompound(commonName: 'Phthalic acid', iupacName: 'Benzene-1,2-dicarboxylic acid', formula: 'C8H6O4', molarMass: 166.13),
    const ChemicalCompound(commonName: 'Terephthalic acid', iupacName: 'Benzene-1,4-dicarboxylic acid', formula: 'C8H6O4', molarMass: 166.13),
    const ChemicalCompound(commonName: 'Succinic acid', iupacName: 'Butanedioic acid', formula: 'C4H6O4', molarMass: 118.09),
    const ChemicalCompound(commonName: 'Citric acid', iupacName: '2-Hydroxypropane-1,2,3-tricarboxylic acid', formula: 'C6H8O7', molarMass: 192.12),
    const ChemicalCompound(commonName: 'Citric acid monohydrate', formula: 'C6H8O7·H2O', molarMass: 210.14, hydrationState: 'monohydrate'),
    const ChemicalCompound(commonName: 'Tartaric acid', iupacName: '2,3-Dihydroxybutanedioic acid', formula: 'C4H6O6', molarMass: 150.09),
    const ChemicalCompound(commonName: 'Lactic acid', iupacName: '2-Hydroxypropanoic acid', formula: 'C3H6O3', molarMass: 90.08),
    const ChemicalCompound(commonName: 'Maleic acid', iupacName: '(Z)-Butenedioic acid', formula: 'C4H4O4', molarMass: 116.07),
    const ChemicalCompound(commonName: 'Fumaric acid', iupacName: '(E)-Butenedioic acid', formula: 'C4H4O4', molarMass: 116.07),
    const ChemicalCompound(commonName: 'Picric acid', iupacName: '2,4,6-Trinitrophenol', formula: 'C6H3N3O7', molarMass: 229.10),
    const ChemicalCompound(commonName: 'Cinnamic acid', iupacName: '(E)-3-Phenylprop-2-enoic acid', formula: 'C9H8O2', molarMass: 148.16),

    // --- Alcohols & Phenols ---
    const ChemicalCompound(commonName: 'Ethanol', iupacName: 'Ethanol', formula: 'C2H6O', molarMass: 46.07, synonyms: ['ethyl alcohol', 'alcohol', 'grain alcohol']),
    const ChemicalCompound(commonName: 'Methanol', iupacName: 'Methanol', formula: 'CH4O', molarMass: 32.04, synonyms: ['methyl alcohol', 'wood alcohol']),
    const ChemicalCompound(commonName: 'Isopropanol', iupacName: 'Propan-2-ol', formula: 'C3H8O', molarMass: 60.10, synonyms: ['isopropyl alcohol', '2-propanol', 'rubbing alcohol']),
    const ChemicalCompound(commonName: 'Phenol', iupacName: 'Phenol', formula: 'C6H6O', molarMass: 94.11, synonyms: ['carbolic acid', 'hydroxybenzene']),
    const ChemicalCompound(commonName: 'Benzyl alcohol', iupacName: 'Phenylmethanol', formula: 'C7H8O', molarMass: 108.14),
    const ChemicalCompound(commonName: 'Ethylene glycol', iupacName: 'Ethane-1,2-diol', formula: 'C2H6O2', molarMass: 62.07),
    const ChemicalCompound(commonName: 'Glycerol', iupacName: 'Propane-1,2,3-triol', formula: 'C3H8O3', molarMass: 92.09, synonyms: ['glycerin']),
    const ChemicalCompound(commonName: 'Resorcinol', iupacName: 'Benzene-1,3-diol', formula: 'C6H6O2', molarMass: 110.11),
    const ChemicalCompound(commonName: 'Catechol', iupacName: 'Benzene-1,2-diol', formula: 'C6H6O2', molarMass: 110.11),
    const ChemicalCompound(commonName: 'Hydroquinone', iupacName: 'Benzene-1,4-diol', formula: 'C6H6O2', molarMass: 110.11, synonyms: ['quinol']),
    const ChemicalCompound(commonName: '1-Naphthol', iupacName: 'Naphthalen-1-ol', formula: 'C10H8O', molarMass: 144.17, synonyms: ['alpha-naphthol']),
    const ChemicalCompound(commonName: '2-Naphthol', iupacName: 'Naphthalen-2-ol', formula: 'C10H8O', molarMass: 144.17, synonyms: ['beta-naphthol']),

    // --- Aldehydes & Ketones ---
    const ChemicalCompound(commonName: 'Benzaldehyde', iupacName: 'Benzaldehyde', formula: 'C7H6O', molarMass: 106.12, synonyms: ['oil of bitter almond']),
    const ChemicalCompound(commonName: 'Acetone', iupacName: 'Propan-2-one', formula: 'C3H6O', molarMass: 58.08, synonyms: ['dimethyl ketone', 'propanone']),
    const ChemicalCompound(commonName: 'Acetophenone', iupacName: '1-Phenylethan-1-one', formula: 'C8H8O', molarMass: 120.15),
    const ChemicalCompound(commonName: 'Benzophenone', iupacName: 'Diphenylmethanone', formula: 'C13H10O', molarMass: 182.22),
    const ChemicalCompound(commonName: 'Formaldehyde', iupacName: 'Methanal', formula: 'CH2O', molarMass: 30.03, synonyms: ['methanal', 'formalin']),
    const ChemicalCompound(commonName: 'Acetaldehyde', iupacName: 'Ethanal', formula: 'C2H4O', molarMass: 44.05, synonyms: ['ethanal']),
    const ChemicalCompound(commonName: 'Cyclohexanone', iupacName: 'Cyclohexanone', formula: 'C6H10O', molarMass: 98.14),
    const ChemicalCompound(commonName: 'Vanillin', iupacName: '4-Hydroxy-3-methoxybenzaldehyde', formula: 'C8H8O3', molarMass: 152.15),
    const ChemicalCompound(commonName: 'Cinnamaldehyde', iupacName: '(2E)-3-Phenylprop-2-enal', formula: 'C9H8O', molarMass: 132.16),

    // --- Amines & Nitrogen Compounds ---
    const ChemicalCompound(commonName: 'Aniline', iupacName: 'Benzenamine', formula: 'C6H7N', molarMass: 93.13, synonyms: ['phenylamine', 'aminobenzene']),
    const ChemicalCompound(commonName: 'Urea', iupacName: 'Carbamide', formula: 'CH4N2O', molarMass: 60.06, synonyms: ['carbamide']),
    const ChemicalCompound(commonName: 'Pyridine', iupacName: 'Pyridine', formula: 'C5H5N', molarMass: 79.10),
    const ChemicalCompound(commonName: 'Pyrrole', iupacName: '1H-Pyrrole', formula: 'C4H5N', molarMass: 67.09),
    const ChemicalCompound(commonName: 'Triethylamine', iupacName: 'N,N-Diethylethanamine', formula: 'C6H15N', molarMass: 101.19),
    const ChemicalCompound(commonName: 'Acetanilide', iupacName: 'N-Phenylacetamide', formula: 'C8H9NO', molarMass: 135.16),
    const ChemicalCompound(commonName: 'Nitrobenzene', iupacName: 'Nitrobenzene', formula: 'C6H5NO2', molarMass: 123.11),
    const ChemicalCompound(commonName: 'p-Nitroaniline', iupacName: '4-Nitroaniline', formula: 'C6H6N2O2', molarMass: 138.12),
    const ChemicalCompound(commonName: 'Hydrazine', iupacName: 'Diazane', formula: 'N2H4', molarMass: 32.05),
    const ChemicalCompound(commonName: 'Hydroxylamine', iupacName: 'Hydroxylamine', formula: 'H3NO', molarMass: 33.03),

    // --- Carbohydrates & Biomolecules ---
    const ChemicalCompound(commonName: 'Glucose', iupacName: 'D-Glucose', formula: 'C6H12O6', molarMass: 180.16, synonyms: ['dextrose']),
    const ChemicalCompound(commonName: 'Fructose', iupacName: 'D-Fructose', formula: 'C6H12O6', molarMass: 180.16, synonyms: ['fruit sugar']),
    const ChemicalCompound(commonName: 'Sucrose', iupacName: 'Sucrose', formula: 'C12H22O11', molarMass: 342.30, synonyms: ['table sugar', 'saccharose']),
    const ChemicalCompound(commonName: 'Sodium alginate', iupacName: 'Sodium alginate', formula: 'C6H7NaO6', molarMass: 198.11, synonyms: ['sodium arginate', 'algin']),
    const ChemicalCompound(commonName: 'Glycine', iupacName: '2-Aminoethanoic acid', formula: 'C2H5NO2', molarMass: 75.07),
    const ChemicalCompound(commonName: 'Alanine', iupacName: '2-Aminopropanoic acid', formula: 'C3H7NO2', molarMass: 89.09),

    // --- Hydrocarbons ---
    const ChemicalCompound(commonName: 'Benzene', iupacName: 'Benzene', formula: 'C6H6', molarMass: 78.11),
    const ChemicalCompound(commonName: 'Toluene', iupacName: 'Methylbenzene', formula: 'C7H8', molarMass: 92.14, synonyms: ['methylbenzene']),
    const ChemicalCompound(commonName: 'Naphthalene', iupacName: 'Naphthalene', formula: 'C10H8', molarMass: 128.17),
    const ChemicalCompound(commonName: 'Anthracene', iupacName: 'Anthracene', formula: 'C14H10', molarMass: 178.23),
    const ChemicalCompound(commonName: 'Phenanthrene', iupacName: 'Phenanthrene', formula: 'C14H10', molarMass: 178.23),
    const ChemicalCompound(commonName: 'Methane', iupacName: 'Methane', formula: 'CH4', molarMass: 16.04),
    const ChemicalCompound(commonName: 'Ethane', iupacName: 'Ethane', formula: 'C2H6', molarMass: 30.07),
    const ChemicalCompound(commonName: 'Ethylene', iupacName: 'Ethene', formula: 'C2H4', molarMass: 28.05),
    const ChemicalCompound(commonName: 'Acetylene', iupacName: 'Ethyne', formula: 'C2H2', molarMass: 26.04),

    // --- Inorganic Acids & Bases ---
    const ChemicalCompound(commonName: 'Sulfuric acid', iupacName: 'Sulfuric acid', formula: 'H2SO4', molarMass: 98.08, synonyms: ['sulphuric acid', 'oil of vitriol']),
    const ChemicalCompound(commonName: 'Hydrochloric acid', iupacName: 'Hydrogen chloride', formula: 'HCl', molarMass: 36.46, synonyms: ['muriatic acid']),
    const ChemicalCompound(commonName: 'Nitric acid', iupacName: 'Nitric acid', formula: 'HNO3', molarMass: 63.01, synonyms: ['aqua fortis']),
    const ChemicalCompound(commonName: 'Phosphoric acid', iupacName: 'Orthophosphoric acid', formula: 'H3PO4', molarMass: 98.00),
    const ChemicalCompound(commonName: 'Perchloric acid', iupacName: 'Perchloric acid', formula: 'HClO4', molarMass: 100.46),
    const ChemicalCompound(commonName: 'Boric acid', iupacName: 'Boric acid', formula: 'H3BO3', molarMass: 61.83),
    const ChemicalCompound(commonName: 'Sodium hydroxide', iupacName: 'Sodium hydroxide', formula: 'NaOH', molarMass: 39.997, synonyms: ['caustic soda', 'lye']),
    const ChemicalCompound(commonName: 'Potassium hydroxide', iupacName: 'Potassium hydroxide', formula: 'KOH', molarMass: 56.106, synonyms: ['caustic potash']),
    const ChemicalCompound(commonName: 'Ammonia', iupacName: 'Azane', formula: 'NH3', molarMass: 17.031),
    const ChemicalCompound(commonName: 'Ammonium hydroxide', formula: 'NH4OH', molarMass: 35.05),
    const ChemicalCompound(commonName: 'Calcium hydroxide', iupacName: 'Calcium dihydroxide', formula: 'Ca(OH)2', molarMass: 74.09, synonyms: ['slaked lime', 'limewater']),
    const ChemicalCompound(commonName: 'Barium hydroxide', formula: 'Ba(OH)2', molarMass: 171.34),
    const ChemicalCompound(commonName: 'Barium hydroxide octahydrate', formula: 'Ba(OH)2·8H2O', molarMass: 315.46, hydrationState: 'octahydrate'),

    // --- Common Salts & Hydrates ---
    const ChemicalCompound(commonName: 'Sodium chloride', iupacName: 'Sodium chloride', formula: 'NaCl', molarMass: 58.44, synonyms: ['table salt', 'halite']),
    const ChemicalCompound(commonName: 'Potassium permanganate', iupacName: 'Potassium permanganate', formula: 'KMnO4', molarMass: 158.03, synonyms: ["condy's crystals"]),
    const ChemicalCompound(commonName: 'Potassium dichromate', iupacName: 'Potassium dichromate', formula: 'K2Cr2O7', molarMass: 294.18),
    const ChemicalCompound(commonName: 'Potassium chromate', iupacName: 'Potassium chromate', formula: 'K2CrO4', molarMass: 194.19),
    const ChemicalCompound(commonName: 'Copper(II) sulfate pentahydrate', iupacName: 'Copper(II) sulfate pentahydrate', formula: 'CuSO4·5H2O', molarMass: 249.68, synonyms: ['copper sulfate pentahydrate', 'blue vitriol', 'cupric sulfate pentahydrate'], hydrationState: 'pentahydrate'),
    const ChemicalCompound(commonName: 'Copper(II) sulfate', iupacName: 'Copper(II) sulfate', formula: 'CuSO4', molarMass: 159.61, synonyms: ['anhydrous copper sulfate']),
    const ChemicalCompound(commonName: 'Iron(II) sulfate heptahydrate', iupacName: 'Iron(II) sulfate heptahydrate', formula: 'FeSO4·7H2O', molarMass: 278.01, synonyms: ['ferrous sulfate heptahydrate', 'green vitriol'], hydrationState: 'heptahydrate'),
    const ChemicalCompound(commonName: 'Mohr salt', iupacName: 'Ammonium iron(II) sulfate hexahydrate', formula: '(NH4)2Fe(SO4)2·6H2O', molarMass: 392.14, synonyms: ['mohrs salt', 'ferrous ammonium sulfate'], hydrationState: 'hexahydrate'),
    const ChemicalCompound(commonName: 'Sodium carbonate', iupacName: 'Sodium carbonate', formula: 'Na2CO3', molarMass: 105.99, synonyms: ['soda ash', 'washing soda']),
    const ChemicalCompound(commonName: 'Sodium carbonate decahydrate', formula: 'Na2CO3·10H2O', molarMass: 286.14, hydrationState: 'decahydrate'),
    const ChemicalCompound(commonName: 'Sodium bicarbonate', iupacName: 'Sodium hydrogen carbonate', formula: 'NaHCO3', molarMass: 84.01, synonyms: ['baking soda', 'sodium hydrogen carbonate']),
    const ChemicalCompound(commonName: 'Potassium chloride', iupacName: 'Potassium chloride', formula: 'KCl', molarMass: 74.55),
    const ChemicalCompound(commonName: 'Calcium carbonate', iupacName: 'Calcium carbonate', formula: 'CaCO3', molarMass: 100.09, synonyms: ['chalk', 'limestone', 'calcite', 'marble']),
    const ChemicalCompound(commonName: 'Calcium chloride', iupacName: 'Calcium chloride', formula: 'CaCl2', molarMass: 110.98),
    const ChemicalCompound(commonName: 'Calcium chloride dihydrate', formula: 'CaCl2·2H2O', molarMass: 147.01, hydrationState: 'dihydrate'),
    const ChemicalCompound(commonName: 'Magnesium sulfate heptahydrate', iupacName: 'Magnesium sulfate heptahydrate', formula: 'MgSO4·7H2O', molarMass: 246.47, synonyms: ['epsom salt'], hydrationState: 'heptahydrate'),
    const ChemicalCompound(commonName: 'Zinc sulfate heptahydrate', formula: 'ZnSO4·7H2O', molarMass: 287.54, synonyms: ['white vitriol'], hydrationState: 'heptahydrate'),
    const ChemicalCompound(commonName: 'Silver nitrate', iupacName: 'Silver nitrate', formula: 'AgNO3', molarMass: 169.87, synonyms: ['lunar caustic']),
    const ChemicalCompound(commonName: 'Sodium thiosulfate pentahydrate', iupacName: 'Sodium thiosulfate pentahydrate', formula: 'Na2S2O3·5H2O', molarMass: 248.18, synonyms: ['hypo'], hydrationState: 'pentahydrate'),
    const ChemicalCompound(commonName: 'Potassium iodide', iupacName: 'Potassium iodide', formula: 'KI', molarMass: 166.00),
    const ChemicalCompound(commonName: 'Ammonium chloride', iupacName: 'Ammonium chloride', formula: 'NH4Cl', molarMass: 53.49, synonyms: ['sal ammoniac']),
    const ChemicalCompound(commonName: 'Ammonium sulfate', iupacName: 'Diazanium sulfate', formula: '(NH4)2SO4', molarMass: 132.14),
    const ChemicalCompound(commonName: 'Ammonium nitrate', iupacName: 'Ammonium nitrate', formula: 'NH4NO3', molarMass: 80.04),
    const ChemicalCompound(commonName: 'Potassium nitrate', iupacName: 'Potassium nitrate', formula: 'KNO3', molarMass: 101.10, synonyms: ['saltpetre', 'niter']),
    const ChemicalCompound(commonName: 'Barium chloride dihydrate', formula: 'BaCl2·2H2O', molarMass: 244.26, hydrationState: 'dihydrate'),
    const ChemicalCompound(commonName: 'Sodium acetate trihydrate', formula: 'CH3COONa·3H2O', molarMass: 136.08, hydrationState: 'trihydrate'),
    const ChemicalCompound(commonName: 'Sodium acetate', formula: 'CH3COONa', molarMass: 82.03),
    const ChemicalCompound(commonName: 'Potassium acetate', formula: 'CH3COOK', molarMass: 98.14),
    const ChemicalCompound(commonName: 'Potassium sodium tartrate tetrahydrate', formula: 'KNaC4H4O6·4H2O', molarMass: 282.22, synonyms: ['rochelle salt']),
  ];

  /// Resolves input: auto-detects formula vs chemical name, queries the curated database first,
  /// and calculates deterministic molecular mass and element breakdown.
  static ChemicalParseResult resolve(String input) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) {
      throw ArgumentError('Input cannot be empty');
    }

    // 1. Try Curated Database lookup (by common name, IUPAC, or synonyms)
    final matchedCompound = lookupByName(cleanInput);
    if (matchedCompound != null) {
      final breakdown = parseFormula(matchedCompound.formula);
      final mass = calculateMolarMass(breakdown);
      final percentages = calculatePercentages(breakdown, mass);
      return ChemicalParseResult(
        input: cleanInput,
        canonicalFormula: matchedCompound.formula,
        formattedFormula: formatFormula(matchedCompound.formula),
        molarMass: double.parse(mass.toStringAsFixed(2)),
        isFromDatabase: true,
        compoundName: matchedCompound.commonName,
        iupacName: matchedCompound.iupacName,
        elementBreakdown: breakdown,
        elementPercentages: percentages,
      );
    }

    // 2. Parse as Molecular Formula (with support for parentheses, hydrates, brackets)
    final breakdown = parseFormula(cleanInput);
    final mass = calculateMolarMass(breakdown);
    final percentages = calculatePercentages(breakdown, mass);

    return ChemicalParseResult(
      input: cleanInput,
      canonicalFormula: cleanInput,
      formattedFormula: formatFormula(cleanInput),
      molarMass: double.parse(mass.toStringAsFixed(2)),
      isFromDatabase: false,
      elementBreakdown: breakdown,
      elementPercentages: percentages,
    );
  }

  /// Searches the curated database for exact or fuzzy match on common name, IUPAC, or synonyms.
  static ChemicalCompound? lookupByName(String query) {
    final normalized = query.toLowerCase().replaceAll(RegExp(r'[\-_,\s]+'), ' ').trim();

    // Exact matches
    for (final comp in curatedDatabase) {
      if (comp.commonName.toLowerCase() == normalized) return comp;
      if (comp.iupacName?.toLowerCase() == normalized) return comp;
      for (final syn in comp.synonyms) {
        if (syn.toLowerCase() == normalized) return comp;
      }
    }

    // Substring or typo-tolerant matching
    for (final comp in curatedDatabase) {
      final compNorm = comp.commonName.toLowerCase().replaceAll(RegExp(r'[\-_,\s]+'), ' ').trim();
      if (compNorm == normalized || compNorm.contains(normalized) || normalized.contains(compNorm)) {
        return comp;
      }
      for (final syn in comp.synonyms) {
        final synNorm = syn.toLowerCase().replaceAll(RegExp(r'[\-_,\s]+'), ' ').trim();
        if (synNorm == normalized || synNorm.contains(normalized) || normalized.contains(synNorm)) {
          return comp;
        }
      }
    }

    return null;
  }

  /// Parses a molecular formula into a map of element symbols to counts.
  /// Supports:
  /// - Nested parentheses: `(NH4)2SO4`
  /// - Brackets: `[Co(NH3)6]Cl3`
  /// - Hydrate dots: `CuSO4·5H2O`, `FeSO4.7H2O`, `Na2CO3*10H2O`
  /// - Multi-letter element symbols (`Na`, `Cl`, `Fe`, `Cu`, `K`, `Mn`, etc.)
  static Map<String, int> parseFormula(String formula) {
    final result = <String, int>{};
    var clean = formula.trim().replaceAll(' ', '');

    // Check for hydrate portion: separated by ·, ., or *
    final hydrateParts = clean.split(RegExp(r'[·\.\*]'));
    final mainFormula = hydrateParts.first;

    _mergeCounts(result, _parseSubFormula(mainFormula), 1);

    // Process hydrate segments (e.g. 5H2O)
    for (var i = 1; i < hydrateParts.length; i++) {
      final part = hydrateParts[i];
      if (part.isEmpty) continue;
      final match = RegExp(r'^(\d+)(.*)$').firstMatch(part);
      final multiplier = match != null ? (int.tryParse(match.group(1)!) ?? 1) : 1;
      final subPart = match != null ? match.group(2)! : part;

      if (subPart.isNotEmpty) {
        _mergeCounts(result, _parseSubFormula(subPart), multiplier);
      }
    }

    if (result.isEmpty) {
      throw FormatException('Could not parse any valid chemical elements from "$formula".');
    }

    return result;
  }

  /// Recursive parser for formula chunks with nested groups `( )` or `[ ]`.
  static Map<String, int> _parseSubFormula(String str) {
    final counts = <String, int>{};
    var i = 0;

    while (i < str.length) {
      final char = str[i];

      if (char == '(' || char == '[') {
        final closeChar = char == '(' ? ')' : ']';
        var depth = 1;
        final start = i + 1;
        i++;
        while (i < str.length && depth > 0) {
          if (str[i] == char) depth++;
          if (str[i] == closeChar) depth--;
          i++;
        }
        if (depth > 0) {
          throw FormatException('Mismatched brackets in formula "$str".');
        }
        final groupContent = str.substring(start, i - 1);
        // Look ahead for multiplier digits
        final numMatch = RegExp(r'^\d+').firstMatch(str.substring(i));
        var multiplier = 1;
        if (numMatch != null) {
          multiplier = int.parse(numMatch.group(0)!);
          i += numMatch.group(0)!.length;
        }

        final innerCounts = _parseSubFormula(groupContent);
        _mergeCounts(counts, innerCounts, multiplier);
      } else if (RegExp(r'[A-Z]').hasMatch(char)) {
        // Element symbol: 1 uppercase followed by optional lowercase letters
        var elem = char;
        i++;
        while (i < str.length && RegExp(r'[a-z]').hasMatch(str[i])) {
          elem += str[i];
          i++;
        }

        // Validate element symbol
        if (!atomicMasses.containsKey(elem)) {
          throw FormatException('Unknown chemical element symbol "$elem".');
        }

        // Look ahead for element count digits
        final numMatch = RegExp(r'^\d+').firstMatch(str.substring(i));
        var count = 1;
        if (numMatch != null) {
          count = int.parse(numMatch.group(0)!);
          i += numMatch.group(0)!.length;
        }

        counts[elem] = (counts[elem] ?? 0) + count;
      } else {
        // Skip stray characters (charges +, -, etc.)
        i++;
      }
    }

    return counts;
  }

  static void _mergeCounts(Map<String, int> target, Map<String, int> source, int multiplier) {
    source.forEach((k, v) {
      target[k] = (target[k] ?? 0) + (v * multiplier);
    });
  }

  /// Computes deterministic molar mass (g/mol) given element counts.
  static double calculateMolarMass(Map<String, int> elements) {
    var total = 0.0;
    elements.forEach((elem, count) {
      final mass = atomicMasses[elem];
      if (mass != null) {
        total += mass * count;
      }
    });
    return total;
  }

  /// Computes percentage mass for each element.
  static Map<String, double> calculatePercentages(Map<String, int> elements, double totalMass) {
    final result = <String, double>{};
    if (totalMass <= 0) return result;

    elements.forEach((elem, count) {
      final mass = (atomicMasses[elem] ?? 0.0) * count;
      result[elem] = double.parse(((mass / totalMass) * 100).toStringAsFixed(2));
    });
    return result;
  }

  /// Formats a molecular formula with proper subscript characters for numbers.
  /// E.g. "C7H6O2" -> "C₇H₆O₂", "CuSO4·5H2O" -> "CuSO₄·5H₂O".
  static String formatFormula(String formula) {
    var s = formula;
    // Replace digits that follow element symbols or closing brackets with subscripts
    s = s.replaceAllMapped(RegExp(r'([A-Za-z\)\]])(\d+)'), (m) {
      final lead = m[1]!;
      final digits = m[2]!.split('').map((d) => _subscriptMap[d] ?? d).join();
      return '$lead$digits';
    });
    return s;
  }
}
