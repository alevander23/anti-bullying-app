import '../repository_contracts/report_repository.dart';

class SubmitReportUseCase {
  final ReportRepository repository;

  SubmitReportUseCase(this.repository);

  Future<String> execute({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    String? deviceIdentifier,
  }) {
    return repository.submitReport(
      schoolId: schoolId,
      title: title,
      description: description,
      category: category,
      bullyNames: bullyNames,
      deviceIdentifier: deviceIdentifier,
    );
  }
}
