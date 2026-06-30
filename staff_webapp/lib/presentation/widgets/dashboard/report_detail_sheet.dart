import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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
    // Initialize state based on the report data passed from the parent
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
            // Handle for dragging the sheet
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

            // Header row with report title and flag toggle
            Row(
              children: [
                Expanded(
                  child: Text(report.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                // Flag toggle button for marking report as flagged
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

            // Display metadata as chips (category, priority, etc)
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

            // Report description section
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(report.description,
                style: const TextStyle(height: 1.5, fontSize: 15)),
            const SizedBox(height: 24),

            if (report.mediaUrls.isNotEmpty) ...[
              const Text('Attached Media',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.mediaUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _MediaThumb(url: report.mediaUrls[i]),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Status selection for updating report status
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

            // Internal notes input field
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

            // Save changes button
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
    final adminName = widget.admin.name;

    // Update status if changed
    if (_selectedStatus != widget.report.status) {
      cubit.updateStatus(widget.report.id, _selectedStatus, adminUid, adminName);
    }
    // Update notes if changed
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

// ---------------------------------------------------------------------------
// Media thumbnail which fetches the file with the staff member's auth token
// since the server only serves /uploads to verified admins
// ---------------------------------------------------------------------------

class _MediaThumb extends StatelessWidget {
  final String url;
  const _MediaThumb({required this.url});

  bool get _isVideo => url.contains('/videos/');

  Future<Uint8List> _fetchProtectedFile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final token = await user.getIdToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Failed to load media (${response.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _MediaViewerDialog(url: url, isVideo: _isVideo),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isVideo
            ? Container(
                width: 100,
                height: 100,
                color: Colors.black12,
                child: const Icon(Icons.play_circle_outline,
                    size: 36, color: Colors.blueGrey),
              )
            : FutureBuilder<Uint8List>(
                future: _fetchProtectedFile(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  }
                  if (snapshot.hasError) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.red.shade50,
                      child: const Icon(Icons.error_outline,
                          color: Colors.red, size: 24),
                    );
                  }
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.black12,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen viewer dialog which is opened when a thumbnail is tapped
// ---------------------------------------------------------------------------

class _MediaViewerDialog extends StatelessWidget {
  final String url;
  final bool isVideo;
  const _MediaViewerDialog({required this.url, required this.isVideo});

  Future<Uint8List> _fetchProtectedFile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final token = await user.getIdToken();
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Failed to load media (${response.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: isVideo
                ? _VideoNotSupportedNotice(url: url)
                : FutureBuilder<Uint8List>(
                    future: _fetchProtectedFile(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return InteractiveViewer(
                          child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Failed to load image',
                              style: TextStyle(color: Colors.white)),
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// This is just a placeholder for playback yk. Don't forget to implement this before the testing rounds begin MAX
class _VideoNotSupportedNotice extends StatelessWidget {
  final String url;
  const _VideoNotSupportedNotice({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_outlined, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Video preview not yet supported in-app.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            url,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}