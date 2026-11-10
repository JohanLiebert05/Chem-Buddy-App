import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VirtualLabsPanel extends StatelessWidget {
  const VirtualLabsPanel({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
    children: [
      Text('Virtual labs', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text(
        'Run a simulated procedure, record what you observe, and use the evidence to answer a question.',
      ),
      const SizedBox(height: 12),
      for (final lab in _Lab.values)
        Card(
          child: ListTile(
            leading: Icon(lab.icon),
            title: Text(lab.title),
            subtitle: Text(lab.summary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => _LabScreen(lab: lab)),
            ),
          ),
        ),
      const SizedBox(height: 12),
      TextButton.icon(
        icon: const Icon(Icons.open_in_new),
        label: const Text('Explore ChemCollective Virtual Labs'),
        onPressed: () async {
          final opened = await launchUrl(
            Uri.https('chemcollective.org', '/vlabs'),
            mode: LaunchMode.externalApplication,
          );
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open ChemCollective.')),
            );
          }
        },
      ),
    ],
  );
}

enum _Lab {
  dilution(
    'Make a glucose solution',
    'Prepare a target concentration from a stock solution.',
    Icons.water_drop_outlined,
  ),
  density(
    'Identify an unknown metal',
    'Measure mass and displaced volume to find the density.',
    Icons.scale_outlined,
  ),
  titration(
    'Find the acid concentration',
    'Use a virtual burette to locate the endpoint.',
    Icons.science_outlined,
  );

  const _Lab(this.title, this.summary, this.icon);
  final String title, summary;
  final IconData icon;
}

class _LabScreen extends StatefulWidget {
  const _LabScreen({required this.lab});
  final _Lab lab;

  @override
  State<_LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<_LabScreen> {
  double _stockMl = 0;
  double? _concentration;
  bool _measuredMass = false;
  bool _measuredVolume = false;
  String? _metal;
  int _baseMl = 0;
  String? _feedback;

  void _reset() => setState(() {
    _stockMl = 0;
    _concentration = null;
    _measuredMass = false;
    _measuredVolume = false;
    _metal = null;
    _baseMl = 0;
    _feedback = null;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.lab.title),
      actions: [
        IconButton(
          tooltip: 'Reset lab',
          icon: const Icon(Icons.restart_alt),
          onPressed: _reset,
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Simulation', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          ...switch (widget.lab) {
            _Lab.dilution => _dilution(),
            _Lab.density => _density(),
            _Lab.titration => _titration(),
          },
          if (_feedback case final feedback?)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(liveRegion: true, child: Text(feedback)),
              ),
            ),
        ],
      ),
    ),
  );

  List<Widget> _dilution() => [
    const Text(
      'Prepare 100 mL of 0.050 mol/L glucose from a 0.50 mol/L stock. Predict how much stock you need, then try it.',
    ),
    const SizedBox(height: 12),
    Text('Stock solution · ${_stockMl.round()} mL'),
    Slider(
      value: _stockMl,
      max: 100,
      divisions: 100,
      label: '${_stockMl.round()} mL',
      semanticFormatterCallback: (value) =>
          '${value.round()} millilitres of stock',
      onChanged: (value) => setState(() {
        _stockMl = value;
        _concentration = null;
        _feedback = null;
      }),
    ),
    FilledButton(
      onPressed: () => setState(() {
        _concentration = 0.50 * _stockMl / 100;
        _feedback = _stockMl == 10
            ? 'Target reached. The moles of glucose stay constant during dilution. '
                  'C₁V₁ = C₂V₂ gives 0.050 × 100 ÷ 0.50 = 10 mL of stock.'
            : 'Target is 0.050 mol/L. '
                  '${_stockMl < 10 ? 'Use more stock.' : 'Use less stock.'} '
                  'The final volume stays at 100 mL.';
      }),
      child: const Text('Top up to 100 mL and mix'),
    ),
    if (_concentration case final concentration?)
      Text(
        'Measured concentration · ${concentration.toStringAsFixed(3)} mol/L',
      ),
  ];

  List<Widget> _density() => [
    const Text(
      'A metal sample has lost its label. Use the balance and the measuring cylinder, then match your calculated density to the reference values.',
    ),
    const SizedBox(height: 12),
    OutlinedButton(
      onPressed: _measuredMass
          ? null
          : () => setState(() => _measuredMass = true),
      child: const Text('Measure mass on the balance'),
    ),
    if (_measuredMass) const Text('Balance reading · 27.0 g'),
    OutlinedButton(
      onPressed: _measuredVolume
          ? null
          : () => setState(() => _measuredVolume = true),
      child: const Text('Lower the sample into the cylinder'),
    ),
    if (_measuredVolume)
      const Text('Water level · 40.0 mL before, 50.0 mL after'),
    if (_measuredMass && _measuredVolume) ...[
      const SizedBox(height: 12),
      const Text('Which metal matches your calculated density?'),
      for (final (metal, density) in [
        ('Aluminium', '2.70'),
        ('Iron', '7.87'),
        ('Copper', '8.96'),
      ])
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ChoiceChip(
            label: Text('$metal · $density g/cm³'),
            selected: _metal == metal,
            onSelected: (_) => setState(() {
              _metal = metal;
              _feedback = metal == 'Aluminium'
                  ? 'Correct. The sample displaced 10.0 mL, so its density is '
                        '27.0 ÷ 10.0 = 2.70 g/cm³, which matches aluminium.'
                  : 'Try again. Subtract the starting water level from the final '
                        'level to get the sample volume, then divide mass by volume.';
            }),
          ),
        ),
    ],
  ];

  List<Widget> _titration() {
    final endpoint = _baseMl == 20;
    final indicator = _baseMl < 20 ? 'Yellow' : (endpoint ? 'Green' : 'Blue');
    return [
      const Text(
        'Titrate 25.0 mL of hydrochloric acid with 0.100 mol/L sodium hydroxide. Stop when the simulated indicator first turns green.',
      ),
      const SizedBox(height: 12),
      Text('NaOH added · ${_baseMl.toStringAsFixed(1)} mL'),
      Text('Indicator · $indicator'),
      Wrap(
        spacing: 8,
        children: [
          for (final amount in [1, 5])
            OutlinedButton(
              onPressed: _baseMl + amount > 30
                  ? null
                  : () => setState(() {
                      _baseMl += amount;
                      _feedback = _baseMl > 20
                          ? 'You passed the endpoint. Reset and add smaller amounts as you approach it.'
                          : null;
                    }),
              child: Text('Add $amount mL'),
            ),
        ],
      ),
      if (endpoint) ...[
        const SizedBox(height: 12),
        const Text(
          'You reached the endpoint. What was the concentration of the acid?',
        ),
        for (final answer in ['0.050', '0.080', '0.125'])
          OutlinedButton(
            onPressed: () => setState(() {
              _feedback = answer == '0.080'
                  ? 'Correct. HCl and NaOH react in a 1:1 ratio. '
                        'The acid concentration is 0.100 × 20.0 ÷ 25.0 = 0.080 mol/L.'
                  : 'Try again. Calculate the moles of NaOH added, then divide by '
                        'the original acid volume in litres.';
            }),
            child: Text('$answer mol/L'),
          ),
      ],
    ];
  }
}
