class CatalogRequestModel {
  String? name;

  CatalogRequestModel({
    this.name
  });

  CatalogRequestModel copyWith({
    String? name
  }) => CatalogRequestModel(name: name ?? this.name);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["name"] = name;
    return map;
  }

  CatalogRequestModel.fromJson(dynamic json) {
    name = json["name"];
  }
}