
import 'package:go_router/go_router.dart';
import '../features/chat/chat_page.dart';
import '../features/image/image_page.dart';
import '../features/video/video_page.dart';
import '../features/settings/settings_page.dart';
import 'shell.dart';

final appRouter = GoRouter(
  initialLocation: '/chat',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/chat', builder: (c,s)=> const ChatPage()),
        GoRoute(path: '/image', builder: (c,s)=> const ImagePage()),
        GoRoute(path: '/video', builder: (c,s)=> const VideoPage()),
        GoRoute(path: '/settings', builder: (c,s)=> const SettingsPage()),
      ],
    ),
  ],
);
