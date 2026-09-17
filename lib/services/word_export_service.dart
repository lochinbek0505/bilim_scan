import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/student_export_model.dart';

class WordExportService {
  static Future<String?> exportResultsToDoc(
      List<StudentExportData> students, String fileName) async {
    try {
      StringBuffer htmlContent = StringBuffer();
      
      htmlContent.writeln('''
        <html xmlns:o='urn:schemas-microsoft-com:office:office' 
              xmlns:w='urn:schemas-microsoft-com:office:word' 
              xmlns='http://www.w3.org/TR/REC-html40'>
        <head>
          <meta charset="utf-8">
          <title>Imtihon Natijalari</title>
          <style>
            body { font-family: 'Times New Roman', serif; }
            .student-card { 
              border: 1px solid #000; 
              padding: 20px; 
              margin-bottom: 30px; 
              page-break-after: always;
            }
            .header-info { text-align: center; font-size: 18px; font-weight: bold; margin-bottom: 20px; }
            table { width: 100%; border-collapse: collapse; margin-top: 15px; margin-bottom: 25px; }
            th, td { border: 1px solid black; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            .profile-img { width: 120px; height: 150px; object-fit: cover; border: 1px solid #ccc; }
            .section-title { font-weight: bold; margin-top: 15px; margin-bottom: 5px; font-size: 16px; }
          </style>
        </head>
        <body>
      ''');

      for (var data in students) {
        final student = data.student;
        final fullName = '${student.lastName ?? ''} ${student.firstName ?? ''} ${student.patronymic ?? ''}'.trim();
        
        final guruhMap = student.guruh;
        final guruhName = (guruhMap != null) ? (guruhMap.name ?? "Guruh kiritilmagan") : "Guruh kiritilmagan";
        
        final bosqichMap = student.bosqich;
        final bosqichName = (bosqichMap != null) ? (bosqichMap.name ?? "Bosqich kiritilmagan") : "Bosqich kiritilmagan";
        
        String imageHtml = '';
        if (data.base64Image != null && data.base64Image!.isNotEmpty) {
          imageHtml = '<img src="data:image/jpeg;base64,${data.base64Image}" alt="profile" class="profile-img" />';
        } else {
          imageHtml = '''<div style="width:120px; height:150px; border:1px solid #000; text-align:center; line-height:150px;">Rasm yo'q</div>''';
        }

        htmlContent.writeln('''
          <div class="student-card">
            <div class="header-info">IMTIHON NATIJALARI (MONITORING)</div>
            <table style="border: none;">
              <tr style="border: none;">
                <td style="border: none; width: 150px;">$imageHtml</td>
                <td style="border: none; vertical-align: top;">
                  <h3>$fullName</h3>
                  <p><strong>Bosqich:</strong> $bosqichName</p>
                  <p><strong>Guruh:</strong> $guruhName</p>
                  <p><strong>Umumiy o'zlashtirish foizi:</strong> ${data.monitoringData.overallPercentage?.toStringAsFixed(1) ?? '0.0'}%</p>
                  <p><strong>Umumiy holat:</strong> ${_translateMastery(data.monitoringData.overallPercentage, data.monitoringData.overallMastery)}</p>
                </td>
              </tr>
            </table>
        ''');

        for (var year in data.monitoringData.academicYears) {
          htmlContent.writeln('''<div class="section-title">O'quv yili: ${year.year ?? "Noma'lum"}</div>''');
          
          for (var month in year.months) {
            htmlContent.writeln('<div style="margin-left: 20px;">');
            htmlContent.writeln('<h4>Oy: ${month.month ?? "Noma'lum"}</h4>');
            
            htmlContent.writeln('''
              <table>
                <tr>
                  <th>Fan nomi</th>
                  <th>O'rtacha foiz</th>
                  <th>O'zlashtirish</th>
                  <th>Imtihonlar</th>
                </tr>
            ''');
            
            for (var subject in month.subjects) {
              String examsHtml = "<ul>";
              for (var exam in subject.exams) {
                examsHtml += "<li>${exam.examName ?? 'Imtihon'} (${exam.percentage?.toStringAsFixed(1) ?? '0.0'}% - ${_translateMastery(exam.percentage, exam.masteryLevel)})</li>";
              }
              examsHtml += "</ul>";
              
              htmlContent.writeln('''
                <tr>
                  <td>${subject.subjectName ?? "Noma'lum fan"}</td>
                  <td>${subject.averagePercentage?.toStringAsFixed(1) ?? '0.0'}%</td>
                  <td>${_translateMastery(subject.averagePercentage, subject.subjectMastery)}</td>
                  <td>$examsHtml</td>
                </tr>
              ''');
            }
            htmlContent.writeln('</table></div>');
          }
        }
        htmlContent.writeln('</div>');
      }

      htmlContent.writeln('</body></html>');

      final bytes = Uint8List.fromList(utf8.encode(htmlContent.toString()));
      final name = fileName.endsWith('.doc') ? fileName : '$fileName.doc';

      final savedUri = await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
      );

      return savedUri?.toString();
    } catch (e) {
      debugPrint("Word eksportida xatolik: $e");
      return null;
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
