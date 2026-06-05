import 'package:equatable/equatable.dart';

class SchoolConfigEntity extends Equatable {
  final String schoolId;
  final String schoolName;
  final bool active;

  const SchoolConfigEntity({
    required this.schoolId,
    required this.schoolName,
    required this.active,
  });

  @override
  List<Object?> get props => [schoolId, schoolName, active];
}
