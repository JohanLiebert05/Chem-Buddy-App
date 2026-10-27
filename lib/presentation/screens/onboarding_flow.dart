import '../../core/widgets/expressive_motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_identity.dart';
import '../../core/constants/seed_data.dart';
import '../../core/widgets/branding/chembuddy_logo.dart';
import '../../core/widgets/hex_background.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../data/models/models.dart';
import '../providers/app_providers.dart';
import 'appearance_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 0;
  bool _saving = false;
  String? _university;
  int _semester = 1;
  final _selected = {
    for (final subject in SeedData.mscChemistrySubjects) subject.code,
  };
  final _elective = TextEditingController(text: 'Open Elective');
  final _customName = TextEditingController();
  final _customCode = TextEditingController();
  final _customTeacher = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _elective.dispose();
    _customName.dispose();
    _customCode.dispose();
    _customTeacher.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) {
      return;
    }
    if (_step < 2) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    if (_selected.isEmpty && _customName.text.trim().isEmpty) {
      setState(() => _error = 'Choose at least one subject to start.');
      return;
    }
    if (_customName.text.trim().isNotEmpty && _customCode.text.trim().isEmpty) {
      setState(() => _error = 'Add a code for your custom subject.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final customName = _customName.text.trim();
      final customCode = _customCode.text.trim();
      final customTeacher = _customTeacher.text.trim();
      final elective = _elective.text.trim();
      // Finish every write before marking onboarding complete; the app then opens Login.
      final repo = ref.read(chemRepositoryProvider);
      if (repo.subjects().isEmpty) {
        final seeds = SeedData.mscChemistrySubjects
            .where((s) => _selected.contains(s.code))
            .toList();
        await repo.seedSubjects(
          seeds,
          electiveName: elective.isEmpty ? 'Open Elective' : elective,
        );
      }
      if (customName.isNotEmpty) {
        final existing = repo
            .subjects()
            .where(
              (subject) =>
                  subject.code.toLowerCase() == customCode.toLowerCase(),
            )
            .firstOrNull;
        await repo.upsertSubject(
          SubjectDraft(
            id: existing?.id ?? repo.newId(),
            name: customName,
            code: customCode,
            teacher: customTeacher,
          ).toSubject(),
        );
      }
      if (!mounted) {
        return;
      }
      await ref
          .read(appControllerProvider.notifier)
          .completeOnboarding(
            university: _university ?? 'Other',
            semester: _semester,
            selectedSeeds: const [],
          );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your setup. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        if (_step > 0)
                          SpringPress(
                            child: IconButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _step--),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Previous step',
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _step == 0 ? 'ChemBuddy' : 'Your course',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        SpringPress(
                          child: TextButton.icon(
                            onPressed: _saving
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const AppearanceScreen(),
                                    ),
                                  ),
                            icon: const Icon(Icons.palette_outlined, size: 18),
                            label: const Text('Your look'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      children: [
                        if (_step == 0) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Icon(
                                Icons.science_outlined,
                                size: 40,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Your chemistry.\nA clearer way through.',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A study companion for MSc Chemistry: organise your week, understand your notes and explore the ideas behind the equations.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          LiquidGlassContainer(
                            padding: const EdgeInsets.all(24),
                            borderRadius: 28,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'What you can do here',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 24),
                                const _SetupFeature(
                                  icon: Icons.calendar_month_outlined,
                                  title: 'Keep your course together',
                                  detail: 'Plan classes, record attendance and keep deadlines in view.',
                                ),
                                const SizedBox(height: 22),
                                const _SetupFeature(
                                  icon: Icons.auto_stories_outlined,
                                  title: 'Study from your own material',
                                  detail: 'Organise PDFs, revisit your notes and use the available revision tools.',
                                ),
                                const SizedBox(height: 22),
                                const _SetupFeature(
                                  icon: Icons.science_outlined,
                                  title: 'Explore the chemistry',
                                  detail: 'Open focused calculators, spectroscopy workspaces, orbital visualisations and the drawing canvas.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          LiquidGlassContainer(
                            enableBlur: false,
                            padding: const EdgeInsets.all(20),
                            borderRadius: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start your way',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Choose your university and subjects, then sign in or continue as guest. Your course details and colours can be changed in Profile.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Guest mode keeps local notes, attendance and tools on this device. Cloud AI needs an account and internet. Keep your original study files backed up.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '${AppIdentity.version}  ·  By ${AppIdentity.author}',
                            style: theme.textTheme.labelMedium,
                          ),
                        ] else ...[
                          Text(
                            'SETUP $_step OF 2',
                            style: theme.textTheme.labelMedium?.copyWith(
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _step == 1
                                ? 'Where are you studying?'
                                : 'Make it your course.',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _step == 1
                                ? 'A few details to shape your study space. You can change these later.'
                                : 'Choose your subjects. Add or change them anytime from Profile.',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 26),
                          if (_step == 1)
                            LiquidGlassContainer(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'University',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _university,
                                    isExpanded: true,
                                    hint: const Text('Choose your university'),
                                    items: [
                                      for (final name in SeedData.universities)
                                        DropdownMenuItem(
                                          value: name,
                                          child: Text(
                                            name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                    onChanged: _saving
                                        ? null
                                        : (value) => setState(
                                            () => _university = value,
                                          ),
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.school_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  Text(
                                    'Semester',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      for (final semester in SeedData.semesters)
                                        SpringPress(
                                          child: ChoiceChip(
                                            label: Text('Semester $semester'),
                                            selected: _semester == semester,
                                            onSelected: _saving
                                                ? null
                                                : (_) => setState(
                                                    () => _semester = semester,
                                                  ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (_step == 2) ...[
                            for (final subject in SeedData.mscChemistrySubjects)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: LiquidGlassContainer(
                                  enableBlur: false,
                                  shadows: const [],
                                  borderRadius: 22,
                                  borderColor: _selected.contains(subject.code)
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: .45,
                                        )
                                      : null,
                                  child: CheckboxListTile(
                                    value: _selected.contains(subject.code),
                                    onChanged: _saving
                                        ? null
                                        : (value) => setState(() {
                                            if (value == true) {
                                              _selected.add(subject.code);
                                            } else {
                                              _selected.remove(subject.code);
                                            }
                                          }),
                                    title: Text(subject.name),
                                    subtitle: Text(subject.code),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (_selected.contains('OE'))
                              TextField(
                                controller: _elective,
                                decoration: const InputDecoration(
                                  labelText: 'Open elective name',
                                ),
                              ),
                            const SizedBox(height: 18),
                            LiquidGlassContainer(
                              enableBlur: false,
                              shadows: const [],
                              padding: const EdgeInsets.all(18),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text('Add a custom subject'),
                                subtitle: const Text('Optional'),
                                children: [
                                  TextField(
                                    controller: _customName,
                                    decoration: const InputDecoration(
                                      labelText: 'Subject name',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _customCode,
                                    decoration: const InputDecoration(
                                      labelText: 'Subject code',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _customTeacher,
                                    decoration: const InputDecoration(
                                      labelText: 'Teacher (optional)',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Column(
                      children: [
                        if (_step > 0) ...[
                          LinearProgressIndicator(
                            value: _step / 2,
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 18),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: SpringPress(
                            child: FilledButton.icon(
                              onPressed:
                                  _saving || (_step == 1 && _university == null)
                                  ? null
                                  : _continue,
                              label: Text(
                                _saving
                                    ? 'Saving your space…'
                                    : _step == 0
                                    ? 'Get started'
                                    : _step == 2
                                    ? 'Finish setup'
                                    : 'Continue',
                              ),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                        if (_step == 0)
                          SpringPress(
                            child: TextButton(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      await ref
                                          .read(appControllerProvider.notifier)
                                          .completeOnboarding(
                                            university: '',
                                            semester: 1,
                                            selectedSeeds: const [],
                                          );
                                    },
                              child: const Text('I already have an account'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupFeature extends StatelessWidget {
  const _SetupFeature({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer
              .withValues(alpha: .55),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(detail, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ],
  );
}

class SubjectDraft {
  SubjectDraft({
    required this.id,
    required this.name,
    required this.code,
    required this.teacher,
  });
  final String id, name, code, teacher;
  Subject toSubject() =>
      Subject(id: id, name: name, code: code, teacher: teacher);
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
  bool signUp = false, loading = false, obscurePassword = true;
  String? error;
  @override
  void dispose() {
    registerNumber.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reg = registerNumber.text.trim();
    final pwd = password.text;
    final fullName = name.text.trim();
    if (reg.isEmpty) {
      setState(() => error = 'Enter your register number.');
      return;
    }
    if (signUp && fullName.isEmpty) {
      setState(() => error = 'Enter your full name.');
      return;
    }
    if (pwd.length < 6) {
      setState(() => error = 'Use a password with at least 6 characters.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ref
          .read(appControllerProvider.notifier)
          .authenticate(
            registerNumber: reg,
            password: pwd,
            name: fullName,
            signUp: signUp,
          );
      if (mounted) {
        setState(() => error = result);
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not sign in. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _guest() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).enterGuest();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not open guest mode. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Row(
              children: [
                const ChemBuddyLogo(size: 48, animated: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('ChemBuddy', style: theme.textTheme.titleLarge),
                ),
                SpringPress(
                  child: IconButton(
                    tooltip: 'Appearance',
                    onPressed: loading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AppearanceScreen(),
                            ),
                          ),
                    icon: const Icon(Icons.palette_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text(
              signUp ? 'Your next chapter.' : 'Welcome back.',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(
              signUp
                  ? 'A study space that grows with you.'
                  : 'Your chemistry, in one place.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            LiquidGlassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SpringPress(
                        child: ChoiceChip(
                          label: const Text('Sign In'),
                          selected: !signUp,
                          onSelected: loading
                              ? null
                              : (_) => setState(() {
                                  signUp = false;
                                  error = null;
                                }),
                        ),
                      ),
                      SpringPress(
                        child: ChoiceChip(
                          label: const Text('Create Account'),
                          selected: signUp,
                          onSelected: loading
                              ? null
                              : (_) => setState(() {
                                  signUp = true;
                                  error = null;
                                }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (signUp) ...[
                    TextField(
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: registerNumber,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Register Number',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    autofillHints: [
                      signUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textInputAction: TextInputAction.done,
                    onSubmitted: loading ? null : (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: SpringPress(
                        child: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SpringPress(
                    child: FilledButton(
                      onPressed: loading ? null : _submit,
                      child: Text(
                        loading
                            ? 'Please wait…'
                            : signUp
                            ? 'Create Account'
                            : 'Sign In',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SpringPress(
              child: OutlinedButton.icon(
                key: const Key('continue-guest'),
                onPressed: loading ? null : _guest,
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Continue as guest'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Notes, attendance and tools stay on this device. Sign in for cloud AI.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 28),
            Text(
              'Version ${AppIdentity.version}  ·  By ${AppIdentity.author}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
