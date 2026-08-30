import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/services/timetable_ocr.dart';
import '../../data/services/timetable_parser_service.dart';
import '../screens/review_timetable_screen.dart';
import 'timetable_review_dialog.dart';

/// Dashboard card: gallery / camera → OCR → review → save to Hive timetable.
class TimetableScannerCard extends ConsumerStatefulWidget {
  const TimetableScannerCard({super.key});

  @override
  ConsumerState<TimetableScannerCard> createState() => _TimetableScannerCardState();
}

class _TimetableScannerCardState extends ConsumerState<TimetableScannerCard> {
  final _picker = ImagePicker();
  final _parser = TimetableParserService();
  bool _busy = false;

  Future<void> _scan(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (file == null) return;
      setState(() => _busy = true);
      final text = await recognizeTimetableText(file.path);
      final entries = _parser.parse(text);
      if (!mounted) return;
      setState(() => _busy = false);
      if (entries.length == 1 &&
          entries.first.subjectCode.isEmpty &&
          entries.first.subject.isEmpty &&
          text.trim().length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't recognize the timetable clearly. Please crop the image or enter the timetable manually."),
          ),
        );
      }
      await Navigator.push<bool>(
        context,
        ReviewTimetableScreen.route(initialEntries: entries, rawText: text),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't recognize the timetable clearly. Please crop the image or enter the timetable manually."),
        ),
      );
      await Navigator.push<bool>(
        context,
        ReviewTimetableScreen.route(initialEntries: _parser.parse(''), rawText: ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.document_scanner_outlined, color: AppColors.purpleBright),
              SizedBox(width: 10),
              Expanded(
                child: Text('Upload Timetable Image', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Photograph or pick your university schedule. We extract days, times, and subject codes for you to confirm.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.purpleBright),
                    SizedBox(height: 10),
                    Text('Reading timetable…', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.purpleBright,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scan(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
