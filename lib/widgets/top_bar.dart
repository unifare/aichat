
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';

class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopBar({super.key});
  @override Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).uri.toString();
    int idx=0;
    if(loc.startsWith('/image')) idx=1;
    else if(loc.startsWith('/video')) idx=2;
    else if(loc.startsWith('/settings')) idx=3;
    final tabs = ['对话','画图','视频','设置'];
    final paths = ['/chat','/image','/video','/settings'];
    final configs = ref.watch(providerConfigsProvider);
    final activeId = ref.watch(activeProviderIdProvider);
    final active = configs.where((c)=>c.id==activeId).firstOrNull ?? (configs.isNotEmpty? configs.first: null);
    final hasProvider = active!=null && active.baseUrl.isNotEmpty && active.apiKey.isNotEmpty;
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF141C2B),
        border: Border(bottom: BorderSide(color: Color(0xFF2E3B52))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if(MediaQuery.of(context).size.width>=1024)
            Row(children: const [
              CircleAvatar(radius: 5.5, backgroundColor: Color(0xFFFF5F56)),
              SizedBox(width:6),
              CircleAvatar(radius: 5.5, backgroundColor: Color(0xFFFFBD2E)),
              SizedBox(width:6),
              CircleAvatar(radius: 5.5, backgroundColor: Color(0xFF27C93F)),
              SizedBox(width:12),
            ]),
          const Text('Universal AI Client', style: TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:13, color: Color(0xFFF1F5F9))),
          const SizedBox(width:12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (i){
                  final isActive = i==idx;
                  return Padding(
                    padding: const EdgeInsets.only(right:6),
                    child: ChoiceChip(
                      label: Text(tabs[i], style: TextStyle(fontSize:13, fontWeight: FontWeight.w600, color: isActive? const Color(0xFF111827): const Color(0xFF94A3B8))),
                      selected: isActive,
                      selectedColor: const Color(0xFFF1F5F9),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: isActive? const Color(0xFFF1F5F9): Colors.transparent),
                      onSelected: (_)=> context.go(paths[i]),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal:10, vertical: 0),
                    ),
                  );
                }),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
            decoration: BoxDecoration(
              color: hasProvider? const Color(0xFF10B981).withValues(alpha:0.12): const Color(0xFFF59E0B).withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: hasProvider? const Color(0xFF10B981).withValues(alpha:0.4): const Color(0xFFF59E0B).withValues(alpha:0.4)),
            ),
            child: Text(hasProvider? '● ${active.name} · 已配置': '○ 未配置 Provider', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: hasProvider? const Color(0xFF10B981): const Color(0xFFF59E0B))),
          ),
          const SizedBox(width:8),
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
