/// Kegagalan pada lapisan jaringan/cache postingan.
class PostsFailure implements Exception {
  const PostsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
