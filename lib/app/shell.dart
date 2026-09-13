
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/right_panel.dart';
import '../widgets/top_bar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = ['/chat','/image','/video','/settings'];
  static const _labels = ['对话','画图','视频','设置'];

  int _indexFor(String loc){
    for(int i=0;i<_tabs.length;i++){
      if(loc.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _indexFor(loc);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1024;
    final isTablet = w >= 600 && w < 1024;
    final isMobile = w < 600;

    if(isMobile){
      return Scaffold(
        appBar: const TopBar(),
        drawer: const Drawer(child: AppSidebar()),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i)=> context.go(_tabs[i]),
          height: 64,
          backgroundColor: const Color(0xFF1A2230),
          indicatorColor: const Color(0xFF10B981).withOpacity(0.15),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: '对话'),
            NavigationDestination(icon: Icon(Icons.image_outlined), selectedIcon: Icon(Icons.image), label: '画图'),
            NavigationDestination(icon: Icon(Icons.videocam_outlined), selectedIcon: Icon(Icons.videocam), label: '视频'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
          ],
        ),
      );
    }

    if(isTablet){
      return Scaffold(
        appBar: const TopBar(),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: idx,
              onDestinationSelected: (i)=> context.go(_tabs[i]),
              backgroundColor: const Color(0xFF1A2230),
              indicatorColor: const Color(0xFF10B981).withOpacity(0.15),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: Text('对话')),
                NavigationRailDestination(icon: Icon(Icons.image_outlined), selectedIcon: Icon(Icons.image), label: Text('画图')),
                NavigationRailDestination(icon: Icon(Icons.videocam_outlined), selectedIcon: Icon(Icons.videocam), label: Text('视频')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('设置')),
              ],
            ),
            const VerticalDivider(width:1, color: Color(0xFF2E3B52)),
            Expanded(child: child),
          ],
        ),
      );
    }

    // desktop: 3 columns
    return Scaffold(
      body: Column(
        children: [
          const TopBar(),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 280, child: AppSidebar()),
                const VerticalDivider(width:1, color: Color(0xFF2E3B52)),
                Expanded(child: child),
                const VerticalDivider(width:1, color: Color(0xFF2E3B52)),
                SizedBox(width: 340, child: RightPanel(currentIndex: idx)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
