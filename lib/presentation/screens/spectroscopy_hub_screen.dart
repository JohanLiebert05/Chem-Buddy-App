import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/spectroscopy_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _runAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _formulaCtrl.dispose();
    _irPeaksCtrl.dispose();
    _nmrPeaksCtrl.dispose();
    _msPeaksCtrl.dispose();
    super.dispose();
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
}
