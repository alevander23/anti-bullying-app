// lib/presentation/bloc/report/report_state.dart

import 'package:staff_webapp/domain/entities/report_entity.dart';


abstract class ReportState {
  const ReportState();
}

/// Initial state when the report bloc is first created
class ReportInitial extends ReportState {
  const ReportInitial();
}

/// State indicating the report data is currently being fetched
class ReportLoading extends ReportState {
  const ReportLoading();
}

/// State containing the fully loaded report data and current filter settings
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

  /// Returns true if any filters (priority, flagged, search) are currently active
  bool get hasActiveFilters =>
      activePriorityFilter != null ||
      activeFlaggedFilter != null ||
      searchQuery.isNotEmpty;
}

/// State indicating an error occurred during report operations
class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
}

/// State indicating a report action (like update/delete) was successful
class ReportActionSuccess extends ReportState {
  final String message;
  const ReportActionSuccess(this.message);
}

/// State indicating a report action failed
class ReportActionError extends ReportState {
  final String message;
  const ReportActionError(this.message);
}