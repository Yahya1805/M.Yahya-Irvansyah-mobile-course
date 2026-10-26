import 'package:flutter/material.dart';

import 'core/format.dart';
import 'features/notes/presentation/pages/notes_page.dart';

const notesRoute = '/notes';

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  if (parseRoute(settings.name) != notesRoute) return null;

  return MaterialPageRoute<void>(
    settings: settings,
    builder: (context) => const NotesPage(),
  );
}
