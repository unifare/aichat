
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final convs = ref.watch(conversationsProvider);
    final activeId = ref.watch(activeConversationIdProvider);
    return Container(
      color: const Color(0xFF1A2230),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14,14,14,12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2E3B52)))),
            child: Row(children: [
              Container(width:32,height:32,decoration:BoxDecoration(color:const Color(0xFF10B981), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: const Text('AI', style: TextStyle(fontFamily:'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:13, color: Color(0xFF111827)))),
              const SizedBox(width:10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Text('AI Client', style: TextStyle(fontWeight: FontWeight.w700, fontSize:13)),
                Text('全平台 · Provider 抽象', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
              ]),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)), color: Color(0xFF10B981).withOpacity(0.12)), child: const Text('全平台', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:10, color: Color(0xFF10B981), fontWeight: FontWeight.w600))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children:[
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: ()=> ref.read(conversationsProvider.notifier).newConversation(), icon: const Icon(Icons.add, size:18), label: const Text('新对话'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Color(0xFF111827), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.symmetric(vertical:11)))),
              const SizedBox(height:8),
              Row(children:[
                Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('模板', style: TextStyle(fontSize:12, color: Color(0xFF94A3B8))))),
                const SizedBox(width:8),
                Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('导入', style: TextStyle(fontSize:12, color: Color(0xFF94A3B8))))),
              ]),
            ]),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(14,6,14,8), child: Align(alignment: Alignment.centerLeft, child: Text('今天', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.8, color: Color(0xFF64748B))))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal:8),
              itemCount: convs.length,
              itemBuilder: (c,i){
                final conv = convs[i];
                final active = conv.id==activeId;
                return Container(
                  margin: const EdgeInsets.only(bottom:6),
                  decoration: BoxDecoration(color: active? const Color(0xFF232E42): Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: active? const Color(0xFF2E3B52): Colors.transparent)),
                  child: ListTile(
                    dense: true,
                    title: Text(conv.title, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
                    subtitle: Text('${conv.model} · ${_ago(conv.updatedAt)}', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
                    trailing: Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:3), decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: Color(0xFF2E3B52))), child: Text(conv.model, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:10, color: Color(0xFF94A3B8)))),
                    onTap: ()=> ref.read(activeConversationIdProvider.notifier).state = conv.id,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2E3B52)))),
            child: Column(children:[
              Row(children:[
                Container(width:8,height:8,decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle, boxShadow:[BoxShadow(color: Color(0x2610B981), blurRadius:6, spreadRadius:2)])),
                const SizedBox(width:8),
                const Text('已连接 1 个 Provider', style: TextStyle(fontWeight: FontWeight.w600, fontSize:12)),
                const Spacer(),
                const Text('延迟 86ms', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
              ]),
              const SizedBox(height:8),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: 0.86, minHeight:6, backgroundColor: Color(0x14FFFFFF), valueColor: AlwaysStoppedAnimation(Color(0xFF10B981)))),
            ]),
          ),
        ],
      ),
    );
  }
  String _ago(DateTime t){
    final d = DateTime.now().difference(t);
    if(d.inMinutes<2) return '刚刚';
    if(d.inMinutes<60) return '${d.inMinutes} 分钟前';
    if(d.inHours<24) return '${d.inHours} 小时前';
    return '${d.inDays} 天前';
  }
}
