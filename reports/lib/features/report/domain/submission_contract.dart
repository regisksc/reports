import 'report.dart';

abstract interface class SubmissionClient {
  Future<SubmissionResult> send(Report report);
}

sealed class SubmissionResult {}

final class SubmissionAccepted extends SubmissionResult {
  SubmissionAccepted(this.serviceRequestNumber);
  final String serviceRequestNumber;
}

final class SubmissionFailed extends SubmissionResult {
  SubmissionFailed(this.kind, this.message);
  final SubmissionFailureKind kind;
  final String message;
}

enum SubmissionFailureKind { rejected, network, sessionExpired, uncertain }

