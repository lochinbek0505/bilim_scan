import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yaratilgan foydalanuvchining login/paroli (server parolni qaytarmagani uchun lokal saqlanadi)
class UserCredential {
  final String userId;
  final String fullName;
  final String username;
  final String password;
  final String? guruhId;
  final String? guruhName;
  final String? bosqichName;

  const UserCredential({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.password,
    this.guruhId,
    this.guruhName,
    this.bosqichName,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'username': username,
        'password': password,
        'guruhId': guruhId,
        'guruhName': guruhName,
        'bosqichName': bosqichName,
      };

  factory UserCredential.fromJson(Map<String, dynamic> json) => UserCredential(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String? ?? '',
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        guruhId: json['guruhId'] as String?,
        guruhName: json['guruhName'] as String?,
        bosqichName: json['bosqichName'] as String?,
      );
}

class CredentialsService {
  static final CredentialsService _instance = CredentialsService._internal();
  factory CredentialsService() => _instance;

  CredentialsService._internal();

  static const String _keyCredentials = 'generated_user_credentials';
  static final Random _random = Random.secure();

  /// "Ibroximjon" + "Abduraxmonov" -> "ibroximjon_abduraxmonov" (band bo'lsa "_2", "_3" ...)
  static String generateUsername(String firstName, String lastName, Set<String> taken) {
    String clean(String str) => str.toLowerCase().replaceAll(RegExp(r"[ʻʼ‘’'`]"), '').replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');

    final fn = clean(firstName);
    final ln = clean(lastName);
    final base = [fn, ln].where((s) => s.isNotEmpty).join('_');
    final root = base.isEmpty ? 'user' : base;

    var candidate = root;
    for (var i = 2; taken.contains(candidate); i++) {
      candidate = '${root}_$i';
    }
    return candidate;
  }

  /// "Ibroximjon" -> "Ibroximjon@482913"
  static String generatePassword(String firstName) {
    final fn = firstName.replaceAll(RegExp(r"[^A-Za-z]"), '');
    final fnCap = fn.isNotEmpty ? fn[0].toUpperCase() + fn.substring(1).toLowerCase() : 'User';
    return '$fnCap@${100000 + _random.nextInt(900000)}';
  }

  Future<Map<String, UserCredential>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyCredentials);
      if (jsonStr == null || jsonStr.isEmpty) return {};
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, UserCredential.fromJson(v as Map<String, dynamic>)));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CREDENTIALS LOAD ERR]: $e');
      }
      return {};
    }
  }

  Future<void> saveAll(Iterable<UserCredential> credentials) async {
    try {
      final all = await loadAll();
      for (final c in credentials) {
        all[c.userId] = c;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCredentials, jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CREDENTIALS SAVE ERR]: $e');
      }
    }
  }

  Future<void> remove(String userId) async {
    final all = await loadAll();
    if (all.remove(userId) == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCredentials, jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))));
  }

  /// Guruh kesimida F.I.Sh., login va parollarni Word (.doc) faylga eksport qiladi.
  /// Har bir guruh alohida sahifada. Saqlangan fayl manzilini qaytaradi.
  static Future<String?> exportToWord(List<UserCredential> credentials, String fileName) async {
    try {
      String esc(String? s) => const HtmlEscape().convert(s ?? '');

      final byGroup = <String, List<UserCredential>>{};
      for (final c in credentials) {
        byGroup.putIfAbsent(c.guruhName ?? 'Guruhsiz', () => []).add(c);
      }
      final groupNames = byGroup.keys.toList()..sort();

      final html = StringBuffer()
        ..writeln('''
        <html xmlns:o='urn:schemas-microsoft-com:office:office'
              xmlns:w='urn:schemas-microsoft-com:office:word'
              xmlns='http://www.w3.org/TR/REC-html40'>
        <head>
          <meta charset="utf-8">
          <title>Login va parollar</title>
          <style>
            body { font-family: 'Times New Roman', serif; font-size: 14px; }
            .group { page-break-after: always; }
            .group:last-child { page-break-after: auto; }
            h2 { text-align: center; margin-bottom: 4px; }
            .sub { text-align: center; margin-bottom: 14px; }
            table { width: 100%; border-collapse: collapse; }
            th, td { border: 1px solid black; padding: 6px 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            td.num { width: 36px; text-align: center; }
            td.mono { font-family: 'Courier New', monospace; }
          </style>
        </head>
        <body>
      ''');

      for (final group in groupNames) {
        final rows = byGroup[group]!..sort((a, b) => a.fullName.compareTo(b.fullName));
        final bosqich = rows.map((c) => c.bosqichName).whereType<String>().firstOrNull;
        html.writeln('<div class="group">');
        html.writeln('<h2>${esc(group.toUpperCase())}</h2>');
        html.writeln('<div class="sub">${bosqich != null ? '${esc(bosqich)} &nbsp;•&nbsp; ' : ''}Jami: ${rows.length} nafar</div>');
        html.writeln('<table><tr><th>№</th><th>F.I.Sh.</th><th>Login</th><th>Parol</th></tr>');
        for (var i = 0; i < rows.length; i++) {
          final c = rows[i];
          html.writeln(
            '<tr><td class="num">${i + 1}</td><td>${esc(c.fullName)}</td>'
            '<td class="mono">${esc(c.username)}</td><td class="mono">${esc(c.password.isEmpty ? '—' : c.password)}</td></tr>',
          );
        }
        html.writeln('</table></div>');
      }
      html.writeln('</body></html>');

      final bytes = Uint8List.fromList(utf8.encode(html.toString()));
      final name = fileName.endsWith('.doc') ? fileName : '$fileName.doc';
      final savedUri = await FilePicker.saveFile(fileName: name, bytes: bytes);
      return savedUri?.toString();
    } catch (e) {
      debugPrint('Login/parol eksportida xatolik: $e');
      return null;
    }
  }
}
