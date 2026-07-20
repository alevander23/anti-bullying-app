import 'package:image_picker/image_picker.dart';
import '../repository_contracts/report_repository.dart';

// handles the two step flow, upload media first, then submit the report itself
class SubmitReportUseCase {
  final ReportRepository repository;

  SubmitReportUseCase(this.repository);

  /// Uploads media files to the server and returns their URLs.
  Future<List<String>> uploadMedia(List<XFile> files) =>
      repository.uploadMediaFiles(files);

  // called after uploadMedia so mediaUrls is already populated
  Future<String> execute({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    required List<String> mediaUrls,
    String? deviceIdentifier,
  }) {
    return repository.submitReport(
      schoolId: schoolId,
      title: title,
      description: description,
      category: category,
      bullyNames: bullyNames,
      mediaUrls: mediaUrls,
      deviceIdentifier: deviceIdentifier,
    );
  }
}