import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/chemical_name_database.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';
import 'package:chem_buddy/data/models/timetable_entry.dart';

void main() {
  group('1. MSc Chemical Name Database & Deterministic Molar Mass Tests', () {
    test('Resolves common organic compound names to exact formulas & masses', () {
      // Benzoic acid: C7H6O2 -> 7*12.011 + 6*1.008 + 2*15.999 = 122.12
      final benzoic = ChemicalNameDatabase.resolve('benzoic acid');
      expect(benzoic.isFromDatabase, true);
      expect(benzoic.formula, 'C7H6O2');
      expect(benzoic.formattedFormula, 'C₇H₆O₂');
      expect((benzoic.molarMass - 122.12).abs() < 0.05, true);

      // Acetic acid: C2H4O2 -> 60.05
      final acetic = ChemicalNameDatabase.resolve('acetic acid');
      expect(acetic.formula, 'C2H4O2');
      expect((acetic.molarMass - 60.05).abs() < 0.05, true);

      // Ethanol: C2H6O -> 46.07
      final ethanol = ChemicalNameDatabase.resolve('ethanol');
      expect(ethanol.formula, 'C2H6O');
      expect((ethanol.molarMass - 46.07).abs() < 0.05, true);

      // Phenol: C6H6O -> 94.11
      final phenol = ChemicalNameDatabase.resolve('phenol');
      expect(phenol.formula, 'C6H6O');
      expect((phenol.molarMass - 94.11).abs() < 0.05, true);

      // Aniline: C6H7N -> 93.13
      final aniline = ChemicalNameDatabase.resolve('aniline');
      expect(aniline.formula, 'C6H7N');
      expect((aniline.molarMass - 93.13).abs() < 0.05, true);
    });

    test('Resolves inorganic salts and common laboratory reagents', () {
      // Sodium chloride: NaCl -> 22.99 + 35.45 = 58.44
      final nacl = ChemicalNameDatabase.resolve('sodium chloride');
      expect(nacl.formula, 'NaCl');
      expect((nacl.molarMass - 58.44).abs() < 0.05, true);

      // Potassium permanganate: KMnO4 -> 39.098 + 54.938 + 4*15.999 = 158.03
      final kmno4 = ChemicalNameDatabase.resolve('potassium permanganate');
      expect(kmno4.formula, 'KMnO4');
      expect((kmno4.molarMass - 158.03).abs() < 0.1, true);

      // Sulfuric acid: H2SO4 -> 98.08
      final h2so4 = ChemicalNameDatabase.resolve('sulfuric acid');
      expect(h2so4.formula, 'H2SO4');
      expect((h2so4.molarMass - 98.08).abs() < 0.1, true);
    });

    test('Correctly parses hydrates with dot separator (e.g. CuSO4·5H2O, FeSO4·7H2O)', () {
      // Copper(II) sulfate pentahydrate: CuSO4·5H2O -> 159.61 + 5*18.015 = 249.68
      final cuso4 = ChemicalNameDatabase.resolve('CuSO4·5H2O');
      expect((cuso4.molarMass - 249.68).abs() < 0.15, true);

      // Iron(II) sulfate heptahydrate: FeSO4·7H2O -> 151.91 + 7*18.015 = 278.01
      final feso4 = ChemicalNameDatabase.resolve('FeSO4.7H2O');
      expect((feso4.molarMass - 278.01).abs() < 0.15, true);
    });

    test('Correctly parses nested brackets and parenthesis in complex formulas', () {
      // Calcium hydroxide: Ca(OH)2 -> 40.078 + 2*(15.999 + 1.008) = 74.09
      final caoh2 = ChemicalNameDatabase.resolve('Ca(OH)2');
      expect((caoh2.molarMass - 74.09).abs() < 0.05, true);

      // Ammonium sulfate: (NH4)2SO4 -> 2*(14.007 + 4*1.008) + 32.06 + 4*15.999 = 132.14
      final ammsulf = ChemicalNameDatabase.resolve('(NH4)2SO4');
      expect((ammsulf.molarMass - 132.14).abs() < 0.1, true);
    });

    test('Correctly parses direct formulas C8H8O and C6H6', () {
      final c8h8o = ChemicalNameDatabase.resolve('C8H8O');
      expect((c8h8o.molarMass - 120.15).abs() < 0.1, true);

      final c6h6 = ChemicalNameDatabase.resolve('C6H6');
      expect((c6h6.molarMass - 78.11).abs() < 0.1, true);
    });

    test('Rejects invalid formula inputs and unknown chemical names gracefully', () {
      expect(() => ChemicalNameDatabase.resolve('XYZ999UnknownMolecule'), throwsA(isA<FormatException>()));
      expect(() => ChemicalNameDatabase.resolve('C(H2'), throwsA(isA<FormatException>()));
    });
  });

  group('2. Spectroscopy Calculation Safety & Academic Valence Tests', () {
    test('Calculates DBE with full halogens (F, Cl, Br, I) and Nitrogen compensation', () {
      // Benzene: C6H6 -> (2*6 + 2 - 6)/2 = 4
      expect(SpectroscopyService.calculateDBE(carbons: 6, hydrogens: 6), 4.0);

      // Acetophenone: C8H8O -> (2*8 + 2 - 8)/2 = 5
      expect(SpectroscopyService.calculateDBE(carbons: 8, hydrogens: 8, oxygens: 1), 5.0);

      // 4-Aminobenzoic acid ethyl ester: C9H11NO2 -> (2*9 + 2 + 1 - 11)/2 = 5
      expect(SpectroscopyService.calculateDBE(carbons: 9, hydrogens: 11, nitrogens: 1, oxygens: 2), 5.0);

      // 1-Bromopropane: C3H7Br -> (2*3 + 2 - 7 - 1)/2 = 0
      expect(SpectroscopyService.calculateDBE(carbons: 3, hydrogens: 7, halogens: 1), 0.0);
    });

    test('parseFormula validates carbon presence and detects chemically impossible saturation', () {
      // Water: H2O (No Carbon) -> invalid for organic spectroscopy
      final h2o = SpectroscopyService.parseFormula('H2O');
      expect(h2o.isValid, false);
      expect(h2o.errorMessage, contains('must contain at least 1 Carbon'));

      // Chemically impossible hyper-hydrogenation: CH6 (Carbon tetravalency violation, DBE < 0)
      final ch6 = SpectroscopyService.parseFormula('CH6');
      expect(ch6.isValid, false);
      expect(ch6.dbe < 0, true);
      expect(ch6.errorMessage, contains('Chemically impossible formula'));
      expect(ch6.errorMessage, contains('tetravalency'));
    });

    test('analyzeSpectraStructured returns 8-step deduction pipeline', () {
      final res = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O',
        irPeaks: [1685, 1600, 1450],
        nmrPeaks: [2.6, 7.5, 7.9],
        msPeaks: [120, 105, 77],
      );

      expect(res.isValid, true);
      expect(res.formula, 'C8H8O');
      expect(res.dbe, 5.0);
      expect(res.steps.length, 8);
      expect(res.steps[0].title, contains('Degrees of Unsaturation'));
      expect(res.steps[1].title, contains('FT-IR'));
      expect(res.steps[2].title, contains('¹H NMR'));
      expect(res.steps[3].title, contains('¹³C NMR'));
      expect(res.steps[4].title, contains('Mass Spectrometry'));
      expect(res.steps[5].title, contains('Subunit Assembly'));
      expect(res.steps[6].title, contains('Candidate Structural Hypotheses'));
      expect(res.steps[7].title, contains('Final Structure Verification'));
    });
  });

  group('3. Timetable Data Validation & Overlap Detection Tests', () {
    int timeToMinutes(String timeStr) {
      final clean = timeStr.trim().toUpperCase();
      final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)').firstMatch(clean);
      if (match == null) return 0;
      var hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final period = match.group(3)!;
      if (period == 'PM' && hours < 12) hours += 12;
      if (period == 'AM' && hours == 12) hours = 0;
      return hours * 60 + minutes;
    }

    bool isTimeRangeValid(String start, String end) {
      final s = timeToMinutes(start);
      final e = timeToMinutes(end);
      return s < e;
    }

    bool hasOverlap(TimetableEntry a, TimetableEntry b) {
      if (a.dayOfWeek.toLowerCase() != b.dayOfWeek.toLowerCase()) return false;
      final startA = timeToMinutes(a.startTime);
      final endA = timeToMinutes(a.endTime);
      final startB = timeToMinutes(b.startTime);
      final endB = timeToMinutes(b.endTime);
      // Overlap condition: max(startA, startB) < min(endA, endB)
      final latestStart = startA > startB ? startA : startB;
      final earliestEnd = endA < endB ? endA : endB;
      return latestStart < earliestEnd;
    }

    test('Validates start < end and flags inverted ranges (e.g. 5:30 PM to 1:30 PM)', () {
      expect(isTimeRangeValid('09:00 AM', '10:00 AM'), true);
      expect(isTimeRangeValid('02:00 PM', '04:00 PM'), true);

      // Inverted range: 5:30 PM to 1:30 PM
      expect(isTimeRangeValid('05:30 PM', '01:30 PM'), false);
      // Equal start and end
      expect(isTimeRangeValid('10:00 AM', '10:00 AM'), false);
    });

    test('Accurately detects overlapping lectures on the same day', () {
      const slot1 = TimetableEntry(
        id: '1',
        dayOfWeek: 'Monday',
        startTime: '09:00 AM',
        endTime: '11:00 AM',
        subject: 'Organic Chemistry',
        subjectCode: 'CHE-501',
      );

      const slot2Overlapping = TimetableEntry(
        id: '2',
        dayOfWeek: 'Monday',
        startTime: '10:30 AM',
        endTime: '12:00 PM',
        subject: 'Inorganic Chemistry',
        subjectCode: 'CHE-502',
      );

      const slot3NonOverlappingSameDay = TimetableEntry(
        id: '3',
        dayOfWeek: 'Monday',
        startTime: '11:30 AM',
        endTime: '01:00 PM',
        subject: 'Physical Chemistry',
        subjectCode: 'CHE-503',
      );

      const slot4DifferentDaySameTime = TimetableEntry(
        id: '4',
        dayOfWeek: 'Tuesday',
        startTime: '09:30 AM',
        endTime: '11:30 AM',
        subject: 'Analytical Chemistry',
        subjectCode: 'CHE-504',
      );

      expect(hasOverlap(slot1, slot2Overlapping), true);
      expect(hasOverlap(slot1, slot3NonOverlappingSameDay), false);
      expect(hasOverlap(slot1, slot4DifferentDaySameTime), false);
    });
  });
}
