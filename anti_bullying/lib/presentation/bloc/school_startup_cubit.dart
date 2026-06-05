import 'package:flutter_bloc/flutter_bloc.dart';
import 'school_startup_state.dart';
import '../../../domain/use_cases/get_school_config_use_case.dart';
import '../../../school_config.dart';

class SchoolStartupCubit extends Cubit<SchoolStartupState> {
  final GetSchoolConfigUseCase _getSchoolConfigUseCase;

  SchoolStartupCubit(this._getSchoolConfigUseCase)
      : super(const SchoolStartupLoading());

  Future<void> validateSchool() async {
    emit(const SchoolStartupLoading());
    try {
      final config = await _getSchoolConfigUseCase.execute(SchoolConfig.schoolId);

      if (!config.active) {
        emit(const SchoolStartupError(
          'This school is not currently active.\nPlease contact your administrator.',
        ));
        return;
      }

      emit(SchoolStartupReady(config.schoolName));
    } catch (e) {
      emit(SchoolStartupError(
        'Could not connect to the reporting service.\n\n'
        'Check your internet connection and try again.\n\n'
        'Detail: ${e.toString()}',
      ));
    }
  }
}
