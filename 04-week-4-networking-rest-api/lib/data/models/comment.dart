class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: _readInt(json['postId']),
      id: _readInt(json['id']),
      name: _readString(json['name']),
      email: _readString(json['email']),
      body: _readString(json['body']),
    );
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(Object? value) => value?.toString() ?? '';
}