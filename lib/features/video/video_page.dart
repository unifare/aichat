
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/video_task.dart';
import '../../providers/app_providers.dart';

class VideoPage extends ConsumerStatefulWidget {
  const VideoPage({super.key});
  @override ConsumerState<VideoPage> createState()=> _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  final _prompt = TextEditingController();
  String _model='';
  String _duration='10s';
  final Map<String, Timer> _pollers={};

  @override void initState(){ super.initState(); WidgetsBinding.instance.addPostFrameCallback((_){ _syncModel(); }); }
  void _syncModel(){
    final configs = ref.read(providerConfigsProvider);
    final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? (configs.isNotEmpty? configs.first: null);
    if(active!=null && _model.isEmpty) setState(()=> _model=active.videoModel);
  }
  @override void dispose(){
    _prompt.dispose();
    for(final t in _pollers.values) t.cancel();
    super.dispose();
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
      _model = active.videoModel;
    }
    final provider = ref.read(aiProviderProvider);
    final notifier = ref.read(videoTasksProvider.notifier);
    try{
      final task = await provider.generateVideo(prompt: prompt, model: _model, duration: _duration);
      notifier.add(task);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已创建任务 · ${task.id}，开始轮询…')));
      _startPoll(task.id);
    }catch(e){
      final msg = e.toString().replaceFirst('Exception:','').trim();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败：$msg')));
    }
  }

  void _startPoll(String taskId){
    _pollers[taskId]?.cancel();
    final provider = ref.read(aiProviderProvider);
    final notifier = ref.read(videoTasksProvider.notifier);
    _pollers[taskId] = Timer.periodic(const Duration(seconds:3), (t) async {
      try{
        final updated = await provider.getVideoTask(taskId);
        notifier.update(taskId, (_)=> updated);
        if(updated.status==VideoStatus.completed || updated.status==VideoStatus.failed){
          t.cancel();
          _pollers.remove(taskId);
          if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(updated.status==VideoStatus.completed? '视频已完成 · $taskId': '视频失败 · ${updated.error??''}')));
          }
        }
      }catch(e){
        // 轮询错误：保留任务，提示一次后继续
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('轮询失败：$e')));
      }
    });
  }

  @override Widget build(BuildContext context){
    final tasks = ref.watch(videoTasksProvider);
    final configs = ref.watch(providerConfigsProvider);
    final hasProvider = configs.isNotEmpty;
    if(hasProvider && _model.isEmpty){
      final active = configs.where((c)=>c.id==ref.read(activeProviderIdProvider)).firstOrNull ?? configs.first;
      WidgetsBinding.instance.addPostFrameCallback((_)=> setState(()=> _model=active.videoModel));
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
                  const Expanded(child: Text('未配置 Provider，无法生成视频。', style: TextStyle(fontSize:12, color: Color(0xFFF59E0B)))),
                  FilledButton(onPressed: ()=> context.go('/settings'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal:12, vertical:6)), child: const Text('去设置', style: TextStyle(fontSize:12))),
                ]),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Row(children:[
                  const Text('PROMPT', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                  const Spacer(),
                  if(_prompt.text.isNotEmpty) Text('${_prompt.text.length} 字', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                ]),
                const SizedBox(height:6),
                TextField(
                  controller: _prompt,
                  maxLines:3, minLines:2,
                  decoration: InputDecoration(
                    hintText: '例如：一辆跑车在未来城市高速行驶，霓虹雨夜，电影运镜…',
                    filled:true, fillColor: AppColors.surface2,
                    suffixIcon: _prompt.text.isNotEmpty? IconButton(icon: const Icon(Icons.clear, size:18), onPressed: ()=> setState(()=> _prompt.clear())): null,
                  ),
                  onChanged: (_)=> setState((){}),
                  enabled: hasProvider,
                ),
                const SizedBox(height:12),
                Row(children:[
                  Expanded(child: _drop('模型', _model, _modelOptions(configs), (v)=> setState(()=>_model=v), enabled: hasProvider)),
                  const SizedBox(width:10),
                  Expanded(child: _drop('时长', _duration, ['5s','10s','15s'], (v)=> setState(()=>_duration=v), enabled: hasProvider)),
                ]),
                const SizedBox(height:12),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: hasProvider? _generate: null, icon: const Icon(Icons.play_arrow, size:18), label: const Text('生成视频'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), disabledBackgroundColor: AppColors.surface2, padding: const EdgeInsets.symmetric(vertical:12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                const SizedBox(height:8),
                const Text('异步：POST 创建 task_id → 每 3 秒轮询 → 完成后返回 video_url。进度与状态来自服务端。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height:16),
            Row(children:[
              Text('任务 · ${tasks.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
              const Spacer(),
              if(tasks.isNotEmpty) TextButton(onPressed: (){
                for(final t in _pollers.values) t.cancel();
                _pollers.clear();
                ref.read(videoTasksProvider.notifier).clear();
              }, child: const Text('清空', style: TextStyle(fontSize:12))),
            ]),
            const SizedBox(height:8),
            if(tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), color: AppColors.surface2),
                child: Column(children:[
                  Container(width:60,height:60, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withValues(alpha:0.2))), child: const Icon(Icons.videocam_outlined, color: AppColors.accent, size:28)),
                  const SizedBox(height:12),
                  const Text('还没有视频任务', style: TextStyle(color: AppColors.muted, fontSize:13)),
                  const SizedBox(height:4),
                  const Text('输入 Prompt 后点击“生成视频”，任务状态将自动轮询。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted), textAlign: TextAlign.center),
                ]),
              )
            else
              ...tasks.map((t)=> Padding(padding: const EdgeInsets.only(bottom:12), child: _videoCard(t))),
          ]),
        ),
      ),
    );
  }

  List<String> _modelOptions(List configs){
    final s=<String>{};
    for(final c in configs) s.add(c.videoModel);
    s.addAll(['sora','runway-gen-3','luma-dream']);
    if(_model.isNotEmpty) s.add(_model);
    return s.toList();
  }

  Widget _drop(String label, String value, List<String> items, Function(String) onChanged, {bool enabled=true}){
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

  Widget _videoCard(VideoTask t){
    final isDone = t.status==VideoStatus.completed;
    final isFailed = t.status==VideoStatus.failed;
    final isProcessing = t.status==VideoStatus.processing;
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isFailed? AppColors.danger.withValues(alpha:0.3): AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children:[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children:[
            Expanded(child: Text('任务 · #${t.id}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13), overflow: TextOverflow.ellipsis)),
            const SizedBox(width:8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
              decoration: BoxDecoration(color: isDone? AppColors.accent.withValues(alpha:0.12): isFailed? AppColors.danger.withValues(alpha:0.12): AppColors.surface2, borderRadius: BorderRadius.circular(999), border: Border.all(color: isDone? AppColors.accent.withValues(alpha:0.4): isFailed? AppColors.danger.withValues(alpha:0.4): AppColors.border)),
              child: Text(isDone? '已完成 · ${t.duration}': isFailed? '失败': isProcessing? (t.progress>0? '处理中 · ${t.progress}%': '处理中…'): '排队中', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: isDone? AppColors.accent: isFailed? AppColors.danger: AppColors.muted)),
            ),
            const SizedBox(width:8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size:16, color: AppColors.muted),
              onSelected: (v){
                if(v=='copy_id'){
                  Clipboard.setData(ClipboardData(text: t.id));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制 task_id')));
                } else if(v=='remove'){
                  _pollers[t.id]?.cancel();
                  _pollers.remove(t.id);
                  ref.read(videoTasksProvider.notifier).remove(t.id);
                } else if(v=='retry_poll'){
                  _startPoll(t.id);
                }
              },
              itemBuilder: (ctx)=> [
                const PopupMenuItem(value:'copy_id', child: Text('复制 task_id')),
                const PopupMenuItem(value:'retry_poll', child: Text('重新轮询')),
                const PopupMenuItem(value:'remove', child: Text('移除任务', style: TextStyle(color: AppColors.danger))),
              ],
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children:[
            AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: isDone
                  ? Stack(alignment: Alignment.center, children:[
                      Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: [AppColors.surface2, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(mainAxisSize: MainAxisSize.min, children:[
                          const Icon(Icons.check_circle, color: AppColors.accent, size:36),
                          const SizedBox(height:8),
                          Text('VIDEO READY · ${t.duration}', style: const TextStyle(fontFamily:'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:13)),
                          const SizedBox(height:4),
                          Text('${t.model} · 已完成', style: const TextStyle(fontSize:12, color: AppColors.muted), textAlign: TextAlign.center),
                          if(t.videoUrl!=null) ...[
                            const SizedBox(height:8),
                            SelectableText(t.videoUrl!, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:10, color: AppColors.muted), maxLines:2),
                          ],
                        ]),
                      ),
                    ])
                  : isFailed
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                          const Icon(Icons.error_outline, color: AppColors.danger, size:28),
                          const SizedBox(height:8),
                          const Text('生成失败', style: TextStyle(fontFamily:'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:12, color: AppColors.danger)),
                          const SizedBox(height:6),
                          Text(t.error??'未知错误', style: const TextStyle(fontSize:12, color: AppColors.muted), textAlign: TextAlign.center, maxLines:3, overflow: TextOverflow.ellipsis),
                          const SizedBox(height:10),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children:[
                            OutlinedButton(onPressed: ()=> _startPoll(t.id), child: const Text('重试轮询', style: TextStyle(fontSize:12))),
                            const SizedBox(width:8),
                            OutlinedButton(onPressed: () async {
                              if(t.error!=null) await Clipboard.setData(ClipboardData(text: t.error!));
                              if(!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制错误')));
                            }, child: const Text('复制错误', style: TextStyle(fontSize:12))),
                          ]),
                        ]),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                        const SizedBox(width:36,height:36, child: CircularProgressIndicator(strokeWidth:3, color: AppColors.accent)),
                        const SizedBox(height:10),
                        Text(isProcessing? (t.progress>0? '处理中 · ${t.progress}%': '处理中…'): '排队中…', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
                        if(t.progress>0) ...[
                          const SizedBox(height:8),
                          Padding(padding: const EdgeInsets.symmetric(horizontal:32), child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: t.progress/100, minHeight:6, backgroundColor: Color(0x14FFFFFF), valueColor: AlwaysStoppedAnimation(AppColors.accent)))),
                        ] else ...[
                          const SizedBox(height:8),
                          const Padding(padding: EdgeInsets.symmetric(horizontal:32), child: LinearProgressIndicator(minHeight:6, backgroundColor: Color(0x14FFFFFF), valueColor: AlwaysStoppedAnimation(AppColors.accent))),
                        ],
                        const SizedBox(height:8),
                        SelectableText('task_id: ${t.id} · 每 3 秒轮询', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted), textAlign: TextAlign.center),
                        const SizedBox(height:4),
                        SelectableText(t.prompt, style: const TextStyle(fontSize:11, color: AppColors.muted, height:1.4), maxLines:2, textAlign: TextAlign.center),
                      ]),
              ),
            ),
            const SizedBox(height:12),
            // 操作区：仅真实能力
            Row(children:[
              if(isDone && t.videoUrl!=null) ...[
                OutlinedButton.icon(onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: t.videoUrl!));
                  if(!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制 video_url')));
                }, icon: const Icon(Icons.link, size:16), label: const Text('复制链接', style: TextStyle(fontSize:12))),
                const SizedBox(width:8),
              ],
              OutlinedButton.icon(onPressed: () async {
                await Clipboard.setData(ClipboardData(text: t.id));
                if(!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制 task_id')));
              }, icon: const Icon(Icons.copy, size:16), label: const Text('复制 ID', style: TextStyle(fontSize:12))),
              const Spacer(),
              Text(t.prompt.length>24? '${t.prompt.substring(0,24)}…': t.prompt, style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
            ]),
          ]),
        ),
      ]),
    );
  }
}
