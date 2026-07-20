import 'package:equatable/equatable.dart';

// domain representation of a school's config, pulled down from Firestore
class SchoolConfigEntity extends Equatable {
  final String schoolId;
  final String schoolName;
  final bool active;

  const SchoolConfigEntity({
    required this.schoolId,
    required this.schoolName,
    required this.active,
  });

  // equatable needs this so state comparisons work without overriding == manually
  @override
  List<Object?> get props => [schoolId, schoolName, active];
}
