import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/chemistry/compound_conformer.dart';
import '../../core/widgets/molecule_3d/molecule_3d_models.dart';
import '../../core/widgets/molecule_3d/molecule_3d_viewer.dart';

class PubChemConformerScreen extends StatefulWidget {
  const PubChemConformerScreen({
    super.key,
    required this.cid,
    required this.name,
    required this.formula,
  });

  final int cid;
  final String name;
  final String formula;

  @override
  State<PubChemConformerScreen> createState() => _PubChemConformerScreenState();
}

class _PubChemConformerScreenState extends State<PubChemConformerScreen> {
  final _client = http.Client();
  late Future<Molecule3D?> _conformer = _load();

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<Molecule3D?> _load() async {
    final response = await _client
        .get(
          Uri.https(
            'pubchem.ncbi.nlm.nih.gov',
            '/rest/pug/compound/cid/${widget.cid}/SDF',
            {'record_type': '3d'},
          ),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw http.ClientException('PubChem conformer request failed');
    }
    final result = CompoundConformer.fromMolfile(
      utf8.decode(response.bodyBytes),
      id: 'pubchem-${widget.cid}',
      name: widget.name,
      formula: widget.formula,
    );
    if (result == null) throw const FormatException('Unsupported 3D record');
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.name)),
    body: SafeArea(
      child: FutureBuilder<Molecule3D?>(
        future: _conformer,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading conformer',
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not open the PubChem 3D record.',
                      textAlign: TextAlign.center,
                    ),
                    FilledButton.tonal(
                      onPressed: () => setState(() => _conformer = _load()),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.data case final model?) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Molecule3DViewer(molecule: model, showLabelsInitial: false),
                const SizedBox(height: 8),
                Text(
                  'PubChem CID ${widget.cid} · computed conformer showing one possible geometry.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'PubChem does not provide a 3D conformer for this record. The 2D diagram is available on the compound page.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    ),
  );
}
