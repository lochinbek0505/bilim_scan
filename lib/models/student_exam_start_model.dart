class Mavzu {
  String? id;
  String? name;
  String? planId;
  num? soat;
  num? tr;
  String? type;

  Mavzu({
    this.id, this.name, this.planId, this.soat, this.tr, this.type
  });

  Mavzu copyWith({
    String? id, String? name, String? planId, num? soat, num? tr, String? type
  }) =>
      Mavzu(id: id ?? this.id,
          name: name ?? this.name,
          planId: planId ?? this.planId,
          soat: soat ?? this.soat,
          tr: tr ?? this.tr,
          type: type ?? this.type);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["id"] = id;
    map["name"] = name;
    map["planId"] = planId;
    map["soat"] = soat;
    map["tr"] = tr;
    map["type"] = type;
    return map;
  }

  Mavzu.fromJson(dynamic json) {
    if (json is Map) {
      id = json["id"]?.toString();
      name = json["name"]?.toString();
      planId = json["planId"]?.toString();
      soat = json["soat"] is num ? json["soat"] : num.tryParse(json["soat"]?.toString() ?? '');
      tr = json["tr"] is num ? json["tr"] : num.tryParse(json["tr"]?.toString() ?? '');
      type = json["type"]?.toString();
    }
  }
}

class Option {
  dynamic isTrue;
  String? text;

  Option({
    this.isTrue, this.text
  });

  Option copyWith({
    dynamic isTrue, String? text
  }) => Option(isTrue: isTrue ?? this.isTrue, text: text ?? this.text);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["isTrue"] = isTrue;
    map["text"] = text;
    return map;
  }

  Option.fromJson(dynamic json) {
    if (json is String) {
      text = json;
      isTrue = false;
    } else if (json is Map) {
      isTrue = json["isTrue"] ?? json["isCorrect"] ?? false;
      text = json["text"]?.toString() ?? json["option"]?.toString() ?? '';
    }
  }
}

class Question {
  String? id;
  Mavzu? mavzu;
  List<Option>? optionsList;
  List<dynamic>? relatedQuestionIdsList;
  String? testId;
  String? title;
  String? type;

  List<Option>? get options => optionsList;

  Question({
    this.id, this.mavzu, this.optionsList, this.relatedQuestionIdsList, this.testId, this.title, this.type
  });

  Question copyWith({
    String? id, Mavzu? mavzu, List<Option>? optionsList, List<
        dynamic>? relatedQuestionIdsList, String? testId, String? title, String? type
  }) =>
      Question(id: id ?? this.id,
          mavzu: mavzu ?? this.mavzu,
          optionsList: optionsList ?? this.optionsList,
          relatedQuestionIdsList: relatedQuestionIdsList ??
              this.relatedQuestionIdsList,
          testId: testId ?? this.testId,
          title: title ?? this.title,
          type: type ?? this.type);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["id"] = id;
    if (mavzu != null) {
      map["mavzu"] = mavzu?.toJson();
    }
    if (optionsList != null) {
      map["options"] = optionsList?.map((v) => v.toJson()).toList();
    }
    if (relatedQuestionIdsList != null) {
      map["relatedQuestionIds"] = relatedQuestionIdsList;
    }
    map["testId"] = testId;
    map["title"] = title;
    map["type"] = type;
    return map;
  }

  Question.fromJson(dynamic json) {
    if (json is Map) {
      id = (json["id"] ?? json["_id"] ?? '').toString();
      mavzu = json["mavzu"] != null ? Mavzu.fromJson(json["mavzu"]) : null;
      if (json["options"] != null && json["options"] is List) {
        optionsList = [];
        for (var v in (json["options"] as List)) {
          if (v != null) {
            optionsList?.add(Option.fromJson(v));
          }
        }
      }
      if (json["relatedQuestionIds"] != null && json["relatedQuestionIds"] is List) {
        relatedQuestionIdsList = json["relatedQuestionIds"];
      }
      testId = json["testId"]?.toString();
      title = (json["title"] ?? json["question"] ?? json["savol"] ?? '').toString();
      type = (json["type"] ?? 'SINGLE_CHOICE').toString();
    }
  }
}

class StudentExamStartModel {
  num? attemptNumber;
  num? durationMinutes;
  String? examSessionId;
  String? id;
  List<Question>? questionsList;
  String? startedAt;
  String? studentExamId;

  List<Question>? get questions => questionsList;

  StudentExamStartModel({
    this.attemptNumber, this.durationMinutes, this.examSessionId, this.id, this.questionsList, this.startedAt, this.studentExamId
  });

  StudentExamStartModel copyWith({
    num? attemptNumber, num? durationMinutes, String? examSessionId, String? id, List<
        Question>? questionsList, String? startedAt, String? studentExamId
  }) =>
      StudentExamStartModel(attemptNumber: attemptNumber ?? this.attemptNumber,
          durationMinutes: durationMinutes ?? this.durationMinutes,
          examSessionId: examSessionId ?? this.examSessionId,
          id: id ?? this.id,
          questionsList: questionsList ?? this.questionsList,
          startedAt: startedAt ?? this.startedAt,
          studentExamId: studentExamId ?? this.studentExamId);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
    };
    map["attemptNumber"] = attemptNumber;
    map["durationMinutes"] = durationMinutes;
    map["examSessionId"] = examSessionId;
    map["id"] = id;
    if (questionsList != null) {
      map["questions"] = questionsList?.map((v) => v.toJson()).toList();
    }
    map["startedAt"] = startedAt;
    map["studentExamId"] = studentExamId;
    return map;
  }

  StudentExamStartModel.fromJson(dynamic jsonInput) {
    Map<String, dynamic> json = {};
    if (jsonInput is Map) {
      json = jsonInput.map((k, v) => MapEntry(k.toString(), v));
    }

    final dataMap = (json['data'] != null && json['data'] is Map)
        ? (json['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : json;

    attemptNumber = dataMap["attemptNumber"] is num
        ? dataMap["attemptNumber"]
        : num.tryParse(dataMap["attemptNumber"]?.toString() ?? '1');
    durationMinutes = dataMap["durationMinutes"] is num
        ? dataMap["durationMinutes"]
        : num.tryParse(dataMap["durationMinutes"]?.toString() ?? '20');
    examSessionId = dataMap["examSessionId"]?.toString();
    id = (dataMap["id"] ?? dataMap["_id"] ?? '').toString();

    final rawQuestions = dataMap["questions"] ?? dataMap["questionsList"] ?? dataMap["savollar"];
    if (rawQuestions != null && rawQuestions is List) {
      questionsList = [];
      for (var v in rawQuestions) {
        if (v != null) {
          questionsList?.add(Question.fromJson(v));
        }
      }
    }

    startedAt = dataMap["startedAt"]?.toString();
    studentExamId = (dataMap["studentExamId"] ?? id ?? '').toString();
  }
}