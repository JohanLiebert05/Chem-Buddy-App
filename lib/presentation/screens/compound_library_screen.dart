import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/chemistry/compound_structure_svg.dart';
import '../../core/widgets/expressive_motion.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../data/services/chemical_name_database.dart';
import 'peptide_library_screen.dart';
import 'pubchem_conformer_screen.dart';
import 'pubchem_lookup_screen.dart';

class CompoundLibraryScreen extends StatefulWidget {
  const CompoundLibraryScreen({super.key});

  @override
  State<CompoundLibraryScreen> createState() => _CompoundLibraryScreenState();
}

class _CompoundLibraryScreenState extends State<CompoundLibraryScreen> {
  late final _structures = rootBundle
      .loadString('assets/chemistry/compound_structures.json')
      .then((data) => jsonDecode(data) as Map<String, dynamic>);
  final _query = TextEditingController();
  late final _compounds = [...ChemicalNameDatabase.curatedDatabase]
    ..sort(
      (a, b) =>
          a.commonName.toLowerCase().compareTo(b.commonName.toLowerCase()),
    );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _openPubChem(String query) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PubChemLookupScreen(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.text.trim().toLowerCase();
    final matches = _compounds
        .where(
          (compound) => [
            compound.commonName,
            compound.iupacName ?? '',
            compound.formula,
            ...compound.synonyms,
          ].any((name) => name.toLowerCase().contains(query)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Compound Names')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: LiquidGlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Compound reference',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Explore classroom chemicals, laboratory solvents, and research reagents.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Common name, synonym, or formula',
                        hintText: 'Aspirin, DMSO, or NaCl',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () => setState(_query.clear),
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SpringPress(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _openPubChem(_query.text.trim()),
                        icon: const Icon(Icons.public),
                        label: const Text('Search more compounds on PubChem'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PeptideLibraryScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Browse Peptide Structures'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _structures,
                builder: (context, snapshot) {
                  final structures = snapshot.data ?? const <String, dynamic>{};
                  if (matches.isEmpty) {
                    return const Center(
                      child: Text('No matching names in the offline library.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: matches.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${matches.length} compounds · offline reference',
                            style: theme.textTheme.labelLarge,
                          ),
                        );
                      }
                      final compound = matches[index - 1];
                      final record =
                          structures[compound.commonName]
                              as Map<String, dynamic>?;
                      return Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: Icon(
                            record == null
                                ? Icons.science_outlined
                                : Icons.polyline_rounded,
                          ),
                          title: Text(compound.commonName),
                          subtitle: Text(
                            [
                              ChemicalNameDatabase.formatFormula(
                                compound.formula,
                              ),
                              if (compound.synonyms.isNotEmpty)
                                compound.synonyms.first,
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showCompound(compound, record),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompound(ChemicalCompound compound, Map<String, dynamic>? record) {
    final cid = record?['cid'] as int?;
    final mol = record?['mol'] as String?;
    final svg = mol == null ? null : CompoundStructureSvg.fromMolfile(mol);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .84,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          children: [
            Text(
              compound.commonName,
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            LiquidGlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (svg != null) ...[
                    SvgPicture.string(
                      svg,
                      height: 210,
                      semanticsLabel: '2D structure of ${compound.commonName}',
                    ),
                    Text(
                      'PubChem CID $cid · 2D record representation',
                      style: Theme.of(sheetContext).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 10),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'An offline structure is unavailable for this compound.',
                      ),
                    ),
                  SelectableText(
                    '${ChemicalNameDatabase.formatFormula(compound.formula)} · '
                    '${compound.molarMass.toStringAsFixed(2)} g/mol',
                  ),
                  if (compound.iupacName case final systematic?)
                    SelectableText('Systematic name · $systematic'),
                ],
              ),
            ),
            if (compound.synonyms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Common names and aliases',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final alias in compound.synonyms)
                    Chip(label: Text(alias)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (cid != null)
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PubChemConformerScreen(
                        cid: cid,
                        name: compound.commonName,
                        formula: compound.formula,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.view_in_ar_outlined),
                label: const Text('View 3D conformer on PubChem'),
              ),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _openPubChem(cid?.toString() ?? compound.commonName);
              },
              icon: const Icon(Icons.public),
              label: const Text('Look up this compound on PubChem'),
            ),
          ],
        ),
      ),
    );
  }
}
