import 'catalog_response.dart';
import 'fan_model.dart';
import 'guruh_model.dart';

class UserResponseDto {
  String? id;
  String? username;
  String? role; // ADMIN, OQITUVCHI, OQUVCHI
  String? firstName;
  String? lastName;
  String? patronymic;
  String? profileImageUrl;
  CatalogResponse? bosqich;
  GuruhModel? guruh;
  CatalogResponse? kafedra;
  FanModel? fan;

  UserResponseDto({
    this.id,
    this.username,
    this.role,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.profileImageUrl,
    this.bosqich,
    this.guruh,
    this.kafedra,
    this.fan,
  });

  String get fullName {
    final parts = [lastName, firstName, patronymic].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? (username ?? 'Foydalanuvchi') : parts.join(' ');
  }

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      id: json["id"] as String?,
      username: json["username"] as String?,
      role: json["role"] as String?,
      firstName: json["firstName"] as String?,
      lastName: json["lastName"] as String?,
      patronymic: json["patronymic"] as String?,
      profileImageUrl: json["profileImageUrl"] as String?,
      bosqich: json["bosqich"] != null ? CatalogResponse.fromJson(json["bosqich"]) : null,
      guruh: json["guruh"] != null ? GuruhModel.fromJson(json["guruh"]) : null,
      kafedra: json["kafedra"] != null ? CatalogResponse.fromJson(json["kafedra"]) : null,
      fan: json["fan"] != null ? FanModel.fromJson(json["fan"]) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["id"] = id;
    map["username"] = username;
    map["role"] = role;
    map["firstName"] = firstName;
    map["lastName"] = lastName;
    map["patronymic"] = patronymic;
    map["profileImageUrl"] = profileImageUrl;
    if (bosqich != null) map["bosqich"] = bosqich?.toJson();
    if (guruh != null) map["guruh"] = guruh?.toJson();
    if (kafedra != null) map["kafedra"] = kafedra?.toJson();
    if (fan != null) map["fan"] = fan?.toJson();
    return map;
  }
}
