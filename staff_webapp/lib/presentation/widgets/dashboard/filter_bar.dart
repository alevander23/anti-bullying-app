import 'package:flutter/material.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/report/report_state.dart';

class FilterBar extends StatefulWidget {
  final Set<ReportStatus> activeStatusFilters;
  final ReportPriority? activePriority;
  final bool? activeFlagged;
  final bool hasActiveFilters;
  final ReportSortField sortField;
  final bool sortAscending;
  final ValueChanged<ReportStatus> onStatusToggled;
  final ValueChanged<ReportPriority?> onPriorityChanged;
  final ValueChanged<bool?> onFlaggedChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<ReportSortField> onSortFieldChanged;
  final ValueChanged<bool> onSortDirectionChanged;

  const FilterBar({
    super.key,
    required this.activeStatusFilters,
    this.activePriority,
    this.activeFlagged,
    required this.hasActiveFilters,
    required this.sortField,
    required this.sortAscending,
    required this.onStatusToggled,
    required this.onPriorityChanged,
    required this.onFlaggedChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
    required this.onSortFieldChanged,
    required this.onSortDirectionChanged,
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

                // Status chips — multi-select, persist until toggled off
                ...ReportStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(_statusLabel(s)),
                        selected: widget.activeStatusFilters.contains(s),
                        onSelected: (_) => widget.onStatusToggled(s),
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
          const SizedBox(height: 10),
          // Sort controls row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Sort by:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                _SortFieldButton(
                  label: 'Recent Changes',
                  icon: Icons.update,
                  isActive: widget.sortField == ReportSortField.updatedAt,
                  onTap: () =>
                      widget.onSortFieldChanged(ReportSortField.updatedAt),
                ),
                const SizedBox(width: 6),
                _SortFieldButton(
                  label: 'Initial Date',
                  icon: Icons.calendar_today,
                  isActive: widget.sortField == ReportSortField.submittedAt,
                  onTap: () =>
                      widget.onSortFieldChanged(ReportSortField.submittedAt),
                ),
                const SizedBox(width: 12),
                // Ascending / descending toggle
                _SortDirectionButton(
                  ascending: widget.sortAscending,
                  onToggle: widget.onSortDirectionChanged,
                ),
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

// ── Sort helpers ─────────────────────────────────────────────────────────────

class _SortFieldButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SortFieldButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Theme.of(context).primaryColor : Colors.grey;
    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor.withOpacity(0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDirectionButton extends StatelessWidget {
  final bool ascending;
  final ValueChanged<bool> onToggle;

  const _SortDirectionButton({
    required this.ascending,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: ascending ? 'Oldest first' : 'Newest first',
      child: InkWell(
        onTap: () => onToggle(!ascending),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                ascending ? 'Oldest first' : 'Newest first',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
