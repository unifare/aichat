
import 'package:flutter/material.dart';

class RightPanel extends StatelessWidget {
  final int currentIndex;
  const RightPanel({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context){
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
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(12), child: _body())),
      ]),
    );
  }

  Widget _body(){
    switch(currentIndex){
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('系统提示词', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: Color(0xFF94A3B8))),
          const SizedBox(height:6),
          TextField(maxLines:3, decoration: InputDecoration(hintText: '你是 Universal AI Client 的助手…'), controller: TextEditingController(text: '你是 Universal AI Client 的助手，精通 Flutter 与 Provider 抽象。')),
          const SizedBox(height:12),
          Row(children:[
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ const Text('温度', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))), Slider(value:0.7, min:0, max:1, onChanged: (_){}, activeColor: Color(0xFF10B981)), const Text('0.7 · 平衡', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))) ])),
            const SizedBox(width:12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[ const Text('Top-P', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))), Slider(value:0.9, min:0, max:1, onChanged: (_){}, activeColor: Color(0xFF10B981)), const Text('0.9', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))) ])),
          ]),
          const SizedBox(height:12),
          const Text('工具', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
          const SizedBox(height:6),
          Wrap(spacing:6, children:[
            _chip('Streaming', accent:true),
            _chip('函数调用'),
            _chip('联网'),
          ]),
          const SizedBox(height:12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Color(0xFF232E42), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF2E3B52))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text('Provider 路由', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
            SizedBox(height:6),
            Text('chat → Mock (本地演示)\nimage → Mock\nvideo → Mock', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, height:1.6)),
          ])),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('负面提示词', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
          const SizedBox(height:6),
          const TextField(decoration: InputDecoration(hintText: '模糊、低质量、畸形…')),
          const SizedBox(height:12),
          const Text('风格预设', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
          const SizedBox(height:6),
          Wrap(spacing:6, children:[ _chip('电影感', accent:true), _chip('赛博'), _chip('水彩'), _chip('极简')]),
          const SizedBox(height:12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Color(0xFF101727), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF2E3B52))), child: const Text('提示：可拖入参考图实现 Image+Text→Image。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8)))),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text('运镜', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: Color(0xFF94A3B8))),
          const SizedBox(height:6),
          DropdownButtonFormField<String>(value:'推轨', decoration: const InputDecoration(), items: const [DropdownMenuItem(value:'推轨', child: Text('推轨')), DropdownMenuItem(value:'环绕', child: Text('环绕')), DropdownMenuItem(value:'固定', child: Text('固定'))], onChanged: (_){}),
          const SizedBox(height:12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Color(0xFF232E42), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF2E3B52))), child: const Text('task_id: v_9f32\nstatus: processing\nprogress: 67%\npoll: 3s / 次', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, height:1.7))),
          const SizedBox(height:12),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: (){}, child: const Text('查看 API 日志'))),
        ]);
      default:
        return const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text('Endpoint 可配置到“模型”级别，支持多 Provider 并存，UI 层无感知切换。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, height:1.6, color: Color(0xFF94A3B8))),
          SizedBox(height:12),
          Text('抽象：AIProvider\nchat / generateImage / generateVideo / getVideoTask', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, height:1.6)),
        ]);
    }
  }

  Widget _chip(String t, {bool accent=false})=> Container(
    padding: const EdgeInsets.symmetric(horizontal:10, vertical:6),
    decoration: BoxDecoration(color: accent? const Color(0xFF10B981).withOpacity(0.12): const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: accent? const Color(0xFF10B981).withOpacity(0.4): const Color(0xFF2E3B52))),
    child: Text(t, style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: accent? const Color(0xFF10B981): const Color(0xFF94A3B8))),
  );
}
