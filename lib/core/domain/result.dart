import 'package:meta/meta.dart';

/// Base Result type - represents either success (Ok) or failure (Failure)
sealed class Result<T, E> {
  const Result();

  /// Returns true if this is an Ok result
  bool get isSuccess => this is Ok<T, E>;

  /// Returns true if this is a Failure result
  bool get isFailure => this is Failure<T, E>;

  /// Get the value if Ok, null if Failure
  T? get value => this is Ok<T, E> ? (this as Ok<T, E>).value : null;

  /// Get the error if Failure, null if Ok
  E? get error => this is Failure<T, E> ? (this as Failure<T, E>).error : null;

  /// Transform the success value
  Result<U, E> map<U>(U Function(T) converter) {
    if (this is Ok<T, E>) {
      return Ok<U, E>(converter((this as Ok<T, E>).value));
    }
    return (this as Failure<T, E>) as Result<U, E>;
  }

  /// Chain operations that return Result
  Result<U, E> flatMap<U>(Result<U, E> Function(T) converter) {
    if (this is Ok<T, E>) {
      return converter((this as Ok<T, E>).value);
    }
    return (this as Failure<T, E>) as Result<U, E>;
  }

  /// Transform the error value
  Result<T, F> mapError<F>(F Function(E) converter) {
    if (this is Failure<T, E>) {
      return Failure<T, F>(converter((this as Failure<T, E>).error));
    }
    return (this as Ok<T, E>) as Result<T, F>;
  }

  /// Handle both cases and return a value
  R fold<R>(R Function(T) onSuccess, R Function(E) onFailure) {
    if (this is Ok<T, E>) {
      return onSuccess((this as Ok<T, E>).value);
    }
    return onFailure((this as Failure<T, E>).error);
  }

  /// Execute side effects based on result type
  Result<T, E> onTap(
    void Function(T) onSuccess, [
    void Function(E)? onFailure,
  ]) {
    if (this is Ok<T, E>) {
      onSuccess((this as Ok<T, E>).value);
    } else if (onFailure != null) {
      onFailure((this as Failure<T, E>).error);
    }
    // we would test the usage like this for now
    // ignore: avoid_returning_this
    return this;
  }

  /// Get value or throw exception if Failure
  T getOrThrow() {
    if (this is Ok<T, E>) {
      return (this as Ok<T, E>).value;
    }
    throw ResultException((this as Failure<T, E>).error);
  }

  /// Get value or default if Failure
  T getOrElse(T Function(E) defaultValue) {
    if (this is Ok<T, E>) {
      return (this as Ok<T, E>).value;
    }
    return defaultValue((this as Failure<T, E>).error);
  }

  /// Convert to nullable value (null if Failure)
  T? toNullable() => value;

  /// Create Ok result
  static Result<T, E> ok<T, E>(T value) => Ok<T, E>(value);

  /// Create Failure result
  static Result<T, E> failure<T, E>(E error) => Failure<T, E>(error);
}

/// Success case
@immutable
class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  @override
  final T value;

  @override
  String toString() => 'Ok($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ok<T, E> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failure case
@immutable
class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  @override
  final E error;

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Exception thrown by getOrThrow()
class ResultException implements Exception {
  const ResultException(this.error);
  final Object? error;

  @override
  String toString() => 'ResultException: $error';
}
