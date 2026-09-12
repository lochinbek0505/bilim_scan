class User {
  dynamic bosqich;
  dynamic fan;
  dynamic firstName;
  dynamic guruh;
  String? id;
  dynamic kafedra;
  dynamic lastName;
  dynamic patronymic;
  dynamic profileImageUrl;
  String? role;
  String? username;

  User({
    this.bosqich, this.fan, this.firstName, this.guruh, this.id, this.kafedra, this.lastName, this.patronymic, this.profileImageUrl, this.role, this.username
  });

  User copyWith({
    dynamic bosqich, dynamic fan, dynamic firstName, dynamic guruh, String? id, dynamic kafedra, dynamic lastName, dynamic patronymic, dynamic profileImageUrl, String? role, String? username
  }) =>
      User(bosqich: bosqich ?? this.bosqich,
          fan: fan ?? this.fan,
          firstName: firstName ?? this.firstName,
          guruh: guruh ?? this.guruh,
          id: id ?? this.id,
          kafedra: kafedra ?? this.kafedra,
          lastName: lastName ?? this.lastName,
          patronymic: patronymic ?? this.patronymic,
          profileImageUrl: profileImageUrl ?? this.profileImageUrl,
          role: role ?? this.role,
          username: username ?? this.username);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["bosqich"] = bosqich;
    map["fan"] = fan;
    map["firstName"] = firstName;
    map["guruh"] = guruh;
    map["id"] = id;
    map["kafedra"] = kafedra;
    map["lastName"] = lastName;
    map["patronymic"] = patronymic;
    map["profileImageUrl"] = profileImageUrl;
    map["role"] = role;
    map["username"] = username;
    return map;
  }

  User.fromJson(dynamic json) {
    bosqich = json["bosqich"];
    fan = json["fan"];
    firstName = json["firstName"];
    guruh = json["guruh"];
    id = json["id"];
    kafedra = json["kafedra"];
    lastName = json["lastName"];
    patronymic = json["patronymic"];
    profileImageUrl = json["profileImageUrl"];
    role = json["role"];
    username = json["username"];
  }
}

class LoginModel {
  String? token;
  User? user;

  LoginModel({
    this.token, this.user
  });

  LoginModel copyWith({
    String? token, User? user
  }) => LoginModel(token: token ?? this.token, user: user ?? this.user);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["token"] = token;
    if (user != null) {
      map["user"] = user?.toJson();
    }
    return map;
  }

  LoginModel.fromJson(dynamic json) {
    token = json["token"];
    user = json["user"] != null ? User.fromJson(json["user"]) : null;
  }
}