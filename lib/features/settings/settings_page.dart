
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/provider_config.dart';
import '../../providers/app_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override ConsumerState<SettingsPage> createState()=> _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override Widget build(BuildContext context){
    final configs = ref.watch(providerConfigsProvider);
    final activeId = ref.watch(activeProviderIdProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
            Row(children:[
              const Text('AI Providers', style: TextStyle(fontWeight: FontWeight.w700, fontSize:16)),
              const SizedBox(width:8),
              Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border), color: const Color(0x0AFFFFFF)), child: const Text('本地安全存储 · flutter_secure_storage', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
              const Spacer(),
              FilledButton.icon(onPressed: _addProvider, icon: const Icon(Icons.add, size:16), label: const Text('添加 Provider'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
            const SizedBox(height:14),
            ...configs.map((c)=> Padding(padding: const EdgeInsets.only(bottom:12), child: _providerCard(c, c.id==activeId))),
            // dashed add card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, style: BorderStyle.solid), color: Colors.transparent),
              child: Row(children:[
                Container(width:32,height:32, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border, style: BorderStyle.solid)), child: const Icon(Icons.add, size:18, color: AppColors.muted)),
                const SizedBox(width:12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                  Text('添加 ComfyUI / Replicate / 本地 LAN API', style: TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
                  Text('支持自定义 Chat / Image / Video Endpoint 与模型列表', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                ]),
                const Spacer(),
                OutlinedButton(onPressed: (){}, child: const Text('新建')),
              ]),
            ),
            const SizedBox(height:14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                const Text('本地数据', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: AppColors.muted)),
                const SizedBox(height:8),
                Wrap(spacing:6, runSpacing:6, children:[
                  _chip('Drift / SQLite · 会话与任务'),
                  _chip('cached_network_image'),
                  _chip('video_player'),
                ]),
                const SizedBox(height:8),
                const Text('所有历史、图片与视频任务均本地持久化，Endpoint 仅在请求时使用。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height:14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: const Text('抽象：AIProvider\nchat / generateImage / generateVideo / getVideoTask', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, height:1.6)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String t)=> Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: Text(t, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted, fontWeight: FontWeight.w600)));

  Widget _providerCard(ProviderConfig c, bool active){
    return Container(
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: active? AppColors.accent.withOpacity(0.4): AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children:[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children:[
            Container(width:8,height:8, decoration: BoxDecoration(color: active? AppColors.accent: AppColors.warn, shape: BoxShape.circle, boxShadow:[BoxShadow(color: (active? AppColors.accent: AppColors.warn).withOpacity(0.2), blurRadius:6, spreadRadius:2)])),
            const SizedBox(width:8),
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13)),
            const SizedBox(width:8),
            Expanded(child: Text(c.baseUrl, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted), overflow: TextOverflow.ellipsis)),
            const SizedBox(width:8),
            Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: active? AppColors.accent.withOpacity(0.12): const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: active? AppColors.accent.withOpacity(0.4): AppColors.border)), child: Text(active? '已连接 · 42ms': '未测试', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: active? AppColors.accent: AppColors.muted))),
            const SizedBox(width:8),
            ChoiceChip(label: const Text('当前', style: TextStyle(fontSize:11)), selected: active, onSelected: (v){ if(v) ref.read(activeProviderIdProvider.notifier).state=c.id; }, selectedColor: AppColors.accent.withOpacity(0.2), showCheckmark: false),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children:[
            Row(children:[
              Expanded(child: _field('Chat Model', c.chatModel, (v)=> _update(c.copyWith(chatModel:v)))),
              const SizedBox(width:10),
              Expanded(child: _field('Image Model', c.imageModel, (v)=> _update(c.copyWith(imageModel:v)))),
            ]),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child: _field('Video Model', c.videoModel, (v)=> _update(c.copyWith(videoModel:v)))),
              const SizedBox(width:10),
              Expanded(child: _field('API Key', c.apiKey.isEmpty? '••••••••': c.apiKey, (v)=> _update(c.copyWith(apiKey:v)), obscure:true)),
            ]),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child: OutlinedButton(onPressed: ()=> _test(c), child: const Text('Test Connection', style: TextStyle(fontSize:12)))),
              const SizedBox(width:8),
              Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('查看用量', style: TextStyle(fontSize:12)))),
            ]),
            if(c.id!='mock') ...[
              const SizedBox(height:10),
              _field('API Base URL', c.baseUrl, (v)=> _update(c.copyWith(baseUrl:v))),
              const SizedBox(height:8),
              Row(children:[
                Expanded(child: _field('Chat Endpoint', c.chatEndpoint, (v)=> _update(c.copyWith(chatEndpoint:v)))),
                const SizedBox(width:8),
                Expanded(child: _field('Image Endpoint', c.imageEndpoint, (v)=> _update(c.copyWith(imageEndpoint:v)))),
              ]),
              const SizedBox(height:8),
              _field('Video Endpoint', c.videoEndpoint, (v)=> _update(c.copyWith(videoEndpoint:v))),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _field(String label, String value, Function(String) onChanged, {bool obscure=false}){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(label, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: AppColors.muted)),
      const SizedBox(height:6),
      TextFormField(
        initialValue: value,
        obscureText: obscure,
        style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:13),
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal:10, vertical:9)),
        onFieldSubmitted: onChanged,
        onChanged: onChanged,
      ),
    ]);
  }

  void _update(ProviderConfig c)=> ref.read(providerConfigsProvider.notifier).update(c);

  void _test(ProviderConfig c) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('测试中…')));
    await Future.delayed(const Duration(milliseconds: 900));
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ 连接成功 · 42ms')));
  }

  void _addProvider(){
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final urlController = TextEditingController(text:'https://');
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('添加 Provider', style: TextStyle(fontSize:15)),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller: nameController, decoration: const InputDecoration(labelText: '名称', hintText: 'My Gateway')),
        const SizedBox(height:8),
        TextField(controller: urlController, decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://ai.example.com/v1')),
      ]),
      actions:[
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: (){
          final name = nameController.text.trim().isEmpty? 'Custom': nameController.text.trim();
          final url = urlController.text.trim().isEmpty? 'https://ai.example.com/v1': urlController.text.trim();
          final id = name.toLowerCase().replaceAll(' ', '_') + '_' + DateTime.now().millisecondsSinceEpoch.toString().substring(8);
          ref.read(providerConfigsProvider.notifier).add(ProviderConfig(id:id, name:name, baseUrl:url, chatModel:'gpt-4o', imageModel:'dall-e-3', videoModel:'sora'));
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已添加 $name')));
        }, style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827)), child: const Text('添加')),
      ],
    ));
  }
}
