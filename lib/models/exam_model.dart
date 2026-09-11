class ExamModel {
  final String id;
  final String name;
  final String testId;
  final String guruhId;
  final int durationMinutes;
  final int questionCount;
  final int maxAttempts;
  final String status; // REJALASHTIRILGAN, FAOL, YAKUNLANGAN

  ExamModel({
    required this.id,
    required this.name,
    required this.testId,
    required this.guruhId,
    required this.durationMinutes,
    required this.questionCount,
    required this.maxAttempts,
    this.status = 'FAOL',
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Imtihon',
      testId: json['testId'] as String? ?? '',
      guruhId: json['guruhId'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? (json['ajratilganVaqt'] as int? ?? 20),
      questionCount: json['questionCount'] as int? ?? 5,
      maxAttempts: json['maxAttempts'] as int? ?? 20,
      status: json['status'] as String? ?? 'FAOL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'testId': testId,
      'guruhId': guruhId,
      'durationMinutes': durationMinutes,
      'questionCount': questionCount,
      'maxAttempts': maxAttempts,
      'status': status,
    };
  }

  // Exact JSON payload format requested for server API
  Map<String, dynamic> toApiRequestJson() {
    return {
      'testId': testId,
      'guruhId': guruhId,
      'durationMinutes': durationMinutes,
      'questionCount': questionCount,
      'maxAttempts': maxAttempts,
    };
  }

  ExamModel copyWith({
    String? id,
    String? name,
    String? testId,
    String? guruhId,
    int? durationMinutes,
    int? questionCount,
    int? maxAttempts,
    String? status,
  }) {
    return ExamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      testId: testId ?? this.testId,
      guruhId: guruhId ?? this.guruhId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      questionCount: questionCount ?? this.questionCount,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      status: status ?? this.status,
    );
  }
}
