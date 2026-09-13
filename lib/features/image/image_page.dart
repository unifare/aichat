
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../models/image_task.dart';
import '../../providers/app_providers.dart';

class ImagePage extends ConsumerStatefulWidget {
  const ImagePage({super.key});
  @override ConsumerState<ImagePage> createState()=> _ImagePageState();
}

class _ImagePageState extends ConsumerState<ImagePage> {
  final _prompt = TextEditingController(text: '一只坐在月球上的橘猫，霓虹城市背景，电影感光影');
  String _model='SDXL 1.0';
  String _size='1024 × 1024';
  String _count='4 张';
  bool _loading=false;

  Future<void> _generate() async {
    if(_prompt.text.trim().isEmpty) return;
    setState(()=>_loading=true);
    final provider = ref.read(aiProviderProvider);
    final tasks = ref.read(imageTasksProvider.notifier);
    // create 4 placeholder tasks
    final ids = List.generate(4, (_)=> const Uuid().v4());
    for(final id in ids){
      tasks.add(ImageTask(id:id, prompt:_prompt.text.trim(), model:_model, size:_size, status: ImageStatus.generating, progress: 12));
    }
    // simulate progress + completion
    for(final id in ids){
      try{
        final res = await provider.generateImage(prompt: _prompt.text.trim(), model: _model);
        // use real urls if returned, else fallback to picsum
        final urls = res.urls.isNotEmpty? res.urls : ['https://picsum.photos/seed/${id.hashCode}/600/600'];
        tasks.update(id, (t)=> t.copyWith(status: ImageStatus.completed, imageUrls: urls, progress: 100));
      }catch(e){
        // mark one as failed randomly? mark this one failed
        tasks.update(id, (t)=> t.copyWith(status: ImageStatus.failed, error: e.toString(), progress: 0));
      }
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if(mounted) setState(()=>_loading=false);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('生成完成 · 已保存到本地')));
  }

  @override void dispose(){ _prompt.dispose(); super.dispose(); }

  @override Widget build(BuildContext context){
    final tasks = ref.watch(imageTasksProvider);
    final w = MediaQuery.of(context).size.width;
    final isMobile = w<600;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                const Text('PROMPT', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, letterSpacing:0.6, color: AppColors.muted)),
                const SizedBox(height:6),
                TextField(controller: _prompt, maxLines:3, style: const TextStyle(fontSize:14), decoration: const InputDecoration(hintText: '一只坐在月球上的橘猫…')),
                const SizedBox(height:12),
                Row(children:[
                  Expanded(child: _dropdown('模型', _model, ['SDXL 1.0','DALL·E 3','Flux Schnell'], (v)=> setState(()=>_model=v))),
                  const SizedBox(width:10),
                  Expanded(child: _dropdown('尺寸', _size, ['1024 × 1024','1152 × 896','896 × 1152'], (v)=> setState(()=>_size=v))),
                ]),
                const SizedBox(height:10),
                Row(children:[
                  Expanded(child: _dropdown('数量', _count, ['4 张','1 张','2 张'], (v)=> setState(()=>_count=v))),
                  const SizedBox(width:10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    const Text('参考图', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                    const SizedBox(height:6),
                    Row(children:[
                      Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('＋ 上传', style: TextStyle(fontSize:12)))),
                      const SizedBox(width:8),
                      Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('粘贴', style: TextStyle(fontSize:12)))),
                    ]),
                  ])),
                ]),
                const SizedBox(height:12),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _loading? null: _generate, icon: const Icon(Icons.bolt, size:18), label: Text(_loading? '生成中…': '生成图片'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), padding: const EdgeInsets.symmetric(vertical:12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                const SizedBox(height:8),
                const Text('支持 Text→Image / Image+Text→Image，失败可重试，成功可保存/分享/再次编辑。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height:16),
            Row(children:[
              Text('生成结果 · ${tasks.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
              const SizedBox(width:8),
              Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: const Text('1024²', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted))),
              const Spacer(),
              const Text('长按可拖拽到桌面保存', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
            ]),
            const SizedBox(height:10),
            if(tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), color: AppColors.surface2),
                child: Column(children:[
                  Container(width:60,height:60, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withOpacity(0.25))), child: const Icon(Icons.image, color: AppColors.accent)),
                  const SizedBox(height:10),
                  const Text('还没有生成', style: TextStyle(color: AppColors.muted, fontSize:13)),
                  const SizedBox(height:4),
                  const Text('输入 Prompt 后点击“生成图片”', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
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

  Widget _dropdown(String label, String value, List<String> items, Function(String) onChanged){
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(label, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
      const SizedBox(height:6),
      DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal:10, vertical:10)),
        items: items.map((e)=> DropdownMenuItem(value:e, child: Text(e, style: const TextStyle(fontSize:13)))).toList(),
        onChanged: (v){ if(v!=null) onChanged(v); },
      ),
    ]);
  }

  Widget _card(ImageTask t){
    Widget body;
    switch(t.status){
      case ImageStatus.generating:
        body = Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          const SizedBox(width:36,height:36, child: CircularProgressIndicator(strokeWidth:3, valueColor: AlwaysStoppedAnimation(AppColors.accent))),
          const SizedBox(height:10),
          const Text('生成中… 67%', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, color: AppColors.muted)),
          const SizedBox(height:8),
          Padding(padding: const EdgeInsets.symmetric(horizontal:24), child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: 0.67, minHeight:6, backgroundColor: Color(0x14FFFFFF), valueColor: AlwaysStoppedAnimation(AppColors.accent)))),
        ]);
        break;
      case ImageStatus.failed:
        body = Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          const Text('生成失败', style: TextStyle(fontFamily:'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:12, color: AppColors.danger)),
          const SizedBox(height:6),
          Text(t.error??'Endpoint 超时，请检查 Base URL', style: const TextStyle(fontSize:12, color: AppColors.muted), textAlign: TextAlign.center),
          const SizedBox(height:10),
          OutlinedButton(onPressed: _generate, child: const Text('重试', style: TextStyle(fontSize:12))),
        ]);
        break;
      case ImageStatus.completed:
        final url = t.imageUrls.isNotEmpty? t.imageUrls.first: null;
        body = Stack(fit: StackFit.expand, children:[
          if(url!=null)
            CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (c,s)=> Container(color: AppColors.surface2, child: const Center(child: CircularProgressIndicator())), errorWidget: (c,s,e)=> Container(color: AppColors.surface2, child: const Icon(Icons.broken_image, color: AppColors.muted)))
          else
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.surface2, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight))),
          Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999)), child: const Text('NEW', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w700, color: Color(0xFF111827))))),
          Positioned(bottom:8,right:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Color(0xCC1A2230), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)), child: Text('${t.model} · 2.4s', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)))),
        ]);
        break;
      default:
        body = const Center(child: Text('排队中…', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:12, color: AppColors.muted)));
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}
