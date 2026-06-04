// lib/presentation/pages/report_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/submit_report_cubit.dart';
import '../bloc/submit_report_state.dart';
import '../../domain/use_cases/submit_report_use_case.dart';
import '../../school_config.dart';

// ---------------------------------------------------------------------------
// Category helpers
// ---------------------------------------------------------------------------

const _categories = [
  _Category('bullying',   'Bullying',   Icons.person_off_outlined),
  _Category('harassment', 'Harassment', Icons.warning_amber_outlined),
  _Category('safety',     'Safety',     Icons.health_and_safety_outlined),
  _Category('other',      'Other',      Icons.help_outline),
];

class _Category {
  final String value;
  final String label;
  final IconData icon;
  const _Category(this.value, this.label, this.icon);
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // Controllers
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bullyNameController   = TextEditingController();

  // Form state
  String? _selectedCategory;
  final List<String> _bullyNames = [];

  late final SubmitReportCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SubmitReportCubit(GetIt.I<SubmitReportUseCase>());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bullyNameController.dispose();
    super.dispose();
  }

  // ── Derived helpers ──────────────────────────────────────────────────────

  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _selectedCategory != null;

  void _addBullyName() {
    final name = _bullyNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _bullyNames.add(name);
      _bullyNameController.clear();
    });
  }

  void _removeBullyName(int index) {
    setState(() => _bullyNames.removeAt(index));
  }

  void _submit() {
    _cubit.submitReport(
      schoolId: SchoolConfig.schoolId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      bullyNames: List.unmodifiable(_bullyNames),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _bullyNameController.clear();
    setState(() {
      _selectedCategory = null;
      _bullyNames.clear();
    });
    _cubit.reset();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const brandColor = Colors.indigo;

    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        appBar: AppBar(
          backgroundColor: brandColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            '${SchoolConfig.schoolName} — Report',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: BlocConsumer<SubmitReportCubit, SubmitReportState>(
                listener: (context, state) {
                  if (state.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.reportId != null && state.reportId!.isNotEmpty
                              ? '✅ Report submitted — ID: ${state.reportId}'
                              : '✅ Report submitted successfully',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ ${state.error}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  // After a successful submission, show the confirmation view.
                  if (state.success) {
                    return _SuccessCard(
                      reportId: state.reportId,
                      onAnother: _resetForm,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── HERO CARD ────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo.shade700,
                              Colors.indigo,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Safe & Anonymous Reporting',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Your report is fully anonymous. No personal information is collected or stored.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── FORM CARD ────────────────────────────────────────
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Category
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                items: _categories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.value,
                                        child: Row(
                                          children: [
                                            Icon(c.icon,
                                                size: 18,
                                                color: Colors.indigo),
                                            const SizedBox(width: 8),
                                            Text(c.label),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: state.loading
                                    ? null
                                    : (val) => setState(
                                        () => _selectedCategory = val),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.category_outlined),
                                  labelText: 'Incident Type',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Title
                              TextField(
                                controller: _titleController,
                                enabled: !state.loading,
                                onChanged: (_) => setState(() {}),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  prefixIcon:
                                      const Icon(Icons.title_outlined),
                                  labelText: 'Brief Title',
                                  hintText: 'e.g. Pushed in corridor',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Description
                              TextField(
                                controller: _descriptionController,
                                enabled: !state.loading,
                                onChanged: (_) => setState(() {}),
                                maxLines: 4,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(bottom: 56),
                                    child: Icon(Icons.description_outlined),
                                  ),
                                  labelText: 'What happened?',
                                  hintText:
                                      'Describe the incident — when, where, and what occurred.',
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Bully names (optional)
                              _BullyNamesField(
                                controller: _bullyNameController,
                                names: _bullyNames,
                                enabled: !state.loading,
                                onAdd: _addBullyName,
                                onRemove: _removeBullyName,
                              ),

                              const SizedBox(height: 28),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFormValid && !state.loading
                                        ? Colors.indigo
                                        : Colors.grey[300],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isFormValid && !state.loading
                                      ? _submit
                                      : null,
                                  child: state.loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Submit Report',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bully names sub-widget
// ---------------------------------------------------------------------------

class _BullyNamesField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> names;
  final bool enabled;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _BullyNamesField({
    required this.controller,
    required this.names,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_search_outlined),
                  labelText: 'Person(s) involved (optional)',
                  hintText: 'Add a name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),

        // Name chips
        if (names.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: names
                .asMap()
                .entries
                .map(
                  (e) => Chip(
                    label: Text(e.value),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: enabled ? () => onRemove(e.key) : null,
                    backgroundColor: Colors.indigo.shade50,
                    side: BorderSide(color: Colors.indigo.shade200),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Success card — shown after a successful submission
// ---------------------------------------------------------------------------

class _SuccessCard extends StatelessWidget {
  final String? reportId;
  final VoidCallback onAnother;

  const _SuccessCard({required this.reportId, required this.onAnother});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you. Your report has been received and will be reviewed by staff.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (reportId != null && reportId!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Reference: $reportId',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAnother,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit Another Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
