class School {
  final String id;
  final String name;
  final String address;
  final bool isActive;
  final DateTime createdAt;

  /// How many days after resolution a report is auto-deleted.
  /// null means never delete.
  final int? resolvedReportRetentionDays;

  /// The last date a cleanup pass was run for this school (date only, no time).
  final DateTime? lastCleanupDate;

  const School({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
    required this.createdAt,
    this.resolvedReportRetentionDays,
    this.lastCleanupDate,
  });
}
