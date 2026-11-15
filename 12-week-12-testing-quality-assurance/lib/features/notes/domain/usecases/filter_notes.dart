import '../entities/note.dart';

/// Memfilter daftar [notes] berdasarkan [query] pada judul (case-insensitive).
List<Note> filterNotes(List<Note> notes, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return notes;
  return notes
      .where((note) => note.title.toLowerCase().contains(trimmed))
      .toList();
}
