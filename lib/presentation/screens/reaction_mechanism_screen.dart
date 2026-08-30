import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/chemistry_markdown_view.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/reaction_models.dart';
import '../../data/services/reaction_mechanism_service.dart';
import '../providers/app_providers.dart';
import 'smart_flashcards_generate_screen.dart';

class ReactionMechanismsScreen extends ConsumerStatefulWidget {
  const ReactionMechanismsScreen({super.key, this.initialReactionId});

  final String? initialReactionId;

  @override
  ConsumerState<ReactionMechanismsScreen> createState() => _ReactionMechanismsScreenState();
}

class _ReactionMechanismsScreenState extends ConsumerState<ReactionMechanismsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ReactionCategory? _selectedCategory;
  ReactionMechanism? _selectedMechanism;

  @override
  void initState() {
    super.initState();
    if (widget.initialReactionId != null) {
      _selectedMechanism = ReactionMechanismService.instance.find(widget.initialReactionId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMechanism != null) {
      return _buildDetailView(_selectedMechanism!);
    }

    final query = _searchController.text;
    final list = ReactionMechanismService.instance.search(query, category: _selectedCategory);

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Reaction Mechanisms ⚗️', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search named reactions, reagents, or products...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.purpleBright),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(null, 'All Mechanisms 🧪'),
                  ...ReactionCategory.values.map(
                    (cat) => _buildCategoryChip(cat, '${cat.emoji} ${cat.displayName}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Count Indicator
            Text(
              '${list.length} Verified MSc Mechanisms',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            // Mechanism List
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.science_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text('No mechanisms found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'Try searching for "Aldol", "Cannizzaro", "Wittig", or "Diels-Alder"',
                        style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...list.map((m) => _buildMechanismCard(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ReactionCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.purple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        onSelected: (_) {
          AppHaptics.selection();
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }

  Widget _buildMechanismCard(ReactionMechanism m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowCard(
        onTap: () {
          AppHaptics.tap();
          setState(() => _selectedMechanism = m);
        },
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${m.category.emoji} ${m.category.displayName}',
                    style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 10.5),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
              ],
            ),
            const SizedBox(height: 10),
            Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 6),
            ChemistryMarkdownView(
              text: m.summary,
              textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.timeline, color: AppColors.purpleBright, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${m.steps.length} Stepwise Transformation${m.steps.length == 1 ? "" : "s"}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Detailed Step-by-Step Mechanism View
  Widget _buildDetailView(ReactionMechanism m) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedMechanism = null),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Overview Card
            GlowCard(
              padding: const EdgeInsets.all(18),
              borderColor: AppColors.purple.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${m.category.emoji} ${m.category.displayName}',
                          style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.verified, color: AppColors.success, size: 18),
                      const SizedBox(width: 4),
                      const Text('Verified MSc Mechanism', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ChemistryMarkdownView(
                    text: m.summary,
                    textStyle: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 10),
                  _buildSpecRow('Reactants', m.reactants),
                  const SizedBox(height: 8),
                  _buildSpecRow('Reagents & Conditions', m.reagentsAndConditions),
                  const SizedBox(height: 8),
                  _buildSpecRow('Products', m.products),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Stepwise Mechanism Breakdown
            const Text(
              'Step-by-Step Reaction Mechanism & Electron Movement',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 10),

            ...m.steps.map((step) => _buildStepCard(step)),

            const SizedBox(height: 16),

            // Key Applications
            if (m.keyApplications.isNotEmpty) ...[
              const Text('Synthetic & Academic Applications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
              const SizedBox(height: 8),
              GlowCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: m.keyApplications.map((app) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w900, fontSize: 15)),
                        Expanded(child: ChemistryMarkdownView(text: app, textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SmartFlashcardsGenerateScreen(prefilledTopic: m.name),
                        ),
                      );
                    },
                    icon: const Icon(Icons.style_outlined, size: 18),
                    label: const Text('Generate Flashcards', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref.read(shellTabProvider.notifier).state = 1; // Go to Ask AI
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Ask ChemBuddy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        ChemistryMarkdownView(
          text: value,
          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStepCard(ReactionStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.purple,
                  child: Text('${step.stepNumber}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ChemistryMarkdownView(
              text: step.description,
              textStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
            ),
            if (step.curvedArrowNotes != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('↪ ', style: TextStyle(color: AppColors.purpleBright, fontSize: 14, fontWeight: FontWeight.w900)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CURVED ARROW & ELECTRON MOVEMENT', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          ChemistryMarkdownView(
                            text: step.curvedArrowNotes!,
                            textStyle: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (step.intermediate != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Intermediate: ', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12)),
                  Expanded(
                    child: ChemistryMarkdownView(
                      text: step.intermediate!,
                      textStyle: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
