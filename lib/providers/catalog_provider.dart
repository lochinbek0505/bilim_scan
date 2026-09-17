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
    if (result != null) {
      _bosqichlar.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateBosqich(String id, String newName) async {
    final result = await _service.updateBosqich(CatalogRequestModel(name: newName), id);
    if (result != null) {
      final idx = _bosqichlar.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _bosqichlar[idx] = CatalogResponse(id: id, name: newName);
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteBosqich(String id) async {
    final result = await _service.deleteBosqich(id);
    if (result) {
      _bosqichlar.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- CRUD ACTIONS FOR KAFEDRALAR ---
  Future<bool> createKafedra(String name) async {
    final result = await _service.createKafedra(CatalogRequestModel(name: name));
    if (result != null) {
      _kafedralar.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateKafedra(String id, String newName) async {
    final result = await _service.updateKafedra(CatalogRequestModel(name: newName), id);
    if (result != null) {
      final idx = _kafedralar.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _kafedralar[idx] = CatalogResponse(id: id, name: newName);
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteKafedra(String id) async {
    final result = await _service.deleteKafedra(id);
    if (result) {
      _kafedralar.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- CRUD ACTIONS FOR GURUHLAR (Request: {"name": "...", "bosqichId": "..."}) ---
  Future<bool> createGuruh(String name, String bosqichId) async {
    final req = GuruhRequestModel(name: name, bosqichId: bosqichId);
    final result = await _service.createGuruh(req);
    if (result != null) {
      _guruhlar.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateGuruh(String id, String name, String bosqichId) async {
    final req = GuruhRequestModel(name: name, bosqichId: bosqichId);
    final result = await _service.updateGuruh(req, id);
    if (result != null) {
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
    return false;
  }

  Future<bool> deleteGuruh(String id) async {
    final result = await _service.deleteGuruh(id);
    if (result) {
      _guruhlar.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- CRUD ACTIONS FOR FANLAR (Request: {"name": "...", "kafedraId": "..."}) ---
  Future<bool> createFan(String name, String kafedraId) async {
    final req = FanRequestModel(name: name, kafedraId: kafedraId);
    final result = await _service.createFan(req);
    if (result != null) {
      _fanlar.add(result);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateFan(String id, String name, String kafedraId) async {
    final req = FanRequestModel(name: name, kafedraId: kafedraId);
    final result = await _service.updateFan(req, id);
    if (result != null) {
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
    return false;
  }

  Future<bool> deleteFan(String id) async {
    final result = await _service.deleteFan(id);
    if (result) {
      _fanlar.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }
}
