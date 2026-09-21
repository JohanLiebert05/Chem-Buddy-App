import 'dart:math' as math;
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

  // Structure Solver Controllers
  final TextEditingController _formulaCtrl = TextEditingController(text: 'C8H8O');
  final TextEditingController _irPeaksCtrl = TextEditingController(text: '1685, 1600, 1450, 3050');
  final TextEditingController _nmr1HPeaksCtrl = TextEditingController(text: '2.60, 7.50, 7.95');
  final TextEditingController _nmr13CPeaksCtrl = TextEditingController(text: '26.6, 128.3, 128.6, 133.1, 137.1, 198.1');
  final TextEditingController _msPeaksCtrl = TextEditingController(text: '120, 105, 77');


  SpectroscopyAnalysisResult? _analysisResult;
  bool _showFullReport = false;

  // Chromatograms & Spectrograms Tab State
  String _selectedTechniqueCategory = 'All';
  int _selectedTechniqueIndex = 0;
  SpectralPeakAnnotation? _selectedPeak;

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
    _tabController = TabController(length: 6, vsync: this);
    _runAnalysis();
    _runInorganicCalculation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _formulaCtrl.dispose();
    _irPeaksCtrl.dispose();
    _nmr1HPeaksCtrl.dispose();
    _nmr13CPeaksCtrl.dispose();
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
    final hList = _nmr1HPeaksCtrl.text
        .split(RegExp(r'[,;\s]+'))
        .map((s) => double.tryParse(s.trim()))
        .whereType<double>()
        .toList();
    final cList = _nmr13CPeaksCtrl.text
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
        nmr1HPeaks: hList,
        nmr13CPeaks: cList,
        msPeaks: msList,
      );
    });
  }

  void _loadPreset(SpectroscopyCaseStudy study) {
    AppHaptics.selection();
    _formulaCtrl.text = study.formula;
    _irPeaksCtrl.text = study.irHighlights;
    _nmr1HPeaksCtrl.text = study.nmr1H;
    _nmr13CPeaksCtrl.text = study.nmr13C;
    _msPeaksCtrl.text = study.massSpec;
    _runAnalysis();
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
              Tab(text: 'Structure Solver'),
              Tab(text: 'Chromatograms & Spectrograms 📊'),
              Tab(text: '¹H / ¹³C NMR'),
              Tab(text: 'FT-IR Frequencies'),
              Tab(text: 'Mass Spec'),
              Tab(text: 'Inorganic 10M ⚗️'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSolverTab(),
            _buildChromatogramsTab(),
            _buildNmrTab(),
            _buildIrTab(),
            _buildMsTab(),
            _buildInorganicTab(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // 1. Structure Solver Tab (Upgraded with dedicated 1H & 13C)
  // ----------------------------------------------------
  Widget _buildSolverTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Presets Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('Presets:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              ...SpectroscopyService.caseStudies.map((study) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(study.compoundName.split(' ').first, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  backgroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: AppColors.brandBright, width: 0.8),
                  onPressed: () => _loadPreset(study),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Input Card
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
              _buildInput('FT-IR Peaks in cm⁻¹ (e.g. 1685, 1600, 1450)', _irPeaksCtrl),
              const SizedBox(height: 10),
              _buildInput('¹H NMR Shifts in ppm (e.g. 2.60, 7.50, 7.95)', _nmr1HPeaksCtrl),
              const SizedBox(height: 10),
              _buildInput('¹³C NMR Shifts in ppm (e.g. 26.6, 128.3, 198.1)', _nmr13CPeaksCtrl),
              const SizedBox(height: 10),
              _buildInput('Mass Spec m/z Peaks (e.g. 120, 105, 77)', _msPeaksCtrl),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: AppColors.brandBright,
                        side: const BorderSide(color: AppColors.brandBright, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _loadPreset(study),
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text('Load into Solver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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

  // ----------------------------------------------------
  // 2. Chromatograms & Spectrograms Tab (Interactive Lab Sim)
  // ----------------------------------------------------
  Widget _buildChromatogramsTab() {
    final allTechniques = SpectroscopyService.analyticalTechniques;
    final filteredTechniques = _selectedTechniqueCategory == 'All'
        ? allTechniques
        : allTechniques.where((t) => t.category == _selectedTechniqueCategory).toList();

    final currentTech = filteredTechniques.isNotEmpty
        ? filteredTechniques[_selectedTechniqueIndex.clamp(0, filteredTechniques.length - 1)]
        : allTechniques.first;
    final currentEx = currentTech.examples.isNotEmpty ? currentTech.examples.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category Filter Chips (All, Chromatography, Spectroscopy)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryFilterChip('All', 'All (${allTechniques.length})', Icons.auto_awesome_mosaic_rounded),
              const SizedBox(width: 8),
              _buildCategoryFilterChip('Chromatography', '🧪 Chromatography (3)', Icons.biotech_rounded),
              const SizedBox(width: 8),
              _buildCategoryFilterChip('Spectroscopy', '🧲 Spectroscopy (5)', Icons.waves_rounded),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Technique Selector with Icons & Subtitles
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(filteredTechniques.length, (index) {
              final isSel = _selectedTechniqueIndex == index;
              final t = filteredTechniques[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.instrumentIcon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.acronym,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isSel ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            t.category == 'Chromatography' ? 'Chromatogram' : 'Spectrogram',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isSel ? Colors.white70 : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  selected: isSel,
                  selectedColor: AppColors.brandPrimary,
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  side: BorderSide(
                    color: isSel ? AppColors.brandBright : Colors.white12,
                    width: 1.2,
                  ),
                  onSelected: (val) {
                    if (val) {
                      AppHaptics.selection();
                      setState(() {
                        _selectedTechniqueIndex = index;
                        _selectedPeak = null;
                      });
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // Prominent Technique Type Banner Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (currentTech.category == 'Chromatography' ? AppColors.accentCyan : AppColors.brandBright).withValues(alpha: 0.18),
                const Color(0xFF0F172A),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (currentTech.category == 'Chromatography' ? AppColors.accentCyan : AppColors.brandBright).withValues(alpha: 0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: (currentTech.category == 'Chromatography' ? AppColors.accentCyan : AppColors.brandBright).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (currentTech.category == 'Chromatography' ? AppColors.accentCyan : AppColors.brandBright).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      currentTech.instrumentIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: (currentTech.category == 'Chromatography' ? AppColors.accentCyan : AppColors.brandBright).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: (currentTech.category == 'Chromatography' ? AppColors.accentCyan : AppColors.brandBright).withValues(alpha: 0.6),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'INSTRUMENT: ${currentTech.category.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: currentTech.category == 'Chromatography' ? AppColors.accentCyan : AppColors.brandBright,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentTech.domainDescription,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentTech.fullInstrumentTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF090E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings_input_component_rounded, size: 14, color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentTech.instrumentParameters,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Principle Header Card
        GlowCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.accentCyan.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Fundamental Working Principle',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Theory', style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ChemistryMarkdownView(
                text: currentTech.fundamentalPrinciple,
                textStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Interactive Spectrogram / Chromatogram Graph
        if (currentEx != null) ...[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF070D18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentEx.title,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              currentEx.compound,
                              style: const TextStyle(color: AppColors.accentCyan, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, size: 12, color: AppColors.accentCyan),
                            SizedBox(width: 4),
                            Text('Tap Peak to Inspect', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    currentEx.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.35),
                  ),
                ),
                const SizedBox(height: 10),

                // Zoomable & Pannable Chart Canvas with Interactive Viewer
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _ZoomableSpectrogramChart(
                    example: currentEx,
                    technique: currentTech,
                    selectedPeak: _selectedPeak,
                    onPeakSelected: (peak) {
                      setState(() => _selectedPeak = peak);
                    },
                  ),
                ),

                // Peak Annotation Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: currentEx.peaks.map((p) {
                      final isSelected = _selectedPeak == p;
                      return InkWell(
                        onTap: () {
                          AppHaptics.selection();
                          setState(() => _selectedPeak = isSelected ? null : p);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentCyan.withValues(alpha: 0.25) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.accentCyan : Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accentCyan : AppColors.brandBright,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? AppColors.accentCyan : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Peak details pop-in
                if (_selectedPeak != null) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedPeak!.label,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentCyan, fontSize: 13),
                            ),
                            Text(
                              _selectedPeak!.compoundOrFragment,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ChemistryMarkdownView(
                          text: _selectedPeak!.explanation,
                          textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // X & Y Axis Fundamental Academic Guide
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlowCard(
                padding: const EdgeInsets.all(14),
                borderColor: AppColors.accentCyan.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded, color: AppColors.accentCyan, size: 18),
                        SizedBox(width: 6),
                        Text('X-Axis Meaning', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentCyan, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(currentTech.xAxisName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
                    Text(currentTech.xAxisUnit, style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Direction: ${currentTech.xAxisDirection}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontStyle: FontStyle.italic)),
                    const Divider(color: AppColors.borderSubtle, height: 14),
                    ChemistryMarkdownView(
                      text: currentTech.xAxisPhysicalMeaning,
                      textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlowCard(
                padding: const EdgeInsets.all(14),
                borderColor: AppColors.brandBright.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swap_vert_rounded, color: AppColors.brandBright, size: 18),
                        SizedBox(width: 6),
                        Text('Y-Axis Meaning', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandBright, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(currentTech.yAxisName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
                    Text(currentTech.yAxisUnit, style: const TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Direction: ${currentTech.yAxisDirection}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontStyle: FontStyle.italic)),
                    const Divider(color: AppColors.borderSubtle, height: 14),
                    ChemistryMarkdownView(
                      text: currentTech.yAxisPhysicalMeaning,
                      textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // How to Read & Interpret Checklist
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.checklist_rounded, color: AppColors.statusSuccess, size: 20),
                  SizedBox(width: 8),
                  Text('How to Read & Interpret this Instrument', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14.5)),
                ],
              ),
              const SizedBox(height: 12),
              ...currentTech.howToRead.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.arrow_right_rounded, color: AppColors.accentCyan, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChemistryMarkdownView(
                          text: item,
                          textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Key Formulas Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.functions_rounded, color: AppColors.accentGold, size: 20),
                      SizedBox(width: 8),
                      Text('Core Mathematical Equations & Rules', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14.5)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                    ),
                    child: const Text('KaTeX LaTeX', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...currentTech.keyFormulas.map((formula) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.25)),
                  ),
                  child: ChemistryMarkdownView(
                    text: formula,
                    textStyle: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChip(String categoryKey, String label, IconData icon) {
    final isSelected = _selectedTechniqueCategory == categoryKey;
    return InkWell(
      onTap: () {
        AppHaptics.selection();
        setState(() {
          _selectedTechniqueCategory = categoryKey;
          _selectedTechniqueIndex = 0;
          _selectedPeak = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandBright : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
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
          child: Material(
            color: Colors.transparent,
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
          child: Material(
            color: Colors.transparent,
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
          child: Material(
            color: Colors.transparent,
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
                          ChemistryMarkdownView(
                            text: prob.problemStatement,
                            textStyle: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                            selectable: false,
                          ),
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
      ),
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

}

// ----------------------------------------------------
// Zoomable & Pannable Spectrogram / Chromatogram Widget
// ----------------------------------------------------
class _ZoomableSpectrogramChart extends StatefulWidget {
  final SpectrogramExample example;
  final AnalyticalTechniqueInfo technique;
  final SpectralPeakAnnotation? selectedPeak;
  final ValueChanged<SpectralPeakAnnotation?> onPeakSelected;

  const _ZoomableSpectrogramChart({
    required this.example,
    required this.technique,
    required this.selectedPeak,
    required this.onPeakSelected,
  });

  @override
  State<_ZoomableSpectrogramChart> createState() => _ZoomableSpectrogramChartState();
}

class _ZoomableSpectrogramChartState extends State<_ZoomableSpectrogramChart> {
  late TransformationController _transformController;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _transformController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ZoomableSpectrogramChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.example != widget.example || oldWidget.technique != widget.technique) {
      _resetZoom();
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    AppHaptics.selection();
    final matrix = _transformController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(1.25, 1.25, 1.0));
    _transformController.value = matrix;
  }

  void _zoomOut() {
    AppHaptics.selection();
    if (_currentScale <= 1.1) {
      _resetZoom();
      return;
    }
    final matrix = _transformController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(1 / 1.25, 1 / 1.25, 1.0));
    _transformController.value = matrix;
  }

  void _resetZoom() {
    AppHaptics.selection();
    _transformController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _handleTap(Offset localPos, Size size) {
    const leftPad = 48.0;
    const rightPad = 24.0;
    const topPad = 24.0;
    const bottomPad = 32.0;

    final plotWidth = size.width - leftPad - rightPad;
    final plotHeight = size.height - topPad - bottomPad;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final xMin = widget.example.xMin;
    final xMax = widget.example.xMax;
    final yMin = widget.example.yMin;
    final yMax = widget.example.yMax;
    final isInvertedX = widget.technique.xAxisDirection.contains('Decreasing') ||
        widget.technique.xAxisDirection.contains('Inverted');

    double mapX(double x) {
      final norm = (x - xMin) / (xMax - xMin);
      if (isInvertedX) {
        return leftPad + (1.0 - norm) * plotWidth;
      }
      return leftPad + norm * plotWidth;
    }

    double mapY(double y) {
      final norm = (y - yMin) / (yMax - yMin);
      return (topPad + plotHeight) - norm * plotHeight;
    }

    SpectralPeakAnnotation? closest;
    double minDistance = 35.0; // 35 logical pixels touch radius

    for (final peak in widget.example.peaks) {
      final px = mapX(peak.x);
      final py = mapY(peak.y);
      final dist = math.sqrt(math.pow(px - localPos.dx, 2) + math.pow(py - localPos.dy, 2));
      if (dist < minDistance) {
        minDistance = dist;
        closest = peak;
      }
    }

    if (closest != null) {
      AppHaptics.selection();
      if (widget.selectedPeak == closest) {
        widget.onPeakSelected(null);
      } else {
        widget.onPeakSelected(closest);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zoom toolbar header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              bottom: BorderSide(color: Colors.white10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.zoom_in_rounded, size: 16, color: AppColors.accentCyan),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (_currentScale > 1.05 ? AppColors.accentGold : AppColors.brandBright).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_currentScale.toStringAsFixed(1)}x Zoom',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _currentScale > 1.05 ? AppColors.accentGold : AppColors.brandBright,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🤏 Pinch & Pan',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentScale > 1.05)
                    InkWell(
                      onTap: _resetZoom,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.restart_alt_rounded, size: 12, color: Colors.white70),
                            SizedBox(width: 3),
                            Text('Reset', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: _zoomOut,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.remove_rounded, size: 16, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _zoomIn,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Zoomable Canvas Viewport
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: Container(
            color: const Color(0xFF070D18),
            height: 240,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = Size(constraints.maxWidth, 240);
                return InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.hardEdge,
                  child: GestureDetector(
                    onTapUp: (details) => _handleTap(details.localPosition, chartSize),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: 240,
                      child: CustomPaint(
                        size: chartSize,
                        painter: _InteractiveSpectrogramChartPainter(
                          example: widget.example,
                          technique: widget.technique,
                          selectedPeak: widget.selectedPeak,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// Interactive Spectrogram & Chromatogram Chart Painter
// ----------------------------------------------------
class _InteractiveSpectrogramChartPainter extends CustomPainter {
  final SpectrogramExample example;
  final AnalyticalTechniqueInfo technique;
  final SpectralPeakAnnotation? selectedPeak;

  _InteractiveSpectrogramChartPainter({
    required this.example,
    required this.technique,
    this.selectedPeak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 48.0;
    const rightPad = 24.0;
    const topPad = 24.0;
    const bottomPad = 32.0;

    final plotWidth = size.width - leftPad - rightPad;
    final plotHeight = size.height - topPad - bottomPad;

    final xMin = example.xMin;
    final xMax = example.xMax;
    final yMin = example.yMin;
    final yMax = example.yMax;

    // Check if inverted X-axis (e.g. FT-IR 4000 -> 400 cm^-1 or NMR 12 -> 0 ppm)
    final isInvertedX = technique.xAxisDirection.contains('Decreasing') || technique.xAxisDirection.contains('Inverted');

    double mapX(double x) {
      final norm = (x - xMin) / (xMax - xMin);
      if (isInvertedX) {
        return leftPad + (1.0 - norm) * plotWidth;
      }
      return leftPad + norm * plotWidth;
    }

    double mapY(double y) {
      final norm = (y - yMin) / (yMax - yMin);
      return (topPad + plotHeight) - norm * plotHeight;
    }

    // Background grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 5; i++) {
      final gy = topPad + i * (plotHeight / 5);
      canvas.drawLine(Offset(leftPad, gy), Offset(leftPad + plotWidth, gy), gridPaint);
      final gx = leftPad + i * (plotWidth / 5);
      canvas.drawLine(Offset(gx, topPad), Offset(gx, topPad + plotHeight), gridPaint);
    }

    // Axes lines
    final axisPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.5;

    // X axis line
    canvas.drawLine(Offset(leftPad, topPad + plotHeight), Offset(leftPad + plotWidth, topPad + plotHeight), axisPaint);
    // Y axis line
    canvas.drawLine(Offset(leftPad, topPad), Offset(leftPad, topPad + plotHeight), axisPaint);

    // Axis labels
    final xLabelPainter = TextPainter(
      text: TextSpan(
        text: example.xAxisLabel,
        style: const TextStyle(color: AppColors.accentCyan, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xLabelPainter.paint(canvas, Offset(leftPad + plotWidth / 2 - xLabelPainter.width / 2, size.height - 18));

    final yLabelPainter = TextPainter(
      text: TextSpan(
        text: example.yAxisLabel,
        style: const TextStyle(color: AppColors.brandBright, fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(14, topPad + plotHeight / 2 + yLabelPainter.width / 2);
    canvas.rotate(-math.pi / 2);
    yLabelPainter.paint(canvas, Offset.zero);
    canvas.restore();

    // If technique is Mass Spec: render as stick spectrum
    if (technique.id == 'ms') {
      final stickPaint = Paint()
        ..color = AppColors.brandBright
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      for (final peak in example.peaks) {
        final px = mapX(peak.x);
        final py = mapY(peak.y);
        final isSel = selectedPeak == peak;

        if (isSel) {
          final glowStick = Paint()
            ..color = AppColors.accentCyan.withValues(alpha: 0.6)
            ..strokeWidth = 5.0
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(px, mapY(0)), Offset(px, py), glowStick);
        }

        canvas.drawLine(Offset(px, mapY(0)), Offset(px, py), stickPaint);
        canvas.drawCircle(Offset(px, py), isSel ? 5.0 : 3.5, Paint()..color = isSel ? AppColors.accentCyan : AppColors.brandBright);
      }
    } else {
      // Continuous curve
      if (example.curvePoints.isNotEmpty) {
        final path = Path();
        final first = example.curvePoints.first;
        path.moveTo(mapX(first.x), mapY(first.y));

        for (int i = 1; i < example.curvePoints.length; i++) {
          final pt = example.curvePoints[i];
          path.lineTo(mapX(pt.x), mapY(pt.y));
        }

        // Curve glow & stroke
        final curveGlow = Paint()
          ..color = AppColors.accentCyan.withValues(alpha: 0.25)
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, curveGlow);

        final curveStroke = Paint()
          ..color = AppColors.accentCyan
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, curveStroke);
      }
    }

    // Draw peak annotation markers
    for (final peak in example.peaks) {
      final px = mapX(peak.x);
      final py = mapY(peak.y);
      final isSel = selectedPeak == peak;

      // Glow marker
      final markerPaint = Paint()..color = isSel ? AppColors.accentGold : AppColors.brandBright;
      canvas.drawCircle(Offset(px, py), isSel ? 6.0 : 4.0, markerPaint);

      // Marker badge text
      final pLabel = TextPainter(
        text: TextSpan(
          text: peak.label.split('(').first.trim(),
          style: TextStyle(
            color: isSel ? AppColors.accentGold : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeY = py - pLabel.height - 4;
      pLabel.paint(canvas, Offset((px - pLabel.width / 2).clamp(leftPad, leftPad + plotWidth - pLabel.width), badgeY));
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveSpectrogramChartPainter oldDelegate) {
    return oldDelegate.example != example ||
        oldDelegate.technique != technique ||
        oldDelegate.selectedPeak != selectedPeak;
  }
}
