import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/hex_background.dart';

class AppGuidesScreen extends StatelessWidget {
  const AppGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HexBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('How to Use ChemBuddy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: const [
            Text(
              'User Guides & Help',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            SizedBox(height: 6),
            Text(
              'Quick, visual tutorials on getting the most out of ChemBuddy for your MSc Chemistry studies.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 16),

            _GuideCard(
              icon: Icons.rocket_launch_rounded,
              title: 'Getting Started',
              subtitle: 'How ChemBuddy organizes your MSc coursework',
              bullets: [
                'ChemBuddy is tailored to your semester curriculum and subjects.',
                'The Home screen dynamically shows your next class, attendance safety margin, and active study sessions.',
                'Use the bottom navigation to switch smoothly between Home, Ask AI, Attendance, Timetable, and Library.',
              ],
            ),

            _GuideCard(
              icon: Icons.how_to_reg_rounded,
              title: 'Attendance Tracker & Safe Bunks',
              subtitle: 'Calculating safety margins and remaining leaves',
              bullets: [
                'Mark attendance (Present, Absent, Postponed) immediately after each lecture.',
                'ChemBuddy checks against the standard 75% university requirement.',
                'The "Can Skip" indicator tells you exactly how many lectures you can safely miss without falling below 75%.',
                'Visual weekly bar charts show your daily lecture attendance pattern.',
              ],
            ),

            _GuideCard(
              icon: Icons.calendar_month_rounded,
              title: 'Timetable & OCR Scanner',
              subtitle: 'Importing schedules from camera photos or manually',
              bullets: [
                'Add classes with subject codes, room numbers, teacher names, and timings.',
                'Use the AI Timetable Scanner to take a photo of your printed department schedule — ChemBuddy extracts and parses slots into editable items.',
                'Class reminders will automatically alert you 15–30 minutes before lectures.',
              ],
            ),

            _GuideCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Study with AI (PDF Workflow)',
              subtitle: 'Academic Summaries, Important Topics, & Grounded AI',
              bullets: [
                'Upload notes, question papers, or syllabus PDFs into your subject folders.',
                'Tap "Study with ChemBuddy" to launch a focused study session.',
                'Start with "Important Topics" to see concepts ranked by coverage depth and exam relevance (🔥 Very High, 🟠 High, 🟡 Medium).',
                'Generate an Academic Summary containing Core Concepts, Definitions, Reactions, and Quick Revision points.',
                'Use Ask ChemBuddy with the document attached for strictly grounded answers.',
              ],
            ),

            _GuideCard(
              icon: Icons.style_rounded,
              title: 'Smart Flashcards & Spaced Repetition',
              subtitle: 'Active recall for chemical reactions and mechanisms',
              bullets: [
                'Generate 10, 20, or 30 cards directly from your uploaded lecture notes.',
                'Practice cards using active recall: write your response or reveal the reference answer.',
                'Rate cards as "Easy", "Difficult", or "Skip". ChemBuddy schedules difficult cards for review sooner.',
                'Track accuracy %, cards reviewed, and weak topics after each study session.',
              ],
            ),

            _GuideCard(
              icon: Icons.quiz_rounded,
              title: 'MSc Chemistry Quiz & Practice',
              subtitle: 'Testing conceptual, mechanism, and numerical skills',
              bullets: [
                'Generate 10, 20, or 30 exam-style multiple choice questions.',
                'Covers mechanisms, reaction conditions, NMR/IR spectroscopy, and step-by-step numerical calculations.',
                'Upon completion, view your Score, Accuracy %, and a detailed list of Weak Areas with targeted revision recommendations.',
              ],
            ),

            _GuideCard(
              icon: Icons.notifications_active_rounded,
              title: 'Notifications & Class Alerts',
              subtitle: 'Customizing alarm timings and quiet hours',
              bullets: [
                'Configure how many minutes before class you want to be reminded (e.g. 15, 30, or 60 min).',
                'Toggle assignment deadline notifications, test reminders, and daily morning timetable summaries.',
                'Enable Quiet Hours to prevent study alerts during late night hours.',
              ],
            ),

            _GuideCard(
              icon: Icons.cloud_sync_rounded,
              title: 'Storage, Backup & Cloud Sync',
              subtitle: 'Keeping your notes and data completely safe',
              bullets: [
                'All attendance, timetable entries, and flashcards are automatically saved locally on your device in Hive.',
                'Cloud Sync connects with Supabase to back up your records securely across device upgrades.',
                'You can use ChemBuddy completely offline without losing any records.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: AppColors.purpleBright, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 10),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.bold, fontSize: 14)),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
