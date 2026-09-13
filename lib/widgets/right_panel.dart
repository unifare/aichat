
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class RightPanel extends ConsumerWidget {
  final int currentIndex;
  const RightPanel({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final titles = ['参数','生成参数','任务','说明'];
    final title = titles[currentIndex.clamp(0,3)];
    return Container(
      color: const Color(0xFF1A2230),
      child: Column(children:[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2E3B52)))),
          child: Row(children:[ Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)), const Spacer(), const Icon(Icons.remove, size:16, color: Color(0xFF94A3B8))]),
        ),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(12), child: _body(ref))),
      ]),
    );
  }

  Widget _body(WidgetRef ref){
    final configs = ref.watch(providerConfigsProvider);
    final activeId = ref.watch(activeProviderIdProvider);
    final active = configs.where((c)=>c.id==activeId).firstOrNull ?? (configs.isNotEmpty? configs.first: null);
    switch(currentIndex){
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('系统提示词', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: Color(0xFF94A3B8))),
          const SizedBox(height:6),
          TextField(maxLines:3, decoration: const InputDecoration(hintText: '你是 Universal AI Client 的助手…'), controller: TextEditingController(text: '你是 Universal AI Client 的助手，精通 Flutter 与 Provider 抽象。')),
          const SizedBox(height:12),
          if(active==null)
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha:0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha:0.25))), child: const Text('未配置 Provider，请到设置页添加后再使用对话。', style: TextStyle(fontSize:12, color: Color(0xFFF59E0B)))),
          if(active!=null)
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF232E42), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF2E3B52))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              const Text('当前 Provider 路由', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
              const SizedBox(height:6),
              Text('chat → ${active.name}\nmodel → ${active.chatModel}\nendpoint → ${active.baseUrl}${active.chatEndpoint}', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, height:1.6)),
            ])),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('负面提示词', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
          const SizedBox(height:6),
          const TextField(decoration: InputDecoration(hintText: '模糊、低质量、畸形…')),
          const SizedBox(height:12),
          if(active==null)
            const Text('未配置 Provider，无法生成图片。', style: TextStyle(fontSize:12, color: Color(0xFFF59E0B))),
          if(active!=null)
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF232E42), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF2E3B52))), child: Text('image → ${active.name}\nmodel → ${active.imageModel}\nendpoint → ${active.baseUrl}${active.imageEndpoint}', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, height:1.6))),
        ]);
      case 2:
        final videos = ref.watch(videoTasksProvider);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          if(active==null)
            const Text('未配置 Provider，无法生成视频。', style: TextStyle(fontSize:12, color: Color(0xFFF59E0B))),
          if(active!=null)
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF232E42), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF2E3B52))), child: Text('video → ${active.name}\nmodel → ${active.videoModel}\nendpoint → ${active.baseUrl}${active.videoEndpoint}', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, height:1.6))),
          const SizedBox(height:12),
          Text('进行中任务：${videos.where((e)=>e.status.name=="processing").length}', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
        ]);
      default:
        return const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('本应用不含任何假数据。所有对话、图片、视频均来自你配置的真实 Endpoint。', style: TextStyle(fontSize:12, height:1.6, color: Color(0xFF94A3B8))),
          SizedBox(height:12),
          Text('抽象：AIProvider\nchat / chatStream / generateImage / generateVideo / getVideoTask / testConnection\n\n未配置时所有操作会返回真实错误，不会展示假成功。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, height:1.6)),
        ]);
    }
  }
}
extension _FO<E> on Iterable<E>{ E? get firstOrNull => isEmpty? null: first; }
