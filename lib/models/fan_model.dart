class Kafedra {
  String? id;
  String? name;

  Kafedra({
    this.id,
    this.name,
  });

  Kafedra copyWith({
    String? id,
    String? name,
  }) =>
      Kafedra(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["id"] = id;
    map["name"] = name;
    return map;
  }

  Kafedra.fromJson(dynamic json) {
    id = json["id"];
    name = json["name"];
  }
}

class FanModel {
  String? id;
  Kafedra? kafedra;
  String? name;

  FanModel({
    this.id,
    this.kafedra,
    this.name,
  });

  FanModel copyWith({
    String? id,
    Kafedra? kafedra,
    String? name,
  }) =>
      FanModel(
        id: id ?? this.id,
        kafedra: kafedra ?? this.kafedra,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["id"] = id;
    if (kafedra != null) {
      map["kafedra"] = kafedra?.toJson();
    }
    map["name"] = name;
    return map;
  }

  FanModel.fromJson(dynamic json) {
    id = json["id"];
    kafedra = json["kafedra"] != null ? Kafedra.fromJson(json["kafedra"]) : null;
    name = json["name"];
  }
}

class FanRequestModel {
  String? name;
  String? kafedraId;

  FanRequestModel({
    this.name,
    this.kafedraId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["name"] = name;
    map["kafedraId"] = kafedraId;
    return map;
  }

  FanRequestModel.fromJson(dynamic json) {
    name = json["name"];
    kafedraId = json["kafedraId"];
  }
}
