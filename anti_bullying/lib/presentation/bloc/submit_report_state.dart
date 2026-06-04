import 'package:equatable/equatable.dart';

class SubmitReportState extends Equatable {
  final bool loading;
  final bool success;
  final String? reportId;
  final String? error;

  const SubmitReportState({
    this.loading = false,
    this.success = false,
    this.reportId,
    this.error,
  });

  factory SubmitReportState.initial() => const SubmitReportState();

  SubmitReportState copyWith({
    bool? loading,
    bool? success,
    String? reportId,
    String? error,
  }) {
    return SubmitReportState(
      loading: loading ?? this.loading,
      success: success ?? this.success,
      reportId: reportId ?? this.reportId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, success, reportId, error];
}
