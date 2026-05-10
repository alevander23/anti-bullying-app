import 'package:flutter/material.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';

class FilterBar extends StatefulWidget {
  final ReportStatus? activeStatus;
  final ReportPriority? activePriority;
  final bool? activeFlagged;
  final bool hasActiveFilters;
  final ValueChanged<ReportStatus?> onStatusChanged;
  final ValueChanged<ReportPriority?> onPriorityChanged;
  final ValueChanged<bool?> onFlaggedChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;

  const FilterBar({
    super.key,
    this.activeStatus,
    this.activePriority,
    this.activeFlagged,
    required this.hasActiveFilters,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onFlaggedChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search reports...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filter:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),

                // Status chips
                ...ReportStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(_statusLabel(s)),
                        selected: widget.activeStatus == s,
                        onSelected: (_) => widget.onStatusChanged(
                            widget.activeStatus == s ? null : s),
                        selectedColor:
                            _statusColor(s).withOpacity(0.2),
                      ),
                    )),

                const SizedBox(width: 8),
                // High priority chip
                FilterChip(
                  label: const Text('High Priority'),
                  selected: widget.activePriority == ReportPriority.high,
                  avatar: const Icon(Icons.priority_high, size: 16),
                  onSelected: (_) => widget.onPriorityChanged(
                      widget.activePriority == ReportPriority.high
                          ? null
                          : ReportPriority.high),
                  selectedColor: Colors.red.withOpacity(0.2),
                ),
                const SizedBox(width: 6),

                // Flagged chip
                FilterChip(
                  label: const Text('Flagged'),
                  selected: widget.activeFlagged == true,
                  avatar: const Icon(Icons.flag, size: 16),
                  onSelected: (_) => widget.onFlaggedChanged(
                      widget.activeFlagged == true ? null : true),
                  selectedColor: Colors.orange.withOpacity(0.2),
                ),

                if (widget.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      widget.onClearFilters();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ReportStatus s) => switch (s) {
    ReportStatus.newReport  => 'New',
    ReportStatus.reviewed   => 'Reviewed',
    ReportStatus.escalated  => 'Escalated',
    ReportStatus.resolved   => 'Resolved',
  };

  Color _statusColor(ReportStatus s) => switch (s) {
    ReportStatus.newReport  => Colors.blue,
    ReportStatus.reviewed   => Colors.purple,
    ReportStatus.escalated  => Colors.orange,
    ReportStatus.resolved   => Colors.green,
  };
}
