import 'package:image_picker/image_picker.dart';
import '../entities/school_config_entity.dart';

// contract the data layer has to fulfill, keeps domain from knowing about Firestore
abstract class ReportRepository {
  // uploads picked images/files first, returns the storage urls to attach to the report
  Future<List<String>> uploadMediaFiles(List<XFile> files);
  // creates the actual report doc, returns the new report id
  Future<String> submitReport({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    required List<String> mediaUrls,
    String? deviceIdentifier,
  });

  Future<SchoolConfigEntity> getSchoolConfig(String schoolId);
}