import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Word ro'yxatidagi bitta kursant qatori
class DocxStudentRow {
  final int rowNumber; // №
  final String fullName; // O'quvchining F.I.Sh.
  final String? birthDate; // "19.05.2011"
  final String? phone; // Kursantning o'z telefoni
  final Uint8List? photoBytes; // FOTO ustunidagi rasm
  final String photoExtension; // ".jpeg", ".png"

  const DocxStudentRow({
    required this.rowNumber,
    required this.fullName,
    this.birthDate,
    this.phone,
    this.photoBytes,
    this.photoExtension = '.jpg',
  });

  /// "Abduraxmonov Ibroximjon El’yor o‘g‘li" -> (familiya, ism, otasining ismi)
  (String lastName, String firstName, String patronymic) get nameParts {
    final parts = fullName.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return ('', '', '');
    if (parts.length == 1) return (parts[0], '', '');
    return (parts[0], parts[1], parts.skip(2).join(' '));
  }
}

/// Hujjatdagi bitta guruh (masalan "11/26-GURUH") va uning kursantlari
class DocxGroup {
  final String name;
  final List<DocxStudentRow> students;

  const DocxGroup({required this.name, required this.students});
}

class DocxImportResult {
  final String fileName;
  final List<DocxGroup> groups;

  const DocxImportResult({required this.fileName, required this.groups});

  int get totalStudents => groups.fold(0, (sum, g) => sum + g.students.length);
  int get totalPhotos => groups.fold(0, (sum, g) => sum + g.students.where((s) => s.photoBytes != null).length);
}

/// "UMUMIY RO'YXAT" kabi .docx fayllardan guruh kesimida kursantlar
/// (F.I.Sh., tug'ilgan sana, telefon va foto) ro'yxatini ajratib oladi.
class DocxImportService {
  static final DocxImportService instance = DocxImportService._internal();

  DocxImportService._internal();

  /// Diskdan .docx faylni tanlash va o'qish. Foydalanuvchi bekor qilsa null qaytaradi.
  Future<DocxImportResult?> pickAndParse() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final groups = await compute(parseDocx, bytes);
    return DocxImportResult(fileName: file.name, groups: groups);
  }
}

const _wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
const _rNs = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

final _groupTitle = RegExp(r'guruh', caseSensitive: false);
final _datePattern = RegExp(r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{4})\b');
final _phonePattern = RegExp(r'tel\s*[:.]?\s*([+\d][\d\s()-]{6,})', caseSensitive: false);

/// .docx baytlarini tahlil qiladi (isolate ichida ishlashi uchun top-level).
List<DocxGroup> parseDocx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('Fayl .docx formatida emas');
  }

  String? readText(String name) {
    final entry = archive.findFile(name);
    if (entry == null) return null;
    return utf8.decode(entry.content as List<int>, allowMalformed: true);
  }

  final documentXml = readText('word/document.xml');
  if (documentXml == null) {
    throw const FormatException('Word hujjat tarkibi topilmadi');
  }

  // Rasm havolalari: rId -> word/media/imageN.jpeg
  final media = <String, String>{};
  final relsXml = readText('word/_rels/document.xml.rels');
  if (relsXml != null) {
    for (final rel in XmlDocument.parse(relsXml).findAllElements('Relationship')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      if (id == null || target == null || rel.getAttribute('TargetMode') == 'External') continue;
      media[id] = target.startsWith('/') ? target.substring(1) : p.posix.normalize('word/$target');
    }
  }

  (Uint8List, String)? loadImage(XmlElement cell) {
    for (final el in cell.descendantElements) {
      final isBlip = el.name.local == 'blip' || el.name.local == 'imagedata';
      if (!isBlip) continue;
      final relId = el.getAttribute('embed', namespace: _rNs) ?? el.getAttribute('id', namespace: _rNs);
      final path = media[relId];
      final entry = path == null ? null : archive.findFile(path);
      if (entry == null) continue;
      return (Uint8List.fromList(entry.content as List<int>), p.extension(path!).toLowerCase());
    }
    return null;
  }

  final body = XmlDocument.parse(documentXml).findAllElements('body', namespace: _wNs).firstOrNull;
  if (body == null) {
    throw const FormatException('Word hujjat tarkibi topilmadi');
  }

  final groups = <DocxGroup>[];
  String? currentGroup;
  var currentStudents = <DocxStudentRow>[];

  void startGroup(String title) {
    if (currentGroup != null && currentStudents.isNotEmpty) {
      groups.add(DocxGroup(name: currentGroup!, students: currentStudents));
    }
    currentGroup = normalizeGroupName(title);
    currentStudents = [];
  }

  for (final node in body.childElements) {
    if (node.name.local == 'p') {
      // Jadvaldan tashqaridagi "11/26-GURUH" sarlavhasi
      final text = _paragraphText(node);
      if (_groupTitle.hasMatch(text) && text.length <= 40 && !text.toLowerCase().contains('rahbar')) {
        startGroup(text);
      }
      continue;
    }
    if (node.name.local != 'tbl') continue;

    var nameCol = 1, photoCol = 2;
    for (final tr in node.findElements('tr', namespace: _wNs)) {
      final cells = tr.findElements('tc', namespace: _wNs).toList();
      final texts = cells.map(_cellText).toList();
      final joined = texts.join(' ').trim();
      if (joined.isEmpty && cells.every((c) => loadImage(c) == null)) continue;

      // Guruh nomi qatori: bitta to'ldirilgan katak, "GURUH" so'zi bilan
      final filled = texts.where((t) => t.trim().isNotEmpty).toList();
      if (filled.length == 1 && _groupTitle.hasMatch(filled.first) && int.tryParse(filled.first.trim()) == null) {
        startGroup(filled.first);
        continue;
      }

      final number = int.tryParse(texts.first.trim());
      if (number == null) {
        // Sarlavha qatori: ustunlar o'rnini aniqlaymiz
        final headerName = texts.indexWhere((t) => RegExp(r'f\.\s*i\.\s*(sh|o)', caseSensitive: false).hasMatch(t));
        if (headerName >= 0) {
          nameCol = headerName;
          final headerPhoto = texts.indexWhere((t) => RegExp(r'foto|rasm|surat', caseSensitive: false).hasMatch(t));
          if (headerPhoto >= 0) photoCol = headerPhoto;
        }
        continue;
      }
      if (nameCol >= cells.length) continue;

      final student = _parseStudentCell(texts[nameCol], number);
      if (student == null) continue;

      // Avval FOTO ustunidan, topilmasa qatorning istalgan joyidan rasm olamiz
      final image = (photoCol < cells.length ? loadImage(cells[photoCol]) : null) ??
          cells.map(loadImage).whereType<(Uint8List, String)>().firstOrNull;

      currentGroup ??= 'Guruhsiz';
      currentStudents.add(DocxStudentRow(
        rowNumber: student.rowNumber,
        fullName: student.fullName,
        birthDate: student.birthDate,
        phone: student.phone,
        photoBytes: image?.$1,
        photoExtension: image?.$2 ?? '.jpg',
      ));
    }
  }
  if (currentGroup != null && currentStudents.isNotEmpty) {
    groups.add(DocxGroup(name: currentGroup!, students: currentStudents));
  }

  if (groups.isEmpty) {
    throw const FormatException('Faylda kursantlar topilmadi. Jadval tuzilishini tekshiring.');
  }
  return groups;
}

/// "11/26-GURUH" -> "11/26-guruh" (tizimdagi "10-25-guruh" ko'rinishiga moslab)
String normalizeGroupName(String raw) {
  final base = raw.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'guruh[iy]?', caseSensitive: false), '').trim();
  final cleaned = base.replaceAll(RegExp(r'^[\s\-–—:]+|[\s\-–—:]+$'), '');
  return cleaned.isEmpty ? raw.trim() : '$cleaned-guruh';
}

/// Guruh nomlarini solishtirish uchun kalit: "11/26-guruh" == "11/26 GURUH"
String groupKey(String name) => name.toLowerCase().replaceAll(RegExp(r'guruh[iy]?|[\s\-–—]'), '');

/// "Abduraxmonov Ibroximjon El’yor o‘g‘li 19/05/2011 Tel: 982733357"
DocxStudentRow? _parseStudentCell(String text, int number) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.isEmpty) return null;

  final date = _datePattern.firstMatch(flat);
  final telIndex = flat.toLowerCase().indexOf('tel');
  var nameEnd = flat.length;
  if (date != null) nameEnd = date.start;
  if (telIndex >= 0 && telIndex < nameEnd) nameEnd = telIndex;

  final name = flat.substring(0, nameEnd).trim().replaceAll(RegExp(r'[,;]+$'), '');
  if (name.isEmpty) return null;

  String? birthDate;
  if (date != null) {
    birthDate = '${date.group(1)!.padLeft(2, '0')}.${date.group(2)!.padLeft(2, '0')}.${date.group(3)}';
  }

  return DocxStudentRow(
    rowNumber: number,
    fullName: name,
    birthDate: birthDate,
    phone: _formatPhone(_phonePattern.firstMatch(flat)?.group(1)),
  );
}

/// "982733357" -> "+998 98 273 33 57"; "yoq" kabi qiymatlar null bo'ladi
String? _formatPhone(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('998')) digits = digits.substring(3);
  if (digits.length != 9) return digits.length >= 7 ? digits : null;
  return '+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7)}';
}

/// Katak matni: paragraflar orasiga bo'sh joy qo'yiladi ("o‘g‘li" + "06/05/2011" yopishib qolmasligi uchun)
String _cellText(XmlElement cell) =>
    cell.findAllElements('p', namespace: _wNs).map(_paragraphText).where((t) => t.isNotEmpty).join(' ').trim();

String _paragraphText(XmlElement paragraph) {
  final buffer = StringBuffer();
  for (final el in paragraph.descendantElements) {
    switch (el.name.local) {
      case 't':
        buffer.write(el.innerText);
      case 'tab':
      case 'br':
        buffer.write(' ');
    }
  }
  return buffer.toString().trim();
}
