import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_export_model.dart';

class PdfExportService {
  static Future<void> exportResultsToPdf(
      List<StudentExportData> students, String fileName) async {
    try {
      final doc = pw.Document();

      final fontData = await PdfGoogleFonts.robotoRegular();
      final fontBoldData = await PdfGoogleFonts.robotoBold();

      for (var data in students) {
        final student = data.student;
        final fullName = '${student.lastName ?? ''} ${student.firstName ?? ''} ${student.patronymic ?? ''}'.trim();
        
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
                              'Umumiy holat: ${_translateMastery(data.monitoringData.overallMastery)}',
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
                              .map((e) => '${e.examName ?? "Imtihon"}: ${e.percentage?.toStringAsFixed(1) ?? "0.0"}% (${_translateMastery(e.masteryLevel)})')
                              .join('\n');
                          return [
                            subject.subjectName ?? "Noma'lum fan",
                            '${subject.averagePercentage?.toStringAsFixed(1) ?? '0.0'}%',
                            _translateMastery(subject.subjectMastery),
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

      final pdfBytes = await doc.save();
      final name = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';

      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: name,
        );
      } catch (e) {
        debugPrint("Printing kanali topilmadi, FilePicker ishlatilmoqda: $e");
        await FilePicker.saveFile(
          fileName: name,
          bytes: pdfBytes,
        );
      }
    } catch (e) {
      debugPrint("PDF eksportida xatolik: $e");
    }
  }

  static String _translateMastery(String? mastery) {
    if (mastery == null || mastery.trim().isEmpty) return "Noma'lum";
    final upper = mastery.toUpperCase().trim();
    if (upper == 'HIGH_MASTERY' || upper == 'EXCELLENT' || upper == 'PASSED_HIGH') {
      return "O'zlashtirdi";
    } else if (upper == 'PASSED' || upper == 'SATISFACTORY' || upper == 'GOOD') {
      return "Qoniqarli";
    } else if (upper == 'FAILED' || upper == 'FAIL' || upper == 'UNSATISFACTORY') {
      return "O'zlashtirmadi";
    }
    return "Noma'lum";
  }
}
