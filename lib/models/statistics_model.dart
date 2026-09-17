class SubjectPerformanceModel {
  String? subjectName;
  num? averagePercentage;
  num? failedCount;
  num? masteredCount;
  num? satisfactoryCount;

  SubjectPerformanceModel({
    this.subjectName,
    this.averagePercentage,
    this.failedCount,
    this.masteredCount,
    this.satisfactoryCount,
  });

  SubjectPerformanceModel.fromJson(dynamic json) {
    if (json == null) return;
    subjectName = json['subjectName'];
    averagePercentage = json['averagePercentage'];
    failedCount = json['failedCount'];
    masteredCount = json['masteredCount'];
    satisfactoryCount = json['satisfactoryCount'];
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectName': subjectName,
      'averagePercentage': averagePercentage,
      'failedCount': failedCount,
      'masteredCount': masteredCount,
      'satisfactoryCount': satisfactoryCount,
    };
  }
}

class TimeDynamicModel {
  num? averagePercentage;
  num? examCount;
  String? month;
  String? year;

  TimeDynamicModel({
    this.averagePercentage,
    this.examCount,
    this.month,
    this.year,
  });

  TimeDynamicModel.fromJson(dynamic json) {
    if (json == null) return;
    averagePercentage = json['averagePercentage'];
    examCount = json['examCount'];
    month = json['month'];
    year = json['year'];
  }

  Map<String, dynamic> toJson() {
    return {
      'averagePercentage': averagePercentage,
      'examCount': examCount,
      'month': month,
      'year': year,
    };
  }
}

class ScopeStatisticsModel {
  num? failedCount;
  num? masteredCount;
  num? overallAveragePercentage;
  num? satisfactoryCount;
  String? scope;
  String? scopeId;
  List<SubjectPerformanceModel>? subjectPerformances;
  List<TimeDynamicModel>? timeDynamics;
  num? totalExamsTaken;
  num? totalStudentsParticipated;

  ScopeStatisticsModel({
    this.failedCount,
    this.masteredCount,
    this.overallAveragePercentage,
    this.satisfactoryCount,
    this.scope,
    this.scopeId,
    this.subjectPerformances,
    this.timeDynamics,
    this.totalExamsTaken,
    this.totalStudentsParticipated,
  });

  ScopeStatisticsModel.fromJson(dynamic json) {
    if (json == null) return;
    failedCount = json['failedCount'];
    masteredCount = json['masteredCount'];
    overallAveragePercentage = json['overallAveragePercentage'];
    satisfactoryCount = json['satisfactoryCount'];
    scope = json['scope'];
    scopeId = json['scopeId'];
    totalExamsTaken = json['totalExamsTaken'];
    totalStudentsParticipated = json['totalStudentsParticipated'];

    if (json['subjectPerformances'] != null && json['subjectPerformances'] is List) {
      subjectPerformances = (json['subjectPerformances'] as List)
          .map((v) => SubjectPerformanceModel.fromJson(v))
          .toList();
    } else {
      subjectPerformances = [];
    }

    if (json['timeDynamics'] != null && json['timeDynamics'] is List) {
      timeDynamics = (json['timeDynamics'] as List)
          .map((v) => TimeDynamicModel.fromJson(v))
          .toList();
    } else {
      timeDynamics = [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'failedCount': failedCount,
      'masteredCount': masteredCount,
      'overallAveragePercentage': overallAveragePercentage,
      'satisfactoryCount': satisfactoryCount,
      'scope': scope,
      'scopeId': scopeId,
      'subjectPerformances': subjectPerformances?.map((v) => v.toJson()).toList(),
      'timeDynamics': timeDynamics?.map((v) => v.toJson()).toList(),
      'totalExamsTaken': totalExamsTaken,
      'totalStudentsParticipated': totalStudentsParticipated,
    };
  }
}

class GroupStatisticsModel {
  String? guruhId;
  num? overallAverage;
  List<SubjectPerformanceModel>? subjectStats;
  num? totalStudents;

  GroupStatisticsModel({
    this.guruhId,
    this.overallAverage,
    this.subjectStats,
    this.totalStudents,
  });

  GroupStatisticsModel.fromJson(dynamic json) {
    if (json == null) return;
    guruhId = json['guruhId'];
    overallAverage = json['overallAverage'];
    totalStudents = json['totalStudents'];

    if (json['subjectStats'] != null && json['subjectStats'] is List) {
      subjectStats = (json['subjectStats'] as List)
          .map((v) => SubjectPerformanceModel.fromJson(v))
          .toList();
    } else {
      subjectStats = [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'guruhId': guruhId,
      'overallAverage': overallAverage,
      'subjectStats': subjectStats?.map((v) => v.toJson()).toList(),
      'totalStudents': totalStudents,
    };
  }
}
