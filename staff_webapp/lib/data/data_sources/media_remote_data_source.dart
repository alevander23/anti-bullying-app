import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// Thrown when no admin is currently signed in — caught by the repository
// implementation and mapped to a [Failure].
class NotSignedInException implements Exception {
  final String message;
  const NotSignedInException([this.message = 'Not signed in']);
}

// Thrown when the storage server returns a non-200 response.
class MediaFetchException implements Exception {
  final int statusCode;
  final String message;
  const MediaFetchException(this.statusCode, this.message);
}

abstract class MediaRemoteDataSource {
  Future<Uint8List> fetchProtectedBytes(String url);
}

class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final http.Client _client;

  MediaRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    http.Client? client,
  })  : _firebaseAuth = firebaseAuth,
        _client = client ?? http.Client();

  @override
  Future<Uint8List> fetchProtectedBytes(String url) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const NotSignedInException();
    }

    final token = await user.getIdToken();
    final response = await _client.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw MediaFetchException(
        response.statusCode,
        'Failed to load media (${response.statusCode})',
      );
    }

    return response.bodyBytes;
  }
}