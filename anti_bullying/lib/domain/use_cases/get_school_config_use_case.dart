import '../entities/school_config_entity.dart';
import '../repository_contracts/report_repository.dart';

class GetSchoolConfigUseCase {
  final ReportRepository repository;

  GetSchoolConfigUseCase(this.repository);

  Future<SchoolConfigEntity> execute(String schoolId) {
    return repository.getSchoolConfig(schoolId);
  }
}
