
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme.dart';
import '../../models/video_task.dart';
import '../../providers/app_providers.dart';

class VideoPage extends ConsumerStatefulWidget {
  const VideoPage({super.key});
  @override ConsumerState<VideoPage> createState()=> _VideoPageState();
}

class _VideoPageState extends ConsumerState<VideoPage> {
  final _prompt = TextEditingController(text: '一辆跑车在未来城市高速行驶，霓虹雨夜，电影运镜');
  String _model='Sora';
  String _duration='10s';
  Timer? _pollTimer;

  @override void dispose(){ _prompt.dispose(); _pollTimer?.cancel(); super.dispose(); }

  Future<void> _generate() async {
    if(_prompt.text.trim().isEmpty) return;
    final provider = ref.read(aiProviderProvider);
    final notifier = ref.read(videoTasksProvider.notifier);
    final task = await provider.generateVideo(prompt: _prompt.text.trim(), model: _model, duration: _duration);
    notifier.add(task);
    // start polling for this task
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 900), (t) async {
      final cur = ref.read(videoTasksProvider).where((e)=>e.id==task.id).firstOrNull;
      if(cur==null || cur.status==VideoStatus.completed || cur.status==VideoStatus.failed){ t.cancel(); return; }
      final updated = await provider.getVideoTask(task.id);
      notifier.update(task.id, (_)=> updated);
      if(updated.status==VideoStatus.completed || updated.status==VideoStatus.failed) t.cancel();
    });
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已提交视频任务 · ${task.id}')));
  }

  @override Widget build(BuildContext context){
    final tasks = ref.watch(videoTasksProvider);
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
                const Text('PROMPT', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                const SizedBox(height:6),
                TextField(controller: _prompt, maxLines:3, decoration: const InputDecoration(hintText: '一辆跑车在未来城市高速行驶…')),
                const SizedBox(height:12),
                Row(children:[
                  Expanded(child: _drop('模型', _model, ['Sora','Runway Gen-3','Luma Dream'], (v)=> setState(()=>_model=v))),
                  const SizedBox(width:10),
                  Expanded(child: _drop('时长', _duration, ['10s','5s','15s'], (v)=> setState(()=>_duration=v))),
                ]),
                const SizedBox(height:12),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _generate, icon: const Icon(Icons.play_arrow, size:18), label: const Text('生成视频'), style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Color(0xFF111827), padding: const EdgeInsets.symmetric(vertical:12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                const SizedBox(height:8),
                const Text('视频为异步任务：POST 创建 task_id → 轮询 3s → 完成后返回 video_url。', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height:16),
            if(tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), color: AppColors.surface2),
                child: Column(children:[
                  Container(width:60,height:60, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withOpacity(0.25))), child: const Icon(Icons.videocam, color: AppColors.accent)),
                  const SizedBox(height:10),
                  const Text('还没有视频任务', style: TextStyle(color: AppColors.muted, fontSize:13)),
                  const SizedBox(height:4),
                  const Text('输入 Prompt 后点击“生成视频”', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                ]),
              )
            else
              ...tasks.map((t)=> Padding(padding: const EdgeInsets.only(bottom:12), child: _videoCard(t))),
          ]),
        ),
      ),
    );
  }

  Widget _drop(String label, String value, List<String> items, Function(String) onChanged){
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

  Widget _videoCard(VideoTask t){
    final isDone = t.status==VideoStatus.completed;
    final isFailed = t.status==VideoStatus.failed;
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children:[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children:[
            Text('任务 · #${t.id}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
            const SizedBox(width:8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal:8, vertical:4),
              decoration: BoxDecoration(color: isDone? AppColors.accent.withOpacity(0.12): AppColors.surface2, borderRadius: BorderRadius.circular(999), border: Border.all(color: isDone? AppColors.accent.withOpacity(0.4): AppColors.border)),
              child: Text(isDone? '已完成 · ${t.duration}': isFailed? '失败': 'Generating… ${t.progress}%', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, fontWeight: FontWeight.w600, color: isDone? AppColors.accent: AppColors.muted)),
            ),
            const Spacer(),
            const Text('轮询间隔 3s · WebSocket 可选', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
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
                      Column(mainAxisSize: MainAxisSize.min, children:[
                        const Icon(Icons.check_circle, color: AppColors.accent, size:36),
                        const SizedBox(height:8),
                        Text('VIDEO READY · ${t.duration} · 1080p', style: const TextStyle(fontFamily:'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:13)),
                        const SizedBox(height:4),
                        Text('${t.model} · 点击播放 · video_url 就绪', style: const TextStyle(fontSize:12, color: AppColors.muted)),
                      ]),
                      Positioned.fill(child: Center(child: Container(width:54,height:54, decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Color(0xFF111827), size:28)))),
                    ])
                  : isFailed
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                        const Text('生成失败', style: TextStyle(fontFamily:'JetBrainsMono', fontWeight: FontWeight.w700, fontSize:12, color: AppColors.danger)),
                        const SizedBox(height:6),
                        Text(t.error??'任务失败', style: const TextStyle(fontSize:12, color: AppColors.muted)),
                      ])
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children:[
                        const SizedBox(width:48,height:48, child: CircularProgressIndicator(strokeWidth:3, valueColor: AlwaysStoppedAnimation(AppColors.accent))),
                        const SizedBox(height:10),
                        Text('Generating… ${t.progress}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
                        const SizedBox(height:8),
                        Padding(padding: const EdgeInsets.symmetric(horizontal:32), child: ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: t.progress/100, minHeight:6, backgroundColor: Color(0x14FFFFFF), valueColor: AlwaysStoppedAnimation(AppColors.accent)))),
                        const SizedBox(height:6),
                        Text('task_id: ${t.id} · 已轮询', style: const TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
                      ]),
              ),
            ),
            const SizedBox(height:12),
            Row(children:[
              OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.download, size:16), label: const Text('保存', style: TextStyle(fontSize:12))),
              const SizedBox(width:8),
              OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.share, size:16), label: const Text('分享', style: TextStyle(fontSize:12))),
              const SizedBox(width:8),
              OutlinedButton(onPressed: (){}, child: const Text('更多', style: TextStyle(fontSize:12))),
              const Spacer(),
              const Text('完成后可一键保存到相册 / 文件', style: TextStyle(fontFamily:'JetBrainsMono', fontSize:11, color: AppColors.muted)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> { E? get firstOrNull => isEmpty? null: first; }
