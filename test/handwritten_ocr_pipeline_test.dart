import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/pdf_ocr_models.dart';
import 'package:chem_buddy/data/services/ocr/chemistry_ocr_normalizer.dart';
import 'package:chem_buddy/data/services/ocr/ocr_provider.dart';
import 'package:chem_buddy/data/services/pdf_text_utils.dart';

class MockTestOcrProvider implements OcrProvider {
  MockTestOcrProvider({this.simulatedText = ''});

  final String simulatedText;
  bool disposed = false;

  @override
  String get name => 'mock_test_ocr';

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<String> recognizeImage(File imageFile) async {
    return simulatedText;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('ChemistryOcrNormalizer Unit Tests', () {
    test('1. Fixes O vs 0 confusion in chemical formulas', () {
      expect(ChemistryOcrNormalizer.normalize('H2S04 is sulfuric acid'), contains('H₂SO₄'));
      expect(ChemistryOcrNormalizer.normalize('Titrate with KMN04 in acid'), contains('KMnO₄'));
      expect(ChemistryOcrNormalizer.normalize('Reaction produces H20 and C02'), contains('H₂O'));
      expect(ChemistryOcrNormalizer.normalize('Reaction produces H20 and C02'), contains('CO₂'));
      expect(ChemistryOcrNormalizer.normalize('Acetic acid formula is CH3C00H'), contains('CH₃COOH'));
      expect(ChemistryOcrNormalizer.normalize('Decomposition of CaC03 to CaO'), contains('CaCO₃'));
      expect(ChemistryOcrNormalizer.normalize('Neutralization of Na2C03 and NaHC03'), contains('Na₂CO₃'));
      expect(ChemistryOcrNormalizer.normalize('Glucose has formula C6H1206'), contains('C₆H₁₂O₆'));
    });

    test('2. Fixes OCR capitalization and element confusion', () {
      expect(ChemistryOcrNormalizer.normalize('Dissolve NACl in pure water'), contains('NaCl'));
      expect(ChemistryOcrNormalizer.normalize('Standard NAOH solution with HCL'), contains('NaOH'));
      expect(ChemistryOcrNormalizer.normalize('Standard NAOH solution with HCL'), contains('HCl'));
      expect(ChemistryOcrNormalizer.normalize('Precipitation of AGCL with AGNO3'), contains('AgCl'));
      expect(ChemistryOcrNormalizer.normalize('Precipitation of AGCL with AGNO3'), contains('AgNO₃'));
      expect(ChemistryOcrNormalizer.normalize('Anhydrous MGSO4 and CACL2 drying agents'), contains('MgSO₄'));
      expect(ChemistryOcrNormalizer.normalize('Anhydrous MGSO4 and CACL2 drying agents'), contains('CaCl₂'));
    });

    test('3. Subscripts chemical formulas accurately without touching non-formula words', () {
      expect(ChemistryOcrNormalizer.normalize('H2SO4 + 2 NaOH -> Na2SO4 + 2 H2O'), contains('H₂SO₄'));
      expect(ChemistryOcrNormalizer.normalize('H2SO4 + 2 NaOH -> Na2SO4 + 2 H2O'), contains('Na₂SO₄'));
      expect(ChemistryOcrNormalizer.normalize('H2SO4 + 2 NaOH -> Na2SO4 + 2 H2O'), contains('H₂O'));

      // Non-formula acronyms should NOT be subscripted
      final ocrText = ChemistryOcrNormalizer.normalize('Analysis performed by HPLC with PDA detector and 1H-NMR spectroscopy');
      expect(ocrText, contains('HPLC'));
      expect(ocrText, contains('PDA'));
      expect(ocrText, contains('¹H NMR'));
    });

    test('4. Formats ionic charges as superscripts', () {
      expect(ChemistryOcrNormalizer.normalize('Oxidation of Fe2+ to Fe3+ by KMnO4'), contains('Fe²⁺'));
      expect(ChemistryOcrNormalizer.normalize('Oxidation of Fe2+ to Fe3+ by KMnO4'), contains('Fe³⁺'));
      expect(ChemistryOcrNormalizer.normalize('Precipitation of Cu2+ and Ca2+ ions'), contains('Cu²⁺'));
      expect(ChemistryOcrNormalizer.normalize('Precipitation of Cu2+ and Ca2+ ions'), contains('Ca²⁺'));
      expect(ChemistryOcrNormalizer.normalize('Hydronium H3O+ and hydroxide OH- equilibrium'), contains('H₃O⁺'));
      expect(ChemistryOcrNormalizer.normalize('Hydronium H3O+ and hydroxide OH- equilibrium'), contains('OH⁻'));
    });

    test('5. Formats NMR isotopes and spectroscopy units', () {
      expect(ChemistryOcrNormalizer.normalize('1H-NMR spectrum recorded in CDCl3'), contains('¹H NMR'));
      expect(ChemistryOcrNormalizer.normalize('13C-NMR signals at 128 ppm'), contains('¹³C NMR'));
      expect(ChemistryOcrNormalizer.normalize('31P-NMR and 19F-NMR analysis'), contains('³¹P NMR'));
      expect(ChemistryOcrNormalizer.normalize('Carbonyl stretch observed at 1715 cm-1'), contains('1715 cm⁻¹'));
      expect(ChemistryOcrNormalizer.normalize('Activation energy of 75.4 kJ/mol'), contains('75.4 kJ·mol⁻¹'));
      expect(ChemistryOcrNormalizer.normalize('Concentration is 0.05 mol/L'), contains('0.05 mol·L⁻¹'));
    });

    test('6. Normalizes reaction arrows and reaction condition symbols', () {
      expect(ChemistryOcrNormalizer.normalize('A + B --> C + D'), contains('A + B → C + D'));
      expect(ChemistryOcrNormalizer.normalize('N2 + 3 H2 <=> 2 NH3'), contains('N₂ + 3 H₂ ⇌ 2 NH₃'));
      expect(ChemistryOcrNormalizer.normalize('Resonance forms: I <--> II'), contains('I ↔ II'));
      expect(ChemistryOcrNormalizer.normalize('Heat under reflux at delta and 100 deg C'), contains('Δ'));
      expect(ChemistryOcrNormalizer.normalize('Heat under reflux at delta and 100 deg C'), contains('100 °C'));
      expect(ChemistryOcrNormalizer.normalize('Photochemical cleavage under hv irradiation'), contains('hν'));
      expect(ChemistryOcrNormalizer.normalize('Reaction half life t1/2 = 12.5 min'), contains('t½'));
    });

    test('7. Preserves and normalizes physical chemistry equations', () {
      final gibbs = ChemistryOcrNormalizer.normalize('Gibbs relation: delta G = delta H - T delta S');
      expect(gibbs, contains('ΔG° = ΔH° − TΔS°'));

      final arrhenius = ChemistryOcrNormalizer.normalize('Arrhenius equation: k = A e^(-Ea/RT)');
      expect(arrhenius, contains('k = A e^(−Ea / RT)'));

      final beer = ChemistryOcrNormalizer.normalize('Beer-Lambert: A = eps * c * l');
      expect(beer, contains('A = ε · c · l'));

      final bragg = ChemistryOcrNormalizer.normalize('Bragg law: n lambda = 2 d sin theta');
      expect(bragg, contains('nλ = 2d sin(θ)'));
    });

    test('8. extractDetectedFormulas extracts formulas and reaction lines', () {
      const sampleText = '''
MSc Chemistry Laboratory Report:
Substrate: Benzaldehyde (C₆H₅CHO)
Reagents: Concentrated NaOH, KMnO₄ catalyst
Reaction: 2 C₆H₅CHO + NaOH → C₆H₅COONa + C₆H₅CH₂OH
Thermodynamic parameter: ΔG° = ΔH° − TΔS°
Beer-Lambert law: A = ε · c · l
''';
      final formulas = ChemistryOcrNormalizer.extractDetectedFormulas(sampleText);
      expect(formulas, isNotEmpty);
      expect(formulas.any((f) => f.contains('C₆H₅CHO') || f.contains('KMnO₄')), isTrue);
      expect(formulas.any((f) => f.contains('→')), isTrue);
      expect(formulas.any((f) => f.contains('ΔG°') || f.contains('A = ε')), isTrue);
    });
  });

  group('DocumentOcrBundle & PdfPageOcrResult Models', () {
    test('1. Serializes and deserializes PdfPageOcrResult to JSON', () {
      const page = PdfPageOcrResult(
        pageNumber: 1,
        rawText: 'H2S04 + 2 NAOH --> Na2SO4 + 2 H2O',
        cleanedText: 'H₂SO₄ + 2 NaOH → Na₂SO₄ + 2 H₂O',
        quality: PageQuality.handwritten,
        confidence: 0.92,
        detectedFormulas: ['H₂SO₄', 'Na₂SO₄', 'H₂O'],
        keyTerms: ['Neutralization', 'Titration'],
      );

      final json = page.toJson();
      final revived = PdfPageOcrResult.fromJson(json);

      expect(revived.pageNumber, 1);
      expect(revived.cleanedText, page.cleanedText);
      expect(revived.quality, PageQuality.handwritten);
      expect(revived.confidence, 0.92);
      expect(revived.detectedFormulas, ['H₂SO₄', 'Na₂SO₄', 'H₂O']);
      expect(revived.keyTerms, ['Neutralization', 'Titration']);
    });

    test('2. Serializes and deserializes DocumentOcrBundle to JSON', () {
      final bundle = DocumentOcrBundle(
        docId: 'test-doc-123',
        docTitle: 'Organic Mechanisms Lecture',
        pages: const [
          PdfPageOcrResult(
            pageNumber: 1,
            rawText: 'Cannizzaro Reaction of Benzaldehyde',
            cleanedText: 'Cannizzaro Reaction of Benzaldehyde (C₆H₅CHO)',
            quality: PageQuality.digitalText,
            confidence: 1.0,
            detectedFormulas: ['C₆H₅CHO'],
          ),
          PdfPageOcrResult(
            pageNumber: 2,
            rawText: 'Hydride transfer step: tetrahedral intermediate',
            cleanedText: 'Hydride transfer step: tetrahedral mono/dianion intermediate',
            quality: PageQuality.handwritten,
            confidence: 0.89,
            detectedFormulas: ['H⁻'],
          ),
        ],
        overallQuality: DocumentQuality.mixed,
        processedAt: DateTime(2026, 9, 6),
        totalPages: 2,
      );

      final json = bundle.toJson();
      final revived = DocumentOcrBundle.fromJson(json);

      expect(revived.docId, 'test-doc-123');
      expect(revived.docTitle, 'Organic Mechanisms Lecture');
      expect(revived.pageCount, 2);
      expect(revived.overallQuality, DocumentQuality.mixed);
      expect(revived.textForPage(1), contains('C₆H₅CHO'));
      expect(revived.textForPage(2), contains('Hydride transfer'));
      expect(revived.fullText, contains('--- Page 1 ---'));
      expect(revived.fullText, contains('--- Page 2 ---'));
      expect(revived.allDetectedFormulas, containsAll(['C₆H₅CHO', 'H⁻']));
      expect(revived.ocrPageRatio, 0.5);
    });
  });

  group('Pluggable OcrProvider & Pipeline Integration', () {
    test('1. Mock OCR provider processes simulated handwritten notes correctly', () async {
      final mockOcr = MockTestOcrProvider(
        simulatedText: 'KMN04 oxidation of secondary alcohol to ketone with H2S04 at 80 deg C\nRate law: k = A e^(-Ea/RT)',
      );

      expect(await mockOcr.isAvailable, isTrue);
      final rawText = await mockOcr.recognizeImage(File('dummy.jpg'));
      final normalized = ChemistryOcrNormalizer.normalize(rawText);

      expect(normalized, contains('KMnO₄'));
      expect(normalized, contains('H₂SO₄'));
      expect(normalized, contains('80 °C'));
      expect(normalized, contains('k = A e^(−Ea / RT)'));

      await mockOcr.dispose();
      expect(mockOcr.disposed, isTrue);
    });
  });
}
