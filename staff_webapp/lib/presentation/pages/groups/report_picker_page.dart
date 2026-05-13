// lib/presentation/pages/groups/report_picker_page.dart

import 'package:flutter/material.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';

class ReportPickerPage extends StatefulWidget {
  final List<Report> allReports;
  final List<String> selectedIds;

  const ReportPickerPage({
    super.key,
    required this.allReports,
    required this.selectedIds,
  });

  @override
  State<ReportPickerPage> createState() => _ReportPickerPageState();
}

class _ReportPickerPageState extends State<ReportPickerPage> {
  late Set<String> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
  }

  List<Report> get _filtered {
    if (_search.isEmpty) return widget.allReports;
    final q = _search.toLowerCase();
    return widget.allReports.where((r) =>
        r.title.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Link reports', style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: () => Navigator.pop(context, _selected.toList()),
              icon: const Icon(Icons.check, size: 18),
              label: Text('Done (${_selected.length} selected)'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search reports…',
                prefixIcon: const Icon(Icons.search, size: 18),
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              'Select reports to add as evidence to this group. A report can belong to multiple groups.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final r = _filtered[i];
                final selected = _selected.contains(r.id);
                return _PickerRow(
                  report: r,
                  selected: selected,
                  onToggle: () => setState(() {
                    if (selected) {
                      _selected.remove(r.id);
                    } else {
                      _selected.add(r.id);
                    }
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final Report report;
  final bool selected;
  final VoidCallback onToggle;

  const _PickerRow({
    required this.report,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEEDFE) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF534AB7).withOpacity(0.4) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF534AB7) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? const Color(0xFF534AB7) : Colors.grey.shade400,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(_categoryLabel(report.category),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                      _StatusPill(status: report.status),
                      Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                      Text(_timeAgo(report.submittedAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 14) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'just now';
  }
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
    return Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500));
  }
}
