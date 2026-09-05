import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/utils/attendance_math.dart';
import '../models/models.dart';
import '../models/reaction_models.dart';
import '../repositories/chem_repository.dart';

/// Professional export service for generating academic PDF reports and
/// Excel-compatible CSV spreadsheets for Attendance and Reaction Mechanisms.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  // ===========================================================================
  // 1. ATTENDANCE EXPORTS (PDF & CSV / EXCEL)
  // ===========================================================================

  /// Generates a comprehensive, publication-grade academic PDF report for attendance.
  Future<File> generateAttendancePdf({
    required UserProfile profile,
    required ChemRepository repository,
    Directory? outputDirectory,
  }) async {
    final doc = PdfDocument();
    doc.pageSettings.margins.all = 36; // 0.5 inch margins

    final page = doc.pages.add();
    final pageSize = page.getClientSize();

    // Fonts
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final sectionFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
    final subFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.regular);
    final boldSubFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final kpiValFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final footerFont = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.italic);

    // Color palette
    final primaryColor = PdfColor(76, 29, 149); // Deep Purple
    final primaryBrush = PdfSolidBrush(primaryColor);
    final darkBrush = PdfSolidBrush(PdfColor(30, 27, 75));
    final mutedBrush = PdfSolidBrush(PdfColor(100, 116, 139));
    final borderPen = PdfPen(PdfColor(226, 232, 240), width: 1);

    double y = 0;

    // Header Accent Bar
    page.graphics.drawRectangle(
      brush: primaryBrush,
      bounds: Rect.fromLTWH(0, y, pageSize.width, 6),
    );
    y += 14;

    // Document Title
    page.graphics.drawString(
      _cleanForPdf('CHEM BUDDY - MSc CHEMISTRY ACADEMIC AUDIT'),
      subFont,
      brush: primaryBrush,
      bounds: Rect.fromLTWH(0, y, pageSize.width, 14),
    );
    y += 16;

    page.graphics.drawString(
      _cleanForPdf('Official Attendance & Coursework Report'),
      titleFont,
      brush: darkBrush,
      bounds: Rect.fromLTWH(0, y, pageSize.width, 24),
    );
    y += 28;

    // Student Info Card
    final studentCardHeight = 52.0;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 250, 252)),
      pen: borderPen,
      bounds: Rect.fromLTWH(0, y, pageSize.width, studentCardHeight),
    );

    final leftColX = 12.0;
    final rightColX = pageSize.width / 2 + 10;
    final infoY1 = y + 8;
    final infoY2 = y + 28;

    final studentName = profile.fullName.trim().isEmpty ? 'MSc Chemistry Scholar' : profile.fullName;
    final regNo = profile.registerNumber.trim().isEmpty ? 'N/A' : profile.registerNumber;
    final uni = profile.university.trim().isEmpty ? 'Autonomous University' : profile.university;
    final dateStr = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());

    page.graphics.drawString('Student Name: ', boldSubFont, brush: darkBrush, bounds: Rect.fromLTWH(leftColX, infoY1, 100, 16));
    page.graphics.drawString(_cleanForPdf(studentName), subFont, brush: darkBrush, bounds: Rect.fromLTWH(leftColX + 90, infoY1, 200, 16));

    page.graphics.drawString('Reg. Number: ', boldSubFont, brush: darkBrush, bounds: Rect.fromLTWH(leftColX, infoY2, 100, 16));
    page.graphics.drawString(_cleanForPdf(regNo), subFont, brush: darkBrush, bounds: Rect.fromLTWH(leftColX + 90, infoY2, 200, 16));

    page.graphics.drawString('University: ', boldSubFont, brush: darkBrush, bounds: Rect.fromLTWH(rightColX, infoY1, 80, 16));
    page.graphics.drawString(_cleanForPdf('$uni (Sem ${profile.semester})'), subFont, brush: darkBrush, bounds: Rect.fromLTWH(rightColX + 75, infoY1, 200, 16));

    page.graphics.drawString('Generated: ', boldSubFont, brush: darkBrush, bounds: Rect.fromLTWH(rightColX, infoY2, 80, 16));
    page.graphics.drawString(_cleanForPdf(dateStr), subFont, brush: darkBrush, bounds: Rect.fromLTWH(rightColX + 75, infoY2, 200, 16));

    y += studentCardHeight + 16;

    // Overall KPI Summary
    final overallStats = repository.overallStats();
    final risk = overallStats.riskTier();

    page.graphics.drawString('Executive Summary & Target Standing', sectionFont, brush: darkBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 18));
    y += 22;

    final kpiBoxWidth = (pageSize.width - 24) / 3;
    final kpiBoxHeight = 56.0;

    // KPI 1: Overall Percentage
    _drawKpiCard(
      page.graphics,
      x: 0,
      y: y,
      width: kpiBoxWidth,
      height: kpiBoxHeight,
      label: 'Overall Attendance',
      value: '${overallStats.percent.toStringAsFixed(1)}%',
      valueFont: kpiValFont,
      labelFont: subFont,
      borderPen: borderPen,
      valueColor: overallStats.percent >= 75 ? PdfColor(16, 185, 129) : PdfColor(239, 68, 68),
    );

    // KPI 2: Sessions Count
    _drawKpiCard(
      page.graphics,
      x: kpiBoxWidth + 12,
      y: y,
      width: kpiBoxWidth,
      height: kpiBoxHeight,
      label: 'Sessions Count',
      value: '${overallStats.present} / ${overallStats.counted}',
      valueFont: kpiValFont,
      labelFont: subFont,
      borderPen: borderPen,
      valueColor: PdfColor(76, 29, 149),
      subtitle: _cleanForPdf('Missed: ${overallStats.absent} - Excused/OD: ${overallStats.excused}'),
    );

    // KPI 3: Academic Standing
    _drawKpiCard(
      page.graphics,
      x: (kpiBoxWidth + 12) * 2,
      y: y,
      width: kpiBoxWidth,
      height: kpiBoxHeight,
      label: 'Academic Standing',
      value: _cleanForPdf(risk.displayName),
      valueFont: PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold),
      labelFont: subFont,
      borderPen: borderPen,
      valueColor: overallStats.percent >= 80 ? PdfColor(16, 185, 129) : PdfColor(245, 158, 11),
      subtitle: _cleanForPdf(overallStats.percent >= 75
          ? 'Buffer: +${overallStats.canSkip} skips allowed'
          : 'Prescription: Attend ${overallStats.attendToReach75} straight'),
    );

    y += kpiBoxHeight + 20;

    // Subject Breakdown Table
    page.graphics.drawString(_cleanForPdf('Coursework & Subject-Wise Performance'), sectionFont, brush: darkBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 18));
    y += 22;

    final subjects = repository.subjects();
    final grid = PdfGrid();
    grid.columns.add(count: 7);
    grid.columns[0].width = 150; // Subject
    grid.columns[1].width = 50;  // Code
    grid.columns[2].width = 45;  // Pres
    grid.columns[3].width = 45;  // Abs
    grid.columns[4].width = 45;  // Exc
    grid.columns[5].width = 50;  // Pct
    grid.columns[6].width = pageSize.width - (150 + 50 + 45 + 45 + 45 + 50); // Status / Prescription

    // Header
    grid.headers.add(1);
    final headerRow = grid.headers[0];
    headerRow.style.backgroundBrush = primaryBrush;
    headerRow.style.textBrush = PdfSolidBrush(PdfColor(255, 255, 255));
    headerRow.style.font = boldSubFont;

    headerRow.cells[0].value = 'Subject';
    headerRow.cells[1].value = 'Code';
    headerRow.cells[2].value = 'Att.';
    headerRow.cells[3].value = 'Miss';
    headerRow.cells[4].value = 'OD';
    headerRow.cells[5].value = 'Pct %';
    headerRow.cells[6].value = 'Status / Prescription';

    for (final s in subjects) {
      final stats = repository.statsFor(s.id);
      final row = grid.rows.add();
      row.style.font = subFont;
      row.cells[0].value = _cleanForPdf(s.name);
      row.cells[1].value = _cleanForPdf(s.code.isEmpty ? '-' : s.code);
      row.cells[2].value = '${stats.present}';
      row.cells[3].value = '${stats.absent}';
      row.cells[4].value = '${stats.excused}';
      row.cells[5].value = '${stats.percent.toStringAsFixed(1)}%';

      final needed75 = stats.attendToReach75;
      final skip75 = stats.canSkip;
      if (stats.percent >= 80) {
        row.cells[6].value = 'Safe (+$skip75 skips for 75%)';
      } else if (stats.percent >= 75) {
        row.cells[6].value = 'On Track (+$skip75 skips)';
      } else {
        row.cells[6].value = 'Danger: Attend +$needed75 classes';
      }
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, y, pageSize.width, 0),
    );

    // Footer on all pages
    for (int i = 0; i < doc.pages.count; i++) {
      final p = doc.pages[i];
      final pSize = p.getClientSize();
      p.graphics.drawLine(borderPen, Offset(0, pSize.height - 18), Offset(pSize.width, pSize.height - 18));
      p.graphics.drawString(
        _cleanForPdf('Chem Buddy by Prajwal A Kambar - Verified MSc Chemistry Study Suite - Page ${i + 1} of ${doc.pages.count}'),
        footerFont,
        brush: mutedBrush,
        bounds: Rect.fromLTWH(0, pSize.height - 14, pSize.width, 14),
      );
    }

    final bytes = await doc.save();
    doc.dispose();

    final targetDir = outputDirectory ?? await getTemporaryDirectory();
    final fileName = 'ChemBuddy_Attendance_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Generates an Excel-compatible CSV spreadsheet for attendance.
  Future<File> generateAttendanceCsv({
    required UserProfile profile,
    required ChemRepository repository,
    Directory? outputDirectory,
  }) async {
    final buffer = StringBuffer();
    // UTF-8 BOM so Excel opens without mojibake
    buffer.write('\uFEFF');

    final overall = repository.overallStats();
    final studentName = profile.fullName.trim().isEmpty ? 'MSc Chemistry Scholar' : profile.fullName;
    final regNo = profile.registerNumber.trim().isEmpty ? 'N/A' : profile.registerNumber;
    final uni = profile.university.trim().isEmpty ? 'Autonomous University' : profile.university;

    // Header metadata
    buffer.writeln('CHEM BUDDY - ATTENDANCE & COURSEWORK AUDIT REPORT');
    buffer.writeln('Student Name,"${_escapeCsv(studentName)}"');
    buffer.writeln('Register Number,"${_escapeCsv(regNo)}"');
    buffer.writeln('University,"${_escapeCsv(uni)}"');
    buffer.writeln('Semester,"Semester ${profile.semester}"');
    buffer.writeln('Generated Date,"${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}"');
    buffer.writeln('Overall Attendance,"${overall.percent.toStringAsFixed(2)}%"');
    buffer.writeln('Total Counted Classes,"${overall.counted}"');
    buffer.writeln('Total Attended,"${overall.present}"');
    buffer.writeln('Total Missed,"${overall.absent}"');
    buffer.writeln('Total Excused / OD,"${overall.excused}"');
    buffer.writeln('');

    // Subject Breakdown
    buffer.writeln('SUBJECT BREAKDOWN');
    buffer.writeln('Subject Name,Subject Code,Teacher,Attended,Missed,Excused / OD,Total Counted,Attendance %,Status,Safe Skips (75%),Classes Needed (75%),Safe Skips (80%),Classes Needed (80%)');

    for (final s in repository.subjects()) {
      final stats = repository.statsFor(s.id);
      final skip75 = stats.canSkip;
      final need75 = stats.attendToReach75;
      final skip80 = stats.canSkipForTarget(80.0);
      final need80 = stats.attendToReachTarget(80.0);
      final status = stats.percent >= 80 ? 'Safe' : (stats.percent >= 75 ? 'Warning' : 'Critical');

      buffer.writeln(
        '"${_escapeCsv(s.name)}",'
        '"${_escapeCsv(s.code)}",'
        '"${_escapeCsv(s.teacher)}",'
        '${stats.present},'
        '${stats.absent},'
        '${stats.excused},'
        '${stats.counted},'
        '${stats.percent.toStringAsFixed(2)},'
        '"$status",'
        '$skip75,'
        '$need75,'
        '$skip80,'
        '$need80',
      );
    }

    buffer.writeln('');
    buffer.writeln('CHRONOLOGICAL SESSIONS LOG');
    buffer.writeln('Date,Subject,Status,Excused / OD,Note');

    final records = repository.attendance();
    final subjectMap = {for (final s in repository.subjects()) s.id: s};
    for (final r in records) {
      final sub = subjectMap[r.subjectId];
      final subName = sub?.name ?? 'Unknown Subject';
      final statusStr = r.status == AttendanceStatus.present
          ? 'Present'
          : (r.status == AttendanceStatus.absent
              ? 'Absent'
              : (r.status == AttendanceStatus.excused ? 'Excused / OD' : 'Postponed'));
      final isExcused = r.status == AttendanceStatus.excused ? 'Yes' : 'No';

      buffer.writeln(
        '"${DateFormat('yyyy-MM-dd').format(r.date)}",'
        '"${_escapeCsv(subName)}",'
        '"$statusStr",'
        '"$isExcused",'
        '"${_escapeCsv(r.note ?? '')}"',
      );
    }

    final targetDir = outputDirectory ?? await getTemporaryDirectory();
    final fileName = 'ChemBuddy_Attendance_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  // ===========================================================================
  // 2. REACTION MECHANISMS EXPORTS (PDF & CSV / EXCEL)
  // ===========================================================================

  /// Generates an elegant PDF dossier for a single reaction mechanism or the entire MSc Compendium.
  Future<File> generateReactionPdf({
    ReactionMechanism? singleReaction,
    List<ReactionMechanism>? reactions,
    Directory? outputDirectory,
  }) async {
    final doc = PdfDocument();
    doc.pageSettings.margins.all = 36;

    final list = singleReaction != null ? [singleReaction] : (reactions ?? []);

    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
    final h2Font = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final regularFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.regular);
    final subFont = PdfStandardFont(PdfFontFamily.helvetica, 8.5, style: PdfFontStyle.regular);
    final footerFont = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.italic);

    final primaryColor = PdfColor(76, 29, 149);
    final primaryBrush = PdfSolidBrush(primaryColor);
    final darkBrush = PdfSolidBrush(PdfColor(30, 27, 75));
    final borderPen = PdfPen(PdfColor(226, 232, 240), width: 1);

    for (int idx = 0; idx < list.length; idx++) {
      final m = list[idx];
      final page = doc.pages.add();
      final pageSize = page.getClientSize();
      double y = 0;

      // Header Bar
      page.graphics.drawRectangle(brush: primaryBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 5));
      y += 12;

      // Category Tag & Title
      page.graphics.drawString(
        _cleanForPdf('MSc ORGANIC CHEMISTRY - ${m.category.displayName.toUpperCase()}'),
        subFont,
        brush: primaryBrush,
        bounds: Rect.fromLTWH(0, y, pageSize.width, 12),
      );
      y += 14;

      page.graphics.drawString(_cleanForPdf(m.name), titleFont, brush: darkBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 22));
      y += 24;

      if (m.aliases.isNotEmpty) {
        page.graphics.drawString(
          _cleanForPdf('Aliases: ${m.aliases.join(', ')}'),
          subFont,
          brush: PdfSolidBrush(PdfColor(100, 116, 139)),
          bounds: Rect.fromLTWH(0, y, pageSize.width, 12),
        );
        y += 14;
      }

      // Summary Box
      final summaryBounds = Rect.fromLTWH(0, y, pageSize.width, 42);
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(248, 250, 252)),
        pen: borderPen,
        bounds: summaryBounds,
      );
      page.graphics.drawString(
        _cleanForPdf(m.summary),
        regularFont,
        brush: darkBrush,
        bounds: Rect.fromLTWH(8, y + 6, pageSize.width - 16, 32),
      );
      y += 50;

      // Chemistry Reaction Details Table
      final detailGrid = PdfGrid();
      detailGrid.columns.add(count: 2);
      detailGrid.columns[0].width = 130;
      detailGrid.columns[1].width = pageSize.width - 130;

      _addDetailRow(detailGrid, 'Reactants:', _cleanForPdf(m.reactants));
      _addDetailRow(detailGrid, 'Reagents & Conditions:', _cleanForPdf(m.reagentsAndConditions));
      _addDetailRow(detailGrid, 'Products:', _cleanForPdf(m.products));

      final detailResult = detailGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, pageSize.width, 0));
      y = detailResult!.bounds.bottom + 14;

      // Step-by-Step Breakdown Table
      page.graphics.drawString(_cleanForPdf('Stepwise Mechanism & Electron Movement'), h2Font, brush: darkBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 16));
      y += 20;

      final stepGrid = PdfGrid();
      stepGrid.columns.add(count: 3);
      stepGrid.columns[0].width = 45; // Step #
      stepGrid.columns[1].width = 180; // Title & Notes
      stepGrid.columns[2].width = pageSize.width - (45 + 180); // Curved arrow & intermediate

      stepGrid.headers.add(1);
      final sHeader = stepGrid.headers[0];
      sHeader.style.backgroundBrush = primaryBrush;
      sHeader.style.textBrush = PdfSolidBrush(PdfColor(255, 255, 255));
      sHeader.style.font = boldFont;
      sHeader.cells[0].value = 'Step';
      sHeader.cells[1].value = 'Transformation';
      sHeader.cells[2].value = 'Curved Arrow Flow & Intermediates';

      for (final step in m.steps) {
        final row = stepGrid.rows.add();
        row.style.font = subFont;
        row.cells[0].value = 'Step ${step.stepNumber}';
        row.cells[1].value = '${_cleanForPdf(step.title)}\n${_cleanForPdf(step.description)}';
        row.cells[2].value = 'Flow: ${_cleanForPdf(step.curvedArrowNotes)}\nIntermediate: ${_cleanForPdf(step.intermediate)}';
      }

      final stepResult = stepGrid.draw(page: page, bounds: Rect.fromLTWH(0, y, pageSize.width, 0));
      y = stepResult!.bounds.bottom + 14;

      // Applications & Limitations
      if (y < pageSize.height - 70) {
        if (m.keyApplications.isNotEmpty) {
          page.graphics.drawString(_cleanForPdf('Synthetic Applications:'), boldFont, brush: darkBrush, bounds: Rect.fromLTWH(0, y, pageSize.width, 14));
          y += 14;
          for (final app in m.keyApplications) {
            page.graphics.drawString(_cleanForPdf('- $app'), subFont, brush: darkBrush, bounds: Rect.fromLTWH(8, y, pageSize.width - 16, 12));
            y += 13;
          }
        }
      }
    }

    // Page Numbering Footer
    for (int i = 0; i < doc.pages.count; i++) {
      final p = doc.pages[i];
      final pSize = p.getClientSize();
      p.graphics.drawLine(borderPen, Offset(0, pSize.height - 18), Offset(pSize.width, pSize.height - 18));
      p.graphics.drawString(
        _cleanForPdf('Chem Buddy by Prajwal A Kambar - MSc Chemistry Reaction Dossier - Page ${i + 1} of ${doc.pages.count}'),
        footerFont,
        brush: PdfSolidBrush(PdfColor(148, 163, 184)),
        bounds: Rect.fromLTWH(0, pSize.height - 14, pSize.width, 14),
      );
    }

    final bytes = await doc.save();
    doc.dispose();

    final targetDir = outputDirectory ?? await getTemporaryDirectory();
    final slug = singleReaction != null ? singleReaction.id : 'msc_compendium';
    final fileName = 'ChemBuddy_Reaction_${slug}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Generates an Excel-compatible CSV spreadsheet for reaction mechanisms.
  Future<File> generateReactionsCsv({
    required List<ReactionMechanism> mechanisms,
    Directory? outputDirectory,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF'); // UTF-8 BOM

    buffer.writeln('CHEM BUDDY - MSC REACTION MECHANISMS CATALOG');
    buffer.writeln('Total Reactions,${mechanisms.length}');
    buffer.writeln('Generated Date,"${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}"');
    buffer.writeln('');

    buffer.writeln('Reaction ID,Reaction Name,Category,Aliases,Reactants,Reagents & Conditions,Products,Steps Count,Key Applications,Limitations');

    for (final m in mechanisms) {
      buffer.writeln(
        '"${_escapeCsv(m.id)}",'
        '"${_escapeCsv(m.name)}",'
        '"${_escapeCsv(m.category.displayName)}",'
        '"${_escapeCsv(m.aliases.join('; '))}",'
        '"${_escapeCsv(m.reactants)}",'
        '"${_escapeCsv(m.reagentsAndConditions)}",'
        '"${_escapeCsv(m.products)}",'
        '${m.steps.length},'
        '"${_escapeCsv(m.keyApplications.join('; '))}",'
        '"${_escapeCsv(m.limitations.join('; '))}"',
      );
    }

    final targetDir = outputDirectory ?? await getTemporaryDirectory();
    final fileName = 'ChemBuddy_Reactions_Catalog_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  /// Shares a file via the system share sheet / intent.
  Future<void> shareFile(File file, {String? subject, String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? 'Chem Buddy Export',
      text: text ?? 'Exported from Chem Buddy by Prajwal A Kambar',
    );
  }

  // ===========================================================================
  // HELPER UTILITIES
  // ===========================================================================

  /// Cleans and sanitizes strings for rendering in standard Helvetica PDF fonts.
  /// Converts common LaTeX syntax, mathematical symbols, Greek letters, and arrows to ASCII,
  /// and strips out unsupported or invisible Unicode codepoints (such as 8290 invisible times)
  /// that would trigger font layout exceptions in Syncfusion PDF.
  static String _cleanForPdf(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input
        .replaceAll(r'\text{', '')
        .replaceAll(r'}', '')
        .replaceAll(r'$', '')
        .replaceAll(r'\rightarrow', ' -> ')
        .replaceAll(r'\longrightarrow', ' -> ')
        .replaceAll(r'\leftarrow', ' <- ')
        .replaceAll(r'\longleftarrow', ' <- ')
        .replaceAll(r'\leftrightarrow', ' <-> ')
        .replaceAll(r'\rightleftharpoons', ' <=> ')
        .replaceAll(r'\Delta', '[heat]')
        .replaceAll(r'\alpha', 'alpha')
        .replaceAll(r'\beta', 'beta')
        .replaceAll(r'\gamma', 'gamma')
        .replaceAll(r'\pi', 'pi')
        .replaceAll(r'\sigma', 'sigma')
        .replaceAll(r'\pm', '+/-')
        .replaceAll(r'\cdot', '*');

    final charMap = {
      '→': '->',
      '←': '<-',
      '↔': '<->',
      '⇌': '<=>',
      '⇒': '=>',
      '•': '*',
      '·': '*',
      '°': ' deg',
      '′': "'",
      '″': '"',
      '−': '-',
      '–': '-',
      '—': '-',
      '“': '"',
      '”': '"',
      '‘': "'",
      '’': "'",
      'Δ': 'Delta',
      'α': 'alpha',
      'β': 'beta',
      'γ': 'gamma',
      'π': 'pi',
      'σ': 'sigma',
      'λ': 'lambda',
      '₀': '0',
      '₁': '1',
      '₂': '2',
      '₃': '3',
      '₄': '4',
      '₅': '5',
      '₆': '6',
      '₇': '7',
      '₈': '8',
      '₉': '9',
      '⁺': '+',
      '⁻': '-',
    };
    charMap.forEach((k, v) {
      text = text.replaceAll(k, v);
    });

    final sb = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // Keep standard ASCII printable (32 to 126), line breaks and tabs
      if ((code >= 32 && code <= 126) || code == 10 || code == 13 || code == 9) {
        sb.writeCharCode(code);
      } else if (code == 160) {
        // Non-breaking space
        sb.write(' ');
      }
      // Any invisible or unsupported Unicode codepoints are safely dropped
    }
    return sb.toString();
  }

  static void _drawKpiCard(
    PdfGraphics graphics, {
    required double x,
    required double y,
    required double width,
    required double height,
    required String label,
    required String value,
    required PdfFont valueFont,
    required PdfFont labelFont,
    required PdfPen borderPen,
    required PdfColor valueColor,
    String? subtitle,
  }) {
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(248, 250, 252)),
      pen: borderPen,
      bounds: Rect.fromLTWH(x, y, width, height),
    );

    graphics.drawString(
      label,
      labelFont,
      brush: PdfSolidBrush(PdfColor(100, 116, 139)),
      bounds: Rect.fromLTWH(x + 8, y + 6, width - 16, 14),
    );

    graphics.drawString(
      value,
      valueFont,
      brush: PdfSolidBrush(valueColor),
      bounds: Rect.fromLTWH(x + 8, y + 20, width - 16, 20),
    );

    if (subtitle != null) {
      graphics.drawString(
        subtitle,
        PdfStandardFont(PdfFontFamily.helvetica, 7.5),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(x + 8, y + 40, width - 16, 12),
      );
    }
  }

  static void _addDetailRow(PdfGrid grid, String label, String value) {
    final row = grid.rows.add();
    row.cells[0].value = label;
    row.cells[0].style.font = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold);
    row.cells[1].value = value;
    row.cells[1].style.font = PdfStandardFont(PdfFontFamily.helvetica, 9);
  }

  static String _escapeCsv(String val) {
    return val.replaceAll('"', '""').replaceAll('\n', ' ');
  }
}
