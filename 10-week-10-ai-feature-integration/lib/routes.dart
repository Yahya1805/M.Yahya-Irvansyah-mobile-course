import 'package:flutter/material.dart';

import 'core/format.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/chat_screen.dart';

const notesRoute = '/notes';
const aiChatRoute = '/ai-chat';

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final route = parseRoute(settings.name);
  if (route == notesRoute) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => const NotesPage(),
    );
  }
  if (route == aiChatRoute) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => const ChatScreen(),
    );
  }
  return null;
}
