import '../../core/widgets/expressive_motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/chemistry_text_formatter.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/syllabus_models.dart';
import '../../data/services/syllabus_service.dart';
import '../providers/app_providers.dart';
import 'reaction_mechanism_screen.dart';

class SyllabusBrowserScreen extends ConsumerStatefulWidget {
  const SyllabusBrowserScreen({super.key});

  @override
  ConsumerState<SyllabusBrowserScreen> createState() =>
      _SyllabusBrowserScreenState();
}

class _SyllabusBrowserScreenState extends ConsumerState<SyllabusBrowserScreen> {
  final _service = SyllabusService();

  List<University> _universities = [];
  University _selectedUniversity = SyllabusService.defaultUniversities.first;

  int _selectedSemester = 1;
  List<SyllabusSubject> _subjects = [];
  bool _loading = true;
  String _searchQuery = '';

  final Map<String, List<SyllabusUnit>> _unitsCache = {};
  final Map<String, List<SyllabusTopic>> _topicsCache = {};
  final Set<String> _expandedSubjects = {};
  final Set<String> _expandedUnits = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    final unis = await _service.fetchUniversities();
    final profile = ref.read(appControllerProvider).profile;

    University initialUni = unis.first;
    if (profile.university.isNotEmpty) {
      final matched = unis.where(
        (u) =>
            u.name.toLowerCase().contains(profile.university.toLowerCase()) ||
            profile.university.toLowerCase().contains(u.name.toLowerCase()),
      );
      if (matched.isNotEmpty) {
        initialUni = matched.first;
      }
    }

    _universities = unis;
    _selectedUniversity = initialUni;
    if (profile.semester >= 1 && profile.semester <= 4) {
      _selectedSemester = profile.semester;
    }

    await _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _loading = true);
    final subs = await _service.fetchSubjects(
      _selectedUniversity.id,
      semester: _selectedSemester,
    );
    setState(() {
      _subjects = subs;
      _loading = false;
      _expandedSubjects.clear();
      _expandedUnits.clear();
    });
  }

  Future<void> _toggleSubject(String subjectId) async {
    AppHaptics.selection();
    if (_expandedSubjects.contains(subjectId)) {
      setState(() => _expandedSubjects.remove(subjectId));
    } else {
      setState(() => _expandedSubjects.add(subjectId));
      if (!_unitsCache.containsKey(subjectId)) {
        final units = await _service.fetchUnits(subjectId);
        setState(() => _unitsCache[subjectId] = units);
      }
    }
  }

  Future<void> _toggleUnit(String unitId) async {
    AppHaptics.selection();
    if (_expandedUnits.contains(unitId)) {
      setState(() => _expandedUnits.remove(unitId));
    } else {
      setState(() => _expandedUnits.add(unitId));
      if (!_topicsCache.containsKey(unitId)) {
        final topics = await _service.fetchTopics(unitId);
        setState(() => _topicsCache[unitId] = topics);
      }
    }
  }

  void _showUniversityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select University Curriculum',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your university to align semester papers and topics:',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _universities.length,
                  itemBuilder: (ctx, idx) {
                    final u = _universities[idx];
                    final isSel = u.id == _selectedUniversity.id;
                    return SpringPress(
                      child: ListTile(
                        title: Text(
                          u.name,
                          style: TextStyle(
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${u.state} · ${u.shortName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        trailing: isSel
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedUniversity = u);
                          Navigator.pop(ctx);
                          _loadSubjects();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSubjects = _subjects.where((s) {
      if (_searchQuery.trim().isEmpty) {
        return true;
      }
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          (s.code?.toLowerCase().contains(q) ?? false);
    }).toList();

    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'MSc Chemistry Syllabus',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            SpringPress(
              child: TextButton.icon(
                onPressed: _showUniversityPicker,
                icon: Icon(
                  Icons.school,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  _selectedUniversity.shortName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // University Badge Card
            GlowCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedUniversity.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedUniversity.state} · Official Framework',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SpringPress(
                    child: OutlinedButton(
                      onPressed: _showUniversityPicker,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Semester Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [1, 2, 3, 4].map((sem) {
                  final isSel = _selectedSemester == sem;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SpringPress(
                      child: ChoiceChip(
                        label: Text(
                          'Semester $sem',
                          style: TextStyle(
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSel
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        onSelected: (val) {
                          if (val && _selectedSemester != sem) {
                            setState(() => _selectedSemester = sem);
                            _loadSubjects();
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search subjects or topics...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredSubjects.isEmpty)
              GlowCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No subjects found matching your query.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...filteredSubjects.map((subject) {
                final isExpanded = _expandedSubjects.contains(subject.id);
                final units = _unitsCache[subject.id] ?? [];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SpringPress(
                          child: InkWell(
                            onTap: () => _toggleSubject(subject.id),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    subject.code ?? 'CHEM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (subject.description != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subject.description!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          Divider(
                            height: 20,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          if (units.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...units.map((unit) {
                              final isUnitExpanded = _expandedUnits.contains(
                                unit.id,
                              );
                              final topics = _topicsCache[unit.id] ?? [];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SpringPress(
                                      child: InkWell(
                                        onTap: () => _toggleUnit(unit.id),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.folder_outlined,
                                                size: 18,
                                                color: AppColors.adaptive(
                                                  context,
                                                  AppColors.accentCyan,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  unit.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                isUnitExpanded
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isUnitExpanded) ...[
                                      Divider(
                                        height: 1,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                      if (topics.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Center(
                                            child: SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            children: topics
                                                .map((t) => _buildTopicTile(t))
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTile(SyllabusTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(topic.importanceEmoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChemistryTextFormatter.format(topic.name),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (topic.hasMechanism)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SpringPress(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReactionMechanismsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 12,
                              color: AppColors.adaptive(
                                context,
                                AppColors.accentCyan,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Interactive SVG Mechanism',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.adaptive(
                                  context,
                                  AppColors.accentCyan,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: topic.importanceColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              topic.importance.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.readableText(context, topic.importanceColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
