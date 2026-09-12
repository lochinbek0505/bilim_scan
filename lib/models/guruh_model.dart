class Bosqich {
  String? id;
  String? name;

  Bosqich({
    this.id,
    this.name,
  });

  Bosqich copyWith({
    String? id,
    String? name,
  }) =>
      Bosqich(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["id"] = id;
    map["name"] = name;
    return map;
  }

  Bosqich.fromJson(dynamic json) {
    id = json["id"];
    name = json["name"];
  }
}

class GuruhModel {
  Bosqich? bosqich;
  String? id;
  String? name;

  GuruhModel({
    this.bosqich,
    this.id,
    this.name,
  });

  GuruhModel copyWith({
    Bosqich? bosqich,
    String? id,
    String? name,
  }) =>
      GuruhModel(
        bosqich: bosqich ?? this.bosqich,
        id: id ?? this.id,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (bosqich != null) {
      map["bosqich"] = bosqich?.toJson();
    }
    map["id"] = id;
    map["name"] = name;
    return map;
  }

  GuruhModel.fromJson(dynamic json) {
    bosqich = json["bosqich"] != null ? Bosqich.fromJson(json["bosqich"]) : null;
    id = json["id"];
    name = json["name"];
  }
}

class GuruhRequestModel {
  String? name;
  String? bosqichId;

  GuruhRequestModel({
    this.name,
    this.bosqichId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["name"] = name;
    map["bosqichId"] = bosqichId;
    return map;
  }

  GuruhRequestModel.fromJson(dynamic json) {
    name = json["name"];
    bosqichId = json["bosqichId"];
  }
}
