// lib/presentation/bloc/report/report_state.dart

import 'package:staff_webapp/domain/entities/report_entity.dart';


abstract class ReportState {
  const ReportState();
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  final List<Report> reports;
  final int totalCount;
  final int newCount;
  final int flaggedCount;
  final int resolvedCount;
  final Set<ReportStatus> activeStatusFilters;
  final ReportPriority? activePriorityFilter;
  final bool? activeFlaggedFilter;
  final String searchQuery;
  final bool hasMore;
  final ReportSortField sortField;
  final bool sortAscending;

  const ReportLoaded({
    required this.reports,
    required this.totalCount,
    required this.newCount,
    required this.flaggedCount,
    required this.resolvedCount,
    required this.activeStatusFilters,
    this.activePriorityFilter,
    this.activeFlaggedFilter,
    this.searchQuery = '',
    this.hasMore = false,
    this.sortField = ReportSortField.updatedAt,
    this.sortAscending = false,
  });

  bool get hasActiveFilters =>
      activePriorityFilter != null ||
      activeFlaggedFilter != null ||
      searchQuery.isNotEmpty;
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
}

class ReportActionSuccess extends ReportState {
  final String message;
  const ReportActionSuccess(this.message);
}

class ReportActionError extends ReportState {
  final String message;
  const ReportActionError(this.message);
}
