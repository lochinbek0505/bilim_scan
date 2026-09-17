import 'guruh_model.dart';

class ExamModel {
  final String id;
  final String? name;
  final String testId;
  final String guruhId;
  final GuruhModel? guruh;
  final int durationMinutes;
  final int questionCount;
  final int maxAttempts;
  final bool active;
  final String? startTime;
  final String? endTime;
  final String status; // REJALASHTIRILGAN, FAOL, YAKUNLANGAN
  final List<String>? combinedTestIds;

  ExamModel({
    required this.id,
    this.name,
    required this.testId,
    required this.guruhId,
    this.guruh,
    required this.durationMinutes,
    required this.questionCount,
    required this.maxAttempts,
    this.active = true,
    this.startTime,
    this.endTime,
    this.status = 'FAOL',
    this.combinedTestIds,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    // Parse testId (String or object)
    String tId = '';
    if (json['test'] is String) {
      tId = json['test'] as String;
    } else if (json['test'] is Map) {
      tId = json['test']['id'] as String? ?? '';
    } else if (json['testId'] != null) {
      tId = json['testId'] as String;
    }

    // Parse guruhId and guruh object
    String gId = '';
    GuruhModel? gObj;
    if (json['guruh'] is Map<String, dynamic>) {
      gObj = GuruhModel.fromJson(json['guruh'] as Map<String, dynamic>);
      gId = gObj.id ?? '';
    } else if (json['guruh'] is String) {
      gId = json['guruh'] as String;
    } else if (json['guruhId'] != null) {
      gId = json['guruhId'] as String;
    }

    final isActive = json['active'] as bool? ?? true;
    final parsedStatus = isActive ? 'FAOL' : 'YAKUNLANGAN';

    List<String>? parsedCombined;
    if (json['combinedTestIds'] != null && json['combinedTestIds'] is List) {
      parsedCombined = (json['combinedTestIds'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return ExamModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? (gObj != null ? 'Imtihon (${gObj.name})' : 'Imtihon'),
      testId: tId,
      guruhId: gId,
      guruh: gObj,
      durationMinutes: json['durationMinutes'] as int? ?? (json['ajratilganVaqt'] as int? ?? 20),
      questionCount: json['questionCount'] as int? ?? 5,
      maxAttempts: json['maxAttempts'] as int? ?? 20,
      active: isActive,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      status: json['status'] as String? ?? parsedStatus,
      combinedTestIds: parsedCombined,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'testId': testId,
      'guruhId': guruhId,
      if (guruh != null) 'guruh': guruh?.toJson(),
      'durationMinutes': durationMinutes,
      'questionCount': questionCount,
      'maxAttempts': maxAttempts,
      'active': active,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      if (combinedTestIds != null && combinedTestIds!.isNotEmpty)
        'combinedTestIds': combinedTestIds,
    };
  }

  // Exact JSON payload requested for /api/exams/create
  Map<String, dynamic> toCreateRequestJson() {
    return {
      if (name != null && name!.isNotEmpty) 'name': name,
      'testId': testId,
      'guruhId': guruhId,
      'durationMinutes': durationMinutes,
      'questionCount': questionCount,
      'maxAttempts': maxAttempts,
      if (combinedTestIds != null && combinedTestIds!.isNotEmpty)
        'combinedTestIds': combinedTestIds,
    };
  }

  Map<String, dynamic> toApiRequestJson() {
    return toCreateRequestJson();
  }

  ExamModel copyWith({
    String? id,
    String? name,
    String? testId,
    String? guruhId,
    GuruhModel? guruh,
    int? durationMinutes,
    int? questionCount,
    int? maxAttempts,
    bool? active,
    String? startTime,
    String? endTime,
    String? status,
    List<String>? combinedTestIds,
  }) {
    return ExamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      testId: testId ?? this.testId,
      guruhId: guruhId ?? this.guruhId,
      guruh: guruh ?? this.guruh,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      questionCount: questionCount ?? this.questionCount,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      active: active ?? this.active,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      combinedTestIds: combinedTestIds ?? this.combinedTestIds,
    );
  }
}
