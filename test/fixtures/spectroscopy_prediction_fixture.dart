import 'dart:convert';

import 'package:chem_buddy/data/services/spectroscopy_prediction_service.dart';

const ethanolRequest = SpectroscopyPredictionRequest(compound: 'ethanol');
Map<String, dynamic> ethanolPredictionJson() => {
  'status': 'predicted',
  'compound_input': 'ethanol',
  'name': 'Ethanol',
  'formula': 'C2H6O',
  'smiles': 'CCO',
  'conditions': {
    'solvent': 'CDCl3',
    'temperature_kelvin': 298,
    'frequency_mhz': 400,
  },
  'proton_signals': [
    {
      'shift_ppm': 1.2,
      'minimum_ppm': 1.1,
      'maximum_ppm': 1.3,
      'hydrogen_count': 3,
      'multiplicity': 't',
      'j_hz': [7.0],
      'assignment': 'CH3 adjacent to CH2',
      'atom_indices': [1],
      'hydrogens_by_atom': [
        {'atom_index': 1, 'count': 3},
      ],
    },
    {
      'shift_ppm': 3.65,
      'minimum_ppm': 3.5,
      'maximum_ppm': 3.8,
      'hydrogen_count': 2,
      'multiplicity': 'q',
      'j_hz': [7.0],
      'assignment': 'CH2 bonded to oxygen',
      'atom_indices': [2],
      'hydrogens_by_atom': [
        {'atom_index': 2, 'count': 2},
      ],
    },
    {
      'shift_ppm': 2.0,
      'minimum_ppm': 1.0,
      'maximum_ppm': 5.0,
      'hydrogen_count': 1,
      'multiplicity': 'br s',
      'j_hz': [],
      'assignment': 'Exchangeable OH; position depends on conditions',
      'atom_indices': [3],
      'hydrogens_by_atom': [
        {'atom_index': 3, 'count': 1},
      ],
    },
  ],
  'carbon_signals': [
    {
      'shift_ppm': 18,
      'minimum_ppm': 16,
      'maximum_ppm': 20,
      'assignment': 'Methyl carbon',
      'atom_indices': [1],
    },
    {
      'shift_ppm': 58,
      'minimum_ppm': 56,
      'maximum_ppm': 60,
      'assignment': 'Oxygen-bearing methylene',
      'atom_indices': [2],
    },
  ],
  'explanation': [
    'DBE 0 is consistent with an acyclic saturated structure.',
    'The ethyl group has methyl and methylene environments.',
  ],
  'uncertainties': [
    'These are estimates, not experimental measurements. OH shifts vary with solvent and concentration.',
  ],
};
SpectroscopyPrediction ethanolPrediction() =>
    SpectroscopyPredictionService.parse(
      jsonEncode(ethanolPredictionJson()),
      ethanolRequest,
      model: 'test-model',
    );
