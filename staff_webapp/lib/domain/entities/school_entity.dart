class School {
  /// Unique identifier for the school.
  final String id;

  /// Official name of the school.
  final String name;

  /// Physical address of the school.
  final String address;

  /// Indicates whether the school is currently active (used for soft deletion or status).
  final bool isActive;

  /// Timestamp when the school was initially created.
  final DateTime createdAt;

  /// Number of days after resolution a report is auto-deleted.
  /// A null value means reports are never deleted.
  final int? resolvedReportRetentionDays;

  /// The last date a cleanup pass was run for this school.
  /// Only the date is stored, with no time component.
  final DateTime? lastCleanupDate;

  /// Duration in days for the auto-grouping window when clustering reports by shared bully name.
  /// Defaults to 5 days if not specified.
  final int autoGroupWindowDays;

  const School({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
    required this.createdAt,
    this.resolvedReportRetentionDays,
    this.lastCleanupDate,
    this.autoGroupWindowDays = 5,
  });
}