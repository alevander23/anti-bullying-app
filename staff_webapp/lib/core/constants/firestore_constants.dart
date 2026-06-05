class FirestoreConstants {
  // Collections
  static const String schools        = 'schools';
  static const String admins         = 'admins';
  static const String reports        = 'reports';
  static const String groups         = 'groups';
  static const String pendingAdmins  = 'pendingAdmins';

  // Report status values
  static const String statusNew        = 'new';
  static const String statusReviewed   = 'reviewed';
  static const String statusEscalated  = 'escalated';
  static const String statusResolved   = 'resolved';

  // Report priority values
  static const String priorityNormal = 'normal';
  static const String priorityHigh   = 'high';

  // Admin roles
  static const String roleAdmin      = 'admin';
  static const String roleSuperAdmin = 'super_admin';

  // Report categories
  static const String categoryBullying   = 'bullying';
  static const String categoryHarassment = 'harassment';
  static const String categorySafety     = 'safety';
  static const String categoryOther      = 'other';

  // School settings fields
  static const String resolvedReportRetentionDays = 'resolvedReportRetentionDays';
  static const String lastCleanupDate             = 'lastCleanupDate';
}
