class EduPlanTopicModel {
  final String? id;
  final int tr;
  final String name;
  final int soat;
  final String type; // Nazariy, Amaliy, Laboratoriya, Seminar

  EduPlanTopicModel({
    this.id,
    required this.tr,
    required this.name,
    required this.soat,
    required this.type,
  });

  factory EduPlanTopicModel.fromJson(dynamic jsonInput) {
    Map<String, dynamic> json = {};
    if (jsonInput is Map) {
      json = jsonInput.map((key, value) => MapEntry(key.toString(), value));
    }

    int parsedTr = 1;
    if (json['tr'] != null) {
      parsedTr = json['tr'] is int ? json['tr'] : int.tryParse(json['tr'].toString()) ?? 1;
    } else if (json['t/r'] != null) {
      parsedTr = json['t/r'] is int ? json['t/r'] : int.tryParse(json['t/r'].toString()) ?? 1;
    }

    int parsedSoat = 2;
    if (json['soat'] != null) {
      parsedSoat = json['soat'] is int ? json['soat'] : int.tryParse(json['soat'].toString()) ?? 2;
    }

    return EduPlanTopicModel(
      id: json['id']?.toString(),
      tr: parsedTr,
      name: (json['name'] ?? json['title'])?.toString() ?? '',
      soat: parsedSoat,
      type: (json['type'] ?? json['tur'])?.toString() ?? 'Amaliy',
    );
  }

  Map<String, dynamic> toBulkRequestJson() {
    return {
      't/r': tr,
      'name': name,
      'soat': soat,
      'type': type,
    };
  }

  Map<String, dynamic> toJson() => toBulkRequestJson();
}

class EduPlanModel {
  final String id;
  final String name;
  final String fanId;
  final String kafedraId;
  final String oquvYili;
  final List<EduPlanTopicModel> topics;

  EduPlanModel({
    required this.id,
    required this.name,
    required this.fanId,
    required this.kafedraId,
    required this.oquvYili,
    required this.topics,
  });

  factory EduPlanModel.fromJson(dynamic jsonInput) {
    Map<String, dynamic> json = {};
    if (jsonInput is Map) {
      json = jsonInput.map((key, value) => MapEntry(key.toString(), value));
    }

    List<EduPlanTopicModel> parsedTopics = [];
    if (json['topics'] != null && json['topics'] is List) {
      for (var e in json['topics'] as List) {
        if (e != null) {
          parsedTopics.add(EduPlanTopicModel.fromJson(e));
        }
      }
    }

    return EduPlanModel(
      id: (json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      name: (json['name'] ?? '').toString(),
      fanId: (json['fanId'] ?? '').toString(),
      kafedraId: (json['kafedraId'] ?? '').toString(),
      oquvYili: (json['oquvYili'] ?? '2025-2026').toString(),
      topics: parsedTopics,
    );
  }

  // Payload for POST /api/edu-plans (EduPlanRequestDto)
  Map<String, dynamic> toRequestDtoJson() {
    return {
      'name': name,
      'fanId': fanId,
      'kafedraId': kafedraId,
      'oquvYili': oquvYili,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fanId': fanId,
      'kafedraId': kafedraId,
      'oquvYili': oquvYili,
      'topics': topics.map((e) => e.toBulkRequestJson()).toList(),
    };
  }

  EduPlanModel copyWith({
    String? id,
    String? name,
    String? fanId,
    String? kafedraId,
    String? oquvYili,
    List<EduPlanTopicModel>? topics,
  }) {
    return EduPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fanId: fanId ?? this.fanId,
      kafedraId: kafedraId ?? this.kafedraId,
      oquvYili: oquvYili ?? this.oquvYili,
      topics: topics ?? this.topics,
    );
  }
}
