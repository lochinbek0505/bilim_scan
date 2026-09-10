class OptionModel {
  final String text;
  final bool isTrue;

  OptionModel({
    required this.text,
    required this.isTrue,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      text: json['text'] as String? ?? '',
      isTrue: json['isTrue'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isTrue': isTrue,
    };
  }
}

class QuestionModel {
  final String title;
  final String mavzu;
  final String type; // SINGLE_CHOICE, MULTIPLE_CHOICE, OPEN, WRITTEN
  final int tr;
  final List<int> relatedQuestionTrs;
  final List<OptionModel> options;

  QuestionModel({
    required this.title,
    required this.mavzu,
    required this.type,
    required this.tr,
    required this.relatedQuestionTrs,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      title: json['title'] as String? ?? '',
      mavzu: json['mavzu'] as String? ?? '',
      type: json['type'] as String? ?? 'SINGLE_CHOICE',
      tr: json['tr'] as int? ?? 1,
      relatedQuestionTrs: (json['relatedQuestionTrs'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => OptionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'mavzu': mavzu,
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

  factory TestModel.fromJson(Map<String, dynamic> json) {
    List<QuestionModel> parsedQuestions = [];
    if (json['questions'] != null) {
      parsedQuestions = (json['questions'] as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return TestModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      fanId: json['fanId'] as String? ?? '',
      kafedraId: json['kafedraId'] as String? ?? '',
      eduPlanId: json['eduPlanId'] as String? ?? '',
      guruhId: json['guruhId'] as String? ?? '10-25-guruh',
      oquvYili: json['oquvYili'] as String? ?? '2026-2027',
      ajratilganVaqt: json['ajratilganVaqt'] as int? ?? 60,
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
