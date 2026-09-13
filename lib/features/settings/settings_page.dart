
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/provider_config.dart';
import '../../providers/app_providers.dart';
import '../../providers/compatible_provider.dart';

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
              Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border), color: const Color(0x0AFFFFFF)), child: const Text('Base URL + Endpoints 可配置 · 真实请求', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
              const Spacer(),
              FilledButton.icon(onPressed: _addProvider, icon: const Icon(Icons.add, size:16), label: const Text('添加 Provider'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
            const SizedBox(height:8),
            const Text('所有 Provider 配置真实持久化到本地（SharedPreferences + SecureStorage）。未配置前，所有 Chat/Image/Video 均会返回真实错误，不展示假数据。', style: TextStyle(fontSize:12, color: AppColors.muted, height:1.5)),
            const SizedBox(height:14),
            if(configs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: Column(children:[
                  Container(width:56,height:56, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withValues(alpha:0.2))), child: const Icon(Icons.cloud_outlined, color: AppColors.accent, size:28)),
                  const SizedBox(height:12),
                  const Text('还没有 Provider', style: TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
                  const SizedBox(height:4),
                  const Text('添加你的 OpenAI / OpenAI Compatible / 自建网关\n填写 Base URL 与 API Key 后即可真实使用', style: TextStyle(fontSize:12, color: AppColors.muted, height:1.5), textAlign: TextAlign.center),
                  const SizedBox(height:12),
                  FilledButton.icon(onPressed: _addProvider, icon: const Icon(Icons.add, size:16), label: const Text('添加第一个 Provider'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827))),
                  const SizedBox(height:12),
                  _exampleCard('OpenAI', 'https://api.openai.com/v1', '/chat/completions', '/images/generations', '/video/generations'),
                  const SizedBox(height:8),
                  _exampleCard('自建网关', 'https://ai.company.local/v1', '/chat/completions', '/images/generations', '/video/generations'),
                ]),
              )
            else
              ...configs.map((c)=> Padding(padding: const EdgeInsets.only(bottom:12), child: _providerCard(c, c.id==activeId))),
            if(configs.isNotEmpty) ...[
              const SizedBox(height:4),
              // 添加更多
              InkWell(
                onTap: _addProvider,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, style: BorderStyle.solid), color: Colors.transparent),
                  child: const Row(children:[
                    Icon(Icons.add, size:18, color: AppColors.muted),
                    SizedBox(width:8),
                    Text('添加 ComfyUI / Replicate / 本地 LAN API', style: TextStyle(fontSize:13, color: AppColors.muted)),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size:14, color: AppColors.muted),
                  ]),
                ),
              ),
            ],
            const SizedBox(height:14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                const Text('本地数据说明', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: AppColors.muted)),
                const SizedBox(height:8),
                const Text('· 会话与消息：SharedPreferences 真实持久化，删除后不可恢复\n· API Key：flutter_secure_storage 加密存储，不以明文落盘\n· 图片/视频任务：当前为内存态，重启后清空（可扩展为本地 DB）', style: TextStyle(fontSize:12, color: AppColors.muted, height:1.6)),
                const SizedBox(height:8),
                Wrap(spacing:6, runSpacing:6, children:[
                  _chip('SharedPreferences'),
                  _chip('flutter_secure_storage'),
                  _chip('Dio'),
                  _chip('Riverpod'),
                  _chip('go_router'),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String t)=> Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: Text(t, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted, fontWeight: FontWeight.w600)));

  Widget _exampleCard(String name, String base, String chat, String img, String vid){
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize:12)),
        const SizedBox(height:4),
        Text('Base: $base\nChat: $chat  Image: $img  Video: $vid', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted, height:1.5)),
      ]),
    );
  }

  Widget _providerCard(ProviderConfig c, bool isActive){
    return Container(
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive? AppColors.accent.withValues(alpha:0.4): AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children:[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children:[
            Container(width:8,height:8, decoration: BoxDecoration(color: isActive? AppColors.accent: AppColors.muted, shape: BoxShape.circle)),
            const SizedBox(width:8),
            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:13), overflow: TextOverflow.ellipsis)),
            const SizedBox(width:8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
              decoration: BoxDecoration(color: isActive? AppColors.accent.withValues(alpha:0.12): const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: isActive? AppColors.accent.withValues(alpha:0.4): AppColors.border)),
              child: Text(isActive? '当前': '未选中', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: isActive? AppColors.accent: AppColors.muted)),
            ),
            const SizedBox(width:8),
            if(!isActive) OutlinedButton(onPressed: ()=> ref.read(activeProviderIdProvider.notifier).set(c.id), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal:10, vertical:6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('设为当前', style: TextStyle(fontSize:11))),
            const SizedBox(width:8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size:16, color: AppColors.muted),
              onSelected: (v){
                if(v=='copy') Clipboard.setData(ClipboardData(text: c.baseUrl));
                if(v=='delete') _confirmDelete(c);
                if(v=='copy_id') Clipboard.setData(ClipboardData(text: c.id));
              },
              itemBuilder: (ctx)=> [
                const PopupMenuItem(value:'copy', child: Text('复制 Base URL')),
                const PopupMenuItem(value:'copy_id', child: Text('复制 ID')),
                const PopupMenuItem(value:'delete', child: Text('删除', style: TextStyle(color: AppColors.danger))),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children:[
            _editableField('名称', c.name, (v)=> _update(c.copyWith(name:v))),
            const SizedBox(height:10),
            _editableField('Base URL', c.baseUrl, (v)=> _update(c.copyWith(baseUrl:v)), hint:'https://api.openai.com/v1'),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child: _editableField('Chat Endpoint', c.chatEndpoint, (v)=> _update(c.copyWith(chatEndpoint:v)), hint:'/chat/completions')),
              const SizedBox(width:8),
              Expanded(child: _editableField('Image Endpoint', c.imageEndpoint, (v)=> _update(c.copyWith(imageEndpoint:v)), hint:'/images/generations')),
            ]),
            const SizedBox(height:10),
            _editableField('Video Endpoint', c.videoEndpoint, (v)=> _update(c.copyWith(videoEndpoint:v)), hint:'/video/generations'),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child: _editableField('Chat Model', c.chatModel, (v)=> _update(c.copyWith(chatModel:v)), hint:'gpt-4o')),
              const SizedBox(width:8),
              Expanded(child: _editableField('Image Model', c.imageModel, (v)=> _update(c.copyWith(imageModel:v)), hint:'dall-e-3')),
            ]),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child: _editableField('Video Model', c.videoModel, (v)=> _update(c.copyWith(videoModel:v)), hint:'sora')),
              const SizedBox(width:8),
              Expanded(child: _editableField('API Key', c.apiKey, (v)=> _update(c.copyWith(apiKey:v)), hint:'sk-…', obscure:true)),
            ]),
            const SizedBox(height:12),
            Row(children:[
              Expanded(child: OutlinedButton.icon(onPressed: ()=> _testConnection(c), icon: const Icon(Icons.wifi_tethering, size:16), label: const Text('测试连接', style: TextStyle(fontSize:12)))),
              const SizedBox(width:8),
              Expanded(child: OutlinedButton.icon(onPressed: ()=> _showDetails(c), icon: const Icon(Icons.info_outline, size:16), label: const Text('查看配置', style: TextStyle(fontSize:12)))),
            ]),
            const SizedBox(height:8),
            SizedBox(
              width: double.infinity,
              child: Text('ID: ${c.id}  ·  Base: ${c.baseUrl.isEmpty? '（未填）': c.baseUrl}', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _editableField(String label, String value, Function(String) onChanged, {String hint='', bool obscure=false}){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(label, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: AppColors.muted)),
      const SizedBox(height:6),
      Row(children:[
        Expanded(
          child: TextFormField(
            initialValue: value,
            obscureText: obscure,
            style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:13),
            decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal:10, vertical:9), isDense: true),
            onFieldSubmitted: onChanged,
            onChanged: (v){
              // 实时更新，但避免每字符都触发保存：用 debounce 可选，这里直接更新，体验更人性化
            },
          ),
        ),
        const SizedBox(width:6),
        SizedBox(
          height: 36,
          child: OutlinedButton(
            onPressed: (){
              final ctrl = TextEditingController(text: value);
              showDialog(context: context, builder: (ctx)=> AlertDialog(
                backgroundColor: AppColors.surface,
                title: Text('编辑 $label', style: const TextStyle(fontSize:14)),
                content: TextField(controller: ctrl, obscureText: obscure, decoration: InputDecoration(hintText: hint), autofocus: true),
                actions:[
                  TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('取消')),
                  FilledButton(onPressed: (){ Navigator.pop(ctx); onChanged(ctrl.text.trim()); }, style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827)), child: const Text('保存')),
                ],
              ));
            },
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal:8), minimumSize: const Size(0,36)),
            child: const Icon(Icons.edit, size:14),
          ),
        ),
      ]),
    ]);
  }

  void _update(ProviderConfig c)=> ref.read(providerConfigsProvider.notifier).update(c);

  Future<void> _testConnection(ProviderConfig c) async {
    if(c.baseUrl.trim().isEmpty || c.apiKey.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写 Base URL 与 API Key')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在测试连接…')));
    final ok = await CompatibleProvider(c).testConnection();
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok? '✓ 连接成功': '✗ 连接失败：请检查 Base URL / Endpoint / API Key / 网络'), backgroundColor: ok? AppColors.accent: AppColors.danger));
  }

  void _showDetails(ProviderConfig c){
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(c.name, style: const TextStyle(fontSize:15)),
      content: SelectableText(
        'ID: ${c.id}\nBase: ${c.baseUrl}\nChat: ${c.chatEndpoint} (${c.chatModel})\nImage: ${c.imageEndpoint} (${c.imageModel})\nVideo: ${c.videoEndpoint} (${c.videoModel})\nAPI Key: ${c.apiKey.isEmpty? '（未填）': '••••••••'}',
        style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:12, height:1.6),
      ),
      actions:[ TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('关闭')) ],
    ));
  }

  void _confirmDelete(ProviderConfig c){
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('删除 Provider？', style: TextStyle(fontSize:15)),
      content: Text('将删除 "${c.name}"，此操作不可撤销。', style: const TextStyle(fontSize:13, color: AppColors.muted)),
      actions:[
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: (){
          Navigator.pop(ctx);
          ref.read(providerConfigsProvider.notifier).remove(c.id);
          final active = ref.read(activeProviderIdProvider);
          if(active==c.id) ref.read(activeProviderIdProvider.notifier).set(null);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除 ${c.name}')));
        }, style: FilledButton.styleFrom(backgroundColor: AppColors.danger), child: const Text('删除')),
      ],
    ));
  }

  void _addProvider(){
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text:'https://');
    final chatEpCtrl = TextEditingController(text:'/chat/completions');
    final imgEpCtrl = TextEditingController(text:'/images/generations');
    final vidEpCtrl = TextEditingController(text:'/video/generations');
    final chatModelCtrl = TextEditingController(text:'gpt-4o');
    final imgModelCtrl = TextEditingController(text:'dall-e-3');
    final vidModelCtrl = TextEditingController(text:'sora');
    final keyCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx)=> AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('添加 Provider', style: TextStyle(fontSize:15)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', hintText: 'OpenAI / 自建网关'), autofocus: true),
          const SizedBox(height:8),
          TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Base URL *', hintText: 'https://api.openai.com/v1')),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child: TextField(controller: chatEpCtrl, decoration: const InputDecoration(labelText: 'Chat Endpoint'))),
            const SizedBox(width:8),
            Expanded(child: TextField(controller: imgEpCtrl, decoration: const InputDecoration(labelText: 'Image Endpoint'))),
          ]),
          const SizedBox(height:8),
          TextField(controller: vidEpCtrl, decoration: const InputDecoration(labelText: 'Video Endpoint')),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child: TextField(controller: chatModelCtrl, decoration: const InputDecoration(labelText: 'Chat Model'))),
            const SizedBox(width:8),
            Expanded(child: TextField(controller: imgModelCtrl, decoration: const InputDecoration(labelText: 'Image Model'))),
          ]),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child: TextField(controller: vidModelCtrl, decoration: const InputDecoration(labelText: 'Video Model'))),
            const SizedBox(width:8),
            Expanded(child: TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: 'API Key *', hintText: 'sk-…'), obscureText: true)),
          ]),
        ]),
      ),
      actions:[
        TextButton(onPressed: ()=> Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(
          onPressed: (){
            final name = nameCtrl.text.trim().isEmpty? 'Custom': nameCtrl.text.trim();
            final base = urlCtrl.text.trim();
            if(base.isEmpty){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写 Base URL')));
              return;
            }
            if(keyCtrl.text.trim().isEmpty){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写 API Key')));
              return;
            }
            final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_') + '_' + DateTime.now().millisecondsSinceEpoch.toString().substring(8);
            final cfg = ProviderConfig(
              id:id, name:name, baseUrl:base,
              chatEndpoint: chatEpCtrl.text.trim().isEmpty? '/chat/completions': chatEpCtrl.text.trim(),
              imageEndpoint: imgEpCtrl.text.trim().isEmpty? '/images/generations': imgEpCtrl.text.trim(),
              videoEndpoint: vidEpCtrl.text.trim().isEmpty? '/video/generations': vidEpCtrl.text.trim(),
              chatModel: chatModelCtrl.text.trim().isEmpty? 'gpt-4o': chatModelCtrl.text.trim(),
              imageModel: imgModelCtrl.text.trim().isEmpty? 'dall-e-3': imgModelCtrl.text.trim(),
              videoModel: vidModelCtrl.text.trim().isEmpty? 'sora': vidModelCtrl.text.trim(),
              apiKey: keyCtrl.text.trim(),
            );
            ref.read(providerConfigsProvider.notifier).add(cfg);
            ref.read(activeProviderIdProvider.notifier).set(id);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已添加 $name 并设为当前')));
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827)),
          child: const Text('添加'),
        ),
      ],
    ));
  }
}
