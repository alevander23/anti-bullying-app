// lib/presentation/pages/groups/group_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/group/group_cubit.dart';
import 'package:staff_webapp/presentation/bloc/group/group_state.dart';
import 'package:staff_webapp/presentation/widgets/dashboard/report_detail_sheet.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';
import 'create_edit_group_page.dart';

class GroupDetailPage extends StatefulWidget {
  final IncidentGroup group;
  final List<GroupTimelineEntry> timeline;
  final Admin admin;
  final List<Report> allReports;

  const GroupDetailPage({
    super.key,
    required this.group,
    required this.timeline,
    required this.admin,
    required this.allReports,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late IncidentGroup _group;
  late List<GroupTimelineEntry> _timeline;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _group = widget.group;
    _timeline = widget.timeline;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupCubit, GroupState>(
      listener: (context, state) {
        if (state is GroupDetailLoaded && state.group.id == _group.id) {
          setState(() {
            _group = state.group;
            _timeline = state.timeline;
          });
        }
        if (state is GroupActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is GroupActionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text(_group.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            actions: [
              TextButton.icon(
                onPressed: () => _openEdit(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black87,
              tabs: [
                const Tab(text: 'Overview'),
                Tab(text: 'Reports (${_group.connectedReportIds.length})'),
                const Tab(text: 'Timeline'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(group: _group, allReports: widget.allReports, admin: widget.admin),
              _ReportsTab(group: _group, allReports: widget.allReports, admin: widget.admin),
              _TimelineTab(timeline: _timeline),
            ],
          ),
        );
      },
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GroupCubit>(),
          child: CreateEditGroupPage(
            admin: widget.admin,
            allReports: widget.allReports,
            existing: _group,
          ),
        ),
      ),
    ).then((_) {
      // Refresh detail after edit
      context.read<GroupCubit>().loadGroupDetail(_group.id);
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group'),
        content: const Text('This will permanently delete the group and its timeline. Linked reports will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GroupCubit>().deleteGroup(_group.id);
              Navigator.pop(context); // back to list
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final IncidentGroup group;
  final List<Report> allReports;
  final Admin admin;
  const _OverviewTab({required this.group, required this.allReports, required this.admin});

  @override
  Widget build(BuildContext context) {
    final reportCubit = context.read<ReportCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final main = _buildMain(context);
          final side = _buildSide(context, reportCubit);
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 16),
                SizedBox(width: 280, child: side),
              ],
            );
          }
          return Column(children: [main, const SizedBox(height: 16), side]);
        },
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    return Column(
      children: [
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusBadge(status: group.status),
                  if (group.priority == GroupPriority.high) _PriorityBadge(),
                  ...group.tags.map((t) => _TagPill(tag: t)),
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(group.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
              ],
            ],
          ),
        ),
        if (group.notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DetailCard(
            title: 'Notes',
            child: Text(group.notes,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
          ),
        ],
        const SizedBox(height: 14),
        _DetailCard(
          title: 'People involved',
          child: group.peopleInvolved.isEmpty
              ? Text('No people added.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
              : Column(
                  children: group.peopleInvolved.map((p) => _PersonRow(person: p)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSide(BuildContext context, ReportCubit reportCubit) {
    final linked = allReports.where((r) => group.connectedReportIds.contains(r.id)).toList();
    return Column(
      children: [
        _DetailCard(
          title: 'Linked reports',
          child: Column(
            children: linked.isEmpty
                ? [Text('No reports linked.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))]
                : linked.map((r) => _LinkedReportTile(report: r, admin: admin, reportCubit: reportCubit)).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _DetailCard(
          title: 'Case info',
          child: _InfoTable(rows: [
            ('Created by', group.createdBy),
            ('Created', _formatDate(group.createdAt)),
            ('Last updated', _formatDate(group.updatedAt)),
          ]),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}

// ── Reports tab ───────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  final IncidentGroup group;
  final List<Report> allReports;
  final Admin admin;
  const _ReportsTab({required this.group, required this.allReports, required this.admin});

  @override
  Widget build(BuildContext context) {
    final reportCubit = context.read<ReportCubit>();
    final linked = allReports.where((r) => group.connectedReportIds.contains(r.id)).toList();

    if (linked.isEmpty) {
      return Center(
        child: Text('No reports linked to this group.',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: linked.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _FullReportTile(report: linked[i], admin: admin, reportCubit: reportCubit),
    );
  }
}

// ── Timeline tab ──────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  final List<GroupTimelineEntry> timeline;
  const _TimelineTab({required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return Center(
        child: Text('No timeline entries yet.',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: timeline.length,
      itemBuilder: (_, i) {
        final entry = timeline[i];
        final isLast = i == timeline.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7F77DD),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.message,
                          style: const TextStyle(fontSize: 13, height: 1.5)),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatDateTime(entry.timestamp)} · ${entry.adminName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _DetailCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final PersonInvolved person;
  const _PersonRow({required this.person});

  @override
  Widget build(BuildContext context) {
    final initials = person.name.split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEEEDFE),
            child: Text(initials,
                style: const TextStyle(fontSize: 10, color: Color(0xFF534AB7), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text(person.role, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          if (person.notes != null && person.notes!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(child: Text('— ${person.notes}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
          ],
        ],
      ),
    );
  }
}

class _LinkedReportTile extends StatelessWidget {
  final Report report;
  final Admin admin;
  final ReportCubit reportCubit;
  const _LinkedReportTile({required this.report, required this.admin, required this.reportCubit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => BlocProvider.value(
          value: reportCubit,
          child: ReportDetailSheet(report: report, admin: admin),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF534AB7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(_categoryLabel(report.category),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(ReportCategory c) => switch (c) {
    ReportCategory.bullying   => 'Bullying',
    ReportCategory.harassment => 'Harassment',
    ReportCategory.safety     => 'Safety',
    ReportCategory.other      => 'Other',
  };
}

class _FullReportTile extends StatelessWidget {
  final Report report;
  final Admin admin;
  final ReportCubit reportCubit;
  const _FullReportTile({required this.report, required this.admin, required this.reportCubit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => BlocProvider.value(
          value: reportCubit,
          child: ReportDetailSheet(report: report, admin: admin),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEDFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF534AB7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(_categoryLabel(report.category),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                      _StatusPill(status: report.status),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(ReportCategory c) => switch (c) {
    ReportCategory.bullying   => 'Bullying',
    ReportCategory.harassment => 'Harassment',
    ReportCategory.safety     => 'Safety',
    ReportCategory.other      => 'Other',
  };
}

class _StatusPill extends StatelessWidget {
  final ReportStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReportStatus.newReport  => ('New', const Color(0xFF185FA5)),
      ReportStatus.reviewed   => ('Reviewed', const Color(0xFF534AB7)),
      ReportStatus.escalated  => ('Escalated', const Color(0xFFBA7517)),
      ReportStatus.resolved   => ('Resolved', const Color(0xFF3B6D11)),
    };
    return Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500));
  }
}

class _InfoTable extends StatelessWidget {
  final List<(String, String)> rows;
  const _InfoTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(row.$1, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            Text(row.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      )).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GroupStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      GroupStatus.open        => ('Open', const Color(0xFFE6F1FB), const Color(0xFF185FA5)),
      GroupStatus.underReview => ('Under review', const Color(0xFFEEEDFE), const Color(0xFF534AB7)),
      GroupStatus.closed      => ('Closed', const Color(0xFFEAF3DE), const Color(0xFF3B6D11)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFCEBEB),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text('High priority',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA32D2D))),
  );
}

class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill({required this.tag});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEDFE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(tag, style: const TextStyle(fontSize: 12, color: Color(0xFF534AB7))),
  );
}