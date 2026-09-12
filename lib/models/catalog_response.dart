class CatalogResponse {
  String? id;
  String? name;

  CatalogResponse({
    this.id, this.name
  });

  CatalogResponse copyWith({
    String? id, String? name
  }) => CatalogResponse(id: id ?? this.id, name: name ?? this.name);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["id"] = id;
    map["name"] = name;
    return map;
  }

  CatalogResponse.fromJson(dynamic json) {
    id = json["id"];
    name = json["name"];
  }
}