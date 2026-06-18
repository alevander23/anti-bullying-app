// lib/presentation/pages/groups/groups_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/group/group_cubit.dart';
import 'package:staff_webapp/presentation/bloc/group/group_state.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';
import 'create_edit_group_page.dart';

class GroupsPage extends StatefulWidget {
  final Admin admin;
  final List<Report> allReports;
  final int windowDays;

  const GroupsPage({
    super.key,
    required this.admin,
    required this.allReports,
    this.windowDays = 5,
  });

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin {
  String? _loadingGroupId;
  late final TabController _tabController;

  final Set<String> _confirmingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<GroupCubit>().loadGroups(
          widget.admin.isSuperAdmin ? null : widget.admin.schoolId,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupCubit>().computeSuggestions(widget.allReports,
          windowDays: widget.windowDays);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupCubit = context.read<GroupCubit>();
    final reportCubit = context.read<ReportCubit>();

    return BlocConsumer<GroupCubit, GroupState>(
      listener: (context, state) {
        if (state is GroupActionSuccess) {
          setState(() => _confirmingIds.clear());
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is GroupActionError) {
          setState(() {
            _loadingGroupId = null;
            _confirmingIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is GroupDetailLoading) {
          if (ModalRoute.of(context)?.isCurrent == true) {
            Navigator.pushNamed(
              context,
              '/groups/detail',
              arguments: {
                'groupId': state.groupId,
                'admin': widget.admin,
                'allReports': widget.allReports,
                'groupCubit': groupCubit,
                'reportCubit': reportCubit,
              },
            );
          }
        }
        if (state is GroupDetailLoaded) {
          setState(() => _loadingGroupId = null);
        }
      },
      buildWhen: (_, s) =>
          s is GroupLoading ||
          s is GroupLoaded ||
          s is GroupError ||
          s is GroupInitial,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('Incident Groups',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49),
              child: Column(
                children: [
                  const Divider(height: 1),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: Colors.black87,
                    indicatorWeight: 2.5,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: [
                      const Tab(text: 'Groups'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Suggestions'),
                            if (state is GroupLoaded &&
                                state.suggestions.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _SuggestionBadge(
                                  count: state.suggestions.length),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildGroupsTab(context, state),
              _buildSuggestionsTab(context, state),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 1: existing groups ────────────────────────────────────────────────

  Widget _buildGroupsTab(BuildContext context, GroupState state) {
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _GroupCard(
                    group: groups[i],
                    isLoading: _loadingGroupId == groups[i].id,
                    onTap: () {
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
    final review =
        all.where((g) => g.status == GroupStatus.underReview).length;
    final closed = all.where((g) => g.status == GroupStatus.closed).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat cards — same visual weight as dashboard StatsRow ─────────
          Row(
            children: [
              Expanded(
                child: _DashStatCard(
                  label: 'Total',
                  value: '${all.length}',
                  icon: Icons.folder_outlined,
                  iconColor: Colors.grey.shade600,
                  iconBg: Colors.grey.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashStatCard(
                  label: 'Open',
                  value: '$open',
                  icon: Icons.folder_open_outlined,
                  iconColor: const Color(0xFF185FA5),
                  iconBg: const Color(0xFFE6F1FB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashStatCard(
                  label: 'Under Review',
                  value: '$review',
                  icon: Icons.find_in_page_outlined,
                  iconColor: const Color(0xFF534AB7),
                  iconBg: const Color(0xFFEEEDFE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashStatCard(
                  label: 'Closed',
                  value: '$closed',
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF3B6D11),
                  iconBg: const Color(0xFFEAF3DE),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Filter pills ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Filter:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700)),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'All',
                  active: state.statusFilter == null,
                  onTap: () =>
                      context.read<GroupCubit>().setStatusFilter(null),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Open',
                  active: state.statusFilter == GroupStatus.open,
                  onTap: () => context
                      .read<GroupCubit>()
                      .setStatusFilter(GroupStatus.open),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Under Review',
                  active: state.statusFilter == GroupStatus.underReview,
                  onTap: () => context
                      .read<GroupCubit>()
                      .setStatusFilter(GroupStatus.underReview),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Closed',
                  active: state.statusFilter == GroupStatus.closed,
                  onTap: () => context
                      .read<GroupCubit>()
                      .setStatusFilter(GroupStatus.closed),
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
          Icon(Icons.folder_open_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No groups yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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

  // ── Tab 2: auto suggestions ───────────────────────────────────────────────

  Widget _buildSuggestionsTab(BuildContext context, GroupState state) {
    if (state is GroupLoading || state is GroupInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is! GroupLoaded) return const SizedBox.shrink();

    final suggestions = state.suggestions;

    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No suggestions',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              'When multiple reports mention the same\nperson within ${widget.windowDays} days, a suggestion will appear here.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner — same colour language as the rest of the app
        Container(
          color: const Color(0xFFF0F4FF),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: Colors.indigo.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reports that share a bully name and occurred within '
                  '${widget.windowDays} day${widget.windowDays == 1 ? '' : 's'} '
                  'of each other are grouped here. Review each suggestion and '
                  'confirm the ones you believe are related.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo.shade800,
                      height: 1.45),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _SuggestionCard(
              suggestion: suggestions[i],
              allReports: widget.allReports,
              isConfirming: _confirmingIds.contains(suggestions[i].id),
              onConfirm: () =>
                  _confirmSuggestion(context, suggestions[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _openCreate(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/groups/create',
      arguments: {
        'admin': widget.admin,
        'allReports': widget.allReports,
        'groupCubit': context.read<GroupCubit>(),
      },
    );
  }

  Future<void> _confirmSuggestion(
      BuildContext context, AutoGroupSuggestion suggestion) async {
    setState(() => _confirmingIds.add(suggestion.id));
    await context.read<GroupCubit>().confirmSuggestion(
          suggestion: suggestion,
          adminName: widget.admin.name,
          adminId: widget.admin.id,
          schoolId: widget.admin.schoolId ?? '',
        );
  }
}

// ── Date helper ───────────────────────────────────────────────────────────────

String _fmtDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

// ── Stat card — mirrors the card style used in dashboard's StatsRow ───────────

class _DashStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _DashStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.1),
                ),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SuggestionBadge extends StatelessWidget {
  final int count;
  const _SuggestionBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      );
}

class _SuggestionCard extends StatelessWidget {
  final AutoGroupSuggestion suggestion;
  final List<Report> allReports;
  final bool isConfirming;
  final VoidCallback onConfirm;

  const _SuggestionCard({
    required this.suggestion,
    required this.allReports,
    required this.isConfirming,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final nameDisplay = suggestion.bullyNames
        .map((n) => n[0].toUpperCase() + n.substring(1))
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 11, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text('Auto-detected',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700)),
                    ],
                  ),
                ),
                const Spacer(),
                isConfirming
                    ? SizedBox(
                        width: 120,
                        height: 32,
                        child: FilledButton(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: EdgeInsets.zero,
                          ),
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 32,
                        child: FilledButton.icon(
                          onPressed: onConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Confirm group'),
                        ),
                      ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Reports involving $nameDisplay',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _MetaChip(
                  icon: Icons.description_outlined,
                  label:
                      '${suggestion.reports.length} report${suggestion.reports.length == 1 ? '' : 's'}',
                ),
                _MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label:
                      '${_fmtDate(suggestion.earliest)} – ${_fmtDate(suggestion.latest)}',
                ),
                _MetaChip(
                  icon: Icons.schedule_outlined,
                  label: '${suggestion.daySpan} day span',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          ...suggestion.reports.map((r) => _ReportRow(report: r)),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final Report report;
  const _ReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.article_outlined,
              size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${_fmtDate(report.submittedAt)}  ·  ${_categoryLabel(report.category)}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (report.bullyNames.isNotEmpty)
            Wrap(
              spacing: 4,
              children: report.bullyNames
                  .map((n) => _BullyChip(name: n))
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _categoryLabel(ReportCategory c) => switch (c) {
        ReportCategory.bullying => 'Bullying',
        ReportCategory.harassment => 'Harassment',
        ReportCategory.safety => 'Safety',
        ReportCategory.other => 'Other',
      };
}

class _BullyChip extends StatelessWidget {
  final String name;
  const _BullyChip({required this.name});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          name,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.red.shade700),
        ),
      );
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterPill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  active ? Colors.black87 : Colors.grey.shade300),
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
  const _GroupCard(
      {required this.group,
      required this.onTap,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      if (group.priority == GroupPriority.high)
                        _PriorityBadge(),
                    ],
                  ),
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatusBadge(status: group.status),
                      _MetaChip(
                          icon: Icons.description_outlined,
                          label:
                              '${group.connectedReportIds.length} report${group.connectedReportIds.length == 1 ? '' : 's'}'),
                      _MetaChip(
                          icon: Icons.people_outlined,
                          label:
                              '${group.peopleInvolved.length} ${group.peopleInvolved.length == 1 ? 'person' : 'people'}'),
                      _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: _timeAgo(group.updatedAt)),
                      if (group.tags.contains('auto-grouped'))
                        _AutoTag(),
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
                      child:
                          CircularProgressIndicator(strokeWidth: 2.5),
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

class _AutoTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 10, color: Colors.orange.shade700),
            const SizedBox(width: 3),
            Text('Auto-grouped',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade700)),
          ],
        ),
      );
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
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA32D2D))),
      );
}

class _StatusBadge extends StatelessWidget {
  final GroupStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      GroupStatus.open =>
        ('Open', const Color(0xFFE6F1FB), const Color(0xFF185FA5)),
      GroupStatus.underReview =>
        ('Under review', const Color(0xFFEEEDFE), const Color(0xFF534AB7)),
      GroupStatus.closed =>
        ('Closed', const Color(0xFFEAF3DE), const Color(0xFF3B6D11)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
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
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500)),
        ],
      );
}