import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'data/data_sources/report_remote_data_source.dart';
import 'data/repository_implementations/report_repository_impl.dart';
import 'domain/repository_contracts/report_repository.dart';
import 'domain/use_cases/submit_report_use_case.dart';
import 'domain/use_cases/get_school_config_use_case.dart';

final getIt = GetIt.instance;

// wires up the whole dependency chain, call once at app startup before runApp
Future<void> setupDependencies() async {
  getIt.registerSingleton<FirebaseFirestore>(
    FirebaseFirestore.instance,
  );

  // data source needs firestore, so it goes right after
  getIt.registerSingleton<ReportRemoteDataSource>(
    ReportRemoteDataSourceImpl(getIt<FirebaseFirestore>()),
  );

  // repository wraps the data source behind the domain contract
  getIt.registerSingleton<ReportRepository>(
    ReportRepositoryImpl(getIt<ReportRemoteDataSource>()),
  );

  // use cases sit on top of the repository, this is what the UI actually calls
  getIt.registerSingleton<SubmitReportUseCase>(
    SubmitReportUseCase(getIt<ReportRepository>()),
  );

  getIt.registerSingleton<GetSchoolConfigUseCase>(
    GetSchoolConfigUseCase(getIt<ReportRepository>()),
  );
}
