import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/models/pdf_study_models.dart';
import '../../data/models/reaction_models.dart';
import '../../data/services/reaction_mechanism_service.dart';
import '../providers/app_providers.dart';
import '../widgets/reaction_mechanisms_card.dart';
import 'chemistry_toolkit_screen.dart';
import 'exam_pattern_quiz_screen.dart';
import 'pdf_library_screen.dart';
import 'pdf_reader_screen.dart';
import 'pericyclic_hub_screen.dart';
import 'predict_important_questions_screen.dart';
import 'reaction_mechanism_screen.dart';
import 'smart_flashcards_generate_screen.dart';
import 'smart_flashcards_hub.dart';
import 'spectroscopy_hub_screen.dart';
import 'syllabus_browser_screen.dart';

enum LibrarySection {
  pdfs('PDFs', '📄', 'Textbooks, research papers & notes'),
  reactions('Reactions', '🧪', 'Curated mechanisms & vector diagrams'),
  flashcards('Flashcards', '🗂', 'Active recall decks & spaced repetition'),
  quizzes('Quizzes', '📝', 'Topic mastery & exam practice papers'),
  tools('Tools', '🧮', 'Calculators, spectroscopy & solvers'),
  notes('Notes & Deadlines', '📓', 'Personal notes, seminars & test dates');

  const LibrarySection(this.title, this.icon, this.description);
  final String title;
  final String icon;
  final String description;
}

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  LibrarySection _currentSection = LibrarySection.pdfs;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSectionPicker(BuildContext context) {
    AppHaptics.selection();
    final state = ref.read(appControllerProvider);
    final repo = ref.read(chemRepositoryProvider);

    int totalQuizzes = 0;
    for (final pdf in state.pdfs) {
      totalQuizzes += repo.getPdfQuizzes(pdf.id).length;
    }

    final pdfCount = state.pdfs.length;
    final reactionCount = ReactionMechanismService.instance.mechanisms.length;
    final noteCount = state.notes.length + state.events.length;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Library Sections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...LibrarySection.values.map((section) {
                  final isSelected = _currentSection == section;
                  String countStr;
                  switch (section) {
                    case LibrarySection.pdfs:
                      countStr = '$pdfCount';
                      break;
                    case LibrarySection.reactions:
                      countStr = '$reactionCount';
                      break;
                    case LibrarySection.flashcards:
                      countStr = 'Active';
                      break;
                    case LibrarySection.quizzes:
                      countStr = totalQuizzes > 0 ? '$totalQuizzes' : 'Papers';
                      break;
                    case LibrarySection.tools:
                      countStr = '16 Tools';
                      break;
                    case LibrarySection.notes:
                      countStr = '$noteCount';
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _currentSection = section);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.purple.withValues(alpha: 0.25)
                              : AppColors.surfaceElevated.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.purpleBright : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(section.icon, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.title,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    section.description,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.purple.withValues(alpha: 0.4)
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                countStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppColors.purpleBright : AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.chevron_right,
                              size: 18,
                              color: isSelected ? AppColors.purpleBright : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // ==========================================
        // 1. CLEAN HEADER (LIBRARY + 3-DOT MENU)
        // ==========================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIBRARY',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'MSc Chemistry Knowledge Base',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Semantics(
              label: 'Library sections',
              button: true,
              child: InkWell(
                onTap: () => _showSectionPicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ==========================================
        // 2. SEARCH BAR
        // ==========================================
        TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 13.5, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search PDFs, reactions, flashcards, tools…',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.purpleBright, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ==========================================
        // 3. SEARCH RESULTS OR SECTION CONTENT
        // ==========================================
        if (_searchQuery.isNotEmpty)
          _buildGlobalSearchResults(context, state)
        else ...[
          // Horizontal Section Selector Bar (Direct 1-tap switching)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LibrarySection.values.map((section) {
                final isSel = _currentSection == section;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Text(section.icon, style: const TextStyle(fontSize: 13)),
                    label: Text(
                      section.title,
                      style: TextStyle(
                        color: isSel ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.purple,
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSel ? AppColors.purpleBright : AppColors.borderSubtle,
                    ),
                    onSelected: (val) {
                      if (val) {
                        AppHaptics.selection();
                        setState(() => _currentSection = section);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Main Section Content
          if (_currentSection == LibrarySection.pdfs)
            const PdfLibraryScreen(embedded: true)
          else if (_currentSection == LibrarySection.reactions)
            const _ReactionLibrarySection()
          else if (_currentSection == LibrarySection.flashcards)
            const SmartFlashcardsHub()
          else if (_currentSection == LibrarySection.quizzes)
            const _QuizzesAndMasteryTab()
          else if (_currentSection == LibrarySection.tools)
            const _SmartToolsHub()
          else if (_currentSection == LibrarySection.notes)
            _NotesTab(state: state),
        ],
      ],
    );
  }

  // ==========================================
  // GLOBAL SEARCH (Deterministic, no AI cost)
  // ==========================================
  Widget _buildGlobalSearchResults(BuildContext context, AppState state) {
    final query = _searchQuery.toLowerCase();

    // 1. Filter Reactions
    final matchedReactions = ReactionMechanismService.instance.mechanisms.where((m) {
      return m.name.toLowerCase().contains(query) ||
          m.summary.toLowerCase().contains(query) ||
          m.aliases.any((a) => a.toLowerCase().contains(query));
    }).toList();

    // 2. Filter PDFs
    final matchedPdfs = state.pdfs.where((p) {
      return p.displayName.toLowerCase().contains(query) ||
          p.filename.toLowerCase().contains(query);
    }).toList();

    // 3. Filter Tools
    final toolsCatalog = [
      ('Molar Mass & Chemical Names', 'Calculations', Icons.scale, 0),
      ('Molarity & Normality Calculator', 'Calculations', Icons.water_drop, 0),
      ('Dilution Calculator (M1V1 = M2V2)', 'Calculations', Icons.opacity, 0),
      ('pH & Buffer Calculator', 'Acid-Base', Icons.science, 1),
      ('Gibbs Free Energy & Thermo', 'Thermodynamics', Icons.local_fire_department, 2),
      ('Arrhenius Kinetics (Ea)', 'Kinetics', Icons.speed, 2),
      ('Beer-Lambert & Spectroscopy', 'Spectroscopy', Icons.lightbulb, 3),
      ('Nernst Equation & Cell Potential', 'Electrochem', Icons.bolt, 4),
      ('Degree of Unsaturation (DBE / IHD)', 'Spectroscopy', Icons.calculate, -1),
      ('Spectroscopy Structure Solver', 'Spectroscopy', Icons.analytics, -1),
      ('Pericyclic Reactions & FMO Analysis', 'Advanced Organic', Icons.autorenew, -2),
      ('University Important PYQ Predictor', 'Exams', Icons.psychology, -3),
      ('MSc University Syllabus Browser', 'Curriculum', Icons.menu_book, -4),
    ];
    final matchedTools = toolsCatalog.where((t) {
      return t.$1.toLowerCase().contains(query) || t.$2.toLowerCase().contains(query);
    }).toList();

    // 4. Filter Notes
    final matchedNotes = state.notes.where((n) {
      return n.title.toLowerCase().contains(query) || n.body.toLowerCase().contains(query);
    }).toList();

    final hasAny = matchedReactions.isNotEmpty ||
        matchedPdfs.isNotEmpty ||
        matchedTools.isNotEmpty ||
        matchedNotes.isNotEmpty;

    if (!hasAny) {
      return GlowCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No matches found for "$_searchQuery"',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching for a reaction name (e.g. "Beckmann"), formula ("C6H6"), tool ("DBE"), or topic.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results (${matchedReactions.length + matchedPdfs.length + matchedTools.length + matchedNotes.length})',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),

        // Reactions
        if (matchedReactions.isNotEmpty) ...[
          const _SearchResultHeader(title: 'Reactions', icon: '🧪'),
          ...matchedReactions.map((r) => _SearchResultTile(
                title: r.name,
                subtitle: r.summary,
                badge: 'REACTION',
                badgeColor: AppColors.purpleBright,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReactionMechanismsScreen(initialReactionId: r.id)),
                ),
              )),
          const SizedBox(height: 12),
        ],

        // Tools
        if (matchedTools.isNotEmpty) ...[
          const _SearchResultHeader(title: 'Tools & Solvers', icon: '🧮'),
          ...matchedTools.map((t) => _SearchResultTile(
                title: t.$1,
                subtitle: t.$2,
                badge: 'TOOL',
                badgeColor: AppColors.accentCyan,
                onTap: () {
                  if (t.$4 == -1) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SpectroscopyHubScreen()));
                  } else if (t.$4 == -2) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PericyclicHubScreen()));
                  } else if (t.$4 == -3) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictImportantQuestionsScreen()));
                  } else if (t.$4 == -4) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SyllabusBrowserScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChemistryToolkitScreen(initialCategory: t.$4)));
                  }
                },
              )),
          const SizedBox(height: 12),
        ],

        // PDFs
        if (matchedPdfs.isNotEmpty) ...[
          const _SearchResultHeader(title: 'PDF Documents', icon: '📄'),
          ...matchedPdfs.map((p) => _SearchResultTile(
                title: p.displayName,
                subtitle: 'Added ${DateFormat("d MMM yyyy").format(p.dateAdded)} · ${(p.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                badge: 'PDF',
                badgeColor: AppColors.accentGold,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PdfReaderScreen(doc: p)),
                ),
              )),
          const SizedBox(height: 12),
        ],

        // Notes
        if (matchedNotes.isNotEmpty) ...[
          const _SearchResultHeader(title: 'Notes', icon: '📓'),
          ...matchedNotes.map((n) => _SearchResultTile(
                title: n.title,
                subtitle: n.body,
                badge: 'NOTE',
                badgeColor: AppColors.success,
                onTap: () {
                  setState(() => _currentSection = LibrarySection.notes);
                  _searchController.clear();
                },
              )),
        ],
      ],
    );
  }
}

class _SearchResultHeader extends StatelessWidget {
  const _SearchResultHeader({required this.title, required this.icon});
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlowCard(
        padding: const EdgeInsets.all(12),
        onTap: () {
          AppHaptics.confirm();
          onTap();
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: badgeColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. REACTION LIBRARY SECTION
// ==========================================
class _ReactionLibrarySection extends StatefulWidget {
  const _ReactionLibrarySection();

  @override
  State<_ReactionLibrarySection> createState() => _ReactionLibrarySectionState();
}

class _ReactionLibrarySectionState extends State<_ReactionLibrarySection> {
  final _searchCtrl = TextEditingController();
  ReactionCategory? _filterCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    var list = ReactionMechanismService.instance.mechanisms;
    if (_filterCategory != null) {
      list = list.where((m) => m.category == _filterCategory).toList();
    }
    if (query.isNotEmpty) {
      list = list.where((m) =>
          m.name.toLowerCase().contains(query) ||
          m.summary.toLowerCase().contains(query) ||
          m.aliases.any((a) => a.toLowerCase().contains(query))).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReactionMechanismsCard(compact: false),
        const SizedBox(height: 16),

        // Subcategory Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Mechanisms'),
                selected: _filterCategory == null,
                onSelected: (_) => setState(() => _filterCategory = null),
              ),
              const SizedBox(width: 8),
              ...ReactionCategory.values.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.displayName),
                      selected: _filterCategory == cat,
                      onSelected: (_) => setState(() => _filterCategory = cat),
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 12),

        ...list.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlowCard(
                padding: const EdgeInsets.all(14),
                onTap: () {
                  AppHaptics.confirm();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReactionMechanismsScreen(initialReactionId: m.id),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('⚗️', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.category.displayName,
                            style: const TextStyle(color: AppColors.purpleBright, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            )),

        const SizedBox(height: 14),
        const GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why Verified Reaction SVGs?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white)),
              SizedBox(height: 8),
              Text(
                'AI text generators often hallucinate chemical structures. ChemBuddy\'s Reaction Engine pairs curated, peer-reviewed reaction mechanisms rendered in vector SVG format with step-by-step electron arrow pushing for 100% academic precision.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 5. SMART TOOLS HUB (Calculations, Spectroscopy, Organic)
// ==========================================
class _SmartToolsHub extends StatefulWidget {
  const _SmartToolsHub();

  @override
  State<_SmartToolsHub> createState() => _SmartToolsHubState();
}

class _SmartToolsHubState extends State<_SmartToolsHub> {
  final _toolSearchCtrl = TextEditingController();
  String _toolQuery = '';

  @override
  void initState() {
    super.initState();
    _toolSearchCtrl.addListener(() {
      setState(() => _toolQuery = _toolSearchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _toolSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Chemistry Tools',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 2),
        const Text(
          'Tools for calculations, reactions, spectroscopy & exams',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),

        // Tool Search Input
        TextField(
          controller: _toolSearchCtrl,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search for a chemistry tool (e.g. molar mass, DBE, Nernst, pH)...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            prefixIcon: const Icon(Icons.build_circle_outlined, color: AppColors.purpleBright, size: 18),
            suffixIcon: _toolQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                    onPressed: () => _toolSearchCtrl.clear(),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purpleBright)),
          ),
        ),

        const SizedBox(height: 16),

        // RECENTLY USED
        const Text(
          'RECENTLY USED',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ActionChip(
              avatar: const Icon(Icons.scale, size: 14, color: AppColors.purpleBright),
              label: const Text('Molar Mass', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.surfaceElevated,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 0))),
            ),
            ActionChip(
              avatar: const Icon(Icons.calculate, size: 14, color: AppColors.accentCyan),
              label: const Text('DBE / IHD Calculator', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.surfaceElevated,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpectroscopyHubScreen())),
            ),
            ActionChip(
              avatar: const Icon(Icons.bolt, size: 14, color: AppColors.accentGold),
              label: const Text('Nernst Equation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.surfaceElevated,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 4))),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // FREQUENTLY USED
        const Text(
          'FREQUENTLY USED',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QuickToolCard(
                title: 'Molarity & Dilution',
                subtitle: 'Concentrations & solutions',
                icon: Icons.water_drop,
                iconColor: AppColors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 0))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickToolCard(
                title: 'Structure Solver',
                subtitle: '8-step IR/NMR deduction',
                icon: Icons.analytics,
                iconColor: AppColors.purpleBright,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpectroscopyHubScreen())),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 1. CALCULATIONS CATEGORY
        if (_shouldShow('calculations', ['molar mass', 'stoichiometry', 'moles', 'yield', 'conversion', 'molarity', 'normality', 'dilution', 'ph', 'buffer', 'titration'])) ...[
          const _ToolCategoryHeader(title: 'CALCULATIONS & STOICHIOMETRY', icon: '🧮'),
          _ToolListTile(
            title: 'Stoichiometry & Unit Conversions',
            subtitle: 'Mass ⇄ mole ⇄ particles, gas volume at STP, percent yield & chemical units',
            icon: Icons.sync_alt,
            iconColor: AppColors.accentCyan,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 1))),
          ),
          _ToolListTile(
            title: 'Molar Mass Calculator',
            subtitle: 'Supports chemical names (e.g. benzoic acid) & formulas (CuSO4·5H2O)',
            icon: Icons.scale,
            iconColor: AppColors.purpleBright,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 0))),
          ),
          _ToolListTile(
            title: 'Molarity & Normality',
            subtitle: 'Solute mass, volume, molarity and normality with valence factor',
            icon: Icons.water_drop_outlined,
            iconColor: AppColors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 0))),
          ),
          _ToolListTile(
            title: 'Dilution Calculator',
            subtitle: 'M1 × V1 = M2 × V2 standard solution dilution',
            icon: Icons.opacity,
            iconColor: AppColors.accentCyan,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 0))),
          ),
          _ToolListTile(
            title: 'pH & Henderson-Hasselbalch Buffer',
            subtitle: 'Weak acid/base equilibria, buffer capacity and pKa calculations',
            icon: Icons.science_outlined,
            iconColor: AppColors.accentGold,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 2))),
          ),
          const SizedBox(height: 16),
        ],

        // 2. PHYSICAL / INORGANIC
        if (_shouldShow('physical', ['gibbs', 'delta g', 'nernst', 'cell potential', 'arrhenius', 'kinetics', 'beer lambert', 'thermo'])) ...[
          const _ToolCategoryHeader(title: 'PHYSICAL / INORGANIC', icon: '⚡'),
          _ToolListTile(
            title: 'Gibbs Free Energy (ΔG = ΔH - TΔS)',
            subtitle: 'Spontaneity analysis, enthalpy, entropy & temperature dependence',
            icon: Icons.local_fire_department,
            iconColor: Colors.deepOrangeAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 3))),
          ),
          _ToolListTile(
            title: 'Arrhenius Activation Energy (Ea)',
            subtitle: 'Two-temperature rate constant ratios & reaction kinetics',
            icon: Icons.speed,
            iconColor: Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 3))),
          ),
          _ToolListTile(
            title: 'Nernst Equation & Cell Potential',
            subtitle: 'Non-standard EMF, reaction quotient Q and transfer electrons n',
            icon: Icons.bolt,
            iconColor: AppColors.accentGold,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 5))),
          ),
          _ToolListTile(
            title: 'Beer-Lambert & Photon Energy (E = hν)',
            subtitle: 'Spectrophotometric absorbance A = ε·c·l and photon transitions',
            icon: Icons.lightbulb_outline,
            iconColor: Colors.tealAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChemistryToolkitScreen(initialCategory: 4))),
          ),
          const SizedBox(height: 16),
        ],

        // 3. SPECTROSCOPY
        if (_shouldShow('spectroscopy', ['dbe', 'ihd', 'nmr', 'ir', 'mass spec', 'spectroscopy', 'structure solver'])) ...[
          const _ToolCategoryHeader(title: 'SPECTROSCOPY', icon: '🧲'),
          _ToolListTile(
            title: 'DBE / IHD Calculator',
            subtitle: 'Degree of unsaturation with valence limits & halogen support',
            icon: Icons.calculate,
            iconColor: AppColors.accentCyan,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpectroscopyHubScreen())),
          ),
          _ToolListTile(
            title: 'Academic Structure Deduction Engine',
            subtitle: '8-step unified deduction from molecular formula, IR, NMR & MS',
            icon: Icons.analytics,
            iconColor: AppColors.purpleBright,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpectroscopyHubScreen())),
          ),
          _ToolListTile(
            title: 'FT-IR Diagnostic Bands & 1H/13C NMR Tables',
            subtitle: 'Carbonyl frequencies, fingerprint region, chemical shift ranges',
            icon: Icons.table_chart,
            iconColor: Colors.lightGreenAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpectroscopyHubScreen())),
          ),
          const SizedBox(height: 16),
        ],

        // 4. ORGANIC & ADVANCED
        if (_shouldShow('organic', ['reactions', 'pericyclic', 'fmo', 'woodward', 'predict', 'pyq', 'syllabus'])) ...[
          const _ToolCategoryHeader(title: 'ORGANIC & ADVANCED', icon: '🌀'),
          _ToolListTile(
            title: 'Reaction Mechanisms & Vector SVGs',
            subtitle: 'Curated reaction database, curved electron arrows & conditions',
            icon: Icons.biotech,
            iconColor: AppColors.brandBright,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReactionMechanismsScreen())),
          ),
          _ToolListTile(
            title: 'Pericyclic Mechanisms & FMO Analysis',
            subtitle: 'Woodward-Hoffmann rules, electrocyclic, cycloadditions, sigmatropic',
            icon: Icons.autorenew,
            iconColor: AppColors.purpleBright,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PericyclicHubScreen())),
          ),
          _ToolListTile(
            title: 'University PYQ Question Predictor',
            subtitle: 'Topic probability modeling based on previous examination patterns',
            icon: Icons.psychology,
            iconColor: AppColors.accentGold,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PredictImportantQuestionsScreen())),
          ),
          _ToolListTile(
            title: 'MSc University Syllabus Browser',
            subtitle: 'Official semester units, core papers, elective modules & references',
            icon: Icons.menu_book,
            iconColor: Colors.tealAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyllabusBrowserScreen())),
          ),
        ],
      ],
    );
  }

  bool _shouldShow(String categoryName, List<String> keywords) {
    if (_toolQuery.isEmpty) return true;
    if (categoryName.contains(_toolQuery)) return true;
    return keywords.any((k) => k.contains(_toolQuery) || _toolQuery.contains(k));
  }
}

class _ToolCategoryHeader extends StatelessWidget {
  const _ToolCategoryHeader({required this.title, required this.icon});
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  const _QuickToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(12),
      onTap: () {
        AppHaptics.confirm();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ToolListTile extends StatelessWidget {
  const _ToolListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlowCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () {
          AppHaptics.confirm();
          onTap();
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. QUIZZES AND MASTERY
// ==========================================
class _QuizzesAndMasteryTab extends ConsumerWidget {
  const _QuizzesAndMasteryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(chemRepositoryProvider);
    final allPdfs = ref.watch(appControllerProvider).pdfs;
    final allQuizzes = <ChemistryQuiz>[];
    for (final pdf in allPdfs) {
      allQuizzes.addAll(repo.getPdfQuizzes(pdf.id));
    }

    final examCard = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowCard(
        borderColor: AppColors.accentGold.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(14),
        onTap: () {
          AppHaptics.confirm();
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ExamPatternQuizScreen()));
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.accentGold, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('University Exam Pattern Paper 📝', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Practice authentic 2M, 5M, and 10M questions with model marking schemes.', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.accentGold, size: 20),
          ],
        ),
      ),
    );

    if (allQuizzes.isEmpty) {
      return Column(
        children: [
          examCard,
          const GlowCard(
            child: Column(
              children: [
                Icon(Icons.quiz_outlined, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No Quiz History Yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  'Take a quiz from any uploaded PDF notes to track your Strong 🟢, Moderate 🟡, and Weak 🔴 chemistry topic mastery here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        examCard,
        const Text('Chemistry Topic Mastery 🧠', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        const Text(
          'Adaptive tracking based on your PDF quiz performance:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...allQuizzes.take(5).map((q) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlowCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, size: 18, color: AppColors.purpleBright),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${q.questionCount} Questions',
                            style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Source: ${q.sourceFileName} · ${DateFormat("d MMM yyyy").format(q.createdAt)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ==========================================
// 7. EVENTS & DEADLINES
// ==========================================
class _EventsTab extends ConsumerWidget {
  const _EventsTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = state.events;
    return Column(
      children: [
        PrimaryButton(
          label: 'Add test or assignment',
          onPressed: () => _editEvent(context, ref),
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          const GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.event_note, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No deadlines yet.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text('Add a test, assignment, or seminar to track it here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ...events.map((e) {
          String? subjectName;
          for (final s in state.subjects) {
            if (s.id == e.subjectId) subjectName = s.name;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () => _editEvent(context, ref, existing: e),
              child: Row(
                children: [
                  Checkbox(
                    value: e.completed,
                    activeColor: AppColors.purple,
                    onChanged: (v) => ref.read(appControllerProvider.notifier).saveEvent(e.copyWith(completed: v ?? false)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: e.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          '${e.type.name.toUpperCase()} · ${DateFormat('d MMM yyyy').format(e.dueDate)}${subjectName == null ? '' : ' · $subjectName'}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (!e.completed) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => SmartFlashcardsGenerateScreen(
                                  prefilledTopic: '${e.title}${subjectName != null ? ' ($subjectName)' : ''}',
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.school, size: 16, color: AppColors.purpleBright),
                            label: const Text('Study for this', style: TextStyle(color: AppColors.purpleBright, fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(appControllerProvider.notifier).deleteEvent(e.id),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _editEvent(BuildContext context, WidgetRef ref, {AcademicEvent? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    var type = existing?.type ?? EventType.test;
    var due = existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    String? subjectId = existing?.subjectId;
    final subjects = ref.read(appControllerProvider).subjects;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(existing == null ? 'New deadline' : 'Edit deadline', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(controller: title, decoration: const InputDecoration(hintText: 'Title')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EventType>(
                      initialValue: type,
                      items: EventType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                          .toList(),
                      onChanged: (v) => setModal(() => type = v ?? type),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: subjectId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No subject')),
                        ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setModal(() => subjectId = v),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Due ${DateFormat('d MMM yyyy').format(due)}'),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: due,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setModal(() => due = picked);
                      },
                    ),
                    TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(hintText: 'Description')),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Save',
                      onPressed: () async {
                        if (title.text.trim().isEmpty) return;
                        final repo = ref.read(chemRepositoryProvider);
                        await ref.read(appControllerProvider.notifier).saveEvent(
                              AcademicEvent(
                                id: existing?.id ?? repo.newId(),
                                title: title.text.trim(),
                                type: type,
                                dueDate: due,
                                subjectId: subjectId,
                                description: desc.text.trim(),
                                completed: existing?.completed ?? false,
                              ),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ==========================================
// 8. NOTES
// ==========================================
class _NotesTab extends ConsumerWidget {
  const _NotesTab({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EventsTab(state: state),
        const SizedBox(height: 24),
        const Text('Daily Chemistry Notes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        PrimaryButton(label: 'New note', onPressed: () => _editNote(context, ref)),
        const SizedBox(height: 16),
        if (state.notes.isEmpty)
          const GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.notes, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No notes yet.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text('Day-to-day notes will show up here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ...state.notes.map((n) {
          String? tag;
          for (final s in state.subjects) {
            if (s.id == n.subjectId) tag = s.code;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              onTap: () => _editNote(context, ref, existing: n),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800))),
                      IconButton(
                        tooltip: 'Flashcard',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SmartFlashcardsGenerateScreen(
                              prefilledTopic: n.title,
                              prefilledText: n.body,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.style_outlined, color: AppColors.purpleBright),
                      ),
                      IconButton(
                        onPressed: () => ref.read(appControllerProvider.notifier).deleteNote(n.id),
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      ),
                    ],
                  ),
                  Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('d MMM, h:mm a').format(n.updatedAt)}${tag == null ? '' : ' · $tag'}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref, {NoteItem? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    String? subjectId = existing?.subjectId;
    final subjects = ref.read(appControllerProvider).subjects;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Text(existing == null ? 'New note' : 'Edit note', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 12),
                    TextField(controller: title, decoration: const InputDecoration(hintText: 'Title')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: subjectId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No subject tag')),
                        ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (v) => setModal(() => subjectId = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: body, maxLines: 6, decoration: const InputDecoration(hintText: 'Write your note…')),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Save',
                      onPressed: () async {
                        if (title.text.trim().isEmpty) return;
                        final repo = ref.read(chemRepositoryProvider);
                        await ref.read(appControllerProvider.notifier).saveNote(
                              NoteItem(
                                id: existing?.id ?? repo.newId(),
                                title: title.text.trim(),
                                body: body.text.trim(),
                                subjectId: subjectId,
                                updatedAt: DateTime.now(),
                              ),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
