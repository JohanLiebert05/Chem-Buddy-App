import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/chemistry/compound_structure_svg.dart';
import '../../core/widgets/liquid_glass.dart';
import 'pubchem_conformer_screen.dart';

class PubChemLookupScreen extends StatefulWidget {
  const PubChemLookupScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<PubChemLookupScreen> createState() => _PubChemLookupScreenState();
}

class _PubChemLookupScreenState extends State<PubChemLookupScreen> {
  static const _host = 'pubchem.ncbi.nlm.nih.gov';
  late final _query = TextEditingController(text: widget.initialQuery);
  final _client = http.Client();
  Map<String, dynamic>? _compound;
  List<Map<String, dynamic>> _matches = const [];
  Future<String?>? _structure;
  Future<List<String>>? _aliases;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _query.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _search() async {
    if (_loading) return;
    final query = _query.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Enter a compound name or PubChem CID.');
      return;
    }
    FocusScope.of(context).unfocus();
    final namespace = RegExp(r'^\d+$').hasMatch(query) ? 'cid' : 'name';
    final uri = Uri(
      scheme: 'https',
      host: _host,
      pathSegments: [
        'rest',
        'pug',
        'compound',
        namespace,
        query,
        'property',
        'Title,MolecularFormula,MolecularWeight,IUPACName,SMILES,InChIKey',
        'JSON',
      ],
    );
    setState(() {
      _error = null;
      _compound = null;
      _matches = const [];
      _loading = true;
    });

    List<Map<String, dynamic>> matches = const [];
    String? error;
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      switch (response.statusCode) {
        case 200:
          final json = jsonDecode(
            utf8.decode(response.bodyBytes),
          ) as Map<String, dynamic>;
          final table = json['PropertyTable'] as Map<String, dynamic>?;
          final rows = table?['Properties'] as List?;
          if (rows == null || rows.isEmpty) {
            error = 'PubChem returned no compound details.';
          } else {
            matches = rows
                .whereType<Map<String, dynamic>>()
                .where((row) => row['CID'] is int)
                .toList();
            if (matches.isEmpty) throw const FormatException('Missing CID');
          }
        case 400:
          error = 'PubChem could not read that search. Try a name or a numeric CID.';
        case 404:
          error = 'No compound found. Try another name or PubChem CID.';
        case 429:
        case 503:
          error = 'PubChem is busy. Wait a moment and try again.';
        default:
          error = 'PubChem is temporarily unavailable. Try again later.';
      }
    } on TimeoutException {
      error = 'The lookup timed out. Try again.';
    } on http.ClientException {
      error = 'Could not reach PubChem. Check your internet connection.';
    } on FormatException {
      error = 'PubChem returned an unreadable response. Try again.';
    } on TypeError {
      error = 'PubChem returned an unreadable response. Try again.';
    }
    if (!mounted) return;
    setState(() {
      _matches = error == null ? matches : const [];
      if (_matches.isNotEmpty) _selectCompound(_matches.first);
      _error = error;
      _loading = false;
    });
  }

  void _selectCompound(Map<String, dynamic> compound) {
    _compound = compound;
    _structure = _loadStructure(compound['CID'] as int);
    _aliases = null;
  }

  @override
  Widget build(BuildContext context) {
    final compound = _compound;
    return Scaffold(
      appBar: AppBar(title: const Text('PubChem Compound Lookup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _query,
              enabled: !_loading,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Compound name or PubChem CID',
                hintText: 'e.g. caffeine or 2519',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
            ),
            const Text(
              'Searches are sent to PubChem at the U.S. National Library of Medicine.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Search PubChem'),
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                semanticsLabel: 'Looking up compound',
              ),
            ],
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Semantics(liveRegion: true, child: Text(error)),
              ),
            if (compound != null) ...[
              const SizedBox(height: 16),
              if (_matches.length > 1) ...[
                const Text('PubChem returned multiple records for this name.'),
                DropdownButton<int>(
                  isExpanded: true,
                  value: compound['CID'] as int,
                  items: [
                    for (final record in _matches)
                      DropdownMenuItem(
                        value: record['CID'] as int,
                        child: Text(
                          "CID ${record['CID']} · ${record['Title'] ?? record['MolecularFormula'] ?? 'Compound'}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (cid) => setState(
                    () => _selectCompound(
                      _matches.firstWhere((record) => record['CID'] == cid),
                    ),
                  ),
                ),
              ],
              _result(context, compound),
            ],
          ],
        ),
      ),
    );
  }

  Widget _result(BuildContext context, Map<String, dynamic> compound) {
    final cid = compound['CID'] as int;
    final image = Uri.https(_host, '/rest/pug/compound/cid/$cid/PNG');
    return LiquidGlassContainer(
      borderRadius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            compound['Title']?.toString() ?? 'Compound $cid',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          FutureBuilder<String?>(
            future: _structure,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data case final svg?) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SvgPicture.string(
                    svg,
                    height: 190,
                    semanticsLabel:
                        'Two-dimensional structure from PubChem coordinates',
                  ),
                );
              }
              return Center(
                child: Image.network(
                  image.toString(),
                  width: 250,
                  height: 180,
                  fit: BoxFit.contain,
                  semanticLabel:
                      'Two-dimensional compound structure from PubChem',
                  errorBuilder: (_, _, _) =>
                      const Text('Structure image unavailable'),
                ),
              );
            },
          ),
          for (final (label, value) in <(String, Object?)>[
            ('PubChem CID', cid),
            ('Molecular formula', compound['MolecularFormula']),
            (
              'Molecular weight',
              compound['MolecularWeight'] == null
                  ? null
                  : "${compound['MolecularWeight']} g/mol",
            ),
            ('IUPAC name', compound['IUPACName']),
            ('SMILES', compound['SMILES']),
            ('InChIKey', compound['InChIKey']),
          ])
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText('$label · $value'),
              ),
          const SizedBox(height: 8),
          ExpansionTile(
            key: ValueKey(cid),
            tilePadding: EdgeInsets.zero,
            title: const Text('Other names and synonyms'),
            onExpansionChanged: (expanded) {
              if (expanded && _aliases == null) {
                setState(() => _aliases = _loadAliases(cid));
              }
            },
            children: [
              FutureBuilder<List<String>>(
                future: _aliases,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Synonyms are temporarily unavailable.');
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  if (snapshot.data!.isEmpty) {
                    return const Text(
                      'No synonyms were returned for this record.',
                    );
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final name in snapshot.data!)
                          Chip(label: Text(name)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PubChemConformerScreen(
                  cid: cid,
                  name: compound['Title']?.toString() ?? 'Compound $cid',
                  formula: compound['MolecularFormula']?.toString() ?? '',
                ),
              ),
            ),
            icon: const Icon(Icons.view_in_ar_outlined),
            label: const Text('View 3D conformer'),
          ),
          OutlinedButton.icon(
            onPressed: () => _openRecord(cid),
            icon: const Icon(Icons.open_in_new),
            label: const Text('View source record on PubChem'),
          ),
        ],
      ),
    );
  }

  Future<String?> _loadStructure(int cid) async {
    try {
      final response = await _client
          .get(
            Uri.https(_host, '/rest/pug/compound/cid/$cid/SDF', {
              'record_type': '2d',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return CompoundStructureSvg.fromMolfile(utf8.decode(response.bodyBytes));
    } on Exception {
      return null;
    }
  }

  Future<List<String>> _loadAliases(int cid) async {
    final response = await _client
        .get(Uri.https(_host, '/rest/pug/compound/cid/$cid/synonyms/JSON'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const FormatException('Synonyms unavailable');
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final rows =
        (json['InformationList'] as Map<String, dynamic>)['Information']
            as List;
    final names =
        ((rows.firstOrNull as Map<String, dynamic>?)?['Synonym'] as List? ??
                const [])
            .whereType<String>();
    final seen = <String>{};
    return names
        .where(
          (name) =>
              name.length <= 70 &&
              RegExp(r'[A-Za-z]').hasMatch(name) &&
              seen.add(name.toLowerCase()),
        )
        .take(16)
        .toList();
  }

  Future<void> _openRecord(int cid) async {
    final opened = await launchUrl(
      Uri.https(_host, '/compound/$cid'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the PubChem record.')),
      );
    }
  }
}
