import 'package:equatable/equatable.dart';

// three states for the startup flow, loading while we fetch config, then ready or error
abstract class SchoolStartupState extends Equatable {
  const SchoolStartupState();
  @override
  List<Object?> get props => [];
}

class SchoolStartupLoading extends SchoolStartupState {
  const SchoolStartupLoading();
}

// fetched school config successfully, carries the name to show on the UI
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
