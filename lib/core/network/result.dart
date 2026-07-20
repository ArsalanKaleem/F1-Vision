import '../errors/failures.dart';

/// A minimal sealed result type so repositories can return either data or a
/// [Failure] without throwing across layer boundaries. (A fuller project might
/// reach for `dartz`/`fpdart`; this keeps the dependency surface small.)
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>() => success(self.data),
      Err<T>() => failure(self.failure),
    };
  }

  /// Returns the data or `null` — convenient for optional UI states.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Err<T>() => null,
      };
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
