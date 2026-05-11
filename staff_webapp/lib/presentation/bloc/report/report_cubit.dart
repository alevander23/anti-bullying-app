// lib/presentation/bloc/report/report_cubit.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/admin_repository.dart';
import 'report_state.dart';

// Default statuses shown on load — resolved is hidden unless the user selects it
const List<ReportStatus> _kDefaultStatuses = [
  ReportStatus.newReport,
  ReportStatus.reviewed,
  ReportStatus.escalated,
];

class ReportCubit extends Cubit<ReportState> {
  final AdminRepository _repository;

  // The school/null context for this session (null = super admin sees all)
  String? _schoolId;

  // Active filter state — multi-status selection persists until explicitly cleared
  Set<ReportStatus> _filterStatuses = Set.from(_kDefaultStatuses);
  ReportPriority? _filterPriority;
  bool? _filterFlagged;
  String _searchQuery = '';

  // Pagination state
  List<Report> _loadedReports = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingPage = false;

  // Stats are loaded independently of the report list
  int _statTotal = 0;
  int _statNew = 0;
  int _statFlagged = 0;
  int _statResolved = 0;

  static const int _pageSize = 20;

  ReportCubit(this._repository) : super(const ReportInitial());

  // Start listening to reports for a school

  Future<void> loadReports(String schoolId) async {
    _schoolId = schoolId;
    await _reset();
  }

  // Feature 4: Super admin passes null to see all reports across every school
  Future<void> loadAllReports() async {
    _schoolId = null;
    await _reset();
  }

  // Filters

  void toggleStatusFilter(ReportStatus status) {
    if (_filterStatuses.contains(status)) {
      _filterStatuses = Set.from(_filterStatuses)..remove(status);
    } else {
      _filterStatuses = Set.from(_filterStatuses)..add(status);
    }
    _resetAndLoad();
  }

  void setPriorityFilter(ReportPriority? priority) {
    _filterPriority = priority;
    _resetAndLoad();
  }

  void setFlaggedFilter(bool? flagged) {
    _filterFlagged = flagged;
    _resetAndLoad();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _emitCurrent();
  }

  void clearFilters() {
    _filterStatuses = Set.from(_kDefaultStatuses);
    _filterPriority = null;
    _filterFlagged = null;
    _searchQuery = '';
    _resetAndLoad();
  }

  // Load the next page when the user scrolls to the bottom
  Future<void> loadNextPage() async {
    if (_isLoadingPage || !_hasMore) return;
    await _fetchPage();
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
    // Refresh stats and visible list after a status change
    await _loadStats();
    _resetAndLoad();
  }

  Future<void> toggleFlag(String reportId, bool current) async {
    final result =
        await _repository.toggleReportFlag(reportId, !current);
    result.fold(
      (f) => emit(ReportActionError(f.message)),
      (_) => emit(const ReportActionSuccess('Flag updated')),
    );
    await _loadStats();
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

  Future<void> _reset() async {
    _loadedReports = [];
    _lastDocument = null;
    _hasMore = true;
    _isLoadingPage = false;
    emit(const ReportLoading());
    await Future.wait([_loadStats(), _fetchPage()]);
  }

  void _resetAndLoad() {
    _loadedReports = [];
    _lastDocument = null;
    _hasMore = true;
    _isLoadingPage = false;
    _fetchPage();
  }
  Future<void> _loadStats() async {
    final result = await _repository.getReportStats(_schoolId);
    result.fold(
      (f) => debugPrint('🔥 STATS ERROR: ${f.message}'),
      (stats) {
        _statTotal = stats['total'] ?? 0;
        _statNew = stats['new'] ?? 0;
        _statFlagged = stats['flagged'] ?? 0;
        _statResolved = stats['resolved'] ?? 0;
      },
    );
  }

  Future<void> _fetchPage() async {
    if (_isLoadingPage || !_hasMore) return;
    _isLoadingPage = true;

    final result = await _repository.getReportPage(
      schoolId: _schoolId,
      statuses: _filterStatuses.toList(),
      priority: _filterPriority,
      isFlagged: _filterFlagged,
      startAfter: _lastDocument,
      pageSize: _pageSize,
    );

    _isLoadingPage = false;

    result.fold(
      (f) {
        debugPrint('🔥 REPORT PAGE ERROR: ${f.message}');
        emit(ReportError('Failed to load reports: ${f.message}'));
      },
      (page) {
        if (page.reports.length < _pageSize) _hasMore = false;
        if (page.lastDoc != null) _lastDocument = page.lastDoc;
        _loadedReports = [..._loadedReports, ...page.reports];
        _emitCurrent();
      },
    );
  }

  void _emitCurrent() {
    // Apply client-side search filter on top of server-paginated results
    final filtered = _searchQuery.isEmpty
        ? _loadedReports
        : _loadedReports.where((r) {
            return r.title.toLowerCase().contains(_searchQuery) ||
                r.description.toLowerCase().contains(_searchQuery);
          }).toList();

    emit(ReportLoaded(
      reports: filtered,
      totalCount: _statTotal,
      newCount: _statNew,
      flaggedCount: _statFlagged,
      resolvedCount: _statResolved,
      activeStatusFilters: _filterStatuses,
      activePriorityFilter: _filterPriority,
      activeFlaggedFilter: _filterFlagged,
      searchQuery: _searchQuery,
      hasMore: _hasMore,
    ));
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
