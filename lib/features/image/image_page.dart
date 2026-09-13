
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/image_task.dart';
import '../../providers/app_providers.dart';

class ImagePage extends ConsumerStatefulWidget {
  const ImagePage({super.key});
  @override ConsumerState<ImagePage> createState()=> _ImagePageState();
}

class _ImagePageState extends ConsumerState<ImagePage> {
  final _prompt = TextEditingController();
  String _model='';
  String _size='1024x1024';
  bool _loading=false;

  @override void initState(){ super.initState(); WidgetsBinding.instance.addPostFrameCallback((_){ _syncModel(); }); }
  void _syncModel(){
    final configs = ref.read(providerConfigsProvider);
    final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? (configs.isNotEmpty? configs.first: null);
    if(active!=null && _model.isEmpty) setState(()=> _model=active.imageModel);
  }

  Future<void> _generate() async {
    final prompt = _prompt.text.trim();
    if(prompt.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入 Prompt')));
      return;
    }
    final configs = ref.read(providerConfigsProvider);
    if(configs.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('未配置 Provider'), action: SnackBarAction(label:'去设置', onPressed: ()=> context.go('/settings'))));
      return;
    }
    if(_model.isEmpty){
      final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? configs.first;
      _model = active.imageModel;
    }
    setState(()=>_loading=true);
    final provider = ref.read(aiProviderProvider);
    final notifier = ref.read(imageTasksProvider.notifier);
    final id = const Uuid().v4();
    notifier.add(ImageTask(id:id, prompt: prompt, model: _model, size: _size, status: ImageStatus.generating, progress: 0));
    try{
      final res = await provider.generateImage(prompt: prompt, model: _model, size: _size);
      if(res.urls.isEmpty){
        notifier.update(id, (t)=> t.copyWith(status: ImageStatus.failed, error: '服务端未返回图片 URL（请检查模型与 Endpoint）'));
      } else {
        notifier.update(id, (t)=> t.copyWith(status: ImageStatus.completed, imageUrls: res.urls, progress: 100));
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.urls.isEmpty? '生成失败：无返回': '生成完成 · ${res.urls.length} 张')));
    }catch(e){
      final msg = e.toString().replaceFirst('Exception:','').trim();
      notifier.update(id, (t)=> t.copyWith(status: ImageStatus.failed, error: msg));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败：$msg')));
    } finally {
      if(mounted) setState(()=>_loading=false);
    }
  }

  @override void dispose(){ _prompt.dispose(); super.dispose(); }

  @override Widget build(BuildContext context){
    final tasks = ref.watch(imageTasksProvider);
    final configs = ref.watch(providerConfigsProvider);
    final hasProvider = configs.isNotEmpty;
    final w = MediaQuery.of(context).size.width;
    final isMobile = w<600;
    if(hasProvider && _model.isEmpty){
      final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? configs.first;
      WidgetsBinding.instance.addPostFrameCallback((_)=> setState(()=> _model=active.imageModel));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
            if(!hasProvider)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom:12),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha:0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha:0.25))),
                child: Row(children:[
                  const Icon(Icons.warning_amber_rounded, size:18, color: Color(0xFFF59E0B)),
                  const SizedBox(width:8),
                  const Expanded(child: Text('未配置 Provider，无法生成图片。', style: TextStyle(fontSize:12, color: Color(0xFFF59E0B)))),
                  FilledButton(onPressed: ()=> context.go('/settings'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:12, vertical:6)), child: const Text('去设置', style: TextStyle(fontSize:12))),
                ]),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Row(children:[
                  const Icon(Icons.edit_outlined, size:12, color: AppColors.muted),
                  const SizedBox(width:4),
                  const Text('PROMPT', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: AppColors.muted)),
                  const Spacer(),
                  if(_prompt.text.isNotEmpty) Text('${_prompt.text.length} 字', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                ]),
                const SizedBox(height:6),
                TextField(
                  controller: _prompt,
                  maxLines:3,
                  minLines:2,
                  style: const TextStyle(fontSize:14, height:1.5),
                  decoration: InputDecoration(
                    hintText: '例如：一只坐在月球上的橘猫，霓虹城市背景，电影感光影…',
                    filled:true, fillColor: AppColors.surface2,
                    suffixIcon: _prompt.text.isNotEmpty? IconButton(icon: const Icon(Icons.clear, size:18), onPressed: ()=> setState(()=> _prompt.clear())): null,
                  ),
                  onChanged: (_)=> setState((){}),
                  enabled: hasProvider && !_loading,
                ),
                const SizedBox(height:12),
                Row(children:[
                  Expanded(child: _dropdown('模型', _model, _modelOptions(configs), (v)=> setState(()=>_model=v), enabled: hasProvider)),
                  const SizedBox(width:10),
                  Expanded(child: _dropdown('尺寸', _size, ['1024x1024','1024x1792','1792x1024','512x512'], (v)=> setState(()=>_size=v), enabled: hasProvider)),
                ]),
                const SizedBox(height:12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading || !hasProvider? null: _generate,
                    icon: _loading? const SizedBox(width:16,height:16, child: CircularProgressIndicator(strokeWidth:2, color: Color(0xFF111827))): const Icon(Icons.bolt, size:18),
                    label: Text(_loading? '正在请求服务端…': '生成图片'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), disabledBackgroundColor: AppColors.surface2, padding: const EdgeInsets.symmetric(vertical:12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(height:8),
                const Text('POST 到你配置的 Image Endpoint，成功返回图片 URL，失败展示错误信息。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height:16),
            Row(children:[
              const Icon(Icons.photo_library_outlined, size:14, color: AppColors.muted),
              const SizedBox(width:6),
              Text('生成结果 · ${tasks.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
              const Spacer(),
              if(tasks.isNotEmpty) TextButton(onPressed: ()=> ref.read(imageTasksProvider.notifier).clear(), child: const Text('清空', style: TextStyle(fontSize:12))),
            ]),
            const SizedBox(height:8),
            if(tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), color: AppColors.surface2),
                child: Column(children:[
                  Container(width:60,height:60, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withValues(alpha:0.2))), child: const Icon(Icons.image_outlined, color: AppColors.accent, size:28)),
                  const SizedBox(height:12),
                  const Text('还没有生成', style: TextStyle(color: AppColors.muted, fontSize:13)),
                  const SizedBox(height:4),
                  const Text('输入 Prompt 后点击“生成图片”，结果来自服务端。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted), textAlign: TextAlign.center),
                ]),
              )
            else
              GridView.builder(
                shrinkWrap:true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isMobile?1:2, crossAxisSpacing:12, mainAxisSpacing:12, childAspectRatio: 1),
                itemCount: tasks.length,
                itemBuilder: (c,i)=> _card(tasks[i]),
              ),
          ]),
        ),
      ),
    );
  }

  List<String> _modelOptions(List configs){
    final s=<String>{};
    for(final c in configs) s.add(c.imageModel);
    s.addAll(['dall-e-3','dall-e-2','sdxl','flux-schnell']);
    if(_model.isNotEmpty) s.add(_model);
    return s.toList();
  }

  Widget _dropdown(String label, String value, List<String> items, Function(String) onChanged, {bool enabled=true}){
    final hasValue = value.isNotEmpty && items.contains(value);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(label, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
      const SizedBox(height:6),
      DropdownButtonFormField<String>(
        initialValue: hasValue? value: null,
        hint: Text('选择$label', style: const TextStyle(fontSize:12, color: AppColors.muted)),
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal:10, vertical:10)),
        items: items.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:13)))).toList(),
        onChanged: enabled? (v){ if(v!=null) onChanged(v); }: null,
      ),
    ]);
  }

  Widget _card(ImageTask t){
    Widget body;
    switch(t.status){
      case ImageStatus.generating:
        body = const Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          SizedBox(width:32,height:32, child: CircularProgressIndicator(strokeWidth:3, color: AppColors.accent)),
          SizedBox(height:10),
          Text('正在生成…', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, color: AppColors.muted)),
          SizedBox(height:6),
          Text('等待服务端返回', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
        ]);
        break;
      case ImageStatus.failed:
        body = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
            const Icon(Icons.error_outline, color: AppColors.danger, size:28),
            const SizedBox(height:8),
            const Text('生成失败', style: TextStyle(fontFamily:'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:12, color: AppColors.danger)),
            const SizedBox(height:6),
            Text(t.error??'未知错误', style: const TextStyle(fontSize:12, color: AppColors.muted), textAlign: TextAlign.center, maxLines:4, overflow: TextOverflow.ellipsis),
            const SizedBox(height:10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children:[
              OutlinedButton(onPressed: _generate, child: const Text('重试', style: TextStyle(fontSize:12))),
              const SizedBox(width:8),
              OutlinedButton(onPressed: () async {
                if(t.error!=null) await Clipboard.setData(ClipboardData(text: t.error!));
                if(!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制错误信息')));
              }, child: const Text('复制错误', style: TextStyle(fontSize:12))),
            ]),
          ]),
        );
        break;
      case ImageStatus.completed:
        final url = t.imageUrls.isNotEmpty? t.imageUrls.first: null;
        final isB64 = url!=null && !url.startsWith('http');
        body = Stack(fit: StackFit.expand, children:[
          if(url!=null && !isB64)
            CachedNetworkImage(
              imageUrl: url, fit: BoxFit.cover,
              placeholder: (c,s)=> Container(color: AppColors.surface2, child: const Center(child: CircularProgressIndicator(color: AppColors.accent))),
              errorWidget: (c,s,e)=> Container(color: AppColors.surface2, child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[ const Icon(Icons.broken_image, color: AppColors.muted), const SizedBox(height:6), Padding(padding: EdgeInsets.symmetric(horizontal:12), child: Text('加载失败：$e', style: TextStyle(fontSize:11, color: AppColors.muted), textAlign: TextAlign.center)) ])),
            )
          else if(isB64)
            Image.memory(Uri.parse('data:image/png;base64,$url').data!.contentAsBytes(), fit: BoxFit.cover, errorBuilder: (c,e,s)=> Container(color: AppColors.surface2, child: const Icon(Icons.broken_image, color: AppColors.muted)))
          else
            Container(color: AppColors.surface2, child: const Icon(Icons.image_not_supported, color: AppColors.muted)),
          Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999)), child: const Text('已完成', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:10, fontWeight: FontWeight.w700, color: Color(0xFF111827))))),
          Positioned(bottom:8,left:8,right:8, child: Row(children:[
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: const Color(0xCC1A2230), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: Text('${t.model} · ${t.size}', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:10, color: AppColors.muted), overflow: TextOverflow.ellipsis))),
            const SizedBox(width:6),
            InkWell(
              onTap: () async {
                if(url!=null) await Clipboard.setData(ClipboardData(text: url));
                if(!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制图片 URL')));
              },
              child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xCC1A2230), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: const Icon(Icons.copy, size:14, color: AppColors.muted)),
            ),
          ])),
        ]);
        break;
      default:
        body = const Center(child: Text('排队中…', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, color: AppColors.muted)));
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.status==ImageStatus.failed? AppColors.danger.withValues(alpha:0.3): AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children:[
        Expanded(child: Center(child: body)),
        // 底部 prompt 预览
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal:10, vertical:8),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
          child: Text(t.prompt, maxLines:2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:11, color: AppColors.muted, height:1.4)),
        ),
      ]),
    );
  }
}
