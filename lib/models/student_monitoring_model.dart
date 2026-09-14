class Exam {
  dynamic date;
  String? examName;
  String? examSessionId;
  String? masteryLevel;
  num? percentage;

  Exam({
    this.date,
    this.examName,
    this.examSessionId,
    this.masteryLevel,
    this.percentage,
  });

  String get formattedDate {
    if (date == null) return "Sana belgilanmagan";
    try {
      final dt = DateTime.parse(date.toString());
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return "$y-$m-$d $hh:$mm";
    } catch (_) {
      return date.toString();
    }
  }

  Exam copyWith({
    dynamic date,
    String? examName,
    String? examSessionId,
    String? masteryLevel,
    num? percentage,
  }) =>
      Exam(
        date: date ?? this.date,
        examName: examName ?? this.examName,
        examSessionId: examSessionId ?? this.examSessionId,
        masteryLevel: masteryLevel ?? this.masteryLevel,
        percentage: percentage ?? this.percentage,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["date"] = date;
    map["examName"] = examName;
    map["examSessionId"] = examSessionId;
    map["masteryLevel"] = masteryLevel;
    map["percentage"] = percentage;
    return map;
  }

  Exam.fromJson(dynamic json) {
    if (json == null) return;
    date = json["date"];
    examName = json["examName"];
    examSessionId = json["examSessionId"];
    masteryLevel = json["masteryLevel"];
    percentage = json["percentage"];
  }
}

class Subject {
  num? averagePercentage;
  List<Exam>? examsList;
  dynamic subjectId;
  String? subjectMastery;
  String? subjectName;

  List<Exam> get exams => examsList ?? [];

  Subject({
    this.averagePercentage,
    this.examsList,
    this.subjectId,
    this.subjectMastery,
    this.subjectName,
  });

  Subject copyWith({
    num? averagePercentage,
    List<Exam>? examsList,
    dynamic subjectId,
    String? subjectMastery,
    String? subjectName,
  }) =>
      Subject(
        averagePercentage: averagePercentage ?? this.averagePercentage,
        examsList: examsList ?? this.examsList,
        subjectId: subjectId ?? this.subjectId,
        subjectMastery: subjectMastery ?? this.subjectMastery,
        subjectName: subjectName ?? this.subjectName,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["averagePercentage"] = averagePercentage;
    if (examsList != null) {
      map["exams"] = examsList?.map((v) => v.toJson()).toList();
    }
    map["subjectId"] = subjectId;
    map["subjectMastery"] = subjectMastery;
    map["subjectName"] = subjectName;
    return map;
  }

  Subject.fromJson(dynamic json) {
    if (json == null) return;
    averagePercentage = json["averagePercentage"];
    if (json["exams"] != null && json["exams"] is List) {
      examsList = [];
      for (var v in json["exams"]) {
        examsList?.add(Exam.fromJson(v));
      }
    }
    subjectId = json["subjectId"];
    subjectMastery = json["subjectMastery"];
    subjectName = json["subjectName"];
  }
}

class Month {
  String? month;
  List<Subject>? subjectsList;

  List<Subject> get subjects => subjectsList ?? [];

  Month({
    this.month,
    this.subjectsList,
  });

  Month copyWith({
    String? month,
    List<Subject>? subjectsList,
  }) =>
      Month(
        month: month ?? this.month,
        subjectsList: subjectsList ?? this.subjectsList,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["month"] = month;
    if (subjectsList != null) {
      map["subjects"] = subjectsList?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  Month.fromJson(dynamic json) {
    if (json == null) return;
    month = json["month"];
    if (json["subjects"] != null && json["subjects"] is List) {
      subjectsList = [];
      for (var v in json["subjects"]) {
        subjectsList?.add(Subject.fromJson(v));
      }
    }
  }
}

class AcademicYear {
  List<Month>? monthsList;
  String? year;

  List<Month> get months => monthsList ?? [];

  AcademicYear({
    this.monthsList,
    this.year,
  });

  AcademicYear copyWith({
    List<Month>? monthsList,
    String? year,
  }) =>
      AcademicYear(
        monthsList: monthsList ?? this.monthsList,
        year: year ?? this.year,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (monthsList != null) {
      map["months"] = monthsList?.map((v) => v.toJson()).toList();
    }
    map["year"] = year;
    return map;
  }

  AcademicYear.fromJson(dynamic json) {
    if (json == null) return;
    if (json["months"] != null && json["months"] is List) {
      monthsList = [];
      for (var v in json["months"]) {
        monthsList?.add(Month.fromJson(v));
      }
    }
    year = json["year"];
  }
}

class StudentMonitoringModel {
  List<AcademicYear>? academicYearsList;
  String? overallMastery;
  num? overallPercentage;
  String? studentId;

  List<AcademicYear> get academicYears => academicYearsList ?? [];

  StudentMonitoringModel({
    this.academicYearsList,
    this.overallMastery,
    this.overallPercentage,
    this.studentId,
  });

  StudentMonitoringModel copyWith({
    List<AcademicYear>? academicYearsList,
    String? overallMastery,
    num? overallPercentage,
    String? studentId,
  }) =>
      StudentMonitoringModel(
        academicYearsList: academicYearsList ?? this.academicYearsList,
        overallMastery: overallMastery ?? this.overallMastery,
        overallPercentage: overallPercentage ?? this.overallPercentage,
        studentId: studentId ?? this.studentId,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (academicYearsList != null) {
      map["academicYears"] = academicYearsList?.map((v) => v.toJson()).toList();
    }
    map["overallMastery"] = overallMastery;
    map["overallPercentage"] = overallPercentage;
    map["studentId"] = studentId;
    return map;
  }

  StudentMonitoringModel.fromJson(dynamic json) {
    if (json == null) return;
    if (json["academicYears"] != null && json["academicYears"] is List) {
      academicYearsList = [];
      for (var v in json["academicYears"]) {
        academicYearsList?.add(AcademicYear.fromJson(v));
      }
    }
    overallMastery = json["overallMastery"];
    overallPercentage = json["overallPercentage"];
    studentId = json["studentId"];
  }
}
