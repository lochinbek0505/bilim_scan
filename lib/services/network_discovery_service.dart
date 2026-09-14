import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

class NetworkDiscoveryService {
  // Spring Boot UDP discovery settings
  static const int _discoveryPort = 8888;
  static const String _discoverMessage = "DISCOVER_BILIMSCAN";
  static const String _expectedResponsePrefix = "BILIMSCAN_HERE";

  /// Tarmoqni skaner qiladi va topilsa Server IP manzilini qaytaradi.
  /// Topilmasa yoki xatolik bo'lsa `null` qaytaradi.
  static Future<String?> discoverServerIp({Duration timeout = const Duration(seconds: 3)}) async {
    // Web (Chrome/Browser) platformasida raw UDP socketlar brauzer xavfsizligi tufayli ishlamaydi
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('ℹ️ [UDP DISCOVERY] Web (Chrome) platformasida UDP socket brauzer tomonidan qo\'llab-quvvatlanmaydi. Standard BaseURL: ${ApiConfig.baseUrl}');
      }
      return null;
    }

    RawDatagramSocket? socket;
    Completer<String?> completer = Completer();

    if (kDebugMode) {
      debugPrint('🔍 [UDP DISCOVERY] Localhost/Server IP qidirilmoqda... Broadcast port: $_discoveryPort');
    }

    try {
      // Socket tayyorlanadi
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      if (kDebugMode) {
        debugPrint('📡 [UDP DISCOVERY] Socket muvaffaqiyatli bog\'landi. Port: ${socket.port}');
      }

      // Tarmoqdan keladigan javoblarni o'qish
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket?.receive();
          if (datagram != null) {
            String message = utf8.decode(datagram.data).trim();
            final ip = datagram.address.address;

            if (kDebugMode) {
              debugPrint('📥 [UDP DISCOVERY] Paket keldi -> IP: $ip, Message: "$message"');
            }

            // Serverimizdan javob kelsa
            if (message.startsWith(_expectedResponsePrefix)) {
              if (kDebugMode) {
                debugPrint('🎯 [UDP DISCOVERY SUCCESS] Server topildi: $ip ($message)');
              }

              if (!completer.isCompleted) {
                completer.complete(ip);
              }
            }
          }
        }
      });

      // So'rovni barcha tarmoqqa (Broadcast) yuborish
      List<int> sendData = utf8.encode(_discoverMessage);
      socket.send(sendData, InternetAddress("255.255.255.255"), _discoveryPort);

      if (kDebugMode) {
        debugPrint('📤 [UDP DISCOVERY] Broadcast paket yuborildi: "$_discoverMessage" -> 255.255.255.255:$_discoveryPort');
      }

      // Timeout beramiz
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          if (kDebugMode) {
            debugPrint('⚠️ [UDP DISCOVERY TIMEOUT] Server (${timeout.inSeconds}s) ichida javob bermadi. Sukut bo\'yicha URL ishlatiladi.');
          }
          completer.complete(null);
        }
      });

    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ [UDP DISCOVERY ERR] Skanerlashda xatolik yuz berdi: $e');
        debugPrint(stack.toString());
      }
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    } finally {
      completer.future.then((_) {
        try {
          socket?.close();
          if (kDebugMode) {
            debugPrint('🔒 [UDP DISCOVERY] Socket yopildi.');
          }
        } catch (_) {}
      });
    }

    final discoveredIp = await completer.future;

    if (discoveredIp != null && discoveredIp.isNotEmpty) {
      ApiConfig.setDiscoveredHost(discoveredIp);
      ApiService().updateBaseUrl(ApiConfig.baseUrl);
      if (kDebugMode) {
        debugPrint('🚀 [UDP DISCOVERY DONE] Yangi dinamik API BaseURL: ${ApiConfig.baseUrl}');
      }
    } else {
      if (kDebugMode) {
        debugPrint('ℹ️ [UDP DISCOVERY FALLBACK] Sukut bo\'yicha BaseURL: ${ApiConfig.baseUrl}');
      }
    }

    return discoveredIp;
  }
}
