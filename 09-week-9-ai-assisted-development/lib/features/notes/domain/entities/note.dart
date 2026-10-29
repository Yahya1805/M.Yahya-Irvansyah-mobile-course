class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    this.createdAt,
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime updatedAt;
  final bool dirty;
}
