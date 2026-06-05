import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'data/data_sources/report_remote_data_source.dart';
import 'data/repository_implementations/report_repository_impl.dart';
import 'domain/repository_contracts/report_repository.dart';
import 'domain/use_cases/submit_report_use_case.dart';
import 'domain/use_cases/get_school_config_use_case.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  getIt.registerSingleton<FirebaseFirestore>(
    FirebaseFirestore.instance,
  );

  getIt.registerSingleton<ReportRemoteDataSource>(
    ReportRemoteDataSourceImpl(getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<ReportRepository>(
    ReportRepositoryImpl(getIt<ReportRemoteDataSource>()),
  );

  getIt.registerSingleton<SubmitReportUseCase>(
    SubmitReportUseCase(getIt<ReportRepository>()),
  );

  getIt.registerSingleton<GetSchoolConfigUseCase>(
    GetSchoolConfigUseCase(getIt<ReportRepository>()),
  );
}
