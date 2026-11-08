import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/format.dart';
import 'core/providers.dart';
import 'features/notes/presentation/pages/notes_page.dart';
import 'features/chat_screen.dart';
import 'features/multimodal_ai_screen.dart';

const notesRoute = '/notes';
const aiChatRoute = '/ai-chat';
const aiMultimodalRoute = '/ai-multimodal';

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
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          return ChatScreen(aiService: ref.watch(aiServiceProvider));
        },
      ),
    );
  }
  if (route == aiMultimodalRoute) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          return MultimodalAiScreen(aiService: ref.watch(aiServiceProvider));
        },
      ),
    );
  }
  return null;
}
