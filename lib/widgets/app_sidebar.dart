
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final convs = ref.watch(conversationsProvider);
    final activeId = ref.watch(activeConversationIdProvider);
    final configs = ref.watch(providerConfigsProvider);
    final hasProvider = configs.isNotEmpty;
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
              Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: Color(0xFF10B981).withValues(alpha:0.3)), color: Color(0xFF10B981).withValues(alpha:0.12)), child: const Text('真实', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:10, color: Color(0xFF10B981), fontWeight: FontWeight.w600))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children:[
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: hasProvider? ()=> ref.read(conversationsProvider.notifier).newConversation(): (){
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先到 设置 页添加 Provider')));
                  context.go('/settings');
                },
                icon: const Icon(Icons.add, size:18), label: const Text('新对话'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Color(0xFF111827), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.symmetric(vertical:11)))),
              const SizedBox(height:8),
              if(!hasProvider)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha:0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha:0.25))),
                  child: const Row(children:[
                    Icon(Icons.info_outline, size:16, color: Color(0xFFF59E0B)),
                    SizedBox(width:8),
                    Expanded(child: Text('未配置 Provider，无法发起对话', style: TextStyle(fontSize:12, color: Color(0xFFF59E0B)))),
                  ]),
                ),
            ]),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(14,6,14,8), child: Align(alignment: Alignment.centerLeft, child: Text('会话', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.8, color: Color(0xFF64748B))))),
          Expanded(
            child: convs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(mainAxisSize: MainAxisSize.min, children:[
                      Icon(Icons.chat_bubble_outline, color: Color(0xFF475569), size:28),
                      SizedBox(height:8),
                      Text('还没有会话', style: TextStyle(fontSize:13, color: Color(0xFF94A3B8))),
                      SizedBox(height:4),
                      Text('点击“新对话”开始（需先配置 Provider）', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF64748B)), textAlign: TextAlign.center),
                    ]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal:8),
                  itemCount: convs.length,
                  itemBuilder: (c,i){
                    final conv = convs[i];
                    final isActive = conv.id==activeId;
                    return Container(
                      margin: const EdgeInsets.only(bottom:6),
                      decoration: BoxDecoration(color: isActive? const Color(0xFF232E42): Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isActive? const Color(0xFF2E3B52): Colors.transparent)),
                      child: ListTile(
                        dense: true,
                        title: Text(conv.title, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
                        subtitle: Text('${conv.model} · ${_ago(conv.updatedAt)} · ${conv.messages.length} 条', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, size:16, color: Color(0xFF64748B)),
                          onSelected: (v){
                            if(v=='del') _confirmDelete(context, ref, conv.id);
                          },
                          itemBuilder: (ctx)=> [const PopupMenuItem(value:'del', child: Text('删除会话', style: TextStyle(color: Color(0xFFEF4444))))],
                        ),
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
                Container(width:8,height:8,decoration: BoxDecoration(color: configs.isEmpty? const Color(0xFFEF4444): const Color(0xFF10B981), shape: BoxShape.circle)),
                const SizedBox(width:8),
                Text(configs.isEmpty? '未配置 Provider': '已配置 ${configs.length} 个 Provider', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:12)),
                const Spacer(),
                TextButton(onPressed: ()=> context.go('/settings'), child: const Text('去设置', style: TextStyle(fontSize:12))),
              ]),
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
  void _confirmDelete(BuildContext context, WidgetRef ref, String id){
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      backgroundColor: const Color(0xFF1A2230),
      title: const Text('删除会话？', style: TextStyle(fontSize:15)),
      content: const Text('此操作不可撤销，本地历史将被删除。', style: TextStyle(fontSize:13, color: Color(0xFF94A3B8))),
      actions:[
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: (){ Navigator.pop(ctx); ref.read(conversationsProvider.notifier).deleteConversation(id); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)), child: const Text('删除')),
      ],
    ));
  }
}
