import 'guruh_model.dart';
import 'test_model.dart';

class ExamSessionModel {
  final String id;
  final String? name;
  final String? test; // testId
  final GuruhModel? guruh;
  final int durationMinutes;
  final int questionCount;
  final int maxAttempts;
  final bool active;
  final String? startTime;
  final String? endTime;

  ExamSessionModel({
    required this.id,
    this.name,
    this.test,
    this.guruh,
    required this.durationMinutes,
    required this.questionCount,
    required this.maxAttempts,
    required this.active,
    this.startTime,
    this.endTime,
  });

  factory ExamSessionModel.fromJson(dynamic jsonInput) {
    Map<String, dynamic> json = {};
    if (jsonInput is Map) {
      json = jsonInput.map((key, value) => MapEntry(key.toString(), value));
    }

    final rawDuration = json['durationMinutes'] ?? json['duration'] ?? json['ajratilganVaqt'];
    int duration = 20;
    if (rawDuration is int) {
      duration = rawDuration;
    } else if (rawDuration != null) {
      duration = int.tryParse(rawDuration.toString()) ?? 20;
    }

    final rawQCount = json['questionCount'] ?? json['questionsCount'] ?? json['totalQuestions'];
    int qCount = 5;
    if (rawQCount is int) {
      qCount = rawQCount;
    } else if (rawQCount != null) {
      qCount = int.tryParse(rawQCount.toString()) ?? 5;
    }

    final rawMaxAttempts = json['maxAttempts'] ?? json['attempts'];
    int attempts = 1;
    if (rawMaxAttempts is int) {
      attempts = rawMaxAttempts;
    } else if (rawMaxAttempts != null) {
      attempts = int.tryParse(rawMaxAttempts.toString()) ?? 1;
    }

    return ExamSessionModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString(),
      test: json['test'] is String ? json['test'] as String : json['test']?['id']?.toString(),
      guruh: json['guruh'] != null ? GuruhModel.fromJson(json['guruh']) : null,
      durationMinutes: duration > 0 ? duration : 20,
      questionCount: qCount,
      maxAttempts: attempts,
      active: json['active'] as bool? ?? true,
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
    );
  }
}

class StartedExamResponse {
  final String studentExamId;
  final String examSessionId;
  final int attemptNumber;
  final int durationMinutes;
  final String startedAt;
  final List<QuestionModel> questions;

  StartedExamResponse({
    required this.studentExamId,
    required this.examSessionId,
    required this.attemptNumber,
    required this.durationMinutes,
    required this.startedAt,
    required this.questions,
  });

  factory StartedExamResponse.fromJson(dynamic jsonInput) {
    Map<String, dynamic> rawMap = {};
    if (jsonInput is Map) {
      rawMap = jsonInput.map((key, value) => MapEntry(key.toString(), value));
    }

    final json = (rawMap['data'] != null && rawMap['data'] is Map)
        ? (rawMap['data'] as Map).map((key, value) => MapEntry(key.toString(), value))
        : rawMap;

    String sExamId = (json['studentExamId'] ?? json['id'] ?? json['_id'] ?? '').toString();
    if (sExamId.isEmpty && json['studentExam'] != null) {
      if (json['studentExam'] is Map) {
        sExamId = (json['studentExam']['id'] ?? json['studentExam']['_id'] ?? '').toString();
      } else {
        sExamId = json['studentExam'].toString();
      }
    }

    int duration = 20;
    final rawDuration = json['durationMinutes'] ?? json['duration'] ?? json['ajratilganVaqt'];
    if (rawDuration is int) {
      duration = rawDuration;
    } else if (rawDuration != null) {
      duration = int.tryParse(rawDuration.toString()) ?? 20;
    }

    List<QuestionModel> parsedQuestions = [];
    final questionsList = json['questions'] ?? json['savollar'] ?? json['testQuestions'];
    if (questionsList != null && questionsList is List) {
      for (var e in questionsList) {
        if (e != null) {
          parsedQuestions.add(QuestionModel.fromJson(e));
        }
      }
    }

    return StartedExamResponse(
      studentExamId: sExamId,
      examSessionId: (json['examSessionId'] ?? json['examId'] ?? '').toString(),
      attemptNumber: json['attemptNumber'] is int
          ? json['attemptNumber'] as int
          : (int.tryParse(json['attemptNumber']?.toString() ?? '1') ?? 1),
      durationMinutes: duration > 0 ? duration : 20,
      startedAt: (json['startedAt'] ?? '').toString(),
      questions: parsedQuestions,
    );
  }
}

class ExamResultResponse {
  final String id;
  final String examSessionId;
  final String studentId;
  final int correctAnswers;
  final int totalQuestions;
  final double percentage;
  final String masteryLevel; // PASSED / FAILED / HIGH_MASTERY
  final String startedAt;
  final String finishedAt;
  final Map<String, bool> topicMastery;
  final List<QuestionModel> questions;

  ExamResultResponse({
    required this.id,
    required this.examSessionId,
    required this.studentId,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.percentage,
    required this.masteryLevel,
    required this.startedAt,
    required this.finishedAt,
    required this.topicMastery,
    required this.questions,
  });

  factory ExamResultResponse.fromJson(dynamic jsonInput) {
    Map<String, dynamic> rawMap = {};
    if (jsonInput is Map) {
      rawMap = jsonInput.map((key, value) => MapEntry(key.toString(), value));
    }

    final json = (rawMap['data'] != null && rawMap['data'] is Map)
        ? (rawMap['data'] as Map).map((key, value) => MapEntry(key.toString(), value))
        : rawMap;

    Map<String, bool> parsedTopicMastery = {};
    if (json['topicMastery'] != null && json['topicMastery'] is Map) {
      (json['topicMastery'] as Map).forEach((key, value) {
        parsedTopicMastery[key.toString()] = value == true;
      });
    }

    List<QuestionModel> parsedQuestions = [];
    final questionsList = json['questions'] ?? json['savollar'];
    if (questionsList != null && questionsList is List) {
      for (var e in questionsList) {
        if (e != null) {
          parsedQuestions.add(QuestionModel.fromJson(e));
        }
      }
    }

    return ExamResultResponse(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      examSessionId: (json['examSessionId'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      correctAnswers: json['correctAnswers'] is int
          ? json['correctAnswers'] as int
          : (int.tryParse(json['correctAnswers']?.toString() ?? '0') ?? 0),
      totalQuestions: json['totalQuestions'] is int
          ? json['totalQuestions'] as int
          : (int.tryParse(json['totalQuestions']?.toString() ?? '0') ?? 0),
      percentage: (json['percentage'] as num?)?.toDouble() ??
          (double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0),
      masteryLevel: (json['masteryLevel'] ?? 'FAILED').toString(),
      startedAt: (json['startedAt'] ?? '').toString(),
      finishedAt: (json['finishedAt'] ?? '').toString(),
      topicMastery: parsedTopicMastery,
      questions: parsedQuestions,
    );
  }
}
