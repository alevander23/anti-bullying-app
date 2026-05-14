// lib/presentation/pages/groups/groups_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/group/group_cubit.dart';
import 'package:staff_webapp/presentation/bloc/group/group_state.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';
import 'group_detail_page.dart';
import 'create_edit_group_page.dart';

class GroupsPage extends StatefulWidget {
  final Admin admin;
  final List<Report> allReports;

  const GroupsPage({
    super.key,
    required this.admin,
    required this.allReports,
  });

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  String? _loadingGroupId;

  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().loadGroups(
          widget.admin.isSuperAdmin ? null : widget.admin.schoolId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final groupCubit = context.read<GroupCubit>();
    final reportCubit = context.read<ReportCubit>();
    return BlocConsumer<GroupCubit, GroupState>(
      listener: (context, state) {
        if (state is GroupActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is GroupActionError) {
          setState(() => _loadingGroupId = null);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is GroupDetailLoaded) {
          setState(() => _loadingGroupId = null);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: groupCubit),
                  BlocProvider.value(value: reportCubit),
                ],
                child: GroupDetailPage(
                  group: state.group,
                  timeline: state.timeline,
                  admin: widget.admin,
                  allReports: widget.allReports,
                ),
              ),
            ),
          );
        }
      },
      buildWhen: (_, s) => s is GroupLoading || s is GroupLoaded || s is GroupError || s is GroupInitial,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('Incident groups', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: () => _openCreate(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New group'),
                ),
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GroupState state) {
    if (state is GroupLoading || state is GroupInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is GroupError) {
      return Center(child: Text(state.message));
    }
    if (state is! GroupLoaded) return const SizedBox.shrink();

    final groups = state.filtered;

    return Column(
      children: [
        _buildStatsAndFilter(context, state),
        Expanded(
          child: groups.isEmpty
              ? _buildEmpty(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _GroupCard(
                    group: groups[i],
                    isLoading: _loadingGroupId == groups[i].id,
                    onTap: () {
                      setState(() => _loadingGroupId = groups[i].id);
                      context.read<GroupCubit>().loadGroupDetail(groups[i].id);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatsAndFilter(BuildContext context, GroupLoaded state) {
    final all = state.groups;
    final open = all.where((g) => g.status == GroupStatus.open).length;
    final review = all.where((g) => g.status == GroupStatus.underReview).length;
    final closed = all.where((g) => g.status == GroupStatus.closed).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatChip(label: 'Total', value: '${all.length}', color: Colors.grey.shade700),
              const SizedBox(width: 10),
              _StatChip(label: 'Open', value: '$open', color: const Color(0xFF185FA5)),
              const SizedBox(width: 10),
              _StatChip(label: 'Under review', value: '$review', color: const Color(0xFF534AB7)),
              const SizedBox(width: 10),
              _StatChip(label: 'Closed', value: '$closed', color: const Color(0xFF3B6D11)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filter:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'All',
                  active: state.statusFilter == null,
                  onTap: () => context.read<GroupCubit>().setStatusFilter(null),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Open',
                  active: state.statusFilter == GroupStatus.open,
                  onTap: () => context.read<GroupCubit>().setStatusFilter(GroupStatus.open),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Under review',
                  active: state.statusFilter == GroupStatus.underReview,
                  onTap: () => context.read<GroupCubit>().setStatusFilter(GroupStatus.underReview),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Closed',
                  active: state.statusFilter == GroupStatus.closed,
                  onTap: () => context.read<GroupCubit>().setStatusFilter(GroupStatus.closed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No groups yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Group related incidents together to build a case.',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
            label: const Text('Create first group'),
          ),
        ],
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GroupCubit>(),
          child: CreateEditGroupPage(
            admin: widget.admin,
            allReports: widget.allReports,
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.black87 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final IncidentGroup group;
  final VoidCallback onTap;
  final bool isLoading;
  const _GroupCard({required this.group, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Stack(
        children: [
          Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(group.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                if (group.priority == GroupPriority.high) _PriorityBadge(),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatusBadge(status: group.status),
                _MetaChip(icon: Icons.description_outlined,
                    label: '${group.connectedReportIds.length} report${group.connectedReportIds.length == 1 ? '' : 's'}'),
                _MetaChip(icon: Icons.people_outlined,
                    label: '${group.peopleInvolved.length} ${group.peopleInvolved.length == 1 ? 'person' : 'people'}'),
                _MetaChip(icon: Icons.schedule_outlined,
                    label: _timeAgo(group.updatedAt)),
              ],
            ),
          ],
        ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 14) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'just now';
  }
}

class _PriorityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFCEBEB),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text('High priority',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFA32D2D))),
  );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Colors.grey.shade500),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ],
  );
}