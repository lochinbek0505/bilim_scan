import 'package:flutter/material.dart';
import '../models/catalog_request_model.dart';
import '../models/catalog_response.dart';
import '../models/fan_model.dart';
import '../models/guruh_model.dart';
import '../services/catalog_service.dart';

enum CatalogType { bosqich, fan, guruh, kafedra }

extension CatalogTypeExtension on CatalogType {
  String get title {
    switch (this) {
      case CatalogType.bosqich:
        return 'KURS BOSQICHLARI';
      case CatalogType.fan:
        return 'O\'QUV FANLARI';
      case CatalogType.guruh:
        return 'O\'QUV GURUHLARI';
      case CatalogType.kafedra:
        return 'KAFEDRALAR';
    }
  }
}

class CatalogProvider extends ChangeNotifier {
  final CatalogService _service = CatalogService();

  bool _isLoading = false;
  String _searchQuery = '';

  List<CatalogResponse> _bosqichlar = [];
  List<CatalogResponse> _kafedralar = [];
  List<FanModel> _fanlar = [];
  List<GuruhModel> _guruhlar = [];

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<CatalogResponse> get bosqichlar => _filterList(_bosqichlar);
  List<CatalogResponse> get kafedralar => _filterList(_kafedralar);

  List<FanModel> get fanlar {
    if (_searchQuery.isEmpty) return _fanlar;
    return _fanlar.where((item) => (item.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<GuruhModel> get guruhlar {
    if (_searchQuery.isEmpty) return _guruhlar;
    return _guruhlar.where((item) => (item.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<CatalogResponse> _filterList(List<CatalogResponse> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((item) => (item.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  CatalogProvider() {
    fetchAllCatalogs();
  }

  Future<void> fetchAllCatalogs() async {
    _isLoading = true;
    notifyListeners();

    final bList = await _service.getBosqichlar();
    if (bList.isNotEmpty) _bosqichlar = bList;

    final kList = await _service.getKafedralar();
    if (kList.isNotEmpty) _kafedralar = kList;

    final fList = await _service.getFanlar();
    if (fList.isNotEmpty) _fanlar = fList;

    final gList = await _service.getGuruhlar();
    if (gList.isNotEmpty) _guruhlar = gList;

    _isLoading = false;
    notifyListeners();
  }

  // --- CRUD ACTIONS FOR BOSQICHLAR ---
  Future<bool> createBosqich(String name) async {
    final result = await _service.createBosqich(CatalogRequestModel(name: name));
    final newObj = result ?? CatalogResponse(id: 'bosqich_${DateTime.now().millisecondsSinceEpoch}', name: name);
    _bosqichlar.add(newObj);
    notifyListeners();
    return true;
  }

  Future<bool> updateBosqich(String id, String newName) async {
    await _service.updateBosqich(CatalogRequestModel(name: newName), id);
    final idx = _bosqichlar.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _bosqichlar[idx] = CatalogResponse(id: id, name: newName);
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteBosqich(String id) async {
    await _service.deleteBosqich(id);
    _bosqichlar.removeWhere((e) => e.id == id);
    notifyListeners();
    return true;
  }

  // --- CRUD ACTIONS FOR KAFEDRALAR ---
  Future<bool> createKafedra(String name) async {
    final result = await _service.createKafedra(CatalogRequestModel(name: name));
    final newObj = result ?? CatalogResponse(id: 'kafedra_${DateTime.now().millisecondsSinceEpoch}', name: name);
    _kafedralar.add(newObj);
    notifyListeners();
    return true;
  }

  Future<bool> updateKafedra(String id, String newName) async {
    await _service.updateKafedra(CatalogRequestModel(name: newName), id);
    final idx = _kafedralar.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _kafedralar[idx] = CatalogResponse(id: id, name: newName);
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteKafedra(String id) async {
    await _service.deleteKafedra(id);
    _kafedralar.removeWhere((e) => e.id == id);
    notifyListeners();
    return true;
  }

  // --- CRUD ACTIONS FOR GURUHLAR (Request: {"name": "...", "bosqichId": "..."}) ---
  Future<bool> createGuruh(String name, String bosqichId) async {
    final req = GuruhRequestModel(name: name, bosqichId: bosqichId);
    final result = await _service.createGuruh(req);

    // Find bosqich name for local UI fallback
    final b = _bosqichlar.firstWhere(
      (element) => element.id == bosqichId,
      orElse: () => CatalogResponse(id: bosqichId, name: 'Bosqich'),
    );

    final newObj = result ??
        GuruhModel(
          id: 'guruh_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          bosqich: Bosqich(id: b.id, name: b.name),
        );

    _guruhlar.add(newObj);
    notifyListeners();
    return true;
  }

  Future<bool> updateGuruh(String id, String name, String bosqichId) async {
    final req = GuruhRequestModel(name: name, bosqichId: bosqichId);
    await _service.updateGuruh(req, id);

    final b = _bosqichlar.firstWhere(
      (element) => element.id == bosqichId,
      orElse: () => CatalogResponse(id: bosqichId, name: 'Bosqich'),
    );

    final idx = _guruhlar.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _guruhlar[idx] = GuruhModel(
        id: id,
        name: name,
        bosqich: Bosqich(id: b.id, name: b.name),
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteGuruh(String id) async {
    await _service.deleteGuruh(id);
    _guruhlar.removeWhere((e) => e.id == id);
    notifyListeners();
    return true;
  }

  // --- CRUD ACTIONS FOR FANLAR (Request: {"name": "...", "kafedraId": "..."}) ---
  Future<bool> createFan(String name, String kafedraId) async {
    final req = FanRequestModel(name: name, kafedraId: kafedraId);
    final result = await _service.createFan(req);

    final k = _kafedralar.firstWhere(
      (element) => element.id == kafedraId,
      orElse: () => CatalogResponse(id: kafedraId, name: 'Kafedra'),
    );

    final newObj = result ??
        FanModel(
          id: 'fan_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          kafedra: Kafedra(id: k.id, name: k.name),
        );

    _fanlar.add(newObj);
    notifyListeners();
    return true;
  }

  Future<bool> updateFan(String id, String name, String kafedraId) async {
    final req = FanRequestModel(name: name, kafedraId: kafedraId);
    await _service.updateFan(req, id);

    final k = _kafedralar.firstWhere(
      (element) => element.id == kafedraId,
      orElse: () => CatalogResponse(id: kafedraId, name: 'Kafedra'),
    );

    final idx = _fanlar.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _fanlar[idx] = FanModel(
        id: id,
        name: name,
        kafedra: Kafedra(id: k.id, name: k.name),
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteFan(String id) async {
    await _service.deleteFan(id);
    _fanlar.removeWhere((e) => e.id == id);
    notifyListeners();
    return true;
  }
}
