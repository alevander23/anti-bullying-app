import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/school_config_entity.dart';

abstract class ReportRemoteDataSource {
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

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore _firestore;

  ReportRemoteDataSourceImpl(this._firestore);

  @override
  Future<String> submitReport({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    String? deviceIdentifier,
  }) async {
    final doc = await _firestore.collection('reports').add({
      'schoolId': schoolId,
      'title': title,
      'description': description,
      'category': category,
      'bullyNames': bullyNames,
      'status': 'new',
      'priority': 'normal',
      'isFlagged': false,
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedBy': null,
      'notes': null,
      'closedAt': null,
      'resolvedBy': null,
      if (deviceIdentifier != null) 'deviceIdentifier': deviceIdentifier,
    });

    return doc.id;
  }

  @override
  Future<SchoolConfigEntity> getSchoolConfig(String schoolId) async {
    final doc = await _firestore.collection('schools').doc(schoolId).get();

    if (!doc.exists) {
      throw Exception('No school found with ID "$schoolId". Check SchoolConfig.schoolId.');
    }

    final data = doc.data() ?? {};

    return SchoolConfigEntity(
      schoolId: schoolId,
      schoolName: data['name'] as String? ?? schoolId,
      active: data['active'] as bool? ?? true,
    );
  }
}
