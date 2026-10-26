import '../../core/widgets/expressive_motion.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/molecule_loader.dart';
import '../../data/services/timetable_ocr.dart';
import '../../data/services/timetable_parser_service.dart';
import '../screens/review_timetable_screen.dart';

/// Dashboard card: gallery / camera → OCR → review → save to Hive timetable.
class TimetableScannerCard extends ConsumerStatefulWidget {
  const TimetableScannerCard({super.key});

  @override
  ConsumerState<TimetableScannerCard> createState() =>
      _TimetableScannerCardState();
}

class _TimetableScannerCardState extends ConsumerState<TimetableScannerCard> {
  final _picker = ImagePicker();
  final _parser = TimetableParserService();
  bool _busy = false;

  Future<void> _scan(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 90);
      if (file == null) {
        return;
      }
      setState(() => _busy = true);
      final text = await recognizeTimetableText(file.path);
      final result = _parser.parseStructured(text);
      final entries = result.entries;
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      if (entries.length == 1 &&
          entries.first.subjectCode.isEmpty &&
          entries.first.subject.isEmpty &&
          text.trim().length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't recognize the timetable clearly. Please crop the image or enter the timetable manually.",
            ),
          ),
        );
      }
      await Navigator.push<bool>(
        context,
        ReviewTimetableScreen.route(
          initialEntries: entries,
          rawText: text,
          metadata: result.metadata,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't recognize the timetable clearly. Please crop the image or enter the timetable manually.",
          ),
        ),
      );
      await Navigator.push<bool>(
        context,
        ReviewTimetableScreen.route(
          initialEntries: _parser.parse(''),
          rawText: '',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.document_scanner_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload Timetable Image',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Photograph or pick your university schedule. We extract days, times, and subject codes for you to confirm.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: BenzeneMoleculeLoader(
                  size: 44,
                  messages: ChemistryMicrocopy.timetable,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SpringPress(
                    child: OutlinedButton.icon(
                      onPressed: () => _scan(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SpringPress(
                    child: OutlinedButton.icon(
                      onPressed: () => _scan(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.adaptive(
                          context,
                          AppColors.blue,
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
