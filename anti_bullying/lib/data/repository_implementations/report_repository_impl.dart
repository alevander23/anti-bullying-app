import '../data_sources/report_remote_data_source.dart';
import '../../domain/entities/school_config_entity.dart';
import '../../domain/repository_contracts/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> submitReport({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    String? deviceIdentifier,
  }) {
    return remoteDataSource.submitReport(
      schoolId: schoolId,
      title: title,
      description: description,
      category: category,
      bullyNames: bullyNames,
      deviceIdentifier: deviceIdentifier,
    );
  }

  @override
  Future<SchoolConfigEntity> getSchoolConfig(String schoolId) {
    return remoteDataSource.getSchoolConfig(schoolId);
  }
}
