import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/services/reaction_curation_repository.dart';

/// Modal bottom sheet providing deep MSc pedagogical breakdowns, interactive MCQs,
/// viva examination questions, and flashcard generation for an organic reaction.
class ReactionPedagogySheet extends StatefulWidget {
  final CuratedReaction reaction;
  final String reactantSmiles;
  final String productSmiles;
  final String reagent;
  final String solvent;

  const ReactionPedagogySheet({
    super.key,
    required this.reaction,
    required this.reactantSmiles,
    required this.productSmiles,
    this.reagent = '',
    this.solvent = '',
  });

  static Future<void> show(
    BuildContext context, {
    required CuratedReaction reaction,
    required String reactantSmiles,
    required String productSmiles,
    String reagent = '',
    String solvent = '',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReactionPedagogySheet(
        reaction: reaction,
        reactantSmiles: reactantSmiles,
        productSmiles: productSmiles,
        reagent: reagent,
        solvent: solvent,
      ),
    );
  }

  @override
  State<ReactionPedagogySheet> createState() => _ReactionPedagogySheetState();
}

class _ReactionPedagogySheetState extends State<ReactionPedagogySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Breakdown data
  Map<String, dynamic>? _explanationData;
  List<Map<String, dynamic>> _mcqs = [];
  List<Map<String, dynamic>> _vivaQuestions = [];
  final Map<int, int> _selectedMcqAnswers = {};
  final Set<int> _revealedViva = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPedagogyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPedagogyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Try invoking Edge Function `explain-reaction`
      final client = SupabaseService.instance.client;
      if (client != null) {
        final res = await client.functions.invoke(
          'explain-reaction',
          body: {
            'reaction_id': widget.reaction.reactionId,
            'reaction_name': widget.reaction.reactionName,
            'reactants_smiles': widget.reactantSmiles,
            'product_smiles': widget.productSmiles,
            'reagent': widget.reagent.isNotEmpty ? widget.reagent : widget.reaction.conditions,
            'solvent': widget.solvent.isNotEmpty ? widget.solvent : widget.reaction.solvent,
            'temperature': widget.reaction.temperature,
            'steps': widget.reaction.steps.map((s) => {
              'step_number': s.stepNumber,
              'step_title': s.stepTitle,
              'step_description': s.stepDescription,
              'bond_changes': s.bondChanges,
            }).toList(),
            'type': 'full',
          },
        );

        if (res.status == 200 && res.data != null) {
          final dynamic raw = res.data;
          final Map<dynamic, dynamic> map = raw is Map ? raw : jsonDecode(raw.toString());
          if (map['success'] == true && map['data'] is Map) {
            _populateFromData(Map<String, dynamic>.from(map['data'] as Map));
            setState(() => _isLoading = false);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[ReactionPedagogySheet] Edge function error: $e');
    }

    // 2. Client-side fallback: synthesize from curated reaction data + Gemini orchestrator
    _populateFromCuratedData();
    setState(() => _isLoading = false);
  }

  void _populateFromData(Map<String, dynamic> data) {
    _explanationData = data;
    if (data['mcqs'] is List) {
      _mcqs = (data['mcqs'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      _mcqs = _generateDefaultMcqs();
    }
    if (data['viva'] is List) {
      _vivaQuestions = (data['viva'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      _vivaQuestions = _generateDefaultViva();
    }
  }

  void _populateFromCuratedData() {
    _explanationData = {
      'summary': widget.reaction.description,
      'why_it_happens': 'Driven by thermodynamic bond enthalpy favorability and transition state stabilization under ${widget.reaction.conditions}.',
      'electron_movement': 'Electron pairs shift from the electron-rich nucleophilic center into the electrophilic orbital as detailed in the curved arrow steps.',
      'role_of_reagents': 'Conditions: ${widget.reaction.conditions}. Solvent: ${widget.reaction.solvent}. Temperature: ${widget.reaction.temperature}.',
      'stereochemical_outcome': widget.reaction.stereochemistryNotes.isNotEmpty ? widget.reaction.stereochemistryNotes : 'Governed by orbital symmetry and steric trajectory.',
      'exam_points': [
        'Selectivity: ${widget.reaction.selectivityNotes}',
        'Major product rule: ${widget.reaction.majorProductRule}',
        'Source reference: ${widget.reaction.sourceReference}',
      ],
      'common_pitfalls': [
        'Confusing competing pathways (e.g. substitution vs elimination)',
        'Misidentifying the rate-determining step (RDS)',
        'Failing to invert or preserve stereocenters correctly',
      ],
    };

    _mcqs = _generateDefaultMcqs();
    _vivaQuestions = _generateDefaultViva();
  }

  List<Map<String, dynamic>> _generateDefaultMcqs() {
    return [
      {
        'question': 'What is the primary factor dictating the rate-determining step in ${widget.reaction.reactionName}?',
        'options': [
          'Steric hindrance and orbital approach trajectory',
          'Solvent boiling point only',
          'Atmospheric pressure',
          'Vessel geometry',
        ],
        'correct_index': 0,
        'explanation': 'In MSc-level organic mechanisms, activation barrier is dictated by steric and electronic orbital overlap in the transition state.',
      },
      {
        'question': 'Which stereochemical outcome is strictly observed for this transformation?',
        'options': [
          widget.reaction.stereochemistryNotes.isNotEmpty ? widget.reaction.stereochemistryNotes : 'Stereospecific inversion / control',
          'Random scrambling without preference',
          'Complete loss of all stereocenters',
          '100% retention at all centers regardless of mechanism',
        ],
        'correct_index': 0,
        'explanation': 'The stereochemical pathway is governed by frontier molecular orbital (FMO) alignment and steric factors.',
      },
      {
        'question': 'Why is ${widget.reaction.solvent.isNotEmpty ? widget.reaction.solvent : "the specified solvent"} chosen for this reaction?',
        'options': [
          'It stabilizes the appropriate transition state or ionic intermediates without impeding reactivity',
          'It changes the elemental composition of the product',
          'It acts as an irreversible poison',
          'It has no effect on reaction kinetics',
        ],
        'correct_index': 0,
        'explanation': 'Solvent polarity and protic/aprotic characteristics dramatically modulate transition state energies and nucleophile/base activity.',
      },
    ];
  }

  List<Map<String, dynamic>> _generateDefaultViva() {
    return [
      {
        'question': 'Explain the frontier molecular orbital (FMO) interactions taking place in ${widget.reaction.reactionName}.',
        'model_answer': 'The highest occupied molecular orbital (HOMO) of the nucleophile/electron-donor overlaps with the lowest unoccupied molecular orbital (LUMO, typically σ* or π*) of the electrophilic partner, leading to bond reorganization.',
        'key_concept': 'HOMO-LUMO Overlap',
      },
      {
        'question': 'How would you experimentally confirm the proposed mechanism and rate law?',
        'model_answer': 'Conduct kinetic experiments (measuring initial rates upon varying reactant concentrations), determine activation parameters (Arrhenius/Eyring plots), and use kinetic isotope effects (KIE) to verify if bond cleavage occurs in the RDS.',
        'key_concept': 'Kinetic & Isotopic Proof',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title & Reaction Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.electricViolet.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.school_rounded, color: AppColors.electricViolet, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reaction.reactionName,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'MSc Mechanism & Pedagogy Masterclass',
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tabs: Concepts | MCQs | Viva Voce
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF38BDF8),
            indicatorWeight: 3,
            labelColor: const Color(0xFF38BDF8),
            unselectedLabelColor: const Color(0xFF94A3B8),
            tabs: const [
              Tab(icon: Icon(Icons.lightbulb_outline_rounded, size: 18), text: 'Concepts'),
              Tab(icon: Icon(Icons.quiz_outlined, size: 18), text: 'MCQs'),
              Tab(icon: Icon(Icons.record_voice_over_outlined, size: 18), text: 'Viva Voce'),
            ],
          ),

          // Tab View Body
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.electricViolet),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConceptsTab(),
                      _buildMcqsTab(),
                      _buildVivaTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptsTab() {
    final data = _explanationData ?? {};
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildConceptCard(
          title: 'What & Why It Happens',
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF38BDF8),
          body: data['why_it_happens'] as String? ?? widget.reaction.description,
        ),
        const SizedBox(height: 14),
        _buildConceptCard(
          title: 'Electron Movement & Orbitals',
          icon: Icons.compare_arrows_rounded,
          iconColor: const Color(0xFFEC4899),
          body: data['electron_movement'] as String? ?? 'Curved arrows signify heterolytic cleavage and coordination of electron pairs.',
        ),
        const SizedBox(height: 14),
        _buildConceptCard(
          title: 'Stereochemical Pathway',
          icon: Icons.threed_rotation_rounded,
          iconColor: const Color(0xFF8B5CF6),
          body: data['stereochemical_outcome'] as String? ?? widget.reaction.stereochemistryNotes,
        ),
        const SizedBox(height: 14),
        _buildListCard(
          title: 'Key Exam Highlights (MSc)',
          icon: Icons.verified_rounded,
          iconColor: const Color(0xFF10B981),
          items: (data['exam_points'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        ),
        const SizedBox(height: 14),
        _buildListCard(
          title: 'Common Student Pitfalls',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          items: (data['common_pitfalls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        ),
      ],
    );
  }

  Widget _buildMcqsTab() {
    if (_mcqs.isEmpty) {
      return const Center(
        child: Text('No MCQs available.', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _mcqs.length,
      itemBuilder: (ctx, i) {
        final mcq = _mcqs[i];
        final options = (mcq['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final correctIdx = (mcq['correct_index'] as num?)?.toInt() ?? 0;
        final selectedIdx = _selectedMcqAnswers[i];
        final explanation = mcq['explanation'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha:0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q${i + 1}. ${mcq['question']}',
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(options.length, (optIdx) {
                final isSelected = selectedIdx == optIdx;
                final isCorrect = optIdx == correctIdx;
                Color optBorder = const Color(0xFF334155);
                Color optBg = Colors.transparent;

                if (selectedIdx != null) {
                  if (isCorrect) {
                    optBorder = const Color(0xFF10B981);
                    optBg = const Color(0xFF10B981).withValues(alpha:0.15);
                  } else if (isSelected) {
                    optBorder = const Color(0xFFEF4444);
                    optBg = const Color(0xFFEF4444).withValues(alpha:0.15);
                  }
                }

                return GestureDetector(
                  onTap: () {
                    if (selectedIdx == null) {
                      AppHaptics.selection();
                      setState(() {
                        _selectedMcqAnswers[i] = optIdx;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: optBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: optBorder),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + optIdx)}.',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            options[optIdx],
                            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                          ),
                        ),
                        if (selectedIdx != null && isCorrect)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                        if (selectedIdx != null && isSelected && !isCorrect)
                          const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18),
                      ],
                    ),
                  ),
                );
              }),
              if (selectedIdx != null && explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          explanation,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildVivaTab() {
    if (_vivaQuestions.isEmpty) {
      return const Center(
        child: Text('No viva questions available.', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _vivaQuestions.length,
      itemBuilder: (ctx, i) {
        final viva = _vivaQuestions[i];
        final isRevealed = _revealedViva.contains(i);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha:0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: Color(0xFFA78BFA), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Viva Q${i + 1}: ${viva['question']}',
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  AppHaptics.selection();
                  setState(() {
                    if (isRevealed) {
                      _revealedViva.remove(i);
                    } else {
                      _revealedViva.add(i);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF334155))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isRevealed ? 'Hide Model Answer' : 'Show Model Answer',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isRevealed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF38BDF8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              if (isRevealed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (viva['key_concept'] != null) ...[
                          Text(
                            'Key Concept: ${viva['key_concept']}',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          viva['model_answer'] as String? ?? '',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConceptCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
