import 'edu_plan_model.dart';

class OptionModel {
  final String text;
  final bool isTrue;

  OptionModel({
    required this.text,
    required this.isTrue,
  });

  factory OptionModel.fromJson(dynamic jsonInput) {
    if (jsonInput is String) {
      return OptionModel(text: jsonInput, isTrue: false);
    }
    if (jsonInput is Map) {
      final map = jsonInput.map((key, value) => MapEntry(key.toString(), value));
      return OptionModel(
        text: (map['text'] ?? map['option'] ?? map['javob'] ?? map['name'] ?? '').toString(),
        isTrue: map['isTrue'] == true || map['isCorrect'] == true || map['to_gri'] == true,
      );
    }
    return OptionModel(text: jsonInput?.toString() ?? '', isTrue: false);
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isTrue': isTrue,
    };
  }
}

class QuestionModel {
  final String id;
  final String title;
  final EduPlanTopicModel? mavzu;
  final String type; // SINGLE_CHOICE, MULTIPLE_CHOICE, OPEN, WRITTEN
  final int tr;
  final List<int> relatedQuestionTrs;
  final List<String> relatedQuestionIds;
  final List<OptionModel> options;

  QuestionModel({
    this.id = '',
    required this.title,
    this.mavzu,
    required this.type,
    required this.tr,
    required this.relatedQuestionTrs,
    this.relatedQuestionIds = const [],
    required this.options,
  });

  factory QuestionModel.fromJson(dynamic jsonInput) {
    Map<String, dynamic> json = {};
    if (jsonInput is Map) {
      json = jsonInput.map((key, value) => MapEntry(key.toString(), value));
    }

    EduPlanTopicModel? parsedMavzu;
    final topicData = json['topic'] ?? json['mavzu'] ?? json['topicId'];
    if (topicData != null) {
      if (topicData is Map) {
        parsedMavzu = EduPlanTopicModel.fromJson(topicData);
      } else if (topicData is String) {
        parsedMavzu = EduPlanTopicModel(
          id: topicData,
          tr: 1,
          name: topicData,
          soat: 2,
          type: 'Amaliy',
        );
      }
    }

    List<int> parsedRelatedTrs = [];
    if (json['relatedQuestionTrs'] != null && json['relatedQuestionTrs'] is List) {
      for (var item in json['relatedQuestionTrs'] as List) {
        if (item is int) {
          parsedRelatedTrs.add(item);
        } else if (item != null) {
          final p = int.tryParse(item.toString());
          if (p != null) parsedRelatedTrs.add(p);
        }
      }
    }

    List<String> parsedRelatedIds = [];
    if (json['relatedQuestionIds'] != null && json['relatedQuestionIds'] is List) {
      for (var item in json['relatedQuestionIds'] as List) {
        if (item != null) parsedRelatedIds.add(item.toString());
      }
    }

    List<OptionModel> parsedOptions = [];
    final rawOptions = json['options'] ?? json['variantlar'] ?? json['answers'];
    if (rawOptions != null && rawOptions is List) {
      for (var e in rawOptions) {
        if (e != null) {
          parsedOptions.add(OptionModel.fromJson(e));
        }
      }
    }

    final rawTr = json['tr'] ?? json['t/r'] ?? json['order'];
    int trVal = 1;
    if (rawTr is int) {
      trVal = rawTr;
    } else if (rawTr != null) {
      trVal = int.tryParse(rawTr.toString()) ?? 1;
    }

    final qId = (json['id'] ?? json['_id'] ?? json['questionId'] ?? 'q_$trVal').toString();

    return QuestionModel(
      id: qId.isNotEmpty ? qId : 'q_$trVal',
      title: (json['title'] ?? json['question'] ?? json['savol'] ?? json['name'] ?? '').toString(),
      mavzu: parsedMavzu,
      type: (json['type'] ?? json['questionType'] ?? 'SINGLE_CHOICE').toString().toUpperCase(),
      tr: trVal,
      relatedQuestionTrs: parsedRelatedTrs,
      relatedQuestionIds: parsedRelatedIds,
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'topicId': mavzu?.id ?? mavzu?.name ?? '',
      'type': type,
      'tr': tr,
      'relatedQuestionTrs': relatedQuestionTrs,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}

class TestModel {
  final String id;
  final String name;
  final String fanId;
  final String kafedraId;
  final String eduPlanId;
  final String guruhId;
  final String oquvYili;
  final int ajratilganVaqt;
  final List<QuestionModel> questions;

  TestModel({
    required this.id,
    required this.name,
    required this.fanId,
    required this.kafedraId,
    required this.eduPlanId,
    this.guruhId = '10-25-guruh',
    this.oquvYili = '2026-2027',
    required this.ajratilganVaqt,
    required this.questions,
  });

  factory TestModel.fromJson(dynamic jsonInput) {
    Map<String, dynamic> json = {};
    if (jsonInput is Map) {
      json = jsonInput.map((key, value) => MapEntry(key.toString(), value));
    }

    List<QuestionModel> parsedQuestions = [];
    final rawQuestions = json['questions'] ?? json['savollar'];
    if (rawQuestions != null && rawQuestions is List) {
      for (var e in rawQuestions) {
        if (e != null) {
          parsedQuestions.add(QuestionModel.fromJson(e));
        }
      }
    }

    final rawVaqt = json['ajratilganVaqt'] ?? json['durationMinutes'] ?? json['duration'];
    int vaqt = 60;
    if (rawVaqt is int) {
      vaqt = rawVaqt;
    } else if (rawVaqt != null) {
      vaqt = int.tryParse(rawVaqt.toString()) ?? 60;
    }

    return TestModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      name: (json['name'] ?? '').toString(),
      fanId: (json['fanId'] ?? '').toString(),
      kafedraId: (json['kafedraId'] ?? '').toString(),
      eduPlanId: (json['eduPlanId'] ?? '').toString(),
      guruhId: (json['guruhId'] ?? '10-25-guruh').toString(),
      oquvYili: (json['oquvYili'] ?? '2026-2027').toString(),
      ajratilganVaqt: vaqt,
      questions: parsedQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fanId': fanId,
      'kafedraId': kafedraId,
      'eduPlanId': eduPlanId,
      'guruhId': guruhId,
      'oquvYili': oquvYili,
      'ajratilganVaqt': ajratilganVaqt,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }

  TestModel copyWith({
    String? id,
    String? name,
    String? fanId,
    String? kafedraId,
    String? eduPlanId,
    String? guruhId,
    String? oquvYili,
    int? ajratilganVaqt,
    List<QuestionModel>? questions,
  }) {
    return TestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fanId: fanId ?? this.fanId,
      kafedraId: kafedraId ?? this.kafedraId,
      eduPlanId: eduPlanId ?? this.eduPlanId,
      guruhId: guruhId ?? this.guruhId,
      oquvYili: oquvYili ?? this.oquvYili,
      ajratilganVaqt: ajratilganVaqt ?? this.ajratilganVaqt,
      questions: questions ?? this.questions,
    );
  }
}
