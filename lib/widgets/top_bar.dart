import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';

class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopBar({super.key});
  @override Size get preferredSize => const Size.fromHeight(48);

  static const _tabs = ['对话','画图','视频','设置'];
  static const _paths = ['/chat','/image','/video','/settings'];
  static const _icons = [Icons.chat_bubble_outline, Icons.image_outlined, Icons.videocam_outlined, Icons.settings_outlined];
  static const _iconsActive = [Icons.chat_bubble, Icons.image, Icons.videocam, Icons.settings];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.toString();
    int idx=0;
    if(loc.startsWith('/image')) idx=1;
    else if(loc.startsWith('/video')) idx=2;
    else if(loc.startsWith('/settings')) idx=3;
    final configs = ref.watch(providerConfigsProvider);
    final activeId = ref.watch(activeProviderIdProvider);
    final active = configs.where((c)=>c.id==activeId).firstOrNull ?? (configs.isNotEmpty? configs.first: null);
    final hasProvider = active!=null && active.baseUrl.isNotEmpty && active.apiKey.isNotEmpty;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF141C2B),
        border: Border(bottom: BorderSide(color: Color(0xFF2E3B52))),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile? 8: 12),
      child: Row(
        children: [
          if(w >= 1024)
            const Row(children: [
              CircleAvatar(radius: 5.5, backgroundColor: Color(0xFFFF5F56)),
              SizedBox(width:6),
              CircleAvatar(radius: 5.5, backgroundColor: Color(0xFFFFBD2E)),
              SizedBox(width:6),
              CircleAvatar(radius: 5.5, backgroundColor: Color(0xFF27C93F)),
              SizedBox(width:12),
            ]),
          Row(children: [
            Container(width:28,height:28,decoration:BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.bolt, size:16, color: Color(0xFF111827))),
            const SizedBox(width:8),
            const Text('Universal AI Client', style: TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:13, color: Color(0xFFF1F5F9))),
          ]),
          const SizedBox(width:12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (i){
                  final isActive = i==idx;
                  final icon = isActive? _iconsActive[i]: _icons[i];
                  final label = _tabs[i];
                  // mobile: icon-only 48x32; desktop: icon+text min 88
                  if(isMobile){
                    return Padding(
                      padding: const EdgeInsets.only(right:4),
                      child: Tooltip(
                        message: label,
                        child: InkWell(
                          onTap: ()=> context.go(_paths[i]),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44, height: 32,
                            decoration: BoxDecoration(
                              color: isActive? const Color(0xFFF1F5F9): Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isActive? const Color(0xFFF1F5F9): Colors.transparent),
                            ),
                            child: Icon(icon, size:18, color: isActive? const Color(0xFF111827): const Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right:6),
                    child: InkWell(
                      onTap: ()=> context.go(_paths[i]),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 88),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal:12),
                        decoration: BoxDecoration(
                          color: isActive? const Color(0xFFF1F5F9): Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isActive? const Color(0xFFF1F5F9): Colors.transparent),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(icon, size:16, color: isActive? const Color(0xFF111827): const Color(0xFF94A3B8)),
                          const SizedBox(width:6),
                          Text(label, style: TextStyle(fontSize:13, fontWeight: FontWeight.w600, color: isActive? const Color(0xFF111827): const Color(0xFF94A3B8))),
                        ]),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width:8),
          if(!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
              decoration: BoxDecoration(
                color: hasProvider? const Color(0xFF10B981).withValues(alpha:0.12): const Color(0xFFF59E0B).withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: hasProvider? const Color(0xFF10B981).withValues(alpha:0.4): const Color(0xFFF59E0B).withValues(alpha:0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(hasProvider? Icons.check_circle: Icons.warning_amber_rounded, size:12, color: hasProvider? const Color(0xFF10B981): const Color(0xFFF59E0B)),
                const SizedBox(width:4),
                Text(hasProvider? active.name: '未配置', maxLines:1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: hasProvider? const Color(0xFF10B981): const Color(0xFFF59E0B))),
              ]),
            )
          else
            Tooltip(
              message: hasProvider? active!.name: '未配置 Provider',
              child: Container(width:32,height:32,decoration: BoxDecoration(color: hasProvider? const Color(0xFF10B981).withValues(alpha:0.14): const Color(0xFFF59E0B).withValues(alpha:0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: hasProvider? const Color(0xFF10B981).withValues(alpha:0.4): const Color(0xFFF59E0B).withValues(alpha:0.4))), child: Icon(hasProvider? Icons.check_circle: Icons.warning_amber_rounded, size:16, color: hasProvider? const Color(0xFF10B981): const Color(0xFFF59E0B))),
            ),
          const SizedBox(width:6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal:8, vertical:6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFF2E3B52)), color: const Color(0x0AFFFFFF)),
            child: const Text('v0.1', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }
}
extension _FO<E> on Iterable<E>{ E? get firstOrNull => isEmpty? null: first; }
