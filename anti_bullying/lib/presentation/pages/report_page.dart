// lib/presentation/pages/report_page.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/submit_report_cubit.dart';
import '../bloc/submit_report_state.dart';
import '../../domain/use_cases/submit_report_use_case.dart';
import '../../school_config.dart';


const _allowedMimePrefixes = ['image/', 'video/'];
const _allowedExtensions = {
  'jpg', 'jpeg', 'png', 'webp', 'gif', // images
  'mp4', 'mov', 'webm',                 // videos
};

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

class _Palette {
  // Brand — sky blue (#278acb)
  static const primary       = Color(0xFF278ACB);
  static const primaryLight  = Color(0xFF55AAE0);
  static const primaryDark   = Color(0xFF186EA8);

  // Page background — warm off-white with the faintest blue tint
  static const pageBg        = Color(0xFFE6F2FF);

  // Card surface
  static const cardBg        = Color(0xFFFFFFFF);

  // Section header bg inside card
  static const sectionBg     = Color(0xFFF0F8FF);

  // Field border (idle)
  static const fieldBorder   = Color(0xFFCCE4F5);
  // Field border (focus)
  static const fieldFocus    = Color(0xFF278ACB);

  // Accent chip bg
  static const chipBg        = Color(0xFFDCEEFA);
  static const chipBorder    = Color(0xFF9ACFE8);

  // Subtle divider
  static const divider       = Color(0xFFDCEEFA);

  // Success green
  static const success       = Color(0xFF22A06B);
  static const successBg     = Color(0xFFE6F6EF);
}

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
// Shared decoration helpers
// ---------------------------------------------------------------------------

bool _isVideoFile(XFile file) {
  final mimeType = lookupMimeType(file.name) ?? lookupMimeType(file.path);
  if (mimeType != null) return mimeType.startsWith('video/');

  // Fallback: check the extension directly
  final ext = file.name.split('.').last.toLowerCase();
  return {'mp4', 'mov', 'webm'}.contains(ext);
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  String? hint,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: alignLabelWithHint,
    labelStyle: const TextStyle(
      color: Color(0xFF555555),
      fontSize: 14,
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF99C5DD),
      fontSize: 14,
    ),
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF7BBAD8)),
    filled: true,
    fillColor: const Color(0xFFF8FBFE),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _Palette.fieldBorder, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: const Color(0xFF278ACB), width: 1.8),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDCEEFA), width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.8),
    ),
  );
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
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bullyNameController   = TextEditingController();

  String? _selectedCategory;
  final List<String> _bullyNames = [];
  final List<XFile> _mediaFiles = [];

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

  bool get _isFormValid =>
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

  void _removeBullyName(int index) =>
      setState(() => _bullyNames.removeAt(index));

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose photo from gallery'),
              onTap: () async {
                Navigator.pop(context);
                final files = await picker.pickMultiImage(imageQuality: 85);
                _addValidatedFiles(files);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickImage(
                  source: ImageSource.camera, imageQuality: 85);
                if (file != null) _addValidatedFiles([file]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Choose video from gallery'),
              onTap: () async {
                Navigator.pop(context);
                final file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 7));
                if (file != null) _addValidatedFiles([file]);
              },
            ),
          ],
        ),
      ),
    );
  }

  // central place that filters and reports rejected files
  void _addValidatedFiles(List<XFile> files) {
    final valid = <XFile>[];
    var rejectedCount = 0;

    for (final f in files) {
      if (_isValidMediaFile(f)) {
        valid.add(f);
      } else {
        rejectedCount++;
      }
    }

    if (valid.isNotEmpty) {
      setState(() => _mediaFiles.addAll(valid));
    }

    if (rejectedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rejectedCount == 1
                ? 'One file was not a supported photo or video and was skipped.'
                : '$rejectedCount files were not supported photos or videos and were skipped.',
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submit() {
    _addBullyName();
    _cubit.submitReport(
      schoolId: SchoolConfig.schoolId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      bullyNames: List.unmodifiable(_bullyNames),
      mediaFiles: List.unmodifiable(_mediaFiles),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _bullyNameController.clear();
    setState(() {
      _selectedCategory = null;
      _bullyNames.clear();
      _mediaFiles.clear();
    });
    _cubit.reset();
  }

  bool _isValidMediaFile(XFile file) {
  final mimeType = lookupMimeType(file.path) ?? lookupMimeType(file.name);
  final ext = file.name.split('.').last.toLowerCase();

  final mimeOk = mimeType != null &&
      _allowedMimePrefixes.any((p) => mimeType.startsWith(p));
  final extOk = _allowedExtensions.contains(ext);

  return mimeOk && extOk;
}

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        // Warm tinted background instead of plain white
        backgroundColor: _Palette.pageBg,
        appBar: _buildAppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: BlocConsumer<SubmitReportCubit, SubmitReportState>(
                listener: _onStateChange,
                builder: (context, state) {
                  if (state.success) {
                    return _SuccessCard(
                      reportId: state.reportId,
                      onAnother: _resetForm,
                    );
                  }
                  return _buildForm(state);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: _Palette.primary,
          // Subtle bottom border instead of harsh elevation shadow
          border: Border(
            bottom: BorderSide(color: Color(0x22000000), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  SchoolConfig.schoolName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(SubmitReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── HERO BANNER ──────────────────────────────────────────────────
        _AnonymousBanner(),

        const SizedBox(height: 20),

        // ── FORM CARD ────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _Palette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCE4F5), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF278ACB).withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card header strip
              _CardHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── INCIDENT TYPE ─────────────────────────────────
                    _SectionLabel('Incident type'),
                    const SizedBox(height: 8),
                    _CategorySelector(
                      selected: _selectedCategory,
                      enabled: !state.loading,
                      onSelected: (val) =>
                          setState(() => _selectedCategory = val),
                    ),

                    const SizedBox(height: 20),
                    const _Divider(),
                    const SizedBox(height: 20),

                    // ── TITLE ─────────────────────────────────────────
                    Text(
                      'Brief title',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      enabled: !state.loading,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15),
                      decoration: _fieldDecoration(
                        label: 'e.g. Pushed in the corridor',
                        icon: Icons.title_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── DESCRIPTION ───────────────────────────────────
                    _SectionLabel('What happened?'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      enabled: !state.loading,
                      onChanged: (_) => setState(() {}),
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15),
                      decoration: _fieldDecoration(
                        label: 'Describe the incident — when, where, what occurred',
                        icon: Icons.description_outlined,
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const _Divider(),
                    const SizedBox(height: 20),

                    // ── INVOLVED PERSONS ──────────────────────────────
                    _BullyNamesField(
                      controller: _bullyNameController,
                      names: _bullyNames,
                      enabled: !state.loading,
                      onAdd: _addBullyName,
                      onRemove: _removeBullyName,
                    ),

                    const SizedBox(height: 20),
                    const _Divider(),
                    const SizedBox(height: 20),

                    // ── MEDIA ATTACHMENTS ─────────────────────────────
                    _MediaPickerField(
                      files: _mediaFiles,
                      enabled: !state.loading,
                      onPickMedia: _pickMedia,
                      onRemove: (i) => setState(() => _mediaFiles.removeAt(i)),
                    ),

                    const SizedBox(height: 28),

// ── SUBMIT BUTTON ─────────────────────────────────
                    _SubmitButton(
                      isValid: _isFormValid,
                      isLoading: state.loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Footer note
        const _FooterNote(),
      ],
    );
  }

  void _onStateChange(BuildContext context, SubmitReportState state) {
    if (state.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.reportId != null && state.reportId!.isNotEmpty
                ? '✅ Report submitted — ID: ${state.reportId}'
                : '✅ Report submitted successfully',
          ),
          backgroundColor: _Palette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${state.error}'),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Anonymous banner
// ---------------------------------------------------------------------------

class _AnonymousBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9ACFE8), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF278ACB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_outlined,
              color: _Palette.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safe & anonymous reporting',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF186EA8),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No personal information is collected or stored.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF186EA8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card header strip
// ---------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _Palette.sectionBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: _Palette.divider, width: 1),
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.edit_note_outlined, size: 18, color: _Palette.primaryLight),
          SizedBox(width: 8),
          Text(
            'Incident report',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              letterSpacing: -0.1,
            ),
          ),
          Spacer(),
          Text(
            'Required fields marked *',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7BBAD8),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$text *',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
        letterSpacing: 0.1,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Divider
// ---------------------------------------------------------------------------

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: _Palette.divider,
      thickness: 1,
      height: 1,
    );
  }
}

// ---------------------------------------------------------------------------
// Category selector — pill toggle group
// ---------------------------------------------------------------------------

class _CategorySelector extends StatelessWidget {
  final String? selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  const _CategorySelector({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = selected == cat.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: enabled ? () => onSelected(cat.value) : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _Palette.primary
                    : const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? _Palette.primaryDark
                      : _Palette.fieldBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF7BBAD8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Submit button
// ---------------------------------------------------------------------------

class _SubmitButton extends StatelessWidget {
  final bool isValid;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isValid,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = isValid && !isLoading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: canSubmit ? 1.0 : 0.55,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: canSubmit
              ? const LinearGradient(
                  colors: [Color(0xFF278ACB), Color(0xFF186EA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canSubmit ? null : const Color(0xFFD1D5DB),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: const Color(0xFF278ACB).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: canSubmit ? onPressed : null,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_outlined, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Submit report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer note
// ---------------------------------------------------------------------------

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.info_outline, size: 14, color: Color(0xFF99C5DD)),
        SizedBox(width: 5),
        Text(
          'Reports are reviewed by staff during school hours.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF99C5DD),
          ),
        ),
      ],
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
        const Text(
          'Bullies Names',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Optional — add names if you know them',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF7BBAD8),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 15),
                decoration: _fieldDecoration(
                  label: 'Add a name',
                  icon: Icons.person_search_outlined,
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              width: 50,
              child: Material(
                color: enabled ? _Palette.primary : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: enabled ? onAdd : null,
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),

        if (names.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: names
                .asMap()
                .entries
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _Palette.chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: _Palette.chipBorder, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF278ACB),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: enabled ? () => onRemove(e.key) : null,
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF55AAE0),
                          ),
                        ),
                      ],
                    ),
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
// Media picker sub-widget
// ---------------------------------------------------------------------------

class _MediaPickerField extends StatelessWidget {
  final List<XFile> files;
  final bool enabled;
  final VoidCallback onPickMedia;
  final void Function(int) onRemove;

  const _MediaPickerField({
    required this.files,
    required this.enabled,
    required this.onPickMedia,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach photos or videos',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Optional — add evidence if you have it',
          style: TextStyle(fontSize: 12, color: Color(0xFF7BBAD8)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: enabled ? onPickMedia : null,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: const Text('Add photo or video'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _Palette.fieldBorder, width: 1.2),
            foregroundColor: _Palette.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (files.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isVideo = _isVideoFile(files[i]);
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isVideo
                          ? Container(
                              width: 80, height: 80,
                              color: Colors.black12,
                              child: const Icon(Icons.play_circle_outline,
                                  color: _Palette.primary, size: 32),
                            )
                          : _ImageThumb(file: files[i]), // ← CHANGED: delegate to platform-safe widget
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: enabled ? () => onRemove(i) : null,
                        child: const CircleAvatar(
                          radius: 10, backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final XFile file;
  const _ImageThumb({required this.file});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, XFile.path is a blob URL where Image.network handles it fine
      return Image.network(file.path, width: 80, height: 80, fit: BoxFit.cover);
    }
    // On Android/iOS, use a real File from dart:io
    return Image.file(File(file.path), width: 80, height: 80, fit: BoxFit.cover);
  }
}

// ---------------------------------------------------------------------------
// Success card
// ---------------------------------------------------------------------------

class _SuccessCard extends StatelessWidget {
  final String? reportId;
  final VoidCallback onAnother;

  const _SuccessCard({required this.reportId, required this.onAnother});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCE4F5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF278ACB).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _Palette.successBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFA8E6CE),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.check_outlined,
                color: _Palette.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Report submitted',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you. Your report has been received and will be reviewed by staff.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
                height: 1.5,
              ),
            ),
            if (reportId != null && reportId!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFCCE4F5), width: 1),
                ),
                child: Center(
                  child: SelectionArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Reference number',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7BBAD8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reportId!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF278ACB),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8), // Clean spacing between the text and icon
                            IconButton(
                              icon: const Icon(Icons.copy, color: Color(0xFF278ACB), size: 18),
                              padding: EdgeInsets.zero, // Shrinks the button's clickable padding box
                              constraints: const BoxConstraints(), // Removes default minimum sizing
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: reportId!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reference number copied to clipboard!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onAnother,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _Palette.fieldBorder, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: const Color(0xFF374151),
                ),
                child: const Text(
                  'Submit another report',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}