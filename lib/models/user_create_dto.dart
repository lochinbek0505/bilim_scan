class UserCreateDto {
  String? username;
  String? password;
  String? role; // USER, TEACHER, ADMIN
  String? firstName;
  String? lastName;
  String? patronymic;
  String? profileImageUrl;
  String? bosqichId;
  String? guruhId;
  String? kafedraId;
  String? fanId;

  UserCreateDto({
    this.username,
    this.password,
    this.role = 'USER',
    this.firstName,
    this.lastName,
    this.patronymic,
    this.profileImageUrl,
    this.bosqichId,
    this.guruhId,
    this.kafedraId,
    this.fanId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (username != null) map["username"] = username;
    if (password != null && password!.isNotEmpty) map["password"] = password;
    if (role != null) map["role"] = role;
    if (firstName != null) map["firstName"] = firstName;
    if (lastName != null) map["lastName"] = lastName;
    if (patronymic != null) map["patronymic"] = patronymic;
    if (profileImageUrl != null) map["profileImageUrl"] = profileImageUrl;
    if (bosqichId != null) map["bosqichId"] = bosqichId;
    if (guruhId != null) map["guruhId"] = guruhId;
    if (kafedraId != null) map["kafedraId"] = kafedraId;
    if (fanId != null) map["fanId"] = fanId;
    return map;
  }

  factory UserCreateDto.fromJson(Map<String, dynamic> json) {
    return UserCreateDto(
      username: json["username"] as String?,
      password: json["password"] as String?,
      role: json["role"] as String?,
      firstName: json["firstName"] as String?,
      lastName: json["lastName"] as String?,
      patronymic: json["patronymic"] as String?,
      profileImageUrl: json["profileImageUrl"] as String?,
      bosqichId: json["bosqichId"] as String?,
      guruhId: json["guruhId"] as String?,
      kafedraId: json["kafedraId"] as String?,
      fanId: json["fanId"] as String?,
    );
  }
}
