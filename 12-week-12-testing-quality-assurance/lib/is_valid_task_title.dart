/// Memeriksa validitas judul tugas atau catatan.
/// Judul harus berisi teks setelah spasi di awal dan akhir diabaikan (trimmed).
bool isValidTaskTitle(String value) {
  return value.trim().isNotEmpty;
}

