abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class SubmitReportFailure extends Failure {
  const SubmitReportFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred']);
}
