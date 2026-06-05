// lib/presentation/pages/groups/create_edit_group_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/group/group_cubit.dart';
import 'package:staff_webapp/presentation/bloc/group/group_state.dart';
import 'report_picker_page.dart';

class CreateEditGroupPage extends StatefulWidget {
  final Admin admin;
  final List<Report> allReports;
  final IncidentGroup? existing; // null = create mode

  const CreateEditGroupPage({
    super.key,
    required this.admin,
    required this.allReports,
    this.existing,
  });

  @override
  State<CreateEditGroupPage> createState() => _CreateEditGroupPageState();
}

class _CreateEditGroupPageState extends State<CreateEditGroupPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  final _personNameController = TextEditingController();
  final _tagController = TextEditingController();

  GroupStatus _status = GroupStatus.open;
  GroupPriority _priority = GroupPriority.normal;
  String _personRole = 'Student';
  List<PersonInvolved> _people = [];
  List<String> _linkedReportIds = [];
  List<String> _tags = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _descController.text = e.description;
      _notesController.text = e.notes;
      _status = e.status;
      _priority = e.priority;
      _people = List.from(e.peopleInvolved);
      _linkedReportIds = List.from(e.connectedReportIds);
      _tags = List.from(e.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _personNameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupCubit, GroupState>(
      listener: (context, state) {
        if (state is GroupActionSuccess) {
          Navigator.pop(context);
        }
        if (state is GroupActionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit group' : 'New group',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 18),
                label: Text(_isEdit ? 'Save changes' : 'Save group'),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildMainColumn()),
                    const SizedBox(width: 16),
                    SizedBox(width: 300, child: _buildSideColumn()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildMainColumn(),
                  const SizedBox(height: 16),
                  _buildSideColumn(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainColumn() {
    return Column(
      children: [
        _FormCard(
          title: 'Details',
          child: Column(
            children: [
              _LabeledField(
                label: 'Title',
                child: TextField(
                  controller: _titleController,
                  decoration: _inputDec('Give this group a clear name…'),
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Description',
                child: TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: _inputDec('Summarise what this group of incidents is about…'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Status',
                      child: DropdownButtonFormField<GroupStatus>(
                        value: _status,
                        decoration: _inputDec(null),
                        items: GroupStatus.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_statusLabel(s)),
                        )).toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Priority',
                      child: DropdownButtonFormField<GroupPriority>(
                        value: _priority,
                        decoration: _inputDec(null),
                        items: GroupPriority.values.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p == GroupPriority.high ? 'High' : 'Normal'),
                        )).toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _FormCard(
          title: 'Notes',
          child: TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: _inputDec('Free-text notes — evidence details, context, next steps…'),
          ),
        ),
        const SizedBox(height: 14),
        _FormCard(
          title: 'People involved',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_people.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _people.map((p) => _PersonTag(
                    person: p,
                    onRemove: () => setState(() => _people.remove(p)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _personNameController,
                      decoration: _inputDec('Name…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _personRole,
                      decoration: _inputDec(null),
                      items: ['Student', 'Staff', 'Other'].map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      )).toList(),
                      onChanged: (v) => setState(() => _personRole = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _addPerson,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideColumn() {
    final linked = widget.allReports
        .where((r) => _linkedReportIds.contains(r.id))
        .toList();

    return Column(
      children: [
        _FormCard(
          title: 'Linked reports',
          child: Column(
            children: [
              ...linked.map((r) => _ReportRefTile(
                report: r,
                onRemove: () => setState(() => _linkedReportIds.remove(r.id)),
              )),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openReportPicker(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Link a report'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _FormCard(
          title: 'Tags',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags.map((t) => _TagChip(
                    tag: t,
                    onRemove: () => setState(() => _tags.remove(t)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _tagController,
                decoration: _inputDec('Add a tag and press Enter…'),
                onSubmitted: (v) {
                  final tag = v.trim();
                  if (tag.isNotEmpty && !_tags.contains(tag)) {
                    setState(() => _tags.add(tag));
                  }
                  _tagController.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addPerson() {
    final name = _personNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _people.add(PersonInvolved(name: name, role: _personRole));
      _personNameController.clear();
    });
  }

  Future<void> _openReportPicker(BuildContext context) async {
    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPickerPage(
          allReports: widget.allReports,
          selectedIds: List.from(_linkedReportIds),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _linkedReportIds = selected);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a title'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final cubit = context.read<GroupCubit>();

    if (_isEdit) {
      cubit.updateGroup(
        groupId: widget.existing!.id,
        original: widget.existing!,
        title: title,
        description: _descController.text.trim(),
        notes: _notesController.text.trim(),
        status: _status,
        priority: _priority,
        peopleInvolved: _people,
        connectedReportIds: _linkedReportIds,
        tags: _tags,
        adminName: widget.admin.name,
      );
    } else {
      cubit.createGroup(IncidentGroup(
        id: '',
        schoolId: widget.admin.schoolId ?? '',
        title: title,
        description: _descController.text.trim(),
        notes: _notesController.text.trim(),
        status: _status,
        priority: _priority,
        peopleInvolved: _people,
        connectedReportIds: _linkedReportIds,
        tags: _tags,
        createdBy: widget.admin.name,
        createdById: widget.admin.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  String _statusLabel(GroupStatus s) => switch (s) {
    GroupStatus.open        => 'Open',
    GroupStatus.underReview => 'Under review',
    GroupStatus.closed      => 'Closed',
  };

  InputDecoration _inputDec(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.black54),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _FormCard({required this.title, required this.child});

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
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _PersonTag extends StatelessWidget {
  final PersonInvolved person;
  final VoidCallback onRemove;
  const _PersonTag({required this.person, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final initials = person.name.split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFFEEEDFE),
            child: Text(initials, style: const TextStyle(fontSize: 8, color: Color(0xFF534AB7), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Text(person.name, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text('· ${person.role}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ReportRefTile extends StatelessWidget {
  final Report report;
  final VoidCallback onRemove;
  const _ReportRefTile({required this.report, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
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
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
          ),
        ],
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

class _TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;
  const _TagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEDFE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tag, style: const TextStyle(fontSize: 12, color: Color(0xFF534AB7))),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 13, color: Color(0xFF534AB7)),
        ),
      ],
    ),
  );
}
