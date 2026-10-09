import 'package:equatable/equatable.dart';

/// Domain-level failures. The presentation layer maps these to friendly,
/// non-judgmental copy — never raw error strings.
sealed class Failure extends Equatable {
  const Failure([this.message = '']);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Content is not cached yet and the device is offline.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message]);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

final class AudioFailure extends Failure {
  const AudioFailure([super.message]);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message]);
}
