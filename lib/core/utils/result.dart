sealed class Result<T, E extends Exception> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get valueOrNull => this is Success<T, E> ? (this as Success<T, E>).data : null;
  E? get errorOrNull => this is Failure<T, E> ? (this as Failure<T, E>).exception : null;

  T get value => (this as Success<T, E>).data;
  E get error => (this as Failure<T, E>).exception;

  W when<W>({
    required W Function(T data) onSuccess,
    required W Function(E exception) onFailure,
  }) {
    if (this is Success<T, E>) {
      return onSuccess((this as Success<T, E>).data);
    } else {
      return onFailure((this as Failure<T, E>).exception);
    }
  }
}

class Success<T, E extends Exception> extends Result<T, E> {
  final T data;
  const Success(this.data);
}

class Failure<T, E extends Exception> extends Result<T, E> {
  final E exception;
  const Failure(this.exception);
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  @override
  String toString() => message;
}
