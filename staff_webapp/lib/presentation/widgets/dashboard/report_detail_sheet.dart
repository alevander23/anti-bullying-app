import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';

class ReportDetailSheet extends StatefulWidget {
  final Report report;
  final Admin admin;

  const ReportDetailSheet({
    super.key,
    required this.report,
    required this.admin,
  });

  @override
  State<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<ReportDetailSheet> {
  final _notesController = TextEditingController();
  late ReportStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _notesController.text = widget.report.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(report.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                // Flag toggle
                IconButton(
                  icon: Icon(
                    report.isFlagged ? Icons.flag : Icons.flag_outlined,
                    color: report.isFlagged ? Colors.red : Colors.grey,
                  ),
                  tooltip: report.isFlagged ? 'Remove flag' : 'Flag report',
                  onPressed: () {
                    context
                        .read<ReportCubit>()
                        .toggleFlag(report.id, report.isFlagged);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Meta chips
            Wrap(
              spacing: 8,
              children: [
                _Chip(
                    label: _categoryLabel(report.category),
                    color: Colors.blue),
                _Chip(
                    label: report.priority == ReportPriority.high
                        ? 'High Priority'
                        : 'Normal Priority',
                    color: report.priority == ReportPriority.high
                        ? Colors.orange
                        : Colors.grey),
                _Chip(
                    label: 'Submitted ${_formatDate(report.submittedAt)}',
                    color: Colors.grey),
                if (report.resolvedBy != null)
                  _Chip(
                      label: 'Resolved by ${report.resolvedBy}',
                      color: Colors.green),
                if (report.closedAt != null)
                  _Chip(
                      label: 'Closed ${_formatDate(report.closedAt!)}',
                      color: Colors.teal),
                if (report.deviceIdentifier != null)
                  _Chip(
                      label: 'Device: ${report.deviceIdentifier}',
                      color: Colors.indigo),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Description
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(report.description,
                style: const TextStyle(height: 1.5, fontSize: 15)),
            const SizedBox(height: 24),

            // Status selector
            const Text('Update Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<ReportStatus>(
              segments: ReportStatus.values
                  .map((s) => ButtonSegment(
                        value: s,
                        label: Text(_statusLabel(s), style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
              selected: {_selectedStatus},
              onSelectionChanged: (s) =>
                  setState(() => _selectedStatus = s.first),
            ),
            const SizedBox(height: 20),

            // Notes
            const Text('Internal Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add internal notes (not visible to students)...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final cubit = context.read<ReportCubit>();
    final adminUid = widget.admin.id;

    if (_selectedStatus != widget.report.status) {
      cubit.updateStatus(widget.report.id, _selectedStatus, adminUid);
    }
    if (_notesController.text != (widget.report.notes ?? '')) {
      cubit.addNotes(widget.report.id, _notesController.text, adminUid);
    }
    Navigator.pop(context);
  }

  String _statusLabel(ReportStatus s) => switch (s) {
    ReportStatus.newReport  => 'New',
    ReportStatus.reviewed   => 'Reviewed',
    ReportStatus.escalated  => 'Escalated',
    ReportStatus.resolved   => 'Resolved',
  };

  String _categoryLabel(ReportCategory c) => switch (c) {
    ReportCategory.bullying   => 'Bullying',
    ReportCategory.harassment => 'Harassment',
    ReportCategory.safety     => 'Safety',
    ReportCategory.other      => 'Other',
  };

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
