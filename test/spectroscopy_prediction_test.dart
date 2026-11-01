import 'dart:convert';

import 'package:chem_buddy/data/remote/supabase_service.dart';
import 'package:chem_buddy/data/services/spectroscopy_prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/spectroscopy_prediction_fixture.dart';

class PredictionRemote implements SupabaseService {
  String? uid = 'student';
  final requests = <Map<String, dynamic>>[];
  List<String> responses = [jsonEncode(ethanolPredictionJson())];
  void Function()? onResponse;
  @override
  String? get userId => uid;
  @override
  Future<dynamic> invokeFunction(
    String name,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 45),
    int maxRetries = 3,
  }) async {
    expect(name, 'ask-gemini-orchestrator');
    requests.add(body);
    onResponse?.call();
    return {
      'text': responses[requests.length - 1],
      'model': 'server-selected-Gemini',
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('ethanol assignments preserve integration, atom identity, ranges and formula-checked SVG', () {
    final value = ethanolPrediction();
    expect(value.compound.formula, 'C2H6O');
    expect(value.compound.dbe, 0);
    expect(value.proton.map((s) => s.signal.integration), [3, 2, 1]);
    expect(value.proton.first.signal.couplingsHz, [7]);
    expect(value.carbon.map((s) => s.signal.position), [18, 58]);
    expect(value.depiction.svg, contains('<svg'));
    expect(value.depiction.graph!.atoms, hasLength(3));
  });
  final corruptions = <String, void Function(Map<String, dynamic>)>{
    'formula mismatches structure': (d) => d['formula'] = 'C3H8O',
    'returned input differs': (d) => d['compound_input'] = 'methanol',
    'conditions differ': (d) => d['conditions']['solvent'] = 'DMSO-d6',
    'temperature differs': (d) => d['conditions']['temperature_kelvin'] = 310,
    'frequency differs': (d) => d['conditions']['frequency_mhz'] = 600,
    'missing carbon': (d) => d['carbon_signals'].removeLast(),
    'duplicated carbon': (d) => d['carbon_signals'][1]['atom_indices'] = [1],
    'noncarbon in carbon assignment': (d) =>
        d['carbon_signals'][1]['atom_indices'] = [3],
    'missing exchangeable proton': (d) => d['proton_signals'].removeLast(),
    'integral conflicts with contributions': (d) =>
        d['proton_signals'][0]['hydrogen_count'] = 2,
    'hydrogens exceed an atom inventory': (d) {
      d['proton_signals'][0]['hydrogen_count'] = 4;
      d['proton_signals'][0]['hydrogens_by_atom'][0]['count'] = 4;
    },
    'protons mapped to wrong carbon': (d) {
      d['proton_signals'][0]['atom_indices'] = [2];
      d['proton_signals'][0]['hydrogens_by_atom'][0]['atom_index'] = 2;
    },
    'zero atom index': (d) => d['carbon_signals'][0]['atom_indices'] = [0],
    'noninteger atom index': (d) =>
        d['carbon_signals'][0]['atom_indices'] = [1.5],
    'out-of-range atom index': (d) =>
        d['carbon_signals'][0]['atom_indices'] = [8],
    'duplicated atom in one signal': (d) =>
        d['carbon_signals'][0]['atom_indices'] = [1, 1],
    'reversed range': (d) => d['proton_signals'][0]['minimum_ppm'] = 5,
    'centre outside range': (d) => d['proton_signals'][0]['shift_ppm'] = 9,
    'nonnumeric shift': (d) => d['proton_signals'][0]['shift_ppm'] = '1.2',
    'negative coupling': (d) => d['proton_signals'][0]['j_hz'] = [-7],
    'unknown multiplicity': (d) =>
        d['proton_signals'][0]['multiplicity'] = 'guaranteed triplet',
    'missing limitations': (d) => d['uncertainties'] = [],
    'unclosed ring': (d) => d['smiles'] = 'C1CO',
    'unclosed branch': (d) => d['smiles'] = 'C(CO',
    'trailing bond': (d) => d['smiles'] = 'CCO=',
    'silently discarded characters': (d) => d['smiles'] = 'CCO?',
    'stereochemistry cannot be silently removed': (d) =>
        d['smiles'] = 'C[C@H]O',
    'fragments are not one molecule': (d) => d['smiles'] = 'CC.O',
  };
  for (final entry in corruptions.entries) {
    test('withholds prediction: ${entry.key}', () {
      final d = ethanolPredictionJson();
      entry.value(d);
      expect(
        () =>
            SpectroscopyPredictionService.parse(jsonEncode(d), ethanolRequest),
        throwsFormatException,
      );
    });
  }
  test(
    'molecular formula alone asks for identity rather than inventing an isomer',
    () {
      expect(
        () => const SpectroscopyPredictionRequest(compound: 'C2H6O').validate(),
        throwsA(isA<PredictionNeedsClarification>()),
      );
    },
  );
  test('supplied SMILES is preserved exactly', () {
    final d = ethanolPredictionJson()..['compound_input'] = 'OCC';
    expect(
      () => SpectroscopyPredictionService.parse(
        jsonEncode(d),
        const SpectroscopyPredictionRequest(
          compound: 'OCC',
          kind: CompoundInputKind.smiles,
        ),
      ),
      throwsFormatException,
    );
  });
  test('cloud call uses existing server keys and includes full prediction conditions', () async {
    final remote = PredictionRemote();
    final value = await SpectroscopyPredictionService(remote: remote)
        .predict(ethanolRequest);
    expect(value.model, 'server-selected-Gemini');
    expect(remote.requests.single['category'], 'spectroscopy_prediction');
    expect(
      jsonDecode(remote.requests.single['prompt'])['input']['solvent'],
      'CDCl3',
    );
    expect(remote.requests.single.containsKey('api_key'), isFalse);
  });
  test('contradictory response gets one correction attempt', () async {
    final remote = PredictionRemote()
      ..responses = [
        jsonEncode(ethanolPredictionJson()..['formula'] = 'C3H8O'),
        jsonEncode(ethanolPredictionJson()),
      ];
    final value = await SpectroscopyPredictionService(remote: remote)
        .predict(ethanolRequest);
    expect(value.compound.formula, 'C2H6O');
    expect(remote.requests, hasLength(2));
    expect(
      jsonDecode(remote.requests[1]['prompt']),
      contains('validation_error_to_correct'),
    );
  });
  test(
    'two malformed responses are withheld without an endless retry',
    () async {
      final remote = PredictionRemote()..responses = ['not JSON', 'not JSON'];
      await expectLater(
        SpectroscopyPredictionService(remote: remote).predict(ethanolRequest),
        throwsFormatException,
      );
      expect(remote.requests, hasLength(2));
    },
  );
  test(
    'ambiguous identity response is not repaired into a fabricated structure',
    () async {
      final remote = PredictionRemote()
        ..responses = [
          jsonEncode({
            'status': 'needs_clarification',
            'message': 'Which cresol isomer?',
          }),
        ];
      await expectLater(
        SpectroscopyPredictionService(remote: remote).predict(ethanolRequest),
        throwsA(isA<PredictionNeedsClarification>()),
      );
      expect(remote.requests, hasLength(1));
    },
  );
  test('guest mode never invokes Gemini or produces fake spectra', () async {
    final remote = PredictionRemote()..uid = null;
    await expectLater(
      SpectroscopyPredictionService(remote: remote).predict(ethanolRequest),
      throwsStateError,
    );
    expect(remote.requests, isEmpty);
  });
  test('account switch discards in-flight private prediction', () async {
    final remote = PredictionRemote();
    remote.onResponse = () => remote.uid = 'other-student';
    await expectLater(
      SpectroscopyPredictionService(remote: remote).predict(ethanolRequest),
      throwsStateError,
    );
  });
}
