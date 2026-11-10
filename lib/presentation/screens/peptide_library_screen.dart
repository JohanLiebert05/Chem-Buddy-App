import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/chemistry/compound_conformer.dart';
import '../../core/chemistry/compound_structure_svg.dart';
import '../../core/widgets/expressive_motion.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/molecule_3d/molecule_3d_viewer.dart';
import '../../data/models/peptide_reference.dart';
import '../../data/services/chemical_name_database.dart';
import 'pubchem_lookup_screen.dart';

class PeptideLibraryScreen extends StatefulWidget {
  const PeptideLibraryScreen({super.key});

  @override
  State<PeptideLibraryScreen> createState() => _PeptideLibraryScreenState();
}

class _PeptideLibraryScreenState extends State<PeptideLibraryScreen> {
  late final _catalog = PeptideReference.load();
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Peptide Structures')),
    body: SafeArea(
      child: FutureBuilder<List<PeptideReference>>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'The offline peptide collection could not be loaded.',
              ),
            );
          }
          final peptides = snapshot.data;
          if (peptides == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = peptides
              .where((peptide) => peptide.matches(_query))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              LiquidGlassContainer(
                borderRadius: 28,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Common peptide names',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Compare 2D diagrams and rotatable 3D conformers. The curated collection works offline.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        labelText: 'Name, alias, sequence or CID',
                        hintText: 'GSH, carnosine, or Gly–Gly',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${matches.length} peptides',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              if (matches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No matches in the offline collection.'),
                ),
              for (final peptide in matches)
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.hub_outlined),
                    title: Text(peptide.name),
                    subtitle: Text(peptide.sequence),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _PeptideDetail(peptide: peptide),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SpringPress(
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PubChemLookupScreen(initialQuery: _query.trim()),
                    ),
                  ),
                  icon: const Icon(Icons.public),
                  label: const Text('Search more compounds on PubChem'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _PeptideDetail extends StatefulWidget {
  const _PeptideDetail({required this.peptide});

  final PeptideReference peptide;

  @override
  State<_PeptideDetail> createState() => _PeptideDetailState();
}

class _PeptideDetailState extends State<_PeptideDetail> {
  bool _show3d = false;
  late final _svg = CompoundStructureSvg.fromMolfile(widget.peptide.mol2d);
  late final _conformer = CompoundConformer.fromMolfile(
    widget.peptide.mol3d,
    id: 'pubchem-${widget.peptide.cid}',
    name: widget.peptide.name,
    formula: widget.peptide.formula,
  );

  @override
  Widget build(BuildContext context) {
    final peptide = widget.peptide;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(peptide.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            LiquidGlassContainer(
              borderRadius: 28,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(peptide.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  SelectableText(
                    peptide.sequence,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(peptide.description),
                  const SizedBox(height: 8),
                  SelectableText(
                    '${ChemicalNameDatabase.formatFormula(peptide.formula)} · '
                    '${peptide.mass.toStringAsFixed(2)} g/mol',
                  ),
                  if (peptide.aliases.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final alias in peptide.aliases)
                          Chip(label: Text(alias)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('2D diagram'),
                  icon: Icon(Icons.polyline_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('3D conformer'),
                  icon: Icon(Icons.view_in_ar_outlined),
                ),
              ],
              selected: {_show3d},
              onSelectionChanged: (value) =>
                  setState(() => _show3d = value.single),
            ),
            const SizedBox(height: 12),
            if (_show3d)
              if (_conformer case final conformer?)
                Molecule3DViewer(molecule: conformer, showLabelsInitial: false)
              else
                const Text('The bundled 3D conformer could not be opened.')
            else if (_svg case final svg?)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 360 / 210,
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: SvgPicture.string(
                      svg,
                      semanticsLabel: '2D structure of ${peptide.name}',
                    ),
                  ),
                ),
              )
            else
              const Text('The bundled 2D diagram could not be opened.'),
            const SizedBox(height: 8),
            Text(
              _show3d
                  ? peptide.source3dLabel
                  : 'PubChem 2D coordinates · pinching zooms the diagram',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openSource(
                Uri.https(
                  'pubchem.ncbi.nlm.nih.gov',
                  '/compound/${peptide.cid}',
                ),
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text('View PubChem CID ${peptide.cid}'),
            ),
            if (peptide.source3dUri case final uri?)
              TextButton.icon(
                onPressed: () => _openSource(uri),
                icon: const Icon(Icons.open_in_new),
                label: const Text('View RCSB 3D source'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSource(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the source record.')),
      );
    }
  }
}
