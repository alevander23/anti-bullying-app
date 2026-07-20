// base class for all the failure types we throw around the app
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

// thrown when submitting a report fails for whatever reason
class SubmitReportFailure extends Failure {
  const SubmitReportFailure(super.message);
}

// generic connectivity issue, has a sensible default message
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

// catch all for anything we didn't expect
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred']);
}
