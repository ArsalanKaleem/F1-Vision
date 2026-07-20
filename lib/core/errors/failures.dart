/// Low-level errors thrown inside the data layer.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'The request timed out.']);
}

class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});
  final int? statusCode;
}

class RateLimitException extends AppException {
  const RateLimitException([super.message = 'Rate limit reached. Slow down.']);
}

class ParseException extends AppException {
  const ParseException([super.message = 'Could not parse the response.']);
}

/// User-facing failures surfaced to the presentation layer. Repositories
/// translate [AppException]s into these so the UI never sees raw plumbing.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Check your connection and try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong upstream.']);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'Too many requests — try shortly.']);
}

/// Sign-in / registration problems with a user-friendly message
/// (wrong password, e-mail already in use, cancelled Google flow, …).
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

/// Maps an exception to its user-facing failure counterpart.
Failure mapExceptionToFailure(Object error) => switch (error) {
      NetworkException() => const NetworkFailure(),
      TimeoutException() => const NetworkFailure('The request timed out.'),
      RateLimitException() => const RateLimitFailure(),
      ServerException(:final message) => ServerFailure(message),
      ParseException(:final message) => ServerFailure(message),
      _ => const UnknownFailure(),
    };
