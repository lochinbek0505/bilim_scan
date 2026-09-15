import 'package:bilim_scan/models/student_monitoring_model.dart';
import 'package:bilim_scan/models/user_response_dto.dart';

class StudentExportData {
  final UserResponseDto student;
  final String? base64Image;
  final StudentMonitoringModel monitoringData;

  StudentExportData({
    required this.student,
    this.base64Image,
    required this.monitoringData,
  });
}
