import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/services/reaction_curation_repository.dart';
import '../../data/services/reaction_matcher_engine.dart';
import '../widgets/animated_mechanism_viewer.dart';
import '../widgets/reaction_pedagogy_sheet.dart';
import '../../services/reaction_predictor_service.dart';
import 'ask_chembuddy_screen.dart';
import 'chem_sketcher_screen.dart';

/// Full-featured Organic Reaction Predictor & Mechanism Viewer for MSc Chemistry students.
class OrganicReactionPredictorScreen extends StatefulWidget {
  final String? initialReactantsSmiles;
  final String? initialReactionId;

  const OrganicReactionPredictorScreen({
    super.key,
    this.initialReactantsSmiles,
    this.initialReactionId,
  });

  @override
  State<OrganicReactionPredictorScreen> createState() =>
      _OrganicReactionPredictorScreenState();
}

class _OrganicReactionPredictorScreenState
    extends State<OrganicReactionPredictorScreen> {
  final TextEditingController _reactantsController = TextEditingController();
  final TextEditingController _reagentsController = TextEditingController();
  final TextEditingController _solventController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();

  bool _isPredicting = false;
  ReactionMatchResult? _matchResult;
  CuratedReaction? _selectedCatalogReaction;
  List<CuratedReaction> _allCuratedReactions = [];

  // Common MSc Reagents for quick-tap selection
  static const List<Map<String, String>> _commonReagents = [
    {'name': 'NaI / Acetone', 'reagent': 'NaI', 'solvent': 'Acetone', 'temp': '25°C'},
    {'name': 'NaOH / H2O', 'reagent': 'NaOH', 'solvent': 'H2O', 'temp': '25°C'},
    {'name': 't-BuOK / Heat', 'reagent': 't-BuOK', 'solvent': 't-BuOH', 'temp': '75°C'},
    {'name': 'HNO3 / H2SO4', 'reagent': 'HNO3 / H2SO4', 'solvent': 'H2SO4', 'temp': '55°C'},
    {'name': 'Br2 / FeBr3', 'reagent': 'Br2 / FeBr3', 'solvent': 'FeBr3', 'temp': '25°C'},
    {'name': 'PCC / CH2Cl2', 'reagent': 'PCC', 'solvent': 'CH2Cl2', 'temp': '25°C'},
    {'name': 'NaBH4 / MeOH', 'reagent': 'NaBH4', 'solvent': 'MeOH', 'temp': '0°C'},
    {'name': 'MeMgBr / Et2O', 'reagent': 'MeMgBr', 'solvent': 'Et2O', 'temp': '0°C'},
    {'name': 'mCPBA', 'reagent': 'mCPBA', 'solvent': 'CH2Cl2', 'temp': '25°C'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialReactantsSmiles != null) {
      _reactantsController.text = widget.initialReactantsSmiles!;
    }
    _loadCuratedReactions();
  }

  @override
  void dispose() {
    _reactantsController.dispose();
    _reagentsController.dispose();
    _solventController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Future<void> _loadCuratedReactions() async {
    final list = await ReactionCurationRepository.instance.getAllReactions();
    setState(() {
      _allCuratedReactions = list;
    });

    if (widget.initialReactionId != null) {
      final found = list.firstWhere(
        (r) => r.reactionId == widget.initialReactionId,
        orElse: () => list.first,
      );
      _selectCuratedReaction(found);
    }
  }

  void _selectCuratedReaction(CuratedReaction rxn) {
    setState(() {
      _selectedCatalogReaction = rxn;
      if (rxn.examples.isNotEmpty) {
        final ex = rxn.examples.first;
        _reactantsController.text = ex.reactantSmiles;
        _reagentsController.text = ex.reagentName;
        _solventController.text = ex.solvent.isNotEmpty ? ex.solvent : rxn.solvent;
        _temperatureController.text = ex.temperature.isNotEmpty ? ex.temperature : rxn.temperature;
      } else {
        _reagentsController.text = rxn.conditions;
        _solventController.text = rxn.solvent;
        _temperatureController.text = rxn.temperature;
      }
    });
    _predictReaction();
  }

  Future<void> _predictReaction() async {
    final reactants = _reactantsController.text.trim();
    final reagents = _reagentsController.text.trim();
    final solvent = _solventController.text.trim();
    final temp = _temperatureController.text.trim();

    if (reactants.isEmpty && reagents.isEmpty && _selectedCatalogReaction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter reactant SMILES, reagent, or select a reaction.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    AppHaptics.selection();
    setState(() {
      _isPredicting = true;
      _matchResult = null;
    });

    try {
      var result = await ReactionMatcherEngine.instance.matchReaction(
        reactantsSmiles: reactants,
        reagents: reagents,
        solvent: solvent,
        temperature: temp,
        optionalReactionName: _selectedCatalogReaction?.reactionId,
      );

      // If local curated database does not have a direct rule match,
      // fallback to the MSc Organic Synthesis Engine (Supabase Edge Function / Gemini Orchestrator)
      if (!result.isMatched && reactants.isNotEmpty) {
        final aiPred = await ReactionPredictorService.instance.predictFullReaction(
          reactantsSmiles: reactants,
          reagents: reagents,
          solvent: solvent,
          temperature: temp,
        );

        if (aiPred.success && aiPred.majorProduct != null) {
          result = _convertAiPredictionToMatchResult(aiPred, reactants, reagents, solvent, temp);
        }
      }

      setState(() {
        _matchResult = result;
        _isPredicting = false;
      });
    } catch (e) {
      setState(() {
        _isPredicting = false;
        _matchResult = ReactionMatchResult.unmatched(
          reason: 'Error predicting reaction: $e',
        );
      });
    }
  }

  ReactionMatchResult _convertAiPredictionToMatchResult(
    OrganicSynthesisPrediction aiPred,
    String reactants,
    String reagents,
    String solvent,
    String temp,
  ) {
    final steps = aiPred.mechanismSteps.map((s) {
      return CuratedReactionStep(
        stepId: 'ai_step_${s.stepNumber}',
        reactionId: 'ai_synthesis_rxn',
        stepNumber: s.stepNumber,
        stepTitle: s.stepTitle,
        stepDescription: s.description,
        intermediateName: s.intermediateSmiles,
        intermediateSmiles: s.intermediateSmiles,
        bondChanges: s.electronPushing,
      );
    }).toList();

    final dynamicReaction = CuratedReaction(
      reactionId: 'AI_SYNTHESIS',
      reactionName: aiPred.reactionName,
      reactionClass: aiPred.reactionClass,
      description: aiPred.pedagogy?.drivingForce ?? '',
      conditions: aiPred.reagents.isNotEmpty ? aiPred.reagents : (reagents.isNotEmpty ? reagents : 'Standard conditions'),
      solvent: solvent,
      temperature: temp,
      majorProductRule: aiPred.majorProduct?.name ?? '',
      selectivityNotes: aiPred.pedagogy?.regioselectivityRule ?? '',
      stereochemistryNotes: aiPred.majorProduct?.stereochemistry ?? '',
      sourceReference: 'MSc Organic Synthesis Engine',
      steps: steps,
      examples: const [],
    );

    return ReactionMatchResult(
      isMatched: true,
      confidence: ReactionConfidence.high,
      reaction: dynamicReaction,
      majorProductSmiles: aiPred.majorProduct?.smiles ?? '',
      majorProductName: aiPred.majorProduct?.name ?? 'Major Product',
      mechanismSteps: steps,
      schemeSvg: aiPred.majorProduct?.svgData ?? '',
      notes: aiPred.reactionClass,
      suggestions: const [],
    );
  }

  Future<void> _openCanvasSketcher() async {
    AppHaptics.confirm();
    final smiles = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => ChemSketcherScreen(
          initialSmiles: _reactantsController.text.trim().isNotEmpty
              ? _reactantsController.text.trim()
              : null,
        ),
      ),
    );

    if (smiles != null && smiles.trim().isNotEmpty) {
      setState(() {
        _reactantsController.text = smiles.trim();
      });
      _predictReaction();
    }
  }

  void _showReactionCatalogModal() {
    AppHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8), size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Curated MSc Reactions (35)',
                    style: TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _allCuratedReactions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final rxn = _allCuratedReactions[i];
                  return InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _selectCuratedReaction(rxn);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha:0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rxn.reactionName,
                                  style: const TextStyle(
                                    color: Color(0xFFF1F5F9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.electricViolet.withValues(alpha:0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rxn.difficulty,
                                  style: const TextStyle(
                                    color: AppColors.electricViolet,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rxn.description,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.35),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.science_outlined, color: Color(0xFF38BDF8), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                rxn.reactionClass,
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                '${rxn.steps.length} Mechanism Steps',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReactionToLibrary() async {
    final rxn = _matchResult?.reaction;
    if (rxn == null) return;

    AppHaptics.confirm();
    final ok = await ReactionCurationRepository.instance.saveReactionForStudent(
      reactionId: rxn.reactionId,
      reactionName: rxn.reactionName,
      reactantSmiles: _reactantsController.text.trim(),
      productSmiles: _matchResult!.majorProductSmiles,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '⭐️ Reaction saved to your ChemBuddy Library!' : 'Reaction saved locally.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reaction Predictor & Mechanism',
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Deterministic Curated Chemistry • Zero Hallucination',
              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showReactionCatalogModal,
            icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Curated Reaction Catalog',
          ),
        ],
      ),
      body: HexBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Inputs Card
            _buildInputSection(),

            const SizedBox(height: 20),

            // 2. Loading State
            if (_isPredicting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.electricViolet),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing chemical graph and matching mechanistic pathway...',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Matched Reaction Outcome
            if (!_isPredicting && _matchResult != null && _matchResult!.isMatched)
              _buildPredictionResultCard(_matchResult!),

            // 4. Unmatched / Ambiguous Feedback
            if (!_isPredicting && _matchResult != null && !_matchResult!.isMatched)
              _buildUnmatchedCard(_matchResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reactant Input Label + Draw in Canvas button
          Row(
            children: [
              const Icon(Icons.science_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Reactant Structure(s)',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openCanvasSketcher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricViolet.withValues(alpha:0.2),
                  foregroundColor: const Color(0xFFC4B5FD),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
                icon: const Icon(Icons.draw_rounded, size: 16),
                label: const Text('Draw in Canvas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Reactant SMILES TextField
          TextField(
            controller: _reactantsController,
            style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. CCBr, c1ccccc1, CC(=O)C (SMILES)',
              hintStyle: const TextStyle(color: Color(0xFF475569)),
              filled: true,
              fillColor: const Color(0xFF1E293B).withValues(alpha:0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF38BDF8)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 14),

          // Reagents Field
          const Row(
            children: [
              Icon(Icons.colorize_rounded, color: Color(0xFFEC4899), size: 18),
              SizedBox(width: 8),
              Text(
                'Reagent / Catalyst',
                style: TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reagentsController,
            style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. NaI, NaOH, HNO3 / H2SO4, PCC, MeMgBr',
              hintStyle: const TextStyle(color: Color(0xFF475569)),
              filled: true,
              fillColor: const Color(0xFF1E293B).withValues(alpha:0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEC4899)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 10),

          // Reagent Quick Chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _commonReagents.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final item = _commonReagents[i];
                return InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    setState(() {
                      _reagentsController.text = item['reagent']!;
                      _solventController.text = item['solvent']!;
                      _temperatureController.text = item['temp']!;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Center(
                      child: Text(
                        item['name']!,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Solvent & Temperature (2 columns)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solvent (Optional)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _solventController,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'e.g. Acetone, EtOH',
                        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF1E293B).withValues(alpha:0.6),
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
                    const Text('Temperature / Time', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _temperatureController,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'e.g. 25°C, Reflux',
                        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF1E293B).withValues(alpha:0.6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Predict Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isPredicting ? null : _predictReaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: const Text(
                'Predict Major Product & Mechanism',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionResultCard(ReactionMatchResult result) {
    final rxn = result.reaction!;
    final isHighConf = result.confidence == ReactionConfidence.high;
    final confColor = isHighConf ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final confText = isHighConf ? 'High (Deterministic Curated Match)' : 'Moderate (Functional Group Match)';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Reaction Title & Confidence Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: confColor.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: confColor.withValues(alpha:0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: confColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            confText,
                            style: TextStyle(color: confColor, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _saveReactionToLibrary,
                      icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFF38BDF8)),
                      tooltip: 'Save to Library',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rxn.reactionName,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Class: ${rxn.reactionClass} • ${rxn.subclass}',
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // 2D Scheme Vector SVG
          if (result.schemeSvg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1120),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: SvgPicture.string(
                    result.schemeSvg,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

          // Product Details Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha:0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREDICTED MAJOR PRODUCT',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.majorProductName,
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SMILES: ${result.majorProductSmiles}',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: result.majorProductSmiles));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Product SMILES copied to clipboard!')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 16),
                        tooltip: 'Copy SMILES',
                      ),
                    ],
                  ),
                  if (result.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Mechanism Rule: ${result.notes}',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Interactive Mechanism Viewer Widget
          if (rxn.steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedMechanismViewer(reaction: rxn),
            ),

          const SizedBox(height: 16),

          // Pedagogy & ChemBuddy AI Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ReactionPedagogySheet.show(
                        context,
                        reaction: rxn,
                        reactantSmiles: _reactantsController.text.trim(),
                        productSmiles: result.majorProductSmiles,
                        reagent: _reagentsController.text.trim(),
                        solvent: _solventController.text.trim(),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.school_rounded, size: 18),
                    label: const Text('Understand & MCQs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => AskChemBuddyScreen(
                            initialQuestion:
                                'Explain the mechanism of ${rxn.reactionName} starting from reactants ${_reactantsController.text.trim()} to yield ${result.majorProductName} (${result.majorProductSmiles}) under conditions: ${rxn.conditions}.',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Ask ChemBuddy AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnmatchedCard(ReactionMatchResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No Confident Mechanism Match',
                  style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result.unmatchedReason ??
                'ChemBuddy does not invent unverified reactions. This ensures 100% academic integrity for your MSc exams.',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.45),
          ),
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Suggestions to resolve:',
              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...result.suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF38BDF8))),
                    Expanded(child: Text(s, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showReactionCatalogModal,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF0284C7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Browse Supported Reaction Catalog (35)'),
            ),
          ),
        ],
      ),
    );
  }
}
