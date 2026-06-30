import 'package:image_picker/image_picker.dart';
import '../entities/school_config_entity.dart';

abstract class ReportRepository {
  Future<List<String>> uploadMediaFiles(List<XFile> files);
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