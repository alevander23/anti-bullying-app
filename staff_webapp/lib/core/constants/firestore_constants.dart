class FirestoreConstants {
  // Firestore collection names used across the application
  static const String schools        = 'schools';
  static const String admins         = 'admins';
  static const String reports        = 'reports';
  static const String groups         = 'groups';
  static const String pendingAdmins  = 'pendingAdmins';

  // Possible values for the status field in report documents
  static const String statusNew        = 'new';
  static const String statusReviewed   = 'reviewed';
  static const String statusEscalated  = 'escalated';
  static const String statusResolved   = 'resolved';

  // Possible values for the priority field in report documents
  static const String priorityNormal = 'normal';
  static const String priorityHigh   = 'high';

  // Possible roles for admin users
  static const String roleAdmin      = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Possible categories for reports
  static const String categoryBullying   = 'bullying';
  static const String categoryHarassment = 'harassment';
  static const String categorySafety     = 'safety';
  static const String categoryOther      = 'other';

  // Fields in school settings documents
  static const String resolvedReportRetentionDays = 'resolvedReportRetentionDays';
  static const String lastCleanupDate             = 'lastCleanupDate';
}