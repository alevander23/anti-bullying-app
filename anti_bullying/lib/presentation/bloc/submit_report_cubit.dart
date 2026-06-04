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
    String? deviceIdentifier,
  }) async {
    emit(state.copyWith(loading: true, error: null, success: false));
    try {
      final reportId = await _submitUseCase.execute(
        schoolId: schoolId,
        title: title,
        description: description,
        category: category,
        bullyNames: bullyNames,
        deviceIdentifier: deviceIdentifier,
      );
      emit(state.copyWith(loading: false, success: true, reportId: reportId));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void reset() => emit(SubmitReportState.initial());
}
