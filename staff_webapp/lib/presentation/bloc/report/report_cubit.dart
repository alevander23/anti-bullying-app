// lib/presentation/bloc/report/report_cubit.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/admin_repository.dart';
import 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final AdminRepository _repository;
  StreamSubscription<List<Report>>? _reportSubscription;

  // Active filter state
  ReportStatus? _filterStatus;
  ReportPriority? _filterPriority;
  bool? _filterFlagged;
  String _searchQuery = '';

  ReportCubit(this._repository) : super(const ReportInitial());

  // Start listening to reports for a school

  void watchReports(String schoolId) {
    emit(const ReportLoading());
    _reportSubscription?.cancel();
    _reportSubscription = _repository
        .watchReportsForSchool(schoolId)
        .listen(
          (reports) => _emitFiltered(reports),
          onError: (_) => emit(const ReportError('Failed to load reports')),
        );
  }

  // Filters

  void setStatusFilter(ReportStatus? status) {
    _filterStatus = status;
    _refreshFiltered();
  }

  void setPriorityFilter(ReportPriority? priority) {
    _filterPriority = priority;
    _refreshFiltered();
  }

  void setFlaggedFilter(bool? flagged) {
    _filterFlagged = flagged;
    _refreshFiltered();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _refreshFiltered();
  }

  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _filterFlagged = null;
    _searchQuery = '';
    _refreshFiltered();
  }

  // Report actions

  Future<void> updateStatus(
      String reportId, ReportStatus status, String adminUid) async {
    final result =
        await _repository.updateReportStatus(reportId, status, adminUid);
    result.fold(
      (f) => emit(ReportActionError(f.message)),
      (_) => emit(const ReportActionSuccess('Status updated')),
    );
  }

  Future<void> toggleFlag(String reportId, bool current) async {
    final result =
        await _repository.toggleReportFlag(reportId, !current);
    result.fold(
      (f) => emit(ReportActionError(f.message)),
      (_) => emit(const ReportActionSuccess('Flag updated')),
    );
  }

  Future<void> addNotes(
      String reportId, String notes, String adminUid) async {
    final result =
        await _repository.addReportNotes(reportId, notes, adminUid);
    result.fold(
      (f) => emit(ReportActionError(f.message)),
      (_) => emit(const ReportActionSuccess('Notes saved')),
    );
  }

  // Helpers

  List<Report>? _allReports;

  void _emitFiltered(List<Report> reports) {
    _allReports = reports;
    _emitWithFilters(reports);
  }

  void _refreshFiltered() {
    if (_allReports != null) _emitWithFilters(_allReports!);
  }

  void _emitWithFilters(List<Report> reports) {
    var filtered = reports.where((r) {
      if (_filterStatus != null && r.status != _filterStatus) return false;
      if (_filterPriority != null && r.priority != _filterPriority) return false;
      if (_filterFlagged == true && !r.isFlagged) return false;
      if (_searchQuery.isNotEmpty) {
        return r.title.toLowerCase().contains(_searchQuery) ||
            r.description.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    emit(ReportLoaded(
      reports: filtered,
      totalCount: reports.length,
      newCount: reports.where((r) => r.isNew).length,
      flaggedCount: reports.where((r) => r.isFlagged).length,
      activeStatusFilter: _filterStatus,
      activePriorityFilter: _filterPriority,
      activeFlaggedFilter: _filterFlagged,
      searchQuery: _searchQuery,
    ));
  }

  @override
  Future<void> close() {
    _reportSubscription?.cancel();
    return super.close();
  }
}
