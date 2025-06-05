import 'package:dartz/dartz.dart';
import '../error/failures.dart';

typedef Result<T> = Either<Failure, T>;

/// Base repository interface for common operations
abstract class BaseRepository {
  /// Generic method for handling exceptions and converting to Result
  Future<Result<T>> safeCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  /// Handle exceptions and convert to appropriate Failure
  Failure _handleException(Object exception) {
    return ServerFailure(message: exception.toString());
  }
}
