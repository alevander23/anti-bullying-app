import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../domain/entities/school_config_entity.dart';
import '../../school_config.dart';

abstract class ReportRemoteDataSource {
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

// talks to Firestore directly and to our own storage server for media uploads
class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore _firestore;
  // storage server lives outside firebase, configured per school
  static const String _serverBaseUrl = SchoolConfig.storageServerIP;

  ReportRemoteDataSourceImpl(this._firestore);

  /// Gets a Firebase ID token, signing in anonymously first if needed.
  /// Anonymous auth lets the server verify the request is from the real
  /// app without identifying the student.
  Future<String> _getAuthToken() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    if (token == null) {
      throw Exception('Failed to obtain auth token');
    }
    return token;
  }

  @override
  Future<List<String>> uploadMediaFiles(List<XFile> files) async {
    final token = await _getAuthToken();
    final urls = <String>[];

    // uploading one at a time, keeps error handling per file simple
    for (final file in files) {
      final bytes = await file.readAsBytes();

      // fall back to path, then fall back to sniffing the actual bytes
      final mimeType = lookupMimeType(file.name, headerBytes: bytes) ??
          lookupMimeType(file.path, headerBytes: bytes) ??
          'application/octet-stream';

      // only images and video are allowed on the storage server
      if (!mimeType.startsWith('image/') && !mimeType.startsWith('video/')) {
        throw Exception('Unsupported file type: $mimeType');
      }

      final parts = mimeType.split('/');

      // build the multipart upload with auth token attached
      final request = http.MultipartRequest('POST', Uri.parse('$_serverBaseUrl/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: MediaType(parts[0], parts[1]),
      ));

      // big files or slow connections can take a while, give it a generous timeout
      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Upload failed (${response.statusCode}): ${response.body}');
      }

      // server hands back the final url after storing the file
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      urls.add(data['url'] as String);
    }

    return urls;
  }

  @override
  Future<String> submitReport({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    required List<String> mediaUrls,
    String? deviceIdentifier,
  }) async {
    // new reports always start as new/normal/unflagged, staff update these later
    final doc = await _firestore.collection('reports').add({
      'schoolId': schoolId,
      'title': title,
      'description': description,
      'category': category,
      'bullyNames': bullyNames,
      'mediaUrls': mediaUrls,
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

    // bad school id in the build config, fail loud so it gets caught early
    if (!doc.exists) {
      throw Exception('No school found with ID "$schoolId". Check SchoolConfig.schoolId.');
    }

    final data = doc.data() ?? {};

    // default to active/schoolId if the doc is missing fields for some reason
    return SchoolConfigEntity(
      schoolId: schoolId,
      schoolName: data['name'] as String? ?? schoolId,
      active: data['active'] as bool? ?? true,
    );
  }
}