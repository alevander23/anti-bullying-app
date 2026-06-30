// Edit this file once per school deployment.
// Do not change it when updating the app.

class SchoolConfig {
  // Set these two values for each school.

  /// Firestore document ID under the /schools collection. Case-sensitive. Every school will get their own build with this premade
  static const String schoolId = 'school_greenfield';
  /// Shown in the app bar and hero card.
  static const String schoolName = 'Greenfield School';
  static const String storageServerIP = 'http://whatever the server ip is:whatever the port is';

  SchoolConfig._();
}
