import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/seed_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_by_prajwal.dart';
import '../../core/widgets/branding/chembuddy_logo.dart';
import '../../core/widgets/branding/chembuddy_mascot.dart';
import '../../core/widgets/branding/chembuddy_wordmark.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/models.dart';
import '../../data/remote/supabase_service.dart';
import '../providers/app_providers.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _page = PageController();
  int _index = 0;
  String? _university;
  int _semester = 1;
  final _selected = <String>{
    for (final s in SeedData.mscChemistrySubjects) s.code,
  };
  String _electiveName = 'Open Elective';
  String _customName = '';
  String _customCode = '';
  String _customTeacher = '';

  Future<void> _next() async {
    if (_index == 1 && _university == null) return;
    if (_index < 4) {
      await _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  Future<void> _finishSubjects() async {
    final seeds = SeedData.mscChemistrySubjects.where((s) => _selected.contains(s.code)).toList();
    await ref.read(appControllerProvider.notifier).completeOnboarding(
          university: _university!,
          semester: _semester,
          selectedSeeds: seeds,
          electiveName: _electiveName.trim().isEmpty ? 'Open Elective' : _electiveName.trim(),
        );
    if (_customName.trim().isNotEmpty && _customCode.trim().isNotEmpty) {
      final repo = ref.read(chemRepositoryProvider);
      await ref.read(appControllerProvider.notifier).saveSubject(
            SubjectDraft(
              id: repo.newId(),
              name: _customName.trim(),
              code: _customCode.trim(),
              teacher: _customTeacher.trim(),
            ).toSubject(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              if (_index == 0) ...[
                const SizedBox(height: 8),
              ] else if (_index >= 1 && _index <= 3) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: List.generate(3, (i) {
                      final step = _index - 1;
                      final active = i <= step;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: active
                                ? const LinearGradient(colors: [AppColors.purple, AppColors.blue])
                                : null,
                            color: active ? null : const Color(0xFF2A2D36),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const ChemBuddyLogo(size: 64),
                const SizedBox(height: 8),
                const ChemBuddyWordmark(fontSize: 22),
              ],
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    const _SplashPage(),
                    _UniversityPage(
                      selected: _university,
                      onSelect: (v) => setState(() => _university = v),
                    ),
                    _SemesterPage(
                      selected: _semester,
                      onSelect: (v) => setState(() => _semester = v),
                    ),
                    _SubjectsPage(
                      selected: _selected,
                      electiveName: _electiveName,
                      customName: _customName,
                      customCode: _customCode,
                      customTeacher: _customTeacher,
                      onToggle: (code) => setState(() {
                        if (_selected.contains(code)) {
                          _selected.remove(code);
                        } else {
                          _selected.add(code);
                        }
                      }),
                      onElective: (v) => setState(() => _electiveName = v),
                      onCustomName: (v) => setState(() => _customName = v),
                      onCustomCode: (v) => setState(() => _customCode = v),
                      onCustomTeacher: (v) => setState(() => _customTeacher = v),
                    ),
                    const LoginPage(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _index == 4
                    ? const SizedBox.shrink()
                    : PrimaryButton(
                        label: _index == 0 ? 'Get Started' : 'Continue →',
                        onPressed: _index == 1 && _university == null
                            ? null
                            : () async {
                                if (_index == 3) {
                                  if (_selected.isEmpty) return;
                                  await _finishSubjects();
                                }
                                await _next();
                              },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubjectDraft {
  SubjectDraft({
    required this.id,
    required this.name,
    required this.code,
    required this.teacher,
  });
  final String id;
  final String name;
  final String code;
  final String teacher;

  Subject toSubject() => Subject(id: id, name: name, code: code, teacher: teacher);
}

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(fade);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const ChemBuddyMascot(size: MascotSize.medium, state: MascotState.idle),
              const SizedBox(height: 12),
              const ChemBuddyWordmark(fontSize: 28, showTag: false),
              const SizedBox(height: 4),
              Text(
                'BY PRAJWAL A KAMBAR',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.35), width: 1),
                ),
                child: const Text(
                  '✨ MSc CHEMISTRY INTELLIGENCE',
                  style: TextStyle(
                    color: AppColors.purpleBright,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chem Buddy by Prajwal A Kambar — attendance, tests, and notes for MSc Chemistry students.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Attendance tracker with safe bunk calculations, smart timetable schedules, PDF library, and next-generation chemical sketcher & AI tools.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _FeatureRow(
                      icon: Icons.how_to_reg_rounded,
                      iconColor: Color(0xFF10B981),
                      title: 'Smart Attendance & Safe Bunks',
                      subtitle: 'Live buffer calculation above 75%, bunk limits, and recovery roadmaps.',
                    ),
                    SizedBox(height: 8),
                    _FeatureRow(
                      icon: Icons.calendar_month_rounded,
                      iconColor: Color(0xFFF59E0B),
                      title: 'Organic & Inorganic Timetables',
                      subtitle: 'Preloaded BCU schedules, faculty mapping, and bidirectional stream switching.',
                    ),
                    SizedBox(height: 8),
                    _FeatureRow(
                      icon: Icons.menu_book_rounded,
                      iconColor: Color(0xFF8B5CF6),
                      title: 'PDF Library & Notes Reader',
                      subtitle: 'In-app PDF reader for textbooks, reference materials, syllabus, and notes.',
                    ),
                    SizedBox(height: 8),
                    _FeatureRow(
                      icon: Icons.quiz_rounded,
                      iconColor: Color(0xFFEC4899),
                      title: 'Tests, Quizzes & Exam Revision',
                      subtitle: 'Track internal assessment tests, chapter revision, and mock exam readiness.',
                    ),
                    SizedBox(height: 8),
                    _FeatureRow(
                      icon: Icons.draw_rounded,
                      iconColor: Color(0xFF06B6D4),
                      title: 'ChemDraw Smart Canvas',
                      subtitle: 'Interactive 2D structure sketching, ring templates & reaction prediction.',
                      badge: 'NEW',
                    ),
                    SizedBox(height: 8),
                    _FeatureRow(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: Color(0xFFA855F7),
                      title: 'Live ChemBuddy AI Tutor',
                      subtitle: 'Google Gemini tutor for reaction mechanisms, spectroscopy & exams.',
                      badge: 'AI',
                    ),
                    SizedBox(height: 8),
                    _FeatureRow(
                      icon: Icons.document_scanner_rounded,
                      iconColor: Color(0xFF3B82F6),
                      title: 'Notes to Smart Flashcards',
                      subtitle: 'Snap photos of handwritten notes into active recall flashcard sets.',
                      badge: 'OCR',
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: iconColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversityPage extends StatelessWidget {
  const _UniversityPage({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('STEP 1 OF 3', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const SizedBox(height: 8),
        const Text('Select University', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Choose your institution to personalise your experience', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ...SeedData.universities.map(
          (u) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              borderColor: selected == u ? AppColors.purple : null,
              onTap: () => onSelect(u),
              child: Row(
                children: [
                  Expanded(child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Icon(
                    selected == u ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected == u ? AppColors.purple : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SemesterPage extends StatelessWidget {
  const _SemesterPage({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STEP 2 OF 3', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
          const SizedBox(height: 8),
          const Text('Select Semester', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('MSc Chemistry · four-semester programme', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: SeedData.semesters.map((s) {
                final active = selected == s;
                return GlowCard(
                  borderColor: active ? AppColors.purple : null,
                  onTap: () => onSelect(s),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SEM', style: TextStyle(color: active ? AppColors.purpleBright : AppColors.textMuted, letterSpacing: 2)),
                      Text('$s', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectsPage extends StatelessWidget {
  const _SubjectsPage({
    required this.selected,
    required this.electiveName,
    required this.customName,
    required this.customCode,
    required this.customTeacher,
    required this.onToggle,
    required this.onElective,
    required this.onCustomName,
    required this.onCustomCode,
    required this.onCustomTeacher,
  });

  final Set<String> selected;
  final String electiveName;
  final String customName;
  final String customCode;
  final String customTeacher;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onElective;
  final ValueChanged<String> onCustomName;
  final ValueChanged<String> onCustomCode;
  final ValueChanged<String> onCustomTeacher;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('STEP 3 OF 3', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const SizedBox(height: 8),
        const Text('Select Subjects', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Pre-loaded for MSc Chemistry. Add your own anytime.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ...SeedData.mscChemistrySubjects.map((s) {
          final on = selected.contains(s.code);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              borderColor: on ? AppColors.purple : null,
              onTap: () => onToggle(s.code),
              child: Row(
                children: [
                  Icon(on ? Icons.check_box : Icons.check_box_outline_blank, color: AppColors.purpleBright),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.isElective ? electiveName : s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(s.code, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        const Text('Rename Open Elective', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          onChanged: onElective,
          decoration: const InputDecoration(hintText: 'Open Elective name'),
        ),
        const SizedBox(height: 16),
        const Text('Add a custom subject', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(onChanged: onCustomName, decoration: const InputDecoration(hintText: 'Name')),
        const SizedBox(height: 8),
        TextField(onChanged: onCustomCode, decoration: const InputDecoration(hintText: 'Code')),
        const SizedBox(height: 8),
        TextField(onChanged: onCustomTeacher, decoration: const InputDecoration(hintText: 'Teacher')),
      ],
    );
  }
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final registerNumber = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool signUp = false;
  bool loading = false;
  bool obscurePassword = true;
  String? error;

  @override
  void dispose() {
    registerNumber.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const SizedBox(height: 8),
              // Minimalist Segmented Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AuthTabButton(
                        label: 'Sign In',
                        active: !signUp,
                        onTap: () => setState(() {
                          signUp = false;
                          error = null;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _AuthTabButton(
                        label: 'Create Account',
                        active: signUp,
                        onTap: () => setState(() {
                          signUp = true;
                          error = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title & Minimalist Subtitle
              Text(
                signUp ? 'Create Account' : 'Welcome Back',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                signUp
                    ? 'Join ChemBuddy with your student register number.'
                    : 'Sign in to access your notes, attendance, and AI.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name (Only for Sign Up)
              if (signUp) ...[
                _buildField(
                  controller: name,
                  hintText: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
              ],

              // Register Number
              _buildField(
                controller: registerNumber,
                hintText: 'Register Number (e.g. 2024MSC001)',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),

              // Password
              _buildField(
                controller: password,
                hintText: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                ),
              ),

              // Error Banner
              if (error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              PrimaryButton(
                label: signUp ? 'Create Account' : 'Sign In',
                loading: loading,
                onPressed: () async {
                  final regNum = registerNumber.text.trim();
                  final pwd = password.text;
                  final fullName = name.text.trim();

                  if (signUp && fullName.isEmpty) {
                    setState(() => error = 'Please enter your full name');
                    return;
                  }
                  if (regNum.isEmpty) {
                    setState(() => error = 'Please enter your register number');
                    return;
                  }
                  if (pwd.length < 6) {
                    setState(() => error = 'Password must be at least 6 characters');
                    return;
                  }

                  setState(() {
                    loading = true;
                    error = null;
                  });

                  if (signUp) {
                    final exists = await SupabaseService.instance.registerNumberExists(regNum);
                    if (exists) {
                      if (!mounted) return;
                      setState(() {
                        loading = false;
                        error = 'Register number already registered';
                      });
                      return;
                    }
                  }

                  final result = await ref.read(appControllerProvider.notifier).authenticate(
                        registerNumber: regNum,
                        password: pwd,
                        name: fullName,
                        signUp: signUp,
                      );
                  if (!mounted) return;
                  setState(() {
                    loading = false;
                    error = result;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Bottom Toggle
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    signUp = !signUp;
                    error = null;
                  }),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      children: [
                        TextSpan(text: signUp ? 'Already have an account? ' : 'First time here? '),
                        TextSpan(
                          text: signUp ? 'Sign In' : 'Create Account',
                          style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AppByPrajwal(large: false),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.purple.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(color: AppColors.purpleBright.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
