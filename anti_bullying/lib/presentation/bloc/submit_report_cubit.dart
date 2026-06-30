import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'submit_report_state.dart';
import '../../../domain/use_cases/submit_report_use_case.dart';

class SubmitReportCubit extends Cubit<SubmitReportState> {
  final SubmitReportUseCase _submitUseCase;

  SubmitReportCubit(this._submitUseCase) : super(SubmitReportState.initial());

  Future<void> submitReport({
    required String schoolId,
    required String title,
    required String description,
    required String category,
    required List<String> bullyNames,
    required List<XFile> mediaFiles,
    String? deviceIdentifier,
  }) async {
    emit(state.copyWith(loading: true, error: null, success: false));
    try {
      // Phase 1: upload files to server, get back URLs
      final mediaUrls = mediaFiles.isNotEmpty
          ? await _submitUseCase.uploadMedia(mediaFiles)
          : <String>[];

      // Phase 2: write the Firestore document with embedded URLs
      final reportId = await _submitUseCase.execute(
        schoolId: schoolId,
        title: title,
        description: description,
        category: category,
        bullyNames: bullyNames,
        mediaUrls: mediaUrls,
        deviceIdentifier: deviceIdentifier,
      );
      emit(state.copyWith(loading: false, success: true, reportId: reportId));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void reset() => emit(SubmitReportState.initial());
}