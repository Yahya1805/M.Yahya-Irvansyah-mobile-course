String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String? parseRoute(String? location) {
  if (location == null || location.isEmpty) return null;

  final uri = Uri.tryParse(location);
  if (uri == null) return null;

  return uri.path.isEmpty ? '/' : uri.path;
}
