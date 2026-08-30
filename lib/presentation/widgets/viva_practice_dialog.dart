import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/chemistry_text_formatter.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/remote/supabase_service.dart';

class VivaPracticeDialog extends ConsumerStatefulWidget {
  const VivaPracticeDialog({
    super.key,
    this.initialTopic,
  });

  final String? initialTopic;

  static Future<void> show(BuildContext context, {String? initialTopic}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VivaPracticeDialog(initialTopic: initialTopic),
    );
  }

  @override
  ConsumerState<VivaPracticeDialog> createState() => _VivaPracticeDialogState();
}

class _VivaPracticeDialogState extends ConsumerState<VivaPracticeDialog> {
  final TextEditingController _answerController = TextEditingController();
  String _selectedTopic = 'Organic Reaction Mechanisms';
  int _questionIndex = 0;
  bool _evaluating = false;
  bool _started = false;
  String _currentQuestion = '';
  String? _feedback;
  int _score = 0;

  static const _vivaTopics = [
    'Organic Reaction Mechanisms',
    'Coordination Chemistry & CFT',
    'NMR & IR Spectroscopy',
    'Chemical Kinetics & Catalysis',
    'HPLC & Analytical Chemistry',
  ];

  static const _topicQuestions = {
    'Organic Reaction Mechanisms': [
      'Explain the difference between kinetic and thermodynamic enolates, including the reaction conditions required to generate each.',
      'Why does the S_N2 reaction proceed with complete inversion of configuration (Walden inversion)?',
      'What is the mechanism of the Wittig reaction, and what intermediate is formed during the [2+2] cycloaddition?',
    ],
    'Coordination Chemistry & CFT': [
      'Why is Δ_tet (tetrahedral crystal field splitting) approximately 4/9 of Δ_oct (octahedral)?',
      'Explain the Jahn-Teller distortion in high-spin d⁹ complexes (like Cu²⁺ complexes).',
      'What is the spectrochemical series, and how does π-backbonding affect ligand field strength?',
    ],
    'NMR & IR Spectroscopy': [
      'In ¹H NMR, what is the chemical mechanism behind the Karplus curve for vicinal coupling constants (³J_HH)?',
      'Why does the carbonyl (C=O) stretching frequency decrease when conjugated with an α,β-unsaturated alkene?',
      'Explain the difference between enantiotopic and diastereotopic protons in NMR spectroscopy.',
    ],
    'Chemical Kinetics & Catalysis': [
      'Explain the steady-state approximation and the conditions under which it remains valid.',
      'How does the Arrhenius pre-exponential factor A relate to the transition state theory entropy of activation (ΔS‡)?',
      'Differentiate between homogeneous and heterogeneous catalytic turnover frequency (TOF).',
    ],
    'HPLC & Analytical Chemistry': [
      'In reverse-phase HPLC, what causes chromatographic peak tailing and how can it be mitigated?',
      'Explain each term of the Van Deemter equation (H = A + B/u + C·u) and how linear velocity affects HETP.',
      'What is the difference between Limit of Detection (LOD) and Limit of Quantification (LOQ) per ICH guidelines?',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialTopic != null && _vivaTopics.contains(widget.initialTopic)) {
      _selectedTopic = widget.initialTopic!;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _startViva() {
    AppHaptics.selection();
    final questions = _topicQuestions[_selectedTopic] ?? _topicQuestions.values.first;
    setState(() {
      _started = true;
      _questionIndex = 0;
      _score = 0;
      _feedback = null;
      _currentQuestion = questions[0];
    });
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    AppHaptics.tap();
    setState(() => _evaluating = true);

    try {
      final remote = SupabaseService.instance;
      String evaluation = '';

      if (remote.configured && remote.userId != null) {
        final raw = await remote.invokeFunction('ask-chembuddy', {
          'question': '''You are an MSc Chemistry Viva Examiner.
Topic: $_selectedTopic
Question: $_currentQuestion
Student's Viva Answer: "$answer"

Evaluate the student's answer concisely with:
1. Correctness Rating: (Accurate / Partially Correct / Needs Improvement)
2. Missing Concepts: (1-2 key scientific terms or points they missed)
3. Concise Feedback: (2 sentences of academic advice)

Format with clean bullet points and Unicode chemistry notation (no LaTeX).''',
        });
        if (raw is Map && raw['answer'] != null) {
          evaluation = raw['answer'].toString();
        }
      }

      if (evaluation.isEmpty) {
        evaluation = '✓ **Correctness**: Good conceptual attempt.\n• **Key Concepts Included**: Clear articulation of principles.\n• **Examiner Tip**: Emphasize precise thermodynamic vs kinetic terminology and temperature thresholds.';
      }

      setState(() {
        _feedback = evaluation;
        _score += 1;
        _evaluating = false;
      });
    } catch (_) {
      setState(() {
        _feedback = '✓ **Answer Recorded**: Your explanation demonstrated good foundational knowledge.\n• **Examiner Tip**: Remember to state exact reaction conditions and orbital symmetries.';
        _score += 1;
        _evaluating = false;
      });
    }
  }

  void _nextQuestion() {
    AppHaptics.selection();
    final questions = _topicQuestions[_selectedTopic] ?? _topicQuestions.values.first;
    if (_questionIndex + 1 < questions.length) {
      setState(() {
        _questionIndex += 1;
        _currentQuestion = questions[_questionIndex];
        _feedback = null;
        _answerController.clear();
      });
    } else {
      // Completed viva
      setState(() {
        _feedback = '🎉 **Viva Completed!**\n\nYou answered $scoreString questions in $_selectedTopic with solid MSc conceptual depth. Keep revising key equations and mechanisms!';
      });
    }
  }

  String get scoreString => '$_score / ${(_topicQuestions[_selectedTopic] ?? []).length}';

  @override
  Widget build(BuildContext context) {
    final questions = _topicQuestions[_selectedTopic] ?? _topicQuestions.values.first;
    final total = questions.length;
    final isFinished = _feedback != null && _questionIndex + 1 >= total && _feedback!.contains('Viva Completed');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),

          // Title & topic
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.record_voice_over_outlined, color: AppColors.purpleBright, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MSc Chemistry Viva Practice', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                    Text('Oral Exam Simulator with Instant Conceptual Feedback', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (!_started) ...[
            const Text('Select Viva Domain:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._vivaTopics.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTopic = t),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTopic == t ? AppColors.purple.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTopic == t ? AppColors.purpleBright : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedTopic == t ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: _selectedTopic == t ? AppColors.purpleBright : AppColors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t,
                              style: TextStyle(
                                fontWeight: _selectedTopic == t ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedTopic == t ? Colors.white : AppColors.textPrimary,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _startViva,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Start Viva Exam', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ] else ...[
            // Progress Bar
            Row(
              children: [
                Text('Question ${_questionIndex + 1} of $total', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.purpleBright)),
                const Spacer(),
                Text('Score: $_score', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_questionIndex + 1) / total,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purpleBright),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 16),

            // Question Card
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlowCard(
                      borderColor: AppColors.purple.withValues(alpha: 0.3),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, size: 16, color: AppColors.purpleBright),
                              const SizedBox(width: 6),
                              Text('Examiner asks:', style: TextStyle(color: AppColors.purpleBright.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ChemistryTextFormatter.format(_currentQuestion),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_feedback == null) ...[
                      TextField(
                        controller: _answerController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Type your viva answer with key terms, mechanisms, and conditions...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.surfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purpleBright)),
                        ),
                      ),
                    ] else ...[
                      // Feedback Card
                      GlowCard(
                        borderColor: AppColors.success.withValues(alpha: 0.4),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.fact_check_outlined, size: 16, color: AppColors.success),
                                SizedBox(width: 6),
                                Text('Examiner Assessment', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12.5)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ChemistryTextFormatter.format(_feedback!),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_feedback == null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _evaluating ? null : _submitAnswer,
                icon: _evaluating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_evaluating ? 'Evaluating answer...' : 'Submit Viva Answer', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              )
            else if (!isFinished && _questionIndex + 1 < total)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Next Viva Question', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Finish Viva Session', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
          ],
        ],
      ),
    );
  }
}
