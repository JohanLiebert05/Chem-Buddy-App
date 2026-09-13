import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/inorganic_spectroscopy_service.dart';
import '../../data/services/spectroscopy_service.dart';
import 'chem_sketcher_screen.dart';

class SpectroscopyHubScreen extends ConsumerStatefulWidget {
  const SpectroscopyHubScreen({super.key});

  @override
  ConsumerState<SpectroscopyHubScreen> createState() => _SpectroscopyHubScreenState();
}

class _SpectroscopyHubScreenState extends ConsumerState<SpectroscopyHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _formulaCtrl = TextEditingController(text: 'C8H8O');
  final TextEditingController _irPeaksCtrl = TextEditingController(text: '1685, 1600, 1450, 3050');
  final TextEditingController _nmrPeaksCtrl = TextEditingController(text: '2.6, 7.5, 7.9');
  final TextEditingController _msPeaksCtrl = TextEditingController(text: '120, 105, 77');

  SpectroscopyAnalysisResult? _analysisResult;
  bool _showFullReport = false;

  // Inorganic Spectroscopy Calculation State
  int _selectedInorganicCategory = 0;
  final TextEditingController _nu1Ctrl = TextEditingController(text: '8500');
  final TextEditingController _nu2Ctrl = TextEditingController(text: '13800');
  final TextEditingController _nu3Ctrl = TextEditingController(text: '25300');
  final TextEditingController _b0Ctrl = TextEditingController(text: '1030');

  int _magDElectrons = 8;
  bool _magIsHighSpin = true;
  final TextEditingController _magLambdaCtrl = TextEditingController(text: '-315');
  final TextEditingController _mag10DqCtrl = TextEditingController(text: '8500');

  final TextEditingController _eprFreqCtrl = TextEditingController(text: '9.45');
  final TextEditingController _eprFieldCtrl = TextEditingController(text: '3246');
  int _eprNuclearSpinDouble = 3; // I = 3/2 (63Cu)
  int _eprLigandCount = 2; // 2x 14N (I = 1)

  final TextEditingController _mossIsomerCtrl = TextEditingController(text: '1.25');
  final TextEditingController _mossQuadCtrl = TextEditingController(text: '2.70');

  String _carbonylSelectedType = 'cis-M(CO)4L2';

  String? _currentInorganicDerivation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _runAnalysis();
    _runInorganicCalculation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _formulaCtrl.dispose();
    _irPeaksCtrl.dispose();
    _nmrPeaksCtrl.dispose();
    _msPeaksCtrl.dispose();
    _nu1Ctrl.dispose();
    _nu2Ctrl.dispose();
    _nu3Ctrl.dispose();
    _b0Ctrl.dispose();
    _magLambdaCtrl.dispose();
    _mag10DqCtrl.dispose();
    _eprFreqCtrl.dispose();
    _eprFieldCtrl.dispose();
    _mossIsomerCtrl.dispose();
    _mossQuadCtrl.dispose();
    super.dispose();
  }

  void _runInorganicCalculation() {
    AppHaptics.selection();
    String derivation = '';

    switch (_selectedInorganicCategory) {
      case 0: // Tanabe-Sugano & Racah
        final n1 = double.tryParse(_nu1Ctrl.text.trim()) ?? 8500.0;
        final n2 = double.tryParse(_nu2Ctrl.text.trim()) ?? 13800.0;
        final n3 = double.tryParse(_nu3Ctrl.text.trim()) ?? 25300.0;
        final b0 = double.tryParse(_b0Ctrl.text.trim()) ?? 1030.0;
        final res = InorganicSpectroscopyService.calculateRacahOctahedralD8(
          nu1: n1,
          nu2: n2,
          nu3: n3,
          b0: b0,
        );
        derivation = res.derivationKaTeX;
        break;
      case 1: // Magnetic Moment
        final lam = double.tryParse(_magLambdaCtrl.text.trim()) ?? -315.0;
        final dq = double.tryParse(_mag10DqCtrl.text.trim()) ?? 8500.0;
        final res = InorganicSpectroscopyService.calculateMagneticMoment(
          dElectrons: _magDElectrons,
          geometry: 'Oh',
          isHighSpin: _magIsHighSpin,
          lambda: lam,
          tenDq: dq,
        );
        derivation = res.derivationKaTeX;
        break;
      case 2: // EPR / ESR
        final freq = double.tryParse(_eprFreqCtrl.text.trim()) ?? 9.45;
        final field = double.tryParse(_eprFieldCtrl.text.trim()) ?? 3246.0;
        final res = InorganicSpectroscopyService.calculateEprGFactor(
          frequencyGhz: freq,
          magneticFieldGauss: field,
          nuclearSpinDouble: _eprNuclearSpinDouble,
          numberOfCoupledNuclei: 1,
          superHyperfineSpinDouble: 2, // 14N I=1
          numberOfLigands: _eprLigandCount,
        );
        derivation = res.derivationKaTeX;
        break;
      case 3: // Mössbauer
        final iso = double.tryParse(_mossIsomerCtrl.text.trim()) ?? 1.25;
        final quad = double.tryParse(_mossQuadCtrl.text.trim()) ?? 2.70;
        final res = InorganicSpectroscopyService.diagnoseMossbauerFe(
          isomerShift: iso,
          quadrupoleSplitting: quad,
        );
        derivation = res.derivationKaTeX;
        break;
      case 4: // Metal Carbonyls IR
        final res = InorganicSpectroscopyService.predictCarbonylIrModes(
          complexType: _carbonylSelectedType,
        );
        derivation = res.derivationKaTeX;
        break;
      default:
        derivation = '';
    }

    setState(() {
      _currentInorganicDerivation = derivation;
    });
  }

  void _runAnalysis() {
    AppHaptics.selection();
    final irList = _irPeaksCtrl.text
        .split(RegExp(r'[,;\s]+'))
        .map((s) => double.tryParse(s.trim()))
        .whereType<double>()
        .toList();
    final nmrList = _nmrPeaksCtrl.text
        .split(RegExp(r'[,;\s]+'))
        .map((s) => double.tryParse(s.trim()))
        .whereType<double>()
        .toList();
    final msList = _msPeaksCtrl.text
        .split(RegExp(r'[,;\s]+'))
        .map((s) => double.tryParse(s.trim()))
        .whereType<double>()
        .toList();

    setState(() {
      _analysisResult = SpectroscopyService.analyzeSpectraStructured(
        formula: _formulaCtrl.text,
        irPeaks: irList,
        nmrPeaks: nmrList,
        msPeaks: msList,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: AppColors.brandBright, size: 22),
              SizedBox(width: 8),
              Text(
                'Spectroscopy Hub',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.draw_outlined, color: AppColors.accentCyan, size: 22),
              tooltip: 'Mobile ChemDraw Canvas',
              onPressed: () {
                AppHaptics.selection();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChemSketcherScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.brandBright,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: '¹H / ¹³C NMR'),
              Tab(text: 'FT-IR Frequencies'),
              Tab(text: 'Mass Spec'),
              Tab(text: 'Structure Solver'),
              Tab(text: 'Inorganic 10M ⚗️'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNmrTab(),
            _buildIrTab(),
            _buildMsTab(),
            _buildSolverTab(),
            _buildInorganicTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNmrTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '¹H NMR Chemical Shift Diagnostic Table (δ ppm)',
          style: TextStyle(color: AppColors.brandBright, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...SpectroscopyService.protonNmrRegions.map((region) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      region.range,
                      style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('¹H NMR', style: TextStyle(color: AppColors.brandBright, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(region.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(region.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        )),
        const SizedBox(height: 20),
        const Text(
          '¹³C NMR Chemical Shift Diagnostic Table (δ ppm)',
          style: TextStyle(color: AppColors.brandBright, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...SpectroscopyService.carbonNmrRegions.map((region) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      region.range,
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('¹³C NMR', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(region.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(region.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildIrTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'FT-IR Diagnostic Absorption Bands (cm⁻¹)',
          style: TextStyle(color: AppColors.brandBright, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...SpectroscopyService.irCharacteristicBands.map((band) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      band.range,
                      style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Text(
                      band.intensity,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(band.group, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(band.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildMsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Mass Spectrometry Halogen Signatures & Rearrangements',
          style: TextStyle(color: AppColors.brandBright, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...SpectroscopyService.massSpecPatterns.map((pat) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pat.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pat.ratio,
                        style: const TextStyle(color: AppColors.statusDanger, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(pat.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSolverTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlowCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.brandBright.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.brandBright, size: 18),
                  SizedBox(width: 8),
                  Text('Structure Deduction Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              _buildInput('Molecular Formula (e.g. C8H8O, C9H11NO2)', _formulaCtrl),
              const SizedBox(height: 10),
              _buildInput('FT-IR Peaks in cm⁻¹ (comma-separated)', _irPeaksCtrl),
              const SizedBox(height: 10),
              _buildInput('¹H NMR Shifts in ppm (comma-separated)', _nmrPeaksCtrl),
              const SizedBox(height: 10),
              _buildInput('Mass Spec m/z Peaks (comma-separated)', _msPeaksCtrl),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _runAnalysis,
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Analyze Spectra & Deduce Structure', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCyan,
                    side: const BorderSide(color: AppColors.accentCyan),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    AppHaptics.selection();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChemSketcherScreen()),
                    );
                  },
                  icon: const Icon(Icons.gesture_rounded, size: 16),
                  label: const Text('Draw Structure in Mobile ChemDraw Canvas ✏️', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_analysisResult != null) ...[
          if (!_analysisResult!.isValid)
            AppCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppColors.statusDanger.withValues(alpha: 0.6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.statusDanger, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Formula Validation Error',
                          style: TextStyle(color: AppColors.statusDanger, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _analysisResult!.errorMessage ?? 'Invalid formula',
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Deduction Header Card
            GlowCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderColor: AppColors.brandBright.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: AppColors.accentCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _analysisResult!.formula,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'DBE = ${_analysisResult!.dbe.toStringAsFixed(1).replaceAll('.0', '')}',
                              style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w800, fontSize: 11.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_analysisResult!.molarMass} g/mol',
                              style: const TextStyle(color: AppColors.brandBright, fontWeight: FontWeight.w800, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '8-Step Spectroscopy Interpretation',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      InkWell(
                        onTap: () {
                          AppHaptics.selection();
                          setState(() => _showFullReport = !_showFullReport);
                        },
                        child: Row(
                          children: [
                            Icon(
                              _showFullReport ? Icons.view_agenda_outlined : Icons.description_outlined,
                              size: 14,
                              color: AppColors.brandBright,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showFullReport ? 'Step View' : 'Full Report',
                              style: const TextStyle(color: AppColors.brandBright, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_analysisResult!.sanityReport != null)
              _buildSanityChecksCard(_analysisResult!.sanityReport!),
            if (_showFullReport)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: ChemistryMarkdownView(
                  text: _analysisResult!.markdownFull,
                  textStyle: const TextStyle(fontSize: 13, height: 1.45, color: Colors.white),
                ),
              )
            else
              ..._analysisResult!.steps.map((step) => _buildDeductionStepCard(step)),
          ],
        ],
        const SizedBox(height: 24),
        const Text(
          'Curated MSc Examination Case Studies',
          style: TextStyle(color: AppColors.brandBright, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...SpectroscopyService.caseStudies.map((study) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      study.compoundName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      'DBE = ${study.dbe.toInt()}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.accentGold),
                    ),
                  ],
                ),
                Text('Formula: ${study.formula} • Molar Mass: ${study.molarMass} g/mol', style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                const Divider(color: AppColors.borderSubtle, height: 18),
                Text('FT-IR: ${study.irHighlights}', style: const TextStyle(fontSize: 12, color: AppColors.accentCyan)),
                const SizedBox(height: 4),
                Text('¹H NMR: ${study.nmr1H}', style: const TextStyle(fontSize: 12, color: AppColors.brandBright)),
                const SizedBox(height: 4),
                Text('¹³C NMR: ${study.nmr13C}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Mass Spec: ${study.massSpec}', style: const TextStyle(fontSize: 12, color: AppColors.statusDanger)),
                const SizedBox(height: 10),
                ExpansionTile(
                  title: const Text('View Step-by-Step Structural Deduction', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.statusSuccess)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(study.deduction, style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildInput(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.bg2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSubtle)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brandBright)),
      ),
    );
  }

  Widget _buildSanityChecksCard(SpectroscopySanityReport report) {
    final hasIssues = report.hasViolations || report.warningCount > 0;
    final borderColor = report.hasViolations
        ? AppColors.statusDanger.withValues(alpha: 0.6)
        : (report.warningCount > 0
            ? AppColors.accentGold.withValues(alpha: 0.6)
            : AppColors.statusSuccess.withValues(alpha: 0.5));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowCard(
        padding: EdgeInsets.zero,
        borderColor: borderColor,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: hasIssues,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (report.hasViolations
                    ? AppColors.statusDanger
                    : (report.warningCount > 0 ? AppColors.accentGold : AppColors.statusSuccess)).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                report.hasViolations
                    ? Icons.gpp_bad_rounded
                    : (report.warningCount > 0 ? Icons.gpp_maybe_rounded : Icons.gpp_good_rounded),
                color: report.hasViolations
                    ? AppColors.statusDanger
                    : (report.warningCount > 0 ? AppColors.accentGold : AppColors.statusSuccess),
                size: 22,
              ),
            ),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Spectral Sanity Checks 🛡️',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                  ),
                ),
                if (report.violationCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusDanger.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusDanger.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${report.violationCount} Violations',
                      style: const TextStyle(color: AppColors.statusDanger, fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                if (report.warningCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${report.warningCount} Warnings',
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${report.passedCount} Passed',
                    style: const TextStyle(color: AppColors.statusSuccess, fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                hasIssues
                    ? 'Cross-spectral inconsistencies or valence violations detected'
                    : 'All rule-based chemical valence and spectroscopic checks verified',
                style: TextStyle(
                  color: hasIssues ? AppColors.accentGold : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: report.items.map((item) {
                    final itemColor = item.passed
                        ? AppColors.statusSuccess
                        : (item.severity == SanitySeverity.violation
                            ? AppColors.statusDanger
                            : AppColors.accentGold);
                    final itemIcon = item.passed
                        ? Icons.check_circle_outline_rounded
                        : (item.severity == SanitySeverity.violation
                            ? Icons.error_outline_rounded
                            : Icons.warning_amber_rounded);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg0,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: itemColor.withValues(alpha: item.passed ? 0.2 : 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(itemIcon, color: itemColor, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: itemColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.bg2,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.message,
                            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                          ),
                          if (!item.passed) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: itemColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline, color: itemColor, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Recommendation: ${item.recommendation}',
                                      style: TextStyle(color: itemColor, fontSize: 11.5, height: 1.3, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeductionStepCard(DeductionStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: step.stepNumber == 1 || step.stepNumber == 7,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(step.icon, color: AppColors.brandBright, size: 20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Step ${step.stepNumber}',
                    style: const TextStyle(color: AppColors.accentCyan, fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                step.summary,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ChemistryMarkdownView(
                  text: step.content,
                  textStyle: const TextStyle(fontSize: 12.5, height: 1.45, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInorganicTab() {
    final categories = [
      {'title': 'Tanabe-Sugano & Racah', 'icon': Icons.auto_awesome},
      {'title': 'Magnetic Moments', 'icon': Icons.toll_outlined},
      {'title': 'EPR / ESR g-Factor', 'icon': Icons.graphic_eq_rounded},
      {'title': '⁵⁷Fe Mössbauer', 'icon': Icons.science_outlined},
      {'title': 'Carbonyls IR Modes', 'icon': Icons.straighten_rounded},
      {'title': '10-Mark Exam Papers', 'icon': Icons.menu_book_outlined},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(categories.length, (idx) {
              final cat = categories[idx];
              final isSelected = _selectedInorganicCategory == idx;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(
                    cat['icon'] as IconData,
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                  label: Text(
                    cat['title'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.brandPrimary,
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (val) {
                    if (val) {
                      AppHaptics.selection();
                      setState(() {
                        _selectedInorganicCategory = idx;
                      });
                      _runInorganicCalculation();
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        if (_selectedInorganicCategory == 5) ...[
          const Text(
            'Curated 10-Mark Postgraduate Exam Solutions',
            style: TextStyle(color: AppColors.brandBright, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...InorganicSpectroscopyService.curated10MarkProblems.map((prob) => _build10MarkProblemCard(prob)),
        ] else ...[
          GlowCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.brandBright.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categories[_selectedInorganicCategory]['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('10-Mark Calculator', style: TextStyle(color: AppColors.accentCyan, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInorganicActiveInputs(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _runInorganicCalculation,
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: const Text('Derive 10-Mark University Model Answer', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_currentInorganicDerivation != null)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: ChemistryMarkdownView(
                text: _currentInorganicDerivation!,
                textStyle: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInorganicActiveInputs() {
    switch (_selectedInorganicCategory) {
      case 0:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInput('ν₁ band (cm⁻¹)', _nu1Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: _buildInput('ν₂ band (cm⁻¹)', _nu2Ctrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildInput('ν₃ band (cm⁻¹)', _nu3Ctrl)),
                const SizedBox(width: 8),
                Expanded(child: _buildInput('Free-ion B₀ (cm⁻¹)', _b0Ctrl)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ActionChip(
                  label: const Text('[Ni(H₂O)₆]²⁺', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _nu1Ctrl.text = '8500';
                      _nu2Ctrl.text = '13800';
                      _nu3Ctrl.text = '25300';
                      _b0Ctrl.text = '1030';
                    });
                    _runInorganicCalculation();
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('[Cr(H₂O)₆]³⁺', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _nu1Ctrl.text = '17400';
                      _nu2Ctrl.text = '24600';
                      _nu3Ctrl.text = '37800';
                      _b0Ctrl.text = '918';
                    });
                    _runInorganicCalculation();
                  },
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('d-Electrons Count', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        initialValue: _magDElectrons,
                        dropdownColor: const Color(0xFF1E293B),
                        items: List.generate(9, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('d$d', style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _magDElectrons = val);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spin State', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<bool>(
                        initialValue: _magIsHighSpin,
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(value: true, child: Text('High Spin', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: false, child: Text('Low Spin', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _magIsHighSpin = val);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildInput('λ constant (cm⁻¹)', _magLambdaCtrl)),
                const SizedBox(width: 8),
                Expanded(child: _buildInput('10Dq (cm⁻¹)', _mag10DqCtrl)),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInput('Frequency ν (GHz)', _eprFreqCtrl)),
                const SizedBox(width: 8),
                Expanded(child: _buildInput('Magnetic Field B (Gauss)', _eprFieldCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Metal Spin (2×I)', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        initialValue: _eprNuclearSpinDouble,
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('I = 1/2', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 2, child: Text('I = 1 (¹⁴N)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 3, child: Text('I = 3/2 (⁶³Cu)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 5, child: Text('I = 5/2 (⁵⁵Mn)', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 7, child: Text('I = 7/2 (⁵¹V)', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _eprNuclearSpinDouble = val);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Coupled Ligands (¹⁴N)', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        initialValue: _eprLigandCount,
                        dropdownColor: const Color(0xFF1E293B),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('0 Ligands', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 2, child: Text('2 Ligands', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 4, child: Text('4 Ligands', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _eprLigandCount = val);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInput('Isomer Shift δ (mm/s)', _mossIsomerCtrl)),
                const SizedBox(width: 8),
                Expanded(child: _buildInput('Quadrupole Splitting ΔEQ (mm/s)', _mossQuadCtrl)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ActionChip(
                  label: const Text('Fe(II) High-Spin', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _mossIsomerCtrl.text = '1.25';
                      _mossQuadCtrl.text = '2.70';
                    });
                    _runInorganicCalculation();
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Fe(III) High-Spin', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _mossIsomerCtrl.text = '0.70';
                      _mossQuadCtrl.text = '0.30';
                    });
                    _runInorganicCalculation();
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Nitroprusside', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _mossIsomerCtrl.text = '-0.16';
                      _mossQuadCtrl.text = '1.72';
                    });
                    _runInorganicCalculation();
                  },
                ),
              ],
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metal Carbonyl Geometry / Isomer', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _carbonylSelectedType,
              dropdownColor: const Color(0xFF1E293B),
              items: const [
                DropdownMenuItem(value: 'M(CO)6', child: Text('M(CO)₆ (Octahedral, Oh)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'M(CO)5L', child: Text('M(CO)₅L (C₄ᵥ)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'trans-M(CO)4L2', child: Text('trans-M(CO)₄L₂ (D₄ₕ)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'cis-M(CO)4L2', child: Text('cis-M(CO)₄L₂ (C₂ᵥ)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'fac-M(CO)3L3', child: Text('fac-M(CO)₃L₃ (C₃ᵥ)', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'mer-M(CO)3L3', child: Text('mer-M(CO)₃L₃ (C₂ᵥ)', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _carbonylSelectedType = val);
                  _runInorganicCalculation();
                }
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _build10MarkProblemCard(Inorganic10MarkExamProblem prob) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(14),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_outlined, color: AppColors.brandBright, size: 20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    prob.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('10 Marks', style: TextStyle(color: AppColors.accentGold, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${prob.universityExam} • ${prob.topic}',
                style: const TextStyle(color: AppColors.accentCyan, fontSize: 11),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Examination Problem Statement:', style: TextStyle(color: AppColors.brandBright, fontWeight: FontWeight.w700, fontSize: 11.5)),
                          const SizedBox(height: 4),
                          Text(prob.problemStatement, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Official Marking Rubric Breakdown:', style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    ...prob.rubricMarkDistribution.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${e.key}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                          Text('${e.value} Marks', style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w700, fontSize: 11.5)),
                        ],
                      ),
                    )),
                    const Divider(color: AppColors.borderSubtle, height: 18),
                    ChemistryMarkdownView(
                      text: prob.fullKaTeXSolution,
                      textStyle: const TextStyle(fontSize: 12.5, height: 1.45, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.statusSuccess.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.statusSuccess, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Key Examination Takeaway: ${prob.takeawayPoints}',
                              style: const TextStyle(color: AppColors.statusSuccess, fontSize: 11.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
