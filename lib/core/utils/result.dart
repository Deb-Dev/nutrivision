import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Type alias for common result pattern
typedef Result<T> = Either<Failure, T>;

/// Type alias for future result pattern
typedef FutureResult<T> = Future<Result<T>>;

/// Extension methods for Result handling
extension ResultX<T> on Result<T> {
  /// Returns true if the result is a success (Right)
  bool get isSuccess => isRight();

  /// Returns true if the result is a failure (Left)
  bool get isFailure => isLeft();

  /// Gets the success value or null if failure
  T? get successValue => fold((l) => null, (r) => r);

  /// Gets the failure value or null if success
  Failure? get failureValue => fold((l) => l, (r) => null);

  /// Handles both success and failure cases with when syntax
  R when<R>({
    required R Function(T) success,
    required R Function(Failure) failure,
  }) {
    return fold(failure, success);
  }
}

/// Extension methods for FutureResult handling
extension FutureResultX<T> on FutureResult<T> {
  /// Maps the success value
  FutureResult<R> mapSuccess<R>(R Function(T) mapper) async {
    final result = await this;
    return result.fold(
      (failure) => Left(failure),
      (success) => Right(mapper(success)),
    );
  }

  /// Maps the failure value
  FutureResult<T> mapFailure(Failure Function(Failure) mapper) async {
    final result = await this;
    return result.fold(
      (failure) => Left(mapper(failure)),
      (success) => Right(success),
    );
  }

  /// Handles both success and failure cases
  Future<R> handle<R>({
    required R Function(Failure) onFailure,
    required R Function(T) onSuccess,
  }) async {
    final result = await this;
    return result.fold(onFailure, onSuccess);
  }
}
