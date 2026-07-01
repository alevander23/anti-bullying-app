import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import 'package:staff_webapp/di.dart';
import 'package:staff_webapp/domain/entities/admin_entity.dart';
import 'package:staff_webapp/domain/entities/report_entity.dart';
import 'package:staff_webapp/presentation/bloc/media/media_cubit.dart';
import 'package:staff_webapp/presentation/bloc/media/media_state.dart';
import 'package:staff_webapp/presentation/bloc/report/report_cubit.dart';

// dart:html is web-only; guarded behind kIsWeb at every call site below.
import 'dart:html' as html show AnchorElement;

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

            // Attached media section (photos/videos submitted with report).
            // MediaCubit is scoped to this sheet via BlocProvider below so
            // every thumbnail and the full-screen dialog share one cache.
            if (report.mediaUrls.isNotEmpty) ...[
              const Text('Attached Media',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              BlocProvider<MediaCubit>(
                create: (_) => getIt<MediaCubit>(),
                child: SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.mediaUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) =>
                        _MediaThumb(url: report.mediaUrls[i]),
                  ),
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
// Media thumbnail. Triggers MediaCubit.fetchMedia and renders whatever
// state comes back via BlocBuilder. No direct Firebase/HTTP calls here.
// ---------------------------------------------------------------------------

class _MediaThumb extends StatefulWidget {
  final String url;
  const _MediaThumb({required this.url});

  @override
  State<_MediaThumb> createState() => _MediaThumbState();
}

class _MediaThumbState extends State<_MediaThumb> {
  bool get _isVideo => widget.url.contains('/videos/');

  @override
  void initState() {
    super.initState();
    context.read<MediaCubit>().fetchMedia(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<MediaCubit>(),
          child: _MediaViewerDialog(url: widget.url, isVideo: _isVideo),
        ),
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
            : BlocBuilder<MediaCubit, MediaState>(
                buildWhen: (prev, curr) =>
                    prev.statusFor(widget.url) != curr.statusFor(widget.url),
                builder: (context, state) {
                  final item = state.statusFor(widget.url);

                  if (item?.status == MediaFetchStatus.loaded) {
                    return Image.memory(
                      item!.bytes!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  }
                  if (item?.status == MediaFetchStatus.error) {
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
// Full-screen viewer dialog, opened when a thumbnail is tapped.
// ---------------------------------------------------------------------------

class _MediaViewerDialog extends StatelessWidget {
  final String url;
  final bool isVideo;
  const _MediaViewerDialog({required this.url, required this.isVideo});

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
                : BlocBuilder<MediaCubit, MediaState>(
                    buildWhen: (prev, curr) =>
                        prev.statusFor(url) != curr.statusFor(url),
                    builder: (context, state) {
                      final item = state.statusFor(url);

                      if (item?.status == MediaFetchStatus.loaded) {
                        return InteractiveViewer(
                          child: Image.memory(item!.bytes!, fit: BoxFit.contain),
                        );
                      }
                      if (item?.status == MediaFetchStatus.error) {
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

// ---------------------------------------------------------------------------
// Video player. Fetches bytes via MediaCubit (not directly), then hands
// video_player a data: URI since it can't attach auth headers reliably
// across platforms.
// ---------------------------------------------------------------------------

class _VideoPlayerView extends StatefulWidget {
  final String url;
  const _VideoPlayerView({required this.url});

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  VideoPlayerController? _controller;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    context.read<MediaCubit>().fetchMedia(widget.url);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _mimeTypeFor(String url) {
    if (url.endsWith('.mov')) return 'video/quicktime';
    if (url.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }

  String _extensionFor(String url) {
    if (url.endsWith('.mov')) return 'mov';
    if (url.endsWith('.webm')) return 'webm';
    return 'mp4';
  }

  Future<void> _initPlayer(Uint8List bytes) async {
    if (_initializing || _controller != null) return;
    _initializing = true;

    final base64Data = base64Encode(bytes);
    final dataUri = 'data:${_mimeTypeFor(widget.url)};base64,$base64Data';

    final controller = VideoPlayerController.networkUrl(Uri.parse(dataUri));
    await controller.initialize();

    if (!mounted) return;
    setState(() => _controller = controller);
    controller.play();
  }

  void _downloadBytes(Uint8List bytes) {
    if (!kIsWeb) return;
    final mimeType = _mimeTypeFor(widget.url);
    final ext = _extensionFor(widget.url);
    final base64Data = base64Encode(bytes);
    final dataUri = 'data:$mimeType;base64,$base64Data';

    final anchor = html.AnchorElement(href: dataUri)
      ..setAttribute('download', 'report_video.$ext')
      ..click();
    anchor.remove();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCubit, MediaState>(
      buildWhen: (prev, curr) =>
          prev.statusFor(widget.url) != curr.statusFor(widget.url),
      builder: (context, state) {
        final item = state.statusFor(widget.url);

        if (item?.status == MediaFetchStatus.error) {
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
                  item?.errorMessage ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.read<MediaCubit>().retry(widget.url),
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
              ],
            ),
          );
        }

        if (item?.status != MediaFetchStatus.loaded) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final bytes = item!.bytes!;
        // ignore: discarded_futures
        _initPlayer(bytes);

        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          return Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                _DownloadButton(onPressed: () => _downloadBytes(bytes)),
              ],
            ),
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
            _DownloadButton(onPressed: () => _downloadBytes(bytes)),
          ],
        );
      },
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DownloadButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.download, color: Colors.white, size: 18),
      label: const Text('Download video'),
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