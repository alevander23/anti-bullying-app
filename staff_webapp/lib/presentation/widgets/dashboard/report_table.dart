import 'package:flutter/material.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';

class ReportTable extends StatelessWidget {
  final List<Report> reports;
  final bool hasMore;
  final ValueChanged<Report> onReportTap;
  final VoidCallback onLoadMore;

  const ReportTable({
    super.key,
    required this.reports,
    required this.hasMore,
    required this.onReportTap,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No reports found',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade50,
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('REPORT', style: _headerStyle)),
                  Expanded(flex: 1, child: Text('CATEGORY', style: _headerStyle)),
                  Expanded(flex: 1, child: Text('STATUS', style: _headerStyle)),
                  Expanded(flex: 1, child: Text('DATE', style: _headerStyle)),
                  SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1),
            // Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) =>
                  _ReportRow(report: reports[i], onTap: onReportTap),
            ),
            // Load more trigger row
            if (hasMore)
              _LoadMoreRow(onLoadMore: onLoadMore),
          ],
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
    letterSpacing: 0.5,
  );
}

class _ReportRow extends StatelessWidget {
  final Report report;
  final ValueChanged<Report> onTap;

  const _ReportRow({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(report),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Title + flag indicator
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (report.isFlagged)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.flag, color: Colors.red, size: 16),
                    ),
                  if (report.priority == ReportPriority.high)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.priority_high,
                          color: Colors.orange, size: 16),
                    ),
                  Expanded(
                    child: Text(
                      report.title,
                      style: TextStyle(
                        fontWeight: report.isNew
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Category
            Expanded(
              flex: 1,
              child: Text(
                _categoryLabel(report.category),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            // Status badge
            Expanded(
              flex: 1,
              child: _StatusBadge(status: report.status),
            ),
            // Date
            Expanded(
              flex: 1,
              child: Text(
                _formatDate(report.submittedAt),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            // Arrow
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

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _LoadMoreRow extends StatefulWidget {
  final VoidCallback onLoadMore;
  const _LoadMoreRow({required this.onLoadMore});

  @override
  State<_LoadMoreRow> createState() => _LoadMoreRowState();
}

class _LoadMoreRowState extends State<_LoadMoreRow> {
  @override
  void initState() {
    super.initState();
    // Trigger load automatically when this widget becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoadMore());
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReportStatus.newReport  => ('New',       Colors.blue),
      ReportStatus.reviewed   => ('Reviewed',  Colors.purple),
      ReportStatus.escalated  => ('Escalated', Colors.orange),
      ReportStatus.resolved   => ('Resolved',  Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
