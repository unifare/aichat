
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});
  @override Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    int idx=0;
    if(loc.startsWith('/image')) idx=1;
    else if(loc.startsWith('/video')) idx=2;
    else if(loc.startsWith('/settings')) idx=3;
    final tabs = ['对话','画图','视频','设置'];
    final paths = ['/chat','/image','/video','/settings'];
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF141C2B),
        border: Border(bottom: BorderSide(color: Color(0xFF2E3B52))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // window dots (desktop decoration)
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
          // tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(4, (i){
                  final active = i==idx;
                  return Padding(
                    padding: const EdgeInsets.only(right:6),
                    child: ChoiceChip(
                      label: Text(tabs[i], style: TextStyle(fontSize:13, fontWeight: FontWeight.w600, color: active? const Color(0xFF111827): const Color(0xFF94A3B8))),
                      selected: active,
                      selectedColor: const Color(0xFFF1F5F9),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: active? const Color(0xFFF1F5F9): Colors.transparent),
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
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4))),
            child: const Text('● Mock · 已连接', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
          ),
          const SizedBox(width:8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal:8, vertical:6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFF2E3B52)), color: const Color(0x0AFFFFFF)),
            child: const Text('v0.1 · Riverpod', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }
}
