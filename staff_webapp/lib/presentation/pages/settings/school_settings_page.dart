// lib/presentation/pages/settings/school_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/pending_admin_entity.dart';
import 'package:staff_webapp/domain/entities/school_entity.dart';
import 'package:staff_webapp/presentation/bloc/settings/settings_cubit.dart';
import 'package:staff_webapp/presentation/bloc/settings/settings_state.dart';

class SchoolSettingsPage extends StatefulWidget {
  final Admin currentAdmin;

  const SchoolSettingsPage({super.key, required this.currentAdmin});

  @override
  State<SchoolSettingsPage> createState() => _SchoolSettingsPageState();
}

class _SchoolSettingsPageState extends State<SchoolSettingsPage> {
  String? _focusedSchoolId;

  static const Color _accent  = Color(0xFF4F46E5);
  static const Color _bg      = Color(0xFFF5F7FA);
  static const Color _surface = Colors.white;
  static const Color _danger  = Color(0xFFDC2626);
  static const Color _warning = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    final admin = widget.currentAdmin;
    if (admin.isSuperAdmin) {
      if (admin.schoolId != null && admin.schoolId!.isNotEmpty) {
        _focusedSchoolId = admin.schoolId;
        context.read<SettingsCubit>().loadForSuperAdmin(_focusedSchoolId!);
      } else {
        // Super admin with no school assigned — load everything, no focused school
        context.read<SettingsCubit>().loadForSuperAdminNoSchool();
      }
    } else {
      context.read<SettingsCubit>().loadForAdmin(admin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ));
        }
        if (state is SettingsActionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ));
        }
      },
      builder: (context, state) {
        // Derive loaded data from any state that carries it
        SettingsLoaded? loaded = _extractLoaded(state);
        final isLoading = state is SettingsActionInProgress;
        final pendingCount = loaded?.pendingAdmins.length ?? 0;

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            title: const Text('School Settings',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            backgroundColor: _surface,
            foregroundColor: Colors.black87,
            elevation: 0,
            actions: [
              // Live badge showing pending approvals count
              if (pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _warning,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pending_outlined,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('$pendingCount pending',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: _buildBody(context, state, loaded, isLoading),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SettingsState state,
      SettingsLoaded? loaded, bool isLoading) {
    if (state is SettingsLoading || state is SettingsInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is SettingsError) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(state.message, style: const TextStyle(fontSize: 15)),
        ]),
      );
    }
    if (loaded == null) return const SizedBox.shrink();

    if (widget.currentAdmin.isSuperAdmin) {
      return _buildSuperAdminLayout(context, loaded, isLoading);
    } else {
      return _buildAdminLayout(context, loaded, isLoading);
    }
  }

  // ─── Regular admin layout ─────────────────────────────────────────────────

  Widget _buildAdminLayout(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (data.pendingAdmins.isNotEmpty)
                _pendingApprovalsCard(context, data, isLoading),
              if (data.pendingAdmins.isNotEmpty) const SizedBox(height: 20),
              _schoolInfoCard(context, data, isLoading),
              const SizedBox(height: 20),
              _retentionCard(context, data, isLoading),
              const SizedBox(height: 20),
              _autoGroupCard(context, data, isLoading),
              const SizedBox(height: 20),
              _adminsCard(context, data, isLoading),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
      if (isLoading) _loadingOverlay(),
    ]);
  }

  // ─── Super admin layout ───────────────────────────────────────────────────

  Widget _buildSuperAdminLayout(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    // Super admin with no focused school yet. just show the school picker + global panels
    final hasFocusedSchool = _focusedSchoolId != null && _focusedSchoolId!.isNotEmpty;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 880;
      if (isWide) {
        return Stack(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 260, child: _schoolSidebar(context, data, isLoading)),
            const VerticalDivider(width: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (data.pendingAdmins.isNotEmpty)
                    _pendingApprovalsCard(context, data, isLoading),
                  if (data.pendingAdmins.isNotEmpty) const SizedBox(height: 20),
                  if (!hasFocusedSchool)
                    _noSchoolSelectedCard()
                  else ...[
                    _schoolInfoCard(context, data, isLoading),
                    const SizedBox(height: 20),
                    _retentionCard(context, data, isLoading),
                    const SizedBox(height: 20),
                    _autoGroupCard(context, data, isLoading),
                    const SizedBox(height: 20),
                    _adminsCard(context, data, isLoading),
                  ],
                  const SizedBox(height: 20),
                  _globalAdminsCard(context, data, isLoading),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ]),
          if (isLoading) _loadingOverlay(),
        ]);
      }
      return Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _schoolSidebarNarrow(context, data, isLoading),
            const SizedBox(height: 20),
            if (data.pendingAdmins.isNotEmpty)
              _pendingApprovalsCard(context, data, isLoading),
            if (data.pendingAdmins.isNotEmpty) const SizedBox(height: 20),
            if (!hasFocusedSchool)
              _noSchoolSelectedCard()
            else ...[
              _schoolInfoCard(context, data, isLoading),
              const SizedBox(height: 20),
              _retentionCard(context, data, isLoading),
              const SizedBox(height: 20),
              _autoGroupCard(context, data, isLoading),
              const SizedBox(height: 20),
              _adminsCard(context, data, isLoading),
            ],
            const SizedBox(height: 20),
            _globalAdminsCard(context, data, isLoading),
            const SizedBox(height: 40),
          ]),
        ),
        if (isLoading) _loadingOverlay(),
      ]);
    });
  }

  Widget _noSchoolSelectedCard() {
    return _card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Select a school from the list to view and edit its settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ─── Pending approvals card ───────────────────────────────────────────────

  Widget _pendingApprovalsCard(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    return _card(
      borderColor: _warning.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(
          Icons.pending_actions_outlined,
          'Pending Approvals',
          iconColor: _warning,
          badge: data.pendingAdmins.length,
        ),
        const SizedBox(height: 6),
        Text(
          'These people signed in with SSO but don\'t have admin access yet. '
          'Approve them to grant access, or reject to remove their request.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        ...data.pendingAdmins.map((p) =>
            _pendingAdminTile(context, p, data, isLoading)),
      ]),
    );
  }

  Widget _pendingAdminTile(BuildContext context, PendingAdmin pending,
      SettingsLoaded data, bool isLoading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            backgroundColor: Colors.amber.shade100,
            backgroundImage: pending.photoUrl != null
                ? NetworkImage(pending.photoUrl!)
                : null,
            child: pending.photoUrl == null
                ? Text(
                    pending.name.isNotEmpty
                        ? pending.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pending.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(pending.email,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ]),
          ),
          // Actions
          TextButton(
            onPressed: isLoading
                ? null
                : () => _confirmReject(context, pending),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: isLoading
                ? null
                : () => _showApproveDialog(context, pending, data),
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: const Text('Approve'),
          ),
        ]),
      ),
    );
  }

  // ─── School info card ─────────────────────────────────────────────────────

  Widget _schoolInfoCard(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(
          Icons.domain_outlined,
          'School Information',
          action: TextButton.icon(
            onPressed:
                isLoading ? null : () => _showEditSchoolDialog(context, data.school),
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Edit'),
            style: TextButton.styleFrom(foregroundColor: _accent),
          ),
        ),
        const SizedBox(height: 16),
        _infoRow('Name', data.school.name),
        const Divider(height: 24),
        _infoRow('Address',
            data.school.address.isEmpty ? '—' : data.school.address),
        const Divider(height: 24),
        _infoRow('Status', data.school.isActive ? 'Active' : 'Inactive',
            valueColor: data.school.isActive
                ? Colors.green.shade700
                : Colors.red.shade700),
        if (widget.currentAdmin.isSuperAdmin) ...[
          const Divider(height: 24),
          Row(children: [
            const Text('Active',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            const Spacer(),
            Switch.adaptive(
              value: data.school.isActive,
              activeColor: _accent,
              onChanged: isLoading
                  ? null
                  : (val) => context
                      .read<SettingsCubit>()
                      .toggleSchoolActive(data.school.id, val),
            ),
          ]),
        ],
      ]),
    );
  }

  // ─── Retention card ───────────────────────────────────────────────────────

  Widget _retentionCard(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    final retentionDays = data.school.resolvedReportRetentionDays;
    final options = <int?>[null, 30, 60, 90, 180, 365];

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.auto_delete_outlined, 'Report Retention'),
        const SizedBox(height: 6),
        Text(
          'Resolved reports are permanently deleted after the chosen period. '
          'This runs automatically on first login each day.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          value: retentionDays,
          decoration: InputDecoration(
            labelText: 'Delete resolved reports after',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: options.map((days) {
            final label = days == null
                ? 'Never (keep forever)'
                : days < 365
                    ? '$days days'
                    : '1 year';
            return DropdownMenuItem(value: days, child: Text(label));
          }).toList(),
          onChanged: isLoading
              ? null
              : (val) => context
                  .read<SettingsCubit>()
                  .updateRetentionPolicy(data.school.id, val),
        ),
        if (retentionDays != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_outlined,
                  size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resolved reports older than $retentionDays days will be permanently deleted.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // ─── Auto-grouping window card ────────────────────────────────────────────

  Widget _autoGroupCard(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    final currentDays = data.school.autoGroupWindowDays;
    // Sensible preset options (1–14 days)
    const options = [1, 2, 3, 5, 7, 10, 14];

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.auto_awesome_outlined, 'Incident Grouping'),
        const SizedBox(height: 6),
        Text(
          'When reports mention the same person and fall within this window, '
          'they are suggested as a potential group for review.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: options.contains(currentDays) ? currentDays : options.first,
          decoration: InputDecoration(
            labelText: 'Auto-group window',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: options
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d == 1 ? '1 day' : '$d days'),
                  ))
              .toList(),
          onChanged: isLoading
              ? null
              : (val) {
                  if (val != null) {
                    context
                        .read<SettingsCubit>()
                        .updateAutoGroupWindow(data.school.id, val);
                  }
                },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFCAF0)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 15, color: Colors.indigo.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reports within $currentDays day${currentDays == 1 ? '' : 's'} of each other '
                'that share a bully name will appear as suggestions on the Groups page.',
                style: TextStyle(fontSize: 12, color: Colors.indigo.shade800),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─── Admins card (this school) ────────────────────────────────────────────

  Widget _adminsCard(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.people_outline, 'Administrators'),
        const SizedBox(height: 12),
        if (data.admins.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No admins assigned to this school yet.',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          )
        else
          ...data.admins.map((admin) => _adminTile(context, admin, isLoading,
              isCurrentUser: admin.id == widget.currentAdmin.id)),
      ]),
    );
  }

  Widget _adminTile(BuildContext context, Admin admin, bool isLoading,
      {required bool isCurrentUser}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _accent.withOpacity(0.12),
          child: Text(
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        title: Row(children: [
          Text(admin.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          if (isCurrentUser) ...[
            const SizedBox(width: 6),
            _pill('You', Colors.indigo.shade100, Colors.indigo.shade700),
          ],
          if (admin.isSuperAdmin) ...[
            const SizedBox(width: 6),
            _pill(
                'Super', Colors.purple.shade100, Colors.purple.shade700),
          ],
        ]),
        subtitle: Text(admin.email,
            style:
                TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: isCurrentUser
            ? null
            : IconButton(
                icon: const Icon(Icons.person_remove_outlined, size: 18),
                color: _danger,
                tooltip: 'Remove admin',
                onPressed: isLoading
                    ? null
                    : () => _confirmRemoveAdmin(context, admin),
              ),
      ),
    );
  }

  // ─── Global admins card (super admin only) ────────────────────────────────

  Widget _globalAdminsCard(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(
          Icons.admin_panel_settings_outlined,
          'All Admins (Global)',
        ),
        const SizedBox(height: 4),
        Text(
          'All admins across every school. Use the menu to reassign or remove.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        if (data.allAdmins.isEmpty)
          Text('No admins found.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14))
        else
          ...data.allAdmins.map((admin) =>
              _globalAdminTile(context, admin, data.allSchools, isLoading)),
      ]),
    );
  }

  Widget _globalAdminTile(BuildContext context, Admin admin,
      List<School> allSchools, bool isLoading) {
    final schoolName = admin.schoolId != null
        ? allSchools
            .where((s) => s.id == admin.schoolId)
            .map((s) => s.name)
            .firstOrNull
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: admin.isSuperAdmin
              ? Colors.purple.shade100
              : _accent.withOpacity(0.12),
          child: Text(
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: admin.isSuperAdmin ? Colors.purple.shade700 : _accent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        title: Row(children: [
          Expanded(
            child: Text(admin.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ),
          if (admin.isSuperAdmin)
            _pill('Super', Colors.purple.shade100, Colors.purple.shade700),
        ]),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(admin.email,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
              if (schoolName != null)
                Text(schoolName,
                    style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500))
              else if (!admin.isSuperAdmin)
                Text('No school assigned',
                    style: TextStyle(
                        color: Colors.orange.shade700, fontSize: 12)),
            ]),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          enabled: !isLoading,
          itemBuilder: (_) => [
            if (!admin.isSuperAdmin)
              const PopupMenuItem(
                  value: 'assign', child: Text('Assign to school')),
            if (admin.id != widget.currentAdmin.id)
              const PopupMenuItem(
                  value: 'remove',
                  child:
                      Text('Remove', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (action) {
            if (action == 'assign') {
              _showAssignSchoolDialog(context, admin, allSchools);
            } else if (action == 'remove') {
              _confirmRemoveAdmin(context, admin);
            }
          },
        ),
      ),
    );
  }

  // ─── School sidebar ───────────────────────────────────────────────────────

  Widget _schoolSidebar(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    return Container(
      color: _surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(children: [
            const Text('Schools',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.black54)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              tooltip: 'Create new school',
              onPressed:
                  isLoading ? null : () => _showCreateSchoolDialog(context),
              color: _accent,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: data.allSchools.length,
            itemBuilder: (context, i) {
              final school = data.allSchools[i];
              final isFocused = school.id == _focusedSchoolId;
              return _schoolSidebarTile(context, school, isFocused, isLoading);
            },
          ),
        ),
      ]),
    );
  }

  Widget _schoolSidebarNarrow(
      BuildContext context, SettingsLoaded data, bool isLoading) {
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('All Schools',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          TextButton.icon(
            onPressed:
                isLoading ? null : () => _showCreateSchoolDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New'),
            style: TextButton.styleFrom(foregroundColor: _accent),
          ),
        ]),
        const SizedBox(height: 8),
        ...data.allSchools.map((school) => _schoolSidebarTile(
            context, school, school.id == _focusedSchoolId, isLoading)),
      ]),
    );
  }

  Widget _schoolSidebarTile(BuildContext context, School school,
      bool isFocused, bool isLoading) {
    return InkWell(
      onTap: isLoading
          ? null
          : () {
              setState(() => _focusedSchoolId = school.id);
              context.read<SettingsCubit>().loadForSuperAdmin(school.id);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isFocused ? _accent.withOpacity(0.08) : Colors.transparent,
          border: Border(
            left: BorderSide(
                color: isFocused ? _accent : Colors.transparent, width: 3),
          ),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(Icons.school_outlined,
              size: 16,
              color: isFocused ? _accent : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(school.name,
                      style: TextStyle(
                        fontWeight: isFocused
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13.5,
                        color: isFocused ? _accent : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (!school.isActive)
                    const Text('Inactive',
                        style:
                            TextStyle(fontSize: 11, color: Colors.red)),
                ]),
          ),
        ]),
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _showApproveDialog(BuildContext context, PendingAdmin pending,
      SettingsLoaded data) {
    AdminRole selectedRole = AdminRole.admin;
    String? selectedSchoolId =
        widget.currentAdmin.isSuperAdmin ? null : widget.currentAdmin.schoolId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Approve ${pending.name}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // User info summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: _accent.withOpacity(0.1),
                    backgroundImage: pending.photoUrl != null
                        ? NetworkImage(pending.photoUrl!)
                        : null,
                    child: pending.photoUrl == null
                        ? Text(
                            pending.name.isNotEmpty
                                ? pending.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: _accent),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pending.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        Text(pending.email,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
                      ]),
                ]),
              ),
              const SizedBox(height: 16),
              // Role picker
              if (widget.currentAdmin.isSuperAdmin)
                DropdownButtonFormField<AdminRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                      labelText: 'Role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: AdminRole.admin, child: Text('Admin')),
                    DropdownMenuItem(
                        value: AdminRole.superAdmin,
                        child: Text('Super Admin')),
                  ],
                  onChanged: (r) =>
                      setDialogState(() => selectedRole = r!),
                ),
              if (widget.currentAdmin.isSuperAdmin)
                const SizedBox(height: 12),
              // School picker (super admin picks; regular admin auto-assigns to own school)
              if (widget.currentAdmin.isSuperAdmin)
                DropdownButtonFormField<String>(
                  value: selectedSchoolId,
                  decoration: const InputDecoration(
                      labelText: 'Assign to school',
                      border: OutlineInputBorder()),
                  items: data.allSchools
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedSchoolId = v),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.school_outlined, size: 16, color: _accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Will be added to: ${data.school.name}',
                        style: TextStyle(fontSize: 13, color: _accent),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: selectedSchoolId == null
                  ? null
                  : () {
                      context.read<SettingsCubit>().approvePendingAdmin(
                            pending: pending,
                            role: selectedRole,
                            schoolId: selectedSchoolId!,
                          );
                      Navigator.pop(ctx);
                    },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(backgroundColor: _accent),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReject(BuildContext context, PendingAdmin pending) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request',
            style: TextStyle(fontWeight: FontWeight.w700)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
            'Reject ${pending.name}\'s access request? They will remain locked out until they sign in again and someone approves them.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context
                  .read<SettingsCubit>()
                  .rejectPendingAdmin(pending);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showEditSchoolDialog(BuildContext context, School school) {
    final nameCtrl = TextEditingController(text: school.name);
    final addressCtrl = TextEditingController(text: school.address);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit School Info',
            style: TextStyle(fontWeight: FontWeight.w700)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'School name', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                  labelText: 'Address', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              context.read<SettingsCubit>().updateSchoolInfo(school.id,
                  name: nameCtrl.text.trim(),
                  address: addressCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateSchoolDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New School',
            style: TextStyle(fontWeight: FontWeight.w700)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'School name', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              context.read<SettingsCubit>().createSchool(
                  nameCtrl.text.trim(), addressCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAssignSchoolDialog(
      BuildContext context, Admin admin, List<School> schools) {
    String? selectedSchoolId = admin.schoolId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign ${admin.name} to School',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: 380,
            child: DropdownButtonFormField<String>(
              value: selectedSchoolId,
              decoration: const InputDecoration(
                  labelText: 'School', border: OutlineInputBorder()),
              items: schools
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name,
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setDialogState(() => selectedSchoolId = v),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: selectedSchoolId == null
                  ? null
                  : () {
                      context
                          .read<SettingsCubit>()
                          .assignAdminToSchool(admin.id, selectedSchoolId!);
                      Navigator.pop(ctx);
                    },
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveAdmin(BuildContext context, Admin admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Admin',
            style: TextStyle(fontWeight: FontWeight.w700)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
            'Remove ${admin.name} (${admin.email})? They will lose access immediately.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<SettingsCubit>().removeAdmin(admin.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  SettingsLoaded? _extractLoaded(SettingsState state) {
    if (state is SettingsLoaded) return state;
    if (state is SettingsActionSuccess) return state.previousData;
    if (state is SettingsActionError) return state.previousData;
    return null;
  }

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title,
      {Widget? action, Color? iconColor, int? badge}) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: (iconColor ?? _accent).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? _accent),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15.5)),
      if (badge != null && badge > 0) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: _warning, borderRadius: BorderRadius.circular(20)),
          child: Text('$badge',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
        ),
      ],
      if (action != null) ...[const Spacer(), action],
    ]);
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 90,
        child: Text(label,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13.5,
                fontWeight: FontWeight.w500)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87)),
      ),
    ]);
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: fg,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _loadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.5),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}