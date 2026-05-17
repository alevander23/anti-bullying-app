// lib/presentation/pages/dashboard/dashboard_page.dart
//
// Root of the admin dashboard. Watches the current admin's school assignment
// and feeds it to the ReportCubit. Super admins see a school selector.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/auth_cubit.dart';
import 'package:staff_webapp/presentation/bloc/auth_state.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';
import 'package:staff_webapp/presentation/bloc/report/report_state.dart';
import 'package:staff_webapp/presentation/bloc/school/school_cubit.dart';
import 'package:staff_webapp/presentation/bloc/school/school_state.dart';
import 'package:staff_webapp/presentation/widgets/dashboard/report_table.dart';
import 'package:staff_webapp/presentation/widgets/dashboard/stats_row.dart';
import 'package:staff_webapp/presentation/widgets/dashboard/filter_bar.dart';
import 'package:staff_webapp/presentation/widgets/dashboard/report_detail_sheet.dart';
import 'package:staff_webapp/presentation/pages/groups/groups_page.dart';
import 'package:staff_webapp/presentation/bloc/settings/settings_cubit.dart';
import 'package:staff_webapp/presentation/pages/settings/school_settings_page.dart';
import 'package:staff_webapp/di.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SchoolCubit>().watchCurrentAdmin();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<ReportCubit>().loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SchoolCubit, SchoolState>(
      listener: (context, state) {
        // When we know the admin's school, start the report stream
        if (state is SchoolLoaded) {
          if (state.admin.isSuperAdmin) {
            context.read<ReportCubit>().loadAllReports();
          } else if (state.admin.schoolId != null) {
            context.read<ReportCubit>().loadReports(state.admin.schoolId!);
          }
        }
        if (state is SchoolActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: BlocBuilder<SchoolCubit, SchoolState>(
        builder: (context, schoolState) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: _buildAppBar(context, schoolState),
            body: _buildBody(context, schoolState),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, SchoolState schoolState) {
    String title = 'Admin Dashboard';
    if (schoolState is SchoolLoaded) {
      title = schoolState.admin.isSuperAdmin
          ? 'Super Admin Dashboard'
          : 'Dashboard';
    }
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
      actions: [
        // Groups navigation button
        if (schoolState is SchoolLoaded)
          BlocBuilder<ReportCubit, ReportState>(
            builder: (context, reportState) {
              final reports = reportState is ReportLoaded ? reportState.reports : <Report>[];
              return TextButton.icon(
                onPressed: () {
                  final reportCubit = context.read<ReportCubit>();
                  Navigator.pushNamed(
                    context,
                    '/groups',
                    arguments: {
                      'admin': (schoolState as SchoolLoaded).admin,
                      'allReports': reports,
                      'reportCubit': reportCubit,
                    },
                  );
                },
                icon: const Icon(Icons.folder_outlined, size: 18),
                label: const Text('Groups'),
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: () => context.read<AuthCubit>().signOut(),
        ),
        // Settings button — shown when admin is loaded
        if (schoolState is SchoolLoaded)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'School Settings',
            onPressed: () {
              final admin = (schoolState as SchoolLoaded).admin;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => getIt<SettingsCubit>(),
                    child: SchoolSettingsPage(currentAdmin: admin),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SchoolState schoolState) {
    if (schoolState is SchoolLoading || schoolState is SchoolInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (schoolState is SchoolError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(schoolState.message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    if (schoolState is! SchoolLoaded) return const SizedBox.shrink();

    final admin = schoolState.admin;

    // Admin with no school assigned yet
    if (!admin.isSuperAdmin && admin.schoolId == null) {
      return const Center(
        child: Text(
          'You have not been assigned to a school yet.\nPlease contact your super admin.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return BlocListener<ReportCubit, ReportState>(
      listener: (context, state) {
        if (state is ReportActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is ReportActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<ReportCubit, ReportState>(
        buildWhen: (previous, current) =>
            current is ReportLoading ||
            current is ReportInitial ||
            current is ReportLoaded ||
            current is ReportError,
        builder: (context, reportState) {
          if (reportState is ReportLoading || reportState is ReportInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (reportState is ReportError) {
            return Center(child: Text(reportState.message));
          }
          if (reportState is! ReportLoaded) return const SizedBox.shrink();

          return _buildDashboardContent(context, admin, reportState);
        },
      ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, Admin admin, ReportLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome + admin name
              Text(
                'Welcome, ${admin.name}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Viewing reports in real-time',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Stats cards
              StatsRow(
                total: state.totalCount,
                newCount: state.newCount,
                flagged: state.flaggedCount,
                resolved: state.resolvedCount,
              ),
              const SizedBox(height: 24),

              // Filter bar
              FilterBar(
                activeStatusFilters: state.activeStatusFilters,
                activePriority: state.activePriorityFilter,
                activeFlagged: state.activeFlaggedFilter,
                hasActiveFilters: state.hasActiveFilters,
                sortField: state.sortField,
                sortAscending: state.sortAscending,
                onStatusToggled: (s) =>
                    context.read<ReportCubit>().toggleStatusFilter(s),
                onPriorityChanged: (p) =>
                    context.read<ReportCubit>().setPriorityFilter(p),
                onFlaggedChanged: (f) =>
                    context.read<ReportCubit>().setFlaggedFilter(f),
                onSearchChanged: (q) =>
                    context.read<ReportCubit>().setSearchQuery(q),
                onClearFilters: () =>
                    context.read<ReportCubit>().clearFilters(),
                onSortFieldChanged: (f) =>
                    context.read<ReportCubit>().setSortField(f),
                onSortDirectionChanged: (asc) =>
                    context.read<ReportCubit>().setSortAscending(asc),
              ),
              const SizedBox(height: 16),

              // Reports table
              ReportTable(
                reports: state.reports,
                hasMore: state.hasMore,
                sortField: state.sortField,
                onReportTap: (report) => _showReportDetail(context, report, admin),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDetail(
      BuildContext context, Report report, Admin admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ReportCubit>(),
        child: ReportDetailSheet(report: report, admin: admin),
      ),
    );
  }
}