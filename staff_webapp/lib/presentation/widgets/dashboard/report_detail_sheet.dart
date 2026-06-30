import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show AnchorElement;
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
                ? _VideoPlayerView(url: url)
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

class _VideoPlayerView extends StatefulWidget {
  final String url;
  const _VideoPlayerView({required this.url});

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  VideoPlayerController? _controller;
  String? _error;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse(widget.url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load video (${response.statusCode})');
      }

      // video_player needs a source it can stream — a data URI works
      // across platforms (web + desktop) without needing a temp file.
      final base64Data = base64Encode(response.bodyBytes);
      final mimeType = widget.url.endsWith('.mov')
          ? 'video/quicktime'
          : widget.url.endsWith('.webm')
              ? 'video/webm'
              : 'video/mp4';
      final dataUri = 'data:$mimeType;base64,$base64Data';

      final controller = VideoPlayerController.networkUrl(Uri.parse(dataUri));
      await controller.initialize();

      if (!mounted) return;
      setState(() => _controller = controller);
      controller.play();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _downloadFallback() async {
    setState(() => _downloading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse(widget.url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final mimeType = widget.url.endsWith('.mov')
          ? 'video/quicktime'
          : widget.url.endsWith('.webm')
              ? 'video/webm'
              : 'video/mp4';
      final ext = widget.url.endsWith('.mov')
          ? 'mov'
          : widget.url.endsWith('.webm')
              ? 'webm'
              : 'mp4';
      final base64Data = base64Encode(response.bodyBytes);
      final dataUri = 'data:$mimeType;base64,$base64Data';

      if (kIsWeb) {
        final anchor = html.AnchorElement(href: dataUri)
          ..setAttribute('download', 'report_video.$ext')
          ..click();
        anchor.remove();
      } else {
        final launched = await launchUrl(
          Uri.parse(dataUri),
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the video')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            const Text('Failed to load video',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _DownloadButton(
              downloading: _downloading,
              onPressed: _downloadFallback,
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              children: [
                Positioned.fill(child: VideoPlayer(controller)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _VideoControls(controller: controller),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _DownloadButton(
          downloading: _downloading,
          onPressed: _downloadFallback,
        ),
      ],
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final bool downloading;
  final VoidCallback onPressed;

  const _DownloadButton({required this.downloading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: downloading ? null : onPressed,
      icon: downloading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.download, color: Colors.white, size: 18),
      label: Text(downloading ? 'Preparing...' : 'Download video'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black54,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                value.isPlaying
                    ? widget.controller.pause()
                    : widget.controller.play();
              });
            },
          ),
          Expanded(
            child: Slider(
              value: value.position.inMilliseconds
                  .clamp(0, value.duration.inMilliseconds)
                  .toDouble(),
              max: value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              onChanged: (v) {
                widget.controller.seekTo(Duration(milliseconds: v.toInt()));
              },
            ),
          ),
        ],
      ),
    );
  }
}