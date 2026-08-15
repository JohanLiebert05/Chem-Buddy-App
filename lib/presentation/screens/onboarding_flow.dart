import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/seed_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_by_prajwal.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';
import '../../data/models/models.dart';
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
                const AtomLogo(size: 72),
                Text(
                  'CHEMVERSE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.purpleBright,
                  ),
                ),
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

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          const AtomLogo(size: 120),
          const SizedBox(height: 16),
          Text(
            'CHEMBUDDY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppColors.purpleBright,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'CHEMVERSE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              letterSpacing: 4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const AppByPrajwal(large: true),
          const SizedBox(height: 12),
          const Text(
            'Your MSc Chemistry companion for attendance, tests, and notes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(flex: 2),
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
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool signUp = true;
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            children: [
              Text(signUp ? 'Create your account' : 'Welcome back', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Continue with Google or your roll number.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              GlowCard(
                onTap: () async {
                  setState(() => loading = true);
                  await ref.read(appControllerProvider.notifier).authenticate(
                        email: 'student@chembuddy.app',
                        password: 'google-sso',
                        name: name.text.trim().isEmpty ? 'Student' : name.text.trim(),
                        signUp: true,
                      );
                  if (mounted) setState(() => loading = false);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata, size: 32, color: AppColors.blue),
                    SizedBox(width: 8),
                    Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('or', style: TextStyle(color: AppColors.textMuted))),
              const SizedBox(height: 16),
              TextField(controller: name, decoration: const InputDecoration(hintText: 'Full name')),
              const SizedBox(height: 10),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Roll number or email')),
              const SizedBox(height: 10),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Password')),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: signUp ? 'Create account' : 'Log in',
                loading: loading,
                onPressed: () async {
                  setState(() {
                    loading = true;
                    error = null;
                  });
                  final result = await ref.read(appControllerProvider.notifier).authenticate(
                        email: email.text.trim(),
                        password: password.text,
                        name: name.text.trim(),
                        signUp: signUp,
                      );
                  if (!mounted) return;
                  setState(() {
                    loading = false;
                    error = result;
                  });
                },
              ),
              TextButton(
                onPressed: () => setState(() => signUp = !signUp),
                child: Text(signUp ? 'Already have an account? Log in' : 'New here? Create an account'),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: AppByPrajwal(large: true),
        ),
      ],
    );
  }
}
