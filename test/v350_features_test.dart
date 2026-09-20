import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('v3.5.0 Spectroscopy Structure Solver Tests', () {
    test('Identifies Acetophenone and rules out 4-methylbenzaldehyde', () {
      final res = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O',
        irPeaks: [1685.0, 1600.0, 1360.0],
        nmr1HPeaks: [2.60, 7.45, 7.55, 7.95],
        nmr13CPeaks: [26.6, 128.3, 128.5, 133.1, 137.1, 198.1],
        msPeaks: [120.0, 105.0, 77.0, 43.0],
      );

      expect(res.isValid, isTrue);
      expect(res.formula, 'C8H8O');
      expect(res.dbe, 5.0);
      
      final step7 = res.steps.firstWhere((s) => s.stepNumber == 7);
      expect(step7.summary, contains('Acetophenone'));
      expect(step7.content, contains('Acetophenone (1-Phenylethan-1-one)'));
      expect(step7.content, contains('4-Methylbenzaldehyde'));
      expect(step7.content, contains('m/z 105'));
    });

    test('Identifies Aspirin with dual carbonyls and ketene loss', () {
      final res = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C9H8O4',
        irPeaks: [1755.0, 1690.0, 1185.0],
        nmr1HPeaks: [2.35, 7.15, 7.35, 7.62, 8.12, 11.10],
        nmr13CPeaks: [20.9, 122.2, 123.9, 126.1, 132.4, 134.8, 151.2, 169.8, 170.1],
        msPeaks: [180.0, 138.0, 120.0, 43.0],
      );

      expect(res.isValid, isTrue);
      final step7 = res.steps.firstWhere((s) => s.stepNumber == 7);
      expect(step7.summary, contains('Aspirin'));
      expect(step7.content, contains('2-Acetoxybenzoic acid'));
      expect(step7.content, contains('m/z 138'));
      expect(step7.content, contains('4-Acetoxybenzoic acid'));
    });

    test('Disambiguates 1-Bromopropane vs 2-Bromopropane via NMR peaks', () {
      // 1-Bromopropane
      final res1 = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C3H7Br',
        nmr1HPeaks: [1.04, 1.90, 3.38],
      );
      final step7_1 = res1.steps.firstWhere((s) => s.stepNumber == 7);
      expect(step7_1.summary, contains('1-Bromopropane'));

      // 2-Bromopropane
      final res2 = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C3H7Br',
        nmr1HPeaks: [1.72, 4.28],
      );
      final step7_2 = res2.steps.firstWhere((s) => s.stepNumber == 7);
      expect(step7_2.summary, contains('2-Bromopropane'));
    });

    test('Algorithmic solver handles unlisted formula with chemical precision', () {
      final res = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C7H7Cl',
        nmr1HPeaks: [4.55, 7.30, 7.35],
      );

      expect(res.isValid, isTrue);
      expect(res.dbe, 4.0);
      final step7 = res.steps.firstWhere((s) => s.stepNumber == 7);
      expect(step7.content, contains('Core Benzene Framework'));
    });
  });

  group('v3.5.0 ChemDraw Pro Sketcher Asset Verification', () {
    test('sketcher.html contains full 118 elements and pro features', () {
      final file = File('assets/web/sketcher.html');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      // Verify 118 elements database
      expect(content, contains('PERIODIC_TABLE_118'));
      expect(content, contains("{ z: 1, sym: 'H'"));
      expect(content, contains("{ z: 118, sym: 'Og'"));
      expect(content, contains('ptable-modal'));
      expect(content, contains('ptable-search'));

      // Verify ChemDraw Pro tools
      expect(content, contains('btn-select'));
      expect(content, contains('btn-clean'));
      expect(content, contains('cleanUpStructure'));
      expect(content, contains('charge_pos'));
      expect(content, contains('charge_neg'));

      // Verify Non-destructive template placement
      expect(content, contains('loadAspirinTemplate'));
      expect(content, contains('loadSalicylicTemplate'));
      expect(content, contains('loadParacetamolTemplate'));
      expect(content, contains('loadBenzoicTemplate'));

      // Verify ChemBridge payload structure
      expect(content, contains("type: 'structureChanged'"));
    });
  });
}
