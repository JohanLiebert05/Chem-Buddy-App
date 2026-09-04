import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/chemistry_text_formatter.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../core/widgets/molecule_loader.dart';
import '../../data/models/pyq_predict_models.dart';
import '../../data/services/pyq_predict_service.dart';
import '../providers/app_providers.dart';

class PredictImportantQuestionsScreen extends ConsumerStatefulWidget {
  const PredictImportantQuestionsScreen({super.key});

  @override
  ConsumerState<PredictImportantQuestionsScreen> createState() =>
      _PredictImportantQuestionsScreenState();
}

class _PredictImportantQuestionsScreenState
    extends ConsumerState<PredictImportantQuestionsScreen> {
  final _service = PyqPredictService();
  final _subjectController = TextEditingController();
  final _universityController = TextEditingController();
  final _yearRangeController = TextEditingController();

  final List<PlatformFile> _selectedFiles = [];
  bool _isAnalyzing = false;
  String _statusText = 'Preparing analysis...';
  double _progress = 0.0;
  String? _errorMessage;

  ImportantQuestionsPrediction? _currentPrediction;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appControllerProvider).profile;
    if (profile.university.isNotEmpty) {
      _universityController.text = profile.university;
    }
    final subjects = ref.read(appControllerProvider).subjects;
    if (subjects.isNotEmpty) {
      _subjectController.text = subjects.first.name;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _universityController.dispose();
    _yearRangeController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final f in result.files) {
            if (!_selectedFiles.any((existing) => existing.name == f.name)) {
              _selectedFiles.add(f);
            }
          }
          _errorMessage = null;
        });
        AppHaptics.confirm();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Could not access file picker: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    AppHaptics.tap();
  }

  Future<void> _startAnalysis() async {
    if (_selectedFiles.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 3 question papers for accurate pattern prediction.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the subject name.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _progress = 0.05;
      _statusText = 'Starting extraction from ${_selectedFiles.length} papers...';
    });

    try {
      final paths = _selectedFiles.map((f) => f.path ?? '').where((p) => p.isNotEmpty).toList();
      final names = _selectedFiles.map((f) => f.name).toList();

      final prediction = await _service.analyzeAndPredict(
        filePaths: paths,
        fileNames: names,
        subjectName: _subjectController.text.trim(),
        universityName: _universityController.text.trim(),
        yearRange: _yearRangeController.text.trim(),
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _statusText = status;
              _progress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _currentPrediction = prediction;
          _isAnalyzing = false;
        });
        AppHaptics.confirm();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
        AppHaptics.warning();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Predict Important Questions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            if (_currentPrediction != null)
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.purpleBright),
                tooltip: 'Analyze New Papers',
                onPressed: () {
                  setState(() {
                    _currentPrediction = null;
                    _selectedFiles.clear();
                  });
                },
              ),
          ],
        ),
        body: _isAnalyzing
            ? _buildAnalyzingState()
            : _currentPrediction != null
                ? _buildResultsView(_currentPrediction!)
                : _buildUploadView(),
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BenzeneMoleculeLoader(size: 90, color: AppColors.purpleBright),
            const SizedBox(height: 32),
            Text(
              'Exam Question Prediction Engine',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _statusText,
              style: const TextStyle(fontSize: 14, color: AppColors.purpleBright),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 6,
                backgroundColor: AppColors.bg2,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purpleBright),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analyzing past year question papers to uncover high-frequency trends, core reaction mechanisms, and mark weightage.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadView() {
    final pastPredictions = _service.getPastPredictions();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: AppColors.purpleBright, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Question Predictor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Upload ≥ 3 PYQ papers to detect patterns', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload 3 or more previous year question paper PDFs from your university. The system analyzes recurring questions, core concepts, and predicts high-probability exam topics.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Inputs Card
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paper Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g. Advanced Organic Chemistry',
                  prefixIcon: Icon(Icons.menu_book, color: AppColors.purpleBright, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _universityController,
                decoration: const InputDecoration(
                  labelText: 'University Name (Optional)',
                  hintText: 'e.g. University of Mumbai / General',
                  prefixIcon: Icon(Icons.school, color: AppColors.purpleBright, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearRangeController,
                decoration: const InputDecoration(
                  labelText: 'Papers Year Range (Optional)',
                  hintText: 'e.g. 2021 – 2024',
                  prefixIcon: Icon(Icons.date_range, color: AppColors.purpleBright, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Files Card
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Upload Question Papers (PDF)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedFiles.length >= 3
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_selectedFiles.length} of 3 min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedFiles.length >= 3 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_selectedFiles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderHighlight, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.bg0.withValues(alpha: 0.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file_rounded, size: 40, color: AppColors.purpleBright),
                      const SizedBox(height: 8),
                      const Text('Select at least 3 PYQ PDFs to begin', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickPdfs,
                        icon: const Icon(Icons.add),
                        label: const Text('Select PDF Papers'),
                      ),
                    ],
                  ),
                )
              else ...[
                Column(
                  children: _selectedFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                            onPressed: () => _removeFile(index),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickPdfs,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Another Paper'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              ],
            ),
          ),

        // Action Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _selectedFiles.length >= 3 ? _startAnalysis : null,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              _selectedFiles.length >= 3
                  ? 'Analyze & Predict Questions (${_selectedFiles.length} Papers)'
                  : 'Add ${_selectedFiles.length < 3 ? 3 - _selectedFiles.length : 0} More Paper(s) to Analyze',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Past Predictions Section
        if (pastPredictions.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text('Past Predictions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...pastPredictions.map((pred) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlowCard(
                  onTap: () {
                    setState(() => _currentPrediction = pred);
                    AppHaptics.selection();
                  },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics, color: AppColors.purpleBright, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pred.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            '${pred.paperCount} papers · ${pred.predictedQuestions.length} predicted questions · ${DateFormat.MMMd().format(pred.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                      onPressed: () async {
                        await _service.deletePrediction(pred.id);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            )),
        ],
      ],
    );
  }

  Widget _buildResultsView(ImportantQuestionsPrediction pred) {
    final filteredQuestions = pred.predictedQuestions.where((q) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == '2 Marks') return q.marks == 2;
      if (_selectedFilter == '5 Marks') return q.marks == 5;
      if (_selectedFilter == '10 Marks') return q.marks == 10;
      if (_selectedFilter == 'Mechanism') return q.questionType == 'mechanism';
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // Header Summary
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pred.subjectName,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (pred.isCached)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('⚡ Cached Analysis', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${pred.universityName} · Based on ${pred.paperCount} Question Papers',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg0,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderHighlight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 18),
                        SizedBox(width: 6),
                        Text('Exam Strategy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pred.examStrategy,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Frequently Asked Topics
        if (pred.frequentlyAskedTopics.isNotEmpty) ...[
          const Text('Recurring High-Frequency Topics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: pred.frequentlyAskedTopics.map((t) {
                Color tagColor = AppColors.blue;
                if (t.importance == 'very_high') tagColor = AppColors.danger;
                if (t.importance == 'high') tagColor = AppColors.warning;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bg1,
                    border: Border.all(color: tagColor.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.importance == 'very_high' ? '🔥 ' : '📌 ',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        t.topic,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${t.appearedCount}x',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tagColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Filter Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Predicted Questions (${filteredQuestions.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', '2 Marks', '5 Marks', '10 Marks', 'Mechanism'].map((f) {
              final isSel = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : AppColors.textSecondary)),
                  selected: isSel,
                  selectedColor: AppColors.brandPrimary,
                  backgroundColor: AppColors.bg2,
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = f);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Questions List
        ...filteredQuestions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          return _PredictedQuestionCard(index: idx + 1, question: q);
        }),

        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _currentPrediction = null;
              _selectedFiles.clear();
            });
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Analyze Different Papers'),
        ),
      ],
    );
  }
}

class _PredictedQuestionCard extends StatefulWidget {
  const _PredictedQuestionCard({required this.index, required this.question});
  final int index;
  final PredictedQuestion question;

  @override
  State<_PredictedQuestionCard> createState() => _PredictedQuestionCardState();
}

class _PredictedQuestionCardState extends State<_PredictedQuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    Color marksColor = AppColors.blue;
    if (q.marks == 2) marksColor = AppColors.accentCyan;
    if (q.marks == 5) marksColor = AppColors.warning;
    if (q.marks >= 10) marksColor = AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: marksColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${q.marks} MARKS',
                  style: TextStyle(color: marksColor, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              if (q.importance == 'very_high')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('🔥 HIGH PROBABILITY', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              Text(
                q.topic,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            'Q${widget.index}. ${ChemistryTextFormatter.format(q.question)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.35),
          ),
          if (q.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Trend rationale: ${q.reason}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
            ),
          ],
          if (q.modelAnswerHints.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.purpleBright,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded ? 'Hide Model Answer Hints' : 'View Model Answer Key Points (${q.modelAnswerHints.length})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purpleBright),
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg0,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: q.modelAnswerHints.map((hint) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.purpleBright, fontSize: 13)),
                            Expanded(
                              child: Text(
                                ChemistryTextFormatter.format(hint),
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                ),
              ),
          ],
        ],
      ),
    ));
  }
}
