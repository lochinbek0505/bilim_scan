class EduPlanTopicModel {
  final int tr;
  final String title;
  final int soat;
  final String tur; // Ma'ruza, Amaliy mashg'ulot, Laboratoriya, Seminar

  EduPlanTopicModel({
    required this.tr,
    required this.title,
    required this.soat,
    required this.tur,
  });

  factory EduPlanTopicModel.fromJson(Map<String, dynamic> json) {
    return EduPlanTopicModel(
      tr: json['tr'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      soat: json['soat'] as int? ?? 2,
      tur: json['tur'] as String? ?? 'Ma\'ruza',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tr': tr,
      'title': title,
      'soat': soat,
      'tur': tur,
    };
  }
}

class EduPlanModel {
  final String id;
  final String name;
  final String fanId;
  final String kafedraId;
  final String oquvOyi;
  final String oquvYili;
  final List<EduPlanTopicModel> topics;

  EduPlanModel({
    required this.id,
    required this.name,
    required this.fanId,
    required this.kafedraId,
    required this.oquvOyi,
    required this.oquvYili,
    required this.topics,
  });

  factory EduPlanModel.fromJson(Map<String, dynamic> json) {
    List<EduPlanTopicModel> parsedTopics = [];
    if (json['topics'] != null) {
      parsedTopics = (json['topics'] as List<dynamic>)
          .map((e) => EduPlanTopicModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return EduPlanModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      fanId: json['fanId'] as String? ?? '',
      kafedraId: json['kafedraId'] as String? ?? '',
      oquvOyi: json['oquvOyi'] as String? ?? 'Sentyabr',
      oquvYili: json['oquvYili'] as String? ?? '2026-2027',
      topics: parsedTopics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fanId': fanId,
      'kafedraId': kafedraId,
      'oquvOyi': oquvOyi,
      'oquvYili': oquvYili,
      'topics': topics.map((e) => e.toJson()).toList(),
    };
  }

  EduPlanModel copyWith({
    String? id,
    String? name,
    String? fanId,
    String? kafedraId,
    String? oquvOyi,
    String? oquvYili,
    List<EduPlanTopicModel>? topics,
  }) {
    return EduPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fanId: fanId ?? this.fanId,
      kafedraId: kafedraId ?? this.kafedraId,
      oquvOyi: oquvOyi ?? this.oquvOyi,
      oquvYili: oquvYili ?? this.oquvYili,
      topics: topics ?? this.topics,
    );
  }
}
