import '../entities/school_config_entity.dart';

abstract class ReportRepository {
  Future<String> submitReport({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    String? deviceIdentifier,
  });

  Future<SchoolConfigEntity> getSchoolConfig(String schoolId);
}
