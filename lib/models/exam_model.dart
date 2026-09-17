import 'guruh_model.dart';

class ExamModel {
  final String id;
  final String? name;
  final String testId;
  final String? testName;
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
  final String? oquvYili;
  final String? oquvOyi;

  ExamModel({
    required this.id,
    this.name,
    required this.testId,
    this.testName,
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
    this.oquvYili,
    this.oquvOyi,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    // Parse testId and testName (String or object)
    String tId = '';
    String? tName;
    if (json['test'] is String) {
      tId = json['test'] as String;
    } else if (json['test'] is Map) {
      tId = (json['test']['id'] ?? json['test']['_id'] ?? '').toString();
      tName = json['test']['name'] as String? ?? json['test']['title'] as String?;
    } else if (json['testId'] != null) {
      tId = json['testId'] as String;
    }
    if (tName == null && json['testName'] != null) {
      tName = json['testName'] as String?;
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
      testName: tName,
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
      oquvYili: json['oquvYili'] as String?,
      oquvOyi: json['oquvOyi'] as String?,
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
      if (oquvYili != null) 'oquvYili': oquvYili,
      if (oquvOyi != null) 'oquvOyi': oquvOyi,
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
      if (oquvYili != null) 'oquvYili': oquvYili,
      if (oquvOyi != null) 'oquvOyi': oquvOyi,
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
    String? oquvYili,
    String? oquvOyi,
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
      oquvYili: oquvYili ?? this.oquvYili,
      oquvOyi: oquvOyi ?? this.oquvOyi,
    );
  }
}
