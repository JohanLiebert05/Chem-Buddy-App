import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum _TableView { families, electronegativity, state }

class PeriodicTablePanel extends StatefulWidget {
  const PeriodicTablePanel({super.key});

  @override
  State<PeriodicTablePanel> createState() => _PeriodicTablePanelState();
}

class _PeriodicTablePanelState extends State<PeriodicTablePanel> {
  late final _elements = _loadElements();
  final _scroll = ScrollController();
  _TableView _view = _TableView.families;
  String _query = '';
  String? _family;
  double _temperature = 298;

  static Future<List<_Element>> _loadElements() async {
    final json = await rootBundle.loadString(
      'assets/chemistry/periodic_elements.json',
    );
    return (jsonDecode(json) as List)
        .cast<Map<String, dynamic>>()
        .map(_Element.new)
        .toList();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_Element>>(
    future: _elements,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text('Could not load the element data.');
      }
      final elements = snapshot.data;
      if (elements == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final colors = Theme.of(context).colorScheme;
      final families = elements.map((e) => e.family).toSet().toList()..sort();
      final matches = elements.where(_matches).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Explore 118 elements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Element name, symbol, or atomic number',
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final (view, label) in [
                (_TableView.families, 'Families'),
                (_TableView.electronegativity, 'Electronegativity'),
                (_TableView.state, 'State at temperature'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _view == view,
                  onSelected: (_) => setState(() => _view = view),
                ),
            ],
          ),
          if (_view == _TableView.families)
            DropdownButton<String>(
              isExpanded: true,
              value: _family ?? '',
              items: [
                const DropdownMenuItem(value: '', child: Text('All families')),
                for (final family in families)
                  DropdownMenuItem(value: family, child: Text(family)),
              ],
              onChanged: (value) =>
                  setState(() => _family = value == '' ? null : value),
            ),
          if (_view == _TableView.electronegativity)
            const Text(
              'Pauling scale · tap an element for its value. Grey means no data.',
            ),
          if (_view == _TableView.state) ...[
            Text('${_temperature.round()} K · approximate states near 1 atm'),
            Slider(
              min: 0,
              max: 6000,
              value: _temperature,
              label: '${_temperature.round()} K',
              semanticFormatterCallback: (value) => '${value.round()} kelvin',
              onChanged: (value) =>
                  setState(() => _temperature = value.roundToDouble()),
            ),
            Wrap(
              spacing: 12,
              children: [
                for (final state in ['Solid', 'Liquid', 'Gas', 'Unknown'])
                  Chip(
                    avatar: Icon(
                      Icons.circle,
                      size: 14,
                      color: _stateColor(state, colors),
                    ),
                    label: Text(state),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (matches.isEmpty)
            const Text('No matching elements.')
          else if (_query.isNotEmpty)
            for (final element in matches)
              ListTile(
                leading: CircleAvatar(child: Text(element.symbol)),
                title: Text(element.name),
                subtitle: Text(
                  '${element.number} · ${_cellDescription(element)}',
                ),
                onTap: () => _showElement(element),
              )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tile = math.max(44.0, constraints.maxWidth / 18);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tile * 18 > constraints.maxWidth + 1)
                      const Text('Swipe sideways to explore all groups.'),
                    Scrollbar(
                      controller: _scroll,
                      thumbVisibility: tile * 18 > constraints.maxWidth + 1,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: tile * 18,
                          height: tile * 10,
                          child: Stack(
                            children: [
                              for (final element in matches)
                                Positioned(
                                  left: (element.column - 1) * tile,
                                  top: (element.row - 1) * tile,
                                  width: tile,
                                  height: tile,
                                  child: _cell(context, element),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 10),
          Wrap(
            children: [
              TextButton(
                onPressed: () => _open('https://periodic-table.rsc.org/'),
                child: const Text('Explore the RSC periodic table'),
              ),
              TextButton(
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: 'Periodic table data',
                  children: [
                    const Text(
                      'Selected fields adapted from Bowserinator’s Periodic-Table-JSON. '
                      'This data extract is licensed under CC BY-SA 3.0.',
                    ),
                    TextButton(
                      onPressed: () => _open(
                        'https://github.com/Bowserinator/Periodic-Table-JSON',
                      ),
                      child: const Text('Source dataset'),
                    ),
                    TextButton(
                      onPressed: () => _open(
                        'https://creativecommons.org/licenses/by-sa/3.0/',
                      ),
                      child: const Text('Data license'),
                    ),
                  ],
                ),
                child: const Text('Element data credits'),
              ),
            ],
          ),
        ],
      );
    },
  );

  bool _matches(_Element element) {
    if (_view == _TableView.families &&
        _family != null &&
        _family != element.family) {
      return false;
    }
    return element.name.toLowerCase().contains(_query) ||
        element.symbol.toLowerCase().startsWith(_query) ||
        element.number.toString() == _query;
  }

  String _cellDescription(_Element e) => switch (_view) {
    _TableView.families => e.family,
    _TableView.electronegativity =>
      e.electronegativity?.toString() ?? 'No electronegativity data',
    _TableView.state => e.stateAt(_temperature),
  };

  Color _stateColor(String state, ColorScheme colors) => switch (state) {
    'Solid' => colors.primaryContainer,
    'Liquid' => colors.secondaryContainer,
    'Gas' => colors.tertiaryContainer,
    _ => colors.surfaceContainerHighest,
  };

  Widget _cell(BuildContext context, _Element element) {
    final colors = Theme.of(context).colorScheme;
    final value = element.electronegativity;
    final background = switch (_view) {
      _TableView.families => switch (element.family) {
        'alkali metal' || 'alkaline earth metal' => colors.primaryContainer,
        'transition metal' ||
        'post-transition metal' => colors.secondaryContainer,
        'lanthanide' || 'actinide' => colors.tertiaryContainer,
        _ => colors.surfaceContainerHighest,
      },
      _TableView.electronegativity =>
        value == null
            ? colors.surfaceContainerHighest
            : Color.lerp(
                colors.primaryContainer,
                colors.primary,
                (value / 4).clamp(0.0, 1.0),
              )!,
      _TableView.state => _stateColor(element.stateAt(_temperature), colors),
    };
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: Tooltip(
          message: '${element.name} · ${_cellDescription(element)}',
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _showElement(element),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${element.number}',
                      style: TextStyle(color: foreground, fontSize: 10),
                    ),
                    Text(
                      element.symbol,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showElement(_Element element) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${element.number} · ${element.name} (${element.symbol})'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Family · ${element.family}'),
            Text('Period · ${element.period}     Block · ${element.block}'),
            if (element.row < 9) Text('Group · ${element.group}'),
            Text('Atomic mass · ${element.mass} u'),
            Text(
              'Electron configuration · ${element.configuration ?? 'Unavailable'}',
            ),
            Text(
              'Electronegativity · ${element.electronegativity ?? 'Unavailable'}',
            ),
            if (element.number != 6 && element.number != 33)
              Text(
                'Melting point · ${element.melt == null ? 'Unavailable' : '${element.melt} K'}',
              ),
            Text(
              'Boiling point · ${element.boil == null ? 'Unavailable' : '${element.boil} K'}',
            ),
            if (_view == _TableView.state)
              Text(
                'State at ${_temperature.round()} K · ${element.stateAt(_temperature)}',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  Future<void> _open(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }
}

class _Element {
  _Element(Map<String, dynamic> data)
    : number = data['number'] as int,
      name = data['name'] as String,
      symbol = data['symbol'] as String,
      family = data['category'] as String,
      group = data['group'] as int?,
      period = data['period'] as int,
      block = data['block'] as String,
      column = data['xpos'] as int,
      row = data['ypos'] as int,
      mass = data['atomic_mass'] as num,
      melt = data['melt'] as num?,
      boil = data['boil'] as num?,
      electronegativity = data['electronegativity_pauling'] as num?,
      configuration = data['electron_configuration_semantic'] as String?;

  final int number, period, column, row;
  final int? group;
  final String name, symbol, family, block;
  final num mass;
  final num? melt, boil, electronegativity;
  final String? configuration;

  String stateAt(double kelvin) {
    // Carbon and arsenic sublime at 1 atm. Helium's melting point
    // in the dataset is measured under pressure.
    if (number == 6 || number == 33 || number > 103) return 'Unknown';
    if (number == 2 && boil != null) return kelvin < boil! ? 'Liquid' : 'Gas';
    if (melt == null || boil == null || melt! >= boil!) return 'Unknown';
    if (kelvin >= boil!) return 'Gas';
    return kelvin >= melt! ? 'Liquid' : 'Solid';
  }
}
