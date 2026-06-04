import 'package:equatable/equatable.dart';

abstract class SchoolStartupState extends Equatable {
  const SchoolStartupState();
  @override
  List<Object?> get props => [];
}

class SchoolStartupLoading extends SchoolStartupState {
  const SchoolStartupLoading();
}

class SchoolStartupReady extends SchoolStartupState {
  final String schoolName;
  const SchoolStartupReady(this.schoolName);
  @override
  List<Object?> get props => [schoolName];
}

class SchoolStartupError extends SchoolStartupState {
  final String message;
  const SchoolStartupError(this.message);
  @override
  List<Object?> get props => [message];
}
