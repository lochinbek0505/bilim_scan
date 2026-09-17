import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_export_model.dart';

class PdfExportService {
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  /// Generates PDF bytes for a single student.
  static Future<Uint8List> generateSingleStudentPdfBytes(
    StudentExportData data, {
    pw.Font? fontData,
    pw.Font? fontBoldData,
  }) async {
    final doc = pw.Document();

    final fontBase = fontData ?? await PdfGoogleFonts.robotoRegular();
    final fontBold = fontBoldData ?? await PdfGoogleFonts.robotoBold();

    final student = data.student;
    final fullName = student.fullName;

    final guruhMap = student.guruh;
    final guruhName = (guruhMap != null) ? (guruhMap.name ?? "Guruh kiritilmagan") : "Guruh kiritilmagan";

    final bosqichMap = student.bosqich;
    final bosqichName = (bosqichMap != null) ? (bosqichMap.name ?? "Bosqich kiritilmagan") : "Bosqich kiritilmagan";

    pw.ImageProvider? profileImage;
    if (data.base64Image != null && data.base64Image!.isNotEmpty) {
      try {
        final bytes = base64Decode(data.base64Image!);
        profileImage = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontBase, bold: fontBold),
        build: (pw.Context context) {
          final List<pw.Widget> content = [];

          // Title
          content.add(
            pw.Center(
              child: pw.Text(
                'IMTIHON NATIJALARI (MONITORING)',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );
          content.add(pw.SizedBox(height: 16));

          // Profile Card Header
          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 80,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: profileImage != null
                        ? pw.Image(profileImage, fit: pw.BoxFit.cover)
                        : pw.Center(
                            child: pw.Text('Rasm yo\'q', style: const pw.TextStyle(fontSize: 10)),
                          ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          fullName.isEmpty ? 'Talaba' : fullName,
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('Bosqich: $bosqichName', style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 3),
                        pw.Text('Guruh: $guruhName', style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Umumiy o\'zlashtirish foizi: ${data.monitoringData.overallPercentage?.toStringAsFixed(1) ?? '0.0'}%',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Umumiy holat: ${_translateMastery(data.monitoringData.overallPercentage, data.monitoringData.overallMastery)}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          content.add(pw.SizedBox(height: 16));

          // Academic Years Loop
          for (var year in data.monitoringData.academicYears) {
            content.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
                child: pw.Text(
                  'O\'quv yili: ${year.year ?? "Noma'lum"}',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
              ),
            );

            for (var month in year.months) {
              content.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4, top: 4, bottom: 4),
                  child: pw.Text(
                    'Oy: ${month.month ?? "Noma'lum"}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );

              if (month.subjects.isNotEmpty) {
                content.add(
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                    headers: ['Fan nomi', 'O\'rtacha foiz', 'O\'zlashtirish', 'Imtihonlar'],
                    data: month.subjects.map((subject) {
                      final examsList = subject.exams
                          .map((e) => '${e.examName ?? "Imtihon"}: ${e.percentage?.toStringAsFixed(1) ?? "0.0"}% (${_translateMastery(e.percentage, e.masteryLevel)})')
                          .join('\n');
                      return [
                        subject.subjectName ?? "Noma'lum fan",
                        '${subject.averagePercentage?.toStringAsFixed(1) ?? '0.0'}%',
                        _translateMastery(subject.averagePercentage, subject.subjectMastery),
                        examsList.isEmpty ? '-' : examsList,
                      ];
                    }).toList(),
                  ),
                );
                content.add(pw.SizedBox(height: 10));
              }
            }
          }

          return content;
        },
      ),
    );

    return await doc.save();
  }

  /// Exports results to a single PDF document or layout viewer.
  static Future<void> exportResultsToPdf(
      List<StudentExportData> students, String fileName) async {
    try {
      if (students.isEmpty) return;

      final fontData = await PdfGoogleFonts.robotoRegular();
      final fontBoldData = await PdfGoogleFonts.robotoBold();

      Uint8List pdfBytes;

      if (students.length == 1) {
        pdfBytes = await generateSingleStudentPdfBytes(
          students.first,
          fontData: fontData,
          fontBoldData: fontBoldData,
        );
      } else {
        final doc = pw.Document();
        for (var data in students) {
          final student = data.student;
          final fullName = student.fullName;

          final guruhMap = student.guruh;
          final guruhName = (guruhMap != null) ? (guruhMap.name ?? "Guruh kiritilmagan") : "Guruh kiritilmagan";

          final bosqichMap = student.bosqich;
          final bosqichName = (bosqichMap != null) ? (bosqichMap.name ?? "Bosqich kiritilmagan") : "Bosqich kiritilmagan";

          pw.ImageProvider? profileImage;
          if (data.base64Image != null && data.base64Image!.isNotEmpty) {
            try {
              final bytes = base64Decode(data.base64Image!);
              profileImage = pw.MemoryImage(bytes);
            } catch (_) {}
          }

          doc.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              theme: pw.ThemeData.withFont(base: fontData, bold: fontBoldData),
              build: (pw.Context context) {
                final List<pw.Widget> content = [];

                content.add(
                  pw.Center(
                    child: pw.Text(
                      'IMTIHON NATIJALARI (MONITORING)',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                );
                content.add(pw.SizedBox(height: 16));

                content.add(
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 80,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: profileImage != null
                              ? pw.Image(profileImage, fit: pw.BoxFit.cover)
                              : pw.Center(
                                  child: pw.Text('Rasm yo\'q', style: const pw.TextStyle(fontSize: 10)),
                                ),
                        ),
                        pw.SizedBox(width: 14),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                fullName.isEmpty ? 'Talaba' : fullName,
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text('Bosqich: $bosqichName', style: const pw.TextStyle(fontSize: 11)),
                              pw.SizedBox(height: 3),
                              pw.Text('Guruh: $guruhName', style: const pw.TextStyle(fontSize: 11)),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Umumiy o\'zlashtirish foizi: ${data.monitoringData.overallPercentage?.toStringAsFixed(1) ?? '0.0'}%',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Umumiy holat: ${_translateMastery(data.monitoringData.overallPercentage, data.monitoringData.overallMastery)}',
                                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                content.add(pw.SizedBox(height: 16));

                for (var year in data.monitoringData.academicYears) {
                  content.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
                      child: pw.Text(
                        'O\'quv yili: ${year.year ?? "Noma'lum"}',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                    ),
                  );

                  for (var month in year.months) {
                    content.add(
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 4, top: 4, bottom: 4),
                        child: pw.Text(
                          'Oy: ${month.month ?? "Noma'lum"}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    );

                    if (month.subjects.isNotEmpty) {
                      content.add(
                        pw.TableHelper.fromTextArray(
                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                          cellStyle: const pw.TextStyle(fontSize: 9),
                          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                          headers: ['Fan nomi', 'O\'rtacha foiz', 'O\'zlashtirish', 'Imtihonlar'],
                          data: month.subjects.map((subject) {
                            final examsList = subject.exams
                                .map((e) => '${e.examName ?? "Imtihon"}: ${e.percentage?.toStringAsFixed(1) ?? "0.0"}% (${_translateMastery(e.percentage, e.masteryLevel)})')
                                .join('\n');
                            return [
                              subject.subjectName ?? "Noma'lum fan",
                              '${subject.averagePercentage?.toStringAsFixed(1) ?? '0.0'}%',
                              _translateMastery(subject.averagePercentage, subject.subjectMastery),
                              examsList.isEmpty ? '-' : examsList,
                            ];
                          }).toList(),
                        ),
                      );
                      content.add(pw.SizedBox(height: 10));
                    }
                  }
                }

                return content;
              },
            ),
          );
        }
        pdfBytes = await doc.save();
      }

      final name = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';

      await FilePicker.saveFile(
        dialogTitle: 'PDF faylini saqlash',
        fileName: name,
        bytes: pdfBytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (e) {
      debugPrint("PDF eksportida xatolik: $e");
    }
  }

  /// Exports group students as individual PDFs inside a group directory in a ZIP file.
  static Future<void> exportGroupToZip({
    required String groupName,
    required List<StudentExportData> students,
    required String zipFileName,
  }) async {
    try {
      final fontData = await PdfGoogleFonts.robotoRegular();
      final fontBoldData = await PdfGoogleFonts.robotoBold();

      final archive = Archive();
      final sanitizedGroupName = sanitizeFileName(groupName.isEmpty ? 'Guruh' : groupName);
      final Map<String, int> nameCounts = {};

      for (var data in students) {
        final pdfBytes = await generateSingleStudentPdfBytes(
          data,
          fontData: fontData,
          fontBoldData: fontBoldData,
        );

        final student = data.student;
        final rawFullName = student.fullName;
        var sanitizedName = sanitizeFileName(rawFullName.isEmpty ? 'Talaba' : rawFullName);

        if (nameCounts.containsKey(sanitizedName)) {
          final count = nameCounts[sanitizedName]! + 1;
          nameCounts[sanitizedName] = count;
          sanitizedName = '${sanitizedName}_$count';
        } else {
          nameCounts[sanitizedName] = 1;
        }

        final filePath = '$sanitizedGroupName/$sanitizedName.pdf';
        archive.addFile(
          ArchiveFile(filePath, pdfBytes.length, pdfBytes),
        );
      }

      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);
      if (zipBytes == null) return;

      final name = zipFileName.endsWith('.zip') ? zipFileName : '$zipFileName.zip';
      await FilePicker.saveFile(
        fileName: name,
        bytes: Uint8List.fromList(zipBytes),
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
    } catch (e) {
      debugPrint("Guruh ZIP eksportida xatolik: $e");
    }
  }

  /// Exports stage (bosqich) students as individual PDFs organized by group subfolders in a ZIP file.
  static Future<void> exportBosqichToZip({
    required String bosqichName,
    required Map<String, List<StudentExportData>> groupStudentsMap,
    required String zipFileName,
  }) async {
    try {
      final fontData = await PdfGoogleFonts.robotoRegular();
      final fontBoldData = await PdfGoogleFonts.robotoBold();

      final archive = Archive();
      final sanitizedBosqichName = sanitizeFileName(bosqichName.isEmpty ? 'Bosqich' : bosqichName);

      for (var entry in groupStudentsMap.entries) {
        final groupName = entry.key;
        final students = entry.value;
        final sanitizedGroupName = sanitizeFileName(groupName.isEmpty ? 'Guruh' : groupName);

        final Map<String, int> nameCounts = {};

        for (var data in students) {
          final pdfBytes = await generateSingleStudentPdfBytes(
            data,
            fontData: fontData,
            fontBoldData: fontBoldData,
          );

          final student = data.student;
          final rawFullName = student.fullName;
          var sanitizedName = sanitizeFileName(rawFullName.isEmpty ? 'Talaba' : rawFullName);

          if (nameCounts.containsKey(sanitizedName)) {
            final count = nameCounts[sanitizedName]! + 1;
            nameCounts[sanitizedName] = count;
            sanitizedName = '${sanitizedName}_$count';
          } else {
            nameCounts[sanitizedName] = 1;
          }

          final filePath = '$sanitizedBosqichName/$sanitizedGroupName/$sanitizedName.pdf';
          archive.addFile(
            ArchiveFile(filePath, pdfBytes.length, pdfBytes),
          );
        }
      }

      final encoder = ZipEncoder();
      final zipBytes = encoder.encode(archive);
      if (zipBytes == null) return;

      final name = zipFileName.endsWith('.zip') ? zipFileName : '$zipFileName.zip';
      await FilePicker.saveFile(
        fileName: name,
        bytes: Uint8List.fromList(zipBytes),
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
    } catch (e) {
      debugPrint("Bosqich ZIP eksportida xatolik: $e");
    }
  }

  static String _translateMastery(dynamic percentageOrMastery, [String? fallbackMastery]) {
    num? percentage;
    String? masteryStr;

    if (percentageOrMastery is num) {
      percentage = percentageOrMastery;
      masteryStr = fallbackMastery;
    } else if (percentageOrMastery is String) {
      final parsed = double.tryParse(percentageOrMastery);
      if (parsed != null) {
        percentage = parsed;
        masteryStr = fallbackMastery;
      } else {
        masteryStr = percentageOrMastery;
      }
    } else {
      masteryStr = fallbackMastery;
    }

    if (percentage != null) {
      if (percentage >= 85.0) {
        return "A'lo";
      } else if (percentage >= 60.0) {
        return "O'zlashtirdi";
      } else {
        return "O'zlashtirmadi";
      }
    }

    if (masteryStr != null && masteryStr.trim().isNotEmpty) {
      final upper = masteryStr.toUpperCase().trim();
      if (upper == 'HIGH_MASTERY' || upper == 'EXCELLENT' || upper == 'PASSED_HIGH' || upper == 'A\'LO') {
        return "A'lo";
      } else if (upper == 'PASSED' || upper == 'SATISFACTORY' || upper == 'GOOD' || upper == 'O\'ZLASHTIRDI') {
        return "O'zlashtirdi";
      } else if (upper == 'FAILED' || upper == 'FAIL' || upper == 'UNSATISFACTORY') {
        return "O'zlashtirmadi";
      }
    }

    return "Noma'lum";
  }
}
