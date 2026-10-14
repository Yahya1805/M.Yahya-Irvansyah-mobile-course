sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;
}

class LocalFailure extends Failure {
  const LocalFailure(super.message);
}
